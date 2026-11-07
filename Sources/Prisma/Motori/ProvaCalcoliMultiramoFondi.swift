import Foundation

/// Prove delle multiramo con il rendimento di ogni fondo (versione 25 dell'archivio), M30–M33: media ponderata
/// dei fondi e del contratto, quote che non tornano, ripieghi, parti a sé, scelta esplicita «Multiramo», copia
/// dalla scheda prodotto, archivio (andata e ritorno, lettura tollerante, archivio senza fondi con i numeri di
/// prima). Chiamate da `ProvaCalcoliMultiramo.esegui`. I conti attesi sono fatti a mano nei commenti.
enum ProvaCalcoliMultiramoFondi {
    static func esegui(_ verifica: VerificaCalcoli) {
        mediaPonderata(verifica)
        casiParticolari(verifica)
        sceltaEScheda(verifica)
        archivio(verifica)
    }

    /// Multiramo in essere da 100.000 €: 40% in gestione separata al 3,0% lordo (trattenuto 1,3, consolidata),
    /// fondi «Azionario» 35% al 6,0% con costi 2,0% e «Obbligazionario» 25% al 4,0% con costi 1,0%.
    private static func conDueFondi(_ modifica: (inout Posizione) -> Void = { _ in }) -> Posizione {
        AiutiProva.posizione("Multiramo a due fondi", .investimento, 100_000) {
            $0.tipologia = "Polizza multiramo"
            $0.totaleVersato = 100_000
            $0.quotaGestioneSeparata = 40
            $0.rendimentoGestione = 3.0
            $0.trattenuto = 1.3
            $0.minimoGarantito = 0
            $0.consolidamento = true
            $0.aliquotaFiscale = 26
            $0.fondi = [FondoMultiramo(nome: "Azionario", quota: 35, rendimento: 6.0, costo: 2.0),
                        FondoMultiramo(nome: "Obbligazionario", quota: 25, rendimento: 4.0, costo: 1.0)]
            modifica(&$0)
        }
    }

    // MARK: - M30: la media ponderata

    private static func mediaPonderata(_ verifica: VerificaCalcoli) {
        let p = conDueFondi()
        verifica.vero("M30 Con l'elenco dei fondi: multiramo a due parti", p.multiramo && p.multiramoDivisa && p.fondiIndicati)
        // Pesi dentro la parte in fondi: 35 / 60 e 25 / 60
        verifica("M30 Peso dell'Azionario 35 / 60", p.pesiFondi.first ?? -1, 0.583333, tolleranza: 0.0001)
        // Fondi: (35 × 6,0 + 25 × 4,0) / 60 = (210 + 100) / 60 = 5,1667%
        verifica("M30 Rendimento dei fondi (35 × 6 + 25 × 4) / 60", p.lordoFondi(), 5.166667, tolleranza: 0.0001)
        // Contratto: 0,40 × 3,0 + 0,35 × 6,0 + 0,25 × 4,0 = 1,2 + 2,1 + 1,0 = 4,30%
        verifica("M30 Media ponderata 0,40 × 3 + 0,35 × 6 + 0,25 × 4", p.rendimentoLordoComposto, 4.3, tolleranza: 0.0001)
        // Costi dei fondi: (35 × 2,0 + 25 × 1,0) / 60 = 95 / 60 = 1,5833%
        verifica("M30 Costi dei fondi (35 × 2 + 25 × 1) / 60", p.costoParteFondi, 1.583333, tolleranza: 0.0001)
        // Costo del contratto: 0,4 × 1,3 + 0,6 × 1,5833 = 0,52 + 0,95 = 1,47%
        verifica("M30 Costo complessivo 0,4 × 1,3 + 0,6 × 1,5833", p.costoComplessivo ?? -1, 1.47, tolleranza: 0.0001)
        // Netto dei fondi 5,1667 − 1,5833 = 3,5833; netto del contratto 0,4 × 1,7 + 0,6 × 3,5833 = 0,68 + 2,15 = 2,83
        verifica("M30 Netto composto 0,4 × 1,7 + 0,6 × 3,5833", p.rendimentoNettoComposto, 2.83, tolleranza: 0.0001)
        verifica.vero("M30 Quote 40 + 35 + 25 = 100%: nessun avviso", abs((p.totaleQuote ?? 0) - 100) < 1e-9 && !p.quoteDaRivedere)
        let testo = p.testoMediaPonderata
        verifica.vero("M30 Testo della media: «40% × 3,00% + 35% × 6,00% + 25% × 4,00% = 4,30%»",
                      testo.contains("40% × 3,00%") && testo.contains("35% × 6,00%") && testo.contains("25% × 4,00%")
                      && testo.hasSuffix("= 4,30%"))
        let voci = p.vociMediaPonderata
        verifica("M30 Voci della media: la gestione e due fondi", Double(voci.count), 3)
        verifica("M30 Le voci tornano al composto", voci.reduce(0) { $0 + $1.quota * $1.rendimento } / 100, 4.3, tolleranza: 0.0001)

        // La proiezione è quella di una multiramo con un solo tasso dei fondi uguale alla media
        let unico = conDueFondi { $0.fondi = nil; $0.rendimentoFondi = 310.0 / 60; $0.costoFondi = 95.0 / 60 }
        let a = MotoreProiezione.calcola(ParametriProiezione(posizione: p, orizzonteCliente: 10))
        let b = MotoreProiezione.calcola(ParametriProiezione(posizione: unico, orizzonteCliente: 10))
        verifica("M30 Proiezione: come un tasso unico dei fondi al 5,1667%", a.netto, b.netto, tolleranza: 0.01)
        verifica("M30 Proiezione: rendimento equivalente 4,30%",
                 ParametriProiezione(posizione: p).rendimentoEquivalente, 4.3, tolleranza: 0.0001)

        // Le parti a sé non portano l'elenco: i fondi come Ramo III al tasso medio
        let fondi = MotoreMultiramo.posizioneFondi(p)
        verifica.vero("M30 Parte in fondi: niente elenco, non è una multiramo", fondi.fondi == nil && !fondi.multiramo)
        verifica("M30 Parte in fondi: rendimento medio", fondi.rendimentoAtteso ?? -1, 5.166667, tolleranza: 0.0001)
        verifica("M30 Parte in fondi: 60.000 €", fondi.valore, 60_000, tolleranza: 0.01)
    }

