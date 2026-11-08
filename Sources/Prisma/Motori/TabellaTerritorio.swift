import Foundation

/// L'esito del riconoscimento di un comune in un testo libero o in una sede.
enum EsitoComune: Equatable {
    case trovato(ComuneTabella)
    /// Più comuni con quel nome: le sigle delle province (in ordine).
    case ambiguo([String])
    case nonTrovato
    case vuoto
    /// Sede fuori dall'Italia (`SedeFiscale.nazione` non vuota né «IT»/«Italia»).
    case estero
}

/// Lettura delle tabelle del Territorio dalle risorse (`Risorse/Territorio/`) e riconoscimento del comune
/// («Luce» giro 11, decisioni 20 e 70). Tutto locale: niente geocodifica in rete, niente CAP (il CAP nel testo
/// dell'indirizzo si ignora), niente codici catastali. Pura: nessuna cache qui (la tiene `StatoTerritorio`).
enum TabellaTerritorio {
    static let fileComuni = "Territorio/comuni.json"
    static func cartellaConfini() -> String { "Territorio/confini" }

    // MARK: Lettura

    /// Una riga di `comuni.json`, a colonne: codice, nome, provincia, lat, lon, raggioKm (e «istat», facoltativa e ignorata).
    private struct RigaComune: Decodable {
        let comune: ComuneTabella

        init(from decoder: Decoder) throws {
            var c = try decoder.unkeyedContainer()
            let codice = try c.decode(String.self)
            let nome = try c.decode(String.self)
            let provincia = try c.decode(String.self)
            let lat = try c.decode(Double.self)
            let lon = try c.decode(Double.self)
            let raggio = try c.decode(Double.self)
            let centro = Coordinata(lat: lat, lon: lon)
            guard !codice.isEmpty, !nome.isEmpty, centro.valida, raggio.isFinite, raggio >= 0 else {
                throw DecodingError.dataCorrupted(.init(codingPath: c.codingPath, debugDescription: "Riga del comune non valida"))
            }
            comune = ComuneTabella(codice: codice, nome: nome, provincia: provincia.uppercased(), centro: centro, raggioKm: raggio)
        }
    }

    private struct FileComuni: Decodable {
        let formato: String
        let diProva: Bool?
        let fonte: String?
        let licenza: String?
        let edizione: String?
        let comuni: ElencoTollerante<RigaComune>
    }

    /// Decodifica `comuni.json` (nil se non è una tabella dei comuni di Prisma o non ha righe leggibili).
    static func leggiComuni(_ dati: Data) -> TabellaComuni? {
        guard let f = try? JSONDecoder().decode(FileComuni.self, from: dati), f.formato == "prisma-comuni" else { return nil }
        let comuni = f.comuni.elementi.map(\.comune)
        guard !comuni.isEmpty else { return nil }
        return TabellaComuni(fonte: f.fonte ?? "", licenza: f.licenza ?? "", edizione: f.edizione ?? "",
                             diProva: f.diProva ?? false, comuni: comuni)
    }

    /// La tabella dei comuni del pacchetto (nil se manca o non si legge: lo controlla `--verifica-risorse`).
    static func caricaComuni() -> TabellaComuni? {
        guard let url = Risorse.cartella?.appendingPathComponent(fileComuni), let dati = try? Data(contentsOf: url) else { return nil }
        return leggiComuni(dati)
    }

    static func leggiConfini(_ dati: Data) -> ConfiniProvincia? {
        try? JSONDecoder().decode(ConfiniProvincia.self, from: dati)
    }

    /// I confini di una provincia (nil se il file non c'è: la mappa disegna solo le luci e i nomi).
    static func caricaConfini(provincia: String) -> ConfiniProvincia? {
        let sigla = provincia.uppercased().filter { $0.isLetter }
        guard sigla.count == 2,
              let url = Risorse.cartella?.appendingPathComponent(cartellaConfini()).appendingPathComponent("\(sigla).json"),
              let dati = try? Data(contentsOf: url) else { return nil }
        return leggiConfini(dati)
    }

    // MARK: Riconoscimento

