import CoreGraphics
import Foundation
import SwiftUI

/// Prove del Territorio («Luce» giro 11, §5.1 «Il tuo territorio»): la tabella dei comuni (di prova, senza codici
/// catastali), il riconoscimento del comune (niente CAP), i luoghi e lo sparpaglio deterministico, le distanze stimate,
/// il giro e il suggerimento «Lungo la strada» (date fisse, mai `Date()`), il criterio «qualcosa da fare», la vista Oggi,
/// la crescita (storico, chiuse, mai un fattore), il raggio della luce, la proiezione, le prestazioni con 200 clienti,
/// le voci di MotoreDaFare e l'ordine della partenza. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliTerritorio {
    static func esegui(_ verifica: VerificaCalcoli) {
        guard let tabella = TabellaTerritorio.caricaComuni() else {
            verifica.vero("Territorio: la tabella dei comuni si legge dalle risorse", false)
            return
        }
        tabellaComuni(verifica, tabella)
        riconoscimento(verifica, tabella)
        luoghi(verifica, tabella)
        sparpaglio(verifica, tabella)
        distanze(verifica, tabella)
        giro(verifica, tabella)
        suggerimento(verifica, tabella)
        criterio(verifica)
        oggi(verifica, tabella)
        crescita(verifica)
        raggio(verifica)
        proiezione(verifica)
        prestazioni(verifica, tabella)
        vociDaFare(verifica)
        partenza(verifica, tabella)
    }

    private static let cal = Calendar(identifier: .gregorian)

    /// Un cliente di prova (dati di prova, inventati).
    private static func cliente(_ id: String, _ indirizzo: String, nome: String? = nil) -> Cliente {
        var c = Cliente(id: id, nome: nome ?? "Prova \(id)", iniziali: "PR", tinta: .blu, tema: "", email: "", telefono: "",
                        preferito: false, nota: "dati di prova", creatoIl: AiutiProva.data(2020, 1, 1))
        c.indirizzo = indirizzo
        return c
    }

    // MARK: 1. Tabella

    private static func tabellaComuni(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        verifica.vero("Territorio: la tabella delle risorse è quella di prova (dichiarata)", t.diProva)
        verifica("Territorio: 32 comuni nella tabella di prova", Double(t.comuni.count), 32)
        verifica.vero("Territorio: il codice di ogni comune è <SIGLA>-<nome normalizzato>",
                      t.comuni.allSatisfy { $0.codice == "\($0.provincia)-\(TabellaTerritorio.normalizza($0.nome))" })
        let etichette = t.comuni.first.map { Mirror(reflecting: $0).children.compactMap { $0.label } } ?? []
        verifica.vero("Territorio: nessun codice catastale nella tabella (decisione 70)",
                      !etichette.isEmpty && !etichette.contains { $0.lowercased().contains("catast") })
        verifica.vero("Territorio: i confini di prova di Bologna si leggono", TabellaTerritorio.caricaConfini(provincia: "BO")?.comuni["BO-bologna"] != nil)
    }

    // MARK: 2. Riconoscimento del comune

    private static func codice(_ e: EsitoComune) -> String? {
        if case .trovato(let c) = e { return c.codice }
        return nil
    }

    private static func riconoscimento(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        verifica.vero("Territorio: «Via dei Mille 12, Bologna» → Bologna",
                      codice(TabellaTerritorio.comune(testo: "Via dei Mille 12, Bologna", tabella: t)) == "BO-bologna")
        verifica.vero("Territorio: «Via Roma 210, Padova» → Padova",
                      codice(TabellaTerritorio.comune(testo: "Via Roma 210, Padova", tabella: t)) == "PD-padova")
        verifica.vero("Territorio: il CAP si ignora («40121 Bologna BO» → Bologna)",
                      codice(TabellaTerritorio.comune(testo: "Via X 1, 40121 Bologna BO", tabella: t)) == "BO-bologna")
        verifica.vero("Territorio: comune omonimo senza sigla → ambiguo (TN, TO)",
                      TabellaTerritorio.comune(testo: "Piazza 1, Samone", tabella: t) == .ambiguo(["TN", "TO"]))
        verifica.vero("Territorio: comune omonimo con la sigla «(TN)» → Samone TN",
                      codice(TabellaTerritorio.comune(testo: "Piazza 1, Samone (TN)", tabella: t)) == "TN-samone")
        verifica.vero("Territorio: comune inesistente → non trovato",
                      TabellaTerritorio.comune(testo: "Via Che Non Esiste 3, Paperopoli", tabella: t) == .nonTrovato)
        verifica.vero("Territorio: indirizzo vuoto → vuoto", TabellaTerritorio.comune(testo: "  ", tabella: t) == .vuoto)
        verifica.vero("Territorio: indirizzo senza virgola («Piazza Duomo 3 Trento») → Trento",
                      codice(TabellaTerritorio.comune(testo: "Piazza Duomo 3 Trento", tabella: t)) == "TN-trento")
        verifica.vero("Territorio: normalizzazione «Sant'Ilario d'Enza» = «santilariodenza»",
                      TabellaTerritorio.normalizza("Sant'Ilario d’Enza") == "santilariodenza")
        // La sede fiscale con il comune vince sull'indirizzo; una sede con il solo indirizzo non lo nasconde; estero
        var conSede = cliente("sede", "Via dei Mille 12, Bologna")
        var f = DatiFiscaliCliente()
        f.sede.comune = "Padova"
        f.sede.provincia = "PD"
        conSede.fiscale = f
        var soloVia = cliente("via", "Via dei Mille 12, Bologna")
        var g = DatiFiscaliCliente()
        g.sede.indirizzo = "Via Altra"
        soloVia.fiscale = g
        var estero = cliente("estero", "Rue de Rivoli 1, Paris")
        var h = DatiFiscaliCliente()
        h.sede.nazione = "FR"
        estero.fiscale = h
        let r = MotoreTerritorio.luoghi(clienti: [conSede, soloVia, estero], tabella: t, zone: [])
        verifica.vero("Territorio: il comune della sede fiscale vince sul testo dell'indirizzo", r.luoghi["sede"]?.comune?.codice == "PD-padova")
        verifica.vero("Territorio: una sede con il solo indirizzo non nasconde l'indirizzo del cliente", r.luoghi["via"]?.comune?.codice == "BO-bologna")
        verifica.vero("Territorio: sede fuori dall'Italia → «sede fuori dall'Italia»",
                      r.senzaLuogo.first { $0.id == "estero" }?.motivo == .estero)
        verifica.vero("Territorio: «Samone» senza sigla resta fuori con il motivo «più province»",
                      MotoreTerritorio.luoghi(clienti: [cliente("s", "Piazza 1, Samone")], tabella: t, zone: []).senzaLuogo.first?.motivo
                          == .comuneAmbiguo("Samone", ["TN", "TO"]))
    }

    // MARK: 3. Luoghi

    private static func luoghi(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        let demo = DatiDemo.clienti()
        let r = MotoreTerritorio.luoghi(clienti: demo, tabella: t, zone: [])
        verifica.vero("Territorio: i 5 clienti di prova sono tutti sulla mappa", r.senzaLuogo.isEmpty && r.luoghi.count == demo.count)
        var aMano = demo
        aMano[0].luogo = LuogoManuale(coordinata: Coordinata(lat: 44.5, lon: 11.35), nota: "prova")
        let m = MotoreTerritorio.luoghi(clienti: aMano, tabella: t, zone: [])
        verifica.vero("Territorio: la posizione a mano vince sul comune",
                      m.luoghi[aMano[0].id]?.precisione == .manuale && m.luoghi[aMano[0].id]?.coordinata == Coordinata(lat: 44.5, lon: 11.35))
        let fittizi = ClientiFittizi.completi().clienti
        let f = MotoreTerritorio.luoghi(clienti: fittizi, tabella: t, zone: [])
        verifica.vero("Territorio: i 35 clienti di prova (5 + 30 fittizi) sono tutti sulla mappa con la tabella di prova",
                      f.senzaLuogo.isEmpty && f.luoghi.count == fittizi.count)
        let zona = ZonaTerritorio(id: "z", nome: "Emilia di prova", comuni: ["BO-bologna", "MO-modena"])
        let z = MotoreTerritorio.luoghi(clienti: [cliente("a", "Via 1, Bologna"), cliente("b", "Via 2, Modena")], tabella: t, zone: [zona])
        verifica.vero("Territorio: le zone dell'utente raggruppano i comuni", z.luoghi["a"]?.zona == "Emilia di prova" && z.luoghi["b"]?.zona == "Emilia di prova")
    }

    // MARK: 4. Sparpaglio

    private static func sparpaglio(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        guard let bologna = t.perCodice["BO-bologna"] else {
            verifica.vero("Territorio: Bologna nella tabella di prova", false)
            return
        }
        let a = MotoreTerritorio.sparpaglia(["c", "a", "b"], attorno: bologna)
        let b = MotoreTerritorio.sparpaglia(["a", "b", "c"], attorno: bologna)
        verifica.vero("Territorio: lo sparpaglio è deterministico", a == b)
        verifica.vero("Territorio: 3 clienti dello stesso comune → 3 punti diversi", Set(a.values).count == 3)
        verifica.vero("Territorio: i punti sparpagliati restano entro il raggio del comune",
                      a.values.allSatisfy { MotoreTerritorio.distanzaKm($0, bologna.centro) <= bologna.raggioKm })
        verifica.vero("Territorio: un cliente solo sta sul centroide", MotoreTerritorio.sparpaglia(["x"], attorno: bologna)["x"] == bologna.centro)
    }

    // MARK: 5. Distanze

    private static func distanze(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        guard let bo = t.perCodice["BO-bologna"]?.centro, let pd = t.perCodice["PD-padova"]?.centro else {
            verifica.vero("Territorio: Bologna e Padova nella tabella di prova", false)
            return
        }
        // Emisenoverso scritto qui, sulle coordinate della tabella
        let r = Double.pi / 180
        let h = pow(sin((pd.lat - bo.lat) * r / 2), 2) + cos(bo.lat * r) * cos(pd.lat * r) * pow(sin((pd.lon - bo.lon) * r / 2), 2)
        let attesa = 2 * 6371.0088 * asin(h.squareRoot())
        let d = MotoreTerritorio.distanzaKm(bo, pd)
        verifica("Territorio: Bologna-Padova in linea d'aria", d, attesa, tolleranza: 0.001)
        verifica("Territorio: Bologna-Padova circa 110 km (tabella di prova)", d, 110, tolleranza: 2.2)
        let imp = ImpostazioniTerritorio()
        let tr = MotoreTerritorio.tratto(bo, pd, stessoComune: false, impostazioni: imp)
        verifica("Territorio: il tratto è la linea d'aria × 1,3", tr.km, d * 1.3, tolleranza: 0.001)
        verifica("Territorio: minuti = km / 70 × 60", Double(tr.minuti), (d * 1.3 / 70 * 60).rounded())
        let corto = MotoreTerritorio.tratto(bo, Coordinata(lat: bo.lat + 0.001, lon: bo.lon), stessoComune: true, impostazioni: imp)
        verifica("Territorio: un tratto cortissimo dura almeno 5 minuti", Double(corto.minuti), 5)
    }

    // MARK: 6. Giro

    private static func giro(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        let giorno = AiutiProva.data(2026, 11, 10)
        func ora(_ h: Int, _ m: Int = 0) -> Date { cal.date(bySettingHour: h, minute: m, second: 0, of: giorno) ?? giorno }
        let clienti = [cliente("a", "Via 1, Bologna"), cliente("b", "Via 2, Modena"), cliente("c", "Via 3, Bologna"),
                       cliente("d", "Via 4, Firenze"), cliente("e", "Via 5, Siena"), cliente("f", "Via 6, Paperopoli")]
        let l = MotoreTerritorio.luoghi(clienti: clienti, tabella: t, zone: [])
        let app = [
            Appuntamento(id: "b2", clienteId: "b", titolo: "Visita", inizio: ora(15), durataMinuti: 60, luogo: "", note: "", stato: .pianificato,
                         tipo: .analisi, presso: .cliente),
            Appuntamento(id: "a1", clienteId: "a", titolo: "Visita", inizio: ora(9), durataMinuti: 60, luogo: "", note: "", stato: .concluso,
                         tipo: .revisione, presso: .cliente),
            Appuntamento(id: "tel", clienteId: "c", titolo: "Telefonata", inizio: ora(11), durataMinuti: 30, luogo: "", note: "", stato: .pianificato,
                         tipo: .telefonata, presso: .cliente),
            Appuntamento(id: "blocco", clienteId: "", titolo: "Non disponibile", inizio: ora(12), durataMinuti: 30, luogo: "", note: "",
                         stato: .pianificato, tipo: .nonDisponibile),
            Appuntamento(id: "studio", clienteId: "c", titolo: "In studio", inizio: ora(16, 30), durataMinuti: 30, luogo: "", note: "",
                         stato: .pianificato, tipo: .analisi, presso: .studio),
            Appuntamento(id: "nil", clienteId: "d", titolo: "Da indicare", inizio: ora(17), durataMinuti: 30, luogo: "", note: "",
                         stato: .pianificato, tipo: .analisi),
            Appuntamento(id: "altro", clienteId: "e", titolo: "Altrove", inizio: ora(18), durataMinuti: 30, luogo: "", note: "",
                         stato: .pianificato, tipo: .analisi, presso: .altro),
            Appuntamento(id: "senza", clienteId: "f", titolo: "Senza luogo", inizio: ora(13), durataMinuti: 30, luogo: "", note: "",
                         stato: .pianificato, tipo: .analisi, presso: .cliente),
        ]
        let partenza = Coordinata(lat: 44.494, lon: 11.343)
        let g = MotoreTerritorio.giro(giorno: giorno, appuntamenti: app, clienti: clienti, luoghi: l.luoghi, partenza: partenza, daFare: [:],
                                      impostazioni: ImpostazioniTerritorio(), orari: OrariLavoro(), calendario: cal)
        verifica.vero("Territorio: il giro tiene solo le visite dal cliente (niente telefonate, blocchi, studio), in ordine d'ora",
                      g.tappe.compactMap(\.appuntamento?.id) == ["a1", "b2"])
        verifica.vero("Territorio: partenza e rientro, una sola volta", g.tappe.first?.genere == .partenza && g.tappe.last?.genere == .rientro
                          && g.tappe.filter { $0.genere != .visita }.count == 2)
        verifica.vero("Territorio: il luogo non indicato va in «luogo da indicare»", g.luogoDaIndicare.map(\.id) == ["nil"])
        verifica("Territorio: le visite «altrove» si contano a parte", Double(g.altrove), 1)
        verifica.vero("Territorio: la visita di un cliente senza luogo resta fuori, segnata", g.senzaLuogo.map(\.id) == ["senza"])
        verifica("Territorio: km totali = somma dei tratti", g.km, g.tappe.reduce(0) { $0 + $1.kmDaPrima }, tolleranza: 0.0001)
        verifica("Territorio: minuti totali = somma dei tratti", Double(g.minuti), Double(g.tappe.reduce(0) { $0 + $1.minutiDaPrima }))
        verifica("Territorio: «2 visite» (non «3 tappe»)", Double(g.visite), 2)
        let senzaPartenza = MotoreTerritorio.giro(giorno: giorno, appuntamenti: app, clienti: clienti, luoghi: l.luoghi, partenza: nil, daFare: [:],
                                                  impostazioni: ImpostazioniTerritorio(), orari: OrariLavoro(), calendario: cal)
        verifica.vero("Territorio: senza partenza il giro comincia dalla prima visita",
                      senzaPartenza.tappe.allSatisfy { $0.genere == .visita } && senzaPartenza.tappe.first?.kmDaPrima == 0)
        let vuoto = MotoreTerritorio.giro(giorno: AiutiProva.data(2026, 11, 9), appuntamenti: app, clienti: clienti, luoghi: l.luoghi,
                                          partenza: partenza, daFare: [:], impostazioni: ImpostazioniTerritorio(), orari: OrariLavoro(), calendario: cal)
        verifica.vero("Territorio: giorno senza visite → il prossimo giro è il primo giorno dopo con visite",
                      vuoto.vuoto && vuoto.prossimoGiorno == cal.startOfDay(for: giorno))
    }

    // MARK: 7. Suggerimento

    private static func datiGiro(_ giorno: Date) -> DatiPrisma {
        var d = DatiPrisma.demo()
        d.appuntamenti = []
        d.attivita = []
        TerritorioDiProva.applica(&d, giorno: giorno, conPartenza: true, calendario: cal)
        return d
    }

    private static func ingressi(_ d: DatiPrisma, oggi: Date, attenzioni: [Attenzione] = []) -> MotoreDaFare.Ingressi {
        MotoreDaFare.Ingressi(clienti: d.clienti, posizioni: d.posizioni, attivita: d.attivita, proposte: [], riesami: [],
                              conformita: [], occasioni: [], attenzioni: attenzioni, oggi: oggi)
    }

    private static func giroDi(_ d: DatiPrisma, _ giorno: Date, _ t: TabellaComuni, daFare: [String: DaFareCliente]) -> GiroGiorno {
        let l = MotoreTerritorio.luoghi(clienti: d.clienti, tabella: t, zone: [])
        return MotoreTerritorio.giro(giorno: giorno, appuntamenti: d.appuntamenti, clienti: d.clienti, luoghi: l.luoghi,
                                     partenza: TerritorioDiProva.partenza, daFare: daFare, impostazioni: ImpostazioniTerritorio(),
                                     orari: OrariLavoro(), calendario: cal)
    }

    private static func suggerimento(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        let martedi = AiutiProva.data(2026, 11, 10)
        let lunedi = AiutiProva.data(2026, 11, 9)
        var d = datiGiro(martedi)
        let voci = MotoreDaFare.voci(ingressi(d, oggi: lunedi))
        let daFare = MotoreTerritorio.daFare(voci, attenzioni: [], attenzioniAlte: [])
        verifica.vero("Territorio: l'attività di prova di Sofia è «qualcosa da fare»", daFare["sofia"] != nil)
        let g = giroDi(d, martedi, t, daFare: daFare)
        verifica("Territorio: giro di prova con 2 visite", Double(g.visite), 2)
        let s = g.suggerimenti.first
        verifica.vero("Territorio: Sofia, a metà strada, è suggerita lungo la strada", s?.cliente.id == "sofia")
        if let s, g.tappe.indices.contains(s.dopoTappa), g.tappe.indices.contains(s.primaDiTappa),
           let a = g.tappe[s.dopoTappa].appuntamento, let b = g.tappe[s.primaDiTappa].appuntamento {
            verifica.vero("Territorio: l'ora proposta cade fra le due visite, con la deviazione entro 10 minuti",
                          s.ora >= a.fine && s.ora.addingTimeInterval(TimeInterval(30 * 60)) <= b.inizio && s.deviazioneMinuti <= 10)
        } else {
            verifica.vero("Territorio: il suggerimento indica le due visite fra cui cade", false)
        }
        // Un cliente con qualcosa da fare lontano (Modena) non si propone
        var lontano = daFare
        lontano["giulia"] = DaFareCliente(perche: "Prova", tipo: .attivita, gruppo: .oggi)
        if let i = d.clienti.firstIndex(where: { $0.id == "giulia" }) {
            d.clienti[i].luogo = LuogoManuale(coordinata: Coordinata(lat: 44.65, lon: 10.93), nota: "prova")
        }
        verifica.vero("Territorio: un cliente a mezz'ora di deviazione non si propone",
                      !giroDi(d, martedi, t, daFare: lontano).suggerimenti.contains { $0.cliente.id == "giulia" })
        // Senza spazio in agenda (un blocco «non disponibile» che occupa il buco) niente suggerimento
        var pieno = d
        let inizio = cal.date(bySettingHour: 11, minute: 0, second: 0, of: martedi) ?? martedi
        pieno.appuntamenti.append(Appuntamento(id: "blocco", clienteId: "", titolo: "Non disponibile", inizio: inizio, durataMinuti: 90,
                                               luogo: "", note: "", stato: .pianificato, tipo: .nonDisponibile))
        verifica.vero("Territorio: senza spazio libero fra le visite nessun suggerimento", giroDi(pieno, martedi, t, daFare: daFare).suggerimenti.isEmpty)
        // Un cliente senza nulla da fare no
        verifica.vero("Territorio: un cliente senza nulla da fare non si propone", giroDi(d, martedi, t, daFare: [:]).suggerimenti.isEmpty)
        // Di domenica (fuori dagli orari di lavoro) nessun suggerimento
        let domenica = AiutiProva.data(2026, 11, 15)
        let dd = datiGiro(domenica)
        verifica.vero("Territorio: di domenica nessun suggerimento", giroDi(dd, domenica, t, daFare: daFare).suggerimenti.isEmpty)
        // I dati di prova del giro si tolgono tutti (appuntamenti, attività, posizioni a mano, partenza)
        var tolto = datiGiro(martedi)
        TerritorioDiProva.togli(&tolto)
        let p = TerritorioDiProva.prefisso
        verifica.vero("Territorio: i dati di prova del giro si tolgono",
                      !tolto.appuntamenti.contains { $0.id.hasPrefix(p) } && !tolto.attivita.contains { $0.id.hasPrefix(p) }
                          && tolto.clienti.allSatisfy { $0.luogo == nil } && tolto.impostazioni.territorio.partenza == nil)
        // Il giorno del giro di prova: di sabato è il lunedì
        verifica.vero("Territorio: il giorno del giro di prova di sabato è il lunedì",
                      TerritorioDiProva.giorno(da: AiutiProva.data(2026, 11, 14), orari: OrariLavoro(), calendario: cal)
                          == cal.startOfDay(for: AiutiProva.data(2026, 11, 16)))
    }

    // MARK: Criterio «qualcosa da fare» (decisione 99)

    private static func voce(_ id: String, _ tipo: VoceDaFare.Tipo, _ gruppo: VoceDaFare.Gruppo, _ c: Cliente) -> VoceDaFare {
        VoceDaFare(id: id, tipo: tipo, cliente: c, data: nil, gruppo: gruppo, quando: "", perche: "Prova \(id)", spiegazione: "",
                   canali: [], posizioneId: nil, fatto: .segna, anello: nil, tipoIncontro: .analisi)
    }

    private static func criterio(_ verifica: VerificaCalcoli) {
        let c = cliente("att", "Via 1, Bologna")
        let a = Attenzione(cliente: c, tipo: .rischio, titolo: "Rischio oltre il profilo (prova)", dettaglio: "")
        let d = DatiPrisma(clienti: [c], appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: c.id, impostazioni: Impostazioni())
        let voci = MotoreDaFare.voci(ingressi(d, oggi: AiutiProva.data(2026, 11, 10), attenzioni: [a]))
        verifica.vero("Territorio: un'attenzione non accende l'anello senza tipi «alti»",
                      MotoreTerritorio.daFare(voci, attenzioni: [a], attenzioniAlte: [])["att"] == nil)
        verifica.vero("Territorio: un'attenzione di un tipo «alto» accende l'anello",
                      MotoreTerritorio.daFare(voci, attenzioni: [a], attenzioniAlte: [Attenzione.Tipo.rischio.rawValue])["att"] != nil)
        verifica.vero("Territorio: una voce di conformità (anche più avanti) accende l'anello",
                      MotoreTerritorio.daFare([voce("conf", .conformita, .avanti, c)], attenzioni: [], attenzioniAlte: [])["att"]?.tipo == .conformita)
        verifica.vero("Territorio: una voce più avanti, non di conformità, no",
                      MotoreTerritorio.daFare([voce("occ", .occasione, .avanti, c)], attenzioni: [], attenzioniAlte: [])["att"] == nil)
        let piuUrgente = MotoreTerritorio.daFare([voce("mese", .attivita, .mese, c), voce("oggi", .attivita, .oggi, c)], attenzioni: [], attenzioniAlte: [])
        verifica.vero("Territorio: per cliente vale la voce più urgente", piuUrgente["att"]?.perche == "Prova oggi")
    }

    // MARK: 8. Oggi

    private static func oggi(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        let d = DatiPrisma.demo()
        let l = MotoreTerritorio.luoghi(clienti: d.clienti, tabella: t, zone: [])
        let o = MotoreTerritorio.oggi(clienti: d.clienti, posizioni: d.posizioni, appuntamenti: d.appuntamenti, luoghi: l.luoghi,
                                      senzaLuogo: l.senzaLuogo, daFare: [:], oggi: AiutiProva.data(2026, 11, 10), calendario: cal)
        verifica("Territorio: il totale è la somma delle luci", o.totale, o.luci.reduce(0) { $0 + $1.patrimonio })
        verifica("Territorio: patrimonio della luce di Giulia (in essere, senza debiti)",
                 o.luci.first { $0.id == "giulia" }?.patrimonio ?? -1, 299_050)
        let due = [AiutiProva.posizione("A", .risparmio, 1_000, canale: .alleanza) { $0.clienteId = "x" },
                   AiutiProva.posizione("I", .investimento, 1_000, canale: .indipendente) { $0.clienteId = "x" }]
        verifica.vero("Territorio: posizioni Alleanza e indipendenti → luce «entrambi»",
                      MotoreTerritorio.canale(cliente("x", ""), due) == .entrambi)
        verifica.vero("Territorio: solo Alleanza → luce Alleanza",
                      MotoreTerritorio.canale(cliente("x", ""), [due[0]]) == .alleanza)
        // Clienti tutti in comuni diversi: nessuna zona «più ricca» (mai una zona con un solo cliente)
        let sparsi = [cliente("p", "Via 1, Bologna"), cliente("q", "Via 2, Modena"), cliente("r", "Via 3, Firenze")]
        let ls = MotoreTerritorio.luoghi(clienti: sparsi, tabella: t, zone: [])
        let os = MotoreTerritorio.oggi(clienti: sparsi, posizioni: [], appuntamenti: [], luoghi: ls.luoghi, senzaLuogo: [], daFare: [:],
                                       oggi: AiutiProva.data(2026, 11, 10), calendario: cal)
        verifica.vero("Territorio: nessuna «zona con più patrimonio» con un solo cliente per zona", os.zonaPiuRicca == nil)
        verifica.vero("Territorio: «Dove hai un solo cliente» trova una zona con un cliente", os.zonaUnCliente?.clienti == 1)
        if let z = o.zonaPiuRicca { verifica.vero("Territorio: la zona più ricca ha almeno 2 clienti", z.clienti >= 2) }
    }

    // MARK: 9. Crescita

    private static func luce(_ id: String, inizio: Int, stimato: Bool = false, patrimonio: Double) -> LuceCliente {
        let c = cliente(id, "")
        let l = LuogoCliente(clienteId: id, coordinata: Coordinata(lat: 44.49, lon: 11.34), precisione: .comune, comune: nil, zona: "Prova")
        return LuceCliente(cliente: c, luogo: l, patrimonio: patrimonio, canale: .indipendente, daFare: nil, annoInizio: inizio, annoStimato: stimato)
    }

    private static func crescita(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 11, 10)
        let vecchia = AiutiProva.posizione("V", .risparmio, 5_000) { $0.clienteId = "a"; $0.decorrenza = AiutiProva.data(2015, 3, 1) }
        let nuova = AiutiProva.posizione("N", .risparmio, 5_000) { $0.clienteId = "a"; $0.decorrenza = AiutiProva.data(2018, 3, 1) }
        var c = cliente("a", "")
        verifica("Territorio: anno d'inizio dalla decorrenza più vecchia",
                 Double(MotoreTerritorio.annoInizio(c, posizioni: [nuova, vecchia], appuntamenti: [], calendario: cal).anno), 2015)
        c.clienteDal = AiutiProva.data(2012, 5, 1)
        verifica("Territorio: anno d'inizio da «cliente dal» se è prima",
                 Double(MotoreTerritorio.annoInizio(c, posizioni: [nuova, vecchia], appuntamenti: [], calendario: cal).anno), 2012)
        let soloScheda = MotoreTerritorio.annoInizio(cliente("s", ""), posizioni: [], appuntamenti: [], calendario: cal)
        verifica.vero("Territorio: senza date l'anno viene dalla scheda ed è stimato", soloScheda.anno == 2020 && soloScheda.stimato)
        // Una chiusa con scadenza conta fino a quell'anno
        let chiusa = AiutiProva.posizione("C", .risparmio, 10_000) {
            $0.clienteId = "b"; $0.stato = .chiusa; $0.decorrenza = AiutiProva.data(2016, 1, 10); $0.scadenza = AiutiProva.data(2020, 6, 30)
        }
        let cb = MotoreTerritorio.crescita(luci: [luce("b", inizio: 2016, patrimonio: 0)], posizioni: [chiusa], oggi: oggi, calendario: cal)
        func anno(_ c: CrescitaTerritorio, _ a: Int) -> AnnoCrescita? { c.anni.first { $0.anno == a } }
        verifica("Territorio: la chiusa con scadenza conta prima della scadenza", anno(cb, 2019)?.patrimonio ?? -1, 10_000)
        verifica("Territorio: la chiusa con scadenza non conta dopo", anno(cb, 2021)?.patrimonio ?? -1, 0)
        verifica.vero("Territorio: la crescita va dal primo anno d'inizio all'anno in corso", cb.anni.first?.anno == 2016 && cb.anni.last?.anno == 2026)
        // Una chiusa senza scadenza rende «non disponibile» gli anni dopo la sua decorrenza
        let senzaScadenza = AiutiProva.posizione("S", .risparmio, 10_000) {
            $0.clienteId = "d"; $0.stato = .chiusa; $0.decorrenza = AiutiProva.data(2018, 1, 10)
        }
        let cd = MotoreTerritorio.crescita(luci: [luce("d", inizio: 2016, patrimonio: 0)], posizioni: [senzaScadenza], oggi: oggi, calendario: cal)
        verifica.vero("Territorio: una chiusa senza scadenza rende nil gli anni dopo la decorrenza, non quelli prima",
                      anno(cd, 2017)?.patrimonio == 0 && anno(cd, 2019)?.patrimonio == nil)
        // Una posizione in essere senza storico: anni passati non disponibili; l'anno in corso è il patrimonio di oggi
        let senzaStorico = AiutiProva.posizione("X", .risparmio, 20_000) { $0.clienteId = "e" }
        let ce = MotoreTerritorio.crescita(luci: [luce("e", inizio: 2020, stimato: true, patrimonio: 20_000)], posizioni: [senzaStorico],
                                           oggi: oggi, calendario: cal)
        verifica.vero("Territorio: senza storico il patrimonio degli anni passati non è disponibile",
                      anno(ce, 2022)?.patrimonio == nil && anno(ce, 2026)?.patrimonio == 20_000)
        verifica("Territorio: i clienti con l'anno della scheda si contano", Double(ce.stimati), 1)
        let conStorico = AiutiProva.posizione("Y", .risparmio, 20_000) { $0.clienteId = "f"; $0.decorrenza = AiutiProva.data(2019, 1, 10) }
        let cf = MotoreTerritorio.crescita(luci: [luce("f", inizio: 2019, patrimonio: 20_000)], posizioni: [conStorico], oggi: oggi, calendario: cal)
        let fattori = (1...10).map { 20_000 * pow(0.93, Double($0)) }
        verifica.vero("Territorio: la crescita non usa mai un fattore inventato (0,93 del template)",
                      cf.anni.compactMap(\.patrimonio).allSatisfy { p in !fattori.contains { abs($0 - p) < 0.5 } })
    }

    // MARK: 10. Raggio della luce

    private static func raggio(_ verifica: VerificaCalcoli) {
        typealias L = Tema.Apple.Territorio.Luce
        verifica("Territorio: raggio della luce con 410.000 €", Double(L.raggio(patrimonio: 410_000)), 12.37, tolleranza: 0.05)
        verifica("Territorio: raggio della luce con 40.000 €", Double(L.raggio(patrimonio: 40_000)), 6.61, tolleranza: 0.05)
        verifica("Territorio: raggio massimo 22", Double(L.raggio(patrimonio: 50_000_000)), 22)
    }

    // MARK: 11. Proiezione

    private static func proiezione(_ verifica: VerificaCalcoli) {
        guard var p = ProiezioneMappa.adatta([Coordinata(lat: 44.4, lon: 11.2), Coordinata(lat: 45.5, lon: 12.1)]) else {
            verifica.vero("Territorio: proiezione adattata ai punti", false)
            return
        }
        p.zoom = 2.5
        p.spostamento = CGSize(width: 30, height: -12)
        let misura = CGSize(width: 1100, height: 760)
        let c = Coordinata(lat: 44.9, lon: 11.7)
        let indietro = p.coordinata(p.punto(c, in: misura, margine: 40), in: misura, margine: 40)
        verifica("Territorio: punto e coordinata sono inversi (lat)", indietro.lat, c.lat, tolleranza: 1e-6)
        verifica("Territorio: punto e coordinata sono inversi (lon)", indietro.lon, c.lon, tolleranza: 1e-6)
        let uno = ProiezioneMappa.adatta([Coordinata(lat: 44.49, lon: 11.34)])
        let punto = uno?.punto(Coordinata(lat: 44.49, lon: 11.34), in: misura, margine: 40)
        verifica.vero("Territorio: un solo punto non divide per zero (sta al centro)",
                      punto.map { $0.x.isFinite && $0.y.isFinite && abs($0.x - 550) < 0.01 && abs($0.y - 380) < 0.01 } ?? false)
        verifica.vero("Territorio: nessun punto, nessuna proiezione", ProiezioneMappa.adatta([]) == nil)
        // Il passaggio fra le inquadrature (Oggi ↔ giro): agli estremi le due proiezioni, a metà la media
        if let b = uno {
            verifica.vero("Territorio: passaggio a 0 = la proiezione di prima",
                          ProiezioneMappa.mescola(p, b, 0).minLat == p.minLat && ProiezioneMappa.mescola(p, b, 0).maxLon == p.maxLon)
            verifica.vero("Territorio: passaggio a 1 = la proiezione nuova", ProiezioneMappa.mescola(p, b, 1) == b)
            verifica("Territorio: passaggio a metà strada", ProiezioneMappa.mescola(p, b, 0.5).minLat, (p.minLat + b.minLat) / 2,
                     tolleranza: 1e-9)
            verifica.vero("Territorio: passaggio oltre 1 fermo alla proiezione nuova", ProiezioneMappa.mescola(p, b, 1.7) == b)
        }
    }

    // MARK: 12. Prestazioni

    private static func prestazioni(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        let base = ClientiFittizi.completi()
        var clienti: [Cliente] = []
        var posizioni: [Posizione] = []
        for k in 0..<7 {
            for c in base.clienti {
                var n = Cliente(id: "\(c.id)-\(k)", nome: c.nome, iniziali: c.iniziali, tinta: c.tinta, tema: "", email: "", telefono: "",
                                preferito: false, nota: "", creatoIl: c.creatoIl)
                n.indirizzo = c.indirizzo
                clienti.append(n)
                if clienti.count >= 200 { break }
            }
            if clienti.count >= 200 { break }
        }
        let ids = Set(clienti.map(\.id))
        for k in 0..<7 {
            for p in base.posizioni {
                var q = p
                q.id = "\(p.id)-\(k)"
                q.clienteId = "\(p.clienteId)-\(k)"
                if ids.contains(q.clienteId) { posizioni.append(q) }
            }
        }
        let inizio = Date()
        let l = MotoreTerritorio.luoghi(clienti: clienti, tabella: t, zone: [])
        let o = MotoreTerritorio.oggi(clienti: clienti, posizioni: posizioni, appuntamenti: base.appuntamenti, luoghi: l.luoghi,
                                      senzaLuogo: l.senzaLuogo, daFare: [:], oggi: AiutiProva.data(2026, 11, 10), calendario: cal)
        _ = MotoreTerritorio.crescita(luci: o.luci, posizioni: posizioni, oggi: AiutiProva.data(2026, 11, 10), calendario: cal)
        _ = MotoreTerritorio.giro(giorno: AiutiProva.data(2026, 11, 10), appuntamenti: base.appuntamenti, clienti: clienti, luoghi: l.luoghi,
                                  partenza: nil, daFare: [:], impostazioni: ImpostazioniTerritorio(), orari: OrariLavoro(), calendario: cal)
        let durata = Date().timeIntervalSince(inizio)
        verifica.vero("Territorio: 200 clienti (luoghi, Oggi, crescita, giro) in meno di 2 s", clienti.count == 200 && durata < 2)
        verifica.vero("Territorio: i 200 clienti di prova sono tutti sulla mappa", l.senzaLuogo.isEmpty && o.luci.count == 200)
    }

    // MARK: 13. Voci di MotoreDaFare

    private static func vociDaFare(_ verifica: VerificaCalcoli) {
        let d = DatiPrisma.demo()
        let x = ingressi(d, oggi: AiutiProva.data(2026, 11, 10))
        verifica.vero("Territorio: il nastro delle voci complete è il nastro di sempre", MotoreDaFare.nastro(MotoreDaFare.voci(x)) == MotoreDaFare.calcola(x))
    }

    // MARK: 14. Partenza

    private static func partenza(_ verifica: VerificaCalcoli, _ t: TabellaComuni) {
        var imp = Impostazioni()
        verifica.vero("Territorio: senza nulla, nessuna partenza", MotoreTerritorio.partenza(impostazioni: imp, tabella: t) == nil)
        imp.studio.spese.partenza = "Studio di via Roma, Modena"
        verifica.vero("Territorio: la partenza di Studio › Spese (testo) vale per ultima",
                      MotoreTerritorio.partenza(impostazioni: imp, tabella: t) == t.perCodice["MO-modena"]?.centro)
        imp.studio.fatturazione.sede.comune = "Firenze"
        verifica.vero("Territorio: la sede dello studio vince sul testo di Studio › Spese",
                      MotoreTerritorio.partenza(impostazioni: imp, tabella: t) == t.perCodice["FI-firenze"]?.centro)
        imp.territorio.comunePartenza = "BO-bologna"
        verifica.vero("Territorio: il comune scelto vince sulla sede",
                      MotoreTerritorio.partenza(impostazioni: imp, tabella: t) == t.perCodice["BO-bologna"]?.centro)
        let aMano = Coordinata(lat: 44.5, lon: 11.3)
        imp.territorio.partenza = LuogoManuale(coordinata: aMano)
        verifica.vero("Territorio: la partenza a mano vince su tutto", MotoreTerritorio.partenza(impostazioni: imp, tabella: t) == aMano)
    }
}
