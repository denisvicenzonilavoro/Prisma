import Foundation

/// Prova di «Tre livelli» (Vera/BRIEF.md, funzione 17) dentro `Prisma --prova-vera`: riconoscimento della richiesta,
/// cifre calcolate dai motori di Prisma (previdenza, protezione, liquidità), stessi numeri nelle tre versioni per tutti
/// i clienti del template, Qwen controllato livello per livello (cifre inventate, cifre essenziali mancanti, cifre in
/// parole, promesse, JSON non valido), la pagina come prospetto con l'avvertenza, «Manda al cliente» solo da confermare
/// e l'archivio. Niente rete, niente Qwen vero, niente dipendenza dall'ora: `oggi` è fisso.
enum ProvaTreLivelliVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let dati = StatoShell(persistente: false).dati.istantanea
        pacchetto(controlla)
        riconoscimento(controlla)
        previdenzaMarco(dati, controlla)
        tuttiCoerenti(dati, controlla)
        altriArgomenti(dati, controlla)
        senzaReddito(dati, controlla)
        qwen(dati, controlla)
        pagina(dati, controlla)
        archivio(dati, controlla)
    }

    /// Lunedì 9 novembre 2026, 10:00: sempre lo stesso giorno.
    private static let oggi: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 11
        c.day = 9
        c.hour = 10
        return Calendar(identifier: .gregorian).date(from: c) ?? Date(timeIntervalSince1970: 1_794_214_800)
    }()

    private static let domanda = "Perché il fondo pensione conviene a Marco?"

    private static func marco(_ dati: DatiPrisma, _ a: ArgomentoTreLivelli = .previdenza) -> SpiegazioneTreLivelli? {
        TreLivelliVera.fonte(dati: dati, clienteId: "marco", oggi: oggi).map { TreLivelliVera.bozza(a, $0, domanda: domanda) }
    }

    private static func json(_ o: [String: Any]) -> String {
        guard let d = try? JSONSerialization.data(withJSONObject: o), let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let t = IstruzioniVera.testo("tre-livelli") ?? ""
        controlla(t.contains("JSON") && t.contains("tecnico") && t.contains("pagina"),
                  "Tre livelli: istruzioni «tre-livelli» nel pacchetto (Vera/Istruzioni/tre-livelli.md)")
        controlla(TreLivelliVera.istruzioni.contains("JSON"), "Tre livelli: le istruzioni (o il ripiego) chiedono il JSON")
    }

    // MARK: - Riconoscimento

    private static func riconoscimento(_ controlla: (Bool, String) -> Void) {
        controlla(TreLivelliVera.eUnaRichiesta(domanda) && TreLivelliVera.argomento(domanda) == .previdenza,
                  "Tre livelli: «\(domanda)» è una richiesta sulla previdenza")
        controlla(TreLivelliVera.livelloChiesto(domanda) == .tecnico, "Tre livelli: di base si apre la versione per il consulente")
        let semplice = "Spiegami in parole semplici la protezione della famiglia di Giulia"
        controlla(TreLivelliVera.eUnaRichiesta(semplice) && TreLivelliVera.argomento(semplice) == .protezione && TreLivelliVera.livelloChiesto(semplice) == .cliente,
                  "Tre livelli: «parole semplici» sulla protezione apre la versione per il cliente")
        let pagina = "La liquidità di Sofia in una pagina da consegnare, spiegala"
        controlla(TreLivelliVera.eUnaRichiesta(pagina) && TreLivelliVera.argomento(pagina) == .liquidita && TreLivelliVera.livelloChiesto(pagina) == .pagina,
                  "Tre livelli: «in una pagina» sulla liquidità apre la pagina stampabile")
        controlla(!TreLivelliVera.eUnaRichiesta("Fissa un incontro con Marco giovedì alle 10"), "Tre livelli: un'azione d'agenda non è una spiegazione")
        controlla(!TreLivelliVera.eUnaRichiesta("La pensione di Marco"), "Tre livelli: «la pensione di Marco» resta allo spunto di sempre (nessuna richiesta di spiegazione)")
        controlla(!TreLivelliVera.eUnaRichiesta("Perché Laura non risponde?"), "Tre livelli: un «perché» senza argomento non è una spiegazione")
        controlla(TreLivelliVera.primoNome("Marco Bianchi") == "Marco" && TreLivelliVera.primoNome("Marco ed Elena Bianchi") == "Marco ed Elena",
                  "Tre livelli: il nome per il tu del cliente")
    }

    // MARK: - Previdenza di Marco (l'esempio del template)

    private static func previdenzaMarco(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        guard let f = TreLivelliVera.fonte(dati: dati, clienteId: "marco", oggi: oggi), let s = marco(dati) else {
            controlla(false, "Tre livelli: Marco tra i clienti del template")
            return
        }
        let e = MotorePrevidenza.calcola(f.posizioni, cliente: f.cliente, analisi: f.analisi.previdenza, data: oggi)
        func cifra(_ k: String) -> CifraTreLivelli? { s.cifre.first { $0.id == k } }
        controlla(e.divario >= 1 && cifra("divario")?.valore == e.divario.rounded() && cifra("divario")?.testo == CifreDoc.euro(e.divario),
                  "Tre livelli: il divario di Marco è quello di MotorePrevidenza (\(CifreDoc.euro(e.divario)))")
        controlla(cifra("pubblica")?.testo == CifreDoc.euro(e.pensionePubblica) && cifra("desiderato")?.testo == CifreDoc.euro(e.redditoDesiderato),
                  "Tre livelli: pensione pubblica stimata e tenore desiderato dall'Analisi 360")
        let marginale = RegoleFiscali.aliquotaMarginale(reddito: 48_000)
        controlla(cifra("marginale")?.valore == marginale && cifra("marginale")?.testo == CifreDoc.condizione(marginale),
                  "Tre livelli: aliquota marginale di Marco dagli scaglioni IRPEF di Prisma (\(CifreDoc.condizione(marginale)))")
        let recupero = RegoleFiscali.risparmioDeduzione(reddito: 48_000, deduzione: 100)
        controlla(cifra("recupero100")?.testo == CifreDoc.euro(recupero) && cifra("recupero100")?.essenziale == true,
                  "Tre livelli: ogni 100 € versati recupera \(CifreDoc.euro(recupero)), cifra essenziale")
        controlla(cifra("aliquotaBase")?.valore == RegoleFiscali.previdenzaBase && cifra("aliquotaMinima")?.valore == RegoleFiscali.previdenzaMinima
                  && cifra("riduzione")?.testo == "0,3 punti" && cifra("rendimenti")?.valore == RegoleFiscali.previdenzaRendimenti,
                  "Tre livelli: prestazione dal 15% al 9% (0,3 punti l'anno) e rendimenti al 20%, dalle regole di Prisma")
        if let piano = e.inEssere.first {
            controlla(cifra("aliquotaPiano")?.valore == piano.aliquota && s.tecnico.joined().contains(piano.posizione.nome) && s.tecnico.joined().contains("(Alleanza)"),
                      "Tre livelli: l'aliquota del piano di Marco alla pensione, con il nome e il canale")
        }
        let v = TreLivelliVera.verifica(s)
        controlla(TreLivelliVera.stessiNumeri(s), "Tre livelli: la bozza di Marco usa gli stessi numeri nelle tre versioni: \(v)")
        for c in s.essenziali {
            for l in LivelloTreLivelli.allCases {
                controlla(s.testoDaControllare(l).contains(c.testo), "Tre livelli: «\(c.etichetta)» (\(c.testo)) scritta uguale nella versione \(l.rawValue)")
            }
        }
        controlla(s.cliente.hasPrefix("Marco,") && !s.cliente.contains("IRPEF") && !s.cliente.contains("deducib"),
                  "Tre livelli: la versione per Marco ha il tu e niente termini tecnici: \(s.cliente)")
        controlla(s.tecnico.contains { $0.contains("IRPEF") } && s.tecnico.contains { $0.contains("divario") },
                  "Tre livelli: la versione tecnica parla di IRPEF e di divario")
        controlla(s.pagina.titolo == "Il fondo pensione, in una pagina" && s.pagina.sezioni.count >= 2 && s.canale == .alleanza,
                  "Tre livelli: la pagina di Marco ha il titolo del template, almeno due sezioni e il canale Alleanza")
        controlla(s.domanda == domanda && s.clienteId == "marco" && s.creataIl == oggi && !s.conQwen,
                  "Tre livelli: la bozza ricorda domanda, cliente e giorno, ed è di Prisma")
    }

    // MARK: - Tutti i clienti, tutti gli argomenti

    private static func tuttiCoerenti(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        var rotte: [String] = []
        var conte = 0
        for c in dati.clienti {
            guard let f = TreLivelliVera.fonte(dati: dati, clienteId: c.id, oggi: oggi) else { continue }
            for a in ArgomentoTreLivelli.allCases {
                let s = TreLivelliVera.bozza(a, f, domanda: "")
                conte += 1
                if !TreLivelliVera.stessiNumeri(s) || s.tecnico.isEmpty || s.cliente.isEmpty || s.pagina.sezioni.isEmpty {
                    rotte.append("\(c.id)/\(a.rawValue): \(TreLivelliVera.verifica(s).values.flatMap { $0 })")
                }
                if Set(s.cifre.map(\.id)).count != s.cifre.count { rotte.append("\(c.id)/\(a.rawValue): cifre doppie") }
            }
        }
        controlla(conte >= 15 && rotte.isEmpty, "Tre livelli: per i clienti del template (\(conte) spiegazioni) ogni cifra viene da Prisma e le essenziali stanno in tutte e tre le versioni: \(rotte)")
        controlla(TreLivelliVera.fonte(dati: dati, clienteId: "nessuno", oggi: oggi) == nil, "Tre livelli: un cliente che non c'è non ha fonte")
    }

    private static func altriArgomenti(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        guard let f = TreLivelliVera.fonte(dati: dati, clienteId: "marco", oggi: oggi),
              let prot = marco(dati, .protezione), let liq = marco(dati, .liquidita) else {
            controlla(false, "Tre livelli: protezione e liquidità di Marco")
            return
        }
        let ep = MotoreProtezioneFamiglia.calcola(f.posizioni, cliente: f.cliente, analisi: f.analisi.protezione, data: oggi)
        let fabbisogno = prot.cifre.first { $0.id == "fabbisogno" }
        controlla(fabbisogno?.testo == CifreDoc.euro(ep.fabbisogno) && (ep.fabbisogno < 1 || fabbisogno?.essenziale == true),
                  "Tre livelli: il fabbisogno caso morte di Marco è quello di MotoreProtezioneFamiglia (\(CifreDoc.euro(ep.fabbisogno)))")
        controlla(ep.capitaleVita < 1 || prot.cifre.first { $0.id == "coperto" }?.testo == CifreDoc.euro(ep.capitaleVita),
                  "Tre livelli: il capitale caso morte in essere di Marco dalle sue polizze")
        controlla(TreLivelliVera.stessiNumeri(prot) && prot.pagina.titolo.contains("protezione"),
                  "Tre livelli: protezione di Marco, stessi numeri nelle tre versioni: \(TreLivelliVera.verifica(prot))")
        let el = MotoreLiquidita.calcola(f.posizioni, obiettivi: f.obiettivi, analisi: f.analisi.protezione, prodotti: f.prodotti, data: oggi)
        controlla(liq.cifre.first { $0.id == "riserva" }?.testo == CifreDoc.euro(el.riservaNecessaria)
                  && liq.cifre.first { $0.id == "totale" }?.testo == CifreDoc.euro(el.totale),
                  "Tre livelli: riserva e liquidità di Marco da MotoreLiquidita")
        controlla(TreLivelliVera.stessiNumeri(liq) && liq.canale == nil, "Tre livelli: liquidità di Marco, stessi numeri nelle tre versioni: \(TreLivelliVera.verifica(liq))")
        controlla(TreLivelliVera.cifre(.protezione, f) == prot.cifre, "Tre livelli: le cifre di un argomento sono quelle della bozza")
    }

    private static func senzaReddito(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        guard let f = TreLivelliVera.fonte(dati: dati, clienteId: "marco", oggi: oggi) else { return }
        var c = f.cliente
        c.profilo.redditoLordoAnnuo = nil
        let senza = FonteTreLivelli(oggi: oggi, cliente: c, posizioni: f.posizioni, analisi: f.analisi, analisiSalvata: false)
        let s = TreLivelliVera.bozza(.previdenza, senza, domanda: "")
        controlla(!s.cifre.contains { $0.id == "recupero100" || $0.id == "marginale" } && s.note.contains { $0.contains("reddito") },
                  "Tre livelli: senza reddito niente risparmio IRPEF inventato, e una nota per il consulente")
        controlla(s.note.contains { $0.contains("prima stesura") } && TreLivelliVera.stessiNumeri(s),
                  "Tre livelli: con l'Analisi 360 non salvata la nota lo dice, e i numeri restano coerenti")
        controlla(s.note.allSatisfy { FontiVera.numeri($0).allSatisfy { $0.unita != .euro && $0.unita != .percento } },
                  "Tre livelli: le note per il consulente non portano importi né percentuali (il nome «Analisi 360» sì)")
    }

    // MARK: - Qwen, livello per livello

    private static func qwen(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        guard let b = marco(dati) else { return }
        func t(_ k: String) -> String { b.cifre.first { $0.id == k }?.testo ?? "?" }
        let clienteBuono = "Marco, alla pensione ti mancheranno circa \(t("divario")) al mese. Per ogni \(t("riferimento")) messi nel fondo ne riavrai circa \(t("recupero100")) con la dichiarazione. Alla pensione paghi al massimo il \(t("aliquotaBase"))."
        let paginaBuona: [String: Any] = ["titolo": "Il tuo fondo pensione", "sezioni": [
            ["titolo": "1. Quanto ti manca", "righe": ["- Ti mancano \(t("divario")) al mese"]] as [String: Any],
            ["titolo": "2. Perché conviene", "righe": ["Ogni \(t("riferimento")) versati ne recuperi \(t("recupero100"))", "Alla pensione paghi al massimo il \(t("aliquotaBase"))"]] as [String: Any],
        ]]
        let buona = TreLivelliVera.leggi(json(["tecnico": b.tecnico.map { "1. \($0) (riscritto)" }, "cliente": clienteBuono, "pagina": paginaBuona]), bozza: b)
        controlla(Set(buona.livelliQwen) == Set(LivelloTreLivelli.allCases) && buona.conQwen,
                  "Tre livelli: con le cifre di Prisma tutti e tre i livelli di Qwen passano: \(buona.livelliQwen.map(\.rawValue))")
        controlla(buona.tecnico.first?.hasPrefix("1. ") == false && buona.tecnico.allSatisfy { $0.hasSuffix("(riscritto)") }
                  && buona.pagina.sezioni.first?.titolo == "Quanto ti manca" && buona.pagina.sezioni.first?.righe.first?.hasPrefix("Ti mancano") == true,
                  "Tre livelli: numerazione e segni d'elenco di Qwen tolti")
        controlla(TreLivelliVera.stessiNumeri(buona), "Tre livelli: dopo Qwen stessi numeri nelle tre versioni")
        controlla(buona.cifre == b.cifre && buona.id == b.id, "Tre livelli: Qwen cambia le parole, non le cifre né la spiegazione")

        // Una cifra inventata, una essenziale che manca, cifre in parole, una promessa: quel livello resta di Prisma
        let inventato = clienteBuono + " In tutto riceverai 1.234.567 €."
        let senzaDivario: [String: Any] = ["titolo": "Il tuo fondo", "sezioni": [["titolo": "Perché conviene", "righe": ["Alla pensione paghi al massimo il \(t("aliquotaBase"))"]] as [String: Any]]]
        let mista = TreLivelliVera.leggi(json(["tecnico": b.tecnico.map { "\($0) (riscritto)" }, "cliente": inventato, "pagina": senzaDivario]), bozza: b)
        controlla(mista.livelliQwen == [.tecnico] && mista.cliente == b.cliente && mista.pagina == b.pagina,
                  "Tre livelli: cifra inventata per il cliente e divario mancante nella pagina scartati, resta la bozza: \(mista.livelliQwen.map(\.rawValue))")
        controlla(TreLivelliVera.stessiNumeri(mista), "Tre livelli: dopo gli scarti i numeri tornano ancora")
        let parole = TreLivelliVera.leggi(json(["tecnico": ["Il divario è di mille e cento euro al mese."], "cliente": clienteBuono + " Il risultato è garantito.", "pagina": paginaBuona]), bozza: b)
        controlla(parole.livelliQwen == [.pagina] && parole.tecnico == b.tecnico && parole.cliente == b.cliente,
                  "Tre livelli: cifre in parole e promessa di risultato scartate: \(parole.livelliQwen.map(\.rawValue))")
        // Le cifre in parole da sole: un testo con tutte le cifre essenziali e solo «mille» in più è scartato proprio per quello
        let conMille = clienteBuono + " Sono più di mille euro in dieci anni."
        let pMille = TreLivelliVera.problemi(conMille, livello: .cliente, spiegazione: b)
        controlla(TreLivelliVera.problemi(clienteBuono, livello: .cliente, spiegazione: b).isEmpty && pMille == ["cliente: cifre in parole"],
                  "Tre livelli: «mille» con tutte le cifre essenziali è scartato per le cifre in parole: \(pMille)")
        for frase in ["Il fondo ti fa risparmiare il venti per cento.", "Ogni mese metti trentacinque euro.", "Tra diciotto anni sarai in pensione.",
                      "Ne recuperi la metà.", "Servono duecento euro.",
                      // I composti in una parola sola e «sei» seguito da un'unità sono cifre
                      "Ti servono duemila euro.", "Ne mancano ventimila.", "Sono centocinquanta euro al mese.",
                      "Metti da parte millecinquecento euro.", "Tieni da parte sei mesi di spese.", "Arrivi a seimila euro."] {
            let pp = TreLivelliVera.problemi(clienteBuono + " " + frase, livello: .cliente, spiegazione: b)
            controlla(pp.contains("cliente: cifre in parole"), "Tre livelli: «\(frase)» ha cifre in parole: \(pp)")
        }
        controlla(!TreLivelliVera.cifreInParole("Ti sei mai chiesto, in tutte e tre le versioni, quanto ti serve?"),
                  "Tre livelli: «sei» verbo e «tutte e tre» non sono cifre in parole")
        let composti = TreLivelliVera.paroleNumeriche("Ti servono duemila euro, ventimila in tutto, centocinquanta al mese, millecinquecento l'anno, seimila e sei anni.")
        controlla(composti == ["duemila", "ventimila", "centocinquanta", "millecinquecento", "seimila", "sei anni"],
                  "Tre livelli: i numerali composti in una parola e «sei anni» si riconoscono: \(composti.sorted())")
        controlla(!TreLivelliVera.cifreInParole("A settembre a Milano, in centro, sei pronto per uno dei fondi?"),
                  "Tre livelli: «settembre», «Milano», «centro», «sei» verbo e «uno» non sono cifre in parole")

        // Una cifra di Prisma con un'altra unità è un'altra cifra: «67 €» non è «67 anni», «15 €» non è «15%»
        let eta = t("etaPensione")
        let anniEta = FontiVera.numeri(eta).first?.valore ?? 0
        let etaInEuro = clienteBuono + " Ti servono \(Int(anniEta)) € in più."
        let pEuro = TreLivelliVera.problemi(etaInEuro, livello: .cliente, spiegazione: b)
        controlla(anniEta > 0 && pEuro.contains { $0.contains("cifra non di Prisma") },
                  "Tre livelli: l'età della pensione (\(eta)) scritta in euro non passa: \(pEuro)")
        let base = t("aliquotaBase")
        let baseValore = FontiVera.numeri(base).first?.valore ?? 0
        let baseInEuro = clienteBuono.replacingOccurrences(of: "il \(base)", with: "\(Int(baseValore)) €")
        let pBase = TreLivelliVera.problemi(baseInEuro, livello: .cliente, spiegazione: b)
        controlla(baseValore > 0 && baseInEuro != clienteBuono && pBase.contains { $0.contains("cifra non di Prisma") },
                  "Tre livelli: l'aliquota (\(base)) scritta come importo non passa: \(pBase)")
        controlla(TreLivelliVera.problemi(clienteBuono + " Lo dice il tuo piano a \(Int(anniEta)).", livello: .cliente, spiegazione: b).isEmpty,
                  "Tre livelli: una cifra di Prisma scritta senza unità resta ammessa")

        // Un anno o un importo da 1900 a 2100 scritto da solo non sfugge più al controllo
        let pAnno = TreLivelliVera.problemi(clienteBuono + " Andrai in pensione nel 2049.", livello: .cliente, spiegazione: b)
        let pDuemila = TreLivelliVera.problemi(clienteBuono + " Ti mancheranno circa 1987 al mese.", livello: .cliente, spiegazione: b)
        controlla(pAnno.contains { $0.contains("«2049»") } && pDuemila.contains { $0.contains("«1987»") },
                  "Tre livelli: «nel 2049» e «1987 al mese» inventati da Qwen si vedono: \(pAnno) \(pDuemila)")

        let tecnicoSenza = TreLivelliVera.leggi(json(["tecnico": ["Conviene per le tasse."], "cliente": "", "pagina": ["titolo": "", "sezioni": [Any]()] as [String: Any]]), bozza: b)
        controlla(tecnicoSenza.livelliQwen.isEmpty && tecnicoSenza == b, "Tre livelli: senza le cifre essenziali e con livelli vuoti resta tutta la bozza")
        controlla(TreLivelliVera.leggi("Non so rispondere.", bozza: b) == b && TreLivelliVera.leggi("{rotto", bozza: b) == b,
                  "Tre livelli: un JSON non valido lascia la bozza com'è")

        // Un livello con una cifra diversa: le tre versioni non dicono più gli stessi numeri
        var diversa = b
        diversa.cliente = b.cliente.replacingOccurrences(of: t("divario"), with: "9.999 €")
        let v = TreLivelliVera.verifica(diversa)
        controlla(!TreLivelliVera.stessiNumeri(diversa) && !(v[.cliente] ?? []).isEmpty && (v[.tecnico] ?? []).isEmpty,
                  "Tre livelli: una cifra cambiata in un solo livello si vede: \(v[.cliente] ?? [])")

        // Il messaggio per Qwen e le opzioni
        let m = TreLivelliVera.messaggi(b)
        controlla(m.count == 2 && m[0].ruolo == .sistema && m[1].testo.contains("CIFRE DI PRISMA") && m[1].testo.contains("\(t("divario")) [in tutte e tre]")
                  && m[1].testo.contains(domanda), "Tre livelli: a Qwen vanno le cifre di Prisma, le essenziali segnate, la domanda e la bozza")
        let o = TreLivelliVera.opzioni(ImpostazioniVera())
        controlla(o.formato != nil && o.temperatura <= 0.3 && (o.massimoToken ?? 0) > 0, "Tre livelli: Qwen risponde con lo schema JSON")
        controlla(TreLivelliVera.schema["required"] as? [String] == ["tecnico", "cliente", "pagina"], "Tre livelli: lo schema chiede tecnico, cliente e pagina")
    }

    // MARK: - Pagina, conferma, chat

    private static func pagina(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        guard let s = marco(dati), let c = dati.clienti.first(where: { $0.id == "marco" }) else { return }
        let p = TreLivelliVera.contenuto(s)
        var indicatori: [IndicatoreProspetto] = []
        var testi: [String] = []
        var note: [String] = []
        var sezioni = 0
        for b in p.blocchi {
            switch b {
            case .indicatori(let i): indicatori += i
            case .testo(let t): testi.append(t)
            case .nota(let n): note.append(n)
            case .sezione: sezioni += 1
            default: break
            }
        }
        controlla(p.titolo == s.pagina.titolo && p.cliente == s.nomeCliente && p.canale == .alleanza && p.data == oggi,
                  "Tre livelli: la pagina diventa un prospetto con titolo, cliente, canale e giorno")
        controlla(indicatori.map(\.valore) == s.essenziali.map(\.testo) && sezioni == s.pagina.sezioni.count,
                  "Tre livelli: nel PDF le cifre essenziali come indicatori, una sezione per sezione della pagina")
        controlla(note.contains { $0.contains("Stime di Prisma") && $0.contains("Non sono una promessa di risultato") },
                  "Tre livelli: il PDF porta l'avvertenza «Stime di Prisma… non sono una promessa di risultato»")
        controlla(testi.joined(separator: "\n").contains(s.essenziali.first?.testo ?? "?"), "Tre livelli: le righe della pagina nel PDF con le stesse cifre")
        controlla(s.testo(.pagina).hasSuffix(TreLivelliVera.avvertenza), "Tre livelli: anche in chat la pagina chiude con l'avvertenza")

        let a = TreLivelliVera.azioneManda(s, cliente: c)
        controlla(a.strumento == RegistroStrumenti.messaggiPrepara && a.app == .messaggi && a.argomenti["cliente"] == "marco"
                  && a.argomenti["testo"] == s.cliente && a.esito == nil && a.avviso == nil,
                  "Tre livelli: «Manda a Marco» è una bozza da confermare, con il testo semplice (Vera non invia)")
        var rotta = s
        rotta.cliente += " Ti costerà 7.777 €."
        controlla(TreLivelliVera.azioneManda(rotta, cliente: c).avviso != nil, "Tre livelli: se le cifre non tornano la scheda di conferma avvisa")

        let r = TreLivelliVera.risposta(s, livello: .cliente)
        controlla(r.testo == s.cliente && (r.titolo ?? "").contains("Per Marco"), "Tre livelli: in chat la versione per il cliente con il titolo «Per Marco»")
        controlla(LivelloTreLivelli.cliente.etichetta(cliente: "Marco") == "Per Marco" && LivelloTreLivelli.tecnico.etichetta(cliente: "Marco") == "Per te",
                  "Tre livelli: le etichette del selettore come nel template")
    }

    // MARK: - Archivio

    private static func archivio(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        guard let s = marco(dati) else { return }
        let codifica = JSONEncoder()
        let decodifica = JSONDecoder()
        let tornata = (try? codifica.encode(s)).flatMap { try? decodifica.decode(SpiegazioneTreLivelli.self, from: $0) }
        controlla(tornata == s, "Tre livelli: la spiegazione si salva e si rilegge uguale")
        let poco = Data(#"{"id":"tre-livelli-vecchia","clienteId":"marco","argomento":"sconosciuto","cifre":"rotto"}"#.utf8)
        let vecchia = try? decodifica.decode(SpiegazioneTreLivelli.self, from: poco)
        controlla(vecchia?.id == "tre-livelli-vecchia" && vecchia?.argomento == .previdenza && vecchia?.cifre.isEmpty == true && vecchia?.livelliQwen.isEmpty == true,
                  "Tre livelli: una spiegazione scritta da un'altra versione si legge con tolleranza")
    }
}
