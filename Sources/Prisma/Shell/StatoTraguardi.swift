import Foundation

// I traguardi festeggiati nello stato (versione «Luce», giro 5, Design/template-luce-specifica.md §5.4.4): la data di
// raggiungimento degli obiettivi (scritta la prima volta che il calcolo li trova raggiunti), l'apertura di Messaggi sul
// traguardo, la telefonata in Agenda, l'idea per il regalo nelle note del cliente, «festeggiato» e «non è un
// traguardo». Il biglietto si vede ma non si condivide ancora (arriva con il giro 15): niente esce dal Mac.

extension StatoShell {
    /// La durata della telefonata messa in Agenda (minuti).
    static let durataTelefonataTraguardo = 15

    /// I traguardi degli ultimi 7 giorni dei clienti visibili (in modalità cliente solo i suoi).
    func traguardi(oggi: Date = Date()) -> [Traguardo] {
        let tutti = traguardiDellArchivio(oggi: oggi)
        guard let solo = modoCliente else { return tutti }
        return tutti.filter { $0.clienteId == solo }
    }

    /// I traguardi del cliente ancora da festeggiare (né festeggiati né scartati), per la riga del dossier (§5.4.4).
    func traguardiDaFesteggiare(cliente id: String, oggi: Date = Date()) -> [Traguardo] {
        traguardi(oggi: oggi).filter { $0.clienteId == id && $0.festeggiatoIl == nil }
    }

    /// Il traguardo con quell'id (nil se non c'è più o è uscito dalla finestra).
    func traguardo(_ id: String, oggi: Date = Date()) -> Traguardo? {
        traguardiDellArchivio(oggi: oggi).first { $0.id == id }
    }

    /// MotoreTraguardi su tutto l'archivio: per oggi una volta per dati dei calcoli, giorno, modalità cliente e ora (come
    /// gli altri dati ricavati), perché lo chiedono a ogni passaggio il pannello del traguardo in Messaggi, il centro
    /// notifiche e il menu delle voci; per un altro giorno calcolato ogni volta, come la conformità. Note (l'idea per il
    /// regalo) e capsule (la capsula dell'obiettivo) non sono dati dei calcoli: la versione delle note e l'impronta delle
    /// capsule stanno nella chiave, lette fuori dal calcolo, così chi chiede i traguardi si aggiorna anche con loro.
    private func traguardiDellArchivio(oggi: Date) -> [Traguardo] {
        guard Calendar.current.isDateInToday(oggi) else {
            return MotoreTraguardi.calcola(dati: datiTraguardi(), oggi: oggi)
        }
        let chiave = "traguardi|\(DerivatiDati.ora(oggi))|\(versioneNote)|\(improntaCapsuleTraguardi())"
        return ricavato(chiave) { () -> [Traguardo] in
            MotoreTraguardi.calcola(dati: datiTraguardi(), oggi: oggi)
        }
    }

    /// Tutto ciò che `MotoreCapsule.perObiettivo` guarda per scegliere la capsula di un traguardo: id, obiettivo e stato
    /// delle capsule legate a un obiettivo, nell'ordine dell'archivio (vale la prima sigillata). Le capsule sono un campo
    /// neutro, senza versione: leggerle qui iscrive chi chiede i traguardi, come quando le leggeva il calcolo.
    private func improntaCapsuleTraguardi() -> Int {
        var impronta = Hasher()
        for c in dati.capsule {
            guard case .obiettivo(let obiettivo) = c.apertura else { continue }
            impronta.combine(c.id)
            impronta.combine(obiettivo)
            impronta.combine(c.stato)
        }
        return impronta.finalize()
    }

    /// L'archivio per MotoreTraguardi: i dati dei calcoli (senza iscriversi a tutto l'archivio) più le note (l'idea per
    /// il regalo) e le impostazioni (le regole dei traguardi), lette vive.
    private func datiTraguardi() -> DatiPrisma {
        var d = datiDeiCalcoli()
        d.note = dati.note
        d.impostazioni = dati.impostazioni
        // «Luce» giro 15: le capsule del tempo, lette vive (la capsula legata all'obiettivo raggiunto)
        d.capsule = dati.capsule
        return d
    }

    /// Scrive `raggiuntoIl` (oggi) sugli obiettivi raggiunti che non ce l'hanno ancora. Mai nelle istantanee, nelle prove
    /// o in sola lettura. La chiamano lo sblocco e l'apertura di Messaggi.
    func segnaObiettiviRaggiunti(oggi: Date = Date()) {
        guard persistente, !solaLettura else { return }
        let ids = Set(obiettiviDaSegnareRaggiunti())
        guard !ids.isEmpty else { return }
        let giorno = Posizione.oggiArrotondato
        for i in dati.obiettivi.indices where ids.contains(dati.obiettivi[i].id) {
            dati.obiettivi[i].raggiuntoIl = giorno
        }
    }

