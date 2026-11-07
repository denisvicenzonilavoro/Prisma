import Foundation

// Le impostazioni di Studio e le novità viste (versione 26, «Orizzonte») dentro `Prisma --prova-backup`: tornano uguali
// dal backup, e un archivio della versione 25 senza i due campi si apre con le impostazioni vuote e tutto il resto uguale.

extension ProvaBackup {
    /// Impostazioni di Studio per la prova del backup. Sono VALORI DI PROVA scritti qui per controllare l'andata e il
    /// ritorno dal backup, non aliquote vere di Alleanza: non finiscono mai nell'archivio reale.
    static func studioDiProva() -> ImpostazioniStudio {
        var s = ImpostazioniStudio()
        s.aliquote[.risparmio] = AliquoteProvvigione(nuovaProduzione: 4, ricorrenti: 3)
        s.aliquote[.protezione] = AliquoteProvvigione(nuovaProduzione: 20, rinnovi: 10)
        s.aliquote[.investimento] = AliquoteProvvigione(nuovaProduzione: 2.5)
        s.obiettivi[2026] = ObiettiviStudio(produzioneAlleanza: 500_000, nuoviClienti: 10, ricaviConsulenza: 35_000)
        s.obiettivi[2027] = ObiettiviStudio(nuoviClienti: 12)
        return s
    }

    /// Controlla i campi della versione 26 dopo il ripristino e la lettura di un archivio della versione 25.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaStudio(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard !originale.impostazioni.studio.senzaAliquote, originale.impostazioni.novitaViste != nil else {
            return "l'archivio di prova non ha impostazioni di Studio né novità viste"
        }
        guard estratto.impostazioni.studio == originale.impostazioni.studio,
              estratto.impostazioni.novitaViste == originale.impostazioni.novitaViste,
              estratto.impostazioni.studio.aliquote[.risparmio]?.ricorrenti == 3,
              estratto.impostazioni.studio.obiettivi[2026]?.ricaviConsulenza == 35_000 else {
            return "le impostazioni di Studio o le novità viste non tornano uguali dal backup"
        }
        // 2. Un archivio della versione 25 (senza i due campi) si apre con i valori vuoti e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "studio") != nil,
              impostazioni.removeValue(forKey: "novitaViste") != nil else {
            return "archivio di prova della versione 25 non preparato"
        }
        radice["impostazioni"] = impostazioni
        radice["versione"] = 25
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        var atteso = try Archivio.decodifica(codificato)
        atteso.impostazioni.studio = ImpostazioniStudio()
        atteso.impostazioni.novitaViste = nil
        guard letto.impostazioni.studio == ImpostazioniStudio(), letto.impostazioni.studio.senzaAliquote,
              letto.impostazioni.novitaViste == nil, letto.impostazioni == atteso.impostazioni,
              letto.clienti == atteso.clienti, letto.posizioni == atteso.posizioni else {
            return "archivio della versione 25 senza le impostazioni di Studio non letto correttamente (attese vuote)"
        }
        // 3. Impostazioni di Studio illeggibili non fanno scartare l'archivio
        impostazioni["studio"] = "non sono impostazioni"
        radice["impostazioni"] = impostazioni
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.impostazioni.studio == ImpostazioniStudio(), illeggibile.clienti.count == originale.clienti.count else {
            return "impostazioni di Studio illeggibili: archivio non aperto con le impostazioni vuote"
        }
        // 4. La versione dell'archivio
        guard DatiPrisma.versioneAttuale >= 26 else {
            return "l'archivio con le impostazioni di Studio deve essere almeno alla versione 26"
        }
        return nil
    }
}
