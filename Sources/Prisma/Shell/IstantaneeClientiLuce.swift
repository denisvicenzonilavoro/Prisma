#if os(macOS)
import SwiftUI

/// Le istantanee di Clienti › Potenziali e Passaparola (Design/template-luce-specifica.md §9.2.7, «Luce» giro 12),
/// tutte nello stato finale (numeri completi, barre piene, legami tracciati, nodi al loro posto):
/// - 850: il percorso con gli otto potenziali di prova e Elena Marchi in «Cliente», chiaro e scuro;
/// - 851: nessun potenziale (colonne vuote e l'invito ad aggiungere);
/// - 852: due potenziali senza stima né probabilità («stima da inserire», «—», fuori dai totali);
/// - 853: il dettaglio di Davide Sala aperto;
/// - 854: l'albero del passaparola con i tre clienti presentati del template e il momento giusto di Sofia, chiaro e scuro;
/// - 855: nessun passaparola (nessun presentatore, nessun potenziale);
/// - 856: i clienti fittizi, con il passaparola di prova a tre generazioni;
/// - 857: come 854 con «Riduci movimento».
/// DATI DI PROVA DICHIARATI: `PotenzialiDiProva` (la vista dice «dati di prova»); i tre clienti del template
/// presentati (Chiara Marino, Elena Marchi, Paola Leone) vivono solo nella scena.
extension Istantanee {
    nonisolated static var scenePotenziali: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("850-clienti-potenziali", { s in potenziali(s) }),
            ("850-clienti-potenziali-scuro", { s in potenziali(s) }),
            ("851-clienti-potenziali-vuoto", { s in
                s.dati.potenziali = []
                s.vistaClienti = .potenziali
                s.apri(.clienti)
            }),
            ("852-clienti-potenziali-senza-stime", { s in
                conTemplate(s)
                var elenco = s.dati.potenziali
                for chiave in ["galli", "ricci"] {
                    if let i = elenco.firstIndex(where: { $0.id == PotenzialiDiProva.prefisso + chiave }) {
                        elenco[i].patrimonioStimato = nil
                        elenco[i].probabilita = nil
                    }
                }
                s.dati.potenziali = elenco
                s.vistaClienti = .potenziali
                s.apri(.clienti)
            }),
            ("853-clienti-potenziale-dettaglio", { s in
                conTemplate(s)
                s.potenziali.dettaglioIstantanea = PotenzialiDiProva.prefisso + "sala"
                s.vistaClienti = .potenziali
                s.apri(.clienti)
            }),
            ("854-clienti-passaparola", { s in passaparola(s) }),
            ("854-clienti-passaparola-scuro", { s in passaparola(s) }),
            ("855-clienti-passaparola-vuoto", { s in
                s.dati.potenziali = []
                s.dati.clienti = s.dati.clienti.map { c in
                    var x = c
                    x.presentatoDa = nil
                    x.presentatoIl = nil
                    return x
                }
                s.vistaClienti = .passaparola
                s.apri(.clienti)
            }),
            ("856-clienti-passaparola-fittizi", { s in
                s.dati.carica(ClientiFittizi.completi())
                s.vistaClienti = .passaparola
                s.apri(.clienti)
            }),
            ("857-clienti-passaparola-calmo", { s in
                s.dati.impostazioni.riduciMovimento = true
                passaparola(s)
            }),
        ]
    }

    /// I potenziali di prova (già nei dati di prova), i tre clienti del template presentati e Elena in «Cliente».
    nonisolated private static func conTemplate(_ s: StatoShell) {
        let t = PotenzialiDiProva.clientiDelTemplate()
        s.dati.clienti = s.dati.clienti + t.clienti.filter { c in !s.dati.clienti.contains { $0.id == c.id } }
        s.dati.posizioni = s.dati.posizioni + t.posizioni.filter { p in !s.dati.posizioni.contains { $0.id == p.id } }
        if !s.dati.potenziali.contains(where: { $0.id == PotenzialiDiProva.prefisso + "marchi" }) {
            s.dati.potenziali = s.dati.potenziali + [PotenzialiDiProva.elenaInCliente()]
        }
    }

    nonisolated private static func potenziali(_ s: StatoShell) {
        conTemplate(s)
        s.vistaClienti = .potenziali
        s.apri(.clienti)
    }

    /// Come 850, con il consenso commerciale di Sofia valido (il suo traguardo di ieri dà il momento giusto).
    nonisolated private static func passaparola(_ s: StatoShell) {
        conTemplate(s)
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) {
            s.dati.clienti[i].consensi.marketing = true
            s.dati.clienti[i].consensi.dataMarketing = Calendar.current.date(byAdding: .month, value: -2, to: Date())
        }
        s.vistaClienti = .passaparola
        s.apri(.clienti)
    }
}
#endif
