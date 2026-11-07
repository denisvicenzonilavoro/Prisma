#if os(macOS)
import Foundation

/// Le istantanee di Incontri › Il copilota dell'incontro (Design/template-novita-specifica.md §8.7), 580-589 in chiaro e
/// in scuro, tutte nello stato finale (`\.modoIstantanea`: righe complete con le evidenze, schede ferme, onda con la forma
/// fissa del template, contatore dichiarato, spunte già messe):
/// - 580: Giulia con il consenso, «Pronto ad ascoltare», schede vuote; 581: senza consenso (scheda arancio, pulsante spento);
/// - 582: a metà del dialogo, 4 righe e le loro schede, «Ascolto · 00:09 · solo sul Mac»; 583: le 7 righe e tutte le
///   schede, due già confermate («✓ Fatto»);
/// - 584: il verbale aperto con i pallini vuoti; 585: dopo «Conferma tutto», con le spunte e l'avviso;
/// - 586: l'ascolto con Ruby non pronta (le schede dalle regole di Prisma); 587: il microfono non permesso;
/// - 588: nessun incontro in agenda oggi; 589: come 582 con «Riduci movimento».
///
/// DATI DI PROVA DICHIARATI: il dialogo e le schede sono quelli del template (DialogoProvaCopilota.swift), il consenso
/// di Giulia esiste solo dentro queste scene (lo stato dell'istantanea non si salva). Nessun microfono: righe e schede
/// sono scritte già nello stato finale.
extension Istantanee {
    nonisolated static var sceneCopilota: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
            scene.append((nome: nome + "-scuro", prepara: prepara))
        }
        coppia("580-copilota-pronto") { s in
            DialogoProvaCopilota.prepara(s, righe: 0)
            s.copilota.mostraPerIstantanea(fase: .pronto, sessione: nil, secondi: 0, qwenPronto: true)
            s.apri(.incontri)
        }
        coppia("581-copilota-senza-consenso") { s in
            DialogoProvaCopilota.prepara(s, righe: 0, consenso: false)
            s.copilota.mostraPerIstantanea(fase: .pronto, sessione: nil, secondi: 0, qwenPronto: true)
            s.apri(.incontri)
        }
        coppia("582-copilota-ascolto") { s in
            let sid = DialogoProvaCopilota.prepara(s, righe: 4)
            s.copilota.mostraPerIstantanea(fase: .ascolto, sessione: sid, secondi: 9, qwenPronto: true)
            s.apri(.incontri)
        }
        coppia("583-copilota-tutte-le-schede") { s in
            let sid = DialogoProvaCopilota.prepara(s, righe: 7)
            if let sid {
                s.confermaSchedeCopilota(["obiettivo-casa", "polizzaEsterna-vita-intera"], sessione: sid)
            }
            s.copilota.mostraPerIstantanea(fase: .ascolto, sessione: sid, secondi: 17 * 60 + 12, qwenPronto: true)
            s.apri(.incontri)
        }
        coppia("584-copilota-verbale") { s in
            let sid = DialogoProvaCopilota.prepara(s, righe: 7)
            s.copilota.mostraPerIstantanea(fase: .concluso, sessione: sid, secondi: 18 * 60, qwenPronto: true, verbale: true)
            s.apri(.incontri)
        }
        coppia("585-copilota-confermato") { s in
            let sid = DialogoProvaCopilota.prepara(s, righe: 7)
            if let sid { s.confermaSchedeCopilota(nil, sessione: sid) }
            s.copilota.mostraPerIstantanea(fase: .concluso, sessione: sid, secondi: 18 * 60, qwenPronto: true, verbale: true)
            s.apri(.incontri)
        }
        coppia("586-copilota-ruby-non-pronta") { s in
            let sid = DialogoProvaCopilota.prepara(s, righe: 4)
            s.copilota.mostraPerIstantanea(fase: .ascolto, sessione: sid, secondi: 9, qwenPronto: false)
            s.apri(.incontri)
        }
        coppia("587-copilota-microfono-negato") { s in
            DialogoProvaCopilota.prepara(s, righe: 0)
            s.copilota.mostraPerIstantanea(fase: .pronto, sessione: nil, secondi: 0, qwenPronto: true,
                                           problema: "Ruby non ha il permesso di usare il microfono: concedilo in Impostazioni di Sistema › Privacy e sicurezza › Microfono.")
            s.apri(.incontri)
        }
        coppia("588-copilota-nessun-incontro") { s in
            let cal = Calendar.current
            s.dati.appuntamenti.removeAll { cal.isDateInToday($0.inizio) }
            DialogoProvaCopilota.prepara(s, righe: 0)
            s.copilota.mostraPerIstantanea(fase: .pronto, sessione: nil, secondi: 0, qwenPronto: true)
            s.apri(.incontri)
        }
        coppia("589-copilota-calmo") { s in
            s.dati.impostazioni.riduciMovimento = true
            let sid = DialogoProvaCopilota.prepara(s, righe: 4)
            s.copilota.mostraPerIstantanea(fase: .ascolto, sessione: sid, secondi: 9, qwenPronto: true)
            s.apri(.incontri)
        }
        return scene
    }
}
#endif
