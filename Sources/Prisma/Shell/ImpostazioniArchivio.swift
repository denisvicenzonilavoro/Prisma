#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

/// Impostazioni › Archivio e backup, come nel template (§4.6, PIE i03-i06): la card con l'anello del backup che si
/// riempie mentre il backup lavora e «Crea backup» (l'azione principale), poi il backup automatico settimanale,
/// «Dove salvare», «Ripristina…» e la password; sotto i backup disponibili, gli avvisi dell'archivio e l'archivio di
/// Prisma. Tutto funziona come prima. I dati di prova stanno in Strumenti.
extension AppImpostazioni {

    var archivio: some View {
        let b = stato.dati.impostazioni.backup
        let n = Tema.Apple.Impostazioni.Nota.self
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            VStack(alignment: .leading, spacing: 0) {
                cardBackup
                    .padding(.bottom, Tema.Apple.Impostazioni.Backup.sottoCard)
                    .cascataImpostazioni(1)
                GruppoImpostazioni {
                    RigaImpostazione(titolo: "Backup automatico settimanale", sottotitolo: testoAutomatico,
                                     stato: b.automatico ? nil : Pillola(testo: "Spento", tono: .neutro),
                                     aiuto: testoProssimo, avvertenza: avvertenzaBackup) {
                        interruttore(Bindable(stato.dati).impostazioni.backup.automatico)
                    }
                    .cascataImpostazioni(2)
                    RigaImpostazione(
                        titolo: "Dove salvare",
                        sottotitolo: Archivio.percorsoBreve(stato.cartellaBackup),
                        stato: stato.cartellaBackupPredefinita ? Pillola(testo: "Sullo stesso Mac", tono: .attenzione) : nil,
                        aiuto: stato.cartellaBackupPredefinita
                            ? "I backup sono sullo stesso Mac: scegli una cartella di iCloud Drive o un disco esterno." : nil
                    ) {
                        ValoreRiga(testo: "Scegli…") { scegliCartella() }
                    }
                    .cascataImpostazioni(3)
                    RigaImpostazione(titolo: "Ripristina", sottotitolo: "Torna a una copia precedente, anche salvata altrove.",
                                     aiuto: "Un backup di Prisma salvato altrove (.zip o, se protetto, .zip.cifrato). Sostituisce l'archivio di questo Mac; prima Prisma salva una copia di sicurezza") {
                        ValoreRiga(testo: "Ripristina…") { scegliFile() }
                    }
                    .cascataImpostazioni(4)
                    RigaImpostazione(titolo: "Proteggi con una password",
                                     sottotitolo: b.cifrato ? "AES-256, password nel Portachiavi." : "Facoltativa.",
                                     stato: b.cifrato ? Pillola(testo: "Protetti", tono: .ok) : nil,
                                     aiuto: testoProtezione + ". Se dimentichi la password, i backup protetti non si possono più aprire",
                                     ultima: true) {
                        HStack(spacing: Tema.Misura.Componenti.spazioTendina) {
                            if b.cifrato {
                                ValoreRiga(testo: "Cambia") { stato.chiediPasswordBackup = true }
                            }
                            interruttore(Binding(get: { stato.dati.impostazioni.backup.cifrato },
                                                 set: { acceso in
                                                     if acceso { stato.chiediPasswordBackup = true } else { confermaTogliPassword = true }
                                                 }))
                        }
                        .popover(isPresented: Bindable(stato).chiediPasswordBackup, arrowEdge: .leading) { moduloPassword }
                    }
                    .cascataImpostazioni(5)
                }
            }
            if b.cifrato {
                NotaImpostazioni("Se dimentichi la password, i backup protetti non si aprono più.")
                    .cascataImpostazioni(6)
            }

            // «Luce» giro 6: la Biblioteca (PDF di condizioni, KID, circolari) nel backup di base, con l'interruttore
            GruppoImpostazioni(titolo: "Biblioteca") {
                // Il numero dei documenti viene da StatoBiblioteca (ObservableObject, non osservato da StatoShell):
                // osservato qui, la riga si aggiorna anche quando si aggiunge un documento con la pagina aperta
                OsservaOggetto(stato.biblioteca) {
                    RigaImpostazione(titolo: "Escludi la Biblioteca dal backup",
                                     sottotitolo: testoMisuraBiblioteca,
                                     aiuto: "Circolari e manuali interni possono essere riservati: decidi tu se possono stare in un backup su iCloud Drive. Se la escludi, un ripristino tiene la Biblioteca di questo Mac",
                                     ultima: true) {
                        interruttore(Binding(get: { stato.dati.impostazioni.backup.escludiBiblioteca == true },
                                             set: { stato.dati.impostazioni.backup.escludiBiblioteca = $0 ? true : nil }))
                    }
                }
            }
            .cascataImpostazioni(6)

            GruppoImpostazioni(titolo: "Backup disponibili") {
                if stato.elencoBackup.isEmpty {
                    RigaImpostazione(titolo: "Nessun backup ancora", sottotitolo: "Crea il primo con «Crea backup».") { EmptyView() }
                }
                ForEach(stato.elencoBackup) { voce in
                    RigaImpostazione(titolo: Formati.dataOra.string(from: voce.data),
                                     sottotitolo: descrizione(voce)) {
                        ValoreRiga(testo: "Ripristina…") { daRipristinare = voce }
                    }
                }
            }
            .cascataImpostazioni(7)

            if stato.copieNonLeggibili > 0 {
                VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.spazioControlliAffiancati) {
                    Text("All'avvio l'archivio non era leggibile: la copia è nella cartella di Prisma e i backup automatici sono fermi, per non sostituire i backup buoni. Ripristina un backup qui sopra oppure, se i dati di oggi vanno bene, riprendi i backup.")
                        .carattereApple(n.carattere)
                        .foregroundColor(n.coloreErrore)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { stato.riprendiBackupAutomatici() } label: { Label("Riprendi i backup automatici", systemImage: "arrow.clockwise") }
                        .buttonStyle(StilePulsanteRigaImpostazioni())
                        .fixedSize()
                }
                .padding(.horizontal, n.rientro)
                .cascataImpostazioni(8)
            }

