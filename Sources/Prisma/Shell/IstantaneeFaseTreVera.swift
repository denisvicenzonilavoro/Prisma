#if os(macOS)
import Foundation

/// Le istantanee della fase 3 di Vera (Design/template-vera.html), chiare e scure, senza Qwen: le promesse con il
/// semaforo, la seconda lettura di una proposta scritta a mano, il confronto tra la polizza di Laura e la proposta
/// (fac-simile), cosa non copre la polizza fac-simile e il resoconto dell'incontro di Giulia da firmare.
extension Istantanee {
    nonisolated static var sceneFaseTreVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("492-vera-promesse", { s in preparaPromesse(s) }),
            ("492-vera-promesse-scuro", { s in preparaPromesse(s) }),
            ("493-vera-seconda-lettura", { s in preparaSecondaLettura(s) }),
            ("493-vera-seconda-lettura-scuro", { s in preparaSecondaLettura(s) }),
            ("494-vera-differenze", { s in preparaFacSimili(s); _ = s.chiediDifferenze("Confronta la polizza di Laura con la proposta", chiave: "laura"); s.apri(.vera) }),
            ("494-vera-differenze-scuro", { s in preparaFacSimili(s); _ = s.chiediDifferenze("Confronta la polizza di Laura con la proposta", chiave: "laura"); s.apri(.vera) }),
            ("495-vera-cosa-non-copre", { s in preparaFacSimili(s); _ = s.chiediCopertura("Cosa non copre la polizza di Laura?", chiave: "laura"); s.apri(.vera) }),
            ("495-vera-cosa-non-copre-scuro", { s in preparaFacSimili(s); _ = s.chiediCopertura("Cosa non copre la polizza di Laura?", chiave: "laura"); s.apri(.vera) }),
            ("496-vera-resoconto", { s in preparaResoconto(s) }),
            ("496-vera-resoconto-scuro", { s in preparaResoconto(s) }),
        ]
    }

    nonisolated private static func base(_ s: StatoShell, cliente: String) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = cliente
        s.veraPortafoglio = false
    }

    nonisolated static func preparaPromesse(_ s: StatoShell) {
        base(s, cliente: "marco")
        let cal = Calendar.current
        let oggi = Date()
        s.dati.note.append(Nota(clienteId: "marco", titolo: "Incontro con Marco",
                                testo: "Ne parliamo dopo l'estate. Le mando il confronto per gli studi di Tommaso entro venerdì, così lo guarda anche Elena."))
        s.dati.note.append(Nota(clienteId: "laura", titolo: "Telefonata con Laura",
                                testo: "Grazie per la chiacchierata. La richiamo dopo il 15 per parlare della pensione a 60 anni."))
        var ritardo = PromessaCliente(clienteId: "sofia", testo: "Mandare a Sofia il riepilogo della rivalutabile", frase: "Le mando il riepilogo della rivalutabile.",
                                      fonte: .nota, fonteId: "nota-sofia-istantanea", fonteEtichetta: "dalla telefonata di ottobre",
                                      scadenza: cal.date(byAdding: .day, value: -8, to: oggi), quando: nil)
        ritardo.creataIl = cal.date(byAdding: .day, value: -15, to: oggi) ?? oggi
        s.dati.promesse.append(ritardo)
        s.veraPortafoglio = true
        _ = s.chiediPromesse("Tutte le mie promesse", chiave: VeraPortafoglio.chiave)
        s.apri(.vera)
    }

    nonisolated static func preparaSecondaLettura(_ s: StatoShell) {
        base(s, cliente: "laura")
        _ = s.chiediSecondaLettura("Rileggi: Gentile Laura, come concordato le propongo un piano di accumulo: con un versamento di 750 € al mese e un rendimento garantito del 4%, tra 11 anni potrà contare sul capitale che le serve, senza rischi.",
                                   chiave: "laura")
        s.apri(.vera)
    }

    nonisolated static func preparaFacSimili(_ s: StatoShell) {
        base(s, cliente: "laura")
        let (a, b) = FacSimiliVera.documenti(cliente: "laura")
        s.dati.documenti += [a, b]
        s.memorizzaTesto(a.id, FacSimiliVera.polizza)
        s.memorizzaTesto(b.id, FacSimiliVera.proposta)
    }

    nonisolated static func preparaResoconto(_ s: StatoShell) {
        base(s, cliente: "giulia")
        _ = s.chiediResoconto("Il resoconto dell'incontro con Giulia", chiave: "giulia")
        s.apri(.vera)
    }
}
#endif
