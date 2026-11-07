import SwiftUI

// Componenti dell'app Incontri: gettoni della testata, indicatore del percorso a passi,
// cifre chiave del dossier e variazioni dal riesame in capsula. Solo gettoni del tema (nel tema Apple:
// TemaIncontri.swift ricava colori e caratteri da Tema.Apple).

/// Gettone in capsula della testata (quando, tipo, durata) o di una priorità: simbolo facoltativo
/// del colore dato, testo in inchiostro.
struct GettoneIncontro: View {
    let testo: String
    var simbolo: String? = nil
    var colore: Color = Tema.Colore.Incontri.secondario
    var font: Font = Tema.Testo.Incontri.gettone
    /// Pallino in coda (per esempio l'importanza di una priorità).
    var pallino: Color? = nil

    var body: some View {
        let m = Tema.Misura.Incontri.self
        HStack(spacing: m.spazioSimboloGettone) {
            if let simbolo {
                Image(systemName: simbolo)
                    .foregroundColor(colore)
            }
            Text(testo)
                .foregroundColor(Tema.Colore.Incontri.testo)
                .lineLimit(1)
            if let pallino {
                Circle()
                    .fill(pallino)
                    .frame(width: m.pallino, height: m.pallino)
            }
        }
        .font(font)
        .padding(.horizontal, m.margineGettone)
        .frame(minHeight: m.gettone)
        .background { Capsule(style: .continuous).fill(Tema.Colore.Incontri.gettone) }
        .fixedSize()
    }
}

/// Un passo del percorso dell'incontro.
struct PassoPercorso: Identifiable {
    let scheda: SchedaIncontro
    let titolo: String
    let fatto: Bool
    var id: String { titolo }
}

/// Il percorso dell'incontro a passi (preparazione → ascolto → prossimi passi): cerchi numerati uniti da un filo.
/// Il passo aperto è pieno d'accento, quelli fatti hanno la spunta verde; ogni passo si tocca per aprirlo.
struct IndicatorePercorso: View {
    let passi: [PassoPercorso]
    @Binding var selezione: SchedaIncontro

    var body: some View {
        let m = Tema.Misura.Incontri.self
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(passi.enumerated()), id: \.element.id) { n, p in
                if n > 0 {
                    Capsule()
                        .fill(passi[n - 1].fatto ? Tema.Colore.Incontri.passoFatto : Tema.Colore.Incontri.filoPasso)
                        .frame(width: m.lunghezzaFilo, height: m.filoPasso)
                        .padding(.top, (m.passo - m.filoPasso) / 2)
                }
                passo(p, numero: n + 1)
            }
        }
        .fixedSize()
    }

    private func passo(_ p: PassoPercorso, numero: Int) -> some View {
        let m = Tema.Misura.Incontri.self
        let aperto = p.scheda == selezione
        return Button { selezione = p.scheda } label: {
            VStack(spacing: m.spazioPasso) {
                cerchio(p, numero: numero, aperto: aperto)
                Text(p.titolo)
                    .font(aperto ? Tema.Testo.Incontri.passo : Tema.Testo.Incontri.passoSpento)
                    .foregroundColor(aperto ? Tema.Colore.Incontri.testo : Tema.Colore.Incontri.secondario)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(minWidth: m.larghezzaPasso)
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .help(p.fatto ? "\(p.titolo): fatto" : p.titolo)
    }

    @ViewBuilder private func cerchio(_ p: PassoPercorso, numero: Int, aperto: Bool) -> some View {
        let m = Tema.Misura.Incontri.self
        let c = Tema.Colore.Incontri.self
        ZStack {
            if aperto {
                Circle().fill(c.passoCorrente)
            } else if p.fatto {
                Circle().fill(c.passoFattoFondo)
            } else {
                Circle().fill(c.passoDaFareFondo)
            }
            if p.fatto && !aperto {
                Image(systemName: "checkmark")
                    .font(Tema.Testo.Incontri.passoNumero)
                    .foregroundColor(c.passoFatto)
            } else {
                Text("\(numero)")
                    .font(Tema.Testo.Incontri.passoNumero)
                    .foregroundColor(aperto ? c.testoSuPasso : c.passoDaFare)
            }
        }
        .frame(width: m.passo, height: m.passo)
    }
}

/// Una cifra chiave del dossier: il numero grande, l'etichetta piccola sotto.
/// Con `numero` la cifra si conta fino al valore (`NumeroCheConta`, nello stato finale con «Riduci movimento»
/// e nelle istantanee); `valore` resta il testo per chi non ha un numero.
struct CifraIncontro: View {
    let valore: String
    let etichetta: String
    var colore: Color = Tema.Colore.Incontri.testo
    var numero: Double? = nil
    var formato: FormatoCifra = .intero
    var indice = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Tema.Misura.Incontri.spazioCifra) {
            cifra
                .font(Tema.Testo.Incontri.cifra)
                .foregroundColor(colore)
                .lineLimit(1)
                .minimumScaleFactor(Tema.Misura.Incontri.scalaMinimaCifra)
            Text(etichetta)
                .font(Tema.Testo.Incontri.cifraEtichetta)
                .foregroundColor(Tema.Colore.Incontri.secondario)
                .lineLimit(1)
        }
    }

    @ViewBuilder private var cifra: some View {
        if let numero {
            NumeroCheConta(numero, formato: formato, indice: indice)
        } else {
            Text(valore)
        }
    }
}

/// Una variazione dal riesame precedente in capsula: freccia del verso, tema e differenza
/// («↘ Pensione −200 €/mese»); la frase intera resta nel suggerimento.
struct GettoneVariazione: View {
    let variazione: VariazioneRiesame

    private var simbolo: String {
        switch variazione.aumento {
        case true?: return "arrow.up.right"
        case false?: return "arrow.down.right"
        case nil: return "arrow.left.arrow.right"
        }
    }

    var body: some View {
        let m = Tema.Misura.Incontri.self
        HStack(spacing: m.spazioSimboloGettone) {
            Image(systemName: simbolo)
                .foregroundColor(Tema.Colore.Memoria.verso(variazione.verso))
            Text(variazione.tema.nome)
                .foregroundColor(Tema.Colore.Incontri.testo)
            if let d = variazione.differenza {
                Text(d)
                    .foregroundColor(Tema.Colore.Memoria.verso(variazione.verso))
            }
            if let c = variazione.canale {
                Circle()
                    .fill(Tema.Apple.AltreApp.canale(c))
                    .frame(width: m.pallino, height: m.pallino)
            }
        }
        .font(Tema.Testo.Incontri.variazione)
        .lineLimit(1)
        .padding(.horizontal, m.margineGettone)
        .frame(minHeight: m.gettone)
        .background { Capsule(style: .continuous).fill(Tema.Colore.Incontri.gettone) }
        .fixedSize()
        .help("\(variazione.testo) · prima \(variazione.prima), oggi \(variazione.oggi)")
    }
}
