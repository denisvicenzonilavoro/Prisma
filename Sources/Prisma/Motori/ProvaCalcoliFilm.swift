import Foundation

// Prova del film del piano («Luce» giro 15, §3.2 e §5 del piano): scene saltate senza obiettivi e senza data di nascita;
// nil con solo titolo e chiusura; quote fra 0 e 1 (già da parte, decisione 81); curva in euro di oggi tagliata all'età di
// pensione; etichetta dell'arrivo dentro l'area; pensione solo con proposte previdenziali e area Previdenza confermata;
// firma Alleanza senza logo e con la parola; durata 20,2 s con tutte le scene, meno senza le scene vuote; la scena e il
// tempo all'istante; il tempo «0:05 / 0:20»; l'impronta che cambia con un obiettivo e non con il mese. Cliente, posizioni
// e cifre inventati per la prova (cifre non tonde, date fisse).
enum ProvaCalcoliFilm {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 6, 15)
        var c = Cliente(id: "prova-film", nome: "Ottavia Brunelleschi", iniziali: "OB", tinta: .viola, tema: "",
                        email: "", telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2023, 2, 7))
        c.dataNascita = AiutiProva.data(1989, 4, 21)
        c.canali = [.indipendente]

        var conto = AiutiProva.posizione("Conto deposito prova", .liquidita, 7_314.27)
        conto.clienteId = c.id
        var fondo = AiutiProva.posizione("Fondo prova", .investimento, 18_623.41)
        fondo.clienteId = c.id
        var proposta = Posizione(clienteId: c.id, canale: .alleanza, stato: .proposta, area: .previdenza, nome: "Piano pensione prova")
        proposta.premio = 137.35
        proposta.frequenza = .mensile

        var casa = Obiettivo(clienteId: c.id, titolo: "Anticipo casa", area: .casa, importo: 41_270, scadenza: AiutiProva.data(2030, 10, 1))
        casa.accantonato = 9_413
        casa.priorita = .alta
        casa.versamentoMensile = 553
        var studi = Obiettivo(clienteId: c.id, titolo: "Studi di Leo", area: .famiglia, importo: 23_740, scadenza: AiutiProva.data(2035, 9, 1))
        studi.accantonato = 31_118          // più dell'importo: la quota resta 1
        studi.priorita = .media
        let senzaImporto = Obiettivo(clienteId: c.id, titolo: "Sogno senza cifra", area: .famiglia, importo: 0,
                                     scadenza: AiutiProva.data(2031, 1, 1))

        var analisi = Analisi360()
        analisi.previdenza.etaPensione = 66
        analisi.previdenza.redditoDesiderato = 2_130
        analisi.previdenza.pensionePubblica = 1_270
        analisi.confermate = [.previdenza]

        let posizioni = [conto, fondo, proposta]
        let obiettivi = [casa, studi, senzaImporto]
        let firme = TestiFilm.firme(cliente: c)
        let avvertenza = ImpostazioniSala.segnapostoAvvertenza
        func film(_ cl: Cliente, _ pos: [Posizione], _ ob: [Obiettivo], _ an: Analisi360?, oggi o: Date) -> DatiFilm? {
            let scheda = MotoreLettera.scheda(cliente: cl, posizioni: pos, obiettivi: ob, analisi: an, oggi: o)
            return MotoreFilm.dati(cliente: cl, posizioni: pos, obiettivi: ob, eventi: [], analisi: an, scheda: scheda,
                                   firme: TestiFilm.firme(cliente: cl), avvertenza: avvertenza, oggi: o, diProva: true)
        }

        // Il film completo: cinque scene, 20,2 s, 606 fotogrammi
        guard let d = film(c, posizioni, obiettivi, analisi, oggi: oggi) else {
            verifica.vero("Film: con obiettivi, data di nascita e previdenza il film c'è", false)
            return
        }
        verifica.vero("Film: con tutti i dati ci sono le cinque scene", d.scene == ScenaFilm.allCases)
        verifica("Film: durata con tutte le scene", d.durataTotale, 20.2, tolleranza: 1e-9)
        verifica("Film: 606 fotogrammi a 30 al secondo", Double(MotoreFilm.fotogrammi(d)), 606)
        verifica.vero("Film: titolo con il nome di battesimo", d.titolo == "Il piano di Ottavia")
        verifica.vero("Film: il mese di oggi", d.data == Formati.meseAnno.string(from: oggi))
        verifica.vero("Film: obiettivo senza importo fuori, al più tre", d.obiettivi.count == 2 && !d.obiettivi.contains { $0.nome == "Sogno senza cifra" })
        verifica.vero("Film: quote fra 0 e 1", d.obiettivi.allSatisfy { $0.quota >= 0 && $0.quota <= 1 })
        verifica("Film: quota già da parte (decisione 81)", d.obiettivi.first { $0.nome == "Anticipo casa" }?.quota ?? -1,
                 MotoreFilm.quota(casa, posizioni: posizioni, oggi: oggi), tolleranza: 1e-9)
        verifica("Film: accantonato oltre l'importo = quota piena", d.obiettivi.first { $0.nome == "Studi di Leo" }?.quota ?? -1, 1)
        verifica.vero("Film: il versamento del primo obiettivo con un versamento", d.versamento == VersamentoFilm(cifra: 553, obiettivo: "Anticipo casa"))

        // Pensione: contributi delle proposte al mese solo con l'area confermata
        verifica("Film: + X € per la pensione = contributi delle proposte / 12", d.pensione ?? -1, 137.35, tolleranza: 0.005)
        var nonConfermata = analisi
        nonConfermata.confermate = []
        verifica.vero("Film: senza la previdenza confermata niente pensione",
                      MotoreFilm.pensioneProposte(cliente: c, posizioni: posizioni, analisi: nonConfermata, oggi: oggi) == nil)
        verifica.vero("Film: senza proposte previdenziali niente pensione",
                      MotoreFilm.pensioneProposte(cliente: c, posizioni: [conto, fondo], analisi: analisi, oggi: oggi) == nil)
        verifica.vero("Film: senza Analisi 360 niente pensione",
                      MotoreFilm.pensioneProposte(cliente: c, posizioni: posizioni, analisi: nil, oggi: oggi) == nil)

        // Curva in euro di oggi, tagliata alla pensione
        let prep = MotoreLineaVita.prepara(cliente: c, posizioni: posizioni, obiettivi: obiettivi, eventi: [], analisi: analisi, oggi: oggi)
        if let i = prep.ingresso {
            let attesi = MotoreLineaVita.calcola(i).punti.filter { $0.eta <= i.etaPensione }.map(\.valore)
            verifica("Film: curva dall'età di oggi a quella di pensione", Double(d.curva.count), Double(i.etaPensione - i.etaOggi + 1))
            verifica.vero("Film: curva = linea della vita in euro di oggi", d.curva == attesi)
            verifica.vero("Film: punto finale all'età di pensione", d.fine?.eta == i.etaPensione && d.fine?.valore == attesi.last)
        } else {
            verifica.vero("Film: ingresso della linea della vita con la data di nascita", false)
        }
        if let a = d.arrivo {
            verifica.vero("Film: arrivo dentro la curva", a.indice >= 0 && a.indice < d.curva.count)
            verifica.vero("Film: etichetta dell'arrivo con l'obiettivo", a.testo.hasSuffix("· Anticipo casa"))
        }

        // Etichette dentro l'area della curva
        let area = Tema.Apple.SalaRacconti.Film.areaCurva
        let vicinoSinistra = GeometriaFilm.sinistraEtichetta(centro: area.minX + 7, larghezza: 213)
        verifica.vero("Film: etichetta dell'arrivo vicino a oggi dentro l'area (x ≥ margine)", vicinoSinistra >= area.minX)
        let vicinoDestra = GeometriaFilm.sinistraEtichetta(centro: area.maxX - 3, larghezza: 213)
        verifica.vero("Film: etichetta dell'arrivo vicino alla fine dentro l'area", vicinoDestra + 213 <= area.maxX + 0.001)
        let fine = GeometriaFilm.sinistraEtichettaFine(punto: area.maxX, larghezza: 371)
        verifica.vero("Film: etichetta finale allineata a destra 14 prima del punto", abs(fine + 371 + 14 - area.maxX) < 0.001)
        verifica.vero("Film: etichetta finale lunga mai fuori a sinistra",
                      GeometriaFilm.sinistraEtichettaFine(punto: area.minX + 40, larghezza: 371) >= area.minX)
        let punti = d.curva.indices.map { GeometriaFilm.punto($0, di: d.curva) }
        verifica.vero("Film: punti della curva dentro l'area",
                      punti.allSatisfy { $0.x >= area.minX - 0.001 && $0.x <= area.maxX + 0.001 && $0.y >= area.minY - 0.001 && $0.y <= area.maxY + 0.001 })

        // Scene saltate
        if let senzaObiettivi = film(c, [conto, fondo], [], nil, oggi: oggi) {
            verifica.vero("Film: senza obiettivi niente «Oggi» né «Ogni mese»", senzaObiettivi.scene == [.titolo, .futuro, .chiusura])
            verifica("Film: senza le scene vuote dura meno", senzaObiettivi.durataTotale, 3.4 + 4.8 + 3.6, tolleranza: 1e-9)
        } else {
            verifica.vero("Film: senza obiettivi resta la curva", false)
        }
        var senzaNascita = c
        senzaNascita.dataNascita = nil
        if let d2 = film(senzaNascita, posizioni, obiettivi, analisi, oggi: oggi) {
            verifica.vero("Film: senza data di nascita niente curva", !d2.scene.contains(.futuro) && d2.curva.isEmpty && d2.fine == nil && d2.arrivo == nil)
            verifica.vero("Film: senza data di nascita restano oggi e ogni mese", d2.scene == [.titolo, .oggi, .ogniMese, .chiusura])
        } else {
            verifica.vero("Film: senza data di nascita restano gli obiettivi", false)
        }
        var senzaVersamento = casa
        senzaVersamento.versamentoMensile = 0
        if let d3 = film(c, [conto, fondo], [senzaVersamento], nil, oggi: oggi) {
            verifica.vero("Film: senza versamenti né pensione la scena «Ogni mese» si salta", !d3.scene.contains(.ogniMese))
        }
        verifica.vero("Film: con solo titolo e chiusura niente film", film(senzaNascita, [conto], [], nil, oggi: oggi) == nil)

        // Firma secondo il canale (decisione 57)
        var soloAlleanza = c
        soloAlleanza.canali = [.alleanza]
        let firmaAlleanza = TestiFilm.firme(cliente: soloAlleanza)
        verifica.vero("Film: firma Alleanza con la parola e il colore del canale, senza logo",
                      firmaAlleanza == [FirmaFilm(testo: Canale.alleanza.nome, colore: Tema.Apple.SalaRacconti.Film.canaleAlleanza)]
                        && firmaAlleanza[0].testo.contains("Alleanza"))
        verifica.vero("Film: firma indipendente per un cliente indipendente", firme.count == 1 && firme[0].testo == Canale.indipendente.nome)
        var senzaCanali = c
        senzaCanali.canali = []
        verifica.vero("Film: senza canali la firma indipendente", TestiFilm.firme(cliente: senzaCanali).map(\.testo) == [Canale.indipendente.nome])

        // Il tempo
        let t0 = MotoreFilm.scena(al: 0, d)
        verifica.vero("Film: all'inizio la scena del titolo", t0.scena == 0 && t0.t == 0)
        let t1 = MotoreFilm.scena(al: 3.537, d)
        verifica.vero("Film: dopo 3,537 s la seconda scena", t1.scena == 1)
        verifica("Film: tempo dentro la seconda scena", t1.t, 0.137, tolleranza: 1e-9)
        let oltre = MotoreFilm.scena(al: 99.3, d)
        verifica.vero("Film: oltre la fine resta l'ultima scena ferma", oltre.scena == d.scene.count - 1 && abs(oltre.t - (d.durate.last ?? 0)) < 1e-9)
        verifica("Film: inizio della scena del futuro", MotoreFilm.inizio(scena: 3, d), 3.4 + 4.2 + 4.2, tolleranza: 1e-9)
        verifica.vero("Film: tempo «0:05 / 0:20» con i decimi troncati", TestiFilm.tempo(5.93, totale: 20.2) == "0:05 / 0:20")
        verifica.vero("Film: alla fine «0:20 / 0:20»", TestiFilm.tempo(23.71, totale: 20.2) == "0:20 / 0:20")
        verifica.vero("Film: «20 secondi · senza voce · pronto»", TestiFilm.dettaglioPronto(20.2) == "20 secondi · senza voce · pronto")
        verifica.vero("Film: nome del file «Il piano di Ottavia.mp4»", TestiFilm.nomeFile("Ottavia") == "Il piano di Ottavia.mp4")

        // L'impronta: cambia con un obiettivo, non con il mese
        let altroMese = DatiFilm(titolo: d.titolo, data: "dicembre 2031", obiettivi: d.obiettivi, versamento: d.versamento,
                                 pensione: d.pensione, curva: d.curva, arrivo: d.arrivo, fine: d.fine, firme: d.firme,
                                 avvertenza: d.avvertenza, scene: d.scene, durate: d.durate, diProva: d.diProva)
        verifica.vero("Film: l'impronta non cambia con il mese", altroMese.impronta == d.impronta)
        var casaCambiata = casa
        casaCambiata.accantonato = 12_947
        if let d4 = film(c, posizioni, [casaCambiata, studi, senzaImporto], analisi, oggi: oggi) {
            verifica.vero("Film: l'impronta cambia con un obiettivo", d4.impronta != d.impronta)
        }
        verifica.vero("Film: impronta SHA256 in esadecimale", d.impronta.count == 64)

        // Colori in esadecimale
        verifica.vero("Film: colore esadecimale andata e ritorno", ColoreFilm.hex("#C4B5FD").esadecimale == "#C4B5FD")
    }
}
