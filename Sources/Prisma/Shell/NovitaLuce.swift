import SwiftUI

// Le 29 novità della versione «Luce» (Design/template-luce-specifica.md §1.1): 15 «davanti al cliente» e 14 «per il
// tuo lavoro», nell'ordine del pannello «✦ Novità» (`NOV15` e `NOVL` del template). Le voci di Orizzonte non ci sono
// più nel pannello (decisione 116). Ogni voce porta all'app che la ospita (o ospiterà): le funzioni che arrivano nei
// giri successivi aprono quell'app con l'avviso «arriva con un prossimo aggiornamento» (§0.7). Le frasi seguono le
// decisioni del §0.5 (decisione 19): mai una promessa che Prisma non mantiene.

/// Una novità di Luce.
enum NovitaLuce: String, CaseIterable, Identifiable {
    // Davanti al cliente · 15
    case prismaCliente, territorio, lettera, film, disegna, settimanaAnno, palestra, prismaLuce, capsula, traguardi
    case giocoRischio, giornataPensione, lanciaAnno, valoreConsulente, realtaAumentata
    // Per il tuo lavoro · 14
    case stanotte, propostaDaSola, compilaDaSolo, dopoLaFirma, sinistro, trovaLaPagina, smontaggio, radar, campagne
    case nuovoCliente, passaparola, imprenditori, notaVocale, speseScadenze

    /// La versione delle novità: `Impostazioni.novitaViste` la ricorda dopo la prima apertura.
    static let versione = "luce"

    /// I due gruppi del pannello.
    enum Gruppo: String, CaseIterable, Identifiable {
        case davantiAlCliente, lavoro

        var id: String { rawValue }

        var titolo: String {
            switch self {
            case .davantiAlCliente: return "Davanti al cliente"
            case .lavoro: return "Per il tuo lavoro"
            }
        }

        /// Le voci del gruppo, nell'ordine del pannello.
        var voci: [NovitaLuce] { NovitaLuce.allCases.filter { $0.gruppo == self } }
    }

    var id: String { rawValue }

    var gruppo: Gruppo {
        switch self {
        case .prismaCliente, .territorio, .lettera, .film, .disegna, .settimanaAnno, .palestra, .prismaLuce, .capsula,
             .traguardi, .giocoRischio, .giornataPensione, .lanciaAnno, .valoreConsulente, .realtaAumentata:
            return .davantiAlCliente
        default:
            return .lavoro
        }
    }

    var titolo: String {
        switch self {
        case .prismaCliente: return "Il Prisma del cliente"
        case .territorio: return "Il tuo territorio"
        case .lettera: return "La lettera dal futuro"
        case .film: return "Il film del piano"
        case .disegna: return "Disegna il tuo futuro"
        case .settimanaAnno: return "La tua settimana, il tuo anno"
        case .palestra: return "La palestra della trattativa"
        case .prismaLuce: return "Il prisma di luce"
        case .capsula: return "La capsula del tempo"
        case .traguardi: return "I traguardi festeggiati"
        case .giocoRischio: return "Il gioco del rischio"
        case .giornataPensione: return "Una giornata della pensione"
        case .lanciaAnno: return "Lancia l’anno"
        case .valoreConsulente: return "Quanto vale avermi accanto"
        case .realtaAumentata: return "La realtà aumentata"
        case .stanotte: return "Stanotte Prisma ha lavorato"
        case .propostaDaSola: return "La proposta si costruisce da sola"
        case .compilaDaSolo: return "Compila da solo"
        case .dopoLaFirma: return "Le pratiche dopo la firma"
        case .sinistro: return "Il sinistro come una spedizione"
        case .trovaLaPagina: return "Trova la pagina"
        case .smontaggio: return "Lo smontaggio"
        case .radar: return "Il radar del portafoglio"
        case .campagne: return "Le campagne"
        case .nuovoCliente: return "Nuovo cliente in 10 secondi"
        case .passaparola: return "Potenziali clienti e passaparola"
        case .imprenditori: return "I clienti imprenditori"
        case .notaVocale: return "La nota vocale"
        case .speseScadenze: return "Chilometri, spese e scadenze"
        }
    }

