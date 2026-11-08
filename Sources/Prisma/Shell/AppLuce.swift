import SwiftUI

// Le tre app di lavoro della versione «Luce» (Design/template-luce-specifica.md §1.2): Territorio, Pratiche e
// Biblioteca. Nel giro 1 (le fondamenta) hanno la testata del template (titolo, occhiello, segmentati) e lo stato
// sobrio «arriva con un prossimo aggiornamento» con la novità che vivrà nella scheda scelta; il contenuto arriva con i
// loro giri (Pratiche 3 e 10, Biblioteca 6, Territorio 11). La Sala sta in AppSala.swift.

/// Territorio: i segmenti «Oggi · La crescita · Il giro di domani» nella testata.
struct AzioniTerritorio: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        SegmentatoPillola(selezione: Bindable(stato).vistaTerritorio, valori: VistaTerritorio.allCases, titolo: { $0.titolo })
            .fixedSize()
    }
}

/// Pratiche: i segmenti «Proposta · Moduli · Dopo la firma · Sinistri» nella testata.
struct AzioniPratiche: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        SegmentatoPillola(selezione: Bindable(stato).schedaPratiche, valori: SchedaPratiche.allCases, titolo: { $0.titolo })
            .fixedSize()
    }
}

/// Il contenuto di Territorio (giro 11): per ora lo stato «in arrivo».
struct AppTerritorio: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        InArrivoAppLuce(app: .territorio, glifo: .mappa, titolo: stato.vistaTerritorio.titolo,
                        frase: frase(stato.vistaTerritorio),
                        nota: "Senza mandare gli indirizzi a nessun servizio: comuni e distanze si calcolano sul Mac.")
    }

    private func frase(_ v: VistaTerritorio) -> String {
        switch v {
        case .oggi: return "I tuoi clienti come luci sulla mappa della tua zona."
        case .crescita: return "Come si è allargata la tua clientela, anno dopo anno."
        case .giro: return "Il giro di domani, con chi è lungo la strada."
        }
    }
}

/// Il contenuto di Pratiche (giri 3 e 10): per ora lo stato «in arrivo» della scheda scelta.
struct AppPratiche: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        if stato.schedaPratiche == .dopoLaFirma {
            // Giro 3: le pratiche dopo la firma (PraticheDopoFirma.swift)
            PraticheDopoFirma()
        } else if stato.schedaPratiche == .proposta {
            // «Luce», giro 3: la proposta si costruisce da sola (Shell/PratichePropostaApple.swift)
            PratichePropostaApple()
        } else {
            let n = stato.schedaPratiche.novita
            InArrivoAppLuce(app: .pratiche, glifo: n.glifo, titolo: n.titolo, frase: n.frase + ".",
                            nota: "Il canale resta sempre in vista: Alleanza e consulenza indipendente, mai mescolati.",
                            canali: true)
        }
    }
}

/// Lo stato sobrio di un'app di Luce il cui contenuto arriva in un giro successivo: l'icona dell'app, il tassello della
/// novità della scheda, il titolo, la frase e «Arriva con un prossimo aggiornamento», con una nota onesta su come
/// funzionerà. Entra a cascata.
struct InArrivoAppLuce: View {
    let app: AppPrisma
    let glifo: GlifoLuce
    let titolo: String
    let frase: String
    let nota: String
    var canali = false

    private typealias A = Tema.Apple.AppLuce

    var body: some View {
        VStack(spacing: A.spazio) {
            HStack(spacing: A.spazio) {
                IconaApp(app: app, lato: A.icona)
                TasselloGlifo(glifo: glifo, lato: A.icona, raggio: Tema.Apple.Raggio.voce)
            }
            .entrataCascata(0)
            Text(titolo)
                .carattereApple(A.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .entrataCascata(1)
            Text(frase)
                .carattereApple(A.testo)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .entrataCascata(2)
            Text("Arriva con un prossimo aggiornamento.")
                .carattereApple(A.testo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .entrataCascata(3)
            Text(nota)
                .carattereApple(A.nota)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .entrataCascata(4)
            if canali {
                HStack(spacing: A.spazio) {
                    EtichettaCanale(canale: .alleanza)
                    EtichettaCanale(canale: .indipendente)
                }
                .entrataCascata(5)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: A.larghezzaMessaggio)
        .padding(A.padding)
        .superficieApple(A.superficie, raggio: A.raggio)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
