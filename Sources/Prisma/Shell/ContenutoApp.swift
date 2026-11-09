import SwiftUI
import UniformTypeIdentifiers

/// Contenuto di una finestra: l'intestazione dell'app e la sua vista.
struct ContenutoApp: View {
    let app: AppPrisma

    var body: some View {
        VStack(spacing: 0) {
            IntestazioneApp(app: app) { azioni }
            Group {
                switch app {
                case .clienti: AppClienti()
                case .posizioni: AppPosizioni()
                case .impostazioni: AppImpostazioni()
                case .agenda: AppAgenda()
                case .attivita: AppAttivita()
                case .simulazioni: AppSimulazioni()
                case .confronti: AppConfronti()
                case .analisi360: AppAnalisi360()
                case .vera: AppVera()
                case .incontri: AppIncontri()
                case .prodotti: AppProdotti()
                case .obiettivi: AppObiettivi()
                case .documenti: AppDocumenti()
                case .presentazioni: AppProspetti()
                case .ricerca: AppRicerca()
                case .note: AppNote()
                // Le app di «Orizzonte»: Studio (Shell/Studio*.swift), Messaggi (giro 3, Shell/AppMessaggi.swift),
                // Mercato (giro 7, Shell/AppMercato.swift)
                case .studio: AppStudio()
                case .messaggi: AppMessaggi()
                case .mercato: AppMercato()
                // Le app di «Luce» (giro 1: testate e stati «in arrivo»; la Sala con griglia e palco)
                case .sala: AppSala()
                case .territorio: AppTerritorio()
                case .pratiche: AppPratiche()
                case .biblioteca: AppBiblioteca()
                default: AppSegnaposto(app: app)
                }
            }
            // iPhone e iPad: la larghezza che resta all'app va nell'ambiente (`larghezzaApp`), così colonne e
            // pannelli del Mac si adattano (ImpaginazioneAdattiva). Sul Mac non fa niente.
            .misuraLarghezzaApp()
            // La Ricerca va da bordo a bordo, come una tabella di iOS
            .padding(.horizontal, app == .ricerca ? 0 : Misure.IntestazioneApp.margineOrizzontale)
            .padding(.vertical, app == .ricerca ? 0 : Misure.IntestazioneApp.margineContenuto)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Un contenuto più grande della finestra non si allarga né si centra fuori dai bordi:
            // l'intestazione resta al suo posto e l'eccesso finisce in basso e a destra, dove la finestra
            // lo taglia (ogni app scorre dentro i suoi pannelli: vedi l'elenco laterale di Posizioni)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .background(sfondo)
        }
    }
}

extension ContenutoApp {
    @ViewBuilder var sfondo: some View {
        switch app {
        case .impostazioni: FondoRighe()
        case .clienti: Colori.Rubrica.fondoApp
        case .note: Gradienti.fondoNote
        case .agenda: Colori.Agenda.fondoApp
        case .incontri: Gradienti.fondoIncontri
        case .vera: Gradienti.linoVera
        case .attivita: Gradienti.linoAttivita
        default: Colori.IntestazioneApp.corpo
        }
    }

    /// Pulsanti a destra nell'intestazione dell'app.
    @ViewBuilder var azioni: some View {
        switch app {
        case .clienti: AzioniClienti()
        case .posizioni: AzioniPosizioni()
        // «Luce» giro 13: «Nota dall’iPhone» (Mac) e «Nota veloce» (iPad) (AzioniIncontri.swift)
        case .incontri: AzioniIncontri()
        case .note: AzioneNuovaNota()
        case .vera: AzioniVera()
        // Il segmentato a pillola delle quattro schede di Studio (StudioApp.swift)
        case .studio: AzioniStudio()
        // La ricerca per ISIN e le soglie degli avvisi (AppMercato.swift)
        case .mercato: AzioniMercato()
        // «Luce»: i segmenti di Territorio e Pratiche e le pillole dei clienti della Sala (AppLuce.swift, AppSala.swift)
        case .territorio: AzioniTerritorio()
        case .pratiche: AzioniPratiche()
        case .sala: AzioniSala()
        // «Luce» giro 12: il segmentato «Messaggi · Campagne» (MessaggiCampagne.swift)
        case .messaggi: AzioniMessaggi()
        default: EmptyView()
        }
    }
}

