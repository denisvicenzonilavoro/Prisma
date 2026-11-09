#if os(macOS)
import Foundation

/// Le istantanee della fase 2 di Vera (Design/template-vera.html), chiare e scure, senza Qwen:
/// «Il cliente in 30 secondi» di Marco, una risposta del «Codice in tasca» con l'articolo citato, la scheda di
/// «Lascia cadere qui» per una polizza riconosciuta dal codice fiscale, e la Biblioteca delle norme. In più: il racconto a
/// voce in 30 secondi e la card nella scheda del cliente; l'estratto conto in Posizioni, la carta d'identità in Anagrafica,
/// la scelta del cliente dalla risposta e «Archiviati da Vera oggi».
extension Istantanee {
    nonisolated static var sceneFaseDueVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("488-vera-trenta-secondi", { s in preparaTrenta(s) }),
            ("488-vera-trenta-secondi-scuro", { s in preparaTrenta(s) }),
            ("489-vera-codice-in-tasca", { s in preparaNorme(s) }),
            ("489-vera-codice-in-tasca-scuro", { s in preparaNorme(s) }),
            ("490-vera-lascia-cadere", { s in preparaLasciaCadere(s) }),
            ("490-vera-lascia-cadere-scuro", { s in preparaLasciaCadere(s) }),
            // «Il cliente in 30 secondi» letto a voce (terza sezione, anello a metà) e la card nella scheda del cliente
            ("630-vera-trenta-secondi-ascolto", { s in preparaTrentaAscolto(s) }),
            ("630-vera-trenta-secondi-ascolto-scuro", { s in preparaTrentaAscolto(s) }),
            ("631-vera-trenta-secondi-dossier", { s in preparaTrentaDossier(s) }),
            ("631-vera-trenta-secondi-dossier-scuro", { s in preparaTrentaDossier(s) }),
            // «Lascia cadere qui»: estratto conto → Posizioni, carta d'identità → Anagrafica, scelta del cliente, archiviati
            ("632-vera-lascia-cadere-estratto", { s in preparaLasciaCadereEstratto(s) }),
            ("632-vera-lascia-cadere-estratto-scuro", { s in preparaLasciaCadereEstratto(s) }),
            ("633-vera-lascia-cadere-identita", { s in preparaLasciaCadereIdentita(s) }),
            ("633-vera-lascia-cadere-identita-scuro", { s in preparaLasciaCadereIdentita(s) }),
            ("634-vera-lascia-cadere-scelta", { s in preparaLasciaCadereScelta(s) }),
            ("634-vera-lascia-cadere-scelta-scuro", { s in preparaLasciaCadereScelta(s) }),
            ("635-vera-archiviati-oggi", { s in preparaArchiviatiOggi(s) }),
            ("635-vera-archiviati-oggi-scuro", { s in preparaArchiviatiOggi(s) }),
            // La memoria (18), i pollici con la lezione salvata e «Le lezioni di Vera» (21), il filo lungo (24)
            ("636-vera-memoria", { s in preparaMemoria(s) }),
            ("636-vera-memoria-scuro", { s in preparaMemoria(s) }),
            ("637-vera-pollici-correzione", { s in preparaPollici(s) }),
            ("637-vera-pollici-correzione-scuro", { s in preparaPollici(s) }),
            ("638-vera-filo-lungo", { s in preparaFiloLungo(s) }),
            ("638-vera-filo-lungo-scuro", { s in preparaFiloLungo(s) }),
            ("491-biblioteca", { s in preparaNorme(s); s.apri(.biblioteca) }),
            ("491-biblioteca-scuro", { s in preparaNorme(s); s.apri(.biblioteca) }),
        ]
    }

    nonisolated static func preparaTrenta(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = false
        s.memoriaVera.ricorda("Marco preferisce le videochiamate al mattino", cliente: "marco", fonte: "dal resoconto")
        s.memoriaVera.ricorda("Prima i numeri, poi le parole", cliente: "marco", fonte: "in chat")
        _ = s.chiediTrentaSecondi("Raccontami Marco in 30 secondi", chiave: "marco")
        s.apri(.vera)
    }

    nonisolated static func preparaTrentaAscolto(_ s: StatoShell) {
        preparaTrenta(s)
        guard let m = s.conversazione("marco").last(where: { $0.trenta != nil }) else { return }
        s.ascoltaTrentaSecondi(messaggio: m.id)
        s.avanzaLetturaTrenta(m.id)
        s.avanzaLetturaTrenta(m.id)
    }

    nonisolated static func preparaTrentaDossier(_ s: StatoShell) {
        s.clienteAttivoId = "marco"
        s.schedaCliente = .panoramica
        s.apri(.clienti)
    }

    /// Un file di prova nella cartella temporanea (la scheda vuole un file vero da archiviare).
    nonisolated private static func fileDiProva(_ nome: String) -> URL {
        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("Prisma-istantanee-vera", isDirectory: true)
        try? FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        let u = cartella.appendingPathComponent(nome)
        try? Data("fac-simile".utf8).write(to: u)
        return u
    }

    nonisolated private static func baseLasciaCadere(_ s: StatoShell, cliente: String) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = cliente
        s.veraPortafoglio = false
    }

    @discardableResult
    nonisolated private static func cadeEstratto(_ s: StatoShell) -> MessaggioVera {
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "📄 Estratto conto ottobre.pdf"), cliente: "marco", parla: false)
        return s.rispondiDocumentoCaduto(fileDiProva("Estratto conto ottobre.pdf"), pagine: [ProvaFaseDueVera.estrattoDiProva], pagineOCR: 0, chiave: "marco")
    }

    @discardableResult
    nonisolated private static func cadeIdentita(_ s: StatoShell) -> MessaggioVera {
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "📄 Carta d'identità Andrea.pdf"), cliente: "marco", parla: false)
        return s.rispondiDocumentoCaduto(fileDiProva("Carta d'identità Andrea.pdf"), pagine: [ProvaFaseDueVera.identitaDiProva], pagineOCR: 0, chiave: "marco")
    }

    nonisolated static func preparaLasciaCadereEstratto(_ s: StatoShell) {
        baseLasciaCadere(s, cliente: "marco")
        cadeEstratto(s)
        s.apri(.vera)
    }

    nonisolated static func preparaLasciaCadereIdentita(_ s: StatoShell) {
        baseLasciaCadere(s, cliente: "marco")
        cadeIdentita(s)
        s.apri(.vera)
    }

    nonisolated static func preparaLasciaCadereScelta(_ s: StatoShell) {
        baseLasciaCadere(s, cliente: "marco")
        s.veraPortafoglio = true
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "📄 Comunicazione.pdf"), cliente: VeraPortafoglio.chiave, parla: false)
        s.rispondiDocumentoCaduto(fileDiProva("Comunicazione.pdf"), pagine: ["Comunicazione per Marco Bianchi e Laura Moretti (fac-simile)"],
                                  pagineOCR: 0, chiave: VeraPortafoglio.chiave)
        s.apri(.vera)
    }

    nonisolated static func preparaArchiviatiOggi(_ s: StatoShell) {
        baseLasciaCadere(s, cliente: "marco")
        _ = s.confermaSchedaVera(messaggio: cadeEstratto(s).id)
        _ = s.confermaSchedaVera(messaggio: cadeIdentita(s).id)
        preparaLasciaCadere(s)
        if let m = s.conversazione("marco").last(where: { $0.conferma?.origine == .documento && $0.conferma?.stato == .daConfermare }) {
            _ = s.confermaSchedaVera(messaggio: m.id)
        }
    }

    /// Le risposte votate di Sofia (testi di prova scritti qui, mai chiesti a Qwen): una con 👍, una corretta con 👎.
    nonisolated private static func conversazioneVotata(_ s: StatoShell) {
        let qwen = s.qwen.nome
        let giorni = [-44, -37, -30, -23, -16, -9, -2]
        for (k, g) in giorni.enumerated() {
            var d = MessaggioVera(autore: .utente, testo: "Prepara due righe per Sofia sulla rivalutabile.")
            d.data = Calendar.current.date(byAdding: .day, value: g, to: Date()) ?? Date()
            var r = MessaggioVera(autore: .vera, testo: "Sofia, la rivalutabile scade a gennaio: giovedì decidiamo insieme cosa fare.", motore: qwen)
            r.data = d.data
            r.voto = k % 3 != 0
            s.aggiungiMessaggio(d, cliente: "sofia", parla: false)
            s.aggiungiMessaggio(r, cliente: "sofia", parla: false)
        }
    }

    nonisolated static func preparaMemoria(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "sofia"
        s.veraPortafoglio = false
        s.memoriaVera.ricorda("Preferisco le mail brevi, una cosa per riga", cliente: nil, fonte: "in chat")
        s.memoriaVera.ricorda("Il martedì mattina lo tengo libero per lo studio", cliente: nil, fonte: "in chat")
        s.memoriaVera.ricorda("Sofia decide sempre insieme a Paolo", cliente: "sofia", fonte: "in chat")
        s.memoriaVera.ricorda("Marco preferisce le videochiamate al mattino", cliente: "marco", fonte: "dal resoconto")
        s.memoriaVera.ricorda("Laura vuole smettere di lavorare a 60 anni", cliente: "laura", fonte: "dall'incontro")
        _ = s.memoriaVera.impara("Con i clienti Alleanza parla di «piano», non di «prodotto»")
        _ = s.memoriaVera.impara("Con Sofia usa il Lei e frasi brevi")
        conversazioneVotata(s)
        s.apri(.vera)
        s.memoriaVera.aperta = true
    }

    nonisolated static func preparaPollici(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "sofia"
        s.veraPortafoglio = false
        let qwen = s.qwen.nome
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Spiega a Sofia perché conviene decidere giovedì sulla rivalutabile."), cliente: "sofia", parla: false)
        let prima = MessaggioVera(autore: .vera, testo: "Ciao Sofia! Il prodotto scade a gennaio, quindi conviene muoversi: giovedì vediamo le opzioni.", motore: qwen)
        s.aggiungiMessaggio(prima, cliente: "sofia", parla: false)
        _ = s.correggiRispostaVera(prima.id, correzione: "Con Sofia usa il Lei e frasi brevi; parla di «piano», non di «prodotto»")
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Riscrivila."), cliente: "sofia", parla: false)
        let dopo = MessaggioVera(autore: .vera, testo: "Gentile Sofia, il suo piano scade a gennaio.\nGiovedì scegliamo insieme se rinnovarlo o reinvestire.\nPorti pure Paolo.", motore: qwen)
        s.aggiungiMessaggio(dopo, cliente: "sofia", parla: false)
        s.approvaRispostaVera(dopo.id)
        s.apri(.vera)
    }

    nonisolated static func preparaFiloLungo(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "laura"
        s.veraPortafoglio = false
        // 16.000 token: la conversazione lunga su Laura esce in parte dalla finestra e Vera tiene il riassunto
        s.dati.impostazioni.vera.finestra = 16_384
        let domande = ["Laura vuole smettere di lavorare a 60 anni: da dove partiamo?", "Niente rischi sulla casa, me l'ha detto due volte.",
                       "Proviamo con 500 € al mese.", "E con 700 € al mese?", "Quanto le manca rispetto alla pensione pubblica?",
                       "Il fondo pensione le conviene?"]
        let risposta = "Con le ipotesi della scheda di Laura, Prisma ha rifatto i conti: a 60 anni con 700 € al mese il divario si chiude quasi del tutto, con 500 € al mese l'obiettivo si sposta verso i 62 anni. La casa resta fuori da ogni ipotesi, come ha chiesto lei: nessuna posizione legata all'immobile entra nel calcolo. "
        for i in 0..<30 {
            s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domande[i % domande.count]), cliente: "laura", parla: false)
            s.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: String(repeating: risposta, count: 5), motore: s.qwen.nome), cliente: "laura", parla: false)
        }
        s.apri(.vera)
    }

    nonisolated static let pagineNormeDiProva = [
        "CODICE DELLE ASSICURAZIONI PRIVATE (testo di prova)\nArt. 176 – Revoca della proposta\nLa proposta può essere revocata fino al momento in cui il contraente è informato che il contratto è concluso.\n",
        "Art. 177 – Diritto di recesso\n1. Il contraente può recedere da un contratto individuale di assicurazione sulla vita entro trenta giorni dal momento in cui è informato che il contratto è concluso.\n2. L'impresa rimborsa il premio entro trenta giorni dalla comunicazione del recesso, trattenuta la parte relativa al rischio corso.\n",
    ]

    nonisolated static func preparaNorme(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.veraPortafoglio = false
        let t = s.biblioteca.aggiungi(titolo: "Codice delle assicurazioni private", sigla: "D.Lgs. 209/2005",
                                      edizione: "testo di prova", file: "codice.pdf", pagine: pagineNormeDiProva)
        let domanda = "Entro quanto un cliente può ripensarci dopo aver firmato una polizza vita?"
        let pezzi = NormeVera.pezzi([t])
        let trovati = RicercaVera.cerca(domanda, in: pezzi, quanti: 3).compactMap { x in NormeVera.citazione(x.pezzo.id, in: [t]).map { (x.pezzo, $0) } }
        let id = trovati.first { $0.1.numero == "177" }?.1.articoloId ?? ""
        s.biblioteca.articoloScelto = id
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domanda), cliente: "giulia", parla: false)
        s.rispondiNorme(#"{"risponde":true,"risposta":"Entro trenta giorni dal momento in cui è informato che il contratto è concluso. L'impresa gli rimborsa il premio entro trenta giorni dalla comunicazione, trattenuta la parte per il rischio già coperto.","articoli":["\#(id)"]}"#,
                        domanda: domanda, trovati: trovati, chiave: "giulia", motore: s.qwen.nome)
        s.apri(.vera)
    }

    nonisolated static func preparaLasciaCadere(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = false
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) { s.dati.clienti[i].codiceFiscale = "RMNSFO65A41H501X" }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("Polizza casa e famiglia.pdf")
        let pagine = ["POLIZZA CASA E FAMIGLIA (fac-simile)\nContraente: Sofia Romano\nCodice fiscale: RMNSFO65A41H501X\nData di scadenza: 30/06/2027\nPremio annuo: 480,00 €"]
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "📄 Polizza casa e famiglia.pdf"), cliente: "marco", parla: false)
        s.rispondiDocumentoCaduto(file, pagine: pagine, pagineOCR: 0, chiave: "marco")
        s.apri(.vera)
    }
}
#endif
