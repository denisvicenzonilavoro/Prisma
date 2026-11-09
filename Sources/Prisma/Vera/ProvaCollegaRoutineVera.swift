import Foundation

/// «Le routine» collegate (CollegaRoutineShell.swift): la frase in chat lancia la routine, niente cambia prima di
/// «Conferma», il lancio è registrato; «Dopo la firma» segna in essere la proposta con «Conferma» e «Annulla» la rimette.
enum ProvaCollegaRoutineVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = false
        let prima = s.dati.istantanea
        controlla(s.smistaVera("Vera, prepara l'incontro con Marco", chiave: "marco"), "Routine in chat: «prepara l'incontro con Marco» è gestita")
        let m = s.conversazione("marco").last
        controlla(m?.esitoRoutine?.routineId == RoutineVera.idPrepara && m?.esitoRoutine?.passi.count == 5, "Routine in chat: i cinque passi di «Prepara l'incontro»")
        controlla(s.dati.appuntamenti == prima.appuntamenti && s.dati.messaggi == prima.messaggi, "Routine in chat: niente cambia prima di «Conferma»")
        controlla(s.routineVera(RoutineVera.idPrepara)?.usata == 1, "Routine in chat: il lancio è registrato")
        _ = s.smistaVera("fissa un incontro con Marco a fine mese", chiave: "marco")
        controlla(s.conversazione("marco").last?.esitoRoutine == nil, "Routine in chat: «fissa… a fine mese» resta un comando")
        guard let aperta = s.dati.posizioni.first(where: { $0.stato == .proposta && $0.esito != .rifiutata }), let c = s.cliente(aperta.clienteId),
              let p = RoutineVera.posizioneFirmata(cliente: c, posizioneId: nil, posizioni: s.dati.posizioni) else { return }
        s.clienteAttivoId = c.id
        _ = s.smistaVera("Vera, ho firmato con \(c.nome)", chiave: c.id)
        guard let firma = s.conversazione(c.id).last, firma.conferma?.azioni.contains(where: { $0.strumento == RoutineVera.strumentoPosizioneFirmata }) == true else {
            return controlla(false, "Routine in chat: «Dopo la firma» propone di segnare in essere la proposta")
        }
        s.confermaSchedaVera(messaggio: firma.id)
        let firmata = s.dati.posizioni.first { $0.id == p.id }
        s.annullaSchedaVera(messaggio: firma.id)
        controlla(firmata?.stato == .inEssere && firmata?.esito == .accettata && s.dati.posizioni.first { $0.id == p.id }?.stato == .proposta,
                  "Routine in chat: «Conferma» segna in essere la proposta firmata e «Annulla» la rimette com'era")
        revisione(controlla)
    }

    /// Le correzioni della revisione: il seguito della proposta, «Annulla» dopo una correzione, la risposta a «Per quale
    /// cliente?» che è un comando, la modalità cliente.
    private static func revisione(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        guard let aperta = s.dati.posizioni.first(where: { $0.stato == .proposta && $0.esito != .rifiutata }), let c = s.cliente(aperta.clienteId) else {
            return controlla(false, "Routine, revisione: nei dati di prova manca una proposta aperta")
        }
        s.clienteAttivoId = c.id
        s.veraPortafoglio = false
        _ = s.smistaVera("Vera, ho firmato con \(c.nome)", chiave: c.id)
        guard let firma = s.conversazione(c.id).last, let az = firma.conferma?.azioni.first(where: { $0.strumento == RoutineVera.strumentoPosizioneFirmata }),
              let pid = az.argomenti["posizione"] else {
            return controlla(false, "Routine, revisione: «Dopo la firma» propone di segnare in essere la proposta")
        }
        s.confermaSchedaVera(messaggio: firma.id)
        let dopo = s.dati.posizioni.first { $0.id == pid }
        controlla(dopo?.stato == .inEssere && (dopo?.seguito == nil || dopo?.seguito?.esitoIl != nil),
                  "Routine, revisione: «segna in essere» scrive l'esito del seguito della proposta")
        // Una correzione del premio dopo la firma resta anche con «Annulla»
        if let i = s.dati.posizioni.firstIndex(where: { $0.id == pid }) {
            var p = s.dati.posizioni[i]
            p.premio += 17
            s.dati.posizioni[i] = p
        }
        let corretto = s.dati.posizioni.first { $0.id == pid }?.premio
        s.annullaSchedaVera(messaggio: firma.id)
        let tornata = s.dati.posizioni.first { $0.id == pid }
        controlla(tornata?.stato == .proposta && tornata?.premio == corretto,
                  "Routine, revisione: «Annulla» rimette la proposta ma lascia il premio corretto dopo")

        // «Per quale cliente?» e poi un comando: il comando non rilancia la routine
        let t = StatoShell(persistente: false)
        t.rispostePreparate = true
        t.veraPortafoglio = true
        _ = t.smistaVera("Vera, prepara l'incontro", chiave: VeraPortafoglio.chiave)
        let domanda = t.conversazione(VeraPortafoglio.chiave).last?.esitoRoutine?.domanda
        let usataPrima = t.routineVera(RoutineVera.idPrepara)?.usata ?? 0
        _ = t.smistaVera("fissa un incontro con Marco giovedì alle 15", chiave: VeraPortafoglio.chiave)
        let rilanciata = t.conversazione(VeraPortafoglio.chiave).contains { $0.esitoRoutine?.routineId == RoutineVera.idPrepara && $0.esitoRoutine?.clienteId == "marco" }
        controlla(domanda != nil && !rilanciata && (t.routineVera(RoutineVera.idPrepara)?.usata ?? 0) == usataPrima,
                  "Routine, revisione: dopo «Per quale cliente?» un comando con un nome non rilancia la routine")

        // Modalità cliente: una routine con l'agenda di tutti non parte
        let u = StatoShell(persistente: false)
        u.rispostePreparate = true
        u.clienteAttivoId = "marco"
        u.veraPortafoglio = false
        u.modoCliente = "marco"
        let lunedi = u.routineVera(RoutineVera.idLunedi)?.usata ?? 0
        _ = u.smistaVera("Vera, com'è la settimana?", chiave: "marco")
        let lanciata = u.conversazione("marco").contains { ($0.esitoRoutine?.passi.isEmpty == false) }
        controlla(!lanciata && (u.routineVera(RoutineVera.idLunedi)?.usata ?? 0) == lunedi,
                  "Routine, revisione: in modalità cliente «Il mio lunedì» (agenda di tutti) non parte")
        u.modoCliente = nil
    }
}
