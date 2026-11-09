import Foundation

// I testi del Prisma del cliente («Luce» giro 15, §2.1): titoli, motivi delle voci spente, il testo del messaggio che
// accompagna il file (mai la password), la frase della scadenza e le note. Funzioni pure, provate da
// `ProvaCalcoliPrismaCliente`.

enum TestiPrismaCliente {
    /// Il titolo della colonna (decisione 19: senza l'HTML acceso non è un'app).
    static let titolo = "Il suo piano, in un file protetto."
    static let etichettaContenuto = "Cosa c'è dentro"
    static let etichettaPassword = "Password"
    static let etichettaScadenza = "Si può aprire fino al"
    static let prepara = "Prepara il file"
    static let manda = "Manda con Messaggi"
    static let condividi = "Condividi…"
    static let unAltra = "Un'altra"
    static let accendiUnaVoce = "Accendi almeno una voce"
    static let preparo = "Preparo il file…"
    static let notaFondo = "Il contenuto è quello dei prospetti approvati, con le stesse avvertenze. Il file è protetto con la password: dilla a voce, mai nello stesso messaggio."
    /// La frase onesta della scadenza (decisione 6): un invito, non un blocco.
    static let fraseScadenza = "Dopo questa data il file invita a chiedere una copia aggiornata."
    static let avvertenzeNonScelte = "Le avvertenze del file non sono ancora scelte: c'è il segnaposto › Impostazioni"
    static let filmAParte = "Il film del tuo piano: te l'ho mandato a parte."
    static let lineaIndicativa = "Dopo la pensione la linea è indicativa: ne parliamo insieme"
    static let datiDiProva = "dati di prova"
    static let html = "Prepara anche il file per il browser (sperimentale)"

    /// La prima parola del nome («Giulia Rossi» → «Giulia»).
    static func nomeBattesimo(_ c: Cliente) -> String {
        let n = c.nome.split(separator: " ").first.map(String.init) ?? c.nome
        return n.isEmpty ? "cliente" : n
    }

    /// Il testo introduttivo con il nome.
    static func introduzione(_ nome: String, html: Bool) -> String {
        let forma = html ? "un file che \(nome) apre sul telefono" : "un PDF che \(nome) apre sul telefono o sul computer"
        return "Prepari \(forma) con la password. Dentro ci sono i suoi obiettivi, il futuro da esplorare, la lettera e "
            + "quello che scegli qui sotto. Nessun server: lo mandi tu, e resta suo."
    }

    // MARK: Motivi delle voci spente

    static func senzaObiettivi(_ nome: String) -> String { "\(nome) non ha ancora obiettivi con un importo nel dossier" }
    static let senzaLettera = "La lettera non è pronta: serve un piano (una proposta o un versamento previsto) e la data di nascita"
    static let senzaFilm = "Il film non è ancora esportato: esportalo nella Sala"
    static let senzaLuce = "Il prisma di luce ha bisogno di almeno una posizione in essere"
    static let senzaGiornata = "La giornata della pensione ha bisogno della data di nascita e delle ipotesi di previdenza"
    static let senzaSinistro = "Nessun sinistro con gli aggiornamenti per il cliente accesi"
    static let senzaPosizioni = "Nessuna posizione in essere"
    static func troppoAvanti(_ nome: String) -> String { "\(nome) ha già superato le età del cursore (58-70 anni)" }

    /// Il collegamento sotto il motivo (nil = nessuno).
    static func collegamento(_ v: VoceFilePrisma) -> String? {
        switch v {
        case .obiettivi: return "Aggiungi un obiettivo ›"
        case .lineaVita: return "Completa l’anagrafica ›"
        case .lettera: return "Apri la lettera ›"
        case .film: return "Apri il film ›"
        case .luce: return "Apri il prisma di luce ›"
        case .giornata: return "Apri la giornata ›"
        case .sinistro: return "Apri i sinistri ›"
        case .posizioni: return nil
        }
    }

    // MARK: Il messaggio e il nome del file

    /// Il testo che accompagna il file in Messaggi: **mai la password** (la si dice a voce).
    static func messaggio(_ c: Cliente) -> String {
        "Ciao \(nomeBattesimo(c)), ti mando il tuo Prisma: la password te la dico a voce."
    }

    static func oggetto(_ c: Cliente) -> String { "Il tuo Prisma" }

    /// «Il-Prisma-di-Giulia»: solo il nome di battesimo, senza caratteri che il Finder o il telefono non amano.
    static func baseNomeFile(_ nome: String) -> String {
        let pulito = nome.folding(options: [.diacriticInsensitive], locale: Formati.italiano)
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        return "Il-Prisma-di-" + (pulito.isEmpty ? "cliente" : pulito)
    }

    /// «✓ Il-Prisma-di-Giulia.pdf · 1,4 MB · protetto con la password».
    static func pronto(nomeFile: String, byte: Int64) -> String {
        "✓ \(nomeFile) · \(dimensione(byte)) · protetto con la password"
    }

    static func dimensione(_ byte: Int64) -> String {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB]
        f.countStyle = .file
        return f.string(fromByteCount: byte)
    }

    /// «File già dato il 3 novembre 2026».
    static func giaDato(_ d: Date) -> String { "File già dato il \(Formati.dataEstesa.string(from: d))" }

    static let nuovaDallUltimo = "nuova dall'ultimo file"

    /// «I risparmi bastano oltre i 90 anni» o «I risparmi bastano fino a 84 anni».
    static func frasePensione(esaurimento: Int?, etaFine: Int) -> String {
        guard let e = esaurimento else { return "I risparmi bastano oltre i \(etaFine) anni" }
        return "I risparmi bastano fino a \(e) anni"
    }

    /// «Hai già messo da parte il 40%» (decisione 81).
    static func fraseObiettivo(_ quota: Double) -> String {
        "Hai già messo da parte il \(Int((min(max(quota, 0), 1) * 100).rounded()))%"
    }

    /// Il piede: «Denis Vicenzoni · il tuo consulente», o «Il tuo consulente» senza nome.
    static func consulente(_ firma: String?) -> String {
        guard let f = firma?.trimmingCharacters(in: .whitespacesAndNewlines), !f.isEmpty else { return "Il tuo consulente" }
        return "\(f) · il tuo consulente"
    }

    /// «Questo Prisma era valido fino al 5 novembre 2027. Chiedi a Denis una copia aggiornata.»
    static func scaduto(_ fino: Date, consulente: String) -> String {
        var chi = "al tuo consulente"
        if consulente.hasSuffix(" · il tuo consulente"), let primo = consulente.split(separator: " ").first {
            chi = "a \(primo)"
        }
        return "Questo Prisma era valido fino al \(Formati.dataEstesa.string(from: fino)). Chiedi \(chi) una copia aggiornata."
    }

    /// La traccia nel dossier (mai la password né il contenuto): «PDF protetto · obiettivi, linea della vita, lettera».
    static func descrizioneUscita(_ voci: [VoceFilePrisma], html: Bool) -> String {
        let nomi = voci.map { v -> String in
            switch v {
            case .obiettivi: return "obiettivi"
            case .lineaVita: return "linea della vita"
            case .lettera: return "lettera"
            case .film: return "film"
            case .luce: return "prisma di luce"
            case .giornata: return "giornata della pensione"
            case .sinistro: return "sinistro"
            case .posizioni: return "posizioni"
            }
        }
        let forma = html ? "PDF e file per il browser protetti" : "PDF protetto"
        return nomi.isEmpty ? forma : "\(forma) · \(nomi.joined(separator: ", "))"
    }
}