/// La testata di Clienti («Luce» giri 12 e 13, §9.1, decisione 1.4): il segmentato «Rubrica · Potenziali · Passaparola»
/// (giro 12) e, nella Rubrica, il menu «…» con «Importa…» e «Incolla da Excel» (non si perdono) e il pulsante blu
/// «Nuovo cliente» con il glifo `scan`, che apre la scena della carta d'identità (sul Mac, anche con ⌘N: la testata c'è
/// solo con Clienti davanti) o la schermata della fotocamera (iPad).
struct AzioniClienti: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        HStack(spacing: Misure.IntestazioneApp.spazioAzioni) {
            // «Luce» giro 12: «Rubrica · Potenziali · Passaparola» (non in modalità cliente: mostrano altre persone)
            if !stato.inModoCliente {
                SegmentatoPillola(selezione: Bindable(stato).vistaClienti, valori: VistaClienti.allCases, titolo: { $0.titolo })
                    .fixedSize()
            }
            if stato.inModoCliente || stato.vistaClienti == .rubrica {
                pulsantiRubrica
            }
        }
    }

    /// Il menu «…» (Importa, Incolla da Excel) e il blu «Nuovo cliente»: solo nella Rubrica.
    @ViewBuilder private var pulsantiRubrica: some View {
        Menu {
            Button { stato.importaClientiDaFile() } label: {
                Label("Importa…", systemImage: "square.and.arrow.down")
            }
            .disabled(stato.solaLettura)
            Button { stato.incollaDaExcel(posizioni: false) } label: {
                Label("Incolla da Excel", systemImage: "doc.on.clipboard")
            }
            .disabled(stato.solaLettura)
        } label: {
            Image(systemName: "ellipsis")
                .accessibilityLabel(Text("Altro"))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Importa clienti da un file (vCard, Excel o CSV) o incollali da Excel")
        // Il blu dell'app: la cosa da fare qui
        Button(action: nuovoCliente) {
            Label {
                Text("Nuovo cliente")
            } icon: {
                GlifoLuceVista(glifo: .scan, lato: Tema.Apple.NuovoCliente.Scheda.glifoTestata, colore: Tema.Colore.Componenti.testoSuColore)
            }
        }
        .buttonStyle(StileAqua())
        .modifier(ScorciatoiaNuovoCliente())
        .help("Nuovo cliente: inquadra la carta d’identità con l’iPhone o trascina una foto, oppure scrivi a mano")
    }

    private func nuovoCliente() {
        #if os(macOS)
        stato.apriNuovoCliente()
        #else
        stato.nuovoCliente.apriTelefono()
        #endif
    }
}

/// ⌘N solo sul Mac (nessun altro ⌘N: PrismaApp toglie `.newItem`; la testata c'è solo con Clienti davanti).
private struct ScorciatoiaNuovoCliente: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.keyboardShortcut("n", modifiers: .command)
        #else
        content
        #endif
    }
}

/// Intestazione dentro la finestra (.os-app-header): titolo, occhiello, «Come si usa» e azioni a destra.
/// Se lo spazio non basta toglie prima l'occhiello, poi lascia ai pulsanti di vetro la sola icona (con il
/// suggerimento): mai una parola tagliata dentro un pulsante. Il blu tiene sempre la scritta.
struct IntestazioneApp<Azioni: View>: View {
    let app: AppPrisma
    @ViewBuilder let azioni: () -> Azioni

    var body: some View {
        ViewThatFits(in: .horizontal) {
            riga(occhiello: true, soloIcona: false)
            riga(occhiello: false, soloIcona: false)
            riga(occhiello: false, soloIcona: true)
        }
        .padding(.horizontal, Misure.IntestazioneApp.margineOrizzontale)
        .padding(.vertical, Misure.IntestazioneApp.margineVerticale)
        .frame(minHeight: Misure.IntestazioneApp.altezzaMinima)
        .background(Gradienti.intestazioneApp)
        .bordoBasso(Colori.IntestazioneApp.bordo)
    }

