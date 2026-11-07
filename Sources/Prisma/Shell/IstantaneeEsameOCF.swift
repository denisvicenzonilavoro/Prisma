#if os(macOS)
import Foundation

/// Le istantanee di Studio › Esame OCF (Design/template-novita-specifica.md §11.7), 530-537 in chiaro e in scuro
/// (537 solo in chiaro), tutte nello stato finale (`\.modoIstantanea`):
/// - 530: le domande di esempio con lo storico di prova, prima domanda aperta;
/// - 531: la domanda sul KID con la risposta C, sbagliata (A verde, C rossa, il caso vero del KID di Giulia);
/// - 532: la domanda sul consolidamento con la risposta A, giusta («Giusto.» e il caso vero della polizza);
/// - 533: l'archivio senza domande (lo stato vero dei dati di prova): anello vuoto, invito a importare;
/// - 534: la data dell'esame impostata e il riquadro del calendario aperto;
/// - 535: il riepilogo di un'importazione con domande nuove, aggiornate e righe scartate;
/// - 536: il ripasso di oggi finito;
/// - 537: la domanda più lunga fra quelle di esempio, per controllare a capo e altezze.
///
/// DATI DI PROVA DICHIARATI: le sette domande sono quelle di esempio di Prisma (`Risorse/ocf-esempio.json`, scritte
/// apposta, non tratte da manuali o quiz). Per vedere anello, barre e fasce servono almeno cinque risposte per materia:
/// le scene aggiungono cinque SEGNAPOSTO per materia («Domanda segnaposto…», risposte «Risposta A»…), palesemente
/// finte, con uno storico di prova a cifre tonde (80%, 60%, 100%, 40%). Segnaposto, storico e riepilogo
/// dell'importazione esistono SOLO dentro queste scene (lo stato dell'istantanea non si salva).
enum CasoEsameOCFIstantanee {
    case prova, finito
}

