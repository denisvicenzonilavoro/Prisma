#if os(macOS)
import Foundation

/// Le istantanee della fase 5 di Vera (Vera/BRIEF.md, Design/template-vera.html), chiare e scure, senza Qwen né Ollama:
/// «Vera su misura» (22: le quattro tappe compiute, l'esame non superato, l'anteprima, pochi esempi, l'esame in corso,
/// solo con Ollama), «Due velocità» (23), «Il cervello grande» (25) e l'etichetta del motore sotto le risposte. Esempi,
/// versioni, esame e richieste sono dati di prova dichiarati (SuMisuraDiProva): la pagina scrive «Numeri di esempio».
/// I numeri sono quelli liberi 554-559 e 567-569.
extension Istantanee {
    nonisolated static var sceneFaseCinqueVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene = sceneSuMisuraVera
        scene += sceneMotoriVera
        scene += sceneEtichettaMotoreVera
        return scene
    }

    // MARK: - Vera su misura (funzione 22)

    nonisolated static var sceneSuMisuraVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("554-vera-su-misura", { s in preparaSuMisura(s, superata: true) }),
            ("554-vera-su-misura-scuro", { s in preparaSuMisura(s, superata: true) }),
            ("555-vera-su-misura-non-superato", { s in preparaSuMisura(s, superata: false) }),
            ("555-vera-su-misura-non-superato-scuro", { s in preparaSuMisura(s, superata: false) }),
            ("559-vera-su-misura-anteprima", { s in preparaAnteprimaSuMisura(s) }),
            ("559-vera-su-misura-anteprima-scuro", { s in preparaAnteprimaSuMisura(s) }),
            ("567-vera-su-misura-pochi-esempi", { s in preparaPochiEsempi(s) }),
            ("567-vera-su-misura-pochi-esempi-scuro", { s in preparaPochiEsempi(s) }),
            ("568-vera-su-misura-esame", { s in preparaEsameInCorso(s) }),
            ("568-vera-su-misura-esame-scuro", { s in preparaEsameInCorso(s) }),
            ("569-vera-su-misura-solo-ollama", { s in preparaSoloOllama(s) }),
            ("569-vera-su-misura-solo-ollama-scuro", { s in preparaSoloOllama(s) }),
        ]
    }

    /// Le basi comuni: risposte preparate, Qwen «pronto» per finta, gli esempi di prova nella memoria (solo in RAM: non
    /// persistente, mai il Portachiavi).
    nonisolated private static func baseSuMisura(_ s: StatoShell, esempi: [EsempioVera] = SuMisuraDiProva.esempi()) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.veraPortafoglio = false
        for e in esempi { s.memoriaVera.approva(domanda: e.domanda, risposta: e.risposta, modalita: e.modalita) }
    }

    nonisolated static func preparaSuMisura(_ s: StatoShell, superata: Bool) {
        baseSuMisura(s)
        var vera = s.dati.impostazioni.vera
        let versioni = SuMisuraDiProva.versioni(superata: superata)
        vera.suMisura.versioni = versioni
        if superata, let v = versioni.first {
            vera.suMisura.modelloPrecedente = MotoreLocale.modelloPredefinito
            vera.modelloLocale = v.id
        }
        s.dati.impostazioni.vera = vera
        s.apriPaginaSuMisura()
    }

    nonisolated static func preparaAnteprimaSuMisura(_ s: StatoShell) {
        baseSuMisura(s, esempi: SuMisuraDiProva.esempi() + [SuMisuraDiProva.esempioDaGuardare()])
        // Un esempio escluso dal consulente
        if let e = s.memoriaVera.esempi.first(where: { $0.domanda.hasPrefix("Traduci") }) { s.escludiEsempioSuMisura(e.id, true) }
        s.apriPaginaSuMisura()
        s.anteprimaSuMisuraAperta = true
    }

    nonisolated static func preparaPochiEsempi(_ s: StatoShell) {
        baseSuMisura(s)
        s.apriPaginaSuMisura()
    }

    nonisolated static func preparaEsameInCorso(_ s: StatoShell) {
        baseSuMisura(s)
        var vera = s.dati.impostazioni.vera
        var v = SuMisuraDiProva.versioni(superata: true)[0]
        v.stato = .importata
        v.esame = nil
        vera.suMisura.versioni = [v]
        s.dati.impostazioni.vera = vera
        s.lavoroSuMisura = "domanda 12 di 80 · Vera di oggi"
        s.esameSuMisuraInCorso = true
        // La chat aspetta: un modello alla volta
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Com'è messa Giulia con la casa?"), cliente: "giulia", parla: false)
        s.esameSuMisuraInPausa(cliente: "giulia")
        s.apriPaginaSuMisura()
    }

    nonisolated static func preparaSoloOllama(_ s: StatoShell) {
        baseSuMisura(s)
        s.dati.impostazioni.vera.fornitore = .compatibileOpenAI
        s.apriPaginaSuMisura()
    }

    // MARK: - I motori di Vera (funzioni 23 e 25)

    nonisolated static var sceneMotoriVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("556-vera-due-velocita", { s in preparaDueVelocita(s) }),
            ("556-vera-due-velocita-scuro", { s in preparaDueVelocita(s) }),
            ("557-vera-cervello-grande", { s in preparaCervelloGrande(s) }),
            ("557-vera-cervello-grande-scuro", { s in preparaCervelloGrande(s) }),
        ]
    }

    nonisolated static func preparaDueVelocita(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        let oggi = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        for r in SuMisuraDiProva.corsie(oggi: oggi) { s.dueVelocita.registra(r.testo, corsia: r.corsia, secondi: r.secondi, quando: r.quando) }
        s.apriPaginaMotori(.dueVelocita)
    }

    nonisolated static func preparaCervelloGrande(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.apriPaginaMotori(.cervello)
    }

    // MARK: - L'etichetta del motore sotto le risposte

    nonisolated static var sceneEtichettaMotoreVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("558-vera-etichetta-motore", { s in preparaEtichettaMotore(s) }),
            ("558-vera-etichetta-motore-scuro", { s in preparaEtichettaMotore(s) }),
        ]
    }

    /// La chat di Giulia con tre risposte etichettate: Qwen in lavoro, Qwen in conversazione, le regole di Prisma (testi
    /// fac-simile, senza cifre).
    nonisolated static func preparaEtichettaMotore(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.veraPortafoglio = false
        let id = "giulia"
        s.dati.conversazioni[id] = []
        func scambio(_ domanda: String, _ risposta: String, motore: String, modalita: ModalitaVera?) {
            s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domanda), cliente: id, parla: false)
            var m = MessaggioVera(autore: .vera, testo: risposta, motore: motore)
            m.modalita = modalita
            s.aggiungiMessaggio(m, cliente: id, parla: false)
        }
        scambio("Com'è messa Giulia con il progetto casa?",
                "Il progetto casa resta la priorità: la quota per l'anticipo procede come previsto. Le cifre esatte sono nella scheda di Prisma.",
                motore: MotoreLocale.nome(MotoreLocale.modelloPredefinito), modalita: .lavoro)
        scambio("Scrivimi un augurio breve per il suo compleanno.",
                "Tanti auguri, Giulia! Che sia un anno pieno di belle notizie, a partire dalla casa.",
                motore: MotoreLocale.nome(MotoreLocale.modelloPredefinito), modalita: .conversazione)
        scambio("Apri l'agenda di domani", "Ecco l'agenda di domani.", motore: StatoShell.motoreAzioni, modalita: nil)
        s.apri(.vera)
    }
}
#endif
