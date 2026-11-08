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
        let tutti = MotoreTraguardi.calcola(dati: dati.istantanea, oggi: oggi)
        guard let solo = modoCliente else { return tutti }
        return tutti.filter { $0.clienteId == solo }
    }

    /// Il traguardo con quell'id (nil se non c'è più o è uscito dalla finestra).
    func traguardo(_ id: String, oggi: Date = Date()) -> Traguardo? {
        MotoreTraguardi.calcola(dati: dati.istantanea, oggi: oggi).first { $0.id == id }
    }

    /// Scrive `raggiuntoIl` (oggi) sugli obiettivi raggiunti che non ce l'hanno ancora. Mai nelle istantanee, nelle prove
    /// o in sola lettura. La chiamano lo sblocco e l'apertura di Messaggi.
    func segnaObiettiviRaggiunti(oggi: Date = Date()) {
        guard persistente, !solaLettura else { return }
        let ids = Set(MotoreTraguardi.daSegnareRaggiunti(dati: dati.istantanea))
        guard !ids.isEmpty else { return }
        let giorno = Posizione.oggiArrotondato
        for i in dati.obiettivi.indices where ids.contains(dati.obiettivi[i].id) {
            dati.obiettivi[i].raggiuntoIl = giorno
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
