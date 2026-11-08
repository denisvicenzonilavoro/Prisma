import Foundation

// «Il sussurro» (Vera/BRIEF.md, funzione 7; template «Il sussurro», Design/template-vera.html): aprendo il dossier di un
// cliente, Vera mostra al massimo tre cose da sapere adesso, ognuna con un'azione. Solo codice, niente Qwen: regole di
// priorità su consensi, riesame, scadenze delle posizioni, promesse, compleanni e anniversari, liquidità ferma, documento
// d'identità e preferenze dai ricordi di Vera. Le fonti sono quelle che Prisma calcola già: MotoreConformita («In
// regola»), MotoreRiesame.dovuti, MotoreOccasioniMessaggi.compleanni, MotoreNotifiche.prossimoCompleanno, PromesseVera.semaforo
// e le posizioni di liquidità con le spese di Analisi 360 (come ClientelaVera e MotoreCheckUp).
// Motore puro: riceve i dati e `oggi`, niente StatoShell né Date() nascosti. Le azioni che cambiano qualcosa non si
// eseguono qui: `conferma(_:cliente:oggi:)` prepara l'AzioneConferma (un'attività) da mostrare nella scheda «Conferma».

// MARK: - Modelli

/// Il colore della voce: rosso (da fare prima di tutto), arancio (presto), blu (da sapere).
enum TonoSussurro: String, Codable, CaseIterable, Comparable {
    case rosso, arancio, blu

    var ordine: Int {
        switch self {
        case .rosso: return 0
        case .arancio: return 1
        case .blu: return 2
        }
    }

    static func < (a: TonoSussurro, b: TonoSussurro) -> Bool { a.ordine < b.ordine }
}

/// Da quale regola nasce la voce: una voce sola per categoria (la più urgente).
enum CategoriaSussurro: String, Codable, CaseIterable {
    case consensoPrivacy, consensoCommerciale, promessa, scadenza, riesame, documento, liquidita
    case compleanno, anniversario, preferenza
}

/// Che cosa fa il pulsante della voce. La vista decide dove portare (`riferimento`); quando c'è `promemoria` l'azione
/// cambia qualcosa e passa dalla scheda di conferma come attività (`SussurroVera.conferma`).
enum TipoAzioneSussurro: String, Codable, CaseIterable {
    /// Apre «In regola» sul consenso (riferimento: "privacy" o "commerciale").
    case rinnovaConsenso
    /// Apre la promessa (riferimento: id della promessa).
    case apriPromessa
    /// Prepara il rinnovo di una polizza (riferimento: id della posizione).
    case preparaRinnovo
    /// Apre il simulatore o Analisi 360 (riferimento: id della posizione, oppure "liquidita").
    case preparaIpotesi
    /// Aggiunge l'argomento al prossimo incontro (riferimento: id dell'appuntamento, nil se non ce n'è uno).
    case mettiInScaletta
    /// Fissa il riesame in Agenda (tipo revisione).
    case fissaRiesame
    /// Cerca gli orari liberi in Agenda tenendo conto della preferenza.
    case proponiOrario
    /// Invita un familiare al prossimo incontro (riferimento: nome del familiare).
    case invita
    /// Chiede al cliente la copia del documento d'identità nuovo.
    case chiediCopia
    /// Apre l'occasione in Messaggi (riferimento: id dell'occasione, `OccasioneMessaggio.id`).
    case faiAuguri
    /// Nessuna azione da fare: la voce si chiude.
    case tieniAMente
}

struct AzioneSussurro: Codable, Equatable {
    var tipo: TipoAzioneSussurro
    /// «Prepara il rinnovo», «Apri la promessa», «Invita Paolo».
    var titolo: String
    var riferimento: String?
    /// Il titolo dell'attività da segnare dopo «Conferma» (nil: l'azione porta solo in un'app, non cambia niente).
    var promemoria: String?
    /// Entro quando (l'attività): il giorno dell'incontro, una settimana prima della scadenza, oppure oggi.
    var entro: Date?

    init(_ tipo: TipoAzioneSussurro, _ titolo: String, riferimento: String? = nil, promemoria: String? = nil, entro: Date? = nil) {
        self.tipo = tipo
        self.titolo = titolo
        self.riferimento = riferimento
        self.promemoria = promemoria
        self.entro = entro
    }

    /// Cambia qualcosa: passa dalla scheda di conferma.
    var cambia: Bool { promemoria != nil }
}

/// Una voce del sussurro.
struct VoceSussurro: Codable, Equatable, Identifiable {
    /// Stabile tra un calcolo e l'altro («privacy», «promessa-…», «scadenza-pos-…-20261217», «compleanno-2026»):
    /// serve per non ripetere una voce chiusa e per togliere i doppioni.
    var chiave: String
    var clienteId: String
    var categoria: CategoriaSussurro
    var tono: TonoSussurro
    /// Breve, al consulente: «L'Infortuni famiglia scade il 17 dicembre.»
    var testo: String
    var azione: AzioneSussurro
    /// Da dove viene il dato (regola 4): «In regola», «Le promesse», «Posizioni», «La memoria»…
    var fonte: String
    /// Priorità dentro il tono: più basso, più in alto.
    var rango: Int
    /// Il giorno che conta (scadenza, compleanno): ordina a parità di tono e rango.
    var data: Date?

