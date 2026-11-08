import CryptoKit
import Foundation

// Prisma ovunque (Design/ovunque-fattibilita.md §3-4, giro 8): lo spazio cifrato nella cartella scelta dall'utente.
//   prisma-ovunque.json              in chiaro: formato, generazione della chiave, sale, iterazioni, verifica, nessun dato
//   istantanea.cifrato               scritta SOLO dal Mac: archivio + generazione + «visto fino a» di ogni dispositivo
//   giornale-<dispositivo>.cifrato   scritto SOLO da quel dispositivo: le sue operazioni non ancora confermate
// I file .cifrato sono «PRISMACF» dell'algoritmo 2 (`CifraturaBackup`): la chiave madre nasce dalla passphrase con il sale
// dello spazio, ogni file ha la sua chiave (HKDF). In chiaro restano solo i nomi dei file, che non dicono nulla dei clienti.
// Il lavoro (cifratura, lettura e scrittura coordinate) va fatto fuori dal thread principale.

/// La chiave madre dello spazio con il descrittore che l'ha verificata. Vive in memoria e nel Portachiavi, mai nell'archivio.
struct ChiaveSpazio {
    let descrittore: DescrittoreSpazio
    let madre: SymmetricKey

    /// I 32 byte da salvare nel Portachiavi del dispositivo (`PortachiaviOvunque`).
    var byte: Data { madre.withUnsafeBytes { Data($0) } }
}

/// I file dello spazio riconosciuti dal nome, con le copie fatte da iCloud («istantanea 2.cifrato»).
enum FileSpazio: Equatable {
    case descrittore
    /// copia: nil per il file vero, n per «… n.cifrato».
    case istantanea(copia: Int?)
    case giornale(dispositivo: String, copia: Int?)

    static func riconosci(_ nome: String) -> FileSpazio? {
        if nome == SpazioOvunque.nomeDescrittore { return .descrittore }
        guard nome.hasSuffix(SpazioOvunque.estensione) else { return nil }
        var base = String(nome.dropLast(SpazioOvunque.estensione.count))
        var copia: Int?
        if let spazio = base.lastIndex(of: " ") {
            let numero = base[base.index(after: spazio)...]
            if !numero.isEmpty, numero.allSatisfy(\.isNumber), let n = Int(numero) {
                copia = n
                base = String(base[..<spazio])
            }
        }
        if base == "istantanea" { return .istantanea(copia: copia) }
        if base.hasPrefix("giornale-") {
            let dispositivo = String(base.dropFirst("giornale-".count))
            return dispositivo.isEmpty ? nil : .giornale(dispositivo: dispositivo, copia: copia)
        }
        return nil
    }
}

enum SpazioOvunque {
    static let nomeDescrittore = "prisma-ovunque.json"
    static let estensione = ".cifrato"
    static let nomeIstantanea = "istantanea" + estensione
    static func nomeGiornale(_ dispositivo: String) -> String { "giornale-\(dispositivo)" + estensione }

    /// Gli usi di HKDF: ogni tipo di file ha la sua chiave, e un giornale non si apre come quello di un altro dispositivo.
    static let usoIstantanea = "PrismaOV v1 · istantanea"
    static func usoGiornale(_ dispositivo: String) -> String { "PrismaOV v1 · giornale \(dispositivo)" }

    // MARK: - Chiave e descrittore

    static func descrittore(in c: CartellaCondivisa) throws -> DescrittoreSpazio {
        let dati: Data
        do {
            dati = try c.leggi(nomeDescrittore)
        } catch ErroreOvunque.fileMancante(_) {
            throw ErroreOvunque.spazioMancante
        }
        guard let d = try? JSONOvunque.decodificatore().decode(DescrittoreSpazio.self, from: dati) else {
            throw ErroreOvunque.fileDanneggiato(nomeDescrittore)
        }
        guard d.formato <= DescrittoreSpazio.formatoAttuale else { throw ErroreOvunque.versionePiuRecente }
        return d
    }