    /// La frase sotto il titolo. Dove il template prometteva un'uscita che le decisioni escludono (WhatsApp, lo stato
    /// «in tempo reale» per il cliente) la frase dice ciò che Prisma fa davvero (decisioni 1, 10 e 19).
    var frase: String {
        switch self {
        case .prismaCliente: return "La sua app personale, in un file"
        case .territorio: return "I clienti come luci, la crescita, il giro"
        case .lettera: return "Da sé stesso a 67 anni"
        case .film: return "Il piano in un breve video, da mostrare"
        case .disegna: return "Lo scarabocchio diventa un piano"
        case .settimanaAnno: return "Trenta secondi ogni lunedì"
        case .palestra: return "Vera fa il cliente difficile"
        case .prismaLuce: return "Il patrimonio in raggi di luce"
        case .capsula: return "Un messaggio sigillato fino al traguardo"
        case .traguardi: return "Il momento giusto, già pronto"
        case .giocoRischio: return "Il profilo vissuto, non dichiarato"
        case .giornataPensione: return "Il divario diventa una vita"
        case .lanciaAnno: return "Due vite affiancate"
        case .valoreConsulente: return "Il tuo lavoro, in cifre"
        case .realtaAumentata: return "Il patrimonio sul tavolo"
        case .stanotte: return "La mattina trovi tutto pronto"
        case .propostaDaSola: return "Dal bisogno alla proposta in un minuto"
        case .compilaDaSolo: return "I moduli si riempiono da soli"
        case .dopoLaFirma: return "Cosa manca, pratica per pratica"
        case .sinistro: return "A che punto è, e l’aggiornamento per il cliente"
        case .trovaLaPagina: return "La risposta, con la frase evidenziata"
        case .smontaggio: return "I costi nascosti cerchiati sul documento"
        case .radar: return "Chi si è allontanato dal suo modello"
        case .campagne: return "Lo stesso bisogno, tanti clienti, un tocco"
        case .nuovoCliente: return "La carta d’identità compila l’anagrafica"
        case .passaparola: return "Il percorso e l’albero di chi presenta chi"
        case .imprenditori: return "L’azienda accanto al titolare"
        case .notaVocale: return "Tra una visita e l’altra, dall’iPhone"
        case .speseScadenze: return "Per te e per il commercialista"
        }
    }

    var glifo: GlifoLuce {
        switch self {
        case .prismaCliente: return .prisma
        case .territorio: return .mappa
        case .lettera: return .lettera
        case .film: return .film
        case .disegna: return .disegna
        case .settimanaAnno: return .storia
        case .palestra: return .palestra
        case .prismaLuce: return .luce
        case .capsula: return .capsula
        case .traguardi: return .festa
        case .giocoRischio: return .rischio
        case .giornataPensione: return .giornata
        case .lanciaAnno: return .dadi
        case .valoreConsulente: return .valore
        case .realtaAumentata: return .ar
        case .stanotte: return .notte
        case .propostaDaSola: return .proposta
        case .compilaDaSolo: return .modulo
        case .dopoLaFirma: return .cartella
        case .sinistro: return .sinistro
        case .trovaLaPagina: return .libro
        case .smontaggio: return .lente
        case .radar: return .radar
        case .campagne: return .campagna
        case .nuovoCliente: return .scan
        case .passaparola: return .albero
        case .imprenditori: return .azienda
        case .notaVocale: return .voce
        case .speseScadenze: return .auto
        }
    }

    var colore: Color { glifo.colore }

    /// L'esperienza della Sala che la voce apre (nil per le voci delle altre app).
    var esperienza: EsperienzaSala? { EsperienzaSala.allCases.first { $0.novita == self } }

    /// L'app che ospita (o ospiterà) la funzione. nil per le due voci che vivono sopra la scrivania («La tua settimana»
    /// e «Stanotte»): la voce porta alla scrivania.
    var app: AppPrisma? {
        if esperienza != nil { return .sala }
        switch self {
        case .territorio: return .territorio
        case .palestra, .speseScadenze: return .studio
        case .traguardi, .campagne: return .messaggi
        case .propostaDaSola, .compilaDaSolo, .dopoLaFirma, .sinistro: return .pratiche
        case .trovaLaPagina: return .biblioteca
        case .smontaggio, .radar: return .posizioni
        case .nuovoCliente, .passaparola, .imprenditori: return .clienti
        case .notaVocale: return .incontri
        default: return nil
        }
    }

