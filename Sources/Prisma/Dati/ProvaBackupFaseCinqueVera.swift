import Foundation

// La fase 5 di Vera dentro `Prisma --prova-backup` (Vera/BRIEF.md, funzioni 22 e 25): le versioni di «Vera su misura»
// (con l'esame e la curva), il modello di prima, le domande tenute per l'esame, gli esempi già usati e il tipo di motore
// esterno tornano uguali dal backup e dall'archivio a pezzi; un archivio di prima, senza questi campi, si apre con i
// valori di base; una versione rovinata si scarta senza perdere le altre; niente entra nell'istantanea di «Prisma
// ovunque». Le richieste di «Due velocità» restano solo in memoria e il modello in Ollama non viaggia con il backup.

extension ProvaBackup {
    static let versioneInUsoDiProva = "vera-su-misura:2026-10-04"
    static let versioneBocciataDiProva = "vera-su-misura:2026-11-08"

    /// Due versioni (una in uso, una non superata con esame e curva), il modello di prima, l'esame, gli esempi usati e il
    /// motore esterno «servizio» (dati di prova).
    static func aggiungiFaseCinqueVeraDiProva(_ d: inout DatiPrisma) {
        let t = Date(timeIntervalSinceReferenceDate: 815_000_000)
        var inUso = VersioneSuMisura(id: versioneInUsoDiProva, creataIl: t, modelloDiPartenza: "qwen3.5:4b", esempi: 64, stato: .inUso)
        inUso.esame = EsitoEsameBreve(domande: 16, percentualeAttuale: 69, percentualeNuova: 81, cifreInventateAttuale: 2,
                                      cifreInventateNuova: 1, fattoIl: t, superato: true)
        var bocciata = VersioneSuMisura(id: versioneBocciataDiProva, creataIl: t.addingTimeInterval(86_400 * 35), modelloDiPartenza: "qwen3.5:4b",
                                        esempi: 80, stato: .nonSuperata)
        bocciata.esame = EsitoEsameBreve(domande: 20, percentualeAttuale: 80, percentualeNuova: 76, cifreInventateAttuale: 0,
                                         cifreInventateNuova: 3, fattoIl: t.addingTimeInterval(86_400 * 35), superato: false)
        bocciata.curva = [2.1, 1.6, 1.2, 0.9, 0.8]
        var s = ImpostazioniSuMisura()
        s.versioni = [inUso, bocciata]
        s.modelloPrecedente = "qwen3.5:4b"
        s.esame = ["esempio-aaaaaaaaaaaa", "esempio-bbbbbbbbbbbb"]
        s.usati = ["esempio-cccccccccccc"]
        s.ultimoPacchetto = t.addingTimeInterval(86_400 * 30)
        s.esempiNelPacchetto = 80
        d.impostazioni.vera.suMisura = s
        d.impostazioni.vera.modelloLocale = versioneInUsoDiProva
        d.impostazioni.vera.motoreEsterno.tipo = .servizio
    }

    /// Restituisce il motivo del primo errore (nil = tutto bene).
    static func verificaFaseCinqueVera(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        let vera = originale.impostazioni.vera
        guard vera.suMisura.versioni.count == 2, vera.motoreEsterno.tipo == .servizio else {
            return "l'archivio di prova non ha i dati della fase 5 di Vera"
        }
        guard estratto.impostazioni.vera.suMisura == vera.suMisura, estratto.impostazioni.vera.motoreEsterno == vera.motoreEsterno,
              estratto.impostazioni.vera.modelloLocale == vera.modelloLocale else {
            return "le versioni di Vera su misura o il tipo di motore esterno non tornano uguali dal backup"
        }

        // Scrittura a pezzi: stanno nelle impostazioni (indice) e tornano uguali
        let fm = FileManager.default
        let cartella = fm.temporaryDirectory.appendingPathComponent("prova-fase5-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: cartella) }
        try ScrittorePezzi(cartella: cartella).scrivi(originale)
        let letto = try ArchivioPezzi.leggi(ArchivioPezzi.cartellaPezzi(in: cartella)).lettura.dati
        guard letto.impostazioni.vera.suMisura == vera.suMisura, letto.impostazioni.vera.motoreEsterno == vera.motoreEsterno else {
            return "Vera su misura o il motore esterno non tornano uguali dall'archivio a pezzi"
        }

        // Un archivio di prima: senza «suMisura» e «motoreEsterno» nelle impostazioni di Vera (chiave «eve»)
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] else { return "archivio di prova non codificato" }
        func conVera(_ cambia: (inout [String: Any]) -> Void) {
            guard var imp = radice["impostazioni"] as? [String: Any], var v = imp["eve"] as? [String: Any] else { return }
            cambia(&v)
            imp["eve"] = v
            radice["impostazioni"] = imp
        }
        let salvata = (radice["impostazioni"] as? [String: Any])?["eve"] as? [String: Any]
        conVera { $0.removeValue(forKey: "suMisura"); $0.removeValue(forKey: "motoreEsterno") }
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senza.impostazioni.vera.suMisura == ImpostazioniSuMisura(), senza.impostazioni.vera.motoreEsterno == ImpostazioniMotoreEsterno(),
              senza.impostazioni.vera.passi == vera.passi, senza.clienti.count == originale.clienti.count else {
            return "un archivio senza Vera su misura e motore esterno non si apre con i valori di base"
        }

        // Una versione rovinata (stato sconosciuto) si scarta, le altre restano; un tipo di motore sconosciuto torna «server»
        conVera { v in
            v = salvata ?? v
            if var s = v["suMisura"] as? [String: Any], var versioni = s["versioni"] as? [[String: Any]], !versioni.isEmpty {
                versioni[0]["stato"] = "sconosciuto"
                s["versioni"] = versioni
                v["suMisura"] = s
            }
            v["motoreEsterno"] = ["tipo": "astronave"]
        }
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.impostazioni.vera.suMisura.versioni.map(\.id) == [versioneBocciataDiProva],
              rovinato.impostazioni.vera.suMisura.modelloPrecedente == vera.suMisura.modelloPrecedente,
              rovinato.impostazioni.vera.motoreEsterno.tipo == .server else {
            return "una versione di Vera su misura rovinata fa perdere le altre, o un tipo di motore sconosciuto non torna di base"
        }

        // Prisma ovunque: le impostazioni di Vera restano sul Mac
        let ist = SpazioOvunque.datiIstantanea(originale)
        guard ist.impostazioni.vera.suMisura == ImpostazioniSuMisura(), ist.impostazioni.vera.motoreEsterno == ImpostazioniMotoreEsterno() else {
            return "Vera su misura e il motore esterno non devono entrare nell'istantanea di Prisma ovunque"
        }
        let byte = try Archivio.codificatore.encode(ist)
        guard byte.range(of: Data(versioneInUsoDiProva.utf8)) == nil else {
            return "il nome della Vera su misura è finito nell'istantanea di Prisma ovunque"
        }
        return nil
    }
}
