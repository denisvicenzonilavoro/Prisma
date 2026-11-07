import CryptoKit
import Foundation

/// Una cartella locale che finge iCloud Drive per `Prisma --prova-ovunque`: ritardi (i file scritti restano «in viaggio»
/// finché non si consegnano), file non ancora scaricati, copie «nome 2» e file troncati. Sotto c'è la cartella vera
/// (`CartellaCondivisaFile`), con la stessa coordinazione dell'app.
final class CartellaOvunqueFinta: CartellaCondivisa {
    let reale: CartellaCondivisaFile
    /// true: le scritture non arrivano finché non si chiama `consegna()` (latenza di iCloud).
    var ritardo = false
    /// I file che risultano in iCloud ma non su questo dispositivo.
    var nonScaricati: Set<String> = []
    private(set) var inViaggio: [String: Data] = [:]

    init(url: URL) {
        reale = CartellaCondivisaFile(url: url)
    }

    func elenca() throws -> [VoceCartella] {
        try reale.elenca().map { v in
            guard nonScaricati.contains(v.nome) else { return v }
            return VoceCartella(nome: v.nome, dimensione: v.dimensione, modificatoIl: v.modificatoIl, scaricato: false)
        }
    }

    func leggi(_ nome: String) throws -> Data {
        if nonScaricati.contains(nome) { throw ErroreOvunque.inAttesaDiICloud(nome) }
        return try reale.leggi(nome)
    }

    func sostituisci(_ nome: String, con dati: Data) throws {
        if ritardo {
            inViaggio[nome] = dati
            return
        }
        try reale.sostituisci(nome, con: dati)
    }

    func elimina(_ nome: String) throws {
        inViaggio[nome] = nil
        try reale.elimina(nome)
    }

    /// iCloud porta a destinazione i file in viaggio.
    func consegna() throws {
        let tutti = inViaggio
        inViaggio = [:]
        for nome in tutti.keys.sorted() {
            if let dati = tutti[nome] { try reale.sostituisci(nome, con: dati) }
        }
    }

    /// La copia che iCloud crea quando due scritture si incrociano («giornale-x 2.cifrato»).
    func duplica(_ nome: String, in copia: String) throws {
        try reale.sostituisci(copia, con: reale.leggi(nome))
    }

    /// Un file arrivato a metà: gli si tolgono gli ultimi `byte`.
    func tronca(_ nome: String, togli byte: Int) throws {
        let dati = try reale.leggi(nome)
        try reale.sostituisci(nome, con: dati.prefix(max(0, dati.count - byte)))
    }
}

/// Prova automatica di Prisma ovunque (`Prisma --prova-ovunque`, Design/ovunque-fattibilita.md §5): due archivi (il «Mac»
/// e l'«iPhone») e una cartella locale che finge iCloud Drive, in una cartella temporanea. L'archivio vero, il Portachiavi
/// e iCloud non si toccano mai. Casi: andata e ritorno, ritardi, file non scaricato, copia «nome 2», idempotenza, stessa
/// cosa cambiata in due posti → «Da decidere», campi diversi senza conflitto, eliminazione contro modifica, cliente che
/// non c'è più, riapplicazione delle operazioni non confermate, file troncato, passphrase sbagliata e cambiata, un altro
/// Mac, copia di sola lettura, nessun dato in chiaro nella cartella, passphrase mai nell'archivio, backup v1 ancora apribili.
enum ProvaOvunque {
    private struct Fallita: Error {
        let motivo: String
    }

    private static func controlla(_ condizione: Bool, _ motivo: @autoclosure () -> String) throws {
        if !condizione { throw Fallita(motivo: motivo()) }
    }

    /// L'errore di un blocco (nil se non ne lancia).
    private static func erroreDi(_ blocco: () throws -> Void) -> Error? {
        do {
            try blocco()
            return nil
        } catch {
            return error
        }
    }

    private static func erroreBackup(_ e: Error?, _ atteso: ErroreBackup) -> Bool {
        guard let b = e as? ErroreBackup else { return false }
        return b.errorDescription == atteso.errorDescription
    }

    /// Poche iterazioni: solo per la durata della prova (l'app usa sempre quelle predefinite).
    static let iterazioni: UInt32 = 2_000
    static let passphrase = "passphrase di prova lunga"
    static let passphraseNuova = "passphrase nuova di prova"
    /// Un testo noto: non deve mai comparire nei byte della cartella condivisa.
    static let testoSegreto = "Testo riservato della prova ovunque 7Q4Z"
    static let idMac = "mac-prova"
    static let idTelefono = "dispositivo-prova"