    /// Mac, prima attivazione: crea lo spazio (sale nuovo, generazione 1) con la passphrase dell'utente.
    static func creaSpazio(in c: CartellaCondivisa, passphrase: String, mac: String,
                           iterazioni: UInt32 = CifraturaBackup.iterazioniPredefinite, adesso: Date = Date()) throws -> ChiaveSpazio {
        guard passphrase.count >= ErroreOvunque.lunghezzaMinimaPassphrase else { throw ErroreOvunque.passphraseCorta }
        if try c.elenca().contains(where: { $0.nome == nomeDescrittore }) { throw ErroreOvunque.spazioGiaPresente }
        return try scriviDescrittore(in: c, passphrase: passphrase, mac: mac, generazione: 1, iterazioni: iterazioni, adesso: adesso)
    }

    /// Mac: passphrase nuova (sale nuovo, generazione della chiave + 1). Prima conviene unire i giornali con la chiave di
    /// prima; poi si riscrive l'istantanea con la chiave nuova. I dispositivi chiedono la passphrase nuova.
    static func cambiaPassphrase(in c: CartellaCondivisa, attuale: ChiaveSpazio, nuova: String,
                                 iterazioni: UInt32 = CifraturaBackup.iterazioniPredefinite, adesso: Date = Date()) throws -> ChiaveSpazio {
        guard nuova.count >= ErroreOvunque.lunghezzaMinimaPassphrase else { throw ErroreOvunque.passphraseCorta }
        let d = try controlla(attuale, in: c)
        return try scriviDescrittore(in: c, passphrase: nuova, mac: d.proprietario, generazione: d.generazioneChiave + 1,
                                     iterazioni: iterazioni, adesso: adesso)
    }

    /// Apre lo spazio con la passphrase (PBKDF2 una volta per sessione). Sbagliata → `.passphraseErrata`.
    static func apri(in c: CartellaCondivisa, passphrase: String) throws -> ChiaveSpazio {
        let d = try descrittore(in: c)
        let madre: SymmetricKey
        do {
            madre = try CifraturaBackup.chiaveSpazio(passphrase: passphrase, sale: d.sale, iterazioni: d.iterazioni)
        } catch {
            throw ErroreOvunque.passphraseErrata
        }
        guard CifraturaBackup.verificaSpazio(madre) == d.verifica else { throw ErroreOvunque.passphraseErrata }
        return ChiaveSpazio(descrittore: d, madre: madre)
    }

    /// Apre lo spazio con la chiave del Portachiavi. Non vale più (passphrase cambiata) → `.generazioneCambiata`.
    static func apri(in c: CartellaCondivisa, chiave byte: Data) throws -> ChiaveSpazio {
        let d = try descrittore(in: c)
        guard byte.count == 32 else { throw ErroreOvunque.generazioneCambiata }
        let madre = SymmetricKey(data: byte)
        guard CifraturaBackup.verificaSpazio(madre) == d.verifica else { throw ErroreOvunque.generazioneCambiata }
        return ChiaveSpazio(descrittore: d, madre: madre)
    }

    /// La chiave in mano vale ancora per lo spazio? Il descrittore attuale, o `.generazioneCambiata`.
    @discardableResult
    static func controlla(_ chiave: ChiaveSpazio, in c: CartellaCondivisa) throws -> DescrittoreSpazio {
        let d = try descrittore(in: c)
        guard d.generazioneChiave == chiave.descrittore.generazioneChiave, d.sale == chiave.descrittore.sale,
              d.verifica == CifraturaBackup.verificaSpazio(chiave.madre) else {
            throw ErroreOvunque.generazioneCambiata
        }
        return d
    }

    private static func scriviDescrittore(in c: CartellaCondivisa, passphrase: String, mac: String, generazione: Int,
                                          iterazioni: UInt32, adesso: Date) throws -> ChiaveSpazio {
        let sale = try CifraturaBackup.casuali(CifraturaBackup.lunghezzaSale)
        let madre = try CifraturaBackup.chiaveSpazio(passphrase: passphrase, sale: sale, iterazioni: iterazioni)
        let d = DescrittoreSpazio(generazioneChiave: generazione, sale: sale, iterazioni: iterazioni,
                                  verifica: CifraturaBackup.verificaSpazio(madre), proprietario: mac,
                                  creatoIl: RegistroOvunque.alSecondo(adesso))
        let codificatore = JSONOvunque.codificatore()
        codificatore.outputFormatting = [.sortedKeys, .prettyPrinted]
        try c.sostituisci(nomeDescrittore, con: codificatore.encode(d))
        return ChiaveSpazio(descrittore: d, madre: madre)
    }

