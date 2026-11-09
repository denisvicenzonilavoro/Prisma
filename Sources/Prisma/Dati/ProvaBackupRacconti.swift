import Foundation

// «Luce», giro 8 («Sala: racconti senza uscita», versione 27) dentro `Prisma --prova-backup`: l'inizio del rapporto
// (`Cliente.clienteDal`), l'indennizzo stimato di una polizza (`Posizione.indennizzoStimato`) e le impostazioni della
// Sala (`Impostazioni.sala`: eventi di Lancia l'anno con probabilità e fonte, anni della partita, avvertenze e titolo del
// valore) tornano uguali dal backup; un archivio senza i campi nuovi si apre senza, con il resto uguale; un evento
// rovinato si scarta e gli altri restano, una probabilità fuori scala diventa «non scritta». L'inizio del rapporto entra
// nell'istantanea di «Prisma ovunque» con il cliente. Le partite di Lancia l'anno non si salvano.
// Le lettere dal futuro conservate (§3.1.5 punto 5, `provaLettere`): nel file del cliente, uguali da backup e ripristino,
// un archivio di prima si apre senza, una lettera senza testo si scarta, mai nell'istantanea di «Prisma ovunque»;
// «Aggiungi al Prisma» conserva la «Con il piano» e il file del cliente la ritrova dopo un riavvio (senza le stesure in
// memoria); un cliente tolto porta via le sue.

extension ProvaBackup {
    /// DATI DI PROVA: l'inizio del rapporto del primo cliente, l'indennizzo stimato di una sua posizione e le
    /// impostazioni della Sala con un evento scritto dall'utente (probabilità e fonte di prova).
    static func aggiungiRaccontiDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        // Date a secondi interi, come le altre dell'archivio di prova
        d.clienti[0].clienteDal = Date(timeIntervalSinceReferenceDate: 700_000_000)
        if let i = d.posizioni.firstIndex(where: { $0.clienteId == c.id }) { d.posizioni[i].indennizzoStimato = 9_000 }
        var sala = ImpostazioniSala()
        sala.eventiAnno = [
            EventoAnno(id: "caldaia", titolo: "La caldaia (di prova)", effetto: .spesa, importo: 8_500, tono: .arancio,
                       probabilita: 0.05, fonte: "Fonte di prova", etaMinima: 25, etaMassima: 80),
            EventoAnno(id: "evento-utente", titolo: "Un evento dell'utente", effetto: .mancatoReddito, mesi: 4,
                       rischio: .invalidita, tono: .rosso),
        ]
        sala.anniPartita = 0
        sala.avvertenzaLettera = "Avvertenza di prova della lettera."
        sala.avvertenzaValore = "Avvertenza di prova del valore."
        sala.titoloValore = "In {periodo} insieme: {valore} (testo di prova)."
        d.impostazioni.sala = sala
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaRacconti(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.clienti.first?.clienteDal != nil, originale.posizioni.contains(where: { $0.indennizzoStimato == 9_000 }),
              originale.impostazioni.sala.eventiAnno.count == 2 else {
            return "l'archivio di prova non ha l'inizio del rapporto, l'indennizzo stimato o le impostazioni della Sala"
        }
        guard estratto.clienti.map(\.clienteDal) == originale.clienti.map(\.clienteDal),
              estratto.posizioni.map(\.indennizzoStimato) == originale.posizioni.map(\.indennizzoStimato),
              estratto.impostazioni.sala == originale.impostazioni.sala else {
            return "inizio del rapporto, indennizzo stimato o impostazioni della Sala non tornano uguali dal backup"
        }
        guard let e = estratto.impostazioni.sala.eventiAnno.first, e.probabilita == 0.05, e.fonte == "Fonte di prova", e.esceACaso,
              estratto.impostazioni.sala.anniPartita == 0 else {
            return "probabilità, fonte o anni della partita persi nel backup"
        }
        // 2. Un archivio senza i campi del giro 8 si apre senza, con il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var clienti = radice["clienti"] as? [[String: Any]], !clienti.isEmpty,
              var posizioni = radice["posizioni"] as? [[String: Any]],
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "sala") != nil,
              clienti[0].removeValue(forKey: "clienteDal") != nil else {
            return "archivio di prova senza i campi del giro 8 non preparato"
        }
        for i in posizioni.indices { posizioni[i].removeValue(forKey: "indennizzoStimato") }
        radice["clienti"] = clienti
        radice["posizioni"] = posizioni
        radice["impostazioni"] = impostazioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard letto.clienti.allSatisfy({ $0.clienteDal == nil }), letto.posizioni.allSatisfy({ $0.indennizzoStimato == nil }),
              letto.impostazioni.sala == ImpostazioniSala(), letto.clienti.count == originale.clienti.count,
              letto.posizioni.count == originale.posizioni.count else {
            return "archivio senza i campi del giro 8 non letto correttamente (attesi nessun inizio, nessun indennizzo, Sala vuota)"
        }
        // 3. Un evento rovinato si scarta, gli altri restano; una probabilità fuori scala non vale; anni fuori scala no
        var sala = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.impostazioni.sala)) as? [String: Any]) ?? [:]
        var eventi = sala["eventiAnno"] as? [[String: Any]] ?? []
        guard eventi.count == 2 else { return "impostazioni della Sala di prova non codificate" }
        eventi[1]["probabilita"] = 7
        sala["eventiAnno"] = [["titolo": "senza id"], "rovinato", eventi[0], eventi[1]] as [Any]
        sala["anniPartita"] = 500
        impostazioni["sala"] = sala
        radice["impostazioni"] = impostazioni
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.impostazioni.sala.eventiAnno.map(\.id) == ["caldaia", "evento-utente"],
              rovinato.impostazioni.sala.eventiAnno[1].probabilita == nil, rovinato.impostazioni.sala.anniPartita == nil,
              rovinato.impostazioni.sala.avvertenzaLettera == "Avvertenza di prova della lettera." else {
            return "eventi rovinati della Sala: archivio non aperto tenendo solo quelli buoni"
        }
        // 4. L'inizio del rapporto entra nell'istantanea di «Prisma ovunque» con il cliente (decisione 44)
        let ist = SpazioOvunque.datiIstantanea(originale)
        guard ist.clienti.first?.clienteDal == originale.clienti.first?.clienteDal else {
            return "l'inizio del rapporto non entra nell'istantanea di Prisma ovunque"
        }
        // 5. I campi stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale == 27 else { return "i campi del giro 8 stanno nella versione 27 dell'archivio di Luce" }
        return nil
    }
}

