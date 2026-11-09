import Foundation

// I testi fissi del film del piano («Luce» giro 15, §3.2): titolo, occhielli, sottotitoli, righe delle cifre, chiusura,
// note degli stati vuoti, tile dell'esportazione, avviso della prima condivisione e il tempo «0:05 / 0:20». Niente Vera
// nel film: sottotitoli fissi di Prisma.

enum TestiFilm {
    static func titolo(_ nome: String) -> String { "Il piano di \(nome)" }

    static let occhielloOggi = "OGGI"
    static let occhielloOgniMese = "OGNI MESE"
    static let occhielloFuturo = "IL TUO FUTURO"
    static let chiusura = "Ce la facciamo insieme."
    static let datiDiProva = "DATI DI PROVA"
    static let datiDiProvaNota = "dati di prova"

    /// Il sottotitolo della scena (vuoto per titolo e chiusura).
    static func sottotitolo(_ s: ScenaFilm) -> String {
        switch s {
        case .titolo, .chiusura: return ""
        case .oggi: return "Ecco dove sei oggi."
        case .ogniMese: return "Un passo ogni mese."
        case .futuro: return "E dove ti porta."
        }
    }

    /// La percentuale dell'anello: «40%».
    static func percentuale(_ quota: Double) -> String {
        "\(Int((min(max(quota, 0), 1) * 100).rounded()))%"
    }

    /// «per «Anticipo casa»».
    static func perObiettivo(_ obiettivo: String) -> String { "per «\(obiettivo)»" }

    /// «+ 420 € per la pensione».
    static func pensione(_ cifra: Double) -> String { "+ \(Formati.euro(cifra)) per la pensione" }

    /// «ottobre 2029 · Anticipo casa».
    static func arrivo(_ mese: String, obiettivo: String) -> String { "\(mese) · \(obiettivo)" }

    /// «a 67 anni, in euro di oggi: 661.156 €».
    static func fine(eta: Int, valore: Double) -> String { "a \(eta) anni, in euro di oggi: \(Formati.euro(valore))" }

    // MARK: Firma secondo il canale (decisione 57)

    /// Una firma per canale del cliente (nome e colore del canale sul fondo scuro, mai il logo); senza canali quella
    /// indipendente.
    static func firme(cliente: Cliente) -> [FirmaFilm] {
        let canali = Canale.allCases.filter { cliente.canali.contains($0) }
        return (canali.isEmpty ? [.indipendente] : canali).map { c in
            FirmaFilm(testo: c.nome, colore: c == .alleanza ? Tema.Apple.SalaRacconti.Film.canaleAlleanza
                                                            : Tema.Apple.SalaRacconti.Film.canaleIndipendente)
        }
    }

    // MARK: Il tempo e la tile

    /// «m:ss» con i decimi troncati (20,2 s = «0:20»).
    static func minuti(_ secondi: Double) -> String {
        let s = max(0, Int(secondi.isFinite ? secondi : 0))
        return "\(s / 60):" + String(format: "%02d", s % 60)
    }

    /// «0:05 / 0:20»: il tempo corrente si ferma al totale.
    static func tempo(_ corrente: Double, totale: Double) -> String {
        "\(minuti(min(corrente, totale))) / \(minuti(totale))"
    }

    /// «20 secondi».
    static func durata(_ totale: Double) -> String {
        let s = max(1, Int(totale.isFinite ? totale : 0))
        return s == 1 ? "1 secondo" : "\(s) secondi"
    }

    /// «Il piano di Giulia.mp4».
    static func nomeFile(_ nome: String) -> String { "\(titolo(nome)).mp4" }

    static let esportoIlVideo = "Esporto il video · 1080p"
    static func pronto(_ nomeFile: String) -> String { "✓ \(nomeFile)" }
    static func dettaglioPronto(_ totale: Double) -> String { "\(durata(totale)) · senza voce · pronto" }
    static func cambiato(_ quando: Date) -> String {
        "Il piano è cambiato dopo il \(Formati.giornoMese.string(from: quando)): esporta di nuovo"
    }
    static let riprova = "Riprova"
    static let esporta = "⇩ Esporta il video"
    static let annulla = "Annulla"
    static let mostraNelFinder = "Mostra nel Finder"
    static let condividi = "Condividi il video…"
    static let uscito = "Il video è uscito dal foglio di condivisione: lo hai mandato tu"

    /// La descrizione della traccia nel dossier («Il film del piano · 20 secondi»).
    static func descrizioneUscita(_ totale: Double) -> String { "\(TestiUscite.titoloFilm) · \(durata(totale))" }

    /// Il titolo del Documento del cliente: «Il film del piano · novembre 2026».
    static func titoloDocumento(_ oggi: Date) -> String { "\(TestiUscite.titoloFilm) · \(Formati.meseAnno.string(from: oggi))" }

    // MARK: Errori

    static let codificatoreNonDisponibile = "Il codificatore video H.264 non è disponibile su questo Mac."
    static func scrittura(_ motivo: String) -> String { "Il video non si è scritto: \(motivo)" }

    // MARK: Stati vuoti

    static let senzaObiettivi = "Senza obiettivi il film mostra solo il futuro del patrimonio."
    static let senzaCurva = "Completa l'anagrafica e la previdenza per la curva del futuro."
    static let senzaVersamenti = "Senza versamenti previsti la scena «Ogni mese» mostra solo la pensione o si salta."
    static func vuoto(_ nome: String) -> String { "Per il film servono almeno un obiettivo o la linea della vita di \(nome)." }
    static let apriObiettivi = "Obiettivi ›"
    static let apriAnagrafica = "Anagrafica ›"
    static let avvertenzaNonScelta = "L'avvertenza del film non è ancora scelta: nel video c'è il segnaposto."
    static let inSalaNota = "Venti secondi da mandare dopo l'incontro."
}