    /// Le ore della prova, al secondo.
    private static func ora(_ minuti: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: 815_100_000 + TimeInterval(minuti * 60))
    }

    static func esegui() -> Int32 {
        let fm = FileManager.default
        let radice = fm.temporaryDirectory.appendingPathComponent("Prisma-prova-ovunque-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: radice) }
        do {
            try fm.createDirectory(at: radice, withIntermediateDirectories: true)
            try provaCifratura(radice: radice)
            try provaArchivio()
            try provaNomi()
            try provaSpaziLuce()
            try provaSpazio(radice: radice)
            print("Prova di Prisma ovunque riuscita")
            return 0
        } catch let f as Fallita {
            print("ERRORE: \(f.motivo)")
            return 1
        } catch {
            print("ERRORE: \(error.localizedDescription)")
            return 1
        }
    }

    // MARK: - Cifratura a chiave dello spazio (algoritmo 2) e backup v1

    private static func provaCifratura(radice: URL) throws {
        let sale = try CifraturaBackup.casuali(CifraturaBackup.lunghezzaSale)
        let madre = try CifraturaBackup.chiaveSpazio(passphrase: passphrase, sale: sale, iterazioni: iterazioni)
        let altra = try CifraturaBackup.chiaveSpazio(passphrase: passphraseNuova, sale: sale, iterazioni: iterazioni)
        try controlla(CifraturaBackup.verificaSpazio(madre) != CifraturaBackup.verificaSpazio(altra),
                      "la verifica dello spazio non distingue due passphrase")
        // Più segmenti (2,5 MiB), un segmento esatto e un file vuoto tornano uguali
        let grande = Data((0..<(5 << 19)).map { UInt8(truncatingIfNeeded: $0 &* 31 &+ 7) })
        let esatto = Data(repeating: 42, count: CifraturaBackup.dimensioneSegmento)
        for chiaro in [grande, esatto, Data(), Data(testoSegreto.utf8)] {
            let cifrato = try CifraturaBackup.cifra(chiaro, chiave: madre, uso: SpazioOvunque.usoIstantanea)
            try controlla(try CifraturaBackup.decifra(cifrato, chiave: madre, uso: SpazioOvunque.usoIstantanea) == chiaro,
                          "un file dello spazio (\(chiaro.count) byte) non torna uguale")
        }
        let cifrato = try CifraturaBackup.cifra(grande, chiave: madre, uso: SpazioOvunque.usoIstantanea)
        try controlla(cifrato.range(of: grande.prefix(64)) == nil, "il file dello spazio contiene i dati in chiaro")
        try controlla(cifrato[9] == CifraturaBackup.algoritmoSpazio, "il file dello spazio non dichiara l'algoritmo 2")
        // Chiave sbagliata o uso sbagliato (il giornale di un altro dispositivo) → password errata
        try controlla(erroreBackup(erroreDi { _ = try CifraturaBackup.decifra(cifrato, chiave: altra, uso: SpazioOvunque.usoIstantanea) },
                                   .passwordErrata), "una chiave sbagliata non è riconosciuta")
        try controlla(erroreBackup(erroreDi { _ = try CifraturaBackup.decifra(cifrato, chiave: madre, uso: SpazioOvunque.usoGiornale("x")) },
                                   .passwordErrata), "un file aperto con l'uso di un altro non è rifiutato")
        // Troncato a metà segmento, senza l'ultimo segmento intero, con un byte cambiato → danneggiato
        let senzaUltimo = cifrato.prefix(CifraturaBackup.lunghezzaIntestazione + 4 + CifraturaBackup.dimensioneSegmento + CifraturaBackup.aggiuntaSegmento)
        var alterato = cifrato
        alterato[alterato.count - 100] ^= 0x01
        for rotto in [cifrato.prefix(cifrato.count - 9), senzaUltimo, alterato] {
            try controlla(erroreBackup(erroreDi { _ = try CifraturaBackup.decifra(Data(rotto), chiave: madre, uso: SpazioOvunque.usoIstantanea) },
                                       .backupDanneggiato), "un file dello spazio troncato o alterato si apre")
        }
        // I backup dell'algoritmo 1 si aprono come prima; un file dello spazio non si apre come backup
        let fm = FileManager.default
        let chiaro = radice.appendingPathComponent("chiaro.zip")
        let backup = radice.appendingPathComponent("backup.zip.cifrato")
        let ritorno = radice.appendingPathComponent("ritorno.zip")
        let spazio = radice.appendingPathComponent("spazio.cifrato")
        try grande.write(to: chiaro)
        try CifraturaBackup.cifra(chiaro, in: backup, password: passphrase, iterazioni: iterazioni)
        try CifraturaBackup.decifra(backup, in: ritorno, password: passphrase)
        try controlla(try Data(contentsOf: ritorno) == grande, "un backup protetto (algoritmo 1) non torna uguale")
        try cifrato.write(to: spazio)
        try controlla(CifraturaBackup.cifrato(backup) && CifraturaBackup.cifrato(spazio), "i file PRISMACF non si riconoscono")
        try? fm.removeItem(at: ritorno)
        try controlla(erroreBackup(erroreDi { try CifraturaBackup.decifra(spazio, in: ritorno, password: passphrase) }, .archivioMancante),
                      "un file dello spazio si apre come un backup")
        try controlla(!fm.fileExists(atPath: ritorno.path), "un tentativo non riuscito lascia un file decifrato")
        for u in [chiaro, backup, spazio] { try? fm.removeItem(at: u) }
    }

    // MARK: - Impostazioni dello spazio nell'archivio (versione 26, tolleranti)

    private static func provaArchivio() throws {
        var dati = DatiPrisma.demo()
        var o = ImpostazioniOvunque()
        try controlla(!o.acceso && o.modificheDaiDispositivi && o.prossimoSeq == 1, "lo spazio non nasce spento")
        o.acceso = true
        o.ruolo = .dispositivo
        o.idDispositivo = idTelefono
        o.nomeDispositivo = "iPhone di prova"
        o.segnalibro = Data([1, 2, 3, 4])
        o.percorso = "/percorso/di/prova"
        o.generazioneChiave = 3
        o.generazione = 7
        o.vistoFinoA = ["dispositivo-a": 4]
        o.lamport = 12
        o.prossimoSeq = 9
        o.ultimaIstantanea = ora(1)
        o.impronteCartella = ["istantanea.cifrato": "10·0·1"]
        dati.impostazioni.ovunque = o
        let codificato = try Archivio.codificatore.encode(dati)
        let letto = try Archivio.decodifica(codificato)
        try controlla(letto.impostazioni.ovunque == o, "le impostazioni dello spazio non tornano uguali dall'archivio")
        try controlla(DatiPrisma.versioneAttuale >= 26, "l'archivio con Prisma ovunque deve essere almeno alla versione 26")

        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var impostazioni = radice["impostazioni"] as? [String: Any] else {
            throw Fallita(motivo: "archivio di prova non preparato")
        }
        // Un archivio di prima, senza lo spazio: si apre spento e il resto è uguale
        impostazioni.removeValue(forKey: "ovunque")
        radice["impostazioni"] = impostazioni
        for k in ["giornaleOvunque", "conflittiOvunque", "arriviOvunque", "inquadratureDaConfermare"] { radice.removeValue(forKey: k) }
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        try controlla(senza.impostazioni.ovunque == ImpostazioniOvunque() && senza.giornaleOvunque.isEmpty && senza.conflittiOvunque.isEmpty
                      && senza.clienti == letto.clienti, "un archivio senza Prisma ovunque non si apre con lo spazio spento")
        // Impostazioni illeggibili: spazio spento, archivio aperto
        impostazioni["ovunque"] = "non sono impostazioni"
        radice["impostazioni"] = impostazioni
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        try controlla(!illeggibile.impostazioni.ovunque.acceso && illeggibile.clienti.count == dati.clienti.count,
                      "impostazioni dello spazio illeggibili: archivio non aperto con lo spazio spento")
        // Un campo illeggibile prende il valore di base, gli altri restano
        impostazioni["ovunque"] = ["acceso": "sì", "idDispositivo": idTelefono, "prossimoSeq": 5, "ruolo": "tostapane"] as [String: Any]
        radice["impostazioni"] = impostazioni
        let parziale = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice)).impostazioni.ovunque
        try controlla(!parziale.acceso && parziale.idDispositivo == idTelefono && parziale.prossimoSeq == 5
                      && parziale.ruolo == RuoloOvunque.predefinito, "lettura tollerante delle impostazioni dello spazio")
        // Un'operazione illeggibile del giornale si scarta, le altre restano
        let buona: [String: Any] = ["id": "op-1", "dispositivo": idTelefono, "lamport": 1, "seq": 1, "data": "2026-11-04T10:00:00Z",
                                    "base": 1, "entita": "nota", "entitaId": "nota-x", "tipo": "elimina", "prima": "{}"]
        var futura = buona
        futura["id"] = "op-2"
        futura["entita"] = "entitaDelFuturo"
        radice["giornaleOvunque"] = [buona, futura, "non è un'operazione"] as [Any]
        let conGiornale = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        try controlla(conGiornale.giornaleOvunque.map(\.id) == ["op-1"], "un'operazione illeggibile del giornale non si scarta da sola")
    }

    // MARK: - Nomi dei file

    // MARK: - «Luce», giro 1: le app nuove negli spazi di lavoro dell'istantanea (decisione 104)

    /// Lo spazio con le quattro app di Luce va nell'istantanea e torna uguale; un'app che chi legge non conosce (un
    /// Prisma più nuovo) si salta senza perdere lo spazio né gli altri dati.
    private static func provaSpaziLuce() throws {
        var dati = DatiPrisma.demo()
        let luce = SpazioLavoro(id: "spazio-luce", nome: "Sala con il cliente",
                                finestre: [.sinistra(.sala), .destra(.territorio), .sinistra(.pratiche), .destra(.biblioteca)])
        dati.spazi = [luce]
        let istantanea = SpazioOvunque.datiIstantanea(dati)
        try controlla(istantanea.spazi == [luce], "lo spazio con le app di Luce non entra nell'istantanea")
        let chiaro = try JSONOvunque.codificatore().encode(istantanea)
        let letto = try JSONOvunque.decodificatore().decode(DatiPrisma.self, from: chiaro)
        try controlla(letto.spazi == [luce], "lo spazio con le app di Luce non torna uguale dall'istantanea")
        // Un'app sconosciuta al posto della Biblioteca: la finestra si salta, lo spazio resta
        guard var radice = try JSONSerialization.jsonObject(with: chiaro) as? [String: Any],
              var spazi = radice["spazi"] as? [[String: Any]], var finestre = spazi.first?["finestre"] as? [[String: Any]],
              finestre.count == 4 else {
            throw Fallita(motivo: "istantanea di prova con un'app sconosciuta non preparata")
        }
        finestre[3]["app"] = "appDiUnPrismaPiuNuovo"
        spazi[0]["finestre"] = finestre
        radice["spazi"] = spazi
        let tollerante = try JSONOvunque.decodificatore().decode(DatiPrisma.self, from: JSONSerialization.data(withJSONObject: radice))
        try controlla(tollerante.spazi.first?.finestre.map(\.app) == luce.finestre.prefix(3).map(\.app)
                      && tollerante.clienti == letto.clienti && tollerante.posizioni == letto.posizioni,
                      "un'app sconosciuta in uno spazio dell'istantanea fa perdere lo spazio o l'archivio")
        try controlla(DatiPrisma.versioneAttuale >= 27, "l'archivio di Luce deve essere almeno alla versione 27")
    }

    private static func provaNomi() throws {
        try controlla(FileSpazio.riconosci("prisma-ovunque.json") == .descrittore, "descrittore non riconosciuto")
        try controlla(FileSpazio.riconosci("istantanea.cifrato") == .istantanea(copia: nil), "istantanea non riconosciuta")
        try controlla(FileSpazio.riconosci("istantanea 2.cifrato") == .istantanea(copia: 2), "copia «istantanea 2» non riconosciuta")
        try controlla(FileSpazio.riconosci("giornale-dispositivo-ab12.cifrato") == .giornale(dispositivo: "dispositivo-ab12", copia: nil),
                      "giornale non riconosciuto")
        try controlla(FileSpazio.riconosci("giornale-dispositivo-ab12 3.cifrato") == .giornale(dispositivo: "dispositivo-ab12", copia: 3),
                      "copia «giornale 3» non riconosciuta")
        for estraneo in ["Prisma backup 2026.zip.cifrato", "giornale-.cifrato", "note.txt", ".istantanea.cifrato.icloud"] {
            try controlla(FileSpazio.riconosci(estraneo) == nil, "«\(estraneo)» scambiato per un file dello spazio")
        }
    }

    // MARK: - Due archivi e una cartella che finge iCloud

    private static func provaSpazio(radice: URL) throws {
        let fm = FileManager.default
        let url = radice.appendingPathComponent("iCloud Drive/Prisma ovunque", isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        let icloud = CartellaOvunqueFinta(url: url)

        // Il Mac: i dati di prova passati una volta dall'archivio (date al secondo, come sul disco)
        var mac = try Archivio.decodifica(Archivio.codificatore.encode(DatiPrisma.demo()))
        try controlla(mac.clienti.count >= 3 && mac.note.count >= 2 && !mac.attivita.isEmpty, "i dati di prova non hanno note e attività")
        try controlla((erroreDi { _ = try SpazioOvunque.creaSpazio(in: icloud, passphrase: "corta", mac: idMac, iterazioni: iterazioni) }
                       as? ErroreOvunque) == .passphraseCorta, "una passphrase corta è accettata")
        var chiaveMac = try SpazioOvunque.creaSpazio(in: icloud, passphrase: passphrase, mac: idMac, iterazioni: iterazioni, adesso: ora(0))
        try controlla((erroreDi { _ = try SpazioOvunque.creaSpazio(in: icloud, passphrase: passphrase, mac: idMac, iterazioni: iterazioni) }
                       as? ErroreOvunque) == .spazioGiaPresente, "uno spazio già presente è stato sovrascritto")
        // Spento: nessuna sincronizzazione
        try controlla((erroreDi { _ = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud) } as? ErroreOvunque)
                      == .spazioMancante, "lo spazio spento sincronizza")
        mac.impostazioni.ovunque.accendi(ruolo: .mac, id: idMac, nome: "Mac di prova", chiave: chiaveMac)
        var em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(1))
        mac = em.dati
        try controlla(em.istantaneaScritta && mac.impostazioni.ovunque.generazione == 1, "la prima istantanea non è stata scritta")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(2))
        mac = em.dati
        try controlla(!em.istantaneaScritta && mac.impostazioni.ovunque.generazione == 1, "istantanea riscritta senza nessuna modifica")

        // L'iPhone: archivio vuoto con una conversazione sua
        var tel = DatiPrisma(clienti: [], appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: "", impostazioni: Impostazioni())
        tel.conversazioni["solo-telefono"] = [MessaggioVera(autore: .utente, testo: "Resta sul telefono")]
        tel.impostazioni.aspetto = .scuro
        try controlla((erroreDi { _ = try SpazioOvunque.apri(in: icloud, passphrase: "passphrase sbagliata") } as? ErroreOvunque)
                      == .passphraseErrata, "una passphrase sbagliata apre lo spazio")
        var chiaveTel = try SpazioOvunque.apri(in: icloud, passphrase: passphrase)
        _ = try SpazioOvunque.apri(in: icloud, chiave: chiaveTel.byte)
        tel.impostazioni.ovunque.accendi(ruolo: .dispositivo, id: idTelefono, nome: "iPhone di prova", chiave: chiaveTel)
        var et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(3))
        tel = et.dati
        try controlla(et.istantaneaNuova && tel.clienti == mac.clienti && tel.note == mac.note && tel.attivita == mac.attivita
                      && tel.posizioni == mac.posizioni, "l'iPhone non ha ricevuto l'archivio del Mac")
        try controlla(tel.conversazioni["solo-telefono"]?.count == 1 && tel.impostazioni.aspetto == .scuro
                      && tel.impostazioni.ovunque.idDispositivo == idTelefono && tel.impostazioni.ovunque.generazione == 1,
                      "l'istantanea ha cancellato ciò che è solo del telefono")

        // 1. Andata e ritorno: una nota e un'attività create sull'iPhone
        let cid = mac.clienti[0].id
        var prima = tel
        let notaTel = Nota(id: "nota-telefono-1", clienteId: cid, titolo: "Dal cliente", testo: testoSegreto, creataIl: ora(4), aggiornataIl: ora(4))
        tel.note.append(notaTel)
        let attivitaTel = Attivita(id: "task-telefono-1", clienteId: cid, titolo: "Richiamare per la casa", scadenza: ora(600),
                                   priorita: .alta, completata: false)
        tel.attivita.append(attivitaTel)
        try controlla(RegistroOvunque.registra(prima: prima, dopo: &tel, adesso: ora(4)) == 2
                      && tel.giornaleOvunque.map(\.seq) == [1, 2] && tel.giornaleOvunque.map(\.tipo) == [.crea, .crea]
                      && tel.giornaleOvunque[1].lamport > tel.giornaleOvunque[0].lamport, "il giornale dell'iPhone non registra le modifiche")
        let giornaleAndata = tel.giornaleOvunque
        // Ritardo di iCloud: il giornale è partito ma non è arrivato
        icloud.ritardo = true
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(5))
        tel = et.dati
        try controlla(et.giornaleScritto && !icloud.inViaggio.isEmpty, "il giornale non è stato scritto")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(6))
        mac = em.dati
        try controlla(em.unite.isEmpty && !mac.note.contains { $0.id == notaTel.id }, "unita una modifica non ancora arrivata")
        icloud.ritardo = false
        try icloud.consegna()
        // File non ancora scaricato sul Mac: si aspetta, niente errore
        let nomeGiornale = SpazioOvunque.nomeGiornale(idTelefono)
        icloud.nonScaricati.insert(nomeGiornale)
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(7))
        mac = em.dati
        try controlla(em.inAttesa == [nomeGiornale] && em.unite.isEmpty, "un giornale non scaricato non è segnalato in attesa")
        icloud.nonScaricati.removeAll()
        // Copia «nome 2» fatta da iCloud: unita senza doppioni, poi eliminata
        let macPrimaDellUnione = mac
        let copia = "giornale-\(idTelefono) 2.cifrato"
        try icloud.duplica(nomeGiornale, in: copia)
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(8))
        mac = em.dati
        try controlla(em.unite.count == 2 && em.conflitti.isEmpty && mac.note.filter { $0.id == notaTel.id }.count == 1
                      && mac.attivita.filter { $0.id == attivitaTel.id }.count == 1, "la copia del giornale ha dato doppioni")
        try controlla(mac.note.first { $0.id == notaTel.id } == notaTel && mac.attivita.first { $0.id == attivitaTel.id } == attivitaTel,
                      "la nota o l'attività dell'iPhone non arrivano uguali sul Mac")
        try controlla(!(try icloud.elenca()).contains { $0.nome == copia }, "la copia del giornale non è stata eliminata")
        try controlla(em.istantaneaScritta && mac.impostazioni.ovunque.generazione == 2
                      && mac.impostazioni.ovunque.vistoFinoA[idTelefono] == 2 && mac.arriviOvunque.count == 2,
                      "dopo l'unione l'istantanea, la ricevuta o gli arrivi non sono aggiornati")
        // 2. Idempotenza: lo stesso giornale unito di nuovo dà lo stesso archivio, anche senza la ricevuta
        let g = GiornaleOvunque(dispositivo: idTelefono, nomeDispositivo: "iPhone di prova", scrittoIl: ora(5), operazioni: giornaleAndata)
        let r1 = MotoreUnioneOvunque.unisci([g], in: macPrimaDellUnione, vistoFinoA: macPrimaDellUnione.impostazioni.ovunque.vistoFinoA,
                                            lamport: 0, adesso: ora(8))
        let r2 = MotoreUnioneOvunque.unisci([g, g], in: r1.dati, vistoFinoA: r1.vistoFinoA, lamport: r1.lamport, adesso: ora(9))
        let r3 = MotoreUnioneOvunque.unisci([g], in: r1.dati, vistoFinoA: [:], lamport: r1.lamport, adesso: ora(9))
        try controlla(r1.dati.note == mac.note && r1.dati.attivita == mac.attivita && r2.dati == r1.dati && r2.unite.isEmpty
                      && r3.dati == r1.dati && r3.conflitti.isEmpty, "l'unione ripetuta non dà lo stesso archivio")
        // Ritorno: l'iPhone vede le sue modifiche confermate e svuota il giornale
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(9))
        tel = et.dati
        try controlla(et.istantaneaNuova && et.confermate == 2 && tel.giornaleOvunque.isEmpty && tel.note.contains(notaTel)
                      && tel.impostazioni.ovunque.generazione == 2, "l'iPhone non ha svuotato il giornale dopo la conferma")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(10))
        mac = em.dati
        try controlla(em.unite.isEmpty && !em.istantaneaScritta, "un giornale vuoto ha cambiato il Mac")

        // 3-5. Conflitti: stesso campo, campi diversi, eliminazione contro modifica, cliente che non c'è più
        let n0 = mac.note[0].id
        let n1 = mac.note[1].id
        let a0 = mac.attivita[0].id
        let assente = mac.clienti[mac.clienti.count - 1].id
        prima = tel
        guard let t0 = tel.note.firstIndex(where: { $0.id == n0 }), let t1 = tel.note.firstIndex(where: { $0.id == n1 }) else {
            throw Fallita(motivo: "le note del Mac non sono sull'iPhone")
        }
        tel.note[t0].testo = "Testo scritto sull'iPhone"
        let fissataTel = !tel.note[t1].fissata
        tel.note[t1].fissata = fissataTel
        tel.attivita.removeAll { $0.id == a0 }
        tel.note.append(Nota(id: "nota-orfana", clienteId: assente, titolo: "Per un cliente che non c'è più", testo: "", creataIl: ora(11),
                             aggiornataIl: ora(11)))
        try controlla(RegistroOvunque.registra(prima: prima, dopo: &tel, adesso: ora(11)) == 4, "il giornale non registra quattro modifiche")
        guard let m0 = mac.note.firstIndex(where: { $0.id == n0 }), let m1 = mac.note.firstIndex(where: { $0.id == n1 }),
              let ma = mac.attivita.firstIndex(where: { $0.id == a0 }) else {
            throw Fallita(motivo: "note o attività mancanti sul Mac")
        }
        mac.note[m0].testo = "Testo scritto sul Mac"
        mac.note[m1].titolo = "Titolo cambiato sul Mac"
        mac.attivita[ma].titolo = "Attività cambiata sul Mac"
        mac.clienti.removeAll { $0.id == assente }
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(12))
        tel = et.dati
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(13))
        mac = em.dati
        let motivi = Set(em.conflitti.map(\.motivo))
        try controlla(em.conflitti.count == 3 && em.unite.count == 1 && motivi == [.stessoCampo, .eliminataSulDispositivo, .clienteMancante]
                      && mac.conflittiOvunque.count == 3, "i conflitti non sono finiti in «Da decidere» (\(em.conflitti.count))")
        try controlla(mac.note.first { $0.id == n0 }?.testo == "Testo scritto sul Mac", "un conflitto ha sovrascritto il valore del Mac")
        try controlla(mac.note.first { $0.id == n1 }?.titolo == "Titolo cambiato sul Mac" && mac.note.first { $0.id == n1 }?.fissata == fissataTel,
                      "due campi diversi della stessa nota non si sono uniti")
        try controlla(mac.attivita.contains { $0.id == a0 } && !mac.note.contains { $0.id == "nota-orfana" },
                      "eliminazione contro modifica o nota orfana decise in silenzio")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(14))
        mac = em.dati
        try controlla(em.conflitti.isEmpty && mac.conflittiOvunque.count == 3, "un conflitto è entrato due volte")
        // Le scelte: «Tieni quella dell'iPhone» per la nota, «Tieni quella del Mac» per l'attività; niente orfani
        guard let cNota = mac.conflittiOvunque.first(where: { $0.motivo == .stessoCampo }),
              let cAttivita = mac.conflittiOvunque.first(where: { $0.motivo == .eliminataSulDispositivo }),
              let cOrfana = mac.conflittiOvunque.first(where: { $0.motivo == .clienteMancante }) else {
            throw Fallita(motivo: "conflitti attesi non trovati")
        }
        try controlla(cNota.valoreMac == JSONOvunque.canonico("Testo scritto sul Mac") && cNota.nomeDispositivo == "iPhone di prova",
                      "il conflitto non ricorda il valore del Mac e il dispositivo")
        try controlla(MotoreUnioneOvunque.decidi(cNota.id, scelta: .tieniDispositivo, in: &mac, adesso: ora(15))
                      && mac.note.first { $0.id == n0 }?.testo == "Testo scritto sull'iPhone", "«Tieni quella dell'iPhone» non applica la modifica")
        try controlla(!MotoreUnioneOvunque.decidi(cOrfana.id, scelta: .tieniDispositivo, in: &mac, adesso: ora(15)),
                      "una nota per un cliente che non c'è più è entrata")
        try controlla(MotoreUnioneOvunque.decidi(cOrfana.id, scelta: .tieniMac, in: &mac, adesso: ora(15))
                      && MotoreUnioneOvunque.decidi(cAttivita.id, scelta: .tieniMac, in: &mac, adesso: ora(15))
                      && mac.conflittiOvunque.isEmpty && mac.attivita.contains { $0.id == a0 }, "le scelte «Tieni quella del Mac» non chiudono i conflitti")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(16))
        mac = em.dati
        try controlla(em.istantaneaScritta, "le scelte sui conflitti non riscrivono l'istantanea")
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(17))
        tel = et.dati
        try controlla(et.confermate == 4 && tel.giornaleOvunque.isEmpty && tel.note.first { $0.id == n0 }?.testo == "Testo scritto sull'iPhone"
                      && tel.attivita.contains { $0.id == a0 } && tel.clienti == mac.clienti, "l'iPhone non vede le scelte del Mac")

        // 8. Riapplicazione: un'operazione unita e una ancora sul telefono quando arriva l'istantanea nuova
        prima = tel
        tel.note.append(Nota(id: "nota-telefono-2", clienteId: cid, titolo: "Seconda nota", testo: "Appunti", creataIl: ora(18), aggiornataIl: ora(18)))
        RegistroOvunque.registra(prima: prima, dopo: &tel, adesso: ora(18))
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(18))
        tel = et.dati
        prima = tel
        guard let ta = tel.attivita.firstIndex(where: { $0.id == attivitaTel.id }) else { throw Fallita(motivo: "attività dell'iPhone sparita") }
        tel.attivita[ta].completata = true
        RegistroOvunque.registra(prima: prima, dopo: &tel, adesso: ora(19))
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(20))
        mac = em.dati
        try controlla(em.unite.count == 1 && mac.note.contains { $0.id == "nota-telefono-2" }
                      && mac.attivita.first { $0.id == attivitaTel.id }?.completata == false, "la prima operazione non è stata unita da sola")
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(21))
        tel = et.dati
        try controlla(et.istantaneaNuova && et.confermate == 1 && et.riapplicate == 1 && tel.giornaleOvunque.count == 1
                      && tel.attivita.first { $0.id == attivitaTel.id }?.completata == true, "l'operazione in sospeso non è stata riapplicata")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(22))
        mac = em.dati
        try controlla(em.unite.count == 1 && mac.attivita.first { $0.id == attivitaTel.id }?.completata == true,
                      "l'operazione riapplicata non è arrivata al Mac")

        // 7. File troncati: l'istantanea si rifiuta (l'iPhone tiene i suoi dati), il giornale si ignora
        try icloud.tronca(SpazioOvunque.nomeIstantanea, togli: 7)
        try controlla((erroreDi { _ = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(23)) }
                       as? ErroreOvunque) == .fileDanneggiato(SpazioOvunque.nomeIstantanea), "un'istantanea troncata si apre")
        try icloud.tronca(nomeGiornale, togli: 5)
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, forza: true, adesso: ora(24))
        mac = em.dati
        try controlla(em.illeggibili == [nomeGiornale] && em.istantaneaScritta, "un giornale troncato ferma il Mac")
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(25))
        tel = et.dati
        try controlla(et.istantaneaNuova && et.giornaleScritto, "dopo un file troncato l'iPhone non riparte")
        // «istantanea 2»: vince la generazione più alta scritta dentro il file, non la data
        let g0 = mac.impostazioni.ovunque.generazione
        try SpazioOvunque.scriviIstantanea(mac, generazione: g0 + 10, vistoFinoA: [:], lamport: 0, mac: idMac, nomeMac: "Mac di prova",
                                           modificheAmmesse: true, chiave: chiaveMac, in: icloud, adesso: ora(26))
        try icloud.duplica(SpazioOvunque.nomeIstantanea, in: "istantanea 2.cifrato")
        try SpazioOvunque.scriviIstantanea(mac, generazione: g0 + 1, vistoFinoA: [:], lamport: 0, mac: idMac, nomeMac: "Mac di prova",
                                           modificheAmmesse: true, chiave: chiaveMac, in: icloud, adesso: ora(27))
        try controlla(try SpazioOvunque.leggiIstantanea(chiave: chiaveTel, in: icloud).istantanea?.generazione == g0 + 10,
                      "tra due copie dell'istantanea non vince la generazione più alta")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, forza: true, adesso: ora(28))
        mac = em.dati
        try controlla(!(try icloud.elenca()).contains { $0.nome == "istantanea 2.cifrato" }, "la copia dell'istantanea non è stata eliminata")
        // Istantanea non ancora scaricata sull'iPhone: in attesa, niente errore
        icloud.nonScaricati.insert(SpazioOvunque.nomeIstantanea)
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(29))
        try controlla(et.inAttesaDiICloud && !et.istantaneaNuova, "un'istantanea non scaricata non è segnalata in attesa")
        icloud.nonScaricati.removeAll()
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(30))
        tel = et.dati

        // Un altro Mac con la stessa chiave: solo lettura
        var altro = mac
        altro.impostazioni.ovunque.idDispositivo = "mac-altro"
        try controlla((erroreDi { _ = try SincroniaOvunque.sincronizzaMac(altro, chiave: chiaveMac, cartella: icloud) } as? ErroreOvunque)
                      == .spazioDiAltroMac, "un secondo Mac scrive l'istantanea")

        // Passphrase cambiata sul Mac: prima si unisce, poi la chiave nuova; l'iPhone chiede la nuova e non perde nulla
        prima = tel
        guard let tb = tel.attivita.firstIndex(where: { $0.id == attivitaTel.id }) else { throw Fallita(motivo: "attività dell'iPhone sparita") }
        tel.attivita[tb].note = "Scritta prima della passphrase nuova"
        RegistroOvunque.registra(prima: prima, dopo: &tel, adesso: ora(31))
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(31))
        tel = et.dati
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(32))
        mac = em.dati
        let chiaveVecchia = chiaveMac
        chiaveMac = try SpazioOvunque.cambiaPassphrase(in: icloud, attuale: chiaveMac, nuova: passphraseNuova, iterazioni: iterazioni, adesso: ora(33))
        mac.impostazioni.ovunque.generazioneChiave = chiaveMac.descrittore.generazioneChiave
        try controlla(chiaveMac.descrittore.generazioneChiave == chiaveVecchia.descrittore.generazioneChiave + 1,
                      "la generazione della chiave non è cambiata")
        try controlla((erroreDi { _ = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveVecchia, cartella: icloud) } as? ErroreOvunque)
                      == .generazioneCambiata, "la chiave di prima vale ancora sul Mac")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, forza: true, adesso: ora(34))
        mac = em.dati
        try controlla(em.istantaneaScritta && em.illeggibili == [nomeGiornale] && mac.attivita.first { $0.id == attivitaTel.id }?.note
                      == "Scritta prima della passphrase nuova", "il cambio di passphrase ha perso l'operazione già unita")
        let telPrima = tel
        prima = tel
        guard let tc = tel.attivita.firstIndex(where: { $0.id == attivitaTel.id }) else { throw Fallita(motivo: "attività dell'iPhone sparita") }
        tel.attivita[tc].priorita = .bassa
        RegistroOvunque.registra(prima: prima, dopo: &tel, adesso: ora(35))
        try controlla((erroreDi { _ = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(35)) }
                       as? ErroreOvunque) == .generazioneCambiata && telPrima.giornaleOvunque.count + 1 == tel.giornaleOvunque.count,
                      "l'iPhone non si accorge della passphrase nuova")
        try controlla((erroreDi { _ = try SpazioOvunque.apri(in: icloud, chiave: chiaveTel.byte) } as? ErroreOvunque) == .generazioneCambiata
                      && (erroreDi { _ = try SpazioOvunque.apri(in: icloud, passphrase: passphrase) } as? ErroreOvunque) == .passphraseErrata,
                      "la chiave o la passphrase di prima aprono lo spazio")
        chiaveTel = try SpazioOvunque.apri(in: icloud, passphrase: passphraseNuova)
        tel.impostazioni.ovunque.generazioneChiave = chiaveTel.descrittore.generazioneChiave
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(36))
        tel = et.dati
        try controlla(et.istantaneaNuova && et.confermate == 1 && et.riapplicate == 1 && tel.giornaleOvunque.count == 1
                      && tel.attivita.first { $0.id == attivitaTel.id }?.priorita == .bassa, "con la passphrase nuova l'iPhone ha perso le modifiche")
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, adesso: ora(37))
        mac = em.dati
        try controlla(em.unite.count == 1 && em.illeggibili.isEmpty && mac.attivita.first { $0.id == attivitaTel.id }?.priorita == .bassa,
                      "il giornale ricifrato con la chiave nuova non è stato unito")

        // Copia di sola lettura («Lavora anche con il Mac spento» spento sul Mac): l'iPhone non scrive il giornale
        mac.impostazioni.ovunque.modificheDaiDispositivi = false
        em = try SincroniaOvunque.sincronizzaMac(mac, chiave: chiaveMac, cartella: icloud, forza: true, adesso: ora(38))
        mac = em.dati
        et = try SincroniaOvunque.sincronizzaDispositivo(tel, chiave: chiaveTel, cartella: icloud, adesso: ora(39))
        tel = et.dati
        prima = tel
        tel.note.append(Nota(clienteId: cid, titolo: "Sola lettura", testo: ""))
        try controlla(!tel.impostazioni.ovunque.modificheDaiDispositivi && RegistroOvunque.registra(prima: prima, dopo: &tel) == 0,
                      "la copia di sola lettura scrive il giornale")
        // E sul Mac nessun dispositivo registra
        var suMac = mac
        let primaMac = suMac
        suMac.note.append(Nota(clienteId: cid, titolo: "Sul Mac", testo: ""))
        try controlla(RegistroOvunque.registra(prima: primaMac, dopo: &suMac) == 0 && suMac.giornaleOvunque.isEmpty, "il Mac scrive un giornale")

        // 9. Nessun dato in chiaro nella cartella condivisa; passphrase e chiave mai nell'archivio
        let segreti = [Data(testoSegreto.utf8), Data(mac.clienti[0].nome.utf8), Data("Testo scritto sull'iPhone".utf8)]
        for f in try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
            let contenuto = try Data(contentsOf: f)
            for s in segreti {
                try controlla(contenuto.range(of: s) == nil, "«\(f.lastPathComponent)» contiene dati dei clienti in chiaro")
            }
        }
        for archivio in [mac, tel] {
            let testo = String(decoding: try Archivio.codificatore.encode(archivio), as: UTF8.self)
            for vietato in [passphrase, passphraseNuova, chiaveMac.byte.base64EncodedString(), chiaveVecchia.byte.base64EncodedString()] {
                try controlla(!testo.contains(vietato), "la passphrase o la chiave sono finite nell'archivio")
            }
        }
        // FSEvents sul Mac: l'osservatore parte e si ferma (gli eventi veri li dà iCloud Drive)
        #if os(macOS)
        let osservatore = OsservatoreCartellaOvunque(cartella: url) {}
        try controlla(osservatore.avvia() && osservatore.attivo, "FSEvents non osserva la cartella")
        osservatore.ferma()
        try controlla(!osservatore.attivo, "FSEvents non si ferma")
        #endif
        // Il controllo all'attivazione si accorge di un file cambiato
        let impronte = try icloud.impronte()
        try controlla(!SpazioOvunque.cartellaCambiata(icloud, rispetto: impronte), "una cartella ferma risulta cambiata")
        try icloud.reale.sostituisci("giornale-dispositivo-nuovo.cifrato", con: Data([1, 2, 3]))
        try controlla(SpazioOvunque.cartellaCambiata(icloud, rispetto: impronte), "un giornale nuovo non si nota al controllo")
        // Il ritmo dell'istantanea: a gruppi
        try controlla(!RitmoIstantanea.daScrivere(.modifica, archivioCambiato: true, ultima: ora(0), adesso: ora(5))
                      && RitmoIstantanea.daScrivere(.modifica, archivioCambiato: true, ultima: ora(0), adesso: ora(10))
                      && RitmoIstantanea.daScrivere(.uscita, archivioCambiato: true, ultima: ora(0), adesso: ora(1))
                      && !RitmoIstantanea.daScrivere(.uscita, archivioCambiato: false, ultima: ora(0), adesso: ora(1))
                      && RitmoIstantanea.attesa(ultima: ora(0), adesso: ora(4)) == 6 * 60, "il ritmo delle istantanee non raggruppa")
    }
}
