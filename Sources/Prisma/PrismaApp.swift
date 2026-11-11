#if os(macOS)
// Solo Mac: su iPhone e iPad il punto d'ingresso è PrismaAppMobile (iOS/PrismaAppMobile.swift).
import AppKit
import SwiftUI

@main
struct PrismaApp: App {
    // L'App tiene lo stato senza osservarlo: i Commands e il menu non si ricostruiscono a ogni cambiamento.
    // `static let` è pigro: nelle modalità `--prova-*` e `--istantanee` (che escono in init) lo stato non nasce
    private static let condiviso = StatoShell()
    private var stato: StatoShell { Self.condiviso }

    init() {
        let argomenti = CommandLine.arguments
        if argomenti.contains("--verifica-risorse") {
            exit(Risorse.verifica())
        }
        if argomenti.contains("--prova-backup") {
            exit(ProvaBackup.esegui())
        }
        if argomenti.contains("--prova-calcoli") {
            exit(ProvaCalcoli.esegui())
        }
        if argomenti.contains("--prova-ovunque") {
            // Prisma ovunque: due archivi e una cartella locale che finge iCloud Drive (Dati/ProvaOvunque.swift)
            exit(ProvaOvunque.esegui())
        }
        // «--prova-ruby» e «--prova-eve» sono i sinonimi di prima dei cambi di nome
        if argomenti.contains("--prova-vera") || argomenti.contains("--prova-ruby") || argomenti.contains("--prova-eve") {
            exit(ProvaVera.esegui())
        }
        if argomenti.contains("--prova-tavolo") {
            // Il tavolo con l'iPad a circuito chiuso su 127.0.0.1 (Tavolo/ProvaTavolo.swift)
            exit(ProvaTavolo.esegui())
        }
        if argomenti.contains("--prova-realta") {
            // La prova di fattibilità della realtà aumentata: il cristallo in RealityKit senza fotocamera (Shell/ProvaRealta.swift)
            exit(ProvaRealta.esegui())
        }
        if argomenti.contains("--controlla-mercato") {
            // Solo per il passo informativo del workflow: scarica una volta le serie pubbliche configurate (BCE,
            // Eurostat) e le legge. Non apre l'archivio: nessun dato dei clienti (Dati/ClienteMercato.swift)
            exit(ClienteMercato.controllaConfigurazione())
        }
        if argomenti.contains("--confronta-modelli") {
            exit(ConfrontoModelli.daRigaDiComando(argomenti))
        }
        if argomenti.contains("--prova-carico") {
            exit(ProvaCarico.esegui())
        }
        if let i = argomenti.firstIndex(of: "--prova-fluidita") {
            // Facoltativo: il file in cui scrivere la tabella (Markdown) per il riepilogo della build
            let file = i + 1 < argomenti.count && !argomenti[i + 1].hasPrefix("--") ? URL(fileURLWithPath: argomenti[i + 1]) : nil
            exit(ProvaFluidita.esegui(uscita: file))
        }
        if let i = argomenti.firstIndex(of: "--prova-prospetti") {
            let cartella = i + 1 < argomenti.count && !argomenti[i + 1].hasPrefix("--") ? URL(fileURLWithPath: argomenti[i + 1], isDirectory: true) : nil
            exit(ProvaProspetti.esegui(cartella: cartella))
        }
        if let i = argomenti.firstIndex(of: "--prova-fattura") {
            // Due fatture XML di esempio (FatturaPA FPR12, dati di prova fittizi) per la verifica contro lo schema.
            // Solo i file: nessun invio al Sistema di Interscambio
            let cartella = i + 1 < argomenti.count && !argomenti[i + 1].hasPrefix("--")
                ? URL(fileURLWithPath: argomenti[i + 1], isDirectory: true)
                : URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true).appendingPathComponent("fatture-di-prova")
            exit(ProvaFatturaPA.esegui(cartella: cartella))
        }
        if let i = argomenti.firstIndex(of: "--prova-film") {
            // Il film del piano («Luce» giro 15): il video dei dati di prova; con la cartella anche i cinque fotogrammi
            let cartella = i + 1 < argomenti.count && !argomenti[i + 1].hasPrefix("--") ? URL(fileURLWithPath: argomenti[i + 1], isDirectory: true) : nil
            exit(ProvaFilm.esegui(cartella: cartella))
        }
        if let i = argomenti.firstIndex(of: "--prova-file-cliente"), i + 1 < argomenti.count {
            // Il Prisma del cliente («Luce» giro 15): il file di prova per il lettore (Node) e le pagine del PDF
            exit(ProvaFileCliente.esegui(cartella: URL(fileURLWithPath: argomenti[i + 1], isDirectory: true)))
        }
        if let i = argomenti.firstIndex(of: "--istantanee"), i + 1 < argomenti.count {
            func valore(_ opzione: String) -> String? {
                argomenti.firstIndex(of: opzione).flatMap { $0 + 1 < argomenti.count ? argomenti[$0 + 1] : nil }
            }
            let metodo = valore("--metodo") ?? "finestra"
            // --testo 1.2: le schermate con il testo ingrandito; --solo a,b: solo quelle scene
            if let t = valore("--testo").flatMap(Double.init) { Tipo.fattore = CGFloat(t) }
            let solo = valore("--solo").map { Set($0.split(separator: ",").map(String.init)) }
            exit(Istantanee.genera(in: URL(fileURLWithPath: argomenti[i + 1], isDirectory: true), metodo: metodo, solo: solo))
        }
        // Avvio vero: l'archivio e Metal si preparano in background mentre nasce la finestra
        if !argomenti.contains(where: { $0.hasPrefix("--") }) {
            AvvioArchivio.avvia()
            Preriscaldamento.avvia()
            // Le cose date al cliente («Luce» giro 15): le chiavi delle capsule nei backup protetti e le copie da spedire
            // rimaste da una chiusura forzata
            CapsuleNelBackup.installa()
            CartellaUscite.svuota()
        }
    }

    var body: some Scene {
        Window("Prisma", id: "prisma") {
            // Aspetto scelto in Impostazioni: lo applicano StatoShell.init (prima del primo disegno) e ShellView (ai cambi)
            ShellView()
                .environment(stato)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        .commands { ComandiPrisma(stato: stato, menu: stato.menu) }
    }

    /// Chiaro, scuro o come il Mac: vale per tutta l'app (i PDF restano comunque chiari).
    @MainActor static func applicaAspetto(_ aspetto: AspettoInterfaccia) {
        NSApp.appearance = aspetto.aspettoMac
    }
}

