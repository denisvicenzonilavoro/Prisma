import Foundation

// Impostazioni › Sala («Luce» giro 8, Design/template-luce-specifica.md §4.3.5, §4.4.5, decisioni 56, 58 e 69): ciò che
// le esperienze «senza uscita» della Sala non possono inventare e che scrive l'utente.
// - Gli eventi di «Lancia l'anno» (`EventoAnno`): probabilità annua CON LA FONTE, importo o mesi di reddito, rischio
//   coperto. Prisma porta con sé solo la risorsa Risorse/Sala/eventi-anno.json, con «testi di prova» e nessuna
//   probabilità: un evento senza probabilità non esce mai a caso (si gioca solo a mano). Niente si scarica (decisione 69).
// - Le avvertenze della lettera, di Lancia l'anno e di «Quanto vale avermi accanto», e il titolo del valore: finché
//   l'utente non le scrive resta il segnaposto dichiarato «Stime basate su ipotesi, non garanzie di risultato.»
//   (decisione 56) e il titolo di prova del template, segnato «testo di prova» (decisione 58).
// Versione 27 dell'archivio, letta con tolleranza: un evento illeggibile si scarta, gli altri restano.

/// Un evento di un anno di «Lancia l'anno» (§4.3.5): una carta che il consulente gioca a mano o che esce a caso
/// solo se l'utente ne ha dato la probabilità con la fonte.
struct EventoAnno: Codable, Identifiable, Hashable {
    /// Che cosa fa l'evento al patrimonio.
    enum Effetto: String, Codable, CaseIterable {
        /// Una spesa imprevista (euro di oggi).
        case spesa
        /// Mesi di reddito netto che mancano (mesi × reddito netto / 12, meno l'indennizzo stimato se coperto).
        case mancatoReddito
        /// Un'entrata (euro di oggi).
        case entrata

        var nome: String {
            switch self {
            case .spesa: return "Spesa"
            case .mancatoReddito: return "Mesi senza reddito"
            case .entrata: return "Entrata"
            }
        }
    }

    /// Il filo della carta: rosso, arancio o verde (`TONE` del template).
    enum Tono: String, Codable, CaseIterable {
        case rosso, arancio, verde
    }

    var id: String
    var titolo: String
    var effetto: Effetto
    /// Euro di oggi della spesa o dell'entrata; nil = da scrivere (la carta si gioca senza cifra).
    var importo: Double?
    /// Mesi di reddito che mancano (solo `mancatoReddito`).
    var mesi: Int?
    /// Il rischio che una polizza può coprire (`TutelaRischio`): con la copertura la carta dice da dove viene l'aiuto.
    var rischio: RischioCoperto?
    var tono: Tono
    /// Probabilità annua (0…1) scritta dall'utente con la fonte. nil = l'evento non esce mai a caso.
    var probabilita: Double?
    /// Da dove viene la probabilità (ISTAT, INAIL, INPS…): senza fonte la probabilità non vale.
    var fonte: String?
    /// L'età in cui può capitare (facoltative).
    var etaMinima: Int?
    var etaMassima: Int?
    /// SOLO DATI DI PROVA (dalla risorsa, le cifre del template): valgono solo con i clienti di prova, segnate così.
    var importoDiProva: Double?

    init(id: String, titolo: String, effetto: Effetto, importo: Double? = nil, mesi: Int? = nil, rischio: RischioCoperto? = nil,
         tono: Tono, probabilita: Double? = nil, fonte: String? = nil, etaMinima: Int? = nil, etaMassima: Int? = nil,
         importoDiProva: Double? = nil) {
        self.id = id
        self.titolo = titolo
        self.effetto = effetto
        self.importo = importo
        self.mesi = mesi
        self.rischio = rischio
        self.tono = tono
        self.probabilita = probabilita
        self.fonte = fonte
        self.etaMinima = etaMinima
        self.etaMassima = etaMassima
        self.importoDiProva = importoDiProva
    }

    private enum CodingKeys: String, CodingKey {
        case id, titolo, effetto, importo, mesi, rischio, tono, probabilita, fonte, etaMinima, etaMassima, importoDiProva
    }

