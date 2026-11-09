#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

// La condivisione del biglietto dei traguardi («Luce» giro 15, Design/template-luce-specifica.md §5.4, decisioni 9 e
// 115). Prisma non spedisce mai: al clic su «Condividi…» disegna il biglietto in PNG (560×420 a scala 2, senza
// coriandoli, nello stato finale) nella cartella temporanea delle uscite (`CartellaUscite`, mai in Download) e apre il
// foglio di condivisione del sistema (`PulsanteCondividi`); il file si cancella dopo l'esito, al blocco e alla chiusura.
// «Mostra la cifra» è spento di base: senza, il biglietto non riceve né la cifra né la sua didascalia. «Salva su file…»
// solo se lo sceglie il consulente.

/// Quello che il biglietto scrive: scelto da una funzione pura (la prova controlla che con la cifra spenta non ci sia).
struct ContenutoBiglietto: Equatable {
    let saluto: String
    let cifra: Double?
    let didascalia: String?
    let frase: String
}

/// I testi della condivisione del biglietto.
enum TestiBiglietto {
    static let mostraCifra = "Mostra la cifra"
    static let condividi = "Condividi…"
    static let salva = "Salva su file…"
    static let tornaAllaFrase = "Torna alla frase di Prisma"
    static let fatto = "Fatto"
    static let aiutoFrase = "Clic per cambiare la frase del biglietto"
    static let notaFrase = "La frase cambiata vale solo per questo biglietto."
    static let altro = "Altro sul biglietto"
    static let messaggioSalva = "Il biglietto resta dove lo salvi: Prisma non lo invia a nessuno."
    static let nonDisegnato = "Non riesco a preparare il biglietto"
    /// «Il biglietto contiene il nome di Sofia e le cifre del suo piano. …» con la cifra; senza, solo il nome.
    static func avvisoPrimaVolta(nome: String, conCifra: Bool) -> String {
        conCifra
            ? TestiUscite.avvisoPrimaVolta(nome: nome, cosa: "Il biglietto")
            : "Il biglietto contiene il nome di \(nome). Esce dal Mac con l'app che scegli: lo mandi tu."
    }

    /// «Biglietto per Sofia.png» (solo il nome di battesimo).
    static func nomeFile(_ t: Traguardo, nome: String) -> String {
        let primo = TestiTraguardi.primoNome(nome)
        return primo.isEmpty ? "Biglietto.png" : "Biglietto per \(primo).png"
    }

    /// La riga della traccia nel dossier: «Biglietto · Ha raggiunto «Rendita integrativa» · con la cifra».
    static func descrizioneUscita(_ t: Traguardo, conCifra: Bool) -> String {
        "Biglietto · \(t.titolo)" + (conCifra ? " · con la cifra" : "")
    }

    /// La frase scritta a mano, ripulita: nil se vuota o uguale a quella di Prisma; tagliata alla misura del biglietto.
    static func fraseScritta(_ testo: String?, traguardo t: Traguardo) -> String? {
        guard let testo else { return nil }
        let pulita = String(testo.trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(Tema.Apple.Messaggi.Traguardo.Esporta.massimoFrase))
        return pulita.isEmpty || pulita == t.frase ? nil : pulita
    }

    /// Che cosa scrive il biglietto: la cifra e la sua didascalia solo con «Mostra la cifra» acceso; la frase scritta a
    /// mano al posto di quella di Prisma.
    static func contenuto(_ t: Traguardo, mostraCifra: Bool, frase: String?) -> ContenutoBiglietto {
        let cifra = mostraCifra ? t.cifra : nil
        return ContenutoBiglietto(saluto: t.saluto, cifra: cifra, didascalia: cifra == nil ? nil : t.didascaliaCifra,
                                  frase: fraseScritta(frase, traguardo: t) ?? t.frase)
    }
}

enum EsportaBiglietto {
    /// Il PNG del biglietto: 560×420 a scala 2, senza coriandoli né ombra, nello stato finale (cifra completa, anello
    /// pieno). Colori fissi del biglietto, angoli trasparenti.
    @MainActor
    static func png(_ t: Traguardo, firma: String?, mostraCifra: Bool, frase: String?) -> Data? {
        typealias B = Tema.Apple.Messaggi.Traguardo
        let vista = BigliettoTraguardo(traguardo: t, firma: firma, mostraCifra: mostraCifra, frase: frase,
                                       coriandoli: false, ombra: false)
            .environment(\.modoIstantanea, true)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: vista)
        renderer.proposedSize = ProposedViewSize(B.biglietto)
        renderer.scale = B.Esporta.scala
        guard let cg = renderer.cgImage else { return nil }
        return ProtocolloTavolo.png(cg)
    }

    /// Scrive il PNG nella cartella delle uscite («Biglietto per Sofia.png»); nil se non si disegna o non si scrive.
    @MainActor
    static func copiaDaCondividere(_ t: Traguardo, nome: String, firma: String?, mostraCifra: Bool, frase: String?) -> URL? {
        guard let dati = png(t, firma: firma, mostraCifra: mostraCifra, frase: frase) else { return nil }
        return try? CartellaUscite.scrivi(dati, nome: TestiBiglietto.nomeFile(t, nome: nome))
    }

    /// «Salva su file…»: il pannello di salvataggio del Mac con il PNG (`StampaCarta.salva` è solo per i PDF). Su iPhone
    /// e iPad il foglio di condivisione (Salva su File…) da una copia nella cartella delle uscite. true se salvato.
    @MainActor
    @discardableResult
    static func salvaSuFile(_ dati: Data, nome: String) -> Bool {
        #if os(macOS)
        let pannello = NSSavePanel()
        pannello.allowedContentTypes = [.png]
        pannello.nameFieldStringValue = nome
        pannello.canCreateDirectories = true
        pannello.message = TestiBiglietto.messaggioSalva
        guard pannello.runModal() == .OK, let url = pannello.url else { return false }
        do {
            try dati.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
        #else
        guard let url = try? CartellaUscite.scrivi(dati, nome: nome) else { return false }
        StampaCarta.condividi(url)
        return true
        #endif
    }
}
