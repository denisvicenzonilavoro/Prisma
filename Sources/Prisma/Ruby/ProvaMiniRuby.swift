#if os(macOS)
import Foundation

/// Prova della mini finestra di Ruby (dentro `Prisma --prova-ruby`): il gesto di ⌥ Spazio, i cinque stati e i passaggi,
/// il contesto, le cifre di Prisma con il canale, la stessa conversazione dell'app Ruby e «non pronta» senza risposte inventate.
enum ProvaMiniRuby {
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
        controlla(g.rilascia(t0.addingTimeInterval(0.12)) == .scrivi, "Mini Ruby: ⌥ Spazio premuto una volta apre per scrivere")
        _ = g.premi(t0)
        controlla(g.tieni(t0.addingTimeInterval(0.1)) == .nessuno, "Mini Ruby: prima della soglia non ascolta")
        controlla(g.premi(t0.addingTimeInterval(0.2)) == .nessuno, "Mini Ruby: la ripetizione del tasto non conta")
        controlla(g.tieni(t0.addingTimeInterval(g.soglia + 0.01)) == .iniziaAParlare, "Mini Ruby: ⌥ Spazio tenuto premuto = parla")
        controlla(g.tieni(t0.addingTimeInterval(g.soglia + 0.5)) == .nessuno, "Mini Ruby: l'ascolto parte una volta sola")
        controlla(g.rilascia(t0.addingTimeInterval(2)) == .finisciDiParlare, "Mini Ruby: rilasciato = Ruby risponde")
        controlla(g.rilascia(t0.addingTimeInterval(3)) == .nessuno, "Mini Ruby: un rilascio senza pressione non fa niente")
    }

    /// Le due forme della superficie e i passaggi tra gli stati.
    private static func stati(_ controlla: (Bool, String) -> Void) {
        let m = Tema.Misura.MiniRuby.self
        controlla(m.larghezzaCapsula == 440 && m.altezzaCapsula == 72 && m.larghezzaScheda == 460, "Mini Ruby: capsula 440 × 72, scheda 460")
        controlla(Tema.Moto.MiniRuby.durataForma == 0.55, "Mini Ruby: il cambio di forma dura 0,55 s")
        controlla(FaseMiniRuby.allCases.filter(\.capsula) == [.ascolta, .pensa, .nonPronta], "Mini Ruby: capsula mentre ascolta, pensa e si sveglia")
        let mini = StatoMiniRuby()
        controlla(!mini.aperta, "Mini Ruby: chiusa all'avvio")
        mini.apri(.scrivi, contesto: nil)
        controlla(mini.aperta && mini.visibile && mini.fase == .scrivi && mini.larghezza == m.larghezzaScheda, "Mini Ruby: si apre per scrivere (scheda)")
        mini.vai(.ascolta)
        controlla(mini.fase == .ascolta && mini.larghezza == m.larghezzaCapsula, "Mini Ruby: ascolta (capsula)")
        mini.pensa("Domanda", passi: ["Uno…", "Due…"])
        controlla(mini.fase == .pensa && mini.passo == "Uno…" && mini.domanda == "Domanda", "Mini Ruby: pensa con il primo passo e la domanda")
        mini.rispondi(testo: "Ecco", titolo: nil, cifre: CifreMiniRuby(), inArrivo: true)
        controlla(mini.fase == .risponde && mini.inArrivo && mini.larghezza == m.larghezzaScheda, "Mini Ruby: la risposta che arriva apre la scheda")
        mini.rispondi(testo: "Ecco tutto", titolo: nil, cifre: CifreMiniRuby(), inArrivo: false)
        controlla(mini.risposta == "Ecco tutto" && !mini.inArrivo, "Mini Ruby: la risposta finita resta nella scheda")
        mini.nonPronta(motivo: nil)
        controlla(mini.fase == .nonPronta && mini.fase.capsula, "Mini Ruby: non pronta (capsula)")
        mini.chiudi()
        controlla(!mini.visibile && mini.aperta, "Mini Ruby: Esc comincia l'uscita")
        mini.riposa()
        controlla(!mini.aperta && mini.fase == .scrivi && mini.risposta.isEmpty, "Mini Ruby: a riposo dopo l'uscita")
    }

    /// Dalla domanda alla risposta, sui dati di prova: contesto, cifre, canali, fonte, pulsanti e conversazione.
    private static func flusso(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        Istantanee.preparaMiniRuby(s)
        let contesto = s.contestoMiniRuby()
        controlla(contesto?.nome == "Giulia Rossi" && contesto?.app == "Posizioni", "Mini Ruby: il contesto è il cliente e l'app aperti")
        let f = s.fonteRuby("giulia")
        let passi = StatoMiniRuby.passi(domanda: Istantanee.domandaMiniRuby, fonte: f, modalita: .lavoro)
        controlla(passi.first == "Apro il dossier di Giulia…" && passi.contains { $0.contains("Alleanza e indipendenti") },
                  "Mini Ruby: i passi di «pensa» vengono dai dati del cliente")

        s.apriMiniRuby(.scrivi)
        let prima = s.conversazione("giulia").count
        s.inviaMiniRuby(DomandaMiniRuby(testo: Istantanee.domandaMiniRuby))
        let mini = s.miniRuby
        controlla(mini.fase == .risponde && !mini.risposta.isEmpty, "Mini Ruby: la domanda arriva alla risposta")
        controlla(s.conversazione("giulia").count == prima + 2 && mini.chiave == "giulia",
                  "Mini Ruby: domanda e risposta nella stessa conversazione dell'app Ruby")
        let attese = (f?.posizioni ?? []).filter { p in
            ["pos-giulia-conto-corrente-e-conto-deposito", "pos-giulia-piano-di-risparmio-rivalutabile"].contains(p.id)
        }
        let righe = mini.cifre.righe
        controlla(righe.count >= 2 && Set(righe.map(\.canale)) == [.alleanza, .indipendente], "Mini Ruby: le scadenze con il loro canale")
        controlla(attese.allSatisfy { p in righe.contains { $0.id == p.id && $0.valore == Formati.euro(p.valore) } },
                  "Mini Ruby: le cifre sono quelle calcolate da Prisma")
        controlla(mini.cifre.linea?.punti.count == righe.count && mini.cifre.linea?.oltre?.contains("→") == true,
                  "Mini Ruby: la linea del tempo con le scadenze e l'obiettivo oltre l'orizzonte")
        controlla(mini.cifre.fonte?.hasPrefix("Cifre dai calcoli di Posizioni") == true, "Mini Ruby: la riga della fonte")
        controlla(mini.cifre.azioni.first?.primaria == true && mini.cifre.azioni.first?.tipo == .posizioni, "Mini Ruby: il primo pulsante porta in Posizioni")
        controlla(CifreMiniRuby.conArticolo("11 gennaio") == "l'11 gennaio" && CifreMiniRuby.conArticolo("3 marzo") == "il 3 marzo",
                  "Mini Ruby: «l'11 gennaio», «il 3 marzo»")
        controlla(!mini.cifre.seguiti.isEmpty, "Mini Ruby: gli spunti per continuare")

        // Un pulsante porta nell'app e chiude la mini finestra
        s.apri(.agenda)
        if let a = mini.cifre.azioni.first { s.eseguiMiniRuby(a) }
        controlla(s.appAttiva == .posizioni && !mini.visibile && !mini.aperta, "Mini Ruby: «Apri in Posizioni» apre l'app e chiude Ruby")

        // La freccia: la stessa conversazione nell'app Ruby completa
        s.apriMiniRuby(.scrivi)
        s.inviaMiniRuby(DomandaMiniRuby(testo: "Fammi un riepilogo del cliente", spunto: .riepilogo))
        s.apriInRubyDaMiniRuby()
        controlla(s.appAttiva == .ruby && !s.rubyPortafoglio && s.clienteAttivoId == "giulia" && !mini.aperta,
                  "Mini Ruby: la freccia apre la conversazione nell'app Ruby")

        // Senza gettone Ruby parla del portafoglio
        s.apriMiniRuby(.scrivi)
        s.togliContestoMiniRuby()
        controlla(mini.contesto == nil, "Mini Ruby: il gettone del contesto si toglie")
        s.inviaMiniRuby(DomandaMiniRuby(testo: SpuntoPortafoglio.ricontattare.domanda, portafoglio: .ricontattare))
        controlla(mini.chiave == RubyPortafoglio.chiave && mini.fase == .risponde && mini.cifre.righe.isEmpty,
                  "Mini Ruby: senza contesto la domanda va al portafoglio, senza cifre di un cliente")
        s.chiudiMiniRuby()

        // In conversazione niente cifre
        let generale = CifreMiniRuby.calcola(domanda: "Cos'è l'inflazione?", fonte: f, modalita: .conversazione, app: "Posizioni")
        controlla(generale.righe.isEmpty && generale.fonte == nil && generale.azioni.isEmpty, "Mini Ruby: in conversazione niente cifre né fonte")

        // In modalità cliente il gettone resta (mai i dati di altri clienti)
        s.entraModoCliente()
        s.apriMiniRuby(.scrivi)
        s.togliContestoMiniRuby()
        controlla(mini.contesto != nil && s.recentiMiniRuby().isEmpty, "Mini Ruby: in modalità cliente il contesto non si toglie e niente recenti")
        s.chiudiMiniRuby()
    }

    /// Qwen non è pronto: «Mi sto svegliando…», la domanda resta da parte, nessuna risposta inventata.
    private static func nonPronta(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        Istantanee.preparaMiniRuby(s)
        s.rispostePreparate = false
        s.apriMiniRuby(.scrivi)
        let prima = s.conversazione("giulia").count
        s.inviaMiniRuby(DomandaMiniRuby(testo: Istantanee.domandaMiniRuby))
        let mini = s.miniRuby
        controlla(mini.fase == .nonPronta && mini.pendente?.testo == Istantanee.domandaMiniRuby, "Mini Ruby: Qwen non pronto → «Mi sto svegliando…»")
        controlla(s.conversazione("giulia").count == prima && mini.risposta.isEmpty, "Mini Ruby: non pronta, nessuna risposta inventata")
        s.riprovaMiniRuby()
        controlla(mini.fase == .nonPronta, "Mini Ruby: Riprova con Qwen ancora spento resta in attesa")
        // Qwen pronto (qui: le risposte preparate): Riprova manda la domanda rimasta da parte
        s.rispostePreparate = true
        s.riprovaMiniRuby()
        controlla(mini.fase == .risponde && mini.pendente == nil && s.conversazione("giulia").count == prima + 2,
                  "Mini Ruby: Riprova manda la domanda quando Qwen è pronto")
    }
}
#endif
