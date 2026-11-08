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
    }
}