    /// Una delle tre versioni della riga. `azioni()` si costruisce tre volte: le azioni dell'intestazione non
    /// hanno stato proprio (né fogli né importazioni: li apre `stato`), quindi si può.
    private func riga(occhiello: Bool, soloIcona: Bool) -> some View {
        HStack(alignment: .center, spacing: Misure.IntestazioneApp.spazio) {
            Text(app.titoloIntestazione)
                .font(Tipo.appTitolo)
                .foregroundColor(Colori.IntestazioneApp.titolo)
                .lineLimit(1)
            if occhiello {
                if app == .mercato {
                    // L'occhiello lo scrive il motore del mercato: «Aggiornato oggi alle 18:00» (AppMercato.swift)
                    OcchielloMercato()
                } else {
                    Text(app.occhiello.uppercased())
                        .font(Tipo.appOcchiello)
                        .foregroundColor(Colori.IntestazioneApp.occhiello)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Misure.IntestazioneApp.spazio)
            Group {
                PulsanteComeSiUsa(app: app)
                azioni()
            }
            .environment(\.pulsantiSoloIcona, soloIcona)
        }
    }
}

/// Riquadro delle app non ancora sviluppate.
struct AppSegnaposto: View {
    let app: AppPrisma

    private var mostraCanali: Bool {
        [.posizioni, .analisi360, .prodotti, .confronti, .simulazioni, .obiettivi].contains(app)
    }

    var body: some View {
        VStack(spacing: 12) {
            IconaApp(app: app, lato: Misure.Scrivania.icona)
            Text(app.titolo)
                .font(Tipo.pannelloTitolo)
                .foregroundColor(Colori.Pannello.titolo)
            Text(app.sottotitolo)
                .font(Tipo.pannelloTesto)
                .foregroundColor(Colori.Pannello.testoSecondario)
            Text(app.inArrivo)
                .font(Tipo.pannelloTesto)
                .foregroundColor(Colori.Pannello.testo)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 380)
            if mostraCanali {
                HStack(spacing: 10) {
                    EtichettaCanale(canale: .alleanza)
                    EtichettaCanale(canale: .indipendente)
                }
                .padding(.top, 6)
            }
        }
        .padding(28)
        .vetro(.sottile, forma: .arrotondata(Tema.Raggio.scheda))
    }
}

struct AzioniPosizioni: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        HStack(spacing: Misure.IntestazioneApp.spazioAzioni) {
            // Un lavoro del consulente su più clienti: in modo cliente non c'è
            if !stato.inModoCliente {
                Button {
                    // Con un file aperto si torna al suo elenco, altrimenti alla griglia dei valori fermi
                    let conFile = stato.aggiornaValori.map { !$0.righe.isEmpty } ?? false
                    stato.apriAggiornaValori(scheda: conFile ? .elenco : .griglia)
                } label: {
                    Label(TestiAggiornaValori.pulsante, systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(StileVetro())
                .disabled(stato.solaLettura)
                .help(TestiAggiornaValori.aiutoPulsante)
            }
            Button { stato.importaPosizioniDaFile() } label: {
                Label("Importa…", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(StileVetro())
            .disabled(stato.solaLettura)
            .help("Importa posizioni da Excel o CSV (elenco delle polizze, portafoglio). Puoi anche trascinare il file sulla finestra.")
            Button { stato.incollaDaExcel(posizioni: true) } label: {
                Label("Incolla da Excel", systemImage: "doc.on.clipboard")
            }
            .buttonStyle(StileVetro())
            .disabled(stato.solaLettura)
            .help("Incolla da Excel: copia in Excel le righe delle polizze con l'intestazione (⌘C), poi premi qui")
            Button { stato.richiestaNuovaPosizione = .proposta } label: {
                Label("Proposta", systemImage: "plus")
            }
            .buttonStyle(StileVetro())
            .help("Nuova proposta: un prodotto che proponi al cliente e che non ha ancora sottoscritto")
            // Il blu dell'app: la cosa da fare qui
            Button { stato.richiestaNuovaPosizione = .inEssere } label: {
                Label("Posizione", systemImage: "plus")
            }
            .buttonStyle(StileBlu())
            .help("Nuova posizione: un prodotto che il cliente ha già (polizza, fondo, conto, piano pensione)")
        }
    }
}