extension ProvaBackup {
    /// Le lettere dal futuro conservate. Restituisce il motivo dell'errore (nil = tutto bene). Dati di prova dichiarati.
    static func provaLettere(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("LettereConservate", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)

        guard ArchivioPezzi.pezzo(.lettere) == .cliente else { return "lettere: non stanno nel file del cliente" }

        // L'archivio con due lettere di Giulia (Vera e Prisma) e una di Marco; date al secondo
        var archivio = DatiPrisma.demo()
        guard archivio.clienti.contains(where: { $0.id == "giulia" }) else { return "lettere: manca Giulia nei dati di prova" }
        let t0 = Date(timeIntervalSinceReferenceDate: 815_017_293)
        let lettere = [
            LetteraFuturo(id: "lettera-prova-g1", clienteId: "giulia", scrittaIl: t0, versione: .conPiano,
                          testo: "Giulia,\n\nlettera di prova scritta da Vera 4K7M.\n\nGiulia, 67 anni", autore: .vera,
                          modello: "qwen3.5:4b", cifre: ["etaTraguardo": "67", "pensioneMensile": "1.730"]),
            LetteraFuturo(id: "lettera-prova-g2", clienteId: "giulia", scrittaIl: t0.addingTimeInterval(61), versione: .senzaPiano,
                          testo: "Giulia,\n\nlettera di prova di Prisma 2R9T.\n\nGiulia, 67 anni", autore: .modelloFisso),
            LetteraFuturo(id: "lettera-prova-m1", clienteId: "marco", scrittaIl: t0.addingTimeInterval(122), versione: .conPiano,
                          testo: "Marco,\n\nlettera di prova 8D3H.\n\nMarco, 66 anni", autore: .modelloFisso),
        ]
        archivio.lettere = lettere
        try Archivio.salva(archivio, in: dati)

        // Il posto su disco: nel file del cliente, mai nell'indice
        let pezzi = ArchivioPezzi.cartellaPezzi(in: dati)
        func leggi(_ url: URL) -> String { (try? String(contentsOf: url, encoding: .utf8)) ?? "" }
        let fileGiulia = leggi(pezzi.appendingPathComponent(ArchivioPezzi.nomeClienti, isDirectory: true)
            .appendingPathComponent(ArchivioPezzi.nomeFile(cliente: "giulia")))
        let indice = leggi(pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice))
        guard fileGiulia.contains("lettera-prova-g1"), fileGiulia.contains("lettera-prova-g2"), !fileGiulia.contains("lettera-prova-m1"),
              !indice.contains("lettera-prova-g1") else {
            return "lettere: non stanno nel file del loro cliente (o finiscono nell'indice)"
        }

