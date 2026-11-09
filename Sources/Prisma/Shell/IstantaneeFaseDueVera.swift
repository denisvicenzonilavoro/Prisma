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
