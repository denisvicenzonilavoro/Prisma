import Foundation

/// Prove della scheda di Inquadra e capisci (Orizzonte, giro 5; specifica §9.5.5, punti 4-7), chiamate da
/// `ProvaCalcoli.esegui()` dopo `ProvaCalcoliInquadra`: le righe della scheda nella forma di Prisma, la riga «Tipo»
/// secondo il canale, i pochi dati, il cliente dal contraente, canale e area, il confronto con una temporanea e la
/// tariffa delle sole temporanee. Il foglio è quello di prova (`FoglioInquadraDiProva`, nessun dato vero).
enum ProvaCalcoliSchedaInquadra {
    static func esegui(_ verifica: VerificaCalcoli) {
        let d = MotoreInquadra.leggi(FoglioInquadraDiProva.righe())

        // IQ7. Le cinque righe nell'ordine fisso, nella forma di Prisma
        let righe = MotoreInquadra.righe(d, canale: .indipendente)
        verifica.vero("IQ7 Cinque righe: contraente, premio, capitale, decorrenza, tipo",
                      righe.map(\.id) == ["contraente", "premio", "capitale", "decorrenza", "tipo"] && righe.allSatisfy(\.trovata))
        verifica.vero("IQ7 Premio «90 € al mese» (senza decimali)", righe[1].valore == Formati.euro(90) + " al mese")
        verifica.vero("IQ7 Capitale «50.000 €»", righe[2].valore == Formati.euro(50_000))
        verifica.vero("IQ7 Decorrenza «marzo 2021»", righe[3].valore == "marzo 2021")
        verifica.vero("IQ7 Tipo con la compagnia letta", righe[4].valore == "Vita intera a premio ricorrente · Esempio Vita S.p.A.")
        verifica.vero("IQ7 Tipo con il canale Alleanza", MotoreInquadra.righe(d, canale: .alleanza)[4].valore == "Vita intera a premio ricorrente · Alleanza")
        let senzaCompagnia = MotoreInquadra.leggi(Array(FoglioInquadraDiProva.righe().prefix(7)))
        verifica.vero("IQ7 Tipo senza compagnia: «altra compagnia»",
                      MotoreInquadra.tipo(senzaCompagnia, canale: .indipendente) == "Vita intera a premio ricorrente · altra compagnia")
        verifica.vero("IQ7 Premio con i centesimi", MotoreInquadra.importo(90.5) == Formati.euroDecimali(90.5) && MotoreInquadra.importo(90) == Formati.euro(90))
        verifica.vero("IQ7 Titolo «Polizza riconosciuta»", MotoreInquadra.titoloRiconosciuto(d.tipoDocumento) == "Polizza riconosciuta"
                      || d.tipoDocumento == .kid || d.tipoDocumento == .estrattoConto)

        // IQ8. Pochi dati: solo contraente e premio, le altre righe senza valore (grigie, senza ✓)
        let parziale = MotoreInquadra.righe(MotoreInquadra.leggi(FoglioInquadraDiProva.parziale()), canale: .indipendente)
        verifica("IQ8 Pochi dati: due righe trovate", Double(parziale.filter(\.trovata).count), 2)
        verifica.vero("IQ8 Pochi dati: le cinque righe restano, quelle che mancano senza valore",
                      parziale.count == 5 && parziale[2].valore == nil && parziale[3].valore == nil && parziale[4].valore == nil)

        // IQ9. Il cliente dal contraente: senza maiuscole e accenti; due uguali → nessuno
        let demo = DatiPrisma.demo()
        let giulia = demo.clienti.first { $0.id == "giulia" }
        verifica.vero("IQ9 «giulia rossi» è Giulia", giulia != nil
                      && MotoreInquadra.clienteProbabile(contraente: "giulia rossi", clienti: demo.clienti)?.id == "giulia")
        verifica.vero("IQ9 Due clienti con lo stesso nome: da scegliere",
                      giulia.map { MotoreInquadra.clienteProbabile(contraente: "Giulia Rossi", clienti: [$0, $0]) == nil } ?? false)
        verifica.vero("IQ9 Contraente sconosciuto: da scegliere", MotoreInquadra.clienteProbabile(contraente: "Anna Verdi", clienti: demo.clienti) == nil)

        // IQ10. Canale e area: compagnia non Alleanza → indipendente; capitale assicurato → protezione
        let ca = MotoreInquadra.canaleEArea(d)
        verifica.vero("IQ10 Canale indipendente, area protezione", ca.canale == .indipendente && ca.area == .protezione)

        // IQ11. Confronto con una temporanea: tariffa 1,1875 ‰ e fabbisogno 160.000 → circa 190 € l'anno
        let tariffa = MotoreSimulatoriAnalisi.TariffaCasoMorte(perMille: 1.1875, coperture: 1, fonte: .archivio)
        let c = MotoreInquadra.confronta(d, fabbisogno: 160_000, tariffa: tariffa)
        verifica("IQ11 Spesa della polizza: 90 × 12", c.polizza.spesaAnnua ?? -1, 1_080)
        verifica("IQ11 Capitale della temporanea dal fabbisogno", c.temporanea.capitaleCasoMorte ?? -1, 160_000)
        verifica("IQ11 Spesa della temporanea, a 10 €", c.temporanea.spesaAnnua ?? -1, 190)
        verifica.vero("IQ11 Riscatto: la vita intera cresce, la temporanea no", c.polizza.riscatto == .cresce && c.temporanea.riscatto == .no)
        let senzaTariffa = MotoreInquadra.confronta(d, fabbisogno: nil, tariffa: nil)
        verifica.vero("IQ11 Senza tariffa: spesa assente e la nota lo dice", senzaTariffa.temporanea.spesaAnnua == nil
                      && senzaTariffa.temporanea.capitaleCasoMorte == 50_000 && MotoreInquadra.notaConfronto(senzaTariffa).hasPrefix("Manca una tariffa"))

        // IQ12. La tariffa usa solo le temporanee (una vita intera costa molto di più per mille)
        var tcm = Posizione(clienteId: "prova", canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Temporanea caso morte")
        tcm.tipologia = "Temporanea caso morte a capitale costante"
        var vi = Posizione(clienteId: "prova", canale: .indipendente, stato: .inEssere, area: .protezione, nome: "Vita intera")
        vi.tipologia = "Vita intera a premio ricorrente"
        verifica.vero("IQ12 Solo le temporanee fanno la tariffa", MotoreInquadra.temporanee([tcm, vi]).map(\.nome) == ["Temporanea caso morte"])

        // IQ13. Nello stato: niente entra nel dossier senza conferma; «Conferma e aggiungi» crea documento e posizione
        do {
            let s = StatoShell(persistente: false)
            let prima = (posizioni: s.dati.posizioni.count, documenti: s.dati.documenti.count)
            s.apriInquadra()
            s.inquadra.mostra(righe: FoglioInquadraDiProva.righe(), origine: "iPhone di prova", subito: true)
            verifica.vero("IQ13 Scena aperta, lettura finita, cliente dal contraente",
                          s.inquadra.aperto && s.inquadra.finito && s.inquadra.fase == .letto && s.clienteInquadra?.id == "giulia")
            verifica.vero("IQ13 Prima della conferma il dossier non cambia",
                          s.dati.posizioni.count == prima.posizioni && s.dati.documenti.count == prima.documenti)
            let confronto = s.confrontoInquadra(s.inquadra.dati ?? d)
            verifica.vero("IQ13 Confronto: tariffa dalle temporanee di Giulia", confronto.fonteTariffa == .cliente && confronto.temporanea.spesaAnnua != nil)
            s.aggiungiInquadrata()
            let nuova = s.dati.posizioni.count == prima.posizioni + 1 ? s.dati.posizioni.last : nil
            verifica.vero("IQ13 Aggiunta: una posizione in essere di Giulia, indipendente, protezione",
                          nuova?.clienteId == "giulia" && nuova?.stato == .inEssere && nuova?.canale == .indipendente && nuova?.area == .protezione)
            verifica.vero("IQ13 Aggiunta: premio mensile, 1.080 € l'anno", nuova?.frequenza == .mensile && abs((nuova?.premioAnnuo ?? 0) - 1_080) < 0.01)
            let doc = s.dati.documenti.count == prima.documenti + 1 ? s.dati.documenti.last : nil
            verifica.vero("IQ13 Il documento senza file, con i dati confermati e collegato",
                          doc?.file == nil && doc?.campi.allSatisfy(\.confermato) == true && doc?.posizioneId == nuova?.id)
            verifica.vero("IQ13 La scena si chiude", !s.inquadra.aperto && s.inquadra.dati == nil)
        }
    }
}
