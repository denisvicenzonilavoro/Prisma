#if os(macOS)
import SwiftUI

/// Le istantanee di «Il prodotto sul cliente» (12 novembre 2026), il foglio messo sopra la shell con il velo (i fogli
/// non si disegnano fuori schermo):
/// - 900: il primo passo, il catalogo con la ricerca e il canale (dossier di Giulia, chiaro e scuro);
/// - 901: il secondo passo, il piano di risparmio del catalogo di prova come proposta per Giulia;
/// - 902: lo stesso come posizione in essere (valore di oggi e numero di contratto).
extension Istantanee {
    nonisolated static var sceneProdottoCliente: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("900-prodotto-sul-cliente-catalogo", { s in giulia(s) }),
            ("900-prodotto-sul-cliente-catalogo-scuro", { s in giulia(s) }),
            ("901-prodotto-sul-cliente-dati", { s in giulia(s) }),
            ("902-prodotto-sul-cliente-in-essere", { s in giulia(s) }),
        ]
    }

    nonisolated private static func giulia(_ s: StatoShell) {
        s.clienteAttivoId = "giulia"
        s.apri(.posizioni)
    }

    /// La shell con sopra il foglio; nil per le altre scene.
    static func moduloProdottoClienteIstantanea(_ nome: String, _ s: StatoShell) -> AnyView? {
        guard nome.hasPrefix("90"), sceneProdottoCliente.contains(where: { $0.nome == nome }) else { return nil }
        let prodotto: Prodotto? = nome.hasPrefix("900") ? nil
            : s.prodotto("prodotto-risparmio-rivalutabile") ?? s.dati.prodotti.first
        let statoIniziale: StatoPosizione = nome.hasPrefix("902") ? .inEssere : .proposta
        return AnyView(
            ZStack {
                ShellView()
                Tema.Colore.velo
                ModuloProdottoSulCliente(prodotto: prodotto, statoIniziale: statoIniziale, clienteId: "giulia",
                                         clienteScelto: false, tuttiICampi: { _ in })
                    // Il foglio vero ha il fondo del sistema: qui serve pieno, o la shell passerebbe attraverso
                    .background(Tema.Apple.Colore.cardPiena)
                    .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.finestra, style: .continuous))
                    .ombraApple(.finestra)
            }
        )
    }
}
#endif
