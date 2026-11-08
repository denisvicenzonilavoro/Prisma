import Foundation

/// «Il sussurro» collegato all'app (Shell/CollegaSussurroShell.swift) dentro `Prisma --prova-vera`: le voci della vista
/// sono quelle del motore, il pulsante di un'azione che cambia qualcosa prepara la scheda «Conferma» (niente segnato
/// prima), «Non ora» chiude la voce per una settimana, la chat risponde con le stesse voci, in modalità cliente niente.
enum ProvaCollegaSussurroVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        let oggi = Date()
        let cal = Calendar.current
        guard let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) else {
            return controlla(false, "Sussurro nell'app: manca Sofia tra i dati di prova")
        }
        // Consenso privacy mancante: la prima voce è rossa, con l'attività da confermare
        s.dati.clienti[i].consensi = Consensi()
        let voci = s.vociSussurro(dati: s.dati.istantanea, clienteId: "sofia", oggi: oggi)
        controlla(!voci.isEmpty && voci.count <= RegoleSussurro.massimoVoci && voci.first?.categoria == .consensoPrivacy && voci.first?.tono == .rosso,
                  "Sussurro nell'app: per Sofia senza consenso privacy la prima voce è il consenso, rossa: \(voci.map(\.testo))")
        controlla(s.vociSussurro(clienteId: "sofia", oggi: oggi) == voci, "Sussurro nell'app: la vista (dati dei calcoli) ha le stesse voci del motore")
        guard let v = voci.first else { return }
        let attivita = s.dati.attivita.count
        guard let mid = s.eseguiSussurro(v, oggi: oggi), let scheda = s.messaggioVera(mid)?.conferma else {
            return controlla(false, "Sussurro nell'app: il pulsante del consenso non prepara la scheda «Conferma»")
        }
        controlla(scheda.stato == .daConfermare && scheda.origine == .sussurro && scheda.azioni.first?.strumento == RegistroStrumenti.attivitaNuova
                  && s.dati.attivita.count == attivita && s.conversazione("sofia").last?.id == mid,
                  "Sussurro nell'app: la scheda «Conferma» va nella conversazione di Sofia e niente è segnato prima di «Conferma»")
        _ = s.confermaSchedaVera(messaggio: mid)
        controlla(s.dati.attivita.count == attivita + 1 && s.statoSchedaSussurro(mid) == .eseguita,
                  "Sussurro nell'app: dopo «Conferma» l'attività è segnata")
        // «Non ora»: la voce non torna per una settimana, poi sì; le righe vecchie si tolgono
        s.chiudiSussurro(v, oggi: oggi)
        controlla(!s.vociSussurro(dati: s.dati.istantanea, clienteId: "sofia", oggi: oggi).contains { $0.chiave == v.chiave },
                  "Sussurro nell'app: una voce chiusa non torna subito")
        controlla(!s.vociSussurro(clienteId: "sofia", oggi: oggi).contains { $0.chiave == v.chiave },
                  "Sussurro nell'app: la vista si aggiorna appena una voce si chiude")
        let dopo = cal.date(byAdding: .day, value: RegoleSussurro.giorniChiusura + 1, to: oggi) ?? oggi
        controlla(s.vociSussurro(dati: s.dati.istantanea, clienteId: "sofia", oggi: dopo).contains { $0.chiave == v.chiave },
                  "Sussurro nell'app: dopo una settimana la voce chiusa torna")
        var altra = v
        altra.chiave = "altra-prova"
        s.chiudiSussurro(altra, oggi: dopo)
        controlla(s.dati.sussurriChiusi.map(\.chiave) == ["altra-prova"], "Sussurro nell'app: le voci chiuse da più di una settimana escono dall'elenco")
        s.riapriSussurro(altra)
        controlla(s.dati.sussurriChiusi.isEmpty, "Sussurro nell'app: «riapri» toglie la voce chiusa")
        // Una preferenza chiusa: nell'archivio solo l'impronta, e la voce resta chiusa
        let pref = VoceSussurro(chiave: "preferenza-decide sempre insieme a paolo", clienteId: "sofia", categoria: .preferenza, tono: .blu,
                                testo: "Decide sempre insieme a Paolo.", azione: AzioneSussurro(.tieniAMente, "Tienilo a mente"),
                                fonte: "La memoria di Vera", rango: 22, data: nil)
        s.chiudiSussurro(pref, oggi: oggi)
        controlla(s.dati.sussurriChiusi.allSatisfy { !$0.chiave.contains("paolo") }, "Sussurro nell'app: nell'archivio la preferenza chiusa è solo un'impronta")
        s.riapriSussurro(pref)
        // In chat: «cosa devo sapere su Sofia?» con le voci e una scheda sola
        s.veraPortafoglio = true
        controlla(!s.chiediSussurro("Cosa devo sapere?", chiave: VeraPortafoglio.chiave), "Sussurro in chat: nel portafoglio senza un nome la frase torna alla chat")
        controlla(s.chiediSussurro("Cosa devo sapere su Sofia?", chiave: VeraPortafoglio.chiave), "Sussurro in chat: «cosa devo sapere su Sofia?» è del sussurro")
        let m = s.conversazione(VeraPortafoglio.chiave).last
        controlla(m?.titolo == "Il sussurro" && (m?.testo.contains("su Sofia") ?? false), "Sussurro in chat: la risposta dice le cose da sapere su Sofia: \(m?.testo ?? "")")
        controlla(!s.chiediSussurro("Scrivi a Sofia cosa deve sapere", chiave: VeraPortafoglio.chiave), "Sussurro in chat: «scrivi a…» resta a «Fallo tu»")
        s.veraPortafoglio = false
        // Modalità cliente: niente sussurro, né nella vista né in chat
        s.clienteAttivoId = "sofia"
        s.modoCliente = "sofia"
        controlla(s.vociSussurro(clienteId: "sofia", oggi: oggi).isEmpty, "Sussurro nell'app: in modalità cliente la card non c'è")
        let primaModo = s.conversazione("sofia").count
        controlla(!s.chiediSussurro("Cosa devo sapere su Sofia?", chiave: "sofia") && s.conversazione("sofia").count == primaModo,
                  "Sussurro in chat: in modalità cliente la frase passa oltre, senza messaggi né scheda")
        s.modoCliente = nil
        // Spento in Impostazioni › Vera
        s.dati.impostazioni.vera.sussurroNelDossier = false
        controlla(s.vociSussurro(clienteId: "sofia", oggi: oggi).isEmpty, "Sussurro nell'app: spento in Impostazioni › Vera la card non c'è")
        s.dati.impostazioni.vera.sussurroNelDossier = true
        // Il cliente tolto porta via le sue voci chiuse
        s.chiudiSussurro(v, oggi: oggi)
        s.eliminaCliente("sofia")
        controlla(!s.dati.sussurriChiusi.contains { $0.clienteId == "sofia" }, "Sussurro nell'app: eliminando il cliente le sue voci chiuse se ne vanno")
    }
}