extension Istantanee {
    nonisolated static var sceneEsameOCF: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("530-studio-ocf", { s in preparaEsameOCF(s, .prova, domanda: idOCFPrima) }),
            ("530-studio-ocf-scuro", { s in preparaEsameOCF(s, .prova, domanda: idOCFPrima) }),
            ("531-studio-ocf-sbagliata", { s in preparaEsameOCF(s, .prova, domanda: idOCFKid, scelta: 2) }),
            ("531-studio-ocf-sbagliata-scuro", { s in preparaEsameOCF(s, .prova, domanda: idOCFKid, scelta: 2) }),
            ("532-studio-ocf-giusta", { s in preparaEsameOCF(s, .prova, domanda: idOCFConsolidamento, scelta: 0) }),
            ("532-studio-ocf-giusta-scuro", { s in preparaEsameOCF(s, .prova, domanda: idOCFConsolidamento, scelta: 0) }),
            // Lo stato vero dei dati di prova: nessuna domanda importata
            ("533-studio-ocf-vuoto", { s in s.apriStudio(.ocf) }),
            ("533-studio-ocf-vuoto-scuro", { s in s.apriStudio(.ocf) }),
            ("534-studio-ocf-data-esame", { s in preparaEsameOCF(s, .prova, domanda: idOCFPrima, dataEsame: true) }),
            ("534-studio-ocf-data-esame-scuro", { s in preparaEsameOCF(s, .prova, domanda: idOCFPrima, dataEsame: true) }),
            ("535-studio-ocf-importazione", { s in preparaEsameOCF(s, .prova, domanda: idOCFPrima, importazione: true) }),
            ("535-studio-ocf-importazione-scuro", { s in preparaEsameOCF(s, .prova, domanda: idOCFPrima, importazione: true) }),
            ("536-studio-ocf-ripasso-finito", { s in preparaEsameOCF(s, .finito) }),
            ("536-studio-ocf-ripasso-finito-scuro", { s in preparaEsameOCF(s, .finito) }),
            ("537-studio-ocf-domanda-lunga", { s in preparaEsameOCF(s, .prova, domanda: idOCFLunga) }),
        ]
    }

    /// Le domande di esempio mostrate dalle scene (Risorse/ocf-esempio.json).
    nonisolated static let idOCFPrima = "esempio-mercato-1"
    nonisolated static let idOCFKid = "esempio-mercato-2"
    nonisolated static let idOCFConsolidamento = "esempio-assicurazioni-2"
    nonisolated static let idOCFLunga = "esempio-previdenza-1"

    /// Studio › Esame OCF con le domande di esempio e, nel caso «prova», i segnaposto con lo storico di prova.
    nonisolated static func preparaEsameOCF(_ s: StatoShell, _ caso: CasoEsameOCFIstantanee, domanda: String? = nil,
                                            scelta: Int? = nil, dataEsame: Bool = false, importazione: Bool = false) {
        let cal = Calendar.current
        let oggi = Date()
        let ieri = cal.date(byAdding: .day, value: -1, to: oggi) ?? oggi
        var a = ArchivioOCF()
        if let i = ImportaOCF.esempio(archivio: a, adesso: ieri) { a.applica(i) }
        let esempi = a.domande
        switch caso {
        case .prova:
            segnapostoOCF(&a, oggi: oggi, cal: cal)
        case .finito:
            // Tutte le domande di esempio già viste oggi, due sbagliate (tornano domani): la coda di oggi è vuota
            let sbagliate: Set<String> = [idOCFKid, idOCFLunga]
            for d in a.domande {
                let giusta = !sbagliate.contains(d.id)
                let risposta = giusta ? d.corretta : (d.corretta + 1) % DomandaOCF.numeroRisposte
                a.rispondi(d.id, scelta: risposta, il: oggi)
            }
        }
        if dataEsame {
            // 107 giorni da oggi, come l'esempio della specifica (3 novembre → 18 febbraio)
            a.dataEsame = cal.date(byAdding: .day, value: 107, to: cal.startOfDay(for: oggi))
        }
        s.dati.ocf = a
        RichiestaIstantaneaOCF.chiedi(s, domanda: domanda, scelta: scelta, riquadroData: dataEsame,
                                      importazione: importazione ? riepilogoOCFDiProva(esempi) : nil)
        s.apriStudio(.ocf)
    }

    /// Cinque segnaposto per materia, con uno storico di prova a cifre tonde: le giuste di due giorni fa tornano fra
    /// qualche giorno, le sbagliate di due giorni fa sono da ripassare oggi.
    nonisolated static func segnapostoOCF(_ a: inout ArchivioOCF, oggi: Date, cal: Calendar) {
        let dueGiorniFa = cal.date(byAdding: .day, value: -2, to: oggi) ?? oggi
        // Giuste su cinque, nell'ordine delle materie di esempio: 80%, 60%, 100%, 40%
        let giustePerMateria = [4, 3, 5, 2]
        for (n, m) in a.materie.enumerated() {
            let giuste = n < giustePerMateria.count ? giustePerMateria[n] : 3
            for k in 1...5 {
                let id = "segnaposto-istantanee-\(m.id)-\(k)"
                a.domande.append(DomandaOCF(id: id, materia: m.id, testo: "Domanda segnaposto \(k) · \(m.nome)",
                                            risposte: ["Risposta A", "Risposta B", "Risposta C", "Risposta D"],
                                            corretta: 0, fonte: "Segnaposto delle istantanee, non una domanda vera",
                                            origine: .esempio, aggiuntaIl: dueGiorniFa))
                a.rispondi(id, scelta: k <= giuste ? 0 : 1, il: dueGiorniFa)
            }
        }
    }

    /// Un riepilogo d'importazione di prova (scena 535): quattro nuove e una aggiornata prese dalle domande di
    /// esempio, due uguali, tre righe scartate con i motivi veri dell'importazione.
    nonisolated static func riepilogoOCFDiProva(_ esempi: [DomandaOCF]) -> ImportazioneOCF {
        var i = ImportazioneOCF()
        i.nuove = Array(esempi.prefix(4))
        i.aggiornate = Array(esempi.dropFirst(4).prefix(1))
        i.uguali = 2
        i.scartate = [RigaScartataOCF(riga: 6, motivo: TestiOCF.mancaRisposta(2)),
                      RigaScartataOCF(riga: 9, motivo: TestiOCF.correttaNonValida("E", daCSV: true)),
                      RigaScartataOCF(riga: 11, motivo: TestiOCF.risposteUguali)]
        i.fonte = "domande-di-prova.csv"
        i.daCSV = true
        return i
    }
}
#endif
