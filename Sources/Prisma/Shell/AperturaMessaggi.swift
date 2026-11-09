import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// Aprire Mail o Messaggi con il messaggio già compilato (Design/template-novita-specifica.md §5.5.2 punto 5). Prisma non
// spedisce mai: apre l'app del sistema con destinatario, oggetto e testo, e la spedizione la fa il consulente.
// Sul Mac: il servizio di condivisione del sistema (NSSharingService .composeEmail / .composeMessage), con il ripiego
// degli indirizzi mailto: e sms: (per Messaggi il testo va anche negli appunti: il corpo dell'indirizzo sms: sul Mac può
// non passare). Su iPhone e iPad: gli stessi indirizzi mailto: e sms:. Senza email o telefono nel dossier non si apre
// niente e il pulsante lo dice. Nessun dato esce da qui se non attraverso l'app che il consulente usa per spedire.

/// Com'è andata l'apertura.
enum EsitoApertura: Equatable {
    /// Aperta l'app (il testo è l'avviso da mostrare: «Aperto in Mail: lo spedisci tu»).
    case aperto(String)
    /// Manca l'indirizzo email o il numero nel dossier.
    case mancaRecapito(String)
    case nonRiuscito(String)

    var aperto: Bool {
        if case .aperto = self { return true }
        return false
    }

    var messaggio: String {
        switch self {
        case .aperto(let m), .mancaRecapito(let m), .nonRiuscito(let m): return m
        }
    }
}

enum AperturaMessaggi {
    // MARK: - Recapiti

    /// L'indirizzo email del dossier, se sembra un indirizzo (senza spazi, con «@» e un punto dopo).
    static func email(_ cliente: Cliente) -> String? {
        let e = cliente.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !e.contains(" "), let chiocciola = e.firstIndex(of: "@"), chiocciola != e.startIndex,
              e[e.index(after: chiocciola)...].contains(".") else { return nil }
        return e
    }

    /// Il numero del dossier con solo le cifre e il «+» iniziale («+39 333 123 4567» → «+393331234567»,
    /// «0039…» → «+39…»). Il prefisso non si aggiunge mai da solo. nil se le cifre sono meno di sei.
    static func telefono(_ cliente: Cliente) -> String? { telefonoNormalizzato(cliente.telefono) }

    static func telefonoNormalizzato(_ grezzo: String) -> String? {
        let t = grezzo.trimmingCharacters(in: .whitespacesAndNewlines)
        let piu = t.hasPrefix("+")
        var cifre = String(t.filter { $0.isASCII && $0.isNumber })
        var internazionale = piu
        if !piu, cifre.hasPrefix("00") {
            cifre = String(cifre.dropFirst(2))
            internazionale = true
        }
        guard cifre.count >= cifreMinime else { return nil }
        return (internazionale ? "+" : "") + cifre
    }

    static let cifreMinime = 6

    /// Il recapito per il canale (nil se manca nel dossier).
    static func recapito(_ cliente: Cliente, canale: CanaleMessaggio) -> String? {
        canale == .mail ? email(cliente) : telefono(cliente)
    }

    /// Il titolo del pulsante principale: «Apri in Mail» o, senza recapito, che cosa manca nel dossier.
    static func titoloPulsante(_ cliente: Cliente, canale: CanaleMessaggio) -> String {
        if recapito(cliente, canale: canale) != nil { return "Apri in \(canale.nome)" }
        return mancante(canale)
    }

    /// «Manca l'indirizzo email nel dossier» / «Manca il numero di telefono nel dossier».
    static func mancante(_ canale: CanaleMessaggio) -> String {
        canale == .mail ? "Manca l'indirizzo email nel dossier" : "Manca il numero di telefono nel dossier"
    }

    // MARK: - Indirizzi

    /// mailto: con destinatario, oggetto e corpo codificati (RFC 6068: gli a capo diventano CRLF).
    static func indirizzoMail(a destinatario: String, oggetto: String?, corpo: String) -> URL? {
        var parti: [String] = []
        if let o = oggetto, !o.isEmpty { parti.append("subject=" + codifica(o)) }
        parti.append("body=" + codifica(aCapoCRLF(corpo)))
        return URL(string: "mailto:" + codifica(destinatario, anche: "@+") + "?" + parti.joined(separator: "&"))
    }

