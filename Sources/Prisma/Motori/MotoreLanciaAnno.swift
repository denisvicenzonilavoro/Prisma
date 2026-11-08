import Foundation

// Lancia l'anno (Design/template-luce-specifica.md §4.3, «Luce» giro 8): due vite affiancate, con e senza il piano, anno
// per anno. Motore puro e leggero: UNA traiettoria (non le mille del Monte Carlo), niente SwiftUI.
// - Il mercato dell'anno viene dal Monte Carlo che esiste: una sola estrazione normale z dal `GeneratoreSeme` per anno,
//   e ogni voce cresce di exp(μ + σ·z) con μ = ln(1 + r) − σ²/2 e r, σ e costi da `MotoreMonteCarlo.linea` (stesso
//   fattore comune, correlazione piena, come `simula`), con le stesse regole: il pavimento del Ramo I, l'imposta annua
//   dei fondi pensione sul risultato positivo, il costo d'ingresso sui versamenti e, nelle multiramo a due parti, la
//   gestione separata che cresce del suo accreditato senza oscillare accanto ai fondi (ribilanciata a fine anno se il
//   contratto lo prevede). Stesso seme → stessa partita (prove e istantanee ripetibili).
// - I versamenti di posizioni e proposte si fermano alla loro scadenza; quelli degli obiettivi alla scadenza
//   dell'obiettivo. Il risparmio che il piano chiede si ricalcola anno per anno.
// - Le due vite hanno lo STESSO risparmio (decisione 78): senza piano = le posizioni in essere di oggi più il risparmio
//   libero sul conto (`IpotesiLiquidita.conto`); con il piano = in essere più le proposte aperte e i versamenti previsti
//   degli obiettivi (decisione 77), pagati con lo stesso risparmio (il capitale delle proposte esce dalla liquidità;
//   anche i premi delle polizze di protezione in proposta escono dal risparmio, perché la loro copertura non è gratis). Se
//   il piano chiede più del risparmio libero, tutte e due le vite contano quella cifra e la partita lo dice.
// - Gli eventi (decisione 69): niente probabilità inventate. Esce a caso solo un evento con probabilità E fonte scritte
//   dall'utente (Impostazioni › Sala); gli eventi del cliente arrivano dalla linea della vita all'età giusta; gli altri
//   si giocano a mano. Gli importi della risorsa sono «dati di prova» e valgono solo con i clienti di prova.
// - Un evento coperto da una polizza (in essere, o in proposta nella vita con il piano): con l'indennizzo stimato
//   scritto dal consulente (`Posizione.indennizzoStimato`, decisione 79) l'effetto è −spesa + indennizzo; senza, la carta
//   dice che dipende dalle condizioni e non mette cifre per la parte coperta.
// Euro nominali (le cifre crescono); la fine della partita dice anche gli euro di oggi con `IpotesiCalcolo.inflazione`.

/// La tabella degli eventi della risorsa (Risorse/Sala/eventi-anno.json).
struct TabellaEventiAnno: Decodable, Equatable {
    var versione: String
    var testiDiProva: Bool
    var eventi: [EventoAnno]

    private enum CodingKeys: String, CodingKey { case versione, testiDiProva, eventi }

    init(versione: String, testiDiProva: Bool, eventi: [EventoAnno]) {
        self.versione = versione
        self.testiDiProva = testiDiProva
        self.eventi = eventi
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versione = (try? c.decodeIfPresent(String.self, forKey: .versione)) ?? nil ?? "?"
        testiDiProva = (try? c.decodeIfPresent(Bool.self, forKey: .testiDiProva)) ?? nil ?? true
        eventi = ((try? c.decodeIfPresent(ElencoTollerante<EventoAnno>.self, forKey: .eventi)) ?? nil)?.elementi ?? []
    }
}