    // MARK: - M31: quote che non tornano, ripieghi

    private static func casiParticolari(_ verifica: VerificaCalcoli) {
        // Quote 40 + 30 + 20 = 90%: avviso; dentro i fondi pesano 30 / 50 e 20 / 50.
        // Fondi (30 × 6 + 20 × 4) / 50 = 260 / 50 = 5,2%; contratto 0,4 × 3 + 0,6 × 5,2 = 4,32%
        let corta = conDueFondi {
            $0.fondi = [FondoMultiramo(nome: "A", quota: 30, rendimento: 6.0), FondoMultiramo(nome: "B", quota: 20, rendimento: 4.0)]
        }
        verifica.vero("M31 Quote al 90%: da rivedere", corta.quoteDaRivedere && abs((corta.totaleQuote ?? 0) - 90) < 1e-9)
        verifica("M31 Quote al 90%: fondi in proporzione (30 × 6 + 20 × 4) / 50", corta.lordoFondi(), 5.2, tolleranza: 0.0001)
        verifica("M31 Quote al 90%: contratto 0,4 × 3 + 0,6 × 5,2", corta.rendimentoLordoComposto, 4.32, tolleranza: 0.0001)

        // Un fondo senza rendimento usa quello dei fondi (4%): (30 × 6 + 30 × 4) / 60 = 5%
        let senzaUno = conDueFondi {
            $0.fondi = [FondoMultiramo(nome: "A", quota: 30, rendimento: 6.0), FondoMultiramo(nome: "B", quota: 30)]
            $0.rendimentoFondi = 4
        }
        verifica("M31 Fondo senza rendimento: quello dei fondi (30 × 6 + 30 × 4) / 60", senzaUno.lordoFondi(), 5, tolleranza: 0.0001)
        // Nessun costo nei fondi: i costi della parte sono il costo annuo del contratto (2,3%)
        verifica("M31 Fondi senza costi: il costo annuo del contratto",
                 conDueFondi { $0.fondi = senzaUno.fondi; $0.costoAnnuo = 2.3 }.costoParteFondi, 2.3, tolleranza: 0.0001)
        // Fondi senza quote: pesano uguale, (6 + 4) / 2 = 5%
        let senzaQuote = conDueFondi {
            $0.fondi = [FondoMultiramo(nome: "A", rendimento: 6.0), FondoMultiramo(nome: "B", rendimento: 4.0)]
        }
        verifica("M31 Fondi senza quote: pesano uguale", senzaQuote.lordoFondi(), 5, tolleranza: 0.0001)
        verifica.vero("M31 Fondi senza quote: nessun controllo delle quote", senzaQuote.totaleQuote == nil && !senzaQuote.quoteDaRivedere)
        // Nessun rendimento nei fondi: si ricava dal complessivo come prima, (4,5 − 0,4 × 3) / 0,6 = 5,5%
        let ricavato = conDueFondi {
            $0.fondi = [FondoMultiramo(nome: "A", quota: 60)]
            $0.rendimentoAtteso = 4.5
        }
        verifica("M31 Fondi senza rendimenti: ricavato dal complessivo", ricavato.lordoFondi(), 5.5, tolleranza: 0.0001)
        verifica.vero("M31 Fondi senza rendimenti: tra le ipotesi", ricavato.rendimentiPartiStimati)
        // Basta l'elenco perché la multiramo sia divisa
        let soloElenco = AiutiProva.posizione("Solo elenco", .investimento, 10_000) {
            $0.tipologia = "Polizza multiramo"; $0.quotaGestioneSeparata = 50
            $0.fondi = [FondoMultiramo(nome: "Unico", quota: 50, rendimento: 5)]
        }
        verifica.vero("M31 Solo l'elenco dei fondi: divisa", soloElenco.multiramoDivisa)
    }

