#if os(macOS)
import Foundation

/// Le istantanee della fase 2 di Vera (Design/template-vera.html), chiare e scure, senza Qwen:
/// «Il cliente in 30 secondi» di Marco, una risposta del «Codice in tasca» con l'articolo citato, la scheda di
/// «Lascia cadere qui» per una polizza riconosciuta dal codice fiscale, e la Biblioteca delle norme.
extension Istantanee {
    nonisolated static var sceneFaseDueVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("488-vera-trenta-secondi", { s in preparaTrenta(s) }),
            ("488-vera-trenta-secondi-scuro", { s in preparaTrenta(s) }),
            ("489-vera-codice-in-tasca", { s in preparaNorme(s) }),
            ("489-vera-codice-in-tasca-scuro", { s in preparaNorme(s) }),
            ("490-vera-lascia-cadere", { s in preparaLasciaCadere(s) }),
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