/// I menu di Prisma. Le azioni passano dallo stato (non osservato); titoli e abilitazioni vengono da StatoMenu,
/// l'unico oggetto osservato: il menu si ricostruisce solo quando cambia uno di quei quattro valori.
struct ComandiPrisma: Commands {
    let stato: StatoShell
    @ObservedObject var menu: StatoMenu

    var body: some Commands {
        CommandMenu("Vai") {
            // Con la schermata di benvenuto davanti, niente si apre dietro di lei
            Group {
            // Il pannello di ricerca come Spotlight: ⌘K lo apre e lo chiude
            Button("Cerca ovunque") { stato.alternaRicerca() }
                .keyboardShortcut("k", modifiers: .command)
            Button(menu.inModoCliente ? "Esci dalla modalità cliente" : "Modalità cliente") { stato.alternaModoCliente() }
                .keyboardShortcut("m", modifiers: [.command, .option])
            Button("Spazi di lavoro…") { stato.pannelloSpazi = true }
                .disabled(menu.inModoCliente)
            Button("Le tue app aperte…") { stato.pannelloAppAperte = true }
            Button(menu.conversazioneAVoce ? "Chiudi la conversazione con Vera" : "Parla con Vera") { stato.alternaAscolto(daMenu: true) }
                .keyboardShortcut("e", modifiers: [.command, .option])
            Divider()
            Button("Scrivania") { stato.mostraScrivania() }
                .keyboardShortcut("0", modifiers: .option)
            Divider()
            ForEach(Array(AppPrisma.delDock.prefix(9).enumerated()), id: \.element) { indice, app in
                Button(app.titolo) { stato.apriApp(app) }
                    .keyboardShortcut(KeyEquivalent(Character("\(indice + 1)")), modifiers: .option)
            }
            Divider()
            ForEach(Array(AppPrisma.delDock.dropFirst(9))) { app in
                Button(app.titolo) { stato.apriApp(app) }
            }
            // Le app con una finestra propria fuori dal dock (versione «Orizzonte»): Prodotti e Note.
            // La Ricerca è «Cerca ovunque» (⌘K), qui sopra
            Divider()
            ForEach(AppPrisma.altreApp.filter { $0 != .ricerca }) { app in
                Button(app.titolo) { stato.apriApp(app) }
            }
            }
            // Durante la presentazione nulla si muove sotto il velo: resta solo la schermata di benvenuto
            .disabled(menu.bloccato || menu.inPresentazione)
            Divider()
            Button("Schermata di benvenuto") { stato.blocca() }
                .keyboardShortcut("l", modifiers: [.command, .option])
                .disabled(menu.bloccato)
        }
        CommandGroup(replacing: .newItem) {}
        // Menu Aiuto: la guida di Prisma al posto della voce di sistema «L'aiuto non è disponibile».
        // Con la schermata di benvenuto davanti le voci restano attive: apriGuida sblocca e poi apre.
        CommandGroup(replacing: .help) {
            Group {
                Button("Guida di Prisma") { stato.apriGuida(.app(stato.appAttiva ?? .clienti)) }
                    .keyboardShortcut("?", modifiers: .command)
                Button("Come funziona Prisma (introduzione)") { stato.apriGuida(.introduzione(0)) }
                Button("Le parole della finanza") { stato.apriGuida(.glossario(nil)) }
            }
            .disabled(menu.inPresentazione)
            Divider()
            // Prova guidata sul Mac (Shell/ProvaGuidata.swift); scelta di nuovo durante la prova, la interrompe
            Button("Prova la fluidità…") { ProvaGuidata.condivisa.avvia(stato: stato) }
        }
    }
}
#endif