    // MARK: - Istantanea (solo il Mac la scrive)

    /// L'archivio come va nell'istantanea: senza conversazioni di Vera, senza trascrizioni del copilota, senza le impostazioni
    /// del Mac (Vera, spazio) e senza giornale. I documenti (file) non ci sono: il telefono vede i dati estratti.
    static func datiIstantanea(_ d: DatiPrisma) -> DatiPrisma {
        var x = d
        x.conversazioni = [:]
        // Le partite del gioco del rischio restano sul Mac (decisione 44)
        x.partiteRischio = []
        // Spese, scadenze, corsi e le loro impostazioni (km per cliente, correzioni) restano sul Mac («Luce» giro 9):
        // sono dati personali del consulente e l'iPhone non ha Studio › Spese
        x.speseStudio = ArchivioSpese()
        x.kmClienti = [:]
        x.impostazioni.studio.spese = ImpostazioniSpese()
        x.giornaleOvunque = []
        x.impostazioni.ovunque = ImpostazioniOvunque()
        x.impostazioni.vera = ImpostazioniVera()
        x.sessioniCopilota = x.sessioniCopilota.map(CampiOvunque.senzaTrascrizione)
        // Mai la trascrizione della nota vocale (fase 3 di Vera): un resoconto non firmato che viene da una nota vocale
        // resta sul Mac finché non è firmato (le sue righe possono essere frasi della trascrizione), e delle promesse
        // dette nella nota vocale va solo la cosa da fare, non la frase
        x.incontri = x.incontri.map { i in
            var c = i
            c.resoconto?.trascrizione = nil
            if let r = c.resoconto, !r.firmato, r.fonti.contains(.notaVocale) { c.resoconto = nil }
            return c
        }
        x.promesse = x.promesse.map { p in
            var q = p
            if q.fonteEtichetta.hasPrefix("dalla nota vocale") { q.frase = "" }
            return q
        }
        return x
    }

    /// L'impronta del contenuto dell'istantanea (SHA-256 del JSON canonico): se non cambia, l'istantanea non si riscrive.
    static func impronta(_ d: DatiPrisma) -> String? {
        guard let dati = try? JSONOvunque.codificatore().encode(datiIstantanea(d)) else { return nil }
        return SHA256.hash(data: dati).map { String(format: "%02x", $0) }.joined()
    }

    static func scriviIstantanea(_ dati: DatiPrisma, generazione: Int, vistoFinoA: [String: Int], lamport: Int, mac: String,
                                 nomeMac: String, modificheAmmesse: Bool, chiave: ChiaveSpazio, in c: CartellaCondivisa,
                                 adesso: Date = Date()) throws {
        let istantanea = IstantaneaOvunque(generazione: generazione, mac: mac, nomeMac: nomeMac, scrittaIl: RegistroOvunque.alSecondo(adesso),
                                           vistoFinoA: vistoFinoA, lamport: lamport, modificheAmmesse: modificheAmmesse,
                                           dati: datiIstantanea(dati))
        let chiaro = try JSONOvunque.codificatore().encode(istantanea)
        let cifrato = try CifraturaBackup.cifra(chiaro, chiave: chiave.madre, uso: usoIstantanea)
        try c.sostituisci(nomeIstantanea, con: cifrato)
    }

    struct LetturaIstantanea {
        /// La migliore: la generazione più alta scritta dentro il file (non la data del file).
        var istantanea: IstantaneaOvunque?
        /// Almeno una copia è in iCloud ma non ancora sul dispositivo.
        var inAttesa = false
        var danneggiate: [String] = []
    }

