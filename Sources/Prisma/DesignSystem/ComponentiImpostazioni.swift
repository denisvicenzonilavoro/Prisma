import SwiftUI

extension Tema.Misura.Componenti {
    /// Riga di un gruppo delle impostazioni (.g-row): margini e altezza minima.
    static let margineRiga = EdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14)
    static let altezzaRiga: CGFloat = 46
    /// Rientro del titolo di un gruppo (.g-title).
    static let rientroTitoloGruppo: CGFloat = 6
}

extension Tema.Testo.Componenti {
    /// Titolo di un gruppo delle impostazioni (.g-title: 12/600).
    static let titoloGruppo = Tema.Testo.sf(12, .semibold)
    /// Freccia a destra del valore di una riga.
    static let frecciaRiga = Tema.Testo.sf(11, .semibold)
}

/// Fondo delle Impostazioni: nessuna trama, si vede il vetro della finestra.
struct FondoRighe: View {
    var body: some View {
        Color.clear
    }
}

/// Interruttore del tema (.tg): capsula 44 × 26, verde se acceso, pomello bianco che scorre a molla.
/// Si anima solo l'interruttore, non ciò che compare o sparisce con lui.
struct StileInterruttore: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        InterruttoreImpostazioni(configuration: configuration)
    }
}

/// L'interruttore del tema, oppure quello del tema Apple dentro le Impostazioni (`.impostazioniApple()`).
private struct InterruttoreImpostazioni: View {
    let configuration: ToggleStyleConfiguration
    @Environment(\.impostazioniApple) private var apple

    var body: some View {
        if apple {
            StileInterruttoreApple(conEtichetta: false).makeBody(configuration: configuration)
        } else {
            InterruttoreTema(configuration: configuration)
        }
    }
}

/// Il disegno dell'interruttore del tema (.tg).
private struct InterruttoreTema: View {
    let configuration: ToggleStyleConfiguration

    var body: some View {
        let m = Tema.Misura.interruttore
        let p = Tema.Misura.pomello
        let acceso = configuration.isOn
        return Button {
            configuration.isOn.toggle()
        } label: {
            ZStack(alignment: acceso ? .trailing : .leading) {
                FormaVetro.capsula.fill(acceso ? Tema.Colore.verde : Tema.Colore.pozzettoScuro)
                Circle()
                    .fill(Tema.Colore.pomello)
                    .overlay { Circle().strokeBorder(Tema.Colore.Componenti.bordoPomello, lineWidth: Tema.Misura.filo) }
                    .frame(width: p, height: p)
                    .ombraTema(Tema.Ombra.pomello)
                    .padding((m.height - p) / 2)
            }
            .animation(Movimenti.curva(Tema.Moto.Controlli.interruttore), value: acceso)
            .frame(width: m.width, height: m.height)
            .contentShape(FormaVetro.capsula)
        }
        .buttonStyle(StileSemplice())
    }
}

/// Gruppo di righe delle impostazioni (.group): scheda arrotondata del tema, titolo sopra.
struct GruppoImpostazioni<Contenuto: View>: View {
    var titolo: String? = nil
    @ViewBuilder let contenuto: () -> Contenuto
    @Environment(\.impostazioniApple) private var apple

    var body: some View {
        if apple {
            corpoApple
        } else {
            corpo
        }
    }