            if stato.solaLettura {
                Text("Archivio in sola lettura: è stato salvato da una versione più recente di Prisma. Le modifiche non vengono salvate: apri l'ultima versione dell'app.")
                    .carattereApple(n.carattere)
                    .foregroundColor(n.coloreErrore)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, n.rientro)
                    .cascataImpostazioni(8)
            }

            GruppoImpostazioni(titolo: "Archivio di Prisma") {
                RigaImpostazione(titolo: "Sul Mac", sottotitolo: Archivio.percorsoBreve(Archivio.cartella),
                                 stato: Pillola(testo: "Versione \(DatiPrisma.versioneAttuale)", tono: .neutro), ultima: true) {
                    ValoreRiga(testo: "Mostra nel Finder") {
                        #if os(macOS)
                        NSWorkspace.shared.activateFileViewerSelecting([Archivio.cartellaPezzi])
                        #elseif os(iOS)
                        // Su iPhone e iPad il Finder non c'è
                        stato.mostraAvviso(StatoShell.soloSulMacPerOra)
                        #endif
                    }
                }
            }
            .cascataImpostazioni(9)
            HStack(spacing: Tema.Apple.Impostazioni.Backup.fraNumeri) {
                numero(stato.clienti.count, "clienti")
                numero(stato.appuntamenti.count, "appuntamenti")
                numero(stato.attivita.count, "attività")
            }
            .padding(.horizontal, n.rientro)
            .cascataImpostazioni(10)
            NotaImpostazioni("Niente cloud: i backup vanno solo nella cartella che scegli tu.")
                .cascataImpostazioni(11)
        }
    }

    // MARK: La card del backup

    /// L'anello del backup (§2.24), che cosa dice l'ultimo backup e «Crea backup».
    private var cardBackup: some View {
        let k = Tema.Apple.Impostazioni.Backup.self
        let b = stato.dati.impostazioni.backup
        let inRegola = b.ultimo != nil && b.ultimoErrore == nil && !b.inRitardo
        return HStack(alignment: .center, spacing: k.spazio) {
            AnelloBackupApple(inCorso: stato.backupInCorso, pieno: inRegola, errore: b.ultimoErrore != nil)
            VStack(alignment: .leading, spacing: k.sottoTitolo) {
                Text(titoloBackup)
                    .carattereApple(k.titolo)
                    .foregroundColor(k.coloreTitolo)
                    .fixedSize(horizontal: false, vertical: true)
                Text(spiegazioneBackup)
                    .carattereApple(k.spiegazione)
                    .foregroundColor(k.coloreSpiegazione)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Crea backup") { stato.creaBackup() }
                .buttonStyle(StilePulsanteRigaImpostazioni(principale: true, grande: true))
                .fixedSize()
                .disabled(stato.backupInCorso)
                .help("Copia completa di clienti, agenda, posizioni, documenti e impostazioni di Vera")
        }
        .padding(k.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(k.superficie, raggio: k.raggio)
    }

    /// «Creo il backup…», «Backup creato adesso», «Ultimo backup: …», «Nessun backup ancora».
    private var titoloBackup: String {
        let b = stato.dati.impostazioni.backup
        if stato.backupInCorso { return "Creo il backup…" }
        if b.ultimoErrore != nil { return "Ultimo backup non riuscito" }
        guard let ultimo = b.ultimo else { return "Nessun backup ancora" }
        if Date().timeIntervalSince(ultimo) < Self.backupAdesso { return "Backup creato adesso" }
        return "Ultimo backup: \(Formati.dataOra.string(from: ultimo))"
    }

    /// Il contenuto vero del backup (e se è cifrato), oppure perché farne uno.
    private var spiegazioneBackup: String {
        let b = stato.dati.impostazioni.backup
        if let e = b.ultimoErrore, !stato.backupInCorso { return e }
        if b.ultimo == nil && !stato.backupInCorso { return "Il primo backup protegge tutto il lavoro fatto finora." }
        let contenuto = "Clienti, agenda, posizioni, documenti e impostazioni di Vera"
        return b.cifrato ? contenuto + " · cifrato" : contenuto
    }

    /// Fino a quando un backup si dice «creato adesso» (secondi).
    static let backupAdesso: TimeInterval = 120

    var testoProtezione: String {
        stato.dati.impostazioni.backup.cifrato
            ? "Attiva: i nuovi backup si aprono solo con la password (cifratura AES-256); la password è nel Portachiavi del Mac"
            : "Facoltativa: i file dei backup si aprono solo con la password, anche su iCloud Drive o su un disco esterno"
    }

    /// Nome e dimensione di un backup dell'elenco, con «protetto» se ha la password.
    /// «La cartella pesa 12 MB, per ognuna delle 8 copie.»
    var testoMisuraBiblioteca: String {
        let n = stato.biblioteca.tutti.count
        guard stato.persistente, n > 0 else { return "La Biblioteca è vuota." }
        let misura = ByteCountFormatter.string(fromByteCount: StatoShell.misuraBiblioteca(), countStyle: .file)
        return "\(n == 1 ? "1 documento" : "\(n) documenti"), \(misura): in ognuna delle \(GestoreBackup.massimo) copie."
    }

    func descrizione(_ voce: VoceBackup) -> String {
        let base = "\(voce.nome) · \(Formati.dimensione(voce.dimensione))"
        return voce.cifrato ? base + " · protetto" : base
    }

    /// Imposta o cambia la password dei backup: due campi, la conferma e l'avvertenza.
    var moduloPassword: some View {
        let protetti = stato.dati.impostazioni.backup.cifrato
        return VStack(alignment: .leading, spacing: Tema.Misura.Componenti.spazioTendina) {
            Text(protetti ? "Nuova password dei backup" : "Password dei backup")
                .font(Tema.Testo.titolo)
                .foregroundColor(Tema.Colore.inchiostro)
            SecureField("Password (almeno \(ImpostazioniBackup.lunghezzaMinimaPassword) caratteri)", text: $nuovaPassword)
                .campoTesto()
            SecureField("Ripeti la password", text: $confermaPassword)
                .campoTesto()
                .onSubmit { salvaPassword() }
            Text(erroreNuovaPassword ?? "Se dimentichi la password, i backup protetti non si possono più aprire: conservala in un posto sicuro. Vale dai prossimi backup; quelli già fatti si aprono con la password di allora.")
                .font(Tema.Testo.secondario)
                .foregroundColor(erroreNuovaPassword == nil ? Tema.Colore.inchiostroSecondario : Tema.Colore.scadenzaOra)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Tema.Misura.Componenti.spazioTendina) {
                Spacer(minLength: 0)
                Button("Annulla") { stato.chiediPasswordBackup = false }
                    .buttonStyle(StileVetro())
                Button("Salva") { salvaPassword() }
                    .buttonStyle(StileBlu())
            }
        }
        .padding(Tema.Misura.Componenti.margineRiga)
        .frame(width: Tema.Misura.popoverLarghezza)
        .onDisappear {
            nuovaPassword = ""
            confermaPassword = ""
            erroreNuovaPassword = nil
        }
    }

    func salvaPassword() {
        let minimo = ImpostazioniBackup.lunghezzaMinimaPassword
        guard nuovaPassword.count >= minimo else {
            erroreNuovaPassword = "Servono almeno \(minimo) caratteri."
            return
        }
        guard nuovaPassword == confermaPassword else {
            erroreNuovaPassword = "Le due password non coincidono."
            return
        }
        if stato.impostaPasswordBackup(nuovaPassword) {
            stato.chiediPasswordBackup = false
        } else {
            erroreNuovaPassword = "Il Portachiavi del Mac non ha salvato la password: riprova."
        }
    }

    /// Backup non riusciti o fermi da più di 8 giorni: resta scritto finché il problema c'è.
    var avvertenzaBackup: String? {
        let b = stato.dati.impostazioni.backup
        if let e = b.ultimoErrore {
            let quando = b.ultimoTentativo.map { " (\(Formati.dataOra.string(from: $0)))" } ?? ""
            return "Ultimo backup non riuscito\(quando): \(e)"
        }
        if b.inRitardo { return "Nessun backup riuscito negli ultimi 8 giorni: crea un backup a mano." }
        return nil
    }

    /// «Ultimo: 1 nov 2026, 9:30», oppure cosa fare se è spento.
    var testoAutomatico: String {
        let b = stato.dati.impostazioni.backup
        guard b.automatico else { return "Spento: ricordati di crearli a mano." }
        return "Ogni settimana; tengo le ultime \(GestoreBackup.massimo) copie."
    }

    /// Il prossimo backup automatico, al passaggio del puntatore.
    var testoProssimo: String? {
        let b = stato.dati.impostazioni.backup
        guard b.automatico, let p = b.prossimo else { return nil }
        return p <= Date() ? "Il prossimo tra poco" : "Prossimo: \(Formati.dataOra.string(from: p))"
    }

    func numero(_ n: Int, _ etichetta: String) -> some View {
        let k = Tema.Apple.Impostazioni.Backup.self
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.sottoTitolo) {
            Text("\(n)").carattereApple(k.numero).foregroundColor(k.coloreNumero)
            Text(etichetta).carattereApple(k.etichettaNumero).foregroundColor(k.coloreEtichettaNumero)
        }
    }

    func scegliCartella() {
        #if os(macOS)
        let pannello = NSOpenPanel()
        pannello.canChooseDirectories = true
        pannello.canChooseFiles = false
        pannello.canCreateDirectories = true
        pannello.allowsMultipleSelection = false
        pannello.prompt = "Usa questa cartella"
        pannello.message = "Scegli dove salvare i backup di Prisma (per esempio iCloud Drive o un disco esterno)."
        if pannello.runModal() == .OK, let url = pannello.url {
            stato.scegliCartellaBackup(url)
        }
        #elseif os(iOS)
        // Su iPhone e iPad i backup non si creano: i dati arrivano dal backup del Mac
        stato.mostraAvviso(StatoShell.soloSulMacPerOra)
        #endif
    }

    func scegliFile() {
        #if os(macOS)
        let pannello = NSOpenPanel()
        pannello.canChooseDirectories = false
        pannello.canChooseFiles = true
        pannello.allowsMultipleSelection = false
        // Anche i backup protetti («… .zip.cifrato»): il ripristino li riconosce dal contenuto
        var tipi: [UTType] = [.zip]
        if let protetto = UTType(filenameExtension: GestoreBackup.estensioneCifrata) { tipi.append(protetto) }
        pannello.allowedContentTypes = tipi
        pannello.prompt = "Ripristina"
        pannello.message = "Scegli un backup di Prisma."
        if pannello.runModal() == .OK, let url = pannello.url {
            fileDaRipristinare = url
        }
        #elseif os(iOS)
        // Su iPhone e iPad il backup si apre dalla schermata di apertura (AperturaBackup, con `.fileImporter`)
        stato.mostraAvviso(StatoShell.soloSulMacPerOra)
        #endif
    }
}