    /// sms: con il numero e il corpo (la forma che leggono iPhone e iPad: «sms:+39…&body=…»).
    static func indirizzoSMS(a numero: String, corpo: String) -> URL? {
        URL(string: "sms:" + codifica(numero, anche: "+") + "&body=" + codifica(corpo))
    }

    /// Codifica percentuale di tutto tranne lettere e cifre ASCII e «-._~» (più i caratteri `anche`): accenti, «€»,
    /// «&», spazi e a capo diventano sequenze %XX in UTF-8.
    static func codifica(_ s: String, anche: String = "") -> String {
        let consentiti = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~" + anche)
        return s.addingPercentEncoding(withAllowedCharacters: consentiti) ?? ""
    }

    private static func aCapoCRLF(_ s: String) -> String {
        s.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n", with: "\r\n")
    }

    // MARK: - Aprire (mai spedire)

    /// Apre l'app del canale con il messaggio già compilato. Senza recapito non apre niente.
    @MainActor
    static func apri(testo: String, oggetto: String?, canale: CanaleMessaggio, cliente: Cliente) -> EsitoApertura {
        guard let a = recapito(cliente, canale: canale) else { return .mancaRecapito(mancante(canale)) }
        switch canale {
        case .mail: return apriMail(a: a, oggetto: oggetto, corpo: testo)
        case .messaggi: return apriMessaggi(a: a, corpo: testo)
        }
    }

    /// Mail con il destinatario dato (anche fuori dal dossier: il sollecito alla compagnia di Pratiche › Sinistri,
    /// all'indirizzo scritto dall'utente). Interna dal giro 15 di «Luce».
    @MainActor
    static func apriMail(a: String, oggetto: String?, corpo: String) -> EsitoApertura {
        let fatto = EsitoApertura.aperto("Aperto in Mail: lo controlli e lo spedisci tu")
        #if os(macOS)
        if let s = NSSharingService(named: .composeEmail), s.canPerform(withItems: [corpo]) {
            s.recipients = [a]
            s.subject = oggetto ?? ""
            s.perform(withItems: [corpo])
            return fatto
        }
        if let url = indirizzoMail(a: a, oggetto: oggetto, corpo: corpo), NSWorkspace.shared.open(url) { return fatto }
        Appunti.copia(corpo)
        return .nonRiuscito("Mail non si apre su questo Mac: il testo è negli appunti")
        #elseif os(iOS)
        guard let url = indirizzoMail(a: a, oggetto: oggetto, corpo: corpo) else {
            Appunti.copia(corpo)
            return .nonRiuscito("Mail non si apre: il testo è negli appunti")
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return fatto
        #else
        return .nonRiuscito("Mail non è disponibile")
        #endif
    }

    @MainActor
    private static func apriMessaggi(a: String, corpo: String) -> EsitoApertura {
        #if os(macOS)
        if let s = NSSharingService(named: .composeMessage), s.canPerform(withItems: [corpo]) {
            s.recipients = [a]
            s.perform(withItems: [corpo])
            return .aperto("Aperto in Messaggi: lo controlli e lo spedisci tu")
        }
        // Il ripiego sms: sul Mac può perdere il corpo: il testo va anche negli appunti
        Appunti.copia(corpo)
        if let url = indirizzoSMS(a: a, corpo: corpo), NSWorkspace.shared.open(url) {
            return .aperto("Aperto in Messaggi: il testo è negli appunti, lo incolli e lo spedisci tu")
        }
        return .nonRiuscito("Messaggi non si apre su questo Mac: il testo è negli appunti")
        #elseif os(iOS)
        guard let url = indirizzoSMS(a: a, corpo: corpo) else {
            Appunti.copia(corpo)
            return .nonRiuscito("Messaggi non si apre: il testo è negli appunti")
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return .aperto("Aperto in Messaggi: lo controlli e lo spedisci tu")
        #else
        return .nonRiuscito("Messaggi non è disponibile")
        #endif
    }
}
