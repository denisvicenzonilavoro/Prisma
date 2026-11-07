import Foundation

// Prisma ovunque (versione 26, «Orizzonte», giro 8) dentro `Prisma --prova-backup`: le impostazioni dello spazio, il
// giornale del dispositivo, i conflitti da decidere, gli arrivi e le posizioni inquadrate tornano uguali dal backup; un
// archivio senza i campi nuovi si apre con lo spazio spento e il resto uguale. La passphrase e la chiave non ci sono mai.

extension ProvaBackup {
    /// Dati di prova di Prisma ovunque (date al secondo: l'archivio le salva così). Nessuna chiave: non va mai nell'archivio.
    static func aggiungiOvunqueDiProva(_ d: inout DatiPrisma) {
        let quando = Date(timeIntervalSinceReferenceDate: 815_200_000)
        var o = ImpostazioniOvunque()
        o.acceso = true
        o.ruolo = .mac
        o.idDispositivo = "mac-prova-backup"
        o.nomeDispositivo = "Mac di prova"
        o.percorso = "/Users/prova/Library/Mobile Documents/com~apple~CloudDocs/Prisma ovunque"
        o.segnalibro = Data([0x50, 0x52, 0x49, 0x53])
        o.generazioneChiave = 2
        o.generazione = 14
        o.vistoFinoA = ["dispositivo-prova": 9]
        o.lamport = 31
        o.ultimaIstantanea = quando
        d.impostazioni.ovunque = o
        let cid = d.clienti.first?.id ?? "giulia"
        let op = OperazioneOvunque(id: "op-prova-backup", dispositivo: "dispositivo-prova", lamport: 30, seq: 9, data: quando, base: 13,
                                   entita: .nota, entitaId: "nota-prova-backup", tipo: .modificaCampo, campo: "testo",
                                   prima: "\"prima\"", dopo: "\"dopo\"")
        d.conflittiOvunque = [ConflittoOvunque(operazione: op, motivo: .stessoCampo, valoreMac: "\"sul Mac\"",
                                               nomeDispositivo: "iPhone di prova", arrivatoIl: quando)]
        d.arriviOvunque = [ArrivoOvunque(entita: .attivita, entitaId: "task-prova-backup", dispositivo: "dispositivo-prova",
                                         nomeDispositivo: "iPhone di prova", il: quando)]
        var giornale = op
        giornale.id = "op-prova-backup-2"
        giornale.seq = 10
        d.giornaleOvunque = [giornale]
        var inquadratura = InquadraturaPonte(clienteId: cid, dispositivo: "iPhone di prova", quando: quando,
                                             righe: [RigaLetta(testo: "Premio: 1.200,00 €")])
        inquadratura.id = "inquadra-prova-backup"
        d.inquadratureDaConfermare = [inquadratura]
    }

    /// Controlla Prisma ovunque dopo il ripristino e la lettura di un archivio senza i campi nuovi.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaOvunque(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard originale.impostazioni.ovunque.acceso, !originale.conflittiOvunque.isEmpty, !originale.giornaleOvunque.isEmpty,
              !originale.inquadratureDaConfermare.isEmpty else {
            return "l'archivio di prova non ha i dati di Prisma ovunque"
        }
        guard estratto.impostazioni.ovunque == originale.impostazioni.ovunque, estratto.conflittiOvunque == originale.conflittiOvunque,
              estratto.giornaleOvunque == originale.giornaleOvunque, estratto.arriviOvunque == originale.arriviOvunque,
              estratto.inquadratureDaConfermare == originale.inquadratureDaConfermare else {
            return "le impostazioni o i dati di Prisma ovunque non tornano uguali dal backup"
        }
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "ovunque") != nil else {
            return "archivio di prova senza Prisma ovunque non preparato"
        }
        radice["impostazioni"] = impostazioni
        for k in ["giornaleOvunque", "conflittiOvunque", "arriviOvunque", "inquadratureDaConfermare"] { radice.removeValue(forKey: k) }
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        // Il confronto con l'archivio riletto (le date dell'archivio sono al secondo, come in verificaCopilota)
        let atteso = try Archivio.decodifica(codificato)
        guard !letto.impostazioni.ovunque.acceso, letto.impostazioni.ovunque == ImpostazioniOvunque(), letto.giornaleOvunque.isEmpty,
              letto.conflittiOvunque.isEmpty, letto.arriviOvunque.isEmpty, letto.inquadratureDaConfermare.isEmpty,
              letto.clienti == atteso.clienti, letto.note == atteso.note else {
            return "archivio senza Prisma ovunque non letto con lo spazio spento e il resto uguale"
        }
        return nil
    }
}
