import Foundation

// Clienti: potenziali e passaparola, e le campagne (versione 27, «Luce» giro 12) dentro `Prisma --prova-backup`:
// - i potenziali clienti, lo storico delle campagne, chi ha presentato ogni cliente (`presentatoDa`, `presentatoIl`), i
//   messaggi di campagna e di richiesta di presentazione e l'interruttore «Porta anche i potenziali clienti» tornano
//   uguali dal backup;
// - un archivio della versione 26 (senza le chiavi nuove) si apre con potenziali e campagne vuoti, nessun presentatore e
//   il resto uguale;
// - un potenziale senza nome si scarta (l'altro resta), una fase sconosciuta diventa «Da contattare», una probabilità
//   fuori scala e una stima negativa diventano «non scritte», una campagna con un tipo sconosciuto resta, un messaggio
//   con un tipo d'occasione sconosciuto si scarta senza perdere gli altri;
// - su disco i potenziali e le campagne stanno in `relazione.json` (non nell'indice né nei file dei clienti), il
//   presentatore nel file del cliente;
// - in modalità cliente Messaggi non si apre e Clienti torna alla Rubrica.
// VALORI DI PROVA scritti qui per l'andata e il ritorno, mai nell'archivio reale.

extension ProvaBackup {
    private static let istanteLuceClienti = Date(timeIntervalSinceReferenceDate: 815_000_000)

