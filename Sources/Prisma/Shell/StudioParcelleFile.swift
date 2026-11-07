#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI
import UniformTypeIdentifiers

// Studio › Parcelle e fatture: il salvataggio dei file della fattura (PDF su carta bianca e file XML del tracciato
// FatturaPA). Sul Mac il pannello di salvataggio (`NSSavePanel`, il nome proposto è quello dello SdI per l'XML); su
// iPhone e iPad il foglio di condivisione (Salva su File, AirDrop…) da una copia temporanea. Prisma prepara SOLO il
// file: non lo invia a nessuno, tanto meno al Sistema di Interscambio. Un errore non lascia file a metà (scrittura
// atomica) e si dice con il suo motivo.

enum FileFattura {
    /// Com'è andato il salvataggio.
    enum Esito {
        /// Salvato all'indirizzo (sul Mac).
        case salvato(URL)
        /// Passato al foglio di condivisione (iPhone e iPad).
        case condiviso
        /// L'utente ha chiuso il pannello senza salvare.
        case annullato
        case errore(String)
    }

    static let messaggioXML = "Prisma prepara il file e non lo invia: lo carichi tu sul portale «Fatture e Corrispettivi» "
        + "dell'Agenzia delle Entrate, o lo dai al commercialista."
    static let messaggioPDF = "Il PDF resta dove lo salvi: Prisma non lo invia a nessuno."

    /// Salva i dati con il pannello del Mac (o li condivide su iPhone e iPad).
    @MainActor
    static func salva(_ dati: Data, nome: String, tipo: UTType, messaggio: String) -> Esito {
        #if os(macOS)
        let pannello = NSSavePanel()
        pannello.allowedContentTypes = [tipo]
        pannello.nameFieldStringValue = nome
        pannello.canCreateDirectories = true
        pannello.message = messaggio
        guard pannello.runModal() == .OK, let url = pannello.url else { return .annullato }
        do {
            try dati.write(to: url, options: .atomic)
            return .salvato(url)
        } catch {
            return .errore(error.localizedDescription)
        }
        #elseif os(iOS)
        do {
            let url = try StampaCarta.copiaDaCondividere(dati, nome: nome)
            StampaCarta.condividi(url)
            return .condiviso
        } catch {
            return .errore(error.localizedDescription)
        }
        #endif
    }

    /// Mostra il file nel Finder (solo sul Mac).
    @MainActor
    static func mostra(_ url: URL) {
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        #endif
    }

    /// Il nome del PDF: «Fattura 2026-015 · Laura Moretti.pdf» (senza «/» e «:»).
    static func nomePDF(_ t: TestiFattura) -> String {
        let numero = t.numero.replacingOccurrences(of: "N. ", with: "")
        return "Fattura \(numero) · \(t.nomeCliente).pdf"
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }
}