/// Una voce di una delle due vite: una posizione, il conto o un versamento previsto.
struct VoceLancia: Equatable {
    var nome: String
    var valore: Double
    /// ln(1 + r) − σ²/2 e σ (frazioni annue) della parte che oscilla (nelle multiramo: i fondi).
    var mu: Double
    var sigma: Double
    /// Il fattore dei costi dell'anno (1 − costo annuo).
    var fattoreCosti: Double
    /// Versamento annuo (premi della posizione o versamento previsto dell'obiettivo), quello che esce di tasca.
    var versamentoAnnuo: Double
    /// Fino a quanti anni dall'inizio si versa (nil = sempre).
    var anniVersamento: Int? = nil
    /// È il conto: riceve il risparmio libero e paga (o incassa) gli imprevisti.
    var conto: Bool = false
    /// Il versamento previsto di un obiettivo (le spese lo usano prima delle altre voci: è lì per questo).
    var obiettivo: Bool = false
    /// Fa parte del piano (proposta o versamento di un obiettivo): i suoi versamenti li paga il risparmio.
    var delPiano: Bool = false
    /// La parte del versamento che entra davvero (1 − costo d'ingresso).
    var fattoreIngresso: Double = 1
    /// Ramo I: il rendimento accreditato non è mai negativo.
    var garantito: Bool = false
    /// Imposta annua sul risultato positivo (fondi pensione), frazione.
    var tassaAnnua: Double = 0
    /// Multiramo a due parti: la quota in gestione separata (0 = nessuna), il suo fattore annuo, il saldo dentro
    /// `valore` e se a fine anno le due parti tornano alla quota.
    var quotaGestione: Double = 0
    var fattoreGestione: Double = 1
    var valoreGestione: Double = 0
    var ribilancia: Bool = false

    /// In quell'anno (1 = il primo) si versa ancora.
    func versaNellAnno(_ anno: Int) -> Bool { !conto && (anniVersamento.map { anno <= $0 } ?? true) }
}

/// Un'uscita del piano che non fa patrimonio: il premio di una polizza di protezione in proposta.
struct UscitaPiano: Equatable {
    let nome: String
    let annuo: Double
    /// Fino a quanti anni si paga (nil = sempre).
    let anni: Int?

    func nellAnno(_ anno: Int) -> Bool { anni.map { anno <= $0 } ?? true }
}

/// Una delle due vite.
struct VitaLanciaAnno: Equatable {
    var voci: [VoceLancia]
    /// Il valore a fine di ogni anno, a partire da oggi.
    var serie: [Double]
    var valore: Double { voci.reduce(0) { $0 + $1.valore } }
}

/// Come un anno tocca una delle due vite: l'importo sul patrimonio (nil = cifra che non si sa) e la frase della carta.
struct EffettoAnno: Equatable {
    let importo: Double?
    let frase: String
}

/// Un anno lanciato: la carta.
struct AnnoLanciato: Equatable {
    let anno: Int
    let eta: Int?
    /// Il rendimento del portafoglio con il piano in quell'anno (solo mercati).
    let rendimento: Double
    let titolo: String
    let evento: EventoAnno?
    /// L'evento della linea della vita del cliente, se è quello.
    let eventoCliente: EventoLineaVita?
    let effettoCon: EffettoAnno
    let effettoSenza: EffettoAnno
    let tono: EventoAnno.Tono
    /// La polizza che copre l'evento nella vita con il piano (per l'etichetta del canale).
    let copertura: Posizione?
    let aMano: Bool
    /// L'importo viene dai dati di prova della risorsa.
    let diProva: Bool
    /// Valori delle due vite a fine anno.
    let valoreCon: Double
    let valoreSenza: Double

    /// Un anno senza evento: la carta dice solo il mercato.
    var soloMercato: Bool { evento == nil && eventoCliente == nil }
}

/// Perché non si può giocare.
enum DatoLanciaMancante: Error, Equatable {
    /// Mancano il patrimonio (nessuna posizione in essere con valore) e/o il risparmio libero del profilo.
    case patrimonioORisparmio
}

