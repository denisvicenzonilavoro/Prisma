import Foundation

/// L'elenco dei documenti di un cliente (app Documenti e scheda Documenti del dossier) senza rifare tutto a ogni disegno.
/// Prima ogni lettera della ricerca, ogni clic su un documento e ogni pagina sfogliata nel PDF rifacevano le voci (stato
/// e confronti di ogni documento) e i gruppi, e con una ricerca di almeno 3 lettere rileggevano dal disco e
/// normalizzavano tutte le pagine dei documenti che non la avevano nel titolo o nei dati. Ora:
/// - voci e gruppi restano finché non cambiano i dati dei calcoli, i documenti in lettura, il cliente, i filtri o la
///   ricerca (le chiavi dicono tutto ciò da cui dipendono);
/// - le pagine originali vanno a `MotoreDocumenti.elenco` solo per i documenti in cui una pagina può avere tutte le
///   parole cercate: per gli altri l'esito è lo stesso (nessuna pagina le ha), senza normalizzare, e il loro testo resta
///   piegato (`PaginePiegate`) per i tasti successivi, senza rileggerlo dal disco.
/// Vive nella vista (`@State`): un cliente alla volta, e le pagine piegate si lasciano quando la ricerca si svuota.
final class MemoriaElencoDocumenti {
    private var chiaveVoci: String?
    private var vociTenute: [MotoreDocumenti.Voce] = []
    private var chiaveGruppi: String?
    private var gruppiTenuti: [MotoreDocumenti.Gruppo] = []
    private let piegate = PaginePiegate()
    /// La versione dei dati delle pagine piegate: rilette dopo una nuova lettura del documento.
    private var versionePagine: Int?

    /// Le voci del cliente: dipendono dai dati dei calcoli (documenti, clienti, posizioni, prodotti) e dai documenti in
    /// lettura. Da chiamare in un body: legge (e così osserva) ciò da cui dipendono.
    static func chiaveDelleVoci(_ stato: StatoShell, cliente: String) -> String {
        let inLettura = stato.documentiInLettura.sorted().joined(separator: ",")
        return "\(stato.versioneCalcoli)|\(cliente)|\(inLettura)"
    }

    /// I gruppi: le voci più i filtri e il testo cercato (in fondo: può contenere qualunque carattere).
    static func chiaveDeiGruppi(voci: String, filtro: MotoreDocumenti.Filtro) -> String {
        "\(voci)|\(filtro.raccolta.rawValue)|\(filtro.categoria?.rawValue ?? "-")|\(filtro.canale?.rawValue ?? "-")|\(filtro.testo)"
    }

    func voci(_ chiave: String, calcola: () -> [MotoreDocumenti.Voce]) -> [MotoreDocumenti.Voce] {
        if chiave == chiaveVoci { return vociTenute }
        vociTenute = calcola()
        chiaveVoci = chiave
        return vociTenute
    }

    func gruppi(_ chiave: String, calcola: () -> [MotoreDocumenti.Gruppo]) -> [MotoreDocumenti.Gruppo] {
        if chiave == chiaveGruppi { return gruppiTenuti }
        gruppiTenuti = calcola()
        chiaveGruppi = chiave
        return gruppiTenuti
    }

    /// Senza ricerca nel testo (meno di 3 caratteri, come in `MotoreDocumenti.elenco`) le pagine piegate non servono.
    func lasciaPagineSeServe(_ filtro: MotoreDocumenti.Filtro) {
        if filtro.testo.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 { piegate.svuota() }
    }

    /// Le parole che `MotoreDocumenti.elenco` cerca nelle pagine (normalizzate come lì).
    static func paroleCercate(_ filtro: MotoreDocumenti.Filtro) -> [String] {
        MotoreDocumenti.normale(filtro.testo).split(separator: " ").map(String.init)
    }

    /// Il testo di un documento per `MotoreDocumenti.elenco`: le pagine originali se almeno una pagina piegata contiene
    /// tutte le parole cercate, altrimenti nessuna (l'elenco non lo avrebbe trovato comunque: una parola di lettere e
    /// cifre nel testo normalizzato c'è anche in quello solo piegato).
    func pagine(_ d: Documento, cercate: [String], stato: StatoShell) -> [String] {
        guard !cercate.isEmpty else { return stato.testoDocumento(d, memorizza: false) }
        let versione = stato.versioneCalcoli
        if versionePagine != versione {
            piegate.svuota()
            versionePagine = versione
        }
        func tutte(_ pagina: String) -> Bool { cercate.allSatisfy { TestoPiegato.contiene(pagina, $0) } }
        if let tenute = piegate.tenute(d.id) {
            return tenute.contains(where: tutte) ? stato.testoDocumento(d, memorizza: false) : []
        }
        // Una pagina alla volta, fino alla prima che le ha tutte; letto tutto senza trovarle, resta piegato
        let originali = stato.testoDocumento(d, memorizza: false)
        var lette: [String] = []
        lette.reserveCapacity(originali.count)
        for originale in originali {
            let pagina = TestoPiegato.piega(originale)
            if tutte(pagina) { return originali }
            lette.append(pagina)
        }
        piegate.tieni(d.id, lette)
        return []
    }
}
