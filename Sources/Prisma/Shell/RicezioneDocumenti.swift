#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Importare e gestire i documenti del cliente
// Una sola logica per l'app Documenti (iPad) e per la scheda Documenti dentro Clienti: il pannello per scegliere
// i file, il trascinamento, la cornice del rilascio, l'avviso di eliminazione e il riallineamento dei filtri.
// I file vanno sempre al cliente attivo (`StatoShell.importaDocumenti`).

/// Gli URL dei file rilasciati, raccolti sul thread principale prima di aggiungerli tutti insieme.
final class RaccoltaRilascio {
    var urls: [URL] = []
}

enum ImportaDocumenti {
    /// Il pannello per scegliere i file: sul Mac `NSOpenPanel`, su iPhone e iPad il `.fileImporter` di
    /// `gestioneDocumenti` (si apre mettendo `scelta` a true).
    static func scegli(_ stato: StatoShell, scelta: Binding<Bool>) {
        #if os(macOS)
        let pannello = NSOpenPanel()
        pannello.allowedContentTypes = [.pdf, .png, .jpeg, .tiff, .heic]
        pannello.allowsMultipleSelection = true
        pannello.prompt = "Importa"
        pannello.message = "Scegli KID, polizze, estratti conto, documenti d'identità o questionari: vengono copiati nell'archivio di Prisma."
        if pannello.runModal() == .OK { stato.aggiungiDocumenti(pannello.urls) }
        #elseif os(iOS)
        scelta.wrappedValue = true
        #endif
    }

    #if os(macOS)
    static let notaStato = "Lettura sul Mac: PDFKit per il testo, Vision per le scansioni · nessun file lascia il computer"
    #elseif os(iOS)
    static let notaStato = "Lettura sul dispositivo: PDFKit per il testo, Vision per le scansioni · nessun file lascia il dispositivo"
    #endif
}

/// Trascinamento e scelta dei file, cornice del rilascio, avviso di eliminazione, riallineamento all'apertura e
/// al cambio del documento scelto.
struct GestioneDocumenti: ViewModifier {
    @EnvironmentObject var stato: StatoShell
    /// Il nome del cliente nella cornice del rilascio.
    let nome: String
    /// Il pannello di sistema su iPhone e iPad (sul Mac non serve).
    @Binding var scelta: Bool
    @Binding var daEliminare: Documento?
    /// Toglie i filtri che nasconderebbero il documento scelto.
    let allinea: () -> Void
    @State private var sopra = false

    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .onDrop(of: [UTType.fileURL], isTargeted: $sopra) { fornitori in
                let raccolta = RaccoltaRilascio()
                let gruppo = DispatchGroup()
                for f in fornitori {
                    gruppo.enter()
                    _ = f.loadObject(ofClass: URL.self) { url, _ in
                        DispatchQueue.main.async {
                            if let url { raccolta.urls.append(url) }
                            gruppo.leave()
                        }
                    }
                }
                gruppo.notify(queue: .main) {
                    if !raccolta.urls.isEmpty { stato.aggiungiDocumenti(raccolta.urls) }
                }
                return true
            }
            #elseif os(iOS)
            // Su iPad i file trascinati (da File o da un'altra app) arrivano come rappresentazioni da copiare subito
            .onDrop(of: ImportaDocumentiMobile.tipiRilascio, isTargeted: $sopra) { fornitori in
                ImportaDocumentiMobile.rilascia(fornitori) { stato.aggiungiDocumenti($0) }
                return true
            }
            .fileImporter(isPresented: $scelta, allowedContentTypes: ImportaDocumentiMobile.tipiScelta,
                          allowsMultipleSelection: true) { esito in
                switch esito {
                case .success(let urls):
                    ImportaDocumentiMobile.importa(urls, avviso: { stato.mostraAvviso($0) }) { stato.aggiungiDocumenti($0) }
                case .failure(let errore):
                    stato.mostraAvviso("Non riesco ad aprire i file scelti: \(errore.localizedDescription)")
                }
            }
            #endif
            .overlay {
                if sopra { RilascioDocumenti(nome: nome) }
            }
            .onAppear { allinea() }
            .onChange(of: stato.documentoSelezionato) { _ in
                stato.vistaDocumenti.pagina = 1
                stato.vistaDocumenti.evidenzia = nil
                allinea()
            }
            .alert("Eliminare il documento?",
                   isPresented: Binding(get: { daEliminare != nil }, set: { if !$0 { daEliminare = nil } }),
                   presenting: daEliminare) { d in
                Button("Annulla", role: .cancel) {}
                Button("Elimina", role: .destructive) { stato.eliminaDocumento(d.id) }
            } message: { _ in
                Text("Il file viene tolto dall'archivio di Prisma. Schede, posizioni e lo storico dei dati portati in Prisma restano. Se serve, lo recuperi da un backup.")
            }
    }
}

extension View {
    /// Importazione (trascinamento e pannello), eliminazione e riallineamento dei documenti del cliente attivo.
    func gestioneDocumenti(nome: String, scelta: Binding<Bool>, daEliminare: Binding<Documento?>,
                           allinea: @escaping () -> Void) -> some View {
        modifier(GestioneDocumenti(nome: nome, scelta: scelta, daEliminare: daEliminare, allinea: allinea))
    }
}
