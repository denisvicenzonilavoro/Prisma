#if os(macOS)
import Foundation

/// Le istantanee di Studio › Palestra, la palestra della trattativa (Design/template-luce-specifica.md §5.3.7, «Luce»
/// giro 5), tutte nello stato finale (`\.modoIstantanea`):
/// - 720: la prima obiezione con le tre risposte e il campo libero, chiaro e scuro;
/// - 721: dopo una risposta: bolla, giudizio «Ottima», replica e l'obiezione dopo, chiaro e scuro;
/// - 722: la fine: anello del punteggio, la frase, cosa ha funzionato, i tre strumenti e «Rifai», chiaro e scuro;
/// - 723: Qwen non pronto; 724: Vera che scrive (puntini e prima riga, ferma);
/// - 725: un cliente con pochi dati (prima di cominciare); 726: nessun cliente scelto.
///
/// TESTI DI PROVA DICHIARATI: obiezioni, risposte e repliche sono frasi scritte qui (riprese dal template, senza cifre
/// inventate: l'unica cifra è l'imposta del 26% delle regole fiscali di Prisma), mai chieste a Qwen. Il cliente è
/// Giulia Rossi dei dati di prova; il profilo è quello che Prisma prepara per Vera (`PalestraVera.scheda`).
extension Istantanee {
    nonisolated static var scenePalestra: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("720-studio-palestra") { s in
            preparaPalestra(s, turni: [turnoPalestra(0)], fase: .tuoTurno, convinta: 40)
        }
        coppia("721-studio-palestra-turno") { s in
            preparaPalestra(s, turni: [turnoPalestra(0, risposta: 2), turnoPalestra(1)], fase: .tuoTurno, convinta: 55)
        }
        coppia("722-studio-palestra-fine") { s in
            preparaPalestra(s, turni: [turnoPalestra(0, risposta: 2), turnoPalestra(1, risposta: 0), turnoPalestra(2, risposta: 0)],
                            fase: .fine, convinta: 75, strumenti: [.lineaVita, .film])
        }
        una("723-studio-palestra-vera-non-pronta") { s in
            preparaPalestra(s, turni: [], fase: .nonPronta(MessaggiDiProva.motivoNonPronta), convinta: 40)
        }
        una("724-studio-palestra-vera-scrive") { s in
            var t = turnoPalestra(0, risposta: 2)
            t.giudizio = nil
            t.replica = nil
            preparaPalestra(s, turni: [t], fase: .veraScrive, convinta: 40, parziale: "Vederlo così mi aiuta: la casa")
        }
        una("725-studio-palestra-profilo-scarno") { s in
            guard let i = s.dati.clienti.firstIndex(where: { $0.id == "andrea" }) else { return }
            s.dati.clienti[i].dataNascita = nil
            s.dati.clienti[i].professione = ""
            s.dati.clienti[i].famiglia = []
            s.dati.clienti[i].profilo.propensione = nil
            s.dati.obiettivi.removeAll { $0.clienteId == "andrea" }
            s.dati.incontri.removeAll { $0.clienteId == "andrea" }
            s.clienteAttivoId = "andrea"
            s.apriStudio(.palestra)
        }
        una("726-studio-palestra-scegli-cliente") { s in
            s.clienteAttivoId = ""
            s.apriStudio(.palestra)
        }
        return scene
    }

    /// Le obiezioni, le suggerite (A, B, C) e le repliche di prova, per turno: la replica è quella della risposta scelta.
    nonisolated static let obiezioniPalestra: [(obiezione: String, suggerite: [String], repliche: [String])] = [
        ("Mi piace l’idea, ma se tra due anni mi servono i soldi per la casa? Restano bloccati?",
         ["Il piano prevede riscatti parziali, come dicono le condizioni del prodotto, e per la casa teniamo un conto a parte.",
          "Non si preoccupi, è un ottimo prodotto.",
          "Guardiamo insieme la linea della vita: anche ritirando una parte per la casa, il progetto arriva lo stesso."],
         ["Ah, quindi non è tutto bloccato. Questo mi tranquillizza.",
          "“Ottimo” lo dicono tutti… vorrei capire meglio.",
          "Vederlo così mi aiuta: la casa resta al primo posto."]),
        ("La banca mi propone un conto senza rischi. Perché dovrei fare altro?",
         ["Il rendimento del conto è lordo: con l’imposta del 26% al netto resta meno, e l’inflazione se ne mangia una parte.",
          "Le banche pensano solo a loro.",
          "Va benissimo per una parte: mettiamoci il fondo per gli imprevisti, e il resto lo facciamo lavorare sul lungo periodo."],
         ["Non ci avevo pensato, al netto è un’altra cosa.",
          "Mah, ho il conto lì da vent’anni…",
          "Così mi sembra equilibrato: una parte tranquilla e una che cresce."]),
        ("Ci devo pensare. Ne parlo con Luca stasera.",
         ["Certo. Le preparo il film del piano da guardare insieme a Luca stasera.",
          "La proposta vale solo fino a venerdì.",
          "Fissiamo già il prossimo incontro con tutti e due?"],
         ["Bello, così glielo faccio vedere senza dover ricordare tutti i numeri.",
          "Così mi mette fretta, però…",
          "Va bene, giovedì sera potremmo esserci entrambi."]),
    ]

    /// Il giudizio di prova di ogni risposta (come il template: 2, 0, 3 · 2, 0, 3 · 3, 0, 2).
    nonisolated static let giudiziPalestra: [[GiudizioPalestra]] = [
        [.buona, .debole, .ottima], [.buona, .debole, .ottima], [.ottima, .debole, .buona],
    ]

    /// Il turno `i` con la risposta `risposta` (nil: ancora da rispondere).
    nonisolated static func turnoPalestra(_ i: Int, risposta: Int? = nil) -> TurnoPalestra {
        let o = obiezioniPalestra[i]
        var t = TurnoPalestra(id: i, obiezione: o.obiezione, suggerite: o.suggerite)
        if let r = risposta {
            t.risposta = o.suggerite[r]
            t.giudizio = giudiziPalestra[i][r]
            t.replica = o.repliche[r]
        }
        return t
    }

    /// Studio › Palestra con Giulia e la conversazione di prova.
    nonisolated static func preparaPalestra(_ s: StatoShell, turni: [TurnoPalestra], fase: StatoPalestra.Fase, convinta: Int,
                                            parziale: String = "", strumenti: [StrumentoPalestra] = []) {
        s.clienteAttivoId = "giulia"
        if let f = s.fonteVera("giulia") {
            s.palestra.prepara(scheda: PalestraVera.scheda(f), turni: turni, fase: fase, convinta: convinta, parziale: parziale,
                               strumenti: strumenti)
        }
        s.apriStudio(.palestra)
    }
}

#endif
