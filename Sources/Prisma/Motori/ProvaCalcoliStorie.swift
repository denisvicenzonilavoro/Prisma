import Foundation

/// Prove di «La tua settimana, il tuo anno» (Design/template-luce-specifica.md §5.2.5 punto 5.2, «Luce» giro 5): pagine
/// assenti con i dati vuoti (restano la prima e l'ultima), la settimana da lunedì a domenica anche a cavallo di mese e
/// d'anno, «il più importante» = la firma, le telefonate escluse, «in arrivo» per giorno con la somma uguale al totale e
/// la nota senza aliquote, le famiglie protette contate una volta per cliente, la variazione nil al primo anno, i clienti
/// nuovi dell'anno, la frase del momento senza cifre inventate, nessun paragone dei chilometri senza la tabella.
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliStorie {
    static func esegui(_ verifica: VerificaCalcoli) {
        vuote(verifica)
        settimane(verifica)
        incontri(verifica)
        inArrivo(verifica)
        anno(verifica)
        momento(verifica)
    }

    private static let cal = Calendar(identifier: .gregorian)
    private static func d(_ a: Int, _ m: Int, _ g: Int, ora: Int = 12) -> Date {
        cal.date(from: DateComponents(year: a, month: m, day: g, hour: ora)) ?? Date()
    }
    /// Oggi delle prove: mercoledì 4 novembre 2026.
    private static let oggi = d(2026, 11, 4)

    private static func cliente(_ id: String, _ nome: String, creato: Date = d(2024, 5, 10)) -> Cliente {
        Cliente(id: id, nome: nome, iniziali: String(nome.prefix(2)).uppercased(), tinta: .blu, tema: "", email: "",
                telefono: "", preferito: false, nota: "", creatoIl: creato)
    }

    private static func archivio(_ clienti: [Cliente], _ modifica: (inout DatiPrisma) -> Void = { _ in }) -> DatiPrisma {
        var dati = DatiPrisma(clienti: clienti, appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: clienti.first?.id ?? "",
                              impostazioni: Impostazioni())
        modifica(&dati)
        return dati
    }

    private static func nomi(_ p: [PaginaStoria]) -> [String] { p.map(\.nome) }

    // MARK: Vuote

    private static func vuote(_ verifica: VerificaCalcoli) {
        let vuoto = archivio([])
        let s = MotoreStorie.settimana(dati: vuoto, oggi: oggi, cal: cal)
        verifica.vero("Storie: settimana vuota = saluto e «settimana tranquilla»",
                      nomi(s) == ["saluto", "finaleSettimana"] && s.last == .finaleSettimana(tranquilla: true))
        let a = MotoreStorie.anno(dati: vuoto, anno: 2026, oggi: oggi, cal: cal)
        verifica.vero("Storie: anno vuoto = titolo e grazie (niente «0 famiglie»)", nomi(a) == ["annoTitolo", "grazie"])
        verifica.vero("Storie: il saluto usa il nome del profilo",
                      s.first == .saluto(nome: "Denis", periodo: MotoreStorie.settimanaDi(oggi, cal: cal)))
        verifica.vero("Storie: «Buongiorno.» senza nome", TestiStorie.buongiorno("") == "Buongiorno.")
        verifica.vero("Storie: nessun paragone dei chilometri senza la tabella approvata (decisione 72)",
                      TestiStorie.paragoniKm.isEmpty && !a.contains { $0.nome == "chilometri" })
    }

    // MARK: Settimane

    private static func settimane(_ verifica: VerificaCalcoli) {
        let s1 = MotoreStorie.settimanaDi(d(2026, 11, 8), cal: cal)   // domenica
        verifica.vero("Storie: la domenica 8 novembre è nella settimana del lunedì 2",
                      s1.start == cal.startOfDay(for: d(2026, 11, 2)) && s1.end == cal.startOfDay(for: d(2026, 11, 9)))
        verifica.vero("Storie: «2 – 8 novembre»", TestiStorie.periodo(s1, cal: cal) == "2 – 8 novembre")
        let s2 = MotoreStorie.settimanaDi(d(2026, 12, 2), cal: cal)
        verifica.vero("Storie: a cavallo di mese «30 novembre – 6 dicembre»", TestiStorie.periodo(s2, cal: cal) == "30 novembre – 6 dicembre")
        let s3 = MotoreStorie.settimanaDi(d(2027, 1, 1), cal: cal)    // venerdì
        verifica.vero("Storie: a cavallo d'anno dal lunedì 28 dicembre 2026 al 3 gennaio 2027",
                      s3.start == cal.startOfDay(for: d(2026, 12, 28)) && s3.end == cal.startOfDay(for: d(2027, 1, 4)))
        let s4 = MotoreStorie.settimanaDi(d(2026, 11, 2), cal: cal)   // lunedì
        verifica.vero("Storie: il lunedì è l'inizio della sua settimana", s4.start == cal.startOfDay(for: d(2026, 11, 2)))
    }

    // MARK: Incontri

    private static func incontri(_ verifica: VerificaCalcoli) {
        func a(_ id: String, _ c: String, _ giorno: Int, _ ora: Int, _ tipo: TipoAppuntamento) -> Appuntamento {
            Appuntamento(id: id, clienteId: c, titolo: "Incontro \(id)", inizio: d(2026, 11, giorno, ora: ora), durataMinuti: 60,
                         luogo: "", note: "", stato: .pianificato, tipo: tipo)
        }
        let dati = archivio([cliente("giulia", "Giulia Rossi"), cliente("marco", "Marco Bianchi")]) {
            $0.appuntamenti = [a("1", "marco", 2, 9, .analisi), a("2", "giulia", 3, 10, .proposta), a("3", "giulia", 5, 16, .firma),
                               a("4", "marco", 6, 11, .telefonata),
                               // Fuori dalla settimana (lunedì dopo) e di un cliente che non c'è
                               a("5", "marco", 9, 9, .firma), a("6", "nessuno", 4, 9, .firma)]
        }
        let p = MotoreStorie.settimana(dati: dati, oggi: oggi, cal: cal)
        guard case .incontri(let n, let clienti, let principale)? = p.first(where: { $0.nome == "incontri" }) else {
            verifica.vero("Storie: la pagina degli incontri c'è", false)
            return
        }
        verifica("Storie: 3 incontri (telefonata, settimana dopo e cliente assente esclusi)", Double(n), 3)
        verifica.vero("Storie: gli avatar una volta per cliente, in ordine", clienti == ["marco", "giulia"])
        verifica.vero("Storie: il più importante è la firma («\(principale ?? "")»)",
                      principale?.hasPrefix("Il più importante: giovedì alle 16:00, la firma di Giulia") ?? false)
    }

    // MARK: In arrivo

    private static func inArrivo(_ verifica: VerificaCalcoli) {
        func parcella(_ id: String, _ importo: Double, scadenza: Date) -> Parcella {
            var p = Parcella(id: id, clienteId: "laura", data: d(2026, 10, 20),
                             righe: [RigaParcella(id: "r", descrizione: "Consulenza", importo: importo)], cal: cal)
            p.stato = .emessa
            p.scadenza = scadenza
            return p
        }
        // Un'Alleanza con la rata nella settimana, senza aliquote: la pagina conta solo le parcelle e lo dice
        var polizza = Posizione(clienteId: "laura", canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Polizza")
        polizza.decorrenza = d(2024, 11, 3)
        polizza.premio = 600
        polizza.frequenza = .annuale
        let dati = archivio([cliente("laura", "Laura Moretti")]) {
            $0.parcelle = [parcella("p1", 500, scadenza: d(2026, 11, 3)), parcella("p2", 750, scadenza: d(2026, 11, 5)),
                           parcella("p3", 900, scadenza: d(2026, 11, 12))]
            $0.posizioni = [polizza]
        }
        let p = MotoreStorie.settimana(dati: dati, oggi: oggi, cal: cal)
        guard case .inArrivo(let totale, let giorni, let didascalia, let parziale)? = p.first(where: { $0.nome == "inArrivo" }) else {
            verifica.vero("Storie: la pagina «In arrivo» c'è", false)
            return
        }
        verifica("Storie: in arrivo = le due parcelle della settimana", totale, 1_250)
        verifica("Storie: la somma dei giorni è il totale", giorni.reduce(0) { $0 + $1.importo }, totale)
        verifica("Storie: cinque colonne (lunedì-venerdì)", Double(giorni.count), 5)
        verifica("Storie: martedì 500 €", giorni[1].importo, 500)
        verifica.vero("Storie: senza aliquote lo dice («\(didascalia)»)",
                      parziale && didascalia == "Due parcelle · solo parcelle: mancano le aliquote")

        // Con le aliquote la rata entra (ricorrenti sulla rata dal secondo anno: 600 × 5% = 30 € il 3 novembre)
        var conAliquote = dati
        conAliquote.impostazioni.studio.aliquote[.protezione] = AliquoteProvvigione(nuovaProduzione: 10, ricorrenti: nil, rinnovi: 5)
        if case .inArrivo(let t, let g, let dida, let parz)? = MotoreStorie.settimana(dati: conAliquote, oggi: oggi, cal: cal)
            .first(where: { $0.nome == "inArrivo" }) {
            verifica("Storie: con le aliquote entra la provvigione della rata", t, 1_280)
            verifica("Storie: con le aliquote la somma dei giorni è il totale", g.reduce(0) { $0 + $1.importo }, t)
            verifica.vero("Storie: didascalia «Rinnovi Alleanza e due parcelle» («\(dida)»)",
                          !parz && dida == "Rinnovi Alleanza e due parcelle")
        } else {
            verifica.vero("Storie: con le aliquote la pagina «In arrivo» c'è", false)
        }
        // Una parcella di sabato aggiunge la colonna del sabato
        var sabato = dati
        sabato.parcelle.append(parcella("p4", 100, scadenza: d(2026, 11, 7)))
        if case .inArrivo(_, let g, _, _)? = MotoreStorie.settimana(dati: sabato, oggi: oggi, cal: cal).first(where: { $0.nome == "inArrivo" }) {
            verifica("Storie: il sabato con un importo ha la sua colonna", Double(g.count), 6)
        }
    }

    // MARK: Anno

    private static func anno(_ verifica: VerificaCalcoli) {
        func protezione(_ c: String, capitale: Double?, decorrenza: Date) -> Posizione {
            var p = Posizione(clienteId: c, canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Protezione \(c)")
            p.decorrenza = decorrenza
            p.capitaleAssicurato = capitale
            return p
        }
        let dati = archivio([cliente("anna", "Anna Neri", creato: d(2026, 2, 1)), cliente("bruno", "Bruno Gialli", creato: d(2026, 6, 1)),
                             cliente("carla", "Carla Blu", creato: d(2025, 6, 1))]) {
            var investimento = Posizione(clienteId: "carla", canale: .indipendente, stato: .inEssere, area: .investimento, nome: "Fondo")
            investimento.controvalore = 30_000
            investimento.decorrenza = d(2026, 3, 1)
            investimento.versamentoIniziale = 25_000
            $0.posizioni = [protezione("anna", capitale: 100_000, decorrenza: d(2026, 3, 1)),
                            protezione("anna", capitale: 50_000, decorrenza: d(2026, 4, 1)),
                            protezione("bruno", capitale: nil, decorrenza: d(2026, 5, 1)),
                            // Dell'anno scorso: non conta
                            protezione("carla", capitale: 70_000, decorrenza: d(2025, 5, 1)),
                            investimento]
        }
        let p = MotoreStorie.anno(dati: dati, anno: 2026, oggi: oggi, cal: cal)
        if case .protette(let f, let capitale)? = p.first(where: { $0.nome == "protette" }) {
            verifica("Storie: famiglie protette contate una volta per cliente", Double(f), 2)
            verifica("Storie: capitale = i capitali scritti dell'anno", capitale ?? 0, 150_000)
        } else {
            verifica.vero("Storie: la pagina delle famiglie protette c'è", false)
        }
        if case .nuoviClienti(let n, let passaparola)? = p.first(where: { $0.nome == "nuoviClienti" }) {
            verifica("Storie: clienti nuovi dell'anno", Double(n), 2)
            verifica.vero("Storie: senza il dato del passaparola nessuna riga", passaparola == nil)
        } else {
            verifica.vero("Storie: la pagina dei clienti nuovi c'è", false)
        }
        // Con due presentatori («Luce» giro 12): Bruno (dell'anno) presentato da Carla, Carla presentata da Anna
        var conPassaparola = dati
        if let b = conPassaparola.clienti.firstIndex(where: { $0.id == "bruno" }),
           let c = conPassaparola.clienti.firstIndex(where: { $0.id == "carla" }) {
            conPassaparola.clienti[b].presentatoDa = "carla"
            conPassaparola.clienti[c].presentatoDa = "anna"
        }
        if case .nuoviClienti(_, let passaparola)? = MotoreStorie.anno(dati: conPassaparola, anno: 2026, oggi: oggi, cal: cal)
            .first(where: { $0.nome == "nuoviClienti" }) {
            verifica("Storie: dal passaparola solo i clienti nuovi dell'anno con «Presentato da»", Double(passaparola ?? -1), 1)
        } else {
            verifica.vero("Storie: la pagina dei clienti nuovi c'è (con il passaparola)", false)
        }
        if case .patrimonio(let valore, _, let variazione)? = p.first(where: { $0.nome == "patrimonio" }) {
            verifica("Storie: il patrimonio seguito è il valore di oggi", valore, 30_000)
            verifica.vero("Storie: al primo anno (niente prima del 1° gennaio) nessuna variazione", variazione == nil)
        } else {
            verifica.vero("Storie: la pagina del patrimonio c'è", false)
        }
        verifica.vero("Storie: «+18% da inizio anno» e «Stabile»",
                      TestiStorie.variazione(0.18) == "+18% da inizio anno" && TestiStorie.variazione(0.001) == "Stabile da inizio anno")
        verifica.vero("Storie: il titolo dell'anno usa nome e cognome delle fatture se ci sono", {
            var i = Impostazioni()
            i.studio.fatturazione.nome = "Denis"
            i.studio.fatturazione.cognome = "Vicenzoni"
            return MotoreStorie.consulente(i) == "Denis Vicenzoni" && MotoreStorie.consulente(Impostazioni()) == "Denis"
        }())
    }

    // MARK: Il momento dell'anno

    private static func momento(_ verifica: VerificaCalcoli) {
        var studi = Obiettivo(clienteId: "marco", titolo: "Studi di Tommaso", area: .famiglia, importo: 40_000, scadenza: d(2027, 9, 1))
        studi.id = "ob-studi"
        studi.accantonato = 40_000
        studi.raggiuntoIl = d(2026, 3, 14)
        var piccolo = Obiettivo(clienteId: "marco", titolo: "Vacanza", area: .patrimonio, importo: 3_000, scadenza: d(2027, 9, 1))
        piccolo.id = "ob-vacanza"
        piccolo.accantonato = 3_000
        piccolo.raggiuntoIl = d(2026, 9, 1)
        let dati = archivio([cliente("marco", "Marco Bianchi", creato: d(2023, 1, 20))]) { $0.obiettivi = [studi, piccolo] }
        let p = MotoreStorie.anno(dati: dati, anno: 2026, oggi: oggi, cal: cal)
        guard case .momento(_, let frase, let c)? = p.first(where: { $0.nome == "momento" }) else {
            verifica.vero("Storie: la pagina del momento dell'anno c'è", false)
            return
        }
        verifica.vero("Storie: il momento è l'obiettivo più grande («\(frase)»)",
                      frase == "Il 14 marzo Marco ha raggiunto «Studi di Tommaso»." && c == "marco")
        let cifre = Set(frase.split(whereSeparator: { !$0.isNumber }).map(String.init))
        verifica.vero("Storie: la frase del momento non ha cifre inventate (solo il giorno)", cifre == ["14"])
        verifica.vero("Storie: «L’8 marzo» con l'apostrofo", TestiTraguardi.ilGiorno(d(2026, 3, 8)) == "L’8 marzo")
    }
}