    /// Nel tema Apple: niente scheda comune, ogni riga è la sua card (10 fra le righe); il titolo è un `.lbl`.
    private var corpoApple: some View {
        let g = Tema.Apple.Impostazioni.Gruppo.self
        return VStack(alignment: .leading, spacing: 0) {
            if let titolo {
                Text(titolo)
                    .carattereApple(g.etichetta)
                    .foregroundColor(g.coloreEtichetta)
                    .lineLimit(1)
                    .padding(.leading, g.rientroEtichetta)
                    .padding(.bottom, g.sottoEtichetta)
            }
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                contenuto()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var corpo: some View {
        let forma = FormaVetro.arrotondata(Tema.Raggio.gruppo)
        VStack(alignment: .leading, spacing: 6) {
            if let titolo {
                Text(titolo)
                    .font(Tema.Testo.Componenti.titoloGruppo)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .padding(.leading, Tema.Misura.Componenti.rientroTitoloGruppo)
            }
            VStack(spacing: 0) {
                contenuto()
            }
            .clipShape(forma)
            .vetro(.sottile, forma: forma)
        }
    }
}

/// Riga di un gruppo (.g-row): icona di vetro facoltativa, titolo, sottotitolo di poche parole (al massimo
/// due righe: il testo lungo va in `aiuto`, che compare al passaggio), stato come pillola (.pill) e accessorio a
/// destra, separatore sottile.
struct RigaImpostazione<Accessorio: View>: View {
    let titolo: String
    var sottotitolo: String? = nil
    /// L'icona di vetro accanto al titolo (.ic piccola).
    var icona: IconaVetroImpostazioni? = nil
    /// Lo stato a destra, prima dell'accessorio («Pronta», «Attivi», «Non consentiti»).
    var stato: Pillola? = nil
    /// La spiegazione lunga: al passaggio del puntatore (.help), non nella riga.
    var aiuto: String? = nil
    var avvertenza: String? = nil
    var ultima = false
    @ViewBuilder let accessorio: () -> Accessorio
    @Environment(\.impostazioniApple) private var apple

    var body: some View {
        if apple {
            corpoApple
        } else {
            corpo
        }
    }

    /// Nel tema Apple: card senza ombra (padding 16×20), titolo 15 bold, spiegazione `.k`, lo stato come pallino e
    /// il controllo a destra.
    private var corpoApple: some View {
        let r = Tema.Apple.Impostazioni.Riga.self
        return HStack(alignment: .center, spacing: r.spazioControllo) {
            HStack(alignment: .center, spacing: r.spazioIcona) {
                if let icona { icona }
                VStack(alignment: .leading, spacing: r.sottoTitolo) {
                    Text(titolo)
                        .carattereApple(r.titolo)
                        .foregroundColor(r.coloreTitolo)
                        .fixedSize(horizontal: false, vertical: true)
                    if let sottotitolo {
                        Text(sottotitolo)
                            .carattereApple(r.spiegazione)
                            .foregroundColor(r.coloreSpiegazione)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let avvertenza {
                        Text(avvertenza)
                            .carattereApple(r.avvertenza)
                            .foregroundColor(r.coloreAvvertenza)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .modifier(AiutoFacoltativo(testo: aiuto))
            .frame(maxWidth: .infinity, alignment: .leading)
            if let stato {
                StatoRigaApple(testo: stato.testo, tono: stato.tono)
            }
            accessorio()
        }
        .padding(r.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(r.superficie, raggio: r.raggio)
    }

    private var corpo: some View {
        HStack(spacing: 16) {
            HStack(spacing: Tema.Misura.Impostazioni.spazioIcona) {
                if let icona { icona }
                VStack(alignment: .leading, spacing: 2) {
                    Text(titolo)
                        .font(Tema.Testo.Componenti.voce)
                        .foregroundColor(Tema.Colore.inchiostro)
                    if let sottotitolo {
                        Text(sottotitolo)
                            .font(Tema.Testo.secondario)
                            .foregroundColor(Tema.Colore.inchiostroSecondario)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let avvertenza {
                        Text(avvertenza)
                            .font(Tema.Testo.secondario)
                            .foregroundColor(Tema.Colore.scadenzaOra)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            // Un sottotitolo troppo lungo per due righe si legge per intero al passaggio
            .modifier(AiutoFacoltativo(testo: testoAiuto))
            Spacer(minLength: 8)
            if let stato { stato }
            accessorio()
        }
        .padding(Tema.Misura.Componenti.margineRiga)
        .frame(minHeight: Tema.Misura.Componenti.altezzaRiga)
        .overlay(alignment: .bottom) {
            if !ultima {
                Rectangle().fill(Tema.Colore.separatore).frame(height: Tema.Misura.filo)
            }
        }
    }
}

extension RigaImpostazione {
    /// Il testo al passaggio: `aiuto`, oppure il sottotitolo quando è troppo lungo per le sue due righe.
    var testoAiuto: String? {
        if let aiuto { return aiuto }
        guard let sottotitolo, sottotitolo.count > Tema.Misura.Impostazioni.caratteriSottotitolo else { return nil }
        return sottotitolo
    }
}

/// `.help` solo quando c'è un testo (niente suggerimenti vuoti).
private struct AiutoFacoltativo: ViewModifier {
    let testo: String?

    @ViewBuilder func body(content: Content) -> some View {
        if let testo, !testo.isEmpty {
            content.help(testo)
        } else {
            content
        }
    }
}

/// Icona di vetro delle Impostazioni (.ic): l'icona dell'app, oppure un simbolo bianco su un fondo colorato a
/// 165° con il riflesso dall'alto e un filo di luce, angoli al 23,5% del lato.
struct IconaVetroImpostazioni: View {
    let icona: SchedaImpostazioni.Icona
    var lato: CGFloat = Tema.Misura.Impostazioni.iconaRiga

    init(_ icona: SchedaImpostazioni.Icona, lato: CGFloat = Tema.Misura.Impostazioni.iconaRiga) {
        self.icona = icona
        self.lato = lato
    }

    /// Un simbolo SF sul vetro colorato.
    init(simbolo: String, colori: ColoriIconaApp, lato: CGFloat = Tema.Misura.Impostazioni.iconaRiga) {
        self.init(.simbolo(simbolo, colori), lato: lato)
    }

    var body: some View {
        switch icona {
        case .app(let app):
            IconaApp(app: app, lato: lato)
        case .simbolo(let simbolo, let colori):
            simboloSuVetro(simbolo, colori)
        }
    }

    private func simboloSuVetro(_ simbolo: String, _ colori: ColoriIconaApp) -> some View {
        let c = Tema.Colore.Impostazioni.self
        let m = Tema.Misura.Impostazioni.self
        let forma = RoundedRectangle(cornerRadius: lato * m.raggioIcona, style: .continuous)
        return Image(systemName: simbolo)
            .font(Tema.Testo.Impostazioni.simboloIcona(lato))
            .foregroundColor(c.simboloIcona)
            .shadow(color: c.ombraIcona, radius: lato * m.ombraSimbolo, x: 0, y: lato * m.ombraSimboloY)
            .frame(width: lato, height: lato)
            .background {
                forma.fill(LinearGradient(colors: [colori.alto, colori.basso],
                                          startPoint: m.inizioFondo, endPoint: m.fineFondo))
            }
            .overlay {
                forma.fill(LinearGradient(colors: c.riflessoIcona, startPoint: .top, endPoint: .bottom))
                    .allowsHitTesting(false)
            }
            .overlay { forma.strokeBorder(c.filoIcona, lineWidth: Tema.Misura.filo).allowsHitTesting(false) }
            .accessibilityHidden(true)
    }
}

/// Voce della barra laterale delle Impostazioni (.side-item con l'icona da 24): come `VoceNavigazione`
/// (stessi margini, stesso fondo al passaggio e della scelta, stesso `idScelta`), con l'icona di vetro.
struct VoceImpostazioni: View {
    let pagina: SchedaImpostazioni
    let attiva: Bool
    var stato: Pillola? = nil
    let azione: () -> Void

    var body: some View {
        let m = Tema.Misura.Componenti.self
        Button(action: azione) {
            HStack(spacing: Tema.Misura.Impostazioni.spazioIcona) {
                IconaVetroImpostazioni(pagina.icona, lato: Tema.Misura.Impostazioni.iconaVoce)
                Text(pagina.titolo)
                    .font(Tema.Testo.Componenti.voce)
                    .foregroundColor(Tema.Colore.inchiostro)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if let stato { stato }
            }
            .padding(m.voceLaterale)
            .frame(minHeight: m.voceLateraleMinima)
            .frame(maxWidth: .infinity)
            .fondoPassaggio(.arrotondata(Tema.Raggio.voceLaterale), selezionata: attiva)
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .accessibilityLabel(pagina.titolo)
        .background {
            if attiva { Color.clear.id(VoceNavigazione.idScelta) }
        }
    }
}

/// Titolo della pagina (.set-h: 22/700).
struct TitoloPaginaImpostazioni: View {
    let testo: String
    @Environment(\.impostazioniApple) private var apple

    var body: some View {
        if apple {
            // `.h2` con 4 sopra e 14 sotto
            let p = Tema.Apple.Impostazioni.Pagina.self
            Text(testo)
                .carattereApple(p.titolo)
                .foregroundColor(p.coloreTitolo)
                .padding(.top, p.sopraTitolo)
                .padding(.bottom, p.sottoTitolo)
        } else {
            corpo
        }
    }

    private var corpo: some View {
        Text(testo)
            .font(Tema.Testo.Impostazioni.titoloPagina)
            .tracking(Tema.Testo.Impostazioni.spaziaturaTitolo)
            .foregroundColor(Tema.Colore.inchiostro)
            .padding(.bottom, Tema.Misura.Impostazioni.sottoTitolo)
    }
}

/// Nota sotto un gruppo (.g-note: 12, una frase), vicina al gruppo che spiega.
struct NotaImpostazioni: View {
    let testo: String
    var colore: Color = Tema.Colore.inchiostroSecondario

    @Environment(\.impostazioniApple) private var apple

    init(_ testo: String, colore: Color = Tema.Colore.inchiostroSecondario) {
        self.testo = testo
        self.colore = colore
    }

    var body: some View {
        if apple {
            let n = Tema.Apple.Impostazioni.Nota.self
            Text(testo)
                .carattereApple(n.carattere)
                .foregroundColor(n.colore)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, n.rientro)
        } else {
            corpo
        }
    }

    private var corpo: some View {
        Text(testo)
            .font(Tema.Testo.Impostazioni.nota)
            .foregroundColor(colore)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Tema.Misura.Impostazioni.rientroNota)
            .padding(.top, Tema.Misura.Impostazioni.notaSopra)
    }
}

/// Tessera di stato della Panoramica (.tile): icona e pillola in alto, etichetta, valore grande, nota.
/// Toccata, porta alla pagina che la riguarda.
struct TesseraImpostazioni: View {
    let pagina: SchedaImpostazioni
    let etichetta: String
    let valore: String
    let nota: String
    let stato: Pillola
    let azione: () -> Void
    @Environment(\.impostazioniApple) private var apple

    var body: some View {
        if apple {
            corpoApple
        } else {
            corpo
        }
    }

    /// Nel tema Apple: tile (padding 14×16, raggio 18), lo stato come pallino, il valore 22 bold.
    private var corpoApple: some View {
        let t = Tema.Apple.Impostazioni.Tessera.self
        return Button(action: azione) {
            VStack(alignment: .leading, spacing: t.spazio) {
                HStack(alignment: .center) {
                    Text(etichetta)
                        .carattereApple(t.etichetta)
                        .foregroundColor(t.coloreEtichetta)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    StatoRigaApple(testo: stato.testo, tono: stato.tono)
                }
                .padding(.bottom, t.sottoTesta)
                Text(valore)
                    .carattereApple(t.valore)
                    .foregroundColor(t.coloreValore)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(nota)
                    .carattereApple(t.nota)
                    .foregroundColor(t.coloreNota)
                    .lineLimit(1)
            }
            .padding(t.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(t.superficie, raggio: t.raggio)
            .contentShape(RoundedRectangle(cornerRadius: t.raggio, style: .continuous))
        }
        .buttonStyle(StileSemplice())
        .accessibilityLabel("\(etichetta): \(valore)")
    }

    @ViewBuilder private var corpo: some View {
        let m = Tema.Misura.Impostazioni.self
        let forma = FormaVetro.arrotondata(Tema.Raggio.tessera)
        Button(action: azione) {
            VStack(alignment: .leading, spacing: m.spazioTessera) {
                HStack(alignment: .top) {
                    IconaVetroImpostazioni(pagina.icona, lato: m.iconaTessera)
                    Spacer(minLength: 6)
                    stato
                }
                Text(etichetta)
                    .font(Tema.Testo.Impostazioni.etichettaTessera)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
                Text(valore)
                    .font(Tema.Testo.Impostazioni.valoreTessera)
                    .foregroundColor(Tema.Colore.inchiostro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(nota)
                    .font(Tema.Testo.Impostazioni.notaTessera)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
            }
            .padding(m.margineTessera)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fondoPassaggio(forma)
            .vetro(.sottile, forma: forma)
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .accessibilityLabel("\(etichetta): \(valore)")
    }
}

/// Una scorciatoia scritta come i tasti (kbd): una capsula a pozzetto per tasto.
struct TastiScorciatoia: View {
    let tasti: [String]

    var body: some View {
        HStack(spacing: Tema.Misura.Impostazioni.spazioTasti) {
            ForEach(Array(tasti.enumerated()), id: \.offset) { _, t in
                TastoBarra(testo: t)
            }
        }
        .fixedSize()
    }
}

/// Valore a destra di una riga, con la freccia ("Denis ›").
struct ValoreRiga: View {
    let testo: String
    let azione: () -> Void
    @Environment(\.impostazioniApple) private var apple

    var body: some View {
        if apple {
            // Nel tema Apple: il pulsante a capsula `.btn` («Scegli…», «Ripristina…»)
            Button(testo, action: azione)
                .buttonStyle(.apple)
                .fixedSize()
        } else {
            corpo
        }
    }

    private var corpo: some View {
        Button(action: azione) {
            HStack(spacing: 5) {
                Text(testo)
                    .font(Tema.Testo.corpo)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                Image(systemName: "chevron.right")
                    .font(Tema.Testo.Componenti.frecciaRiga)
                    .foregroundColor(Tema.Colore.inchiostroTerziario)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
    }
}

/// Schede di un'app: controllo a segmenti del tema, largo quanto i testi. Se lo spazio non basta, la
/// versione compatta: mai una parola tagliata.
struct SchedeApp<Valore: Hashable>: View {
    let opzioni: [(Valore, String)]
    @Binding var selezione: Valore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ControlloSegmenti(opzioni: opzioni, selezione: $selezione)
                .fixedSize()
            ControlloSegmenti(opzioni: opzioni, selezione: $selezione, compatto: true)
                .fixedSize()
        }
    }
}