    /// Lettura tollerante: id e titolo sono necessari; una probabilità fuori da 0…1, un importo negativo o
    /// illeggibile diventano «non scritti».
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func leggi<T: Decodable>(_ k: CodingKeys) -> T? { (try? c.decodeIfPresent(T.self, forKey: k)) ?? nil }
        id = try c.decode(String.self, forKey: .id)
        titolo = try c.decode(String.self, forKey: .titolo)
        effetto = leggi(.effetto) ?? .spesa
        importo = (leggi(.importo) as Double?).flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        mesi = (leggi(.mesi) as Int?).flatMap { $0 > 0 ? $0 : nil }
        rischio = leggi(.rischio)
        tono = leggi(.tono) ?? .arancio
        probabilita = (leggi(.probabilita) as Double?).flatMap { $0.isFinite && $0 > 0 && $0 <= 1 ? $0 : nil }
        fonte = (leggi(.fonte) as String?).flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        etaMinima = leggi(.etaMinima)
        etaMassima = leggi(.etaMassima)
        importoDiProva = (leggi(.importoDiProva) as Double?).flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
    }

    /// Può uscire a caso: probabilità E fonte scritte dall'utente (decisione 69).
    var esceACaso: Bool { probabilita != nil && fonte != nil }
}

/// Impostazioni › Sala (`Impostazioni.sala`, versione 27, «Luce» giro 8).
struct ImpostazioniSala: Codable, Equatable {
    /// Gli eventi scritti o corretti dall'utente: sostituiscono la voce della risorsa con lo stesso id, gli altri si
    /// aggiungono. Vuoto finché l'utente non ne scrive uno.
    var eventiAnno: [EventoAnno] = []
    /// Quanti anni dura una partita di Lancia l'anno (nil = 12, come il template; 0 = fino alla pensione).
    var anniPartita: Int?
    /// Le avvertenze approvate dall'utente (nil = il segnaposto dichiarato della decisione 56).
    var avvertenzaLettera: String?
    var avvertenzaLancia: String?
    var avvertenzaValore: String?
    /// Il titolo di «Quanto vale avermi accanto», con {valore} e {periodo} (nil = il testo di prova del template).
    var titoloValore: String?
    /// «Lo scatto può comprendere la stanza» (Impostazioni › Sala, «Luce» giro 16, decisione 27): spento di base; acceso,
    /// sull'iPad del tavolo si può mandare anche la foto con la stanza, con la conferma a ogni scatto.
    var scattoConStanza = false

    init() {}

    /// Il segnaposto dichiarato della decisione 56: resta finché l'utente non scrive l'avvertenza.
    static let segnapostoAvvertenza = "Stime basate su ipotesi, non garanzie di risultato."
    /// Il titolo del template, «testo di prova» finché l'utente non lo approva o lo riscrive.
    static let titoloValoreDiProva = "In {periodo} il nostro lavoro vale circa {valore}."
    /// Anni della partita senza una scelta dell'utente (il template).
    static let anniPartitaPredefiniti = 12
    static let anniPartitaMassimi = 40

    private enum CodingKeys: String, CodingKey {
        case eventiAnno, anniPartita, avvertenzaLettera, avvertenzaLancia, avvertenzaValore, titoloValore
        case scattoConStanza
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func testo(_ k: CodingKeys) -> String? {
            ((try? c.decodeIfPresent(String.self, forKey: k)) ?? nil)
                .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        }
        eventiAnno = ((try? c.decodeIfPresent(ElencoTollerante<EventoAnno>.self, forKey: .eventiAnno)) ?? nil)?.elementi ?? []
        anniPartita = ((try? c.decodeIfPresent(Int.self, forKey: .anniPartita)) ?? nil)
            .flatMap { $0 >= 0 && $0 <= Self.anniPartitaMassimi ? $0 : nil }
        avvertenzaLettera = testo(.avvertenzaLettera)
        avvertenzaLancia = testo(.avvertenzaLancia)
        avvertenzaValore = testo(.avvertenzaValore)
        titoloValore = testo(.titoloValore)
        scattoConStanza = ((try? c.decodeIfPresent(Bool.self, forKey: .scattoConStanza)) ?? nil) ?? false
    }

    /// Un testo dell'utente o il segnaposto, con il segno se è il segnaposto.
    static func avvertenza(_ scritta: String?) -> (testo: String, segnaposto: Bool) {
        if let scritta { return (scritta, false) }
        return (segnapostoAvvertenza, true)
    }
}