    var id: String { chiave }
}

/// Una voce chiusa dal consulente («Fatto» o ✕): per qualche giorno non torna. Da mettere nell'archivio
/// (`DatiPrisma.sussurriChiusi`), una riga per cliente e chiave.
struct SussurroChiuso: Codable, Equatable {
    var clienteId: String
    var chiave: String
    var chiusoIl: Date
}

/// Tutto quello che serve al sussurro di un cliente.
struct FonteSussurro {
    let oggi: Date
    let cliente: Cliente
    /// Le posizioni del cliente (le altre si ignorano).
    var posizioni: [Posizione] = []
    var appuntamenti: [Appuntamento] = []
    var incontri: [Incontro] = []
    var promesse: [PromessaCliente] = []
    /// L'Analisi 360 salvata del cliente; nil = non salvata (le spese sarebbero stimate: niente voce sulla liquidità).
    var analisi: Analisi360?
    var regole = RegoleConformita()
    /// I ricordi di Vera sul cliente, dal più recente (MemoriaVera, `SussurroVera.ricordi`).
    var ricordi: [String] = []
    /// Le chiavi delle voci chiuse di recente (`SussurroVera.chiuse`).
    var chiuse: Set<String> = []

    init(oggi: Date, cliente: Cliente, posizioni: [Posizione] = [], appuntamenti: [Appuntamento] = [], incontri: [Incontro] = [],
         promesse: [PromessaCliente] = [], analisi: Analisi360? = nil, regole: RegoleConformita = RegoleConformita(),
         ricordi: [String] = [], chiuse: Set<String> = []) {
        self.oggi = oggi
        self.cliente = cliente
        self.posizioni = posizioni.filter { $0.clienteId == cliente.id }
        self.appuntamenti = appuntamenti.filter { $0.clienteId == cliente.id }
        self.incontri = incontri.filter { $0.clienteId == cliente.id }
        self.promesse = promesse.filter { $0.clienteId == cliente.id }
        self.analisi = analisi
        self.regole = regole
        self.ricordi = ricordi
        self.chiuse = chiuse
    }
}

/// Le soglie del sussurro, tutte in un punto.
enum RegoleSussurro {
    /// Mai più di tante voci.
    static let massimoVoci = 3
    /// Dello stesso tono al massimo tante, se ci sono voci di altri toni (il sussurro resta vario, come nel template).
    static let massimoPerTono = 2
    /// Una posizione in essere che scade entro tanti giorni è rossa; entro `giorniScadenza` arancio.
    static let giorniScadenzaRossa = 30
    static let giorniScadenza = 90
    /// Una posizione scaduta da al massimo tanti giorni (ancora «in essere») resta tra le voci, rossa.
    static let giorniScadutaDaPoco = 30
    /// Il documento d'identità in scadenza entro tanti giorni (arancio); scaduto è rosso.
    static let giorniDocumento = 90
    /// L'incontro in agenda entro tanti giorni diventa «la scaletta» delle voci.
    static let giorniIncontro = 30
    /// Un compleanno tondo (decine) entro tanti giorni va in scaletta; uno qualsiasi entro una settimana (Messaggi).
    static let giorniCompleannoTondo = 60
    /// L'anniversario della relazione (da quando è cliente) entro tanti giorni.
    static let giorniAnniversario = 7
    /// Liquidità «ferma»: oltre tanti mesi di spese (come la domanda di «Chiedi alla tua clientela»); arancio da
    /// `mesiLiquiditaAlta`.
    static let mesiLiquiditaFerma = 6.0
    static let mesiLiquiditaAlta = 9.0
    /// Una voce chiusa non torna per tanti giorni.
    static let giorniChiusura = 7
    /// Età in cui un compleanno tondo è il momento della pensione.
    static let etaPensioneDa = 40
    static let etaPensioneA = 60
}

// MARK: - Motore

enum SussurroVera {
    // MARK: Fonti

    /// La fonte del sussurro di un cliente dai dati di Prisma (nil se il cliente non c'è).
    static func fonte(dati: DatiPrisma, clienteId: String, ricordi: [String], chiuse: Set<String> = [], oggi: Date) -> FonteSussurro? {
        guard let c = dati.clienti.first(where: { $0.id == clienteId }) else { return nil }
        return FonteSussurro(oggi: oggi, cliente: c, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti,
                             incontri: dati.incontri, promesse: dati.promesse, analisi: dati.analisi[c.id],
                             regole: dati.impostazioni.conformita, ricordi: ricordi, chiuse: chiuse)
    }