/// Una partita.
struct PartitaLanciaAnno: Equatable {
    let seme: UInt64
    var generatore: GeneratoreSeme
    let annoIniziale: Int
    let etaIniziale: Int?
    var con: VitaLanciaAnno
    var senza: VitaLanciaAnno
    var anni: [AnnoLanciato]
    let anniMassimi: Int
    let eventiCliente: [EventoLineaVita]
    let tabella: [EventoAnno]
    let copertureCon: [Posizione]
    let copertureSenza: [Posizione]
    let redditoNetto: Double?
    let diProva: Bool
    /// Il risparmio libero del cliente e quanto chiede il piano all'anno (proposte + obiettivi).
    let risparmioLibero: Double
    let chiedeIlPiano: Double
    /// I premi delle polizze di protezione in proposta: escono dal risparmio della vita con il piano.
    let usciteProtezione: [UscitaPiano]
    /// Nessuna proposta aperta né versamento previsto: le due vite sono uguali.
    let senzaPiano: Bool
    /// Almeno un evento può uscire a caso (probabilità e fonte scritte dall'utente).
    let eventiACaso: Bool

    static func == (a: PartitaLanciaAnno, b: PartitaLanciaAnno) -> Bool {
        a.seme == b.seme && a.anni == b.anni && a.con == b.con && a.senza == b.senza
    }

    var finita: Bool { anni.count >= anniMassimi }
    /// Il piano chiede più del risparmio libero.
    var pianoOltreRisparmio: Bool { chiedeIlPiano > risparmioLibero + 0.5 }
    var annoCorrente: Int { annoIniziale + anni.count }
    var etaCorrente: Int? { etaIniziale.map { $0 + anni.count } }

    /// Quanto chiede il piano in quell'anno (1 = il primo): versamenti delle proposte e degli obiettivi ancora in corso
    /// e premi della protezione proposta.
    func richiestaDelPiano(anno k: Int) -> Double {
        con.voci.filter { $0.delPiano && $0.versaNellAnno(k) }.reduce(0) { $0 + $1.versamentoAnnuo }
            + usciteProtezione.filter { $0.nellAnno(k) }.reduce(0) { $0 + $1.annuo }
    }
}

extension GeneratoreSeme: Equatable {
    static func == (a: GeneratoreSeme, b: GeneratoreSeme) -> Bool { a.stato == b.stato }
}

enum MotoreLanciaAnno {
    static let fileEventi = "Sala/eventi-anno.json"

    /// La risorsa letta una volta sola (nil se manca: la partita ha solo mercati ed eventi del cliente).
    static let caricati: TabellaEventiAnno? = {
        guard let url = Risorse.cartella?.appendingPathComponent(fileEventi), let d = try? Data(contentsOf: url) else { return nil }
        return leggi(d)
    }()

    static func leggi(_ dati: Data) -> TabellaEventiAnno? {
        try? JSONDecoder().decode(TabellaEventiAnno.self, from: dati)
    }

