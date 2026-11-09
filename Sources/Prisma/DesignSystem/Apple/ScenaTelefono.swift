import SwiftUI

// Il telefono disegnato e il velo della scena (Design/template-luce-specifica.md §1.4.1, punto 4.2): estratti da
// Inquadra e capisci (Shell/ScenaInquadra.swift) perché servono anche a Nuovo cliente in 10 secondi e alla Nota vocale
// (dentro il velo), al Prisma del cliente e al sinistro (nel palco). Stessi valori di prima (`Tema.Apple.Apparecchio`,
// `Tema.Apple.VeloScena`): le istantanee di Inquadra (600-609) restano identiche. Entrata, rotazione ed Esc restano a
// chi usa il telefono: qui solo il disegno.

/// L'iPhone disegnato (300×620, raggio 50, corpo scuro con il filo, tacca in alto, schermo rientrato di 11 con raggio
/// 40): lo schermo lo dà chi lo usa, ritagliato nella sua forma.
struct TelefonoDisegnato<Schermo: View>: View {
    let schermo: Schermo

    private typealias A = Tema.Apple.Apparecchio

    init(@ViewBuilder schermo: () -> Schermo) {
        self.schermo = schermo()
    }

    var body: some View {
        let corpo = RoundedRectangle(cornerRadius: A.raggio, style: .continuous)
        ZStack(alignment: .top) {
            corpo
                .fill(A.corpo)
                .shadow(color: A.ombra, radius: A.ombraRaggio, x: 0, y: A.ombraY)
            corpo.strokeBorder(A.filo, lineWidth: A.spessoreFilo)
            schermo
                .clipShape(RoundedRectangle(cornerRadius: A.raggioSchermo, style: .continuous))
                .padding(A.rientro)
            RoundedRectangle(cornerRadius: A.raggioTacca, style: .continuous)
                .fill(A.coloreTacca)
                .frame(width: A.tacca.width, height: A.tacca.height)
                .padding(.top, A.taccaDallAlto)
        }
        .frame(width: A.larghezza, height: A.altezza)
    }
}

/// Lo schermo vuoto del telefono (fondo #1A1D21), per la vetrina e per le scene che non hanno ancora il contenuto.
struct SchermoTelefonoVuoto: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Tema.Apple.Apparecchio.raggioSchermo, style: .continuous)
            .fill(Tema.Apple.Apparecchio.schermo)
    }
}

/// Il velo scuro sfocato della scena del telefono, uguale in chiaro e in scuro. Un clic qui non fa nulla (chiudere per
/// sbaglio a metà lettura sarebbe fastidioso): la scena si chiude con ✕ o con Esc.
struct VeloScena: View {
    @Environment(\.modoIstantanea) private var istantanea

    private typealias V = Tema.Apple.VeloScena

    var body: some View {
        let fermo = istantanea || Vetro.semplificato
        ZStack {
            if !fermo {
                Rectangle().fill(V.materiale)
            }
            Rectangle().fill(fermo ? V.coloreFermo : V.colore)
        }
        .contentShape(Rectangle())
        .onTapGesture {}
        .accessibilityHidden(true)
    }
}

/// L'iPad disegnato del palco della realtà aumentata («Luce» giro 16, §2.3.1): 944×560, raggio 42, corpo scuro con il
/// gradiente a 145°, filo interno, fotocamera frontale sul lato sinistro e schermo nero rientrato di 15 con raggio 28.
/// Lo schermo lo dà chi lo usa, ritagliato nella sua forma.
struct CorniceiPad<Schermo: View>: View {
    let schermo: Schermo

    private typealias I = Tema.Apple.RealtaAumentata.CorniceiPad

    init(@ViewBuilder schermo: () -> Schermo) {
        self.schermo = schermo()
    }

    var body: some View {
        let corpo = RoundedRectangle(cornerRadius: I.raggio, style: .continuous)
        ZStack(alignment: .leading) {
            corpo
                .fill(LinearGradient(stops: [.init(color: I.fondoInizio, location: 0),
                                             .init(color: I.fondoFine, location: I.fermataFondo)],
                                     startPoint: I.inizio, endPoint: I.fine))
                .shadow(color: I.ombra, radius: I.raggioOmbra, x: 0, y: I.scostamentoOmbra - I.rientroOmbra)
            corpo.strokeBorder(I.filo, lineWidth: I.spessoreFilo)
            Circle()
                .fill(I.coloreFotocamera)
                .frame(width: I.fotocamera, height: I.fotocamera)
                .padding(.leading, (I.margine - I.fotocamera) / 2)
            ZStack {
                RoundedRectangle(cornerRadius: I.raggioSchermo, style: .continuous).fill(I.schermo)
                schermo
            }
            .clipShape(RoundedRectangle(cornerRadius: I.raggioSchermo, style: .continuous))
            .padding(I.margine)
        }
        .frame(width: I.dimensione.width, height: I.dimensione.height)
    }
}
