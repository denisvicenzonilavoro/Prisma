#if os(iOS)
import SwiftUI
import UIKit

// «Nuovo cliente in 10 secondi» sull'iPhone e sull'iPad (Design/template-luce-specifica.md §9.1.4, «Luce» giro 13):
// Clienti › «Nuovo cliente» apre la fotocamera dal vivo (lo scanner di Inquadra, `ScannerInquadra`; ripiego la scansione
// documenti di sistema). Lo scatto si legge con Vision **sul telefono**; i campi trovati compaiono a cascata
// (MotoreCartaIdentita, gli stessi del Mac); «Aggiungi il retro» legge la seconda faccia; «Manda al Mac» manda **solo il
// testo** (righe con il riquadro), cifrato sul ponte: l'immagine non lascia il telefono e non si salva. Senza Mac: «Il
// Mac non risponde: il documento resta qui finché chiudi questa schermata» (niente coda per la carta). L'iPhone non crea
// il cliente: lo crea solo il Mac.

// MARK: - Presentazione da Clienti

extension View {
    /// La schermata della fotocamera per la carta d'identità, quando `stato.nuovoCliente.telefonoAperto`.
    func cartaIdentitaTelefono(_ stato: StatoShell) -> some View {
        modifier(PresentaCartaIdentitaTelefono(nuovoCliente: stato.nuovoCliente))
    }
}

private struct PresentaCartaIdentitaTelefono: ViewModifier {
    @Environment(StatoShell.self) var stato
    let nuovoCliente: StatoNuovoCliente
    @Environment(\.istantaneaSchermo) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: Binding(get: { nuovoCliente.telefonoAperto },
                                                     set: { if !$0 { nuovoCliente.chiudiTelefono() } })) {
            CartaIdentitaTelefono(nuovoCliente: nuovoCliente)
                .environment(stato)
                .environment(\.istantaneaSchermo, istantanea)
                .prismaCalmo(calmo)
        }
    }
}

/// Il pulsante grande «Nuovo cliente» in cima a Clienti sull'iPhone (una cosa principale in alto, Design/iphone.html).
struct PulsanteNuovoClienteTelefono: View {
    @Environment(StatoShell.self) var stato

    private typealias M = Tema.Apple.NuovoCliente.Mobile

    var body: some View {
        let _ = ContaCorpi.segna()
        Button { stato.nuovoCliente.apriTelefono() } label: {
            HStack(spacing: M.spazio) {
                GlifoLuceVista(glifo: .scan, lato: M.glifo, colore: Tema.Colore.Componenti.testoSuColore)
                Text("Nuovo cliente")
                    .carattereApple(M.pulsante)
            }
            .frame(maxWidth: .infinity, minHeight: M.altezzaPulsante)
        }
        .buttonStyle(.applePrimarioGrande)
        .accessibilityHint(Text("Inquadra la carta d’identità: al Mac va solo il testo letto"))
    }
}

// MARK: - La schermata

struct CartaIdentitaTelefono: View {
    @Environment(StatoShell.self) var stato
    let nuovoCliente: StatoNuovoCliente
    @Environment(\.istantaneaSchermo) private var istantanea
    @StateObject private var scanner = ControlloreScannerInquadra()
    @State private var scansioneDocumenti = false

    private typealias M = Tema.Apple.Inquadra.Mobile
    private typealias S = Tema.Apple.Inquadra.Scheda

