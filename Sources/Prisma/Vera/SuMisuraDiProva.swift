import Foundation

/// Dati di prova di «Vera su misura» e dei motori (fase 5), per istantanee e prove: dichiarati, mai mostrati come veri.
/// Le frasi parlano dei clienti fac-simile del template (Giulia, Marco, Laura, Sofia); le percentuali dell'esame e la
/// curva sono numeri di esempio (la pagina scrive «Numeri di esempio»).
enum SuMisuraDiProva {
    /// 12 coppie domanda-risposta approvate (dati di prova).
    static func esempi(oggi: Date = Date()) -> [EsempioVera] {
        let coppie: [(String, String, ModalitaVera)] = [
            ("Giulia Rossi vuole versare 550 € al mese per la casa: come glielo spiego?",
             "Le direi così: con 550 € al mese mette da parte la quota per l'anticipo senza toccare la liquidità di emergenza. Le cifre esatte gliele mostro dal prospetto di Prisma.", .lavoro),
            ("Scrivimi una mail cordiale per ricordare a Marco Bianchi l'appuntamento di giovedì.",
             "Gentile Marco, le ricordo il nostro appuntamento di giovedì. Porti pure le domande che le sono venute in mente: le vediamo insieme. A presto, Denis", .conversazione),
            ("Cos'è una gestione separata, in parole semplici?",
             "È un fondo dentro la polizza che investe soprattutto in obbligazioni e consolida ogni anno il rendimento ottenuto: quello che è acquisito non si perde. Il rendimento non è garantito in anticipo.", .conversazione),
            ("Laura Moretti chiede se può riscattare in anticipo: cosa le dico?",
             "Le direi che il riscatto è possibile, ma nei primi anni ci sono dei costi: prima di decidere guardiamo insieme il valore di riscatto aggiornato nella scheda della polizza.", .lavoro),
            ("Riassumi in tre righe l'incontro con Sofia Romano.",
             "Sofia vuole lasciare qualcosa alla figlia Marta con calma. Preferisce soluzioni semplici. Ci rivediamo dopo che avrà parlato con lei.", .lavoro),
            ("Come spiego il rischio a un cliente prudente?",
             "Partirei da una domanda: quanto le darebbe fastidio vedere il valore scendere per qualche mese? Poi mostrerei con un esempio che il rischio si sceglie in base al tempo che ha davanti.", .conversazione),
            ("Marco vuole proteggere la famiglia con 30 € al mese: da dove parto?",
             "Partirei dalla protezione del reddito: con 30 € al mese si può coprire il rischio più grave per la famiglia. Poi vediamo con il prospetto di Prisma quali coperture entrano nel budget.", .lavoro),
            ("Traduci in inglese: «la ringrazio per la fiducia».",
             "«Thank you for your trust.»", .conversazione),
            ("Giulia ha paura di perdere i soldi: come la rassicuro senza promettere niente?",
             "Le direi che capisco la preoccupazione e che nessuno può promettere un risultato. Le mostrerei però come è costruito il piano: una parte prudente e una che lavora nel tempo, che possiamo rivedere insieme.", .lavoro),
            ("Che differenza c'è tra un PIP e un fondo aperto?",
             "Il PIP è un piano previdenziale costruito su una polizza; il fondo aperto è gestito da banche o compagnie. Entrambi hanno i vantaggi fiscali della previdenza complementare: cambiano costi e flessibilità.", .conversazione),
            ("Laura vuole più flessibilità: come imposto il prossimo incontro?",
             "Partirei dagli obiettivi che sono cambiati, poi le proporrei due strade: una più flessibile e una più stabile, con i pro e i contro di ciascuna. Le cifre le prepara Prisma.", .lavoro),
            ("Dammi tre idee per un messaggio di auguri ai clienti.",
             "1) Un augurio semplice con un ricordo dell'anno insieme. 2) Un pensiero sui progetti del nuovo anno. 3) Un grazie per la fiducia, con l'invito a sentirsi a gennaio.", .conversazione),
        ]
        return coppie.enumerated().map { i, c in
            EsempioVera(domanda: c.0, risposta: c.1, data: oggi.addingTimeInterval(Double(i - coppie.count) * 86_400), modalita: c.2)
        }
    }

    /// La versione fac-simile di novembre con esame 71% → 84% e la curva sintetica (numeri di esempio).
    static func versioni(oggi: Date = Date(), superata: Bool = true) -> [VersioneSuMisura] {
        var v = VersioneSuMisura(id: SuMisuraVera.nomeModello(oggi), creataIl: oggi, modelloDiPartenza: MotoreLocale.modelloPredefinito,
                                 esempi: 12, stato: superata ? .inUso : .nonSuperata)
        v.esame = EsitoEsameBreve(domande: 80, percentualeAttuale: superata ? 71 : 80, percentualeNuova: superata ? 84 : 76,
                                  cifreInventateAttuale: 2, cifreInventateNuova: superata ? 0 : 3, fattoIl: oggi, superato: superata)
        v.curva = curva()
        v.diProva = true
        return [v]
    }

    /// Una curva dell'errore che scende, con un po' di rumore (sintetica).
    static func curva() -> [Double] {
        (0..<SuMisuraVera.puntiCurva).map { i in
            let x = Double(i) / Double(SuMisuraVera.puntiCurva - 1)
            return 0.55 + 1.6 * exp(-3.2 * x) + 0.04 * sin(Double(i) * 1.7)
        }
    }

    /// Le 7 richieste del template, nella corsia dove vanno davvero con il modello Apple spento, con i tempi del template
    /// (indicativi, dati di prova): un secondo dopo l'altra, a partire da `oggi`.
    static func corsie(oggi: Date = Date()) -> [(testo: String, corsia: CorsiaVera, secondi: Double, quando: Date)] {
        let righe: [(String, CorsiaVera, Double)] = [
            ("Apri l'agenda di domani", .regole, 0.3),
            ("Che documento è questo?", .qwen, 0.6),
            ("Confronta i due KID di Giulia", .qwen, 6),
            ("Segna 24 km per oggi", .regole, 0.2),
            ("Prepara la proposta per Laura", .qwen, 9),
            ("Chi devo chiamare oggi?", .regole, 0.5),
            ("Spiegami la rivalutabile di Sofia", .qwen, 5),
        ]
        return righe.enumerated().map { i, r in (r.0, r.1, r.2, oggi.addingTimeInterval(Double(i))) }
    }

    /// Un esempio con un nome che l'archivio non conosce (per l'anteprima: «da guardare»), dati di prova.
    static func esempioDaGuardare(oggi: Date = Date()) -> EsempioVera {
        EsempioVera(domanda: "Ho sentito Carla Neri per la polizza della figlia: come le rispondo?",
                    risposta: "Le direi che guardiamo insieme le condizioni prima di decidere.", data: oggi, modalita: .lavoro)
    }
}

