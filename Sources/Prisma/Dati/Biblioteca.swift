import Foundation

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.5.2, «Luce» giro 6). I documenti della
// Biblioteca sono gli stessi testi di «Il codice in tasca» (Vera, funzione 13: `TestoNorma`, Shell/BibliotecaVera.swift):
// un solo elenco in Prisma/Biblioteca/biblioteca.json, accanto all'archivio, con i PDF e il testo pagina per pagina
// (`<id>.txt`, pagine separate da `LetturaDocumenti.separatorePagine`). Entra nei backup con la cartella dell'archivio
// (a meno che l'utente non la escluda); non va in «Prisma ovunque», che non porta i documenti. L'indice delle parole è
// derivato e sta solo in memoria (Motori/MotoreBiblioteca.swift).

/// Un documento della Biblioteca: condizioni, set informativi, KID, note informative, circolari, normativa.
typealias DocumentoBiblioteca = TestoNorma

enum GenereBiblioteca: String, Codable, CaseIterable, Identifiable {
    case condizioni, notaInformativa, kid, setInformativo, circolare, normativa, altro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .condizioni: return "Condizioni"
        case .notaInformativa: return "Nota informativa"
        case .kid: return "KID"
        case .setInformativo: return "Set informativo"
        case .circolare: return "Circolare"
        case .normativa: return "Normativa"
        case .altro: return "Altro"
        }
    }

    /// Normativa e circolari non sono di un canale.
    var diRiferimento: Bool { self == .normativa || self == .circolare }
}

extension TestoNorma {
    /// Il genere da mostrare: i testi di «Il codice in tasca» (senza genere) sono normativa.
    var genereVisto: GenereBiblioteca { genere ?? .normativa }

    /// Genere e canale proposti da Prisma e non ancora confermati dall'utente.
    var daConfermare: Bool { genere != nil && confermato == false }

    /// Il numero di pagine (i testi di prima: l'ultima pagina in cui comincia un articolo).
    var numeroPagine: Int { pagine ?? articoli.map(\.pagina).max() ?? 0 }

    /// Un PDF illeggibile (nessuna pagina con testo): resta nella barra, ma non ci si cerca dentro.
    var illeggibile: Bool { pagine != nil && testo == nil }

    /// Il PDF originale (nil per i fac-simile di prova, che sono solo testo).
    var ePDF: Bool { file.lowercased().hasSuffix(".pdf") }

    /// La prima parte del titolo, per la chip della risposta («Piano rivalutabile»).
    var titoloBreve: String {
        titolo.components(separatedBy: " · ").first?.trimmingCharacters(in: .whitespaces) ?? titolo
    }

    /// «Condizioni · 38 pagine».
    var dettaglio: String {
        let n = numeroPagine
        let pagine = n == 1 ? "1 pagina" : "\(n) pagine"
        return daConfermare ? "\(genereVisto.nome) da confermare · \(pagine)" : "\(genereVisto.nome) · \(pagine)"
    }
}

/// Le proposte di Prisma per un documento appena letto (l'utente conferma).
enum PropostaBiblioteca {
    /// Il genere dalle parole del testo (prime pagine).
    static func genere(_ testo: String) -> GenereBiblioteca {
        let t = testo.lowercased()
        if t.contains("documento contenente le informazioni chiave") || t.contains("key information document") { return .kid }
        if t.contains("set informativo") { return .setInformativo }
        if t.contains("nota informativa") { return .notaInformativa }
        if t.contains("condizioni di assicurazione") || t.contains("condizioni generali") || t.contains("condizioni contrattuali") { return .condizioni }
        if t.contains("circolare") { return .circolare }
        if t.contains("decreto") || t.contains("d.lgs") || t.contains("regolamento") || t.contains("gazzetta ufficiale") { return .normativa }
        return .altro
    }

    /// Il canale: Alleanza se il testo la nomina; nessuno per normativa e circolari; altrimenti l'indipendente.
    static func canale(_ testo: String, genere: GenereBiblioteca) -> Canale? {
        if genere.diRiferimento { return nil }
        return testo.lowercased().contains("alleanza") ? .alleanza : .indipendente
    }

    /// L'edizione se il testo la scrive («Edizione 03/2026», «ed. 03/2026», «aggiornato al …»).
    static func edizione(_ testo: String) -> String? {
        let schema = #"(?i)\b(edizione|ed\.|aggiornat[oa] al)\s+([0-9]{1,2}[/.][0-9]{4}|[0-9]{1,2}[/.][0-9]{1,2}[/.][0-9]{2,4}|[0-9]{1,2}° ?[a-z]+ [0-9]{4}|[a-z]+ [0-9]{4})"#
        guard let r = testo.range(of: schema, options: .regularExpression) else { return nil }
        return String(testo[r]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// I sei fac-simile di prova (Sources/Prisma/Risorse/Biblioteca/): testi scritti apposta per Prisma, mai copiati da
/// condizioni o norme vere. Si caricano solo con i clienti di prova (Impostazioni › Strumenti) e si tolgono con loro;
/// le istantanee e le prove li usano in memoria.
enum EsempiBiblioteca {
    struct Esempio {
        let risorsa: String
        let titolo: String
        let genere: GenereBiblioteca
        let canale: Canale?
        let edizione: String
    }

    static let elenco: [Esempio] = [
        Esempio(risorsa: "piano-rivalutabile", titolo: "Piano rivalutabile · Condizioni di assicurazione", genere: .condizioni,
                canale: .alleanza, edizione: "fac-simile, ed. 01/2026"),
        Esempio(risorsa: "temporanea-caso-morte", titolo: "Temporanea caso morte · Condizioni di assicurazione", genere: .condizioni,
                canale: .alleanza, edizione: "fac-simile, ed. 01/2026"),
        Esempio(risorsa: "fondo-pensione-aperto", titolo: "Fondo pensione aperto · Nota informativa", genere: .notaInformativa,
                canale: .indipendente, edizione: "fac-simile, ed. 03/2026"),
        Esempio(risorsa: "fondo-azionario-globale", titolo: "Fondo azionario globale · KID", genere: .kid,
                canale: .indipendente, edizione: "fac-simile, ed. 02/2026"),
        Esempio(risorsa: "circolare-previdenza", titolo: "Circolare · Previdenza complementare", genere: .circolare,
                canale: nil, edizione: "fac-simile, ed. 05/2024"),
        Esempio(risorsa: "normativa-riferimento", titolo: "Normativa di riferimento · Raccolta", genere: .normativa,
                canale: nil, edizione: "fac-simile, ed. 09/2025"),
    ]

    /// Le pagine di un fac-simile dal pacchetto dell'app.
    static func pagine(_ risorsa: String) -> [String]? {
        guard let url = Risorse.cartella?.appendingPathComponent("Biblioteca/\(risorsa).txt"),
              let t = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return t.components(separatedBy: LetturaDocumenti.separatorePagine)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
