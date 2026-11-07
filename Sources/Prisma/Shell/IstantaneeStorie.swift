#if os(macOS)
import Foundation

/// Le istantanee di «La tua settimana, il tuo anno» (Design/template-luce-specifica.md §5.2.7, «Luce» giro 5), tutte
/// nello stato finale (`\.modoIstantanea`: numeri completi, colonne cresciute, anello pieno, linea tracciata; barre: le
/// precedenti piene, la corrente a metà). Le storie sono uguali in chiaro e in scuro: niente «-scuro» tranne la 719.
/// - 710: pagina 1 della settimana; 711: gli incontri con gli avatar; 712: «In arrivo» con le colonne;
/// - 713: il traguardo con l'anello e «Festeggialo ›»; 714: la settimana senza dati («Una settimana tranquilla»);
/// - 715: il titolo dell'anno («2026» a 150); 716: il patrimonio con la linea; 717: i clienti nuovi con i pallini;
/// - 718: il patrimonio al primo anno, senza percentuale; 719: la scrivania con l'invito «La tua settimana è pronta».
/// DATI DI PROVA DICHIARATI, solo dentro le scene: gli incontri di questa settimana (una firma il giovedì alle 16, una
/// proposta, un'analisi), due parcelle emesse che scadono martedì e giovedì e le aliquote di prova di Studio; il
/// traguardo è quello dei dati di prova (`TraguardiDiProva`). Le cifre le calcolano i motori.
extension Istantanee {
    nonisolated static var sceneStorie: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("710-storia-settimana-saluto", { s in apriStoriaIstantanea(s, .settimana, pagina: "saluto") }),
            ("711-storia-settimana-incontri", { s in apriStoriaIstantanea(s, .settimana, pagina: "incontri") }),
            ("712-storia-settimana-in-arrivo", { s in apriStoriaIstantanea(s, .settimana, pagina: "inArrivo") }),
            ("713-storia-settimana-traguardo", { s in apriStoriaIstantanea(s, .settimana, pagina: "traguardo") }),
            ("714-storia-settimana-vuota", { s in
                archivioVuoto(s)
                s.dati.parcelle.removeAll()
                s.apriStoria(.settimana)
                s.storia.pagina = max(0, s.storia.pagine.count - 1)
            }),
            ("715-storia-anno-titolo", { s in apriStoriaIstantanea(s, .anno, pagina: "annoTitolo") }),
            ("716-storia-anno-patrimonio", { s in
                rilevazioniDiProva(s)
                apriStoriaIstantanea(s, .anno, pagina: "patrimonio")
            }),
            ("717-storia-anno-nuovi-clienti", { s in apriStoriaIstantanea(s, .anno, pagina: "nuoviClienti") }),
            ("718-storia-anno-primo-anno", { s in
                primoAnnoDiProva(s)
                apriStoriaIstantanea(s, .anno, pagina: "patrimonio")
            }),
            ("719-scrivania-invito-settimana", { s in s.storia.invitoIstantanea = true }),
            ("719-scrivania-invito-settimana-scuro", { s in s.storia.invitoIstantanea = true }),
        ]
    }

    /// Prepara la settimana di prova, apre la storia e va alla pagina con quel nome (la prima se non c'è).
    nonisolated static func apriStoriaIstantanea(_ s: StatoShell, _ tipo: TipoStoria, pagina: String) {
        settimanaDiProva(s)
        s.apriStoria(tipo)
        s.storia.pagina = s.storia.pagine.firstIndex { $0.nome == pagina } ?? 0
    }

    /// Gli incontri di questa settimana, due parcelle e le aliquote di prova (solo nella scena).
    nonisolated static func settimanaDiProva(_ s: StatoShell) {
        let cal = Calendar.current
        let lunedi = MotoreStorie.lunedi(di: Date(), cal: cal)
        func quando(_ giorno: Int, _ ora: Int) -> Date {
            let g = cal.date(byAdding: .day, value: giorno, to: lunedi) ?? lunedi
            return cal.date(bySettingHour: ora, minute: 0, second: 0, of: g) ?? g
        }
        let nuovi: [(String, String, String, Int, Int, TipoAppuntamento)] = [
            ("storia-prova-1", "andrea", "Analisi delle posizioni", 0, 10, .analisi),
            ("storia-prova-2", "marco", "La proposta per la famiglia", 1, 15, .proposta),
            ("storia-prova-3", "laura", "Il punto sul fondo pensione", 2, 11, .revisione),
            ("storia-prova-4", "giulia", "La firma del piano", 3, 16, .firma),
            ("storia-prova-5", "sofia", "Uno sguardo ai prossimi mesi", 4, 9, .revisione),
        ]
        for (id, cliente, titolo, giorno, ora, tipo) in nuovi where s.dati.clienti.contains(where: { $0.id == cliente }) {
            s.dati.appuntamenti.append(Appuntamento(id: id, clienteId: cliente, titolo: titolo, inizio: quando(giorno, ora),
                                                    durataMinuti: 60, luogo: "", note: "", stato: .pianificato, tipo: tipo))
        }
        for (id, cliente, importo, giorno) in [("storia-parcella-1", "laura", 1_200.0, 1), ("storia-parcella-2", "giulia", 900.0, 3)]
            where s.dati.clienti.contains(where: { $0.id == cliente }) {
            var p = Parcella(id: id, clienteId: cliente, data: quando(-10, 12),
                             righe: [RigaParcella(id: id + "-riga", descrizione: "Consulenza", importo: importo)])
            p.stato = .emessa
            p.numero = id
            p.scadenza = quando(giorno, 12)
            s.dati.parcelle.append(p)
        }
        aliquoteDiProva(s)
    }

    /// Le rilevazioni di prova dal 1° gennaio (una al mese, che crescono un poco): la linea del patrimonio si vede.
    nonisolated static func rilevazioniDiProva(_ s: StatoShell) {
        let cal = Calendar.current
        let anno = cal.component(.year, from: Date())
        let mese = cal.component(.month, from: Date())
        for i in s.dati.posizioni.indices where s.dati.posizioni[i].stato == .inEssere && !s.dati.posizioni[i].area.passivo {
            let oggi = s.dati.posizioni[i].valore
            guard oggi > 0 else { continue }
            var rilevazioni: [Rilevazione] = []
            for m in 1..<max(mese, 2) {
                guard let data = cal.date(from: DateComponents(year: anno, month: m, day: 1, hour: 12)) else { continue }
                let quota = 0.9 + 0.1 * Double(m - 1) / Double(max(mese - 1, 1))
                rilevazioni.append(Rilevazione(data: data, controvalore: (oggi * quota).rounded()))
            }
            s.dati.posizioni[i].rilevazioni = rilevazioni
        }
    }

    /// Al primo anno: tutte le posizioni decorrono quest'anno (niente valori prima del 1° gennaio).
    nonisolated static func primoAnnoDiProva(_ s: StatoShell) {
        let cal = Calendar.current
        let anno = cal.component(.year, from: Date())
        let inizio = cal.date(from: DateComponents(year: anno, month: 2, day: 1, hour: 12)) ?? Date()
        for i in s.dati.posizioni.indices {
            s.dati.posizioni[i].decorrenza = inizio
            s.dati.posizioni[i].rilevazioni = nil
        }
    }
}
#endif
