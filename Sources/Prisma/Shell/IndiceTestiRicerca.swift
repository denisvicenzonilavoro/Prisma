import Foundation

// La ricerca a parole senza rifare il lavoro a ogni tasto (fluidità, «scattante e veloce»). Prima ogni tasto nel
// pannello ⌘K rifaceva i candidati di tutto l'archivio (con le date scritte di ogni appuntamento, nota, attività…),
// rileggeva dal disco il testo di ogni documento e lo confrontava pagina per pagina con le regole della lingua
// (maiuscole e accenti). Ora:
// - i testi si «piegano» una volta (minuscole, senza accenti, con le stesse regole di `MotoreRicerca.contiene`) e poi
//   una parola si cerca byte per byte;
// - i candidati e le pagine piegate stanno in un indice (`IndiceRicerca`) che il pannello tiene finché è aperto e i
//   dati che legge non cambiano (`MemoriaIndiceRicerca`): i tasti dopo il primo non rifanno i candidati e non
//   rileggono i documenti che non hanno le parole (quelli che costavano di più: letti fino in fondo);
// - le pagine si leggono solo quando le parole non sono nel titolo e nei dati, e una alla volta fino alle parole;
// - le pagine piegate restano entro un tetto di memoria (`PaginePiegate`): oltre, si rileggono come prima;
// - l'estratto (la riga attorno alla parola) si scrive solo per i risultati mostrati, e per i primi cinque di un
//   gruppo non si ordinano tutti i risultati.

/// Testi piegati: minuscole e senza accenti, poi il confronto byte per byte (UTF-8).
enum TestoPiegato {
    /// Minuscole e senza accenti, con le regole di `MotoreRicerca.contiene` (italiano). Contiguo in UTF-8: le ricerche
    /// dopo non lo convertono più.
    static func piega(_ s: String) -> String {
        var p = s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Formati.italiano)
        p.makeContiguousUTF8()
        return p
    }

    /// `ago` dentro `pagliaio`, tutti e due già piegati. Vuoto non si trova mai, come con `range(of:)`.
    static func contiene(_ pagliaio: String, _ ago: String) -> Bool {
        guard !ago.isEmpty, pagliaio.utf8.count >= ago.utf8.count else { return false }
        var h = pagliaio
        var n = ago
        return h.withUTF8 { testo in n.withUTF8 { parola in cerca(parola, in: testo) } }
    }

    /// `s` comincia con `prefisso` (tutti e due già piegati). Vuoto no, come con `range(of:options:.anchored)`.
    static func iniziaCon(_ s: String, _ prefisso: String) -> Bool {
        !prefisso.isEmpty && s.utf8.starts(with: prefisso.utf8)
    }

    /// La parola nel testo, byte per byte: in UTF-8 una sequenza valida si trova solo all'inizio di un carattere.
    private static func cerca(_ parola: UnsafeBufferPointer<UInt8>, in testo: UnsafeBufferPointer<UInt8>) -> Bool {
        let n = parola.count
        guard n > 0, testo.count >= n, let p = parola.baseAddress, let t = testo.baseAddress else { return false }
        let primo = p[0]
        let ultimo = testo.count - n
        var i = 0
        while i <= ultimo {
            if t[i] == primo && memcmp(t + i, p, n) == 0 { return true }
            i += 1
        }
        return false
    }
}

/// Il testo piegato delle pagine, per documento, entro un tetto di memoria (come la memoria dei testi di StatoShell):
/// oltre il tetto le pagine si rileggono e si piegano ogni volta, così un archivio grande non resta tutto in memoria.
/// Si tengono solo i documenti letti fino in fondo senza trovare le parole: sono quelli che a ogni tasto costavano di
/// più. Chi trova le parole nelle prime pagine si ferma lì (e al tasto dopo rifà lo stesso poco lavoro).
final class PaginePiegate {
    /// Byte UTF-8 del testo piegato tenuto (circa 4 milioni di caratteri).
    static let tetto = MemoriaTesti.limiteCaratteri

    private var piegate: [String: [String]] = [:]
    private var usati = 0

    /// Le pagine piegate di un documento (`chiave`), se ci sono già.
    func tenute(_ chiave: String) -> [String]? { piegate[chiave] }

