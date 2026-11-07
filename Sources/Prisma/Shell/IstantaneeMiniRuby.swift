#if os(macOS)
import Foundation

/// Le istantanee della mini finestra di Ruby: i cinque stati del template (Design/ruby-mini.html), chiari e scuri,
/// sopra Posizioni di Giulia Rossi. Le cifre vengono dai calcoli di Prisma sui dati di prova.
extension Istantanee {
    nonisolated static let domandaMiniRuby = "Cosa ha Giulia in scadenza nei prossimi mesi?"

    nonisolated static var sceneMiniRuby: [(nome: String, prepara: (StatoShell) -> Void)] {
        let stati: [(String, (StatoShell) -> Void)] = [
            ("240-ruby-mini-ascolta", { s in
                preparaMiniRuby(s)
                s.voceIstantanea = StatoVoce(ascolta: true, trascritto: domandaMiniRuby, livello: 0.55)
                s.apriMiniRuby(.ascolta)
            }),
            ("241-ruby-mini-pensa", { s in
                preparaMiniRuby(s)
                s.apriMiniRuby(.scrivi)
                s.miniRuby.pensa(domandaMiniRuby, passi: StatoMiniRuby.passi(domanda: domandaMiniRuby, fonte: s.fonteRuby("giulia"), modalita: .lavoro))
            }),
            ("242-ruby-mini-risposta", { s in
                preparaMiniRuby(s)
                s.apriMiniRuby(.scrivi)
                // Lo spunto delle scadenze: la risposta preparata è breve e sotto si vedono linea del tempo e righe
                s.inviaMiniRuby(DomandaMiniRuby(testo: domandaMiniRuby, spunto: .scadenze))
                // Nell'app la risposta della mini finestra la scrive Qwen, breve (Ruby/Istruzioni/mini.md); qui, senza
                // Qwen, una risposta breve come quella: le cifre sotto restano quelle calcolate da Prisma
                let m = s.miniRuby
                let totale = m.cifre.linea?.totale ?? ""
                m.rispondi(testo: "Nei prossimi 12 mesi Giulia ha 2 posizioni in scadenza, per \(totale) in tutto: il conto deposito a gennaio e il piano di risparmio a marzo. È liquidità che può andare verso l'anticipo della casa: ne parlerei con lei prima di gennaio.",
                           titolo: nil, cifre: m.cifre, inArrivo: false)
            }),
            ("243-ruby-mini-scrivi", { s in
                preparaMiniRuby(s)
                s.apriMiniRuby(.scrivi)
            }),
            ("244-ruby-mini-nonpronta", { s in
                preparaMiniRuby(s)
                // Qwen non c'è: niente risposte preparate, la domanda resta da parte
                s.rispostePreparate = false
                s.apriMiniRuby(.scrivi)
                s.inviaMiniRuby(DomandaMiniRuby(testo: domandaMiniRuby))
            }),
        ]
        return stati.flatMap { nome, prepara in [(nome: nome, prepara: prepara), (nome: nome + "-scuro", prepara: prepara)] }
    }

    /// Giulia in Posizioni, due scadenze nei prossimi mesi (una per canale) e due domande recenti.
    nonisolated static func preparaMiniRuby(_ s: StatoShell) {
        let cal = Calendar.current
        let oggi = Date()
        func tra(_ mesi: Int, giorni: Int) -> Date? {
            cal.date(byAdding: .day, value: giorni, to: cal.date(byAdding: .month, value: mesi, to: oggi) ?? oggi)
        }
        for (id, mesi, giorni) in [("pos-giulia-conto-corrente-e-conto-deposito", 2, 12), ("pos-giulia-piano-di-risparmio-rivalutabile", 4, 3)] {
            if let i = s.dati.posizioni.firstIndex(where: { $0.id == id }) { s.dati.posizioni[i].scadenza = tra(mesi, giorni: giorni) }
        }
        s.rispostePreparate = true
        var ieri = MessaggioRuby(autore: .utente, testo: "Differenza tra i due PIP di Marco Bianchi")
        ieri.data = cal.date(byAdding: .day, value: -1, to: oggi) ?? oggi
        var prima = MessaggioRuby(autore: .utente, testo: "Cosa dice il KID del fondo Orizzonte?")
        prima.data = cal.date(byAdding: .day, value: -3, to: oggi) ?? oggi
        s.aggiungiMessaggio(prima, cliente: "giulia", parla: false)
        s.aggiungiMessaggio(ieri, cliente: "marco", parla: false)
        s.clienteAttivoId = "giulia"
        s.apri(.posizioni)
        // Lo schermo delle istantanee (900 punti): la scheda si allunga fin quasi in fondo, come sul Mac
        let m = Tema.Misura.MiniRuby.self
        s.miniRuby.altezzaMassima = Istantanee.altezzaSchermoMiniRuby - Tema.Misura.barra - m.distanzaBarra - m.margineSchermo - m.margineOmbraSotto
    }

    nonisolated static let altezzaSchermoMiniRuby: CGFloat = 900
}
#endif
