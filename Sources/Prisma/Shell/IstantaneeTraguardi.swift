#if os(macOS)
import AppKit
import SwiftUI

/// Le istantanee dei traguardi festeggiati in Messaggi (Design/template-luce-specifica.md §5.4.7, «Luce» giro 5), tutte
/// nello stato finale (cifra completa, anello pieno, niente coriandoli, pulsanti nello stato iniziale):
/// - 730: Messaggi con il gruppo «Da festeggiare», il traguardo di Sofia (obiettivo raggiunto ieri), chiaro e scuro; dal
///   giro 15 la riga «Il biglietto» con «Condividi…», il menu «…» e l'interruttore «Mostra la cifra» spento (il biglietto
///   dell'anteprima è senza cifra: si vede ciò che parte) e, sotto le tre righe, la tile della capsula del tempo di Sofia
///   se c'è una capsula pronta (parte 15c);
/// - 731: «Un anno insieme» di Giulia, chiaro e scuro;
/// - 732: telefonata «✓ In agenda» e regalo «✓ Annotata»;
/// - 733: nessuna idea dalle note (la frase è quella di Prisma);
/// - 734: modalità cliente: dal giro 12 Messaggi è fra le app riservate (decisione 50), quindi la scena mostra l'avviso
///   «In modalità cliente Messaggi non si apre…» invece del biglietto (domanda aperta per l'utente);
/// - 735: il PNG vero del biglietto (`EsportaBiglietto.png`, il file che parte dal foglio di condivisione), senza la
///   cifra come di base; `735-biglietto-traguardo-con-cifra` lo stesso con «Mostra la cifra» acceso («Luce» giro 15).
/// L'iPhone (736) non è in questo giro.
/// DATI DI PROVA DICHIARATI: i due traguardi di `TraguardiDiProva` (e quelli di `MessaggiDiProva` per le altre voci).
extension Istantanee {
    nonisolated static var sceneTraguardi: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("730-messaggi-traguardo", { s in MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "sofia") }),
            ("730-messaggi-traguardo-scuro", { s in MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "sofia") }),
            ("731-messaggi-traguardo-anniversario", { s in MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "giulia") }),
            ("731-messaggi-traguardo-anniversario-scuro", { s in MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "giulia") }),
            ("732-messaggi-traguardo-fatto", { s in
                if let t = s.traguardi().first(where: { $0.clienteId == "sofia" }) {
                    s.aggiungiTelefonataTraguardo(t)
                    s.annotaRegaloTraguardo(t, testo: t.ideaRegalo?.testo ?? "")
                }
                MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "sofia")
            }),
            ("733-messaggi-traguardo-senza-regalo", { s in
                if let i = s.dati.obiettivi.firstIndex(where: { $0.id == TraguardiDiProva.obiettivoSofia }) { s.dati.obiettivi[i].note = "" }
                MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "sofia")
            }),
            // «Luce» giro 12: Messaggi riservata in modalità cliente, la scena è la prova visiva dell'avviso
            ("734-messaggi-traguardo-modo-cliente", { s in
                s.clienteAttivoId = "sofia"
                s.entraModoCliente(avviso: false)
                MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "sofia")
            }),
            // Disegnati da `tavolaLuce` (IstantaneeLuce.swift): il PNG vero del biglietto, senza e con la cifra
            ("735-biglietto-traguardo", { _ in }),
            ("735-biglietto-traguardo-con-cifra", { _ in }),
        ]
    }

    /// Il biglietto di Sofia (dati di prova) da solo, su un fondo neutro: l'immagine è il PNG vero di
    /// `EsportaBiglietto.png` (560×420 a scala 2), lo stesso file che parte dal foglio di condivisione.
    static func tavolaBiglietto(conCifra: Bool = false) -> AnyView {
        let dati = DatiPrisma.demo()
        let t = MotoreTraguardi.calcola(dati: dati, oggi: Date()).first { $0.clienteId == "sofia" }
        let firma = ModelliMessaggi.firma(nil, tono: .cordiale, impostazioni: dati.impostazioni)
        let png = t.flatMap { EsportaBiglietto.png($0, firma: firma, mostraCifra: conCifra, frase: nil) }
        let immagine = png.flatMap { NSImage(data: $0) }
        let misura = Tema.Apple.Messaggi.Traguardo.biglietto
        return AnyView(
            ZStack {
                Tema.Apple.Parcelle.Anteprima.tavoloCarta
                if let immagine {
                    Image(nsImage: immagine)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: misura.width, height: misura.height)
                }
            }
            .environment(\.colorScheme, .light)
        )
    }
}
#endif
