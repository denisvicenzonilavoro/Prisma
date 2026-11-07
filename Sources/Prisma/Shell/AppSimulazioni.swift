import SwiftUI

/// App Simulazioni (.os-app-simulations): il laboratorio delle ipotesi. Sul Mac è accorpata negli strumenti
/// di Analisi 360 (`StrumentiAnalisi360`); qui resta l'involucro di iPhone e iPad: cornice ed elenco laterale
/// attorno alle stesse viste (`SimulatoreIpotesi`, `ScenariSalvati`, `SchedaTFR`).
struct AppSimulazioni: View {
    @EnvironmentObject var stato: StatoShell

    private var cliente: String { stato.clienteAttivoId }
    private var salvate: [Simulazione] { stato.simulazioniCliente(cliente) }

    /// Nuova ipotesi: parte dalla liquidità del cliente (la logica sta nel simulatore).
    static func nuova(per cliente: String, stato: StatoShell) -> Simulazione {
        SimulatoreIpotesi.nuova(per: cliente, stato: stato)
    }

    var body: some View {
        CorniceStrumento(
            notaStato: "Calcoli eseguiti in locale · rendimento costante, nessuna previsione o raccomandazione",
            notaDestra: "\(salvate.count) \(salvate.count == 1 ? "scenario" : "scenari") nel dossier"
        ) {
            rail
        } contenuto: {
            // Le stesse viste di Analisi 360 sul Mac, nel tema Apple
            Group {
                switch stato.schedaSimulazioni {
                case .simulatore: SimulatoreIpotesi()
                case .scenari: ScenariSalvati()
                case .tfr: StrumentoTFR()
                }
            }
            .strumentiApple()
        }
    }

    // MARK: - Elenco laterale

    @ViewBuilder private var rail: some View {
        DossierRail()
        EtichettaRail(testo: "Vista")
        SegmentiAnalisi(opzioni: [(SchedaSimulazioni.simulatore, "Simulatore"), (.scenari, "Scenari"), (.tfr, "TFR")],
                        selezione: $stato.schedaSimulazioni)
        if stato.schedaSimulazioni != .tfr {
            railPosizioni
        }
        CollegatiRail(app: [.posizioni, .analisi360], strumenti: [.confronto])
    }

    /// «Parti da una posizione»: le posizioni proiettabili del cliente (anche nel menu della testata del simulatore).
    @ViewBuilder private var railPosizioni: some View {
        let posizioni = stato.posizioniCliente(cliente).filter { $0.area.proiettabile && $0.stato != .chiusa }
        let daPosizione = stato.bozzaSimulazione.flatMap { $0.clienteId == cliente ? $0.posizioneId : nil }
        if !posizioni.isEmpty {
            EtichettaRail(testo: "Parti da una posizione")
            VStack(spacing: 0) {
                ForEach(posizioni) { p in
                    VoceNavigazione(titolo: (p.stato == .proposta ? "Proposta · " : "") + p.nome, colore: Colori.Analisi.area(p.area),
                                    attiva: daPosizione == p.id && stato.schedaSimulazioni == .simulatore) {
                        stato.simula(p)
                    }
                }
            }
        }
    }
}

/// Modulo per dare un nome allo scenario prima di salvarlo.
struct ModuloScenario: View {
    @Environment(\.dismiss) var chiudi
    @State var bozza: Simulazione
    let salva: (Simulazione) -> Void

    var body: some View {
        CorniceModulo(titolo: "Salva nel dossier") {
            VStack(alignment: .leading, spacing: 14) {
                CampoModulo(etichetta: "Nome dello scenario") {
                    TextField("Per esempio Piano 10 anni", text: $bozza.titolo).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Ipotesi") {
                    Text("\(Formati.euro(bozza.capitale)) iniziali · \(Formati.euro(bozza.versamentoMensile))/mese · \(bozza.anni) anni · \(Formati.percentuale(bozza.rendimento)) annuo · costi \(Formati.percentuale(bozza.costoAnnuo)) all'anno")
                        .font(Tipo.campoValore)
                        .foregroundColor(Colori.Rubrica.secondario)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } piede: {
            Spacer()
            Button("Annulla") { chiudi() }
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button("Salva scenario") {
                var s = bozza
                s.titolo = s.titolo.trimmingCharacters(in: .whitespacesAndNewlines)
                salva(s)
                chiudi()
            }
            .buttonStyle(StileBlu())
            .disabled(bozza.titolo.trimmingCharacters(in: .whitespaces).isEmpty)
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: 520, height: 260)
    }
}
