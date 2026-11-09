import SwiftUI

// La carta d'identità fac-simile del template (Design/template-luce-specifica.md §9.1.1, «Luce» giro 13): «CARTA
// D'IDENTITÀ» e «FAC-SIMILE», la foto con la sagoma, cinque campi (COGNOME, NOME, NATA IL, A, SCADENZA), il codice
// fiscale a tutta larghezza e la zona a lettura ottica. **Sempre la stessa carta, con i dati di prova dichiarati**
// (`CartaIdentitaFacSimile`): il documento vero non si disegna mai. I campi letti si accendono (anello verde e fondo
// verde al 14%). Valori in `Tema.Apple.NuovoCliente.Carta`; la carta è carta: chiara anche in scuro.

struct CartaIdentitaDisegnata: View {
    /// I campi letti da accendere.
    let accesi: Set<CampoCarta>

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto

    private typealias K = Tema.Apple.NuovoCliente.Carta

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: K.raggio, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Carta d’identità")
                    .carattereApple(K.intestazione)
                    .foregroundColor(K.inchiostroForte)
                Spacer(minLength: 0)
                Text("Fac-simile")
                    .carattereApple(K.facSimile)
                    .foregroundColor(K.inchiostroEtichetta)
            }
            HStack(alignment: .top, spacing: K.spazioFoto) {
                foto
                VStack(alignment: .leading, spacing: K.spazioCampi) {
                    campo("Cognome", CartaIdentitaFacSimile.cognome, .cognome)
                    campo("Nome", CartaIdentitaFacSimile.nome, .nome)
                    campo("Nata il", CartaIdentitaFacSimile.nascita, .dataNascita)
                    campo("A", CartaIdentitaFacSimile.luogo, .luogoNascita)
                    campo("Scadenza", CartaIdentitaFacSimile.scadenza, .scadenza)
                }
            }
            .padding(.top, K.spazioTesta)
            campo("Codice fiscale", CartaIdentitaFacSimile.codiceFiscale, .codiceFiscale)
                .padding(.top, K.fiscaleSopra)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(CartaIdentitaFacSimile.zonaDisegnata, id: \.self) { riga in
                    Text(riga)
                        .carattereApple(K.mrz)
                        .foregroundColor(K.inchiostroMrz)
                        .lineLimit(1)
                }
            }
            .padding(.top, K.mrzSopra)
        }
        .padding(K.padding)
        .background(forma.fill(LinearGradient(colors: K.fondo, startPoint: .topLeading, endPoint: .bottomTrailing)))
        .clipShape(forma)
        .shadow(color: K.ombra, radius: K.ombraRaggio, x: 0, y: K.ombraY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Carta d’identità fac-simile, dati di prova"))
    }

    /// La foto con la sagoma grigia (testa e spalle).
    private var foto: some View {
        let forma = RoundedRectangle(cornerRadius: K.raggioFoto, style: .continuous)
        return ZStack {
            forma.fill(K.fondoFoto)
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                ZStack {
                    Circle()
                        .fill(K.sagoma)
                        .frame(width: w * K.testaSagoma, height: w * K.testaSagoma)
                        .position(x: w / 2, y: h / 3)
                    Ellipse()
                        .fill(K.sagoma)
                        .frame(width: w * K.spalleSagoma.width, height: h * K.spalleSagoma.height)
                        .position(x: w / 2, y: h)
                }
            }
            .clipShape(forma)
        }
        .frame(width: K.foto.width, height: K.foto.height)
    }

    private func campo(_ etichetta: String, _ valore: String, _ c: CampoCarta) -> some View {
        let acceso = accesi.contains(c)
        let forma = RoundedRectangle(cornerRadius: K.raggioCampo, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Text(etichetta)
                .carattereApple(K.etichettaCampo)
                .foregroundColor(K.inchiostroEtichetta)
            Text(valore)
                .carattereApple(K.valoreCampo)
                .foregroundColor(K.inchiostroForte)
                .lineLimit(1)
        }
        .padding(K.paddingCampo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(forma.fill(acceso ? K.fondoLetto : Color.clear))
        .overlay(forma.strokeBorder(acceso ? K.coloreLetto : Color.clear, lineWidth: K.contornoLetto))
        .animation(calmo || scatto ? nil : Tema.Apple.Moto.Inquadra.accensione, value: acceso)
    }
}