    /// Gli stessi obiettivi di `MotoreTraguardi.daSegnareRaggiunti` (senza data, importo > 0, accantonato ≥ importo), senza
    /// costruire `AvanzamentoObiettivo`: per l'accantonato basta sommare le posizioni collegate in essere, mentre il versamento
    /// necessario (decine di proiezioni mese per mese per ogni obiettivo) qui non serve e cadeva sullo sblocco e
    /// sull'apertura di Messaggi. Le posizioni si sommano nell'ordine dell'archivio, come `AvanzamentoObiettivo`.
    private func obiettiviDaSegnareRaggiunti() -> [String] {
        let candidati = dati.obiettivi.filter { $0.raggiuntoIl == nil && $0.importo > 0 }
        guard !candidati.isEmpty else { return [] }
        let posizioni = dati.posizioni
        // Il posto nell'archivio delle posizioni in essere, per id (con due posizioni con lo stesso id contano tutte e due)
        var inEssere: [String: [Int]] = [:]
        for (i, p) in posizioni.enumerated() where p.stato == .inEssere { inEssere[p.id, default: []].append(i) }
        return candidati.compactMap { o -> String? in
            let posti = Set(o.posizioniCollegate).flatMap { inEssere[$0] ?? [] }.sorted()
            let collegate = posti.reduce(0.0) { somma, i in somma + posizioni[i].valore }
            return o.accantonato + collegate >= o.importo ? o.id : nil
        }
    }

    /// Apre Messaggi sul traguardo (dalla storia, dalla voce Novità): senza id, sul primo da festeggiare.
    func apriTraguardo(_ traguardoId: String?, clienteId: String?) {
        if let t = traguardoId, let c = clienteId {
            preparaMessaggio(clienteId: c, occasioneId: OccasioneMessaggio.id(tipo: .traguardo, clienteId: c, riferimento: t))
        } else {
            preparaMessaggio(occasioneId: occasioniMessaggi().festeggiare.first?.id)
        }
    }

    // MARK: Telefonata

    /// La telefonata del traguardo già in Agenda (nil se non c'è).
    func telefonataTraguardo(_ t: Traguardo) -> Appuntamento? {
        dati.appuntamenti.first { $0.id == Self.idTelefonata(t) }
    }

    static func idTelefonata(_ t: Traguardo) -> String { "telefonata-" + t.id }

    /// «Aggiungi»: una telefonata con il cliente nel primo spazio libero da domani negli orari di lavoro (se domani è
    /// pieno, il primo giorno utile), con il titolo «Telefonata: …». Segna il traguardo come festeggiato. Restituisce
    /// l'appuntamento (nil in sola lettura o senza spazio).
    @discardableResult
    func aggiungiTelefonataTraguardo(_ t: Traguardo, oggi: Date = Date()) -> Appuntamento? {
        guard !solaLettura else { return nil }
        if let gia = telefonataTraguardo(t) { return gia }
        let cal = Calendar.current
        let domani = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: oggi)) ?? oggi
        guard let spazio = MotorePianificazione.primoSpazio(durata: Self.durataTelefonataTraguardo, da: domani,
                                                           appuntamenti: dati.appuntamenti, orari: dati.impostazioni.orari)
        else { return nil }
        let a = Appuntamento(id: Self.idTelefonata(t), clienteId: t.clienteId, titolo: "Telefonata: " + t.titolo,
                             inizio: spazio.inizio, durataMinuti: Self.durataTelefonataTraguardo, luogo: "", note: t.perche,
                             stato: .pianificato, tipo: .telefonata)
        dati.appuntamenti.append(a)
        segnaFesteggiato(t)
        return a
    }

    /// Il secondo clic su «✓ In agenda»: l'Agenda sul giorno della telefonata, con l'appuntamento scelto.
    func apriTelefonataTraguardo(_ t: Traguardo) {
        guard let a = telefonataTraguardo(t) else { return }
        giornoAgenda = Calendar.current.startOfDay(for: a.inizio)
        appuntamentoSelezionato = a.id
        apri(.agenda)
    }

    // MARK: Idea per il regalo

    static func idNotaRegalo(_ t: Traguardo) -> String { "nota-regalo-" + t.id }

    /// La nota «Idea per un regalo» del traguardo, se c'è già.
    func notaRegaloTraguardo(_ t: Traguardo) -> Nota? {
        dati.note.first { $0.id == Self.idNotaRegalo(t) }
    }

    /// «Annota»: salva l'idea in una nota del cliente «Idea per un regalo» (con il traguardo sotto). Un testo vuoto non
    /// si salva.
    @discardableResult
    func annotaRegaloTraguardo(_ t: Traguardo, testo: String) -> Bool {
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !solaLettura, !pulito.isEmpty, notaRegaloTraguardo(t) == nil,
              dati.clienti.contains(where: { $0.id == t.clienteId }) else { return false }
        var n = Nota(clienteId: t.clienteId, titolo: "Idea per un regalo", testo: pulito + "\n\nPer il traguardo: " + t.titolo + ".")
        n.id = Self.idNotaRegalo(t)
        dati.note.append(n)
        return true
    }

    // MARK: Festeggiato e scartato

    /// Segna il traguardo come festeggiato: resta nella lista con la spunta fino a domani, poi esce.
    func segnaFesteggiato(_ t: Traguardo) {
        guard !solaLettura, dati.impostazioni.traguardi.festeggiati[t.id] == nil else { return }
        dati.impostazioni.traguardi.festeggiati[t.id] = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
    }

    /// «Non è un traguardo»: non torna più (per esempio un anniversario in un momento difficile).
    func scartaTraguardo(_ t: Traguardo) {
        guard !solaLettura, !dati.impostazioni.traguardi.scartati.contains(t.id) else { return }
        dati.impostazioni.traguardi.scartati.append(t.id)
    }
}