    /// Legge l'istantanea (e le sue copie «istantanea n.cifrato»). Se c'è solo una copia danneggiata → `.fileDanneggiato`.
    static func leggiIstantanea(chiave: ChiaveSpazio, in c: CartellaCondivisa) throws -> LetturaIstantanea {
        var r = LetturaIstantanea()
        let decodificatore = JSONOvunque.decodificatore()
        for v in try c.elenca() {
            guard case .istantanea? = FileSpazio.riconosci(v.nome) else { continue }
            guard v.scaricato else {
                _ = try? c.leggi(v.nome)   // fa partire lo scaricamento
                r.inAttesa = true
                continue
            }
            do {
                let grezzo = try c.leggi(v.nome)
                let chiaro = try CifraturaBackup.decifra(grezzo, chiave: chiave.madre, uso: usoIstantanea)
                let ist = try decodificatore.decode(IstantaneaOvunque.self, from: chiaro)
                guard ist.formato <= IstantaneaOvunque.formatoAttuale, !Archivio.diVersionePiuRecente(ist.dati) else {
                    throw ErroreOvunque.versionePiuRecente
                }
                if ist.generazione > (r.istantanea?.generazione ?? Int.min) { r.istantanea = ist }
            } catch ErroreOvunque.inAttesaDiICloud(_) {
                r.inAttesa = true
            } catch ErroreOvunque.versionePiuRecente {
                throw ErroreOvunque.versionePiuRecente
            } catch ErroreBackup.versionePiuRecente {
                throw ErroreOvunque.versionePiuRecente
            } catch {
                r.danneggiate.append(v.nome)
            }
        }
        if r.istantanea == nil, !r.inAttesa, let prima = r.danneggiate.first { throw ErroreOvunque.fileDanneggiato(prima) }
        return r
    }

    // MARK: - Giornali (ognuno lo scrive solo il suo dispositivo)

    static func scriviGiornale(_ g: GiornaleOvunque, chiave: ChiaveSpazio, in c: CartellaCondivisa) throws {
        let chiaro = try JSONOvunque.codificatore().encode(g)
        let cifrato = try CifraturaBackup.cifra(chiaro, chiave: chiave.madre, uso: usoGiornale(g.dispositivo))
        try c.sostituisci(nomeGiornale(g.dispositivo), con: cifrato)
    }

    struct LetturaGiornali {
        var giornali: [GiornaleOvunque] = []
        /// File in iCloud non ancora su questo Mac (lo scaricamento è partito).
        var inAttesa: [String] = []
        /// File troncati, alterati o cifrati con una chiave di prima: si ignorano finché non arriva una copia buona.
        var illeggibili: [String] = []
        /// Le copie «giornale-x n.cifrato» lette: dopo l'unione si eliminano.
        var copieLette: [String] = []
    }

    /// Legge i giornali di tutti i dispositivi (tranne `escluso`), copie comprese. Un file illeggibile non ferma gli altri.
    static func leggiGiornali(chiave: ChiaveSpazio, in c: CartellaCondivisa, escluso: String? = nil) throws -> LetturaGiornali {
        var r = LetturaGiornali()
        let decodificatore = JSONOvunque.decodificatore()
        for v in try c.elenca() {
            guard case .giornale(let dispositivo, let copia)? = FileSpazio.riconosci(v.nome), dispositivo != escluso else { continue }
            guard v.scaricato else {
                _ = try? c.leggi(v.nome)
                r.inAttesa.append(v.nome)
                continue
            }
            do {
                let grezzo = try c.leggi(v.nome)
                let chiaro = try CifraturaBackup.decifra(grezzo, chiave: chiave.madre, uso: usoGiornale(dispositivo))
                let g = try decodificatore.decode(GiornaleOvunque.self, from: chiaro)
                guard g.dispositivo == dispositivo, g.formato <= GiornaleOvunque.formatoAttuale else {
                    r.illeggibili.append(v.nome)
                    continue
                }
                r.giornali.append(g)
                if copia != nil { r.copieLette.append(v.nome) }
            } catch ErroreOvunque.inAttesaDiICloud(_) {
                r.inAttesa.append(v.nome)
            } catch {
                r.illeggibili.append(v.nome)
            }
        }
        return r
    }

    /// Spegnendo lo spazio sul Mac: si cancellano l'istantanea e le sue copie (i dati restano sul Mac). I giornali sono dei
    /// dispositivi e il descrittore resta: riaccendendo si riapre con la stessa passphrase.
    static func cancellaIstantanea(in c: CartellaCondivisa) throws {
        for v in try c.elenca() {
            if case .istantanea? = FileSpazio.riconosci(v.nome) { try c.elimina(v.nome) }
        }
    }