    // MARK: - M32: scelta esplicita «Multiramo» e scheda prodotto

    private static func sceltaEScheda(_ verifica: VerificaCalcoli) {
        // Una tipologia che il testo non riconosce: con la scelta è una multiramo, ed è una polizza vita
        let scelta = AiutiProva.posizione("Piano Valore", .investimento, 10_000) {
            $0.tipologia = "Piano Valore"; $0.sceltaMultiramo = true
        }
        verifica.vero("M32 Scelta «Multiramo»: multiramo anche senza la parola", scelta.multiramo && scelta.regime == .polizza)
        let gestione = MotoreMultiramo.posizioneGestione(scelta)
        verifica.vero("M32 Scelta «Multiramo»: la parte in gestione separata è un Ramo I, non una multiramo",
                      gestione.sceltaMultiramo == nil && !gestione.multiramo && gestione.gestioneSeparata)
        let spenta = AiutiProva.posizione("Multiramo spenta", .investimento, 10_000) {
            $0.tipologia = "Polizza multiramo"; $0.sceltaMultiramo = false
        }
        verifica.vero("M32 Scelta spenta: non è una multiramo anche se la tipologia lo dice", !spenta.multiramo)
        let testo = AiutiProva.posizione("Dal testo", .investimento, 10_000) { $0.tipologia = "Polizza multiramo" }
        verifica.vero("M32 Senza scelta: riconosciuta dal testo come prima", testo.multiramo && testo.sceltaMultiramo == nil)

        // Dalla scheda: i fondi interni uno per uno nella proposta, con la media uguale al tasso unico
        var s = Prodotto(nome: "Multiramo a due fondi", canale: .indipendente, area: .investimento)
        s.tipologia = "Polizza multiramo"
        var gs = ComponenteContratto(tipo: .gestioneSeparata, nome: "GS", quota: 40)
        gs.rendimentoAtteso = 3; gs.trattenuto = 1.3
        var f1 = ComponenteContratto(tipo: .fondoInterno, nome: "Azionario", quota: 35)
        f1.rendimentoAtteso = 6; f1.commissione = 1.5; f1.costiSottostanti = 0.5
        var f2 = ComponenteContratto(tipo: .fondoInterno, nome: "Obbligazionario", quota: 25)
        f2.rendimentoAtteso = 4; f2.commissione = 0.8; f2.costiSottostanti = 0.2
        var c = CondizioniContratto()
        c.componenti = [gs, f1, f2]
        s.condizioni = c
        let proposta = s.proposta(per: "prova")
        verifica("M32 Dalla scheda: due fondi nella proposta", Double(proposta.fondi?.count ?? 0), 2)
        verifica.vero("M32 Dalla scheda: nomi e quote dei fondi",
                      proposta.fondi?.map(\.nome) == ["Azionario", "Obbligazionario"]
                      && abs((proposta.fondi?.first?.quota ?? 0) - 35) < 1e-9 && abs((proposta.fondi?.last?.quota ?? 0) - 25) < 1e-9)
        // Lo stesso numero con o senza l'elenco: (35 × 6 + 25 × 4) / 60 = 5,1667%; costi (35 × 2 + 25 × 1) / 60 = 1,5833%
        verifica("M32 Dalla scheda: media dei fondi", proposta.lordoFondi(), 5.166667, tolleranza: 0.0001)
        verifica("M32 Dalla scheda: il tasso unico è la stessa media", proposta.rendimentoFondi ?? -1, 5.166667, tolleranza: 0.0001)
        verifica("M32 Dalla scheda: costi dei fondi", proposta.costoParteFondi, 1.583333, tolleranza: 0.0001)
        // Il campo della scheda prevale sulle parti: i fondi copiati non portano il loro rendimento, la media resta 5%
        var conCampo = s
        conCampo.rendimentoFondi = 5
        let propostaCampo = conCampo.proposta(per: "prova")
        verifica.vero("M32 Campo della scheda: fondi copiati senza rendimento",
                      propostaCampo.fondi?.count == 2 && propostaCampo.fondi?.allSatisfy { $0.rendimento == nil } == true)
        verifica("M32 Campo della scheda: rendimento dei fondi 5%", propostaCampo.lordoFondi(), 5, tolleranza: 0.0001)
        // In essere i fondi della scheda non si copiano (come la quota): le quote di oggi sono sull'estratto conto
        var inEssere = Posizione(clienteId: "prova", canale: .indipendente, stato: .inEssere, area: .investimento, nome: "In essere")
        inEssere.tipologia = "Polizza multiramo"
        MotoreMultiramo.applica(s, a: &inEssere)
        verifica.vero("M32 In essere: i fondi della scheda non si copiano", inEssere.fondi == nil)
    }

