#if os(macOS)
import SwiftUI

/// Le istantanee di Messaggi › Campagne (Design/template-luce-specifica.md §9.4.7, «Luce» giro 12), tutte nello stato
/// finale (pallini già radunati, numeri completi):
/// - 862: i clienti fittizi con i gruppi calcolati dai motori, il primo gruppo scelto, chiaro e scuro;
/// - 863: il gruppo dei titoli di Stato in scadenza nello stesso mese («BTP in scadenza a marzo» del template);
/// - 864: la campagna avviata (le bozze pronte, «Apri la prossima»), chiaro e scuro;
/// - 865: due membri senza consenso commerciale (pillola arancio, fuori dall'invio);
/// - 866: nessun gruppo (la frase al centro);
/// - 867: Vera non è pronta (resta il testo di Prisma, con l'avviso);
/// - 868: il gruppo più grande dei clienti fittizi;
/// - 869: la testata di Messaggi con il segmentato «Messaggi · Campagne».
/// DATI DI PROVA DICHIARATI: i clienti fittizi (`ClientiFittizi`) con i gruppi del template di `CampagneDiProva`
/// (titoli di Stato in scadenza, compleanni tondi, fondi pensione fermi: solo nei dati della scena); il pannello dice
/// «tra i clienti di prova».
extension Istantanee {
    nonisolated static var sceneCampagne: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("862-messaggi-campagne", { s in campagne(s, gruppo: 0) }),
            ("862-messaggi-campagne-scuro", { s in campagne(s, gruppo: 0) }),
            ("863-messaggi-campagne-btp", { s in
                s.dati.carica(CampagneDiProva.datiScena())
                let gruppi = s.gruppiCampagne()
                let btp = gruppi.first { $0.tipo == .scadenzaNelMese }
                s.campagne.scegli(btp?.id ?? (gruppi.count > 1 ? gruppi[1].id : gruppi.first?.id))
                s.campagne.radunati = true
                s.vistaMessaggi = .campagne
                s.apri(.messaggi)
            }),
            ("864-messaggi-campagne-avviata", { s in avviata(s) }),
            ("864-messaggi-campagne-avviata-scuro", { s in avviata(s) }),
            ("865-messaggi-campagne-consenso", { s in
                s.dati.carica(CampagneDiProva.datiScena())
                if let g = s.gruppiCampagne().first {
                    for m in g.membri.prefix(2) {
                        if let i = s.dati.clienti.firstIndex(where: { $0.id == m.clienteId }) {
                            s.dati.clienti[i].consensi.marketing = false
                        }
                    }
                }
                campagne(s, gruppo: 0, carica: false)
            }),
            ("866-messaggi-campagne-vuoto", { s in
                s.dati.carica(ArchivioPezzi.vuoto)
                s.vistaMessaggi = .campagne
                s.apri(.messaggi)
            }),
            ("867-messaggi-campagne-vera-non-pronta", { s in
                s.disponibilitaLocale = .nonDisponibile(MessaggiDiProva.motivoNonPronta)
                campagne(s, gruppo: 0)
            }),
            ("868-messaggi-campagne-fittizi", { s in
                s.dati.carica(CampagneDiProva.datiScena())
                let piuGrande = s.gruppiCampagne().max { $0.membri.count < $1.membri.count }
                s.campagne.scegli(piuGrande?.id)
                s.vistaMessaggi = .campagne
                s.apri(.messaggi)
            }),
            ("869-messaggi-testata-campagne", { s in
                MessaggiDiProva.apri(s, tipo: .riepilogoIncontro, cliente: "giulia")
                s.vistaMessaggi = .messaggi
            }),
        ]
    }

    /// I clienti fittizi con i gruppi del template, Messaggi › Campagne sul gruppo `gruppo` (nell'ordine del motore: dal
    /// più grande).
    nonisolated private static func campagne(_ s: StatoShell, gruppo: Int, carica: Bool = true) {
        if carica { s.dati.carica(CampagneDiProva.datiScena()) }
        let gruppi = s.gruppiCampagne()
        s.campagne.scegli(gruppi.indices.contains(gruppo) ? gruppi[gruppo].id : gruppi.first?.id)
        s.campagne.radunati = true
        s.vistaMessaggi = .campagne
        s.apri(.messaggi)
    }

    /// La campagna del primo gruppo già avviata (le bozze nel dossier dei clienti della scena, mai salvate).
    nonisolated private static func avviata(_ s: StatoShell) {
        campagne(s, gruppo: 0)
        guard let g = s.gruppiCampagne().first else { return }
        let inclusi = g.membri.filter { $0.inclusoDiBase && $0.recapitoMail }.map(\.clienteId)
        if let c = s.avviaCampagna(g, inclusi: inclusi, appuntamenti: s.spaziCampagna().map(\.inizio), tono: .cordiale,
                                   canale: .mail, firmaCanale: .indipendente) {
            s.campagne.avviata = c.id
        }
    }
}
#endif
