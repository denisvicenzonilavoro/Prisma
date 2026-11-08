#if os(macOS)
import Foundation

/// Le istantanee di Studio › Spese, «Chilometri, spese e scadenze» (Design/template-luce-specifica.md §6.3.7, «Luce»
/// giro 9), tutte nello stato finale (`\.modoIstantanea`):
/// - 780: la scheda con i dati di prova (il totale vero delle spese), chiaro e scuro;
/// - 781: niente km, niente spese, niente scadenze: i tre stati vuoti con i pulsanti, chiaro e scuro;
/// - 782: visite senza km («almeno …» e la riga arancio); 783: lo scontrino appena inquadrato in cima, con il totale
///   aggiornato; 784: uno scontrino letto da controllare; 785: il pacchetto pronto, chiaro e scuro;
/// - 786: il dettaglio di una spesa con lo scontrino; 787: Impostazioni › Studio sui chilometri e le spese;
/// - 788: la finestra stretta, le tre card in colonna. (789, l'iPhone, non c'è: decisione 34, niente iPhone in questo giro.)
///
/// DATI DI PROVA DICHIARATI: le visite (appuntamenti con id «prova-»), i km di andata e ritorno dei cinque clienti di
/// prova, la partenza e le ore richieste (30, il valore dimostrativo del template) esistono SOLO dentro queste scene: lo
/// stato delle istantanee non si salva. Spese, corsi e scadenze non fiscali sono quelli di `SpeseDiProva`.
extension Istantanee {
    nonisolated static var sceneSpese: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("780-studio-spese") { s in
            speseDiProvaScena(s)
            s.apriStudio(.spese)
        }
        coppia("781-studio-spese-vuoto") { s in
            s.dati.speseStudio = ArchivioSpese()
            s.apriStudio(.spese)
        }
        una("782-studio-spese-km-mancanti") { s in
            speseDiProvaScena(s)
            s.dati.impostazioni.studio.spese.kmAndataRitornoPerCliente["sofia"] = nil
            if let i = s.dati.appuntamenti.firstIndex(where: { $0.id == SpeseDiProva.prefisso + "visita-21" }) {
                s.dati.appuntamenti[i].presso = nil
            }
            s.apriStudio(.spese)
        }
        una("783-studio-spese-scontrino-nuovo") { s in
            speseDiProvaScena(s)
            let nuova = SpesaStudio(id: SpeseDiProva.prefisso + "spesa-nuova", data: giornoScena(s, 30), descrizione: "Pranzo con cliente",
                                    esercente: "Trattoria di prova", importo: 36, categoria: .pasti, scontrino: "prova-scontrino.jpg",
                                    letta: true, nota: SpeseDiProva.nota)
            s.dati.speseStudio.spese.append(nuova)
            s.studioSpese.nuovaSpesaId = nuova.id
            s.apriStudio(.spese)
        }
        una("784-studio-spese-scontrino-da-controllare") { s in
            speseDiProvaScena(s)
            let incerta = SpesaStudio(id: SpeseDiProva.prefisso + "spesa-incerta", data: giornoScena(s, 30), descrizione: "Parcheggio",
                                      importo: 4, categoria: .parcheggio, scontrino: "prova-scontrino.jpg", letta: true,
                                      daControllare: true, nota: SpeseDiProva.nota)
            s.dati.speseStudio.spese.append(incerta)
            s.studioSpese.nuovaSpesaId = incerta.id
            s.apriStudio(.spese)
        }
        coppia("785-studio-spese-pacchetto") { s in
            speseDiProvaScena(s)
            let mese = s.studioSpese.mese(impostazioni: s.dati.impostazioni.studio.spese)
            let nome = PacchettoCommercialista.nome(mese: mese) + ".zip"
            s.studioSpese.pacchetto = .pronto(url: URL(fileURLWithPath: "/" + nome), nome: nome,
                                              descrizione: PacchettoCommercialista.descrizione(scontrini: 0, pdf: true))
            s.apriStudio(.spese)
        }
        una("786-studio-spese-dettaglio-spesa") { s in
            speseDiProvaScena(s)
            let id = SpeseDiProva.prefisso + "spesa-pranzo"
            if let i = s.dati.speseStudio.spese.firstIndex(where: { $0.id == id }) {
                s.dati.speseStudio.spese[i].scontrino = "prova-scontrino.jpg"
                s.dati.speseStudio.spese[i].esercente = "Trattoria di prova"
                s.dati.speseStudio.spese[i].canale = .indipendente
            }
            s.studioSpese.foglio = .spesa(id)
            s.apriStudio(.spese)
        }
        una("787-impostazioni-studio-spese") { s in
            speseDiProvaScena(s)
            s.schedaImpostazioni = .studio
            s.studioSpese.impostazioniInCima = true
            s.apri(.impostazioni)
        }
        una("788-studio-spese-stretta") { s in
            speseDiProvaScena(s)
            s.apriStudio(.spese)
        }
        return scene
    }

    /// Un giorno del mese mostrato (fermato all'ultimo giorno del mese).
    nonisolated static func giornoScena(_ s: StatoShell, _ g: Int, mesiPrima: Int = 0) -> Date {
        let cal = Calendar.current
        let mostrato = s.studioSpese.mese(impostazioni: s.dati.impostazioni.studio.spese)
        let mese = cal.date(byAdding: .month, value: -mesiPrima, to: mostrato) ?? mostrato
        let giorni = cal.range(of: .day, in: .month, for: mese)?.count ?? 28
        var c = cal.dateComponents([.year, .month], from: mese)
        (c.day, c.hour) = (min(g, giorni), 10)
        return cal.date(from: c) ?? mese
    }

    /// Le visite, i km e le ore di prova della scena (dati dimostrativi, mai salvati).
    nonisolated static func speseDiProvaScena(_ s: StatoShell) {
        var imp = s.dati.impostazioni.studio.spese
        imp.partenza = "Studio (dati di prova)"
        imp.kmAndataRitornoPerCliente = ["giulia": 14, "laura": 14, "marco": 41, "sofia": 18, "andrea": 22]
        imp.oreAggiornamentoAnno[Calendar.current.component(.year, from: Date())] = 30
        s.dati.impostazioni.studio.spese = imp
        // I giri del mese mostrato: il 28 unisce due clienti e l'utente l'ha corretto a mano (47 invece di 55)
        let giri: [(Int, [String])] = [(3, ["giulia", "laura"]), (8, ["marco"]), (14, ["sofia", "andrea"]), (21, ["andrea"]),
                                       (24, ["laura"]), (28, ["giulia", "marco"])]
        var visite: [Appuntamento] = []
        for (g, clienti) in giri {
            for (i, c) in clienti.enumerated() {
                var inizio = giornoScena(s, g)
                inizio = Calendar.current.date(byAdding: .hour, value: i * 3, to: inizio) ?? inizio
                visite.append(Appuntamento(id: SpeseDiProva.prefisso + "visita-\(g)" + (i == 0 ? "" : "-\(i)"), clienteId: c,
                                           titolo: "Visita (dati di prova)", inizio: inizio, durataMinuti: 60, luogo: "", note: "",
                                           stato: .concluso, tipo: .revisione, presso: .cliente))
            }
        }
        // I mesi prima, per le colonne dei km
        let perMese = [2, 3, 3, 2, 3, 3, 1, 1, 3]
        let clienti = ["giulia", "marco", "sofia", "andrea", "laura"]
        for (m, n) in perMese.enumerated() {
            for k in 0..<n {
                let c = clienti[(m + k) % clienti.count]
                visite.append(Appuntamento(id: SpeseDiProva.prefisso + "visita-prima-\(m)-\(k)", clienteId: c, titolo: "Visita (dati di prova)",
                                           inizio: giornoScena(s, 5 + k * 7, mesiPrima: 9 - m), durataMinuti: 60, luogo: "", note: "",
                                           stato: .concluso, tipo: .revisione, presso: .cliente))
            }
        }
        s.dati.appuntamenti.append(contentsOf: visite)
        s.dati.impostazioni.studio.spese.kmCorretti[ImpostazioniSpese.chiaveGiorno(giornoScena(s, 28))] = 47
    }
}
#endif