    // MARK: - M33: archivio

    private static func archivio(_ verifica: VerificaCalcoli) {
        // Andata e ritorno con l'elenco e la scelta esplicita
        var p = conDueFondi { $0.sceltaMultiramo = true }
        p.creataIl = AiutiProva.data(2026, 1, 15)
        let letta = (try? Archivio.codificatore.encode(p)).flatMap { try? Archivio.decodificatore.decode(Posizione.self, from: $0) }
        verifica.vero("M33 Archivio: fondi e scelta identici dopo andata e ritorno", letta == p && letta?.fondi?.count == 2)

        // Lettura tollerante: un fondo malformato non fa scartare la posizione
        if let dati = try? Archivio.codificatore.encode(p),
           var oggetto = (try? JSONSerialization.jsonObject(with: dati)) as? [String: Any] {
            let malformati: [Any] = [["nome": 5, "quota": "trenta"] as [String: Any], 3,
                                     ["nome": "Buono", "quota": 30, "rendimento": 5] as [String: Any]]
            oggetto["fondi"] = malformati
            let tollerata = (try? JSONSerialization.data(withJSONObject: oggetto))
                .flatMap { try? Archivio.decodificatore.decode(Posizione.self, from: $0) }
            verifica.vero("M33 Fondi malformati: la posizione si legge, tre fondi",
                          tollerata != nil && tollerata?.fondi?.count == 3 && tollerata?.fondi?.last?.rendimento == 5
                          && tollerata?.fondi?.first?.quota == nil)
        } else {
            verifica.vero("M33 Fondi malformati: JSON di prova", false)
        }

        // Un archivio di prima (versione 24, senza fondi né scelta): gli stessi numeri di prima (quelli di M15)
        var vecchia = AiutiProva.posizione("Marco v24", .investimento, 62_000) {
            $0.tipologia = "Polizza multiramo (Ramo I e Ramo III)"
            $0.quotaGestioneSeparata = 40; $0.rendimentoGestione = 3.0; $0.trattenuto = 1.3; $0.minimoGarantito = 0
            $0.consolidamento = true; $0.rendimentoFondi = 5.5; $0.costoFondi = 2.3
        }
        vecchia.creataIl = AiutiProva.data(2025, 6, 1)
        let grezzo = (try? Archivio.codificatore.encode(vecchia)).flatMap { try? JSONSerialization.jsonObject(with: $0) }
        let oggetto = (grezzo as? [String: Any]) ?? [:]
        verifica.vero("M33 Archivio 24: il JSON non ha i campi nuovi", !oggetto.isEmpty && oggetto["fondi"] == nil && oggetto["sceltaMultiramo"] == nil)
        let letta24 = (try? JSONSerialization.data(withJSONObject: oggetto)).flatMap { try? Archivio.decodificatore.decode(Posizione.self, from: $0) }
        if let m = letta24 {
            verifica.vero("M33 Archivio 24: letta, divisa, senza fondi", m.multiramoDivisa && m.fondi == nil && m.sceltaMultiramo == nil)
            verifica("M33 Archivio 24: fondi al 5,5% come prima", m.lordoFondi(), 5.5, tolleranza: 0.0001)
            verifica("M33 Archivio 24: composto 0,4 × 3 + 0,6 × 5,5 = 4,5%", m.rendimentoLordoComposto, 4.5, tolleranza: 0.0001)
            verifica("M33 Archivio 24: netto composto 0,4 × 1,7 + 0,6 × 3,2 = 2,6%", m.rendimentoNettoComposto, 2.6, tolleranza: 0.0001)
            verifica("M33 Archivio 24: costo composto 0,4 × 1,3 + 0,6 × 2,3 = 1,9%", m.costoComposto, 1.9, tolleranza: 0.0001)
            let prima = MotoreProiezione.calcola(ParametriProiezione(posizione: vecchia, orizzonteCliente: 10))
            let dopo = MotoreProiezione.calcola(ParametriProiezione(posizione: m, orizzonteCliente: 10))
            verifica("M33 Archivio 24: la stessa proiezione", dopo.netto, prima.netto, tolleranza: 0.01)
        } else {
            verifica.vero("M33 Archivio 24: la posizione si legge", false)
        }
    }
}
