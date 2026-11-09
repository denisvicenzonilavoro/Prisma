import Foundation

// I testi della capsula del tempo («Luce» giro 15, §3.4). Il testo del messaggio lo scrive il cliente, mai Prisma né
// Vera: qui solo le frasi intorno (titolo con il genere, frase onesta della decisione 41, segnaposto, aiuto della
// dettatura, conferma, toast, stati, sopratitolo e piede del PDF).

enum TestiCapsule {
    /// «Scrivi alla te stessa / al te stesso del giorno in cui ce l'avrai fatta.»; senza il genere una frase neutra.
    static func titolo(femminile: Bool?) -> String {
        switch femminile {
        case .some(true): return "Scrivi alla te stessa del giorno in cui ce l’avrai fatta."
        case .some(false): return "Scrivi al te stesso del giorno in cui ce l’avrai fatta."
        case .none: return "Scrivi un messaggio per il giorno in cui ce l’avrai fatta."
        }
    }

    /// La frase onesta (decisione 41): mai «nemmeno Denis».
    static let fraseOnesta = "Prisma la sigilla e la cifra: non si può leggere fino al giorno giusto."
    static let segnaposto = "Perché lo stai facendo? Cosa vuoi ricordarti quel giorno?"
    /// Decisione 35: la dettatura del sistema resta attiva, e si dice.
    static let aiutoDettatura = "Si può anche dettare: la dettatura è un servizio del sistema di Apple. Il testo resta su questo Mac, sigillato."
    static let etichettaQuando = "Si apre quando"
    static let inUnaData = "In una data…"
    static let sigilla = "✉︎ Sigilla la capsula"
    static let conferma = "Dopo il sigillo il messaggio non si può rileggere né correggere fino al giorno giusto."
    static let toastSigillata = "Capsula sigillata e cifrata"
    static let toastStampata = "Capsula stampata su carta, pronta da consegnare"
    static let toastNonSigillata = "La capsula non si è sigillata: la chiave delle capsule non è disponibile su questo Mac"
    static let etichettaElenco = "Le capsule sigillate"
    static let apriEConsegna = "Apri e consegna"
    static let chiudi = "Chiudi"
    static let cambiaQuando = "Cambia quando si apre"
    static let elimina = "Elimina la capsula"
    static let confermaElimina = "Il messaggio si distrugge senza essere letto. Non si può tornare indietro."
    static let obiettivoSparito = "L’obiettivo non c’è più: scegli quando si apre"
    static let nonApribile = "Non si può aprire su questo Mac"
    static let aiutoNonApribile = "La chiave di questa capsula non è nel Portachiavi di questo Mac. Torna con il ripristino di un backup protetto da password, fatto sul Mac dove è stata sigillata."
    /// Impostazioni › Archivio, con capsule e backup in chiaro (decisione 42).
    static let avvisoBackup = "Le capsule del tempo si riaprono solo da questo Mac: proteggi i backup con una password."
    static let condividi = "Condividi…"

    static func stampa(nome: String) -> String { "Stampala su carta per \(nome)" }
    static func nessuna(nome: String) -> String { "Nessuna capsula sigillata per \(nome)." }
    static func senzaObiettivi(nome: String) -> String { "\(nome) non ha ancora obiettivi: la capsula si apre in una data." }

    /// «sigillata a novembre 2025».
    static func sigillataA(_ d: Date) -> String { "sigillata a " + Formati.meseAnno.string(from: d) }

    /// «SIGILLATA A GIUGNO 2025» (sopratitolo del foglio e del PDF).
    static func sopratitolo(_ d: Date) -> String { sigillataA(d).uppercased() }

    /// Il piede del PDF: «Aperta il 9 novembre 2026 · Prisma».
    static func piede(apertaIl d: Date) -> String { "Aperta il \(Formati.dataEstesa.string(from: d)) · Prisma" }

    /// La seconda riga di una capsula nell'elenco: quando si apre e lo stato (mai il testo).
    static func riga(_ c: CapsulaTempo, stato: StatoCapsula, quando: String) -> String {
        switch stato {
        case .sigillata: return "\(quando) · \(sigillataA(c.sigillataIl))"
        case .pronta: return "pronta · \(sigillataA(c.sigillataIl))"
        case .daDecidere: return obiettivoSparito
        case .nonApribile: return nonApribile
        case .aperta(let d): return "aperta il \(Formati.dataEstesa.string(from: d))"
        case .consegnata(let d): return "consegnata il \(Formati.dataEstesa.string(from: d))"
        }
    }

    /// La tile arancio: «Obiettivo raggiunto il 4 novembre: è il momento di consegnarla».
    static func perchePronta(_ c: CapsulaTempo, dal d: Date, oggi: Date, cal: Calendar = .current) -> String {
        let quando = TestiTraguardi.quando(d, oggi: oggi, cal: cal)
        switch c.apertura {
        case .obiettivo: return "Obiettivo raggiunto \(quando): è il momento di consegnarla"
        case .data: return "È arrivato il giorno, \(quando): è il momento di consegnarla"
        }
    }

    /// Notifiche (solo il pannello di Prisma, decisione 29): mai il testo.
    static func titoloNotifica(nome: String) -> String { "La capsula di \(nome) è pronta" }
    static let dettaglioNotifica = "Aprila e consegnala nella Sala"

    /// La tile nel pannello del traguardo.
    static func titoloTraguardo(nome: String) -> String { "La capsula del tempo di \(nome) è pronta" }
    static func percheTraguardo(_ c: CapsulaTempo) -> String {
        "l’aveva sigillata a \(Formati.meseAnno.string(from: c.sigillataIl)), per questo giorno"
    }
    static let apriDalTraguardo = "Apri la capsula"

    /// Dossier › Obiettivi: accanto all'obiettivo con una capsula.
    static func dossier(_ stato: StatoCapsula, sigillataIl: Date) -> String {
        switch stato {
        case .sigillata: return sigillataA(sigillataIl)
        case .pronta: return "capsula pronta"
        case .daDecidere: return "capsula da decidere"
        case .nonApribile: return "capsula non apribile su questo Mac"
        case .aperta(let d): return "capsula aperta il \(Formati.giornoMese.string(from: d))"
        case .consegnata(let d): return "capsula consegnata il \(Formati.giornoMese.string(from: d))"
        }
    }

    /// La traccia nel dossier del PDF condiviso (mai il testo né la password).
    static let descrizioneUscita = "PDF protetto della capsula del tempo"
    /// Il nome del file condiviso: «La-capsula-di-Sofia.pdf» (solo il nome di battesimo).
    static func nomeFile(nome: String) -> String {
        let pulito = nome.replacingOccurrences(of: " ", with: "-")
        return "La-capsula-di-\(pulito.isEmpty ? "cliente" : pulito).pdf"
    }
}
