#if os(macOS)
import AppKit
#endif
import SwiftUI

// Il foglio di condivisione del sistema per le cose date al cliente («Luce» giro 15, decisione 1, CLAUDE.md › Dati e
// privacy). Prisma non spedisce mai: prepara i file solo al clic e apre il foglio del sistema ancorato al pulsante; sceglie
// e spedisce il consulente. Senza il consenso a WhatsApp segnato nel dossier il servizio WhatsApp si toglie dai servizi
// proposti. Le copie temporanee (`CartellaUscite`) si tolgono dopo l'esito. Nessuna richiesta di rete da qui.

/// Com'è finita una condivisione.
enum EsitoCondivisione: Equatable {
    /// Il servizio scelto nel foglio («AirDrop», «Messaggi»…; vuoto se il sistema non lo dice).
    case condiviso(via: String)
    case annullato
    case nonRiuscito(String)
}

/// Il pulsante che apre il foglio di condivisione del sistema.
struct PulsanteCondividi: View {
    /// «Condividi il video…».
    let titolo: String
    var primario = false
    let consensoWhatsApp: Bool
    /// Prepara i file al clic; nil = non pronto (il messaggio lo dà chi prepara).
    let prepara: @MainActor () async -> [URL]?
    var esito: @MainActor (EsitoCondivisione) -> Void = { _ in }

    @State private var inPreparazione = false
    #if os(macOS)
    @State private var ancora = ScatolaAncora()
    @State private var delegato: DelegatoCondivisione?
    #endif

    var body: some View {
        let _ = ContaCorpi.segna()
        Button(action: avvia) {
            Label(titolo, systemImage: "square.and.arrow.up")
        }
        .buttonStyle(StilePulsanteApple(primario ? .principale : .secondaria))
        .disabled(inPreparazione)
        .help(consensoWhatsApp ? titolo : TestiUscite.whatsappSenzaConsenso)
        .background(sfondoAncora)
    }

    @ViewBuilder private var sfondoAncora: some View {
        #if os(macOS)
        AncoraCondivisione(scatola: ancora)
        #else
        Color.clear
        #endif
    }

    private func avvia() {
        guard !inPreparazione else { return }
        inPreparazione = true
        Task { @MainActor in
            let urls = await prepara()
            inPreparazione = false
            guard let urls, !urls.isEmpty else { return }
            mostra(urls)
        }
    }

    @MainActor private func mostra(_ urls: [URL]) {
        #if os(macOS)
        guard let vista = ancora.vista, vista.window != nil else {
            termina(.nonRiuscito("Il foglio di condivisione non si apre"), urls)
            return
        }
        let d = DelegatoCondivisione(consensoWhatsApp: consensoWhatsApp) { e in
            Task { @MainActor in termina(e, urls) }
        }
        delegato = d
        let picker = NSSharingServicePicker(items: urls)
        picker.delegate = d
        d.picker = picker
        picker.show(relativeTo: vista.bounds, of: vista, preferredEdge: .minY)
        #else
        // iPhone e iPad: il foglio di UIKit non dà l'esito; la copia resta fino al blocco o alla chiusura (il foglio la
        // sta ancora leggendo). Senza consenso, WhatsApp non compare
        StampaCarta.condividiAlCliente(urls, consensoWhatsApp: consensoWhatsApp)
        esito(.condiviso(via: ""))
        #endif
    }

    #if os(macOS)
    @MainActor private func termina(_ e: EsitoCondivisione, _ urls: [URL]) {
        delegato = nil
        for u in urls { CartellaUscite.togli(u) }
        esito(e)
    }
    #endif
}

#if os(macOS)
/// Tiene la vista AppKit a cui si ancora il foglio (debole: la vista è di SwiftUI).
final class ScatolaAncora {
    weak var vista: NSView?
}

/// L'ancora AppKit del foglio: una vista vuota dietro il pulsante.
struct AncoraCondivisione: NSViewRepresentable {
    let scatola: ScatolaAncora

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        scatola.vista = v
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        scatola.vista = nsView
    }
}

/// Il delegato del foglio e del servizio scelto. Il foglio lo tiene debole: lo tiene vivo la vista finché non arriva
/// l'esito. Senza consenso toglie WhatsApp dai servizi proposti.
final class DelegatoCondivisione: NSObject, NSSharingServicePickerDelegate, NSSharingServiceDelegate {
    let consensoWhatsApp: Bool
    let fine: (EsitoCondivisione) -> Void
    var picker: NSSharingServicePicker?
    private var finito = false

    init(consensoWhatsApp: Bool, fine: @escaping (EsitoCondivisione) -> Void) {
        self.consensoWhatsApp = consensoWhatsApp
        self.fine = fine
        super.init()
    }

    /// Una sola volta.
    private func chiudi(_ e: EsitoCondivisione) {
        guard !finito else { return }
        finito = true
        picker = nil
        fine(e)
    }

    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any],
                              proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard !consensoWhatsApp else { return proposedServices }
        return proposedServices.filter { !$0.title.localizedCaseInsensitiveContains("WhatsApp") }
    }

    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker,
                              delegateFor sharingService: NSSharingService) -> NSSharingServiceDelegate? {
        self
    }

    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        if service == nil { chiudi(.annullato) }
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        chiudi(.condiviso(via: sharingService.title))
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        let e = error as NSError
        if e.domain == NSCocoaErrorDomain && e.code == NSUserCancelledError {
            chiudi(.annullato)
        } else {
            chiudi(.nonRiuscito(e.localizedDescription))
        }
    }
}
#endif