    /// Il controllo all'attivazione (avvio, risveglio, finestra di nuovo attiva; su iOS il ritorno in primo piano):
    /// true se i file della cartella sono cambiati rispetto alle impronte dell'ultimo controllo.
    static func cartellaCambiata(_ c: CartellaCondivisa, rispetto impronte: [String: String]) -> Bool {
        guard let attuali = try? c.impronte() else { return true }
        return attuali != impronte
    }
}

/// Quando il Mac riscrive l'istantanea: a gruppi, mai a ogni tasto. Ogni scrittura carica in iCloud l'intero file.
enum MotivoIstantanea {
    /// L'archivio è cambiato sul Mac.
    case modifica
    /// Prisma si chiude o il Mac va a riposo.
    case uscita
    /// «Sincronizza ora» o un giornale nuovo appena unito.
    case manuale
}

enum RitmoIstantanea {
    /// Al massimo un'istantanea ogni 10 minuti per le modifiche fatte sul Mac.
    static let intervallo: TimeInterval = 10 * 60

    static func daScrivere(_ motivo: MotivoIstantanea, archivioCambiato: Bool, ultima: Date?, adesso: Date = Date()) -> Bool {
        switch motivo {
        case .manuale: return true
        case .uscita: return archivioCambiato
        case .modifica:
            guard archivioCambiato else { return false }
            guard let ultima else { return true }
            return adesso.timeIntervalSince(ultima) >= intervallo
        }
    }

    /// Fra quanto riprovare quando una modifica arriva prima dell'intervallo (per un `asyncAfter`, niente Timer).
    static func attesa(ultima: Date?, adesso: Date = Date()) -> TimeInterval {
        guard let ultima else { return 0 }
        return max(0, intervallo - adesso.timeIntervalSince(ultima))
    }
}

/// Il risultato di una sincronizzazione sul Mac.
struct EsitoSincroniaMac {
    var dati: DatiPrisma
    var unite: [OperazioneOvunque]
    var conflitti: [ConflittoOvunque]
    var scartate: Int
    var inAttesa: [String]
    var illeggibili: [String]
    var istantaneaScritta: Bool
}

/// Il risultato di una sincronizzazione su iPhone o iPad.
struct EsitoSincroniaDispositivo {
    var dati: DatiPrisma
    /// È arrivata un'istantanea nuova del Mac.
    var istantaneaNuova: Bool
    /// Operazioni del giornale confermate dal Mac (tolte dal giornale).
    var confermate: Int
    /// Operazioni ancora in sospeso riapplicate sopra l'istantanea nuova.
    var riapplicate: Int
    var inAttesaDiICloud: Bool
    var giornaleScritto: Bool

    /// Le modifiche ancora in attesa di arrivare al Mac.
    var inSospeso: Int { dati.giornaleOvunque.count }
}

