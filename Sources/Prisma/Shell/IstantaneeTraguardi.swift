#if os(macOS)
import SwiftUI

/// Le istantanee dei traguardi festeggiati in Messaggi (Design/template-luce-specifica.md §5.4.7, «Luce» giro 5), tutte
/// nello stato finale (cifra completa, anello pieno, niente coriandoli, pulsanti nello stato iniziale):
/// - 730: Messaggi con il gruppo «Da festeggiare», il traguardo di Sofia (obiettivo raggiunto ieri), chiaro e scuro;
/// - 731: «Un anno insieme» di Giulia, chiaro e scuro;
/// - 732: telefonata «✓ In agenda» e regalo «✓ Annotata»;
/// - 733: nessuna idea dalle note (la frase è quella di Prisma);
/// - 734: modalità cliente: solo il biglietto;
/// - 735: il biglietto da solo, come sarà il file da mandare (la condivisione arriva con il giro 15).
/// La capsula del tempo (730 nel template) arriva con il giro 15: la tile non c'è. L'iPhone (736) non è in questo giro.
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
            ("734-messaggi-traguardo-modo-cliente", { s in
                s.clienteAttivoId = "sofia"
                s.entraModoCliente(avviso: false)
                MessaggiDiProva.apri(s, tipo: .traguardo, cliente: "sofia")
            }),
            // Disegnato da `tavolaLuce` (IstantaneeLuce.swift): il biglietto da solo
            ("735-biglietto-traguardo", { _ in }),
        ]
    }

    /// Il biglietto di Sofia (dati di prova) da solo, su un fondo neutro, come sarà il file da mandare.
    static func tavolaBiglietto() -> AnyView {
        let dati = DatiPrisma.demo()
        let t = MotoreTraguardi.calcola(dati: dati, oggi: Date()).first { $0.clienteId == "sofia" }
        return AnyView(
            ZStack {
                Tema.Apple.Parcelle.Anteprima.tavoloCarta
                if let t {
                    BigliettoTraguardo(traguardo: t, firma: ModelliMessaggi.firma(nil, tono: .cordiale, impostazioni: dati.impostazioni))
                }
            }
            .environment(\.colorScheme, .light)
        )
    }
}
#endif
