import Foundation

// Il radar del portafoglio (Design/template-luce-specifica.md §8.3, «Luce» giro 2): per ogni cliente con un portafoglio
// modello, quanto la composizione di oggi si è allontanata dal modello.
// - Composizione: `MotoreAree360.composizione` sulle posizioni finanziarie in essere, SENZA la previdenza (decisione 91:
//   un fondo pensione non si ribilancia come un fondo). Stessa stima dall'SRI di Analisi 360, segnata «stimata».
// - Distanza: ½ · Σ |quota − peso| sulle quattro classi, in punti (0…100): dice quanta parte del portafoglio va
//   spostata per tornare al modello. Fuori tolleranza = distanza > tolleranza (del modello o generale; senza tolleranza
//   scritta dall'utente nessuno è «fuori»).
// - Spostamenti: dentro ogni canale, dalle classi in eccesso a quelle in difetto (decisione 91: mai da un canale
//   all'altro), con l'importo; costi solo dai motori: penale (`MotoreFiscale`, con le condizioni della posizione o del
//   prodotto) e imposta sulla plusvalenza quota per quota; senza versato le tasse restano «da calcolare». Il costo
//   d'ingresso dipende dal prodotto di arrivo, che sceglie l'utente: la frase lo dice. Mai una percentuale fissa.
// - Il radar non sposta niente: «Riequilibra» prepara bozze di proposta (`bozza(_:)`), e i punti restano dove sono
//   finché le posizioni non cambiano davvero (decisione 2), con il segno «proposta pronta».

/// Uno spostamento proposto dentro un canale: da una classe in eccesso a una in difetto.
struct SpostamentoRadar: Equatable, Identifiable {
    let da: ComposizioneInvestimenti360.Classe
    let a: ComposizioneInvestimenti360.Classe
    let canale: Canale
    let importo: Double
    var id: String { "\(canale.rawValue)-\(da.rawValue)-\(a.rawValue)" }
}

/// Quanto costa uscire dalle posizioni che si riducono, dai motori di Prisma.
struct CostoRiequilibrio: Equatable {
    /// Penali d'uscita sulla parte venduta (dalle condizioni della posizione o della scheda prodotto).
    var penali: Double = 0
    /// Imposte sulle plusvalenze della parte venduta, quota per quota, dove c'è il versato.
    var imposte: Double = 0
    /// Le posizioni da ridurre senza versato: le tasse restano da calcolare.
    var senzaVersato: [String] = []
    var totaleNoto: Double { penali + imposte }
}

/// Un cliente sul radar.
struct VoceRadar: Identifiable, Equatable {
    let clienteId: String
    let nome: String
    let iniziali: String
    let tinta: TintaAvatar
    let modello: PortafoglioModello
    /// Quote di oggi per classe, in punti (somma 100).
    let quote: PesiModello
    /// Euro per classe e canale (per le barre divise per canale nel dettaglio).
    let perCanale: [ComposizioneInvestimenti360.Classe: [Canale: Double]]
    let totale: Double
    /// Distanza dal modello in punti (0…100).
    let distanza: Double
    /// La tolleranza che vale per questo cliente (nil = non scritta).
    let tolleranza: Double?
    let stimata: Bool
    let spostamenti: [SpostamentoRadar]
    let costo: CostoRiequilibrio
    /// C'è già una bozza di riequilibrio ancora da presentare (decisione 2: «proposta pronta»).
    let bozzaPronta: Bool
    /// Il modello ha più azioni di quante ne regga il profilo del cliente (SRI massimo della propensione).
    let oltreProfilo: Bool
    /// Da dove disegnare il punto dentro il settore del modello: 0…1, fisso per cliente (dall'id, non casuale).
    let angoloNelSettore: Double

    var id: String { clienteId }
    var fuori: Bool { tolleranza.map { distanza > $0 + 1e-9 } ?? false }
    /// Gli euro da spostare per tornare al modello: distanza × patrimonio considerato.
    var daSpostare: Double { distanza / 100 * totale }
    /// La somma degli spostamenti proposti (dentro i canali può superare `daSpostare` se i canali si compensano).
    var spostato: Double { spostamenti.reduce(0) { $0 + $1.importo } }
}

struct RadarPortafoglio: Equatable {
    let modelli: [PortafoglioModello]
    let voci: [VoceRadar]
    /// I clienti con investimenti ma senza modello assegnato (o con un modello che non esiste più).
    let senzaModello: [String]
    let tolleranzaGenerale: Double?