    var body: some View {
        let _ = ContaCorpi.segna()
        ZStack(alignment: .topLeading) {
            M.fondoCamera.ignoresSafeArea()
            if nuovoCliente.fase == .attesa {
                camera
                    .ignoresSafeArea()
                VStack {
                    Spacer(minLength: 0)
                    pannello
                        .padding(.horizontal, M.margine)
                        .padding(.bottom, M.margine)
                }
            } else {
                ScrollView {
                    pannello
                        .padding(.horizontal, M.margine)
                        .padding(.top, M.foglioDallAlto)
                        .padding(.bottom, M.margine)
                }
            }
            Button { nuovoCliente.chiudiTelefono() } label: { Image(systemName: "xmark") }
                .buttonStyle(.appleVetro)
                .accessibilityLabel(Text("Chiudi: il documento letto si scarta"))
                .padding(M.margine)
        }
        .sheet(isPresented: $scansioneDocumenti) {
            CameraDocumentiInquadra { foto in
                scansioneDocumenti = false
                if let foto { stato.leggiFotoCarta(foto) }
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder private var camera: some View {
        if istantanea {
            M.fondoCamera
        } else if ControlloreScannerInquadra.dalVivo {
            ScannerInquadra(controllore: scanner)
        } else {
            M.fondoCamera
        }
    }

    private var scritta: some View {
        Text(testoScritta)
            .carattereApple(M.scritta)
            .foregroundColor(M.coloreScritta)
            .padding(M.paddingScritta)
            .background(Capsule(style: .continuous).fill(M.fondoScritta))
    }

    private var testoScritta: String {
        switch nuovoCliente.fase {
        case .lettura: return "Riconosco i dati…"
        case .illeggibile: return "Non riesco a leggere il documento"
        case .letto: return nuovoCliente.finito ? "✓ Fatto" : "Riconosco i dati…"
        case .attesa, .trascina:
            if nuovoCliente.facce > 0 { return "Inquadra il retro" }
            return scanner.righeViste > 0 ? "Tocca il pulsante per leggere" : "Inquadra il documento"
        }
    }

    // MARK: Il pannello

    private var pannello: some View {
        VStack(alignment: .leading, spacing: M.spazio) {
            switch nuovoCliente.fase {
            case .attesa, .trascina:
                pannelloCamera
            case .lettura:
                scritta
                Text("Sto leggendo…")
                    .carattereApple(M.titolo)
                    .foregroundColor(M.coloreTitolo)
            case .illeggibile:
                Text("Non riesco a leggere il documento: avvicinalo e cerca una luce senza riflessi")
                    .carattereApple(M.titolo)
                    .foregroundColor(M.coloreTitolo)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Riprova") { nuovoCliente.apriTelefono() }
                    .buttonStyle(.applePrimarioGrande)
            case .letto:
                pannelloLetto
            }
        }
        .padding(M.paddingPannello)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.superficiePannello, raggio: M.raggioPannello)
    }

    @ViewBuilder private var pannelloCamera: some View {
        HStack {
            scritta
            Spacer(minLength: 0)
        }
        if istantanea || ControlloreScannerInquadra.dalVivo {
            Text("Tieni la carta intera nel riquadro, senza riflessi. Prisma la legge qui sull’iPhone: al Mac va solo il testo, cifrato. L’immagine non si salva.")
                .carattereApple(M.frase)
                .foregroundColor(M.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer(minLength: 0)
                Button { scatta() } label: {
                    ZStack {
                        Circle().strokeBorder(M.coloreScatto, lineWidth: M.anelloScatto)
                            .frame(width: M.scatto, height: M.scatto)
                        Circle().fill(M.coloreScatto)
                            .frame(width: M.interScatto, height: M.interScatto)
                    }
                }
                .buttonStyle(StileSemplice())
                .accessibilityLabel(Text("Leggi la carta d’identità"))
                Spacer(minLength: 0)
            }
        } else if ControlloreScannerInquadra.scansioneDisponibile {
            Text("Su questo dispositivo la lettura dal vivo non c’è: scansiona la carta, poi Prisma la legge qui.")
                .carattereApple(M.frase)
                .foregroundColor(M.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
            Button("Scansiona la carta") { scansioneDocumenti = true }
                .buttonStyle(.applePrimarioGrande)
        } else {
            Text("La fotocamera non è disponibile: consenti a Prisma di usarla in Impostazioni › Prisma › Fotocamera.")
                .carattereApple(M.frase)
                .foregroundColor(M.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var pannelloLetto: some View {
        let righe = MotoreCartaIdentita.righe(nuovoCliente.lettura, correzioni: [:], oggi: Date())
        HStack {
            scritta
            Spacer(minLength: 0)
        }
        Text(nuovoCliente.finito ? MotoreCartaIdentita.sottotitolo(nuovoCliente.lettura) : "Leggo il documento")
            .carattereApple(M.titolo)
            .foregroundColor(M.coloreTitolo)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(righe.prefix(nuovoCliente.mostrate)), id: \.id) { r in
                rigaLetta(r)
                    .entrataStile(.rigaInquadra)
            }
        }
        if nuovoCliente.finito {
            if let r = nuovoCliente.ricevuta {
                Text(testoRicevuta(r))
                    .carattereApple(M.frase)
                    .foregroundColor(M.coloreFrase)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if nuovoCliente.ricevuta?.accettato == true {
                Button("Fatto") { nuovoCliente.chiudiTelefono() }
                    .buttonStyle(.applePrimarioGrande)
            } else {
                Button { stato.mandaCartaAlMac() } label: {
                    Label(nuovoCliente.inInvio ? "Mando…" : "Manda al Mac", systemImage: "desktopcomputer")
                }
                .buttonStyle(.applePrimarioGrande)
                .disabled(nuovoCliente.inInvio)
                HStack(spacing: M.spazio) {
                    if nuovoCliente.facce < PonteVera.massimeFacce {
                        Button("Aggiungi il retro") { nuovoCliente.preparaRetro() }
                            .buttonStyle(.appleGrande)
                            .disabled(nuovoCliente.inInvio)
                    }
                    Button("Rifai") { nuovoCliente.apriTelefono() }
                        .buttonStyle(.appleGrande)
                        .disabled(nuovoCliente.inInvio)
                }
            }
        }
    }

    private func rigaLetta(_ r: RigaNuovoCliente) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: S.spazioTesta) {
            Text(r.stato == .letta ? "✓" : (r.stato == .daGuardare ? "!" : "—"))
                .carattereApple(S.spunta)
                .foregroundColor(r.stato == .letta ? S.coloreSpunta : (r.stato == .daGuardare ? Tema.Apple.NuovoCliente.Scheda.coloreDaGuardare : S.coloreMancante))
                .frame(width: S.larghezzaSpunta, alignment: .leading)
            VStack(alignment: .leading, spacing: 0) {
                Text(r.etichetta)
                    .carattereApple(S.etichettaRiga)
                    .foregroundColor(S.coloreEtichettaRiga)
                Text(r.valore)
                    .carattereApple(r.stato == .mancante ? S.etichettaRiga : S.valore)
                    .foregroundColor(r.stato == .mancante ? S.coloreMancante : S.coloreValore)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, S.paddingRiga)
        .overlay(alignment: .bottom) { Rectangle().fill(S.filo).frame(height: Tema.Apple.Misura.bordo) }
        .accessibilityElement(children: .combine)
    }

    private func testoRicevuta(_ r: RicevutaPonte) -> String {
        if r.accettato { return "Mandata al Mac: lì crei il cliente con «Crea il dossier»." }
        if r.macIrraggiungibile { return "Il Mac non risponde: il documento resta qui finché chiudi questa schermata." }
        return r.motivo ?? PonteVera.macNonTrovato
    }

    private func scatta() {
        guard !istantanea else { return }
        Task { @MainActor in
            guard let foto = await scanner.scatta() else { return }
            stato.leggiFotoCarta(foto)
        }
    }
}

// MARK: - Lettura della foto e invio al Mac

extension StatoShell {
    /// La foto della carta: ridotta e letta con Vision sul telefono, in coda; solo in memoria, poi si dimentica.
    func leggiFotoCarta(_ foto: UIImage) {
        let giro = nuovoCliente.inizioLettura(origine: "", file: nil)
        let lato = CGFloat(Self.latoImmagineInquadra)
        Self.codaInquadra.async { [weak self] in
            let righe = autoreleasepool { () -> [RigaLetta]? in
                LetturaDocumenti.riconosciConRiquadri(Self.ridottaInquadra(foto, lato: lato))
            }
            DispatchQueue.main.async {
                guard let self, self.nuovoCliente.telefonoAperto else { return }
                guard let righe, !righe.isEmpty else {
                    self.nuovoCliente.illeggibile(origine: "", giroAtteso: giro)
                    return
                }
                self.nuovoCliente.mostra(righe: righe, origine: "", giroAtteso: giro)
            }
        }
    }

    /// «Manda al Mac»: il testo letto (righe con il riquadro, fronte e retro), mai l'immagine, sul ponte cifrato.
    /// Un Mac di prima (protocollo 2) lo si dice subito, senza tentare.
    @MainActor
    func mandaCartaAlMac() {
        guard !nuovoCliente.righe.isEmpty, !nuovoCliente.inInvio else { return }
        if let s = PonteVera.ultimo, !s.riceveCartaENota {
            nuovoCliente.ricevuta = .rifiutata(PonteVera.macDaAggiornare)
            return
        }
        let righe = nuovoCliente.righe.prefix(PonteVera.massimoRighe).map {
            RigaLetta(testo: String($0.testo.prefix(PonteVera.massimoTestoRiga)), riquadro: $0.riquadro)
        }
        let facce = min(PonteVera.massimeFacce, max(1, nuovoCliente.facce))
        let carta = CartaIdentitaPonte(dispositivo: String(UIDevice.current.name.prefix(PonteVera.massimoDispositivo)),
                                       righe: Array(righe), facce: facce)
        let vera = dati.impostazioni.vera
        nuovoCliente.inInvio = true
        nuovoCliente.ricevuta = nil
        Task { @MainActor [weak self] in
            let r = await PonteVera.manda(.cartaIdentita(carta), vera: vera)
            guard let self else { return }
            self.nuovoCliente.inInvio = false
            self.nuovoCliente.ricevuta = r
        }
    }
}
#endif