    /// La scheda di Pratiche su cui si apre la voce.
    var schedaPratiche: SchedaPratiche? {
        switch self {
        case .propostaDaSola: return .proposta
        case .compilaDaSolo: return .moduli
        case .dopoLaFirma: return .dopoLaFirma
        case .sinistro: return .sinistri
        default: return nil
        }
    }

    /// Dove vivrà la funzione, con le parole dell'interfaccia (per l'avviso e per VoiceOver).
    var dove: String {
        if esperienza != nil { return "Sala › \(titolo)" }
        switch self {
        case .territorio: return "Territorio › Oggi"
        case .settimanaAnno: return "la scrivania, «La tua settimana»"
        case .palestra: return "Studio › Palestra"
        case .traguardi: return "Messaggi"
        case .stanotte: return "la scrivania, «Stanotte»"
        case .propostaDaSola: return "Pratiche › Proposta"
        case .compilaDaSolo: return "Pratiche › Moduli"
        case .dopoLaFirma: return "Pratiche › Dopo la firma"
        case .sinistro: return "Pratiche › Sinistri"
        case .trovaLaPagina: return "Biblioteca"
        case .smontaggio: return "Posizioni › Smontaggio"
        case .radar: return "Posizioni › Radar"
        case .campagne: return "Messaggi › Campagne"
        case .nuovoCliente: return "Clienti › Nuovo cliente"
        case .passaparola: return "Clienti › Passaparola"
        case .imprenditori: return "Clienti, nel dossier: L’azienda"
        case .notaVocale: return "Incontri › Nota dall’iPhone"
        case .speseScadenze: return "Studio › Spese"
        default: return titolo
        }
    }

    /// Vero per le funzioni già in Prisma. Nel giro 1 (le fondamenta) nessuna delle 29 è ancora fatta: le voci portano
    /// all'app che le ospiterà. Ogni giro accende qui le sue.
    var disponibile: Bool {
        switch self {
        case .radar, .smontaggio: return true   // giro 2: Posizioni › Radar e Smontaggio
        case .dopoLaFirma: return true          // giro 3: Pratiche › Dopo la firma
        case .propostaDaSola: return true        // giro 3: Pratiche › Proposta
        case .prismaLuce, .disegna: return true  // giro 4: Sala › Il prisma di luce, Disegna il tuo futuro
        case .giornataPensione, .giocoRischio: return true   // giro 4: Sala › Una giornata della pensione, Il gioco del rischio
        case .settimanaAnno, .traguardi: return true          // giro 5: la tua settimana e il tuo anno, i traguardi festeggiati
        case .palestra: return true              // giro 5: Studio › Palestra, la palestra della trattativa
        case .trovaLaPagina: return true         // giro 6: Biblioteca, «Trova la pagina»
        case .imprenditori: return true          // giro 7: Clienti › dossier › L'azienda
        case .lettera, .lanciaAnno, .valoreConsulente: return true   // giro 8: Sala › la lettera, Lancia l'anno, Quanto vale
        case .speseScadenze: return true         // giro 9: Studio › Spese, chilometri, spese e scadenze
        case .compilaDaSolo: return true         // giro 10: Pratiche › Moduli, «Compila da solo»
        case .passaparola, .campagne: return true   // giro 12: Clienti › Potenziali e Passaparola, Messaggi › Campagne
        default: return false
        }
    }

    /// L'avviso per una funzione che arriva più avanti (nil se c'è già, o se l'app stessa lo dice: le esperienze della
    /// Sala, Territorio, Pratiche e Biblioteca hanno la loro schermata «in arrivo»).
    var avvisoInArrivo: String? {
        guard !disponibile else { return nil }
        if let app, [.sala, .territorio, .pratiche, .biblioteca].contains(app) { return nil }
        return "«\(titolo)» arriva con un prossimo aggiornamento: vivrà in \(dove)."
    }
}