    var fuori: [VoceRadar] { voci.filter(\.fuori).sorted { $0.distanza > $1.distanza } }
    var piuLontani: [VoceRadar] { Array(voci.sorted { $0.distanza > $1.distanza }.prefix(3)) }
    /// I fuori tolleranza che non hanno ancora una bozza.
    var daRiequilibrare: [VoceRadar] { fuori.filter { !$0.bozzaPronta } }
    var vuoto: Bool { voci.isEmpty }
}

enum MotoreRadar {
    typealias Classe = ComposizioneInvestimenti360.Classe

    /// ½ · Σ |quota − peso| sulle quattro classi, in punti.
    static func distanza(quote: PesiModello, pesi: PesiModello) -> Double {
        Classe.allCases.reduce(0) { $0 + abs(quote[$1] - pesi[$1]) } / 2
    }

    /// Le posizioni che il radar considera: finanziarie in essere (investimento, risparmio, liquidità), senza la
    /// previdenza e senza protezione, immobili e debiti.
    static func considerate(_ posizioni: [Posizione]) -> [Posizione] {
        posizioni.filter { $0.stato == .inEssere && $0.valore > 0 && $0.area != .previdenza
            && ($0.area.proiettabile || $0.area == .liquidita) }
    }

    /// Il radar di tutti i clienti.
    static func calcola(_ dati: DatiPrisma) -> RadarPortafoglio {
        let modelli = dati.portafogliModello
        let perId = Dictionary(modelli.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var perCliente: [String: [Posizione]] = [:]
        for p in dati.posizioni { perCliente[p.clienteId, default: []].append(p) }
        let bozze = Set(dati.posizioni.filter { $0.riequilibrio != nil && $0.stato == .proposta && ($0.esito ?? .bozza) == .bozza }
                            .map(\.clienteId))
        let prodotti = Dictionary(dati.prodotti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var voci: [VoceRadar] = []
        var senza: [String] = []
        for c in dati.clienti {
            let sue = considerate(perCliente[c.id] ?? [])
            guard !sue.isEmpty else { continue }
            guard let id = c.modelloId, let m = perId[id] else {
                senza.append(c.id)
                continue
            }
            if let v = voce(cliente: c, modello: m, posizioni: sue, prodotti: prodotti,
                            tolleranzaGenerale: dati.impostazioni.tolleranzaRadar, bozzaPronta: bozze.contains(c.id)) {
                voci.append(v)
            }
        }
        return RadarPortafoglio(modelli: modelli, voci: voci, senzaModello: senza,
                                tolleranzaGenerale: dati.impostazioni.tolleranzaRadar)
    }

    /// Un cliente sul radar (nil se la composizione è vuota).
    static func voce(cliente c: Cliente, modello m: PortafoglioModello, posizioni: [Posizione],
                     prodotti: [String: Prodotto] = [:], tolleranzaGenerale: Double?, bozzaPronta: Bool = false) -> VoceRadar? {
        let sue = considerate(posizioni)
        let k = MotoreAree360.composizione(sue, cliente: c)
        guard !k.vuota else { return nil }
        var quote = PesiModello()
        var canali: [Classe: [Canale: Double]] = [:]
        for pezzo in k.pezzi {
            quote[pezzo.classe] = pezzo.quota
            canali[pezzo.classe] = pezzo.perCanale
        }
        let d = distanza(quote: quote, pesi: m.pesi)
        let spost = spostamenti(perCanale: canali, pesi: m.pesi)
        return VoceRadar(clienteId: c.id, nome: c.nome, iniziali: c.iniziali, tinta: c.tinta, modello: m, quote: quote,
                         perCanale: canali, totale: k.totale, distanza: d, tolleranza: m.tolleranza ?? tolleranzaGenerale,
                         stimata: k.stimata, spostamenti: spost,
                         costo: costo(spost, posizioni: sue, prodotti: prodotti),
                         bozzaPronta: bozzaPronta, oltreProfilo: oltreProfilo(m, cliente: c),
                         angoloNelSettore: angolo(c.id))
    }

    /// Dentro ogni canale, dalle classi in eccesso alle classi in difetto rispetto ai pesi del modello, la più grande
    /// con la più grande. Gli importi sono esatti (al centesimo); si arrotondano solo nelle frasi.
    static func spostamenti(perCanale: [Classe: [Canale: Double]], pesi: PesiModello) -> [SpostamentoRadar] {
        var esito: [SpostamentoRadar] = []
        for canale in Canale.allCases {
            let euro = Dictionary(uniqueKeysWithValues: Classe.allCases.map { ($0, perCanale[$0]?[canale] ?? 0) })
            let totale = euro.values.reduce(0, +)
            guard totale > 0.005 else { continue }
            var eccessi = Classe.allCases.map { ($0, euro[$0]! - pesi[$0] / 100 * totale) }.filter { $0.1 > 0.005 }
            var difetti = Classe.allCases.map { ($0, pesi[$0] / 100 * totale - euro[$0]!) }.filter { $0.1 > 0.005 }
            eccessi.sort { $0.1 > $1.1 }
            difetti.sort { $0.1 > $1.1 }
            var i = 0, j = 0
            while i < eccessi.count, j < difetti.count {
                let importo = min(eccessi[i].1, difetti[j].1)
                if importo > 0.005 {
                    esito.append(SpostamentoRadar(da: eccessi[i].0, a: difetti[j].0, canale: canale,
                                                  importo: (importo * 100).rounded() / 100))
                }
                eccessi[i].1 -= importo
                difetti[j].1 -= importo
                if eccessi[i].1 <= 0.005 { i += 1 }
                if difetti[j].1 <= 0.005 { j += 1 }
            }
        }
        return esito
    }

    /// Penali e imposte sulla parte venduta di ogni posizione delle classi da ridurre: la quota venduta di una classe
    /// in un canale si toglie in proporzione da ogni posizione di quel canale che ne contiene (quota per quota).
    static func costo(_ spostamenti: [SpostamentoRadar], posizioni: [Posizione], prodotti: [String: Prodotto]) -> CostoRiequilibrio {
        var c = CostoRiequilibrio()
        var daRidurre: [Canale: [Classe: Double]] = [:]
        for s in spostamenti { daRidurre[s.canale, default: [:]][s.da, default: 0] += s.importo }
        var frazioni: [String: Double] = [:]
        for (canale, classi) in daRidurre {
            let delCanale = posizioni.filter { $0.canale == canale }
            for (classe, importo) in classi {
                let quote = delCanale.map { p -> (Posizione, Double) in (p, p.valore * quotaClasse(classe, p)) }
                let inClasse = quote.reduce(0) { $0 + $1.1 }
                guard inClasse > 0 else { continue }
                let parte = min(1, importo / inClasse)
                for (p, euro) in quote where euro > 0 {
                    frazioni[p.id, default: 0] += euro * parte / max(p.valore, 0.01)
                }
            }
        }
        for p in posizioni {
            guard let f = frazioni[p.id], f > 0 else { continue }
            let quota = min(1, f)
            guard p.area != .liquidita else { continue }
            let fiscale = MotoreFiscale.calcola(p, prodotto: p.prodottoId.flatMap { prodotti[$0] })
            c.penali += fiscale.penale * quota
            if fiscale.versato > 0 {
                c.imposte += fiscale.imposta * quota
            } else {
                c.senzaVersato.append(p.nome)
            }
        }
        c.penali = (c.penali * 100).rounded() / 100
        c.imposte = (c.imposte * 100).rounded() / 100
        return c
    }

    /// La quota di una posizione in una classe (0…1), con la stessa composizione di Analisi 360.
    static func quotaClasse(_ classe: Classe, _ p: Posizione) -> Double {
        guard let k = MotoreResistenza.composizione(p) else { return 0 }
        switch classe {
        case .azionario: return k.azioni
        case .obbligazionario: return k.governativi + k.societarie
        case .gestioneSeparata: return k.gestioneSeparata
        case .liquidita: return k.liquidita
        }
    }

    /// Il modello chiede più azioni di quante ne regga il profilo: la quota azionaria del modello supera quella che
    /// Prisma associa all'SRI massimo della propensione (`MotoreResistenza.azioniPerSRI`). Senza profilo, no.
    static func oltreProfilo(_ m: PortafoglioModello, cliente: Cliente) -> Bool {
        guard let p = cliente.profilo.propensione else { return false }
        let massimo = MotoreResistenza.azioniPerSRI[MotoreCoerenza.sriMassimo(p)] ?? 1
        return m.pesi.azionario / 100 > massimo + 1e-9
    }

    /// Un numero fisso per cliente fra 0 e 1, dall'id (FNV-1a): lo stesso a ogni apertura, non casuale.
    static func angolo(_ id: String) -> Double {
        var h: UInt64 = 0xcbf29ce484222325
        for b in id.utf8 {
            h ^= UInt64(b)
            h = h &* 0x100000001b3
        }
        return Double(h % 10_000) / 10_000
    }

    // MARK: - Bozze

    /// La bozza di riequilibrio per un cliente: una proposta (`stato = .proposta`, `esito = .bozza`) per canale, con gli
    /// spostamenti nelle note. Niente si esegue: l'utente la rilegge, sceglie i prodotti e la presenta.
    static func bozze(_ v: VoceRadar, oggi: Date = Date()) -> [Posizione] {
        Canale.allCases.compactMap { canale -> Posizione? in
            let suoi = v.spostamenti.filter { $0.canale == canale }
            guard !suoi.isEmpty else { return nil }
            var p = Posizione(clienteId: v.clienteId, canale: canale, stato: .proposta, area: .investimento,
                              nome: TestiRadar.nomeBozza(v.modello))
            p.esito = .bozza
            p.versamentoIniziale = suoi.reduce(0) { $0 + $1.importo }
            p.note = TestiRadar.noteBozza(v, spostamenti: suoi)
            p.riequilibrio = OrigineRiequilibrio(modelloId: v.modello.id, distanza: v.distanza, creataIl: oggi)
            p.creataIl = oggi
            return p
        }
    }
}

// MARK: - Testi

enum TestiRadar {
    private static let punti: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    /// «9,5» (un decimale al massimo).
    static func punti(_ v: Double) -> String { punti.string(from: NSNumber(value: (v * 10).rounded() / 10)) ?? "\(v)" }
    /// «9,5 punti», «1 punto».
    static func puntiConNome(_ v: Double) -> String {
        let r = (v * 10).rounded() / 10
        return "\(punti(r)) \(r == 1 ? "punto" : "punti")"
    }

    /// I pesi in fila: «20 · 55 · 20 · 5».
    static func pesi(_ p: PesiModello) -> String {
        ComposizioneInvestimenti360.Classe.allCases.map { punti(p[$0]) }.joined(separator: " · ")
    }

    static let leggendaClassi = "Azioni · obbligazioni · gestione separata · liquidità"

    static func nomeClasse(_ c: ComposizioneInvestimenti360.Classe) -> String {
        switch c {
        case .azionario: return "Azioni"
        case .obbligazionario: return "Obbligazioni"
        case .gestioneSeparata: return "Gestione separata"
        case .liquidita: return "Liquidità"
        }
    }

    /// «dalle azioni», «dalla liquidità»…
    static func dalla(_ c: ComposizioneInvestimenti360.Classe) -> String {
        switch c {
        case .azionario: return "dalle azioni"
        case .obbligazionario: return "dalle obbligazioni"
        case .gestioneSeparata: return "dalla gestione separata"
        case .liquidita: return "dalla liquidità"
        }
    }

    static func alla(_ c: ComposizioneInvestimenti360.Classe) -> String {
        switch c {
        case .azionario: return "alle azioni"
        case .obbligazionario: return "alle obbligazioni"
        case .gestioneSeparata: return "alla gestione separata"
        case .liquidita: return "alla liquidità"
        }
    }

    /// Gli importi della frase, arrotondati alle migliaia (sotto i mille, alle centinaia).
    static func circa(_ euro: Double) -> String {
        let passo: Double = euro >= 1_000 ? 1_000 : 100
        return Formati.euro(max(passo, (euro / passo).rounded() * passo))
    }

    static func nomeBozza(_ m: PortafoglioModello) -> String { "Riequilibrio verso il modello \(m.nome)" }

    /// Una riga per spostamento: «circa 20.000 € dalle azioni alle obbligazioni (Alleanza)».
    static func spostamento(_ s: SpostamentoRadar, conCanale: Bool) -> String {
        "circa \(circa(s.importo)) \(dalla(s.da)) \(alla(s.a))" + (conCanale ? " (\(s.canale.nomeBreve))" : "")
    }

    /// La frase del riequilibrio nel dettaglio: spostamenti, costi dai motori, ingresso che dipende dal prodotto.
    static func riequilibrio(_ v: VoceRadar) -> String {
        guard !v.spostamenti.isEmpty else { return "Il portafoglio è già come il modello: niente da spostare." }
        let canali = Set(v.spostamenti.map(\.canale)).count > 1
        let elenco = v.spostamenti.prefix(3).map { spostamento($0, conCanale: canali) }
        var frase = "Spostare " + elenco.joined(separator: "; ")
        if v.spostamenti.count > 3 { frase += " e altri \(v.spostamenti.count - 3) spostamenti" }
        frase += ", dentro il canale di ogni posizione."
        var costi: [String] = []
        if v.costo.penali > 0 { costi.append("penali d'uscita \(Formati.euro(v.costo.penali))") }
        if v.costo.imposte > 0 { costi.append("tasse sulle plusvalenze \(Formati.euro(v.costo.imposte))") }
        if !costi.isEmpty {
            frase += " Costo stimato dai motori di Prisma: " + costi.joined(separator: " e ") + "."
        } else if v.costo.senzaVersato.isEmpty {
            frase += " Nessuna penale né tassa sulle plusvalenze secondo i dati in Prisma."
        }
        if !v.costo.senzaVersato.isEmpty {
            let nomi = v.costo.senzaVersato.prefix(2).joined(separator: ", ")
            frase += " Tasse da calcolare: manca il versato di \(nomi)\(v.costo.senzaVersato.count > 2 ? " e altre" : "")."
        }
        frase += " Il costo d'ingresso dipende dal prodotto che scegli."
        return frase
    }

    /// Le note della bozza: modello, distanza, spostamenti e costi, con la data.
    static func noteBozza(_ v: VoceRadar, spostamenti: [SpostamentoRadar]) -> String {
        var righe = ["Bozza preparata dal radar del portafoglio: \(puntiConNome(v.distanza)) di distanza dal modello \(v.modello.nome) (\(pesi(v.modello.pesi))).",
                     "Spostamenti proposti:"]
        righe += spostamenti.map { "• \(Formati.euro($0.importo)) \(dalla($0.da)) \(alla($0.a))" }
        righe.append(riequilibrio(v))
        righe.append("Da rileggere: scegli i prodotti e presentala tu. Niente si esegue da solo.")
        return righe.joined(separator: "\n")
    }

    static func fuoriTolleranza(_ t: Double?) -> String {
        guard let t else { return "clienti fuori tolleranza (tolleranza da impostare)" }
        return "clienti fuori tolleranza (oltre \(puntiConNome(t)))"
    }

    static func pulsanteRiequilibra(_ n: Int) -> String {
        n == 1 ? "Riequilibra il cliente" : "Riequilibra i \(n) clienti"
    }

    static let spiegaRiequilibra = "Prepara le proposte di riequilibrio, una per cliente, con i costi e le tasse di ogni spostamento."
    static let piede = "Più un cliente è lontano dal centro, più il suo portafoglio si è allontanato dal modello scelto. Tocca un punto per il dettaglio."
    static let barraLinea = "La barra è oggi, la linea è il modello."
    static let senzaModelli = "Definisci i tuoi portafogli modello per vedere chi se ne allontana."
    static let senzaAssegnati = "Assegna un modello ai clienti con investimenti: lo scegli tu, in Impostazioni › Portafogli modello."
    static let senzaTolleranza = "Imposta la tolleranza in Impostazioni › Portafogli modello: senza, nessuno è segnato fuori."
    static let previdenzaEsclusa = "La previdenza non entra nel radar: un fondo pensione non si ribilancia come un fondo."

    static func senzaModello(_ n: Int) -> String {
        n == 1 ? "1 cliente senza modello" : "\(n) clienti senza modello"
    }

    static func bozzePronte(_ n: Int) -> String {
        n == 1 ? "1 bozza pronta" : "\(n) bozze pronte"
    }

    static func avvisoBozze(_ n: Int) -> String {
        "\(bozzePronte(n)): le trovi in Posizioni, fra le proposte di ogni cliente. Niente si esegue da solo."
    }

    static func oltreProfilo(_ v: VoceRadar) -> String {
        "Il modello \(v.modello.nome) ha più azioni di quante ne regga il profilo del cliente: controlla l'adeguatezza prima di proporlo."
    }

    /// VoiceOver: «Laura Moretti, modello Equilibrato, 9,5 punti, fuori tolleranza».
    static func accessibilita(_ v: VoceRadar) -> String {
        var s = "\(v.nome), modello \(v.modello.nome), \(puntiConNome(v.distanza))"
        if v.fuori { s += ", fuori tolleranza" }
        if v.bozzaPronta { s += ", proposta pronta" }
        return s
    }
}