enum SincroniaOvunque {
    /// Mac: legge i giornali, li unisce (conflitti in «Da decidere»), salva la ricevuta e riscrive l'istantanea se qualcosa
    /// è cambiato (o con `forza`). Le copie «nome 2» lette si eliminano. Da chiamare fuori dal thread principale; chi
    /// chiama salva `dati` dell'esito nell'archivio.
    static func sincronizzaMac(_ dati: DatiPrisma, chiave: ChiaveSpazio, cartella c: CartellaCondivisa, forza: Bool = false,
                               adesso: Date = Date()) throws -> EsitoSincroniaMac {
        var d = dati
        let o = d.impostazioni.ovunque
        guard o.acceso, o.ruolo == .mac, let mac = o.idDispositivo else { throw ErroreOvunque.spazioMancante }
        let descrittore = try SpazioOvunque.controlla(chiave, in: c)
        guard descrittore.proprietario == mac else { throw ErroreOvunque.spazioDiAltroMac }

        var lettura = SpazioOvunque.LetturaGiornali()
        var unite: [OperazioneOvunque] = []
        var conflitti: [ConflittoOvunque] = []
        var scartate = 0
        if o.modificheDaiDispositivi {
            lettura = try SpazioOvunque.leggiGiornali(chiave: chiave, in: c, escluso: mac)
            let u = MotoreUnioneOvunque.unisci(lettura.giornali, in: d, vistoFinoA: o.vistoFinoA, lamport: o.lamport, adesso: adesso)
            d = u.dati
            d.impostazioni.ovunque.vistoFinoA = u.vistoFinoA
            d.impostazioni.ovunque.lamport = u.lamport
            unite = u.unite
            conflitti = u.conflitti
            scartate = u.scartate
        }

        let impronta = SpazioOvunque.impronta(d)
        let manca = try !c.elenca().contains { $0.nome == SpazioOvunque.nomeIstantanea }
        let daScrivere = forza || manca || o.generazione == 0 || impronta == nil || impronta != o.improntaIstantanea
            || d.impostazioni.ovunque.vistoFinoA != o.vistoFinoA
        var scritta = false
        if daScrivere {
            let generazione = o.generazione + 1
            try SpazioOvunque.scriviIstantanea(d, generazione: generazione, vistoFinoA: d.impostazioni.ovunque.vistoFinoA,
                                               lamport: d.impostazioni.ovunque.lamport, mac: mac, nomeMac: o.nomeDispositivo ?? "Mac",
                                               modificheAmmesse: o.modificheDaiDispositivi, chiave: chiave, in: c, adesso: adesso)
            d.impostazioni.ovunque.generazione = generazione
            d.impostazioni.ovunque.improntaIstantanea = impronta
            d.impostazioni.ovunque.ultimaIstantanea = RegistroOvunque.alSecondo(adesso)
            scritta = true
            // Il Mac è l'unico scrittore dell'istantanea: le copie fatte da iCloud non servono più
            for v in (try? c.elenca()) ?? [] {
                if case .istantanea(let copia)? = FileSpazio.riconosci(v.nome), copia != nil { try? c.elimina(v.nome) }
            }
        }
        // Le copie dei giornali sono state unite (o erano già viste): via, senza doppioni
        for nome in lettura.copieLette { try? c.elimina(nome) }
        d.impostazioni.ovunque.ultimoControllo = RegistroOvunque.alSecondo(adesso)
        d.impostazioni.ovunque.ultimoErrore = nil
        d.impostazioni.ovunque.impronteCartella = (try? c.impronte()) ?? [:]
        return EsitoSincroniaMac(dati: d, unite: unite, conflitti: conflitti, scartate: scartate, inAttesa: lettura.inAttesa,
                                 illeggibili: lettura.illeggibili, istantaneaScritta: scritta)
    }

    /// iPhone e iPad: scrive prima il proprio giornale (le modifiche sopravvivono anche se il telefono si perde), poi legge
    /// l'istantanea del Mac; se è nuova la accoglie, toglie dal giornale le operazioni confermate e riapplica sopra quelle
    /// ancora in sospeso. Un file non ancora scaricato non è un errore (`inAttesaDiICloud`).
    static func sincronizzaDispositivo(_ dati: DatiPrisma, chiave: ChiaveSpazio, cartella c: CartellaCondivisa,
                                       adesso: Date = Date()) throws -> EsitoSincroniaDispositivo {
        var d = dati
        let o = d.impostazioni.ovunque
        guard o.acceso, o.ruolo == .dispositivo, let mio = o.idDispositivo else { throw ErroreOvunque.spazioMancante }
        try SpazioOvunque.controlla(chiave, in: c)
        let nomeGiornale = SpazioOvunque.nomeGiornale(mio)
        let cera = try c.elenca().contains { $0.nome == nomeGiornale }
        var giornaleScritto = false
        if !d.giornaleOvunque.isEmpty || cera {
            try SpazioOvunque.scriviGiornale(giornale(d, dispositivo: mio, adesso: adesso), chiave: chiave, in: c)
            giornaleScritto = true
        }
        let lettura = try SpazioOvunque.leggiIstantanea(chiave: chiave, in: c)
        var nuova = false
        var confermate = 0
        var riapplicate = 0
        if let ist = lettura.istantanea, ist.generazione != o.generazione {
            let accolta = accogli(ist, in: d)
            d = accolta.dati
            confermate = accolta.confermate
            riapplicate = accolta.riapplicate
            nuova = true
            if confermate > 0 {
                try SpazioOvunque.scriviGiornale(giornale(d, dispositivo: mio, adesso: adesso), chiave: chiave, in: c)
                giornaleScritto = true
            }
        }
        d.impostazioni.ovunque.ultimoControllo = RegistroOvunque.alSecondo(adesso)
        d.impostazioni.ovunque.ultimoErrore = nil
        d.impostazioni.ovunque.impronteCartella = (try? c.impronte()) ?? [:]
        return EsitoSincroniaDispositivo(dati: d, istantaneaNuova: nuova, confermate: confermate, riapplicate: riapplicate,
                                         inAttesaDiICloud: lettura.inAttesa && !nuova, giornaleScritto: giornaleScritto)
    }