        // Backup e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        let d = estratto.dati
        GestoreBackup.pulisciEstrazione(estratto.cartella)
        guard Set(d.lettere.map(\.id)) == Set(lettere.map(\.id)),
              d.lettere.first(where: { $0.id == "lettera-prova-g1" }) == lettere[0] else {
            return "lettere: non tornano uguali dal backup"
        }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(creato).cartella)
        let r = Archivio.carica(in: ripristinata).dati
        guard Set(r.lettere.map(\.id)) == Set(lettere.map(\.id)) else { return "lettere: non tornano dal ripristino" }

        // Un archivio di prima, senza la chiave: nessuna lettera, il resto uguale
        var vecchio = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(archivio)) as? [String: Any] ?? [:]
        vecchio["lettere"] = nil
        let letto = try Archivio.decodificatore.decode(DatiPrisma.self, from: JSONSerialization.data(withJSONObject: vecchio))
        guard letto.lettere.isEmpty, letto.clienti.count == archivio.clienti.count else {
            return "lettere: un archivio di prima non si apre senza lettere"
        }

        // Lettura tollerante: senza testo si scarta, una versione e un autore sconosciuti diventano quelli di base
        var strana = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(lettere[0])) as? [String: Any] ?? [:]
        strana["versione"] = "versione-futura"
        strana["autore"] = "altro"
        strana["cifre"] = 7
        var senzaTesto = strana
        senzaTesto["id"] = "lettera-prova-vuota"
        senzaTesto["testo"] = "   "
        let lette = try Archivio.decodificatore.decode(ElencoTollerante<LetteraFuturo>.self,
                                                       from: JSONSerialization.data(withJSONObject: [senzaTesto, strana, "rovinata"] as [Any])).elementi
        guard lette.count == 1, lette[0].id == "lettera-prova-g1", lette[0].versione == .conPiano, lette[0].autore == .modelloFisso,
              lette[0].cifre.isEmpty, lette[0].testo == lettere[0].testo else {
            return "lettere: non si leggono con tolleranza"
        }

        // Mai nell'istantanea di «Prisma ovunque» (D-L8, decisione 44), e il dispositivo tiene le sue (vuote)
        let ist = SpazioOvunque.datiIstantanea(archivio)
        let chiaro = String(decoding: try JSONOvunque.codificatore().encode(ist), as: UTF8.self)
        guard ist.lettere.isEmpty, !chiaro.contains("4K7M"), archivio.lettere == lettere else {
            return "lettere: entrano nell'istantanea di Prisma ovunque (o l'istantanea tocca l'archivio del Mac)"
        }

        // Conserva: l'ultima per cliente e versione sostituisce la precedente
        let nuova = LetteraFuturo(id: "lettera-prova-g3", clienteId: "giulia", scrittaIl: t0.addingTimeInterval(183), versione: .conPiano,
                                  testo: "Giulia,\n\nseconda stesura di prova 6F1B.\n\nGiulia, 67 anni", autore: .vera)
        let dopo = LetteraFuturo.conserva(nuova, in: lettere)
        guard dopo.count == 3, !dopo.contains(where: { $0.id == "lettera-prova-g1" }),
              LetteraFuturo.ultima(dopo, cliente: "giulia", versione: .conPiano)?.id == "lettera-prova-g3",
              LetteraFuturo.ultima(dopo, cliente: "giulia", versione: .senzaPiano)?.id == "lettera-prova-g2" else {
            return "lettere: conservare non sostituisce la lettera dello stesso cliente e della stessa versione"
        }

        // Nello stato: «Aggiungi al Prisma» conserva la «Con il piano»; dopo un riavvio (senza stesure in memoria) il file
        // del cliente usa la lettera conservata, non quella fissa; un cliente tolto porta via le sue
        let s = StatoShell(persistente: false)
        guard let giulia = s.cliente("giulia"), let scheda = s.schedaLettera(giulia), scheda.pianoPresente else {
            return "lettere: Giulia dei dati di prova non ha la scheda della lettera con il piano"
        }
        s.dati.lettere = []
        s.sala.stesureLettera["giulia"] = [.conPiano: TestoLettera(testo: "Giulia,\n\nstesura di Vera di prova 3N5Q.\n\nGiulia, 67 anni",
                                                                   autore: .vera, modello: "qwen3.5:4b", avviso: nil)]
        if s.voceAggiunta(.lettera, cliente: giulia) { s.aggiungiAlPrismaCliente(.lettera, cliente: giulia) }
        s.aggiungiAlPrismaCliente(.lettera, cliente: giulia)
        guard s.dati.lettere.count == 1, let conservata = s.dati.lettere.first, conservata.versione == .conPiano,
              conservata.autore == .vera, conservata.testo.contains("3N5Q"), conservata.cifre["etaTraguardo"] == "\(scheda.etaTraguardo)" else {
            return "lettere: «Aggiungi al Prisma» non conserva la stesura «Con il piano»"
        }
        s.sala.stesureLettera = [:]
        guard s.letteraPerIlFile(giulia)?.contains("3N5Q") == true else {
            return "lettere: senza le stesure in memoria il file del cliente non usa la lettera conservata"
        }
        s.dati.lettere = [conservata] + lettere.filter { $0.clienteId == "marco" }
        s.eliminaCliente("giulia")
        guard s.dati.lettere.map(\.id) == ["lettera-prova-m1"] else {
            return "lettere: un cliente tolto non porta via le sue lettere (o porta via quelle degli altri)"
        }
        return nil
    }
}