    /// «Sant'Ilario d'Enza» → «santilariodenza»: minuscole, senza accenti, senza spazi, apostrofi, trattini e punti
    /// (restano solo lettere e cifre, come `normalizza` dello script di conversione).
    static func normalizza(_ s: String) -> String {
        let piegato = s.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                                locale: Locale(identifier: "it_IT")).lowercased()
        var r = String.UnicodeScalarView()
        for u in piegato.unicodeScalars where CharacterSet.alphanumerics.contains(u) { r.append(u) }
        return String(r)
    }

    /// Le parole di un pezzo di indirizzo senza il CAP (5 cifre, ignorato: decisione dell'utente) e senza la sigla
    /// finale («(BO)» o « BO»), che torna a parte.
    private static func paroleESigla(_ testo: String) -> (parole: [String], sigla: String?) {
        var parole = testo.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" }).map(String.init)
        parole.removeAll { $0.count == 5 && $0.allSatisfy(\.isNumber) }
        var sigla: String?
        if let ultima = parole.last {
            let interno = ultima.hasPrefix("(") && ultima.hasSuffix(")") ? String(ultima.dropFirst().dropLast()) : nil
            if let interno, interno.count == 2, interno.allSatisfy(\.isLetter) {
                sigla = interno.uppercased()
                parole.removeLast()
            } else if parole.count > 1, ultima.count == 2, ultima.allSatisfy({ $0.isLetter && $0.isUppercase }) {
                sigla = ultima
                parole.removeLast()
            }
        }
        return (parole, sigla)
    }

    /// Cerca un nome (già spezzato in parole) nella tabella; nil = nessun comune con quel nome.
    private static func cerca(_ parole: [String], sigla: String?, tabella: TabellaComuni) -> EsitoComune? {
        let chiave = normalizza(parole.joined(separator: " "))
        guard !chiave.isEmpty, let trovati = tabella.perNome[chiave], !trovati.isEmpty else { return nil }
        if let sigla {
            let conSigla = trovati.filter { $0.provincia == sigla }
            if let c = conSigla.first { return .trovato(c) }
            // Sigla diversa da quella del comune: vale solo se il nome è unico (una sigla sbagliata non inventa omonimi)
            return trovati.count == 1 ? .trovato(trovati[0]) : .ambiguo(trovati.map(\.provincia).sorted())
        }
        return trovati.count == 1 ? .trovato(trovati[0]) : .ambiguo(trovati.map(\.provincia).sorted())
    }

    /// L'ultimo pezzo dopo la virgola, senza CAP e sigla: il nome da mostrare in «comune non riconosciuto».
    static func pezzoComune(_ testo: String) -> String {
        let ultimo = testo.split(separator: ",").last.map(String.init) ?? testo
        return paroleESigla(ultimo.trimmingCharacters(in: .whitespacesAndNewlines)).parole.joined(separator: " ")
    }

    /// Il comune di un testo libero: ultimo pezzo dopo la virgola, tolti un CAP (ignorato) e una sigla di provincia
    /// «(BO)» o « BO» finale; con più comuni omonimi vale solo con la sigla. Se l'ultimo pezzo non si trova (indirizzo
    /// senza virgole: «Piazza Duomo 3 Trento»), si provano le ultime 4, 3, 2, 1 parole del testo intero, dalla più lunga
    /// (così «Reggio nell'Emilia» vince su «Emilia»).
    static func comune(testo: String, tabella: TabellaComuni) -> EsitoComune {
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty else { return .vuoto }
        let pezzi = pulito.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard let ultimo = pezzi.last else { return .vuoto }
        let (parole, sigla) = paroleESigla(ultimo)
        if let e = cerca(parole, sigla: sigla, tabella: tabella) { return e }
        // Indirizzo senza virgole (o nome in coda al testo): le ultime parole del testo intero
        let tutto = paroleESigla(pezzi.joined(separator: " "))
        let n = tutto.parole.count
        for k in stride(from: min(4, n), through: 1, by: -1) {
            if let e = cerca(Array(tutto.parole[(n - k)...]), sigla: tutto.sigla, tabella: tabella) { return e }
        }
        return .nonTrovato
    }

    /// Vero se la nazione scritta indica l'Italia (o è vuota).
    static func italiana(_ nazione: String) -> Bool {
        let n = nazione.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return n.isEmpty || n == "it" || n == "italia" || n == "ita" || n == "italy"
    }

    /// Il comune di una sede strutturata (`SedeFiscale.comune` + `.provincia`). `.estero` se `nazione` non è vuota e
    /// non è «IT»/«Italia»; `.vuoto` se il comune non è scritto.
    static func comune(sede: SedeFiscale, tabella: TabellaComuni) -> EsitoComune {
        guard italiana(sede.nazione) else { return .estero }
        let nome = sede.comune.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nome.isEmpty else { return .vuoto }
        let sigla = sede.provincia.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let parole = nome.split(separator: " ").map(String.init)
        return cerca(parole, sigla: sigla.count == 2 ? sigla : nil, tabella: tabella) ?? .nonTrovato
    }
}