    /// Un potenziale completo, uno minimo, un presentatore, una campagna con due bozze, una richiesta di presentazione.
    static func aggiungiLuceClientiDiProva(_ d: inout DatiPrisma) {
        let t = istanteLuceClienti
        var completo = PotenzialeCliente(id: "pot-backup-completo", nome: "Potenziale di prova", creatoIl: t)
        completo.email = "potenziale@esempio.invalid"
        completo.telefono = "+39 000 0000000"
        completo.presentatoDa = d.clienti.first?.id
        completo.patrimonioStimato = 180_000
        completo.probabilita = 40
        completo.chiusuraPrevista = t.addingTimeInterval(86_400 * 30)
        completo.fase = .analisi
        completo.storia = [CambioFase(fase: .daContattare, il: t), CambioFase(fase: .primoIncontro, il: t.addingTimeInterval(86_400)),
                           CambioFase(fase: .analisi, il: t.addingTimeInterval(86_400 * 2))]
        completo.informativaIl = t
        completo.consensoContatto = true
        completo.nota = "nota di prova"
        completo.diProva = true
        var minimo = PotenzialeCliente(id: "pot-backup-minimo", nome: "Solo nome", creatoIl: t)
        minimo.fonte = "dal sito dello studio (prova)"
        d.potenziali = [completo, minimo]
        if d.clienti.count > 2 {
            d.clienti[1].presentatoDa = d.clienti[0].id
            d.clienti[1].presentatoIl = t
            d.clienti[2].presentatoDa = d.clienti[1].id
        }
        // Una campagna con due bozze e una richiesta di presentazione aperta
        let clienti = Array(d.clienti.prefix(2))
        var idMessaggi: [String] = []
        for c in clienti {
            let o = OccasioneMessaggio(origine: OrigineMessaggio(tipo: .campagna, riferimento: "campagna-backup"), clienteId: c.id,
                                       canale: nil, gruppo: .oggi, titolo: "Campagna di prova", perche: "Campagna: prova",
                                       oggetto: "Campagna di prova", cifre: [CifraMessaggio(.bisogno, "un bisogno di prova")],
                                       priorita: .bassa, data: t)
            let m = MessaggioCliente(clienteId: c.id, occasioneId: o.id, origine: o.origine, canaleLavoro: nil, tono: .cordiale,
                                     canale: .mail, oggetto: o.oggetto, testo: "Testo di prova", cifre: o.cifre,
                                     autore: .modelloFisso, modello: nil, creatoIl: t)
            idMessaggi.append(m.id)
            d.messaggi.append(m)
        }
        if let c = clienti.first {
            var r = MessaggioCliente(clienteId: c.id, occasioneId: "richiestaPresentazione-\(c.id)-prova",
                                     origine: OrigineMessaggio(tipo: .richiestaPresentazione, riferimento: "prova"), canaleLavoro: nil,
                                     tono: .formale, canale: .messaggi, oggetto: nil, testo: "Testo di prova",
                                     cifre: [CifraMessaggio(.traguardo, "Ha raggiunto «Obiettivo di prova»")],
                                     autore: .modelloFisso, modello: nil, creatoIl: t)
            r.stato = .apertoInMessaggi
            r.apertoIl = t
            d.messaggi.append(r)
        }
        d.campagne = [Campagna(id: "campagna-backup", gruppoId: "protezioneFamiglia", gruppoTipo: .protezioneFamiglia,
                               titolo: "Famiglia senza protezione", avviataIl: t, tono: .cordiale, canale: .mail,
                               clienti: clienti.map(\.id), appuntamenti: [t.addingTimeInterval(86_400 * 3)], messaggi: idMessaggi)]
        d.impostazioni.ovunque.potenzialiNelloSpazio = true
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaLuceClienti(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.potenziali.count == 2, originale.campagne.count == 1,
              originale.clienti.contains(where: { $0.presentatoDa != nil }),
              originale.impostazioni.ovunque.potenzialiNelloSpazio else {
            return "l'archivio di prova non ha potenziali, campagne, presentatori e l'interruttore dei potenziali"
        }
        guard estratto.potenziali == originale.potenziali else { return "i potenziali clienti non tornano uguali dal backup" }
        guard estratto.campagne == originale.campagne else { return "le campagne non tornano uguali dal backup" }
        guard estratto.clienti.map(\.presentatoDa) == originale.clienti.map(\.presentatoDa),
              estratto.clienti.map(\.presentatoIl) == originale.clienti.map(\.presentatoIl) else {
            return "chi ha presentato i clienti non torna uguale dal backup"
        }
        let nuovi: Set<TipoOccasioneMessaggio> = [.campagna, .richiestaPresentazione]
        guard estratto.messaggi.filter({ nuovi.contains($0.origine.tipo) }) == originale.messaggi.filter({ nuovi.contains($0.origine.tipo) }),
              originale.messaggi.filter({ nuovi.contains($0.origine.tipo) }).count == 3 else {
            return "i messaggi di campagna e di richiesta di presentazione non tornano uguali dal backup"
        }
        guard estratto.impostazioni.ovunque.potenzialiNelloSpazio else {
            return "l'interruttore «Porta anche i potenziali clienti» non torna dal backup"
        }
        // 2. Un archivio della versione 26 (senza le chiavi nuove) si apre con tutto vuoto e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "potenziali") != nil,
              radice.removeValue(forKey: "campagne") != nil,
              var clienti = radice["clienti"] as? [[String: Any]] else {
            return "archivio di prova della versione 26 non preparato"
        }
        let originaliRadice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] ?? [:]
        for i in clienti.indices {
            clienti[i].removeValue(forKey: "presentatoDa")
            clienti[i].removeValue(forKey: "presentatoIl")
        }
        radice["clienti"] = clienti
        radice["versione"] = 26
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.potenziali.isEmpty, letto.campagne.isEmpty, letto.clienti.allSatisfy({ $0.presentatoDa == nil && $0.presentatoIl == nil }),
              letto.clienti.map(\.id) == atteso.clienti.map(\.id), letto.posizioni == atteso.posizioni, letto.messaggi == atteso.messaggi else {
            return "archivio della versione 26 non letto correttamente (attesi potenziali e campagne vuoti, nessun presentatore, il resto uguale)"
        }
        guard !ImpostazioniOvunque().potenzialiNelloSpazio else {
            return "l'interruttore dei potenziali nello spazio è acceso di base"
        }
        // 3. Elementi illeggibili si scartano, valori illeggibili diventano «non scritti»
        guard var potenziali = originaliRadice["potenziali"] as? [[String: Any]], potenziali.count == 2,
              var campagne = originaliRadice["campagne"] as? [[String: Any]], var campagna = campagne.first,
              var messaggi = originaliRadice["messaggi"] as? [[String: Any]], let unMessaggio = messaggi.first else {
            return "potenziali, campagne o messaggi di prova non codificati"
        }
        potenziali[0]["fase"] = "fase di un Prisma più nuovo"
        potenziali[0]["probabilita"] = 140
        potenziali[0]["patrimonioStimato"] = -5
        potenziali[1].removeValue(forKey: "nome")
        campagna["gruppoTipo"] = "tipo di un Prisma più nuovo"
        campagna["tono"] = "tono sconosciuto"
        campagne[0] = campagna
        campagne.append(["titolo": "Senza id"])
        var strano = unMessaggio
        strano["id"] = "messaggio-tipo-sconosciuto"
        strano["origine"] = ["tipo": "tipo di un Prisma più nuovo", "riferimento": "x"]
        messaggi.append(strano)
        var radiceStrana = originaliRadice
        radiceStrana["potenziali"] = potenziali
        radiceStrana["campagne"] = campagne
        radiceStrana["messaggi"] = messaggi
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radiceStrana))
        guard illeggibile.potenziali.count == 1, let p = illeggibile.potenziali.first, p.id == "pot-backup-completo",
              p.fase == .daContattare, p.probabilita == nil, p.patrimonioStimato == nil, p.email == "potenziale@esempio.invalid",
              p.storia.count == 3, p.informativaIl != nil else {
            return "potenziali illeggibili: elemento senza nome non scartato, valori fuori scala non tolti o campi leggibili persi"
        }
        guard illeggibile.campagne.count == 1, illeggibile.campagne.first?.gruppoTipo == nil,
              illeggibile.campagne.first?.tono == .cordiale, illeggibile.campagne.first?.messaggi.count == 2 else {
            return "campagne illeggibili: campagna senza id non scartata o campagna di un tipo nuovo persa"
        }
        guard illeggibile.messaggi.count == originale.messaggi.count,
              !illeggibile.messaggi.contains(where: { $0.id == "messaggio-tipo-sconosciuto" }) else {
            return "un messaggio con un tipo d'occasione sconosciuto non si scarta (o fa perdere gli altri)"
        }
        return nil
    }

    /// Su disco: potenziali e campagne in `relazione.json`, il presentatore nel file del cliente.
    static func provaPezziLuceClienti(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("ClientiLuce", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        var archivio = DatiPrisma.demo()
        aggiungiLuceClientiDiProva(&archivio)
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)
        try Archivio.salva(archivio, in: dati)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: dati)
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        guard indice.sezioni.contains("relazione"),
              let testoRelazione = String(data: try Data(contentsOf: pezzi.appendingPathComponent("relazione.json")), encoding: .utf8),
              testoRelazione.contains("pot-backup-completo"), testoRelazione.contains("campagna-backup"),
              let testoIndice = String(data: try Data(contentsOf: pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice)), encoding: .utf8),
              !testoIndice.contains("pot-backup-completo"), !testoIndice.contains("campagna-backup") else {
            return "clienti: potenziali e campagne non stanno in relazione.json della cartella a pezzi (o sono nell'indice)"
        }
        guard let presentato = archivio.clienti.first(where: { $0.presentatoDa != nil }),
              let voce = indice.clienti.first(where: { $0.id == presentato.id }),
              let testoCliente = String(data: try Data(contentsOf: pezzi.appendingPathComponent("Clienti/" + voce.file)), encoding: .utf8),
              testoCliente.contains("presentatoDa"), !testoCliente.contains("pot-backup-completo") else {
            return "clienti: chi ha presentato il cliente non sta nel suo file (o i potenziali finiscono nei file dei clienti)"
        }
        let riletto = Archivio.carica(in: dati)
        Archivio.coda.sync {}
        guard riletto.dati.potenziali == archivio.potenziali, riletto.dati.campagne == archivio.campagne else {
            return "clienti: potenziali e campagne non si rileggono uguali dalla cartella a pezzi"
        }
        return nil
    }

    /// In modalità cliente Messaggi non si apre (decisione 50) e Clienti torna alla Rubrica.
    static func provaModoClienteLuce() -> String? {
        let stato = StatoShell(persistente: false)
        guard StatoShell.appRiservate.contains(.messaggi) else { return "clienti: Messaggi non è fra le app riservate" }
        guard let c = stato.dati.clienti.first else { return "clienti: nessun cliente di prova" }
        stato.dati.clienteAttivoId = c.id
        stato.vistaClienti = .passaparola
        stato.apri(.messaggi)
        stato.entraModoCliente(avviso: false)
        guard !stato.finestre.contains(where: { $0.app == .messaggi }) else {
            return "clienti: entrando in modalità cliente Messaggi resta aperta"
        }
        guard stato.vistaClienti == .rubrica else { return "clienti: in modalità cliente Clienti resta su Potenziali o Passaparola" }
        stato.apri(.messaggi)
        guard !stato.finestre.contains(where: { $0.app == .messaggi }) else { return "clienti: in modalità cliente Messaggi si apre" }
        stato.esciModoCliente()
        return nil
    }
}