    /// Tiene le pagine piegate (tutte) di un documento, se stanno sotto il tetto.
    func tieni(_ chiave: String, _ pagine: [String]) {
        guard piegate[chiave] == nil else { return }
        let misura = pagine.reduce(0) { $0 + $1.utf8.count }
        guard usati + misura <= Self.tetto else { return }
        piegate[chiave] = pagine
        usati += misura
    }

    func svuota() {
        guard usati > 0 || !piegate.isEmpty else { return }
        piegate = [:]
        usati = 0
    }
}

/// Da dove vengono le pagine di un candidato: un documento del cliente o (sul Mac) uno della Biblioteca.
enum FontePagineRicerca {
    case documento(Documento)
    case biblioteca(DocumentoBiblioteca)

    var chiave: String {
        switch self {
        case .documento(let d): return "d·" + d.id
        case .biblioteca(let d): return "b·" + d.id
        }
    }

    /// Il testo originale, pagina per pagina (dalla memoria dei testi o dal disco, senza tenerlo).
    func originali(_ stato: StatoShell) -> [String] {
        switch self {
        case .documento(let d): return stato.testoDocumento(d, memorizza: false)
        case .biblioteca(let d): return stato.trovaPagina.pagine(d)
        }
    }
}

/// Un candidato della ricerca: il risultato, i campi (etichetta, valore) in cui cercare e, per i documenti, da dove
/// leggere le pagine. Classe: le forme piegate di titolo, campi e dettaglio si preparano la prima volta che servono e
/// restano per i tasti successivi (dentro `IndiceRicerca`).
final class CandidatoRicerca {
    let risultato: RisultatoRicerca
    let campi: [(String, String)]
    let fonte: FontePagineRicerca?

    private var titolo: String?
    private var iniziali: [String]?
    private var dettaglio: String?
    private var valori: [String?]

    init(_ risultato: RisultatoRicerca, campi: [(String, String)] = [], fonte: FontePagineRicerca? = nil) {
        self.risultato = risultato
        self.campi = campi
        self.fonte = fonte
        valori = Array(repeating: nil, count: campi.count)
    }

    var titoloPiegato: String {
        if let t = titolo { return t }
        let t = TestoPiegato.piega(risultato.titolo)
        titolo = t
        return t
    }

    /// Le parole del titolo (divise come in `MotoreRicerca.punteggio`), piegate.
    var inizialiPiegate: [String] {
        if let i = iniziali { return i }
        let i = risultato.titolo.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map { TestoPiegato.piega(String($0)) }
        iniziali = i
        return i
    }

    var dettaglioPiegato: String {
        if let d = dettaglio { return d }
        let d = TestoPiegato.piega(risultato.dettaglio)
        dettaglio = d
        return d
    }

    /// Il valore del campo `i`, piegato.
    func valorePiegato(_ i: Int) -> String {
        if let v = valori[i] { return v }
        let v = TestoPiegato.piega(campi[i].1)
        valori[i] = v
        return v
    }
}

/// I candidati della ricerca a parole per una versione dei dati, con le pagine piegate dei documenti.
final class IndiceRicerca {
    /// Ciò da cui dipendono i candidati: i dati dei calcoli (clienti, posizioni, documenti e il loro testo, agenda,
    /// attività, obiettivi, incontri, prodotti), le note, la modalità cliente (le azioni) e i documenti della Biblioteca.
    struct Firma: Equatable {
        let calcoli: Int
        let note: Int
        let modoCliente: Bool
        let biblioteca: [DocumentoBiblioteca]
    }

    let firma: Firma
    let candidati: [GruppoRicerca: [CandidatoRicerca]]
    let pagine = PaginePiegate()

    init(firma: Firma, candidati: [GruppoRicerca: [CandidatoRicerca]]) {
        self.firma = firma
        self.candidati = candidati
    }
}

/// L'indice tenuto dal pannello ⌘K finché è aperto: si rifà solo quando cambia la sua firma.
final class MemoriaIndiceRicerca {
    private var ultimo: IndiceRicerca?

    func indice(_ stato: StatoShell) -> IndiceRicerca {
        let firma = MotoreRicerca.firmaIndice(stato)
        if let i = ultimo, i.firma == firma { return i }
        // Il vecchio si lascia prima di fare il nuovo: mai due archivi di candidati in memoria
        ultimo = nil
        let nuovo = MotoreRicerca.nuovoIndice(stato, firma: firma)
        ultimo = nuovo
        return nuovo
    }
}
