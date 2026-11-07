#if os(macOS)
import Foundation

/// Prova della mini finestra di Vera (dentro `Prisma --prova-vera`): il gesto di ⌥ Spazio, i cinque stati e i passaggi,
/// il contesto, le cifre di Prisma con il canale, la stessa conversazione dell'app Vera e «non pronta» senza risposte inventate.
enum ProvaMiniVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        gesto(controlla)
        stati(controlla)
        flusso(controlla)
        nonPronta(controlla)
    }

    /// ⌥ Spazio: premuto e lasciato = scrivi; tenuto = parla, lasciato = risponde; le ripetizioni non contano.
    private static func gesto(_ controlla: (Bool, String) -> Void) {
        let t0 = Date()
        var g = GestoScorciatoia()
        _ = g.premi(t0)
        controlla(g.rilascia(t0.addingTimeInterval(0.12)) == .scrivi, "Mini Vera: ⌥ Spazio premuto una volta apre per scrivere")
        _ = g.premi(t0)
        controlla(g.tieni(t0.addingTimeInterval(0.1)) == .nessuno, "Mini Vera: prima della soglia non ascolta")
        controlla(g.premi(t0.addingTimeInterval(0.2)) == .nessuno, "Mini Vera: la ripetizione del tasto non conta")
        controlla(g.tieni(t0.addingTimeInterval(g.soglia + 0.01)) == .iniziaAParlare, "Mini Vera: ⌥ Spazio tenuto premuto = parla")
        controlla(g.tieni(t0.addingTimeInterval(g.soglia + 0.5)) == .nessuno, "Mini Vera: l'ascolto parte una volta sola")
        controlla(g.rilascia(t0.addingTimeInterval(2)) == .finisciDiParlare, "Mini Vera: rilasciato = Vera risponde")
        controlla(g.rilascia(t0.addingTimeInterval(3)) == .nessuno, "Mini Vera: un rilascio senza pressione non fa niente")
    }

    /// Le due forme della superficie e i passaggi tra gli stati.
    private static func stati(_ controlla: (Bool, String) -> Void) {
        let m = Tema.Misura.MiniVera.self
        controlla(m.larghezzaCapsula == 440 && m.altezzaCapsula == 72 && m.larghezzaScheda == 460, "Mini Vera: capsula 440 × 72, scheda 460")
        controlla(Tema.Moto.MiniVera.durataForma == 0.55, "Mini Vera: il cambio di forma dura 0,55 s")
        controlla(FaseMiniVera.allCases.filter(\.capsula) == [.ascolta, .pensa, .nonPronta], "Mini Vera: capsula mentre ascolta, pensa e si sveglia")
        let mini = StatoMiniVera()
        controlla(!mini.aperta, "Mini Vera: chiusa all'avvio")
        mini.apri(.scrivi, contesto: nil)
        controlla(mini.aperta && mini.visibile && mini.fase == .scrivi && mini.larghezza == m.larghezzaScheda, "Mini Vera: si apre per scrivere (scheda)")
        mini.vai(.ascolta)
        controlla(mini.fase == .ascolta && mini.larghezza == m.larghezzaCapsula, "Mini Vera: ascolta (capsula)")
        mini.pensa("Domanda", passi: ["Uno…", "Due…"])
        controlla(mini.fase == .pensa && mini.passo == "Uno…" && mini.domanda == "Domanda", "Mini Vera: pensa con il primo passo e la domanda")
        mini.rispondi(testo: "Ecco", titolo: nil, cifre: CifreMiniVera(), inArrivo: true)
        controlla(mini.fase == .risponde && mini.inArrivo && mini.larghezza == m.larghezzaScheda, "Mini Vera: la risposta che arriva apre la scheda")
        mini.rispondi(testo: "Ecco tutto", titolo: nil, cifre: CifreMiniVera(), inArrivo: false)
        controlla(mini.risposta == "Ecco tutto" && !mini.inArrivo, "Mini Vera: la risposta finita resta nella scheda")
        mini.nonPronta(motivo: nil)
        controlla(mini.fase == .nonPronta && mini.fase.capsula, "Mini Vera: non pronta (capsula)")
        mini.chiudi()
        controlla(!mini.visibile && mini.aperta, "Mini Vera: Esc comincia l'uscita")
        mini.riposa()
        controlla(!mini.aperta && mini.fase == .scrivi && mini.risposta.isEmpty, "Mini Vera: a riposo dopo l'uscita")
    }

    /// Dalla domanda alla risposta, sui dati di prova: contesto, cifre, canali, fonte, pulsanti e conversazione.
    private static func flusso(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        Istantanee.preparaMiniVera(s)
        let contesto = s.contestoMiniVera()
        controlla(contesto?.nome == "Giulia Rossi" && contesto?.app == "Posizioni", "Mini Vera: il contesto è il cliente e l'app aperti")
        let f = s.fonteVera("giulia")
        let passi = StatoMiniVera.passi(domanda: Istantanee.domandaMiniVera, fonte: f, modalita: .lavoro)
        controlla(passi.first == "Apro il dossier di Giulia…" && passi.contains { $0.contains("Alleanza e indipendenti") },
                  "Mini Vera: i passi di «pensa» vengono dai dati del cliente")

        s.apriMiniVera(.scrivi)
        let prima = s.conversazione("giulia").count
        s.inviaMiniVera(DomandaMiniVera(testo: Istantanee.domandaMiniVera))
        let mini = s.miniVera
        controlla(mini.fase == .risponde && !mini.risposta.isEmpty, "Mini Vera: la domanda arriva alla risposta")
        controlla(s.conversazione("giulia").count == prima + 2 && mini.chiave == "giulia",
                  "Mini Vera: domanda e risposta nella stessa conversazione dell'app Vera")
        let attese = (f?.posizioni ?? []).filter { p in
            ["pos-giulia-conto-corrente-e-conto-deposito", "pos-giulia-piano-di-risparmio-rivalutabile"].contains(p.id)
        }
        let righe = mini.cifre.righe
        controlla(righe.count >= 2 && Set(righe.map(\.canale)) == [.alleanza, .indipendente], "Mini Vera: le scadenze con il loro canale")
        controlla(attese.allSatisfy { p in righe.contains { $0.id == p.id && $0.valore == Formati.euro(p.valore) } },
                  "Mini Vera: le cifre sono quelle calcolate da Prisma")
        controlla(mini.cifre.linea?.punti.count == righe.count && mini.cifre.linea?.oltre?.contains("→") == true,
                  "Mini Vera: la linea del tempo con le scadenze e l'obiettivo oltre l'orizzonte")
        controlla(mini.cifre.fonte?.hasPrefix("Cifre dai calcoli di Posizioni") == true, "Mini Vera: la riga della fonte")
        controlla(mini.cifre.azioni.first?.primaria == true && mini.cifre.azioni.first?.tipo == .posizioni, "Mini Vera: il primo pulsante porta in Posizioni")
        controlla(CifreMiniVera.conArticolo("11 gennaio") == "l'11 gennaio" && CifreMiniVera.conArticolo("3 marzo") == "il 3 marzo",
                  "Mini Vera: «l'11 gennaio», «il 3 marzo»")
        controlla(!mini.cifre.seguiti.isEmpty, "Mini Vera: gli spunti per continuare")

        // Un pulsante porta nell'app e chiude la mini finestra
        s.apri(.agenda)
        if let a = mini.cifre.azioni.first { s.eseguiMiniVera(a) }
        controlla(s.appAttiva == .posizioni && !mini.visibile && !mini.aperta, "Mini Vera: «Apri in Posizioni» apre l'app e chiude Vera")

        // La freccia: la stessa conversazione nell'app Vera completa
        s.apriMiniVera(.scrivi)
        s.inviaMiniVera(DomandaMiniVera(testo: "Fammi un riepilogo del cliente", spunto: .riepilogo))
        s.apriInVeraDaMiniVera()
        controlla(s.appAttiva == .vera && !s.veraPortafoglio && s.clienteAttivoId == "giulia" && !mini.aperta,
                  "Mini Vera: la freccia apre la conversazione nell'app Vera")

        // Senza gettone Vera parla del portafoglio
        s.apriMiniVera(.scrivi)
        s.togliContestoMiniVera()
        controlla(mini.contesto == nil, "Mini Vera: il gettone del contesto si toglie")
        s.inviaMiniVera(DomandaMiniVera(testo: SpuntoPortafoglio.ricontattare.domanda, portafoglio: .ricontattare))
        controlla(mini.chiave == VeraPortafoglio.chiave && mini.fase == .risponde && mini.cifre.righe.isEmpty,
                  "Mini Vera: senza contesto la domanda va al portafoglio, senza cifre di un cliente")
        s.chiudiMiniVera()

        // In conversazione niente cifre
        let generale = CifreMiniVera.calcola(domanda: "Cos'è l'inflazione?", fonte: f, modalita: .conversazione, app: "Posizioni")
        controlla(generale.righe.isEmpty && generale.fonte == nil && generale.azioni.isEmpty, "Mini Vera: in conversazione niente cifre né fonte")

        // In modalità cliente il gettone resta (mai i dati di altri clienti)
        s.entraModoCliente()
        s.apriMiniVera(.scrivi)
        s.togliContestoMiniVera()
        controlla(mini.contesto != nil && s.recentiMiniVera().isEmpty, "Mini Vera: in modalità cliente il contesto non si toglie e niente recenti")
        s.chiudiMiniVera()
    }

    /// Qwen non è pronto: «Mi sto svegliando…», la domanda resta da parte, nessuna risposta inventata.
    private static func nonPronta(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        Istantanee.preparaMiniVera(s)
        s.rispostePreparate = false
        s.apriMiniVera(.scrivi)
        let prima = s.conversazione("giulia").count
        s.inviaMiniVera(DomandaMiniVera(testo: Istantanee.domandaMiniVera))
        let mini = s.miniVera
        controlla(mini.fase == .nonPronta && mini.pendente?.testo == Istantanee.domandaMiniVera, "Mini Vera: Qwen non pronto → «Mi sto svegliando…»")
        controlla(s.conversazione("giulia").count == prima && mini.risposta.isEmpty, "Mini Vera: non pronta, nessuna risposta inventata")
        s.riprovaMiniVera()
        controlla(mini.fase == .nonPronta, "Mini Vera: Riprova con Qwen ancora spento resta in attesa")
        // Qwen pronto (qui: le risposte preparate): Riprova manda la domanda rimasta da parte
        s.rispostePreparate = true
        s.riprovaMiniVera()
        controlla(mini.fase == .risponde && mini.pendente == nil && s.conversazione("giulia").count == prima + 2,
                  "Mini Vera: Riprova manda la domanda quando Qwen è pronto")
    }
}
#endif
