#if os(iOS)
import SwiftUI

/// La scrivania dell'iPad nel tema Apple (Design/template-apple-specifica.md §3.6 e §5.1): la stessa del Mac fra la
/// barra e il dock, con gli stessi riquadri di Shell/ScrivaniaApple.swift (`RiquadriScrivania`): il saluto con
/// «Nuovo cliente» e «Cerca ovunque», la guida compatta «Comincia con i tuoi dati» sotto il saluto, la mossa del
/// giorno a tutta larghezza, poi Agenda di oggi, Portafoglio clienti con i tre anelli, Ruby, Da fare oggi e
/// In scadenza. In orizzontale la disposizione del Mac; in verticale (sotto i 1100 punti) tre righe a due colonne.
/// Se l'altezza non basta la scrivania scorre. Sul touch niente passaggio: alla pressione i riquadri scendono a 0,98.
/// Un tocco sul fondo libero fa cadere una goccia sull'acqua; un tocco sul riquadro di Ruby apre la sua app.
struct ScrivaniaiPad: View {
    /// Dove comincia la scrivania (sotto la barra) e quanto lasciare in basso (il dock).
    let alto: CGFloat
    let basso: CGFloat

    var body: some View {
        GeometryReader { geo in
            let d = Tema.Apple.Scrivania.Disposizione.self
            // Margine laterale: 3% della larghezza, fra 16 e 44 punti; contenuto al massimo 1600, centrato
            let margine = min(max(geo.size.width * d.quotaMargine, d.margineMinimo), d.margine)
            let larghezza = max(0, min(geo.size.width - 2 * margine, d.larghezzaMassima))
            let minima = Self.altezzaMinima(larghezza)
            Group {
                if geo.size.height >= minima {
                    RiquadriScrivania()
                        .frame(width: larghezza, height: geo.size.height)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        RiquadriScrivania()
                            .frame(width: larghezza, height: minima)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .padding(.top, alto)
        .padding(.bottom, basso)
        // Un tocco sul fondo libero (non su riquadri, pulsanti o testi) fa cadere una goccia sull'acqua
        .gocciaAlTocco()
    }

    /// L'altezza sotto cui i riquadri si schiaccerebbero: da lì in giù la scrivania scorre.
    static func altezzaMinima(_ larghezza: CGFloat) -> CGFloat {
        let p = Tema.Apple.Scrivania.iPad.self
        return RiquadriScrivania.dueColonne(larghezza) ? p.altezzaMinimaStretta : p.altezzaMinimaLarga
    }
}
#endif