    /// Il giornale del dispositivo con le operazioni ancora in sospeso.
    static func giornale(_ d: DatiPrisma, dispositivo: String, adesso: Date) -> GiornaleOvunque {
        GiornaleOvunque(dispositivo: dispositivo, nomeDispositivo: d.impostazioni.ovunque.nomeDispositivo ?? "iPhone",
                        scrittoIl: RegistroOvunque.alSecondo(adesso), operazioni: d.giornaleOvunque)
    }

    /// Sul dispositivo: l'istantanea del Mac al posto dell'archivio, tenendo ciò che è solo del dispositivo (conversazioni
    /// con Vera, aspetto, impostazioni dello spazio) e riapplicando le operazioni non ancora confermate.
    static func accogli(_ ist: IstantaneaOvunque, in locale: DatiPrisma) -> (dati: DatiPrisma, confermate: Int, riapplicate: Int) {
        var nuovo = ist.dati
        let o = locale.impostazioni.ovunque
        let confermato = o.idDispositivo.flatMap { ist.vistoFinoA[$0] } ?? 0
        let inSospeso = locale.giornaleOvunque.filter { $0.seq > confermato }.sorted { $0.seq < $1.seq }

        nuovo.conversazioni = locale.conversazioni
        nuovo.partiteRischio = locale.partiteRischio
        nuovo.speseStudio = locale.speseStudio
        nuovo.kmClienti = locale.kmClienti
        let mie = locale.impostazioni
        var imp = nuovo.impostazioni
        imp.vera = mie.vera
        imp.studio.spese = mie.studio.spese
        imp.aspetto = mie.aspetto
        imp.dimensioneTesto = mie.dimensioneTesto
        imp.sfondoAnimato = mie.sfondoAnimato
        imp.pioggia = mie.pioggia
        imp.acquaDellaScrivania = mie.acquaDellaScrivania
        imp.riduciMovimento = mie.riduciMovimento
        imp.backup = mie.backup
        imp.promemoria = mie.promemoria
        imp.introduzioneVista = mie.introduzioneVista
        imp.guidaNascosta = mie.guidaNascosta
        imp.ovunque = o
        imp.ovunque.generazione = ist.generazione
        imp.ovunque.lamport = max(o.lamport, ist.lamport)
        imp.ovunque.modificheDaiDispositivi = ist.modificheAmmesse
        imp.ovunque.ultimaIstantanea = ist.scrittaIl
        nuovo.impostazioni = imp
        if nuovo.clienti.contains(where: { $0.id == locale.clienteAttivoId }) { nuovo.clienteAttivoId = locale.clienteAttivoId }

        var riapplicate = 0
        for op in inSospeso {
            if MotoreUnioneOvunque.applicaForzata(op, a: &nuovo) { riapplicate += 1 }
        }
        nuovo.giornaleOvunque = inSospeso
        nuovo.versione = DatiPrisma.versioneAttuale
        return (nuovo, locale.giornaleOvunque.count - inSospeso.count, riapplicate)
    }
}

extension ImpostazioniOvunque {
    /// Accende lo spazio con la chiave appena creata o aperta. La chiave va nel Portachiavi, mai qui.
    mutating func accendi(ruolo: RuoloOvunque, id: String, nome: String, chiave: ChiaveSpazio) {
        acceso = true
        self.ruolo = ruolo
        idDispositivo = id
        nomeDispositivo = nome
        generazioneChiave = chiave.descrittore.generazioneChiave
        ultimoErrore = nil
    }

    /// Spegne lo spazio: niente più file scritti. L'id resta (riaccendendo, il giornale continua dallo stesso progressivo).
    mutating func spegni() {
        acceso = false
        improntaIstantanea = nil
    }
}
