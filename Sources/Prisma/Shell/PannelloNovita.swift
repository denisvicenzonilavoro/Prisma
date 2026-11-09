import SwiftUI

/// Il pannello «Le novità» della versione «Luce» (Design/template-luce-specifica.md §1.1): un vetro largo fino a 1180
/// centrato sotto la barra, sopra la scrivania, le finestre e le notifiche. In testa «✦ Le novità» e «29 funzioni da
/// provare»; sotto i due gruppi («Davanti al cliente · 15», «Per il tuo lavoro · 14»), ognuno una griglia a tre colonne
/// riga per riga (due colonne quando una colonna scenderebbe sotto 300, decisione 117). Ogni voce: il tassello colorato
/// con il glifo, il titolo e la frase su una riga sola; niente numero né freccia. Le voci entrano a cascata dal basso.
/// Il pannello scende come quello delle notifiche. Un clic su una voce porta dove vive la funzione
/// (`StatoShell.apriVoceNovita`); un clic fuori o Esc lo chiude. Con «Riduci movimento» pannello e voci compaiono già
/// fermi con la dissolvenza del contenitore; nelle istantanee sono subito nello stato finale.
struct PannelloNovita: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo

    private typealias N = Tema.Apple.Novita

    var body: some View {
        let _ = ContaCorpi.segna()
        GeometryReader { geo in
            let larghezza = max(0, min(N.larghezzaDueGruppi, geo.size.width - 2 * N.bordo))
            ZStack(alignment: .top) {
                // Un clic fuori dal pannello lo chiude (la barra resta sopra: la pillola lo richiude da sé)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { stato.chiudiNovita() }
                pannello(colonne: Self.colonne(larghezzaPannello: larghezza))
                    .frame(width: larghezza)
                    .frame(maxHeight: max(0, min(N.altezzaMassima, geo.size.height - N.dallAlto - N.basso)),
                           alignment: .top)
                    .entrataScheda(Tema.Apple.Moto.animazione(Tema.Apple.Moto.PannelloNovita.animazione, calmo: calmo),
                                   scala: Tema.Apple.Moto.PannelloNovita.scala, ancora: .center,
                                   y: Tema.Apple.Moto.PannelloNovita.spostamento)
                    .padding(.top, N.dallAlto)
                // Esc chiude il pannello (prima di dettaglio, notifiche e finestra)
                Button("Chiudi le novità") { stato.chiudiNovita() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(StileSemplice())
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    /// Tre colonne finché ognuna resta larga almeno 300, poi due.
    static func colonne(larghezzaPannello w: CGFloat) -> Int {
        let interno = w - 2 * N.padding
        let tre = (interno - CGFloat(N.colonne - 1) * N.spazioColonne) / CGFloat(N.colonne)
        return tre >= N.larghezzaMinimaColonna ? N.colonne : N.colonneStrette
    }

    private func pannello(colonne: Int) -> some View {
        VStack(alignment: .leading, spacing: N.spazioTestataDueGruppi) {
            testata
            // Alto quanto il contenuto; se la finestra è bassa, le voci scorrono
            ViewThatFits(in: .vertical) {
                gruppi(colonne: colonne)
                ScrollView { gruppi(colonne: colonne) }
                    .scrollIndicators(.hidden)
            }
        }
        .padding(N.padding)
        // Vetro che sfoca ciò che c'è sotto; senza sfocatura (istantanee) coprente
        .superficieApple(.vetroSopra, raggio: N.raggio)
    }

    private var testata: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("✦ Le novità")
                .carattereApple(N.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: N.spazioVoce)
            // «Le 25 novità di Vera» (NovitaVera.swift): il pannello del template di Vera, sopra la sua finestra
            Button { stato.apriNovitaVera() } label: {
                Text("✦ Le \(NovitaVera.allCases.count) novità di Vera")
                    .carattereApple(Tema.Apple.PannelloVeraNovita.pulsante)
                    .foregroundColor(Tema.Apple.PannelloVeraNovita.colorePulsante)
            }
            .buttonStyle(StileSemplice())
            .help("Le 25 novità di Vera, nei cinque gruppi")
            Text("\(NovitaLuce.allCases.count) funzioni da provare")
                .carattereApple(N.conteggio)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
        }
        .lineLimit(1)
    }

    private func gruppi(colonne: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(NovitaLuce.Gruppo.allCases.enumerated()), id: \.element) { g, gruppo in
                Text("\(gruppo.titolo) · \(gruppo.voci.count)")
                    .carattereApple(N.etichettaGruppo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(1)
                    .padding(.top, g == 0 ? N.sopraPrimoGruppo : N.sopraSecondoGruppo)
                    .padding(.bottom, N.sottoGruppo)
                    .accessibilityAddTraits(.isHeader)
                griglia(gruppo, colonne: colonne, primo: g == 0 ? 0 : NovitaLuce.Gruppo.davantiAlCliente.voci.count)
            }
        }
    }

    /// Le voci del gruppo riga per riga (prima riga 1, 2, 3…). Righe fisse, non una griglia pigra: nelle istantanee
    /// si disegna tutto subito. `primo`: l'indice della prima voce nella cascata delle 29.
    private func griglia(_ gruppo: NovitaLuce.Gruppo, colonne: Int, primo: Int) -> some View {
        let voci = gruppo.voci
        let n = max(1, colonne)
        let righe = stride(from: 0, to: voci.count, by: n).map { Array(voci[$0..<min($0 + n, voci.count)]) }
        return VStack(alignment: .leading, spacing: N.spazioVoci) {
            ForEach(Array(righe.enumerated()), id: \.offset) { r, riga in
                HStack(spacing: N.spazioColonne) {
                    ForEach(Array(riga.enumerated()), id: \.element) { c, voce in
                        RigaNovitaLuce(voce: voce)
                            .frame(maxWidth: .infinity)
                            .entrataVoceNovitaGriglia(primo + r * n + c)
                    }
                    // L'ultima riga incompleta tiene le colonne della griglia
                    ForEach(riga.count..<n, id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                    }
                }
            }
        }
    }
}

/// Una voce della griglia: il tassello colorato con il glifo, il titolo in grassetto e la frase in grigio, su una riga
/// sola con i puntini. Sotto il puntatore il fondo `chip`; le voci non si inclinano.
private struct RigaNovitaLuce: View {
    @Environment(StatoShell.self) var stato
    let voce: NovitaLuce
    @State private var sopra = false

    private typealias N = Tema.Apple.Novita

    var body: some View {
        let _ = ContaCorpi.segna()
        let forma = RoundedRectangle(cornerRadius: N.raggioVoce, style: .continuous)
        Button { stato.apriVoceNovita(voce) } label: {
            HStack(spacing: N.spazioVoceGriglia) {
                TasselloGlifo(glifo: voce.glifo, lato: N.tasselloVoce)
                VStack(alignment: .leading, spacing: 0) {
                    Text(voce.titolo)
                        .carattereApple(N.titoloVoceGriglia)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(voce.frase)
                        .carattereApple(N.fraseVoceGriglia)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(N.paddingVoceGriglia)
            .background {
                if sopra { forma.fill(N.fondoPassaggio) }
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { s in withAnimation(Tema.Apple.Moto.VoceNovita.passaggio) { sopra = s } }
        .accessibilityLabel(Text("\(voce.titolo): \(voce.frase)"))
        .accessibilityHint(Text("Apre \(voce.dove)"))
    }
}