    /// I testi dei ricordi di Vera su un cliente, dal più recente.
    static func ricordi(_ elenco: [RicordoVera], clienteId: String) -> [String] {
        elenco.filter { $0.clienteId == clienteId }
            .sorted { ($0.data, $0.id) > ($1.data, $1.id) }
            .map { $0.testo.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Le chiavi chiuse di un cliente negli ultimi `RegoleSussurro.giorniChiusura` giorni.
    static func chiuse(_ elenco: [SussurroChiuso], clienteId: String, oggi: Date, cal: Calendar = .current) -> Set<String> {
        Set(elenco.filter { s in
            s.clienteId == clienteId && MotoreOccasioniMessaggi.giorni(da: s.chiusoIl, a: oggi, cal: cal) < RegoleSussurro.giorniChiusura
        }.map(\.chiave))
    }

    // MARK: Calcolo

    /// Le voci da mostrare: al massimo tre, senza doppioni, in ordine di tono e priorità.
    static func voci(_ f: FonteSussurro, cal: Calendar = .current) -> [VoceSussurro] {
        scegli(candidate(f, cal: cal))
    }

    /// Comodità per la vista: dai dati di Prisma.
    static func voci(dati: DatiPrisma, clienteId: String, ricordi: [String], chiuse: Set<String> = [], oggi: Date,
                     cal: Calendar = .current) -> [VoceSussurro] {
        guard let f = fonte(dati: dati, clienteId: clienteId, ricordi: ricordi, chiuse: chiuse, oggi: oggi) else { return [] }
        return voci(f, cal: cal)
    }

    /// Tutte le voci possibili, ordinate e senza doppioni (anche oltre tre: per le prove e per «mostra tutto»).
    static func candidate(_ f: FonteSussurro, cal: Calendar = .current) -> [VoceSussurro] {
        var elenco: [VoceSussurro] = []
        let esito = MotoreConformita.calcola(cliente: f.cliente, posizioni: f.posizioni, regole: f.regole, oggi: f.oggi, calendario: cal)
        elenco += consensi(esito, f: f, cal: cal)
        elenco += documento(esito, f: f, cal: cal)
        elenco += promesse(f, cal: cal)
        elenco += scadenze(f, cal: cal)
        elenco += riesame(f, cal: cal)
        elenco += liquidita(f)
        elenco += compleanni(f, cal: cal)
        elenco += anniversario(f, cal: cal)
        elenco += preferenza(f, cal: cal)
        let ordinate = elenco.filter { !f.chiuse.contains($0.chiave) }.sorted(by: precede)
        var chiavi = Set<String>()
        var testi = Set<String>()
        var categorie = Set<CategoriaSussurro>()
        return ordinate.filter { v in
            guard !categorie.contains(v.categoria) else { return false }
            guard chiavi.insert(v.chiave).inserted, testi.insert(normale(v.testo)).inserted else { return false }
            categorie.insert(v.categoria)
            return true
        }
    }

    /// Le prime tre, con al massimo due voci dello stesso tono finché ce ne sono di altri toni.
    static func scegli(_ candidate: [VoceSussurro]) -> [VoceSussurro] {
        let ordinate = candidate.sorted(by: precede)
        var scelte: [VoceSussurro] = []
        var lasciate: [VoceSussurro] = []
        for v in ordinate {
            guard scelte.count < RegoleSussurro.massimoVoci else { break }
            if scelte.filter({ $0.tono == v.tono }).count < RegoleSussurro.massimoPerTono {
                scelte.append(v)
            } else {
                lasciate.append(v)
            }
        }
        // Se mancano voci di altri toni si riempie con quelle lasciate
        for v in lasciate where scelte.count < RegoleSussurro.massimoVoci { scelte.append(v) }
        return scelte.sorted(by: precede)
    }

    /// L'ordine fisso: tono, rango, giorno, chiave.
    static func precede(_ a: VoceSussurro, _ b: VoceSussurro) -> Bool {
        if a.tono != b.tono { return a.tono < b.tono }
        if a.rango != b.rango { return a.rango < b.rango }
        let da = a.data ?? .distantFuture
        let db = b.data ?? .distantFuture
        if da != db { return da < db }
        return a.chiave < b.chiave
    }

    // MARK: Conferma

    /// L'attività da segnare per una voce che cambia qualcosa (nil per le voci che portano solo in un'app). Prisma
    /// la esegue solo dopo «Conferma» (regola 2), con lo strumento «attivita_nuova» del registro.
    static func conferma(_ v: VoceSussurro, cliente: Cliente, oggi: Date, cal: Calendar = .current) -> AzioneConferma? {
        guard let titolo = v.azione.promemoria else { return nil }
        let entro = cal.startOfDay(for: v.azione.entro ?? oggi)
        let giorno = max(entro, cal.startOfDay(for: oggi))
        return AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita,
                              titolo: "Segno un'attività per \(cliente.nome)",
                              dettaglio: "«\(titolo)» · entro \(DateItaliane.descrivi(giorno, conOra: false, oggi: oggi, cal: cal))",
                              argomenti: ["cliente": cliente.id, "titolo": titolo, "scadenza": RegistroStrumenti.isoData(giorno)])
    }

    // MARK: - Le regole

    /// Consenso privacy mancante o da firmare di nuovo (rosso), consenso commerciale scaduto (rosso) o in scadenza (arancio).
    static func consensi(_ e: EsitoConformita, f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        var voci: [VoceSussurro] = []
        let id = f.cliente.id
        if let p = e.voce(.privacy) {
            let rinnovo = AzioneSussurro(.rinnovaConsenso, "Prepara il rinnovo", riferimento: "privacy",
                                         promemoria: "Rinnovare il consenso privacy di \(nome(f.cliente))", entro: f.oggi)
            switch p.stato {
            case .mancante:
                var a = rinnovo
                a.titolo = "Raccogli il consenso"
                a.promemoria = "Raccogliere il consenso privacy di \(nome(f.cliente))"
                voci.append(VoceSussurro(chiave: "privacy", clienteId: id, categoria: .consensoPrivacy, tono: .rosso,
                                         testo: "Manca il consenso privacy: raccoglilo prima di nuove proposte.",
                                         azione: a, fonte: "In regola", rango: 1, data: nil))
            case .scaduta:
                let quando = p.scadenza.map { " " + MotoreOccasioniMessaggi.alGiorno($0) } ?? ""
                voci.append(VoceSussurro(chiave: "privacy", clienteId: id, categoria: .consensoPrivacy, tono: .rosso,
                                         testo: "Il consenso privacy è scaduto\(quando): rinnovalo prima di nuove proposte.",
                                         azione: rinnovo, fonte: "In regola", rango: 1, data: p.scadenza))
            case .entro30, .entro60:
                let quando = p.scadenza.map { MotoreOccasioniMessaggi.alGiorno($0) } ?? "a breve"
                voci.append(VoceSussurro(chiave: "privacy", clienteId: id, categoria: .consensoPrivacy, tono: .arancio,
                                         testo: "L'informativa privacy cambia \(quando): falla firmare di nuovo.",
                                         azione: rinnovo, fonte: "In regola", rango: 13, data: p.scadenza))
            default:
                break
            }
        }
        if let k = e.voce(.commerciale), k.stato == .scaduta || k.stato == .entro30 {
            let scaduto = k.stato == .scaduta
            let quando = k.scadenza.map { MotoreOccasioniMessaggi.alGiorno($0) } ?? ""
            let a = AzioneSussurro(.rinnovaConsenso, "Prepara il rinnovo", riferimento: "commerciale",
                                   promemoria: "Rinnovare il consenso commerciale di \(nome(f.cliente))", entro: k.scadenza ?? f.oggi)
            voci.append(VoceSussurro(chiave: "commerciale", clienteId: id, categoria: .consensoCommerciale,
                                     tono: scaduto ? .rosso : .arancio,
                                     testo: scaduto ? "Il consenso commerciale è scaduto \(quando): rinnovalo prima di proporre."
                                                    : "Il consenso commerciale scade \(quando).",
                                     azione: a, fonte: "In regola", rango: scaduto ? 6 : 14, data: k.scadenza))
        }
        return voci
    }

    /// Il documento d'identità scaduto (rosso) o in scadenza entro 90 giorni (arancio). Senza data scritta niente:
    /// il motore non stima la scadenza.
    static func documento(_ e: EsitoConformita, f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        guard let d = e.voce(.documento), d.stato != .nonRichiesta, let s = d.scadenza, let g = d.giorni,
              g <= RegoleSussurro.giorniDocumento else { return [] }
        let scaduto = g < 0
        let a = AzioneSussurro(.chiediCopia, "Chiedi la copia",
                               promemoria: "Chiedere a \(nome(f.cliente)) la copia del nuovo documento d'identità",
                               entro: scaduto ? f.oggi : s)
        return [VoceSussurro(chiave: "documento-\(MotoreOccasioniMessaggi.timbro(s, cal: cal))", clienteId: f.cliente.id,
                             categoria: .documento, tono: scaduto ? .rosso : .arancio,
                             testo: scaduto ? "Il documento d'identità è scaduto \(MotoreOccasioniMessaggi.alGiorno(s))."
                                            : "Il documento d'identità scade \(MotoreOccasioniMessaggi.alGiorno(s)).",
                             azione: a, fonte: "In regola", rango: scaduto ? 5 : 12, data: s)]
    }

    /// Le promesse aperte o rimandate: in ritardo (rosso) o entro una settimana (arancio). Una voce sola, la più urgente,
    /// con il numero delle altre dello stesso stato.
    static func promesse(_ f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        let aperte = f.promesse.filter { $0.stato == .aperta || $0.stato == .rimandata }
        func data(_ p: PromessaCliente) -> Date { p.scadenzaAttuale ?? .distantFuture }
        let ordina: (PromessaCliente, PromessaCliente) -> Bool = { (data($0), $0.id) < (data($1), $1.id) }
        var voci: [VoceSussurro] = []
        let stati: [(PromesseVera.Semaforo, TonoSussurro, Int)] = [(.inRitardo, .rosso, 2), (.presto, .arancio, 10)]
        for (stato, tono, rango) in stati {
            let elenco = aperte.filter { PromesseVera.semaforo($0, oggi: f.oggi) == stato }.sorted(by: ordina)
            guard let p = elenco.first else { continue }
            let cosa = minuscola(p.testo.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "."))))
            let quando = p.scadenzaAttuale.map { MotoreOccasioniMessaggi.alGiorno($0) } ?? ""
            let testo: String
            if stato == .inRitardo {
                testo = elenco.count == 1 ? "Promessa in ritardo: \(cosa), era per \(quando)."
                                          : "Hai \(elenco.count) promesse in ritardo; la più vecchia: \(cosa), era per \(quando)."
            } else {
                // Le parole della frase solo se dicono ancora il giorno giusto: dopo un rimando o con un'espressione
                // relativa («domani», «tra tre giorni») vale la data calcolata da Prisma
                let parole = p.quando.map { $0.trimmingCharacters(in: .whitespaces) }.flatMap { $0.isEmpty ? nil : $0 }
                let entro = parole.flatMap { p.rimandataAl == nil && !quandoRelativo($0) ? $0 : nil } ?? "entro \(quando)"
                testo = elenco.count == 1 ? "Gli hai promesso di \(cosa) \(entro)."
                                          : "Hai \(elenco.count) promesse in arrivo; la prima: \(cosa) \(entro)."
            }
            voci.append(VoceSussurro(chiave: "promessa-\(p.id)", clienteId: f.cliente.id, categoria: .promessa, tono: tono,
                                     testo: testo, azione: AzioneSussurro(.apriPromessa, "Apri la promessa", riferimento: p.id),
                                     fonte: p.fonteEtichetta.isEmpty ? "Le promesse" : "Le promesse, \(p.fonteEtichetta)",
                                     rango: rango, data: p.scadenzaAttuale))
        }
        // Una voce per categoria: vince la rossa (l'ordine poi la mette davanti)
        return voci
    }

    /// Le posizioni in essere che scadono entro 90 giorni (rosse entro 30) o scadute da poco. Se c'è un incontro in
    /// agenda prima della scadenza, l'azione è «Metti in scaletta».
    static func scadenze(_ f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        let elenco = f.posizioni.compactMap { p -> (Posizione, Date, Int)? in
            guard p.stato == .inEssere, let s = p.scadenza else { return nil }
            let g = MotoreOccasioniMessaggi.giorni(da: f.oggi, a: s, cal: cal)
            guard g >= -RegoleSussurro.giorniScadutaDaPoco, g <= RegoleSussurro.giorniScadenza else { return nil }
            return (p, s, g)
        }.sorted { ($0.1, $0.0.id) < ($1.1, $1.0.id) }
        guard let primo = elenco.first else { return [] }
        let (p, s, g) = primo
        let nomePos = p.nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? p.area.nome : p.nome.trimmingCharacters(in: .whitespacesAndNewlines)
        let rossa = g <= RegoleSussurro.giorniScadenzaRossa
        let incontro = prossimoIncontro(f, prima: s, posizione: p.id, cal: cal)
        var testo: String
        if g < 0 {
            testo = "«\(nomePos)» è scaduta \(MotoreOccasioniMessaggi.alGiorno(s))"
        } else if g == 0 {
            testo = "«\(nomePos)» scade oggi"
        } else {
            testo = "«\(nomePos)» scade \(MotoreOccasioniMessaggi.alGiorno(s))"
        }
        let azione: AzioneSussurro
        if let a = incontro, g >= 0 {
            testo += ": ne parlate \(DateItaliane.descrivi(a.inizio, conOra: false, oggi: f.oggi, cal: cal))"
            azione = AzioneSussurro(.mettiInScaletta, "Metti in scaletta", riferimento: a.id,
                                    promemoria: "Parlare con \(nome(f.cliente)) di «\(nomePos)» in scadenza", entro: a.inizio)
        } else if p.area == .protezione {
            azione = AzioneSussurro(.preparaRinnovo, "Prepara il rinnovo", riferimento: p.id,
                                    promemoria: "Preparare il rinnovo di «\(nomePos)» per \(nome(f.cliente))",
                                    entro: cal.date(byAdding: .day, value: -7, to: s) ?? s)
        } else {
            azione = AzioneSussurro(.preparaIpotesi, "Prepara un'ipotesi", riferimento: p.id)
        }
        let altre = elenco.count - 1
        if altre == 1 { testo += ". Ne scade anche un'altra" } else if altre > 1 { testo += ". Ne scadono anche altre \(altre)" }
        return [VoceSussurro(chiave: "scadenza-\(p.id)-\(MotoreOccasioniMessaggi.timbro(s, cal: cal))", clienteId: f.cliente.id,
                             categoria: .scadenza, tono: rossa ? .rosso : .arancio, testo: testo + ".", azione: azione,
                             fonte: "Posizioni, \(p.canale.nomeBreve)", rango: rossa ? 3 : 11, data: s)]
    }

    /// Il riesame saltato (MotoreRiesame.dovuti, già scaduto): rosso.
    static func riesame(_ f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        guard let r = MotoreRiesame.dovuti(clienti: [f.cliente], posizioni: f.posizioni, appuntamenti: f.appuntamenti,
                                           incontri: f.incontri, oggi: f.oggi).first(where: { $0.scaduto(f.oggi) }) else { return [] }
        let testo: String
        if let u = r.ultimoContatto {
            let mesi = cal.dateComponents([.month], from: u, to: f.oggi).month ?? MotoreRiesame.mesiRiesame
            testo = "Il riesame è saltato: sono passati \(mesi) mesi dall'ultimo incontro."
        } else {
            testo = "Non c'è ancora un incontro registrato: fissa il primo riesame."
        }
        return [VoceSussurro(chiave: "riesame-" + (r.dovutoDal.map { MotoreOccasioniMessaggi.timbro($0, cal: cal) } ?? "mai"),
                             clienteId: f.cliente.id, categoria: .riesame, tono: .rosso, testo: testo,
                             azione: AzioneSussurro(.fissaRiesame, "Fissa il riesame"), fonte: "Agenda e incontri",
                             rango: 4, data: r.dovutoDal)]
    }

    /// La liquidità ferma in mesi di spese (liquidità in essere / fabbisogno mensile di Analisi 360 › Protezione, come
    /// MotoreCheckUp e ClientelaVera). Solo con l'analisi salvata: con le spese stimate la cifra non è del cliente.
    static func liquidita(_ f: FonteSussurro) -> [VoceSussurro] {
        guard let a = f.analisi, a.protezione.fabbisognoMensile > 0 else { return [] }
        let liquidita = f.posizioni.filter { $0.stato == .inEssere && $0.area == .liquidita }.reduce(0) { $0 + $1.valore }
        let mesi = liquidita / a.protezione.fabbisognoMensile
        guard mesi > RegoleSussurro.mesiLiquiditaFerma else { return [] }
        let arrotondati = (mesi * 2).rounded(.down) / 2
        let alta = arrotondati >= RegoleSussurro.mesiLiquiditaAlta
        return [VoceSussurro(chiave: "liquidita", clienteId: f.cliente.id, categoria: .liquidita, tono: alta ? .arancio : .blu,
                             testo: "Ha \(mesiTesto(arrotondati)) mesi di spese ferme in liquidità.",
                             azione: AzioneSussurro(.preparaIpotesi, "Prepara un'ipotesi", riferimento: "liquidita"),
                             fonte: "Posizioni e Analisi 360", rango: alta ? 15 : 23, data: nil)]
    }

    /// Il compleanno della settimana (MotoreOccasioniMessaggi.compleanni: gli auguri in Messaggi) e quello tondo dei
    /// prossimi due mesi (in scaletta: dai 40 ai 60 anni è il momento della pensione). Stessa chiave: vince il primo.
    static func compleanni(_ f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        let c = f.cliente
        guard let n = c.dataNascita else { return [] }
        let inizio = cal.startOfDay(for: f.oggi)
        var voci: [VoceSussurro] = []
        if let o = MotoreOccasioniMessaggi.compleanni([c], posizioni: [:], inizio: inizio, cal: cal).first {
            voci.append(VoceSussurro(chiave: "compleanno-\(cal.component(.year, from: o.data))", clienteId: c.id,
                                     categoria: .compleanno, tono: .blu, testo: o.perche + ".",
                                     azione: AzioneSussurro(.faiAuguri, "Fai gli auguri", riferimento: o.id),
                                     fonte: "La scheda", rango: 20, data: o.data))
        }
        if let d = MotoreNotifiche.prossimoCompleanno(n, da: inizio, cal: cal) {
            let g = MotoreOccasioniMessaggi.giorni(da: inizio, a: d, cal: cal)
            let anni = cal.component(.year, from: d) - cal.component(.year, from: n)
            if anni > 0, anni % 10 == 0, g >= 0, g <= RegoleSussurro.giorniCompleannoTondo {
                let pensione = anni >= RegoleSussurro.etaPensioneDa && anni <= RegoleSussurro.etaPensioneA
                let incontro = prossimoIncontro(f, prima: nil, posizione: nil, cal: cal)
                let argomento = pensione ? "la pensione" : "i suoi progetti"
                voci.append(VoceSussurro(chiave: "compleanno-\(cal.component(.year, from: d))", clienteId: c.id,
                                         categoria: .compleanno, tono: .blu,
                                         testo: "\(quandoMese(d, oggi: inizio, cal: cal)) compie \(anni) anni: è il momento giusto per parlare \(pensione ? "della pensione" : "dei suoi progetti").",
                                         azione: AzioneSussurro(.mettiInScaletta, "Metti in scaletta", riferimento: incontro?.id,
                                                                promemoria: "Parlare con \(nome(c)) di \(argomento) (compie \(anni) anni)",
                                                                entro: incontro?.inizio ?? d),
                                         fonte: "La scheda", rango: 21, data: d))
            }
        }
        return voci
    }

    /// L'anniversario della relazione (dal giorno in cui è cliente in Prisma) entro una settimana.
    static func anniversario(_ f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        let inizio = cal.startOfDay(for: f.oggi)
        guard let d = MotoreNotifiche.prossimoCompleanno(f.cliente.creatoIl, da: inizio, cal: cal) else { return [] }
        let anni = cal.component(.year, from: d) - cal.component(.year, from: f.cliente.creatoIl)
        let g = MotoreOccasioniMessaggi.giorni(da: inizio, a: d, cal: cal)
        guard anni > 0, g >= 0, g <= RegoleSussurro.giorniAnniversario else { return [] }
        let quando: String
        switch g {
        case 0: quando = "Oggi"
        case 1: quando = "Domani"
        default: quando = maiuscola(MotoreOccasioniMessaggi.alGiorno(d))
        }
        let durata = anni == 1 ? "un anno" : "\(anni) anni"
        return [VoceSussurro(chiave: "anniversario-\(cal.component(.year, from: d))", clienteId: f.cliente.id,
                             categoria: .anniversario, tono: .blu,
                             testo: "\(quando) sono \(durata) da quando è tuo cliente.",
                             azione: AzioneSussurro(.tieniAMente, "Tienilo a mente"), fonte: "La scheda", rango: 24, data: d)]
    }

    /// Le preferenze dai ricordi di Vera: decide con qualcuno (invitalo), orari e modi di sentirsi (proponi un orario),
    /// altre preferenze (tienilo a mente). Una voce sola: il ricordo più recente che ne contiene una.
    static func preferenza(_ f: FonteSussurro, cal: Calendar) -> [VoceSussurro] {
        let incontro = prossimoIncontro(f, prima: nil, posizione: nil, cal: cal)
        for ricordo in f.ricordi {
            let t = piega(ricordo)
            let azione: AzioneSussurro
            var rango = 22
            if let chi = conChi(ricordo, cliente: f.cliente) {
                azione = AzioneSussurro(.invita, "Invita \(chi)", riferimento: chi,
                                        promemoria: "Invitare \(chi) al prossimo incontro con \(nome(f.cliente))",
                                        entro: incontro?.inizio ?? f.oggi)
            } else if contieneParola(t, paroleOrari) {
                azione = AzioneSussurro(.proponiOrario, "Proponi un orario")
            } else if contieneParola(t, parolePreferenze) {
                azione = AzioneSussurro(.tieniAMente, "Tienilo a mente")
                rango = 25
            } else {
                continue
            }
            return [VoceSussurro(chiave: "preferenza-\(normale(ricordo).prefix(40))", clienteId: f.cliente.id,
                                 categoria: .preferenza, tono: .blu, testo: frase(ricordo), azione: azione,
                                 fonte: "La memoria di Vera", rango: rango, data: nil)]
        }
        return []
    }

    // MARK: - Aiuti

    /// Le parole dei ricordi che parlano di orari e modi di sentirsi.
    static let paroleOrari = ["videochiam", "telefon", "chiamat", "mattin", "pomerigg", "sera", "orari", "lunedi", "martedi",
                              "mercoledi", "giovedi", "venerdi", "sabato", "non puo", "whatsapp", "in studio", "a casa sua"]
    /// Le parole delle altre preferenze.
    static let parolePreferenze = ["prefer", "non ama", "ama", "non vuole", "vuole", "evita", "detesta", "odia", "decide",
                                   "gli piace", "le piace", "non si fida", "si fida", "tiene a", "tiene al", "tiene alla", "tiene ai",
                                   "tiene agli", "tiene all'", "ci tiene"]

    /// Una delle parole compare nel testo (già piegato) a inizio di parola: «orari» non si trova in «onorari», «odia» in
    /// «custodia», «ama» in «chiama». Le radici troncate («videochiam», «prefer») valgono come inizio di parola; quelle
    /// intere («ama», «sera», «odia») anche come fine, così «amaro» o «serata» non contano. «orari» resta una radice,
    /// così vale anche «orario».
    static func contieneParola(_ testo: String, _ parole: [String]) -> Bool {
        parole.contains { p in
            let schema = NSRegularExpression.escapedPattern(for: p)
            let fine = paroleIntere.contains(p) ? #"(?![\p{L}])"# : ""
            return DateItaliane.cerca(#"(?<![\p{L}])"# + schema + fine, testo) != nil
        }
    }

    /// Le parole delle liste che vanno trovate intere (le altre sono radici: «telefon», «mattin»…).
    static let paroleIntere: Set<String> = ["sera", "lunedi", "martedi", "mercoledi", "giovedi", "venerdi", "sabato",
                                            "ama", "non ama", "odia", "evita", "vuole", "non vuole", "decide", "detesta",
                                            "tiene a", "tiene al", "tiene alla", "tiene ai", "tiene agli"]

    /// Il «quando» della frase parla di un giorno relativo a quando è stata scritta («domani», «tra tre giorni», «la
    /// settimana prossima»): letto più tardi direbbe un giorno sbagliato.
    static func quandoRelativo(_ quando: String) -> Bool {
        DateItaliane.cerca(#"(?<![\p{L}])(oggi|domani|dopodomani|ieri|stasera|stamattina|stanotte|tra|fra|prossim\p{L}*|settimana|mese)(?![\p{L}])"#,
                           piega(quando)) != nil
    }

    /// Il familiare con cui il cliente decide («Decide sempre insieme a Paolo»): un familiare della scheda nominato nel
    /// ricordo con «insieme» o «decide», oppure il nome dopo «insieme a».
    static func conChi(_ ricordo: String, cliente: Cliente) -> String? {
        let t = piega(ricordo)
        let insieme = t.contains("insieme") || t.contains("decid") || t.contains("sentire anche") || t.contains("chiede a")
        if insieme {
            for m in cliente.famiglia {
                guard let primo = m.nome.split(separator: " ").first.map(String.init), primo.count >= 2 else { continue }
                if DateItaliane.cerca("\\b\(NSRegularExpression.escapedPattern(for: piega(primo)))\\b", t) != nil { return primo }
            }
        }
        if let trovato = DateItaliane.cerca(#"insieme (?:a|ad|al|alla|con) ([A-Za-zÀ-ÿ']+)"#, ricordo) {
            let g = trovato.1
            if g.count > 1, let iniziale = g[1].first, iniziale.isUppercase { return g[1] }
        }
        return nil
    }

    /// Il primo incontro in agenda del cliente da oggi a 30 giorni (prima di `prima`, se c'è); a parità vince quello
    /// sulla posizione.
    static func prossimoIncontro(_ f: FonteSussurro, prima: Date?, posizione: String?, cal: Calendar) -> Appuntamento? {
        let inizio = cal.startOfDay(for: f.oggi)
        let fine = cal.date(byAdding: .day, value: RegoleSussurro.giorniIncontro + 1, to: inizio) ?? inizio
        let limite = prima.map { min($0, fine) } ?? fine
        let futuri = f.appuntamenti.filter { $0.stato == .pianificato && $0.tipo != .nonDisponibile && $0.inizio >= inizio && $0.inizio < limite }
            .sorted { ($0.inizio, $0.id) < ($1.inizio, $1.id) }
        if let posizione, let a = futuri.first(where: { $0.posizioneId == posizione }) { return a }
        return futuri.first
    }

    /// «A dicembre», «Ad aprile», «Questo mese».
    static func quandoMese(_ d: Date, oggi: Date, cal: Calendar) -> String {
        if cal.component(.month, from: d) == cal.component(.month, from: oggi), cal.component(.year, from: d) == cal.component(.year, from: oggi) {
            return "Questo mese"
        }
        let mese = DateItaliane.mesi[(cal.component(.month, from: d) - 1 + 12) % 12]
        return (mese.hasPrefix("a") ? "Ad " : "A ") + mese
    }

    /// «9», «7,5».
    static func mesiTesto(_ m: Double) -> String {
        m == m.rounded() ? String(Int(m)) : String(format: "%.1f", m).replacingOccurrences(of: ".", with: ",")
    }

    /// Il nome di battesimo.
    static func nome(_ c: Cliente) -> String {
        c.nome.split(separator: " ").first.map(String.init) ?? c.nome
    }

    /// Il ricordo come frase: maiuscola in testa, punto in fondo.
    static func frase(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return t }
        let chiusa = [".", "!", "?"].contains(String(t.suffix(1))) ? t : t + "."
        return maiuscola(chiusa)
    }

    static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }

    static func minuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.lowercased() + s.dropFirst()
    }

    /// Minuscolo e senza accenti, per cercare le parole.
    static func piega(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "it_IT"))
    }

    /// Per i doppioni: minuscolo, senza accenti, solo lettere e cifre.
    static func normale(_ s: String) -> String {
        String(piega(s).unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(Character.init))
    }
}