    /// Gli eventi della partita: quelli della risorsa, sostituiti da quelli dell'utente con lo stesso id, più quelli
    /// nuovi dell'utente.
    static func eventi(risorsa: [EventoAnno], utente: [EventoAnno]) -> [EventoAnno] {
        let perId = Dictionary(utente.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let base = risorsa.map { perId[$0.id] ?? $0 }
        let nuovi = utente.filter { u in !risorsa.contains { $0.id == u.id } }
        return base + nuovi
    }

    /// Gli anni della partita: 12 di base; 0 = fino alla pensione (senza età: 12).
    static func anniPartita(_ scelta: Int?, eta: Int?, etaPensione: Int) -> Int {
        guard let scelta else { return ImpostazioniSala.anniPartitaPredefiniti }
        guard scelta == 0 else { return min(max(1, scelta), ImpostazioniSala.anniPartitaMassimi) }
        guard let eta else { return ImpostazioniSala.anniPartitaPredefiniti }
        return min(max(1, etaPensione - eta), ImpostazioniSala.anniPartitaMassimi)
    }

    /// Le aree che fanno patrimonio nella partita.
    static func finanziaria(_ p: Posizione) -> Bool { p.area.proiettabile || p.area == .liquidita }

    // MARK: - Preparare

    static func prepara(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventiCliente: [EventoLineaVita],
                        tabella: [EventoAnno], diProva: Bool, anniScelti: Int?, oggi: Date, seme: UInt64,
                        cal: Calendar = .current) -> Result<PartitaLanciaAnno, DatoLanciaMancante> {
        let mie = posizioni.filter { $0.clienteId == cliente.id }
        let inEssere = mie.filter { $0.stato == .inEssere && finanziaria($0) && $0.valore > 0 && $0.area != .debiti }
        let proposte = mie.filter { $0.stato == .proposta && $0.area.proiettabile && ($0.versamentoIniziale > 0 || $0.premioAnnuo > 0) }
        let patrimonio = inEssere.reduce(0) { $0 + $1.valore }
        guard let risparmio = cliente.profilo.risparmioAnnuo, risparmio >= 0, patrimonio > 0 || risparmio > 0 else {
            return .failure(.patrimonioORisparmio)
        }
        let annoOggi = cal.component(.year, from: oggi)
        let eta = cliente.dataNascita.flatMap { cal.dateComponents([.year], from: $0, to: oggi).year }
        let etaPensione = cliente.profilo.lavoro?.etaPensione ?? 67
        let anni = anniPartita(anniScelti, eta: eta, etaPensione: etaPensione)

        func voce(_ p: Posizione, valore: Double, delPiano: Bool) -> VoceLancia {
            voceLancia(p, valore: valore, delPiano: delPiano, oggi: oggi, cal: cal)
        }
        func conto(_ valore: Double) -> VoceLancia {
            VoceLancia(nome: "Conto", valore: valore, mu: log(1 + IpotesiLiquidita.conto / 100), sigma: 0, fattoreCosti: 1,
                       versamentoAnnuo: 0, conto: true)
        }

        // Il capitale delle proposte esce dalla liquidità in essere; quello che manca è denaro nuovo per tutte e due
        let capitaleProposte = proposte.reduce(0) { $0 + max(0, $1.versamentoIniziale) }
        let liquidita = inEssere.filter { $0.area == .liquidita }.reduce(0) { $0 + $1.valore }
        let nuovo = max(0, capitaleProposte - liquidita)
        let daLiquidita = capitaleProposte - nuovo

        // Senza piano: le posizioni in essere (la liquidità diventa il conto), più il denaro nuovo sul conto
        var vociSenza = inEssere.filter { $0.area != .liquidita }.map { voce($0, valore: $0.valore, delPiano: false) }
        vociSenza.append(conto(liquidita + nuovo))
        // Con il piano: la liquidità meno il capitale delle proposte, le proposte, i versamenti previsti degli obiettivi
        var vociCon = inEssere.filter { $0.area != .liquidita }.map { voce($0, valore: $0.valore, delPiano: false) }
        vociCon.append(conto(liquidita - daLiquidita))
        vociCon += proposte.map { voce($0, valore: max(0, $0.versamentoIniziale), delPiano: true) }
        let annoInizio = oggi
        for o in obiettivi where o.clienteId == cliente.id && o.versamentoMensile > 0 && o.scadenza > oggi && o.raggiuntoIl == nil {
            let mesi = cal.dateComponents([.month], from: annoInizio, to: o.scadenza).month ?? 12
            let anniObiettivo = max(1, (mesi + 11) / 12)
            var v = VoceLancia(nome: "Versamento per «\(o.titolo)»", valore: 0, mu: log(max(1 + o.rendimento / 100, 0.01)), sigma: 0,
                               fattoreCosti: 1, versamentoAnnuo: o.versamentoMensile * 12, obiettivo: true, delPiano: true)
            v.anniVersamento = anniObiettivo
            vociCon.append(v)
        }
        // I premi della protezione proposta: la copertura nella vita con il piano si paga con lo stesso risparmio
        let protezioneProposta = mie.filter { $0.stato == .proposta && $0.area == .protezione }
        let uscite = protezioneProposta.compactMap { p -> UscitaPiano? in
            guard p.frequenza.volteAllAnno > 0, p.premioAnnuo > 0 else { return nil }
            return UscitaPiano(nome: p.nome, annuo: p.premioAnnuo, anni: anniVersamento(p, oggi: oggi, cal: cal))
        }
        let chiede = vociCon.filter { $0.delPiano && $0.versaNellAnno(1) }.reduce(0) { $0 + $1.versamentoAnnuo }
            + uscite.filter { $0.nellAnno(1) }.reduce(0) { $0 + $1.annuo }
        let coperte = mie.filter { $0.area == .protezione && $0.rischio != nil }
        let partita = PartitaLanciaAnno(
            seme: seme, generatore: GeneratoreSeme(seme: seme), annoIniziale: annoOggi, etaIniziale: eta,
            con: VitaLanciaAnno(voci: vociCon, serie: [vociCon.reduce(0) { $0 + $1.valore }]),
            senza: VitaLanciaAnno(voci: vociSenza, serie: [vociSenza.reduce(0) { $0 + $1.valore }]),
            anni: [], anniMassimi: anni, eventiCliente: eventiCliente.filter { $0.clienteId == cliente.id && $0.importo != nil },
            tabella: tabella,
            copertureCon: coperte.filter { $0.stato == .inEssere || $0.stato == .proposta },
            copertureSenza: coperte.filter { $0.stato == .inEssere },
            redditoNetto: cliente.profilo.redditoNettoAnnuo.flatMap { $0 > 0 ? $0 : nil },
            diProva: diProva, risparmioLibero: risparmio, chiedeIlPiano: chiede, usciteProtezione: uscite,
            senzaPiano: proposte.isEmpty && protezioneProposta.isEmpty && !vociCon.contains(where: \.obiettivo),
            eventiACaso: tabella.contains { $0.esceACaso })
        return .success(partita)
    }

    /// Gli anni in cui una posizione riceve ancora versamenti: fino alla scadenza (0 se già scaduta), nil senza scadenza.
    static func anniVersamento(_ p: Posizione, oggi: Date, cal: Calendar) -> Int? {
        guard let scadenza = p.scadenza else { return nil }
        let mesi = max(0, cal.dateComponents([.month], from: oggi, to: scadenza).month ?? 0)
        return (mesi + 11) / 12
    }

    /// La voce di una posizione con le regole di `MotoreMonteCarlo.linea` e `simula`.
    static func voceLancia(_ p: Posizione, valore: Double, delPiano: Bool, oggi: Date, cal: Calendar = .current) -> VoceLancia {
        let predefinito = p.area == .liquidita ? IpotesiLiquidita.conto : IpotesiCalcolo.rendimentoPredefinito
        let l = MotoreMonteCarlo.linea(p, rendimentoPredefinito: predefinito, mesi: 12, data: oggi)
        let s = max(0, l.volatilita) / 100
        var v = VoceLancia(nome: p.nome, valore: valore, mu: log(max(1 + l.rendimento / 100, 0.01)) - s * s / 2, sigma: s,
                           fattoreCosti: 1 - min(max(l.costoAnnuo, 0), 99) / 100,
                           versamentoAnnuo: p.frequenza.volteAllAnno > 0 ? max(0, p.premioAnnuo) : 0,
                           anniVersamento: anniVersamento(p, oggi: oggi, cal: cal), delPiano: delPiano)
        v.fattoreIngresso = 1 - min(max(l.costoIngresso, 0), 99) / 100
        v.garantito = l.capitaleGarantito
        v.tassaAnnua = max(0, l.tassazioneAnnua) / 100
        if let g = l.gestione {
            v.quotaGestione = min(max(g.quota, 0), 1)
            v.fattoreGestione = max(1 + g.accreditato / 100, 0.01)
            v.valoreGestione = valore * v.quotaGestione
            v.ribilancia = g.ribilanciamento
        }
        return v
    }

    // MARK: - Lanciare

    /// Un anno in più. `cartaAMano`: l'evento scelto dal consulente; `z`: solo per le prove (l'estrazione del mercato).
    @discardableResult
    static func lancia(_ p: inout PartitaLanciaAnno, cartaAMano: EventoAnno? = nil, z zFissa: Double? = nil) -> AnnoLanciato? {
        guard !p.finita else { return nil }
        let k = p.anni.count + 1
        let anno = p.annoIniziale + k
        let eta = p.etaIniziale.map { $0 + k }
        let z = zFissa ?? p.generatore.normale()
        // Le estrazioni degli eventi a caso, una per evento estraibile, sempre nello stesso ordine
        var uscito: EventoAnno?
        for e in p.tabella where e.esceACaso {
            let u = p.generatore.uniforme()
            if uscito == nil, u < (e.probabilita ?? 0), etaAmmessa(e, eta: eta) { uscito = e }
        }

        // 1. Il mercato: ogni voce cresce del suo fattore, poi i versamenti
        let rendimento = cresci(&p.con, z: z, anno: k)
        _ = cresci(&p.senza, z: z, anno: k)
        // 2. Il risparmio: lo stesso nelle due vite (il piano lo usa per proposte e obiettivi, il resto va sul conto)
        let chiedeOra = p.richiestaDelPiano(anno: k)
        let totale = max(p.risparmioLibero, chiedeOra)
        sulConto(&p.senza, totale)
        sulConto(&p.con, max(0, totale - chiedeOra))

        // 3. L'evento: la carta a mano, poi la linea della vita, poi quello uscito a caso
        let inflazione = pow(1 + IpotesiCalcolo.inflazione / 100, Double(k))
        var titolo = "\(anno) · " + titoloMercato(z: z)
        var evento: EventoAnno?
        var delCliente: EventoLineaVita?
        var con = EffettoAnno(importo: nil, frase: fraseMercato(rendimento))
        var senza = con
        var tono = tonoMercato(z: z)
        var copertura: Posizione?
        var diProva = false
        let delloStessoAnno = eventoCliente(p, eta: eta, anno: anno)
        // L'evento della linea della vita del cliente non si perde mai: con una carta a mano si applicano tutti e due
        var importoCliente: Double?
        if let v = delloStessoAnno {
            delCliente = v
            let importo = (v.importo ?? 0) * inflazione
            importoCliente = importo
            titolo = "\(anno) · \(v.nome)"
            tono = importo >= 0 ? .verde : .arancio
            let frase = importo >= 0 ? "Entrano \(euro(importo))" : "Escono \(euro(-importo))"
            con = EffettoAnno(importo: importo, frase: frase)
            senza = con
        }
        if let e = cartaAMano ?? (delloStessoAnno == nil ? uscito : nil) {
            evento = e
            tono = e.tono
            let r = effetti(e, partita: p, inflazione: inflazione)
            copertura = r.copertura
            diProva = r.diProva
            if let v = delloStessoAnno, let ic = importoCliente {
                titolo = "\(anno) · \(e.titolo) · \(v.nome)"
                let fraseCliente = "\(v.nome): " + (ic >= 0 ? "entrano \(euro(ic))" : "escono \(euro(-ic))")
                con = EffettoAnno(importo: r.con.importo, frase: r.con.frase + " · " + fraseCliente)
                senza = EffettoAnno(importo: r.senza.importo, frase: r.senza.frase + " · " + fraseCliente)
            } else {
                titolo = "\(anno) · \(e.titolo)"
                con = r.con
                senza = r.senza
            }
        }
        if let i = con.importo { applica(&p.con, i) }
        if let i = senza.importo { applica(&p.senza, i) }
        // Con una carta a mano l'importo dell'evento del cliente si applica a parte (anche se la carta non ha cifra)
        if evento != nil, let ic = importoCliente {
            applica(&p.con, ic)
            applica(&p.senza, ic)
        }
        p.con.serie.append(p.con.valore)
        p.senza.serie.append(p.senza.valore)
        let a = AnnoLanciato(anno: anno, eta: eta, rendimento: rendimento, titolo: titolo, evento: evento, eventoCliente: delCliente,
                             effettoCon: con, effettoSenza: senza, tono: tono, copertura: copertura, aMano: cartaAMano != nil,
                             diProva: diProva, valoreCon: p.con.valore, valoreSenza: p.senza.valore)
        p.anni.append(a)
        return a
    }

    /// Il valore in euro di oggi di una cifra nominale fra `anni` anni.
    static func euroDiOggi(_ valore: Double, anni: Int) -> Double {
        valore / pow(1 + IpotesiCalcolo.inflazione / 100, Double(anni))
    }

    // MARK: - Aiuti

    private static func etaAmmessa(_ e: EventoAnno, eta: Int?) -> Bool {
        guard let eta else { return e.etaMinima == nil && e.etaMassima == nil }
        if let m = e.etaMinima, eta < m { return false }
        if let m = e.etaMassima, eta > m { return false }
        return true
    }

    /// L'evento della linea della vita che cade in quell'anno (con la durata: ogni anno per N anni).
    static func eventoCliente(_ p: PartitaLanciaAnno, eta: Int?, anno: Int) -> EventoLineaVita? {
        p.eventiCliente.first { e in
            guard let inizio = e.etaEvento(etaOggi: p.etaIniziale, annoOggi: p.annoIniziale) else {
                guard let a = e.anno else { return false }
                return anno >= a && anno < a + e.anniDurata
            }
            guard let eta else { return false }
            return eta >= inizio && eta < inizio + e.anniDurata
        }
    }

    /// Fa crescere le voci di una vita per un anno e restituisce il rendimento medio pesato (frazione).
    static func cresci(_ v: inout VitaLanciaAnno, z: Double, anno: Int) -> Double {
        let prima = v.valore
        var dopo = 0.0
        for i in v.voci.indices {
            let x = v.voci[i]
            var m = exp(x.mu + x.sigma * z) * x.fattoreCosti
            // Ramo I: il rendimento accreditato non è mai negativo
            if x.garantito, m < 1 { m = 1 }
            // Fondi pensione: imposta sul risultato positivo, anno per anno
            if x.tassaAnnua > 0, m > 1 { m = 1 + (m - 1) * (1 - x.tassaAnnua) }
            let rata = x.versaNellAnno(anno) ? x.versamentoAnnuo * x.fattoreIngresso : 0
            if x.quotaGestione > 0 {
                // Multiramo a due parti: la gestione separata non oscilla, i fondi sì
                let g = x.valoreGestione * x.fattoreGestione
                let f = (x.valore - x.valoreGestione) * m
                dopo += g + f
                var gDopo = g + rata * x.quotaGestione
                var fDopo = f + rata * (1 - x.quotaGestione)
                if x.ribilancia {
                    let somma = gDopo + fDopo
                    gDopo = somma * x.quotaGestione
                    fDopo = somma - gDopo
                }
                v.voci[i].valoreGestione = gDopo
                v.voci[i].valore = gDopo + fDopo
            } else {
                v.voci[i].valore = x.valore * m
                dopo += v.voci[i].valore
                v.voci[i].valore += rata
            }
        }
        return prima > 0 ? dopo / prima - 1 : 0
    }

    /// Toglie a una voce una parte del valore, con la stessa proporzione nella gestione separata.
    private static func togli(_ v: inout VitaLanciaAnno, _ j: Int, _ importo: Double) {
        let x = v.voci[j]
        if x.quotaGestione > 0, x.valore > 0 { v.voci[j].valoreGestione = x.valoreGestione * max(0, 1 - importo / x.valore) }
        v.voci[j].valore -= importo
    }

    private static func sulConto(_ v: inout VitaLanciaAnno, _ importo: Double) {
        guard let i = v.voci.firstIndex(where: \.conto) else { return }
        v.voci[i].valore += importo
    }

    /// Un'entrata va sul conto; una spesa esce dal conto, poi da ciò che si è messo da parte per gli obiettivi (è lì per
    /// questo) e, se non basta, dalle altre voci in proporzione.
    private static func applica(_ v: inout VitaLanciaAnno, _ importo: Double) {
        guard let i = v.voci.firstIndex(where: \.conto) else { return }
        if importo >= 0 || v.voci[i].valore + importo >= 0 {
            v.voci[i].valore += importo
            return
        }
        var manca = -(v.voci[i].valore + importo)
        v.voci[i].valore = 0
        for j in v.voci.indices where v.voci[j].obiettivo && manca > 0 {
            let preso = min(manca, max(0, v.voci[j].valore))
            togli(&v, j, preso)
            manca -= preso
        }
        guard manca > 0.005 else { return }
        let altre = v.voci.indices.filter { $0 != i && v.voci[$0].valore > 0 }
        let totale = altre.reduce(0) { $0 + v.voci[$1].valore }
        guard totale > 0 else {
            v.voci[i].valore = -manca
            return
        }
        let quota = min(1, manca / totale)
        for j in altre { togli(&v, j, v.voci[j].valore * quota) }
        manca -= totale * quota
        if manca > 0.005 { v.voci[i].valore = -manca }
    }

    /// Gli effetti di un evento sulle due vite.
    static func effetti(_ e: EventoAnno, partita p: PartitaLanciaAnno, inflazione: Double)
        -> (con: EffettoAnno, senza: EffettoAnno, copertura: Posizione?, diProva: Bool) {
        var diProva = false
        var importo: Double?
        switch e.effetto {
        case .spesa, .entrata:
            if let i = e.importo {
                importo = i * inflazione
            } else if p.diProva, let i = e.importoDiProva {
                importo = i * inflazione
                diProva = true
            }
        case .mancatoReddito:
            if let m = e.mesi, let r = p.redditoNetto { importo = Double(m) * r / 12 * inflazione }
        }
        if e.effetto == .entrata {
            let f = importo.map { EffettoAnno(importo: $0, frase: "Entrano \(euro($0))") }
                ?? EffettoAnno(importo: nil, frase: "Importo da scrivere in Impostazioni › Sala")
            return (f, f, nil, diProva)
        }
        func lato(_ coperture: [Posizione]) -> (EffettoAnno, Posizione?) {
            let polizza = e.rischio.flatMap { r in coperture.first { $0.rischio == r } }
            guard let x = importo else {
                let mancante = e.effetto == .mancatoReddito ? "Serve il reddito netto per la cifra" : "Importo da scrivere in Impostazioni › Sala"
                return (EffettoAnno(importo: nil, frase: polizza.map { "Coperto da «\($0.nome)»: \(mancante.lowercased())" } ?? mancante), polizza)
            }
            guard let polizza else { return (EffettoAnno(importo: -x, frase: "Dai risparmi: −\(euro(x))"), nil) }
            if let indennizzo = polizza.indennizzoStimato {
                // L'indennizzo è la cifra scritta dal consulente dalle condizioni: non si rivaluta con l'inflazione
                let netto = -x + indennizzo
                return (EffettoAnno(importo: netto, frase: "«\(polizza.nome)» copre \(euro(indennizzo)): \(segnato(netto))"), polizza)
            }
            // Senza indennizzo stimato la spesa resta tutta: nessuna cifra per la parte coperta
            return (EffettoAnno(importo: -x, frase: "Coperto da «\(polizza.nome)»: l’indennizzo dipende dalle condizioni"), polizza)
        }
        let (con, polizza) = lato(p.copertureCon)
        let (senza, _) = lato(p.copertureSenza)
        return (con, senza, polizza, diProva)
    }

    static func titoloMercato(z: Double) -> String {
        if z <= -1 { return "Un anno brutto dei mercati" }
        if z >= 1 { return "Un anno forte dei mercati" }
        return "Un anno normale dei mercati"
    }

    static func tonoMercato(z: Double) -> EventoAnno.Tono {
        if z <= -1 { return .rosso }
        if z >= 1 { return .verde }
        return .arancio
    }

    static func fraseMercato(_ r: Double) -> String {
        "I mercati fanno il loro: \(percento(r))"
    }

    static func percento(_ r: Double) -> String {
        let v = (r * 100).rounded()
        return (v > 0 ? "+" : v < 0 ? "−" : "") + "\(Int(abs(v)))%"
    }

    static func euro(_ v: Double) -> String { Formati.euro((abs(v) / 10).rounded() * 10) }

    static func segnato(_ v: Double) -> String { (v >= 0 ? "+" : "−") + euro(v) }
}
