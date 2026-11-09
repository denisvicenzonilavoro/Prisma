import CryptoKit
import Foundation

// Il file del Prisma del cliente per il browser («Luce» giro 15, §2.1.5 punto 4; decisione 3: costruito e provato, ma
// spento finché la prova su iPhone e Android veri non passa: `ImpostazioniSala.htmlSperimentale`). Un HTML autonomo:
// in chiaro solo il titolo generico «Il Prisma», il logo, il campo della password, il testo di ripiego e i parametri della
// cifratura; il contenuto (`ContenutoPrismaCliente` in JSON) sta in **un solo blocco** cifrato AES-256-GCM con la chiave
// PBKDF2-HMAC-SHA256 dalla password (NFC, 600.000 iterazioni, sale di 16 byte, nonce di 12; `CifraturaBackup.chiaveSpazio`).
// I dati associati legano il blocco all'intestazione (versione, sale, iterazioni, nonce, scadenza): cambiarne uno rompe la
// decifratura. Il lettore (`Risorse/PrismaCliente/lettore.js`, scritto a mano, senza librerie e senza rete: controllo
// statico nel workflow) decifra con WebCrypto. La password non si conserva mai.

enum FilePrismaCliente {
    static let iterazioni: UInt32 = 600_000
    static let lettore = "PrismaCliente/lettore.js"
    static let stile = "PrismaCliente/lettore.css"
    static let marca = "PRISMA-CLIENTE"

    enum Errore: Error, Equatable {
        case risorse
        case formato
        case passwordSbagliata
    }

    /// I parametri in chiaro del blocco.
    struct Intestazione: Equatable {
        var versione = 1
        var sale: Data
        var iterazioni: UInt32
        var nonce: Data
        /// «2027-11-05» (calendario gregoriano, ora locale).
        var scadenza: String

        /// I dati associati di AES-GCM: «PRISMA-CLIENTE|1|<sale b64>|600000|<nonce b64>|2027-11-05» in UTF-8 (il lettore
        /// li ricostruisce uguali).
        var datiAssociati: Data {
            Data([FilePrismaCliente.marca, String(versione), sale.base64EncodedString(), String(iterazioni),
                  nonce.base64EncodedString(), scadenza].joined(separator: "|").utf8)
        }

        /// Il JSON in chiaro dell'intestazione nell'HTML (chiavi ordinate).
        var json: String {
            "{\"iterazioni\":\(iterazioni),\"nonce\":\"\(nonce.base64EncodedString())\",\"sale\":\"\(sale.base64EncodedString())\","
                + "\"scadenza\":\"\(scadenza)\",\"versione\":\(versione)}"
        }

        static func daJSON(_ testo: String) -> Intestazione? {
            guard let dati = testo.data(using: .utf8),
                  let o = (try? JSONSerialization.jsonObject(with: dati)) as? [String: Any],
                  let v = o["versione"] as? Int, let it = o["iterazioni"] as? Int, it > 0,
                  let s = (o["sale"] as? String).flatMap({ Data(base64Encoded: $0) }),
                  let n = (o["nonce"] as? String).flatMap({ Data(base64Encoded: $0) }),
                  let sc = o["scadenza"] as? String else { return nil }
            return Intestazione(versione: v, sale: s, iterazioni: UInt32(it), nonce: n, scadenza: sc)
        }
    }

    /// «2027-11-05».
    static func giorno(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    // MARK: Cifratura

    static func cifra(_ c: ContenutoPrismaCliente, password: String, iterazioni: UInt32 = iterazioni) throws -> (Intestazione, Data) {
        let i = Intestazione(sale: try CifraturaBackup.casuali(CifraturaBackup.lunghezzaSale), iterazioni: iterazioni,
                             nonce: try CifraturaBackup.casuali(12), scadenza: giorno(c.validoFinoAl))
        let chiave = try CifraturaBackup.chiaveSpazio(passphrase: password, sale: i.sale, iterazioni: i.iterazioni)
        let scatola = try AES.GCM.seal(try c.json(), using: chiave, nonce: try AES.GCM.Nonce(data: i.nonce),
                                       authenticating: i.datiAssociati)
        // La forma che vuole WebCrypto: testo cifrato seguito dall'etichetta di 16 byte
        return (i, scatola.ciphertext + scatola.tag)
    }

    static func decifra(_ blocco: Data, _ i: Intestazione, password: String) throws -> ContenutoPrismaCliente {
        guard blocco.count > 16, i.nonce.count == 12 else { throw Errore.formato }
        let chiave = try CifraturaBackup.chiaveSpazio(passphrase: password, sale: i.sale, iterazioni: i.iterazioni)
        let chiaro: Data
        do {
            let scatola = try AES.GCM.SealedBox(nonce: try AES.GCM.Nonce(data: i.nonce), ciphertext: blocco.dropLast(16),
                                                tag: blocco.suffix(16))
            chiaro = try AES.GCM.open(scatola, using: chiave, authenticating: i.datiAssociati)
        } catch {
            throw Errore.passwordSbagliata
        }
        return try ContenutoPrismaCliente.daJSON(chiaro)
    }

    // MARK: L'HTML

    /// L'HTML completo del file (UTF-8). Fuori dal blocco nessun nome, cifra o testo del cliente.
    static func html(_ c: ContenutoPrismaCliente, password: String, iterazioni: UInt32 = iterazioni) throws -> Data {
        guard let js = risorsa(lettore), let css = risorsa(stile) else { throw Errore.risorse }
        let (i, blocco) = try cifra(c, password: password, iterazioni: iterazioni)
        let variabili = Tema.Apple.MiniCliente.tuttiHex.map { "--\($0.nome): \($0.hex);" }.joined(separator: " ")
        let pagina = """
        <!doctype html>
        <html lang="it">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <meta name="referrer" content="no-referrer">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; img-src data:; media-src data:">
        <title>Il Prisma</title>
        <style>:root { \(variabili) }
        \(css)</style>
        </head>
        <body>
        <main id="prisma">
        <section id="porta" class="porta">
        <div class="logo">\(logoSVG())</div>
        <h1>Il Prisma</h1>
        <p id="ripiego" class="ripiego">Se non vedi il campo della password, apri il file con Safari o con Chrome.</p>
        </section>
        </main>
        <script type="application/json" id="intestazione">\(i.json)</script>
        <script type="application/octet-stream" id="blocco">\(blocco.base64EncodedString())</script>
        <script id="lettore">
        \(js)
        </script>
        </body>
        </html>
        """
        return Data(pagina.utf8)
    }

    /// Intestazione e blocco da un HTML del file (per le prove).
    static func parti(_ html: String) -> (Intestazione, Data)? {
        guard let testa = contenuto(html, apertura: "<script type=\"application/json\" id=\"intestazione\">"),
              let i = Intestazione.daJSON(testa),
              let b = contenuto(html, apertura: "<script type=\"application/octet-stream\" id=\"blocco\">"),
              let blocco = Data(base64Encoded: b.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        return (i, blocco)
    }

    /// L'HTML senza il blocco cifrato (per le prove: lì non deve esserci nulla del cliente).
    static func fuoriDalBlocco(_ html: String) -> String {
        let apertura = "<script type=\"application/octet-stream\" id=\"blocco\">"
        guard let a = html.range(of: apertura), let b = html.range(of: "</script>", range: a.upperBound..<html.endIndex) else { return html }
        return String(html[..<a.upperBound]) + String(html[b.lowerBound...])
    }

    private static func contenuto(_ html: String, apertura: String) -> String? {
        guard let a = html.range(of: apertura), let b = html.range(of: "</script>", range: a.upperBound..<html.endIndex) else { return nil }
        return String(html[a.upperBound..<b.lowerBound])
    }

    /// «Il-Prisma-di-Giulia.pdf» (solo il nome di battesimo).
    static func nomeFile(_ c: ContenutoPrismaCliente, estensione: String) -> String {
        TestiPrismaCliente.baseNomeFile(c.nomeBattesimo) + "." + estensione
    }

    /// Il simbolo di Prisma in SVG (i tre spicchi, #0F2433 a 1 / 0,66 / 0,38), dagli stessi tracciati di `LogoPrisma`.
    static func logoSVG() -> String {
        let r = GeometriaLogo.riquadro
        let g = Double(GeometriaLogo.raggio)
        func n(_ v: CGFloat) -> String { String(format: "%.2f", Double(v)) }
        func spicchio(_ s: GeometriaLogo.Spicchio, opacita: Double) -> String {
            var d = "M\(n(s.punta.x)) \(n(s.punta.y))"
            for a in s.archi {
                d += " L\(n(a.inizio.x)) \(n(a.inizio.y)) A\(String(format: "%.0f", g)) \(String(format: "%.0f", g)) 0 0 1 \(n(a.fine.x)) \(n(a.fine.y))"
            }
            d += " Z"
            return "<path d=\"\(d)\" fill=\"\(Tema.Apple.MiniCliente.logoHex)\" fill-opacity=\"\(opacita)\"/>"
        }
        return "<svg viewBox=\"\(n(r.minX)) \(n(r.minY)) \(n(r.width)) \(n(r.height))\" width=\"44\" height=\"39\" aria-hidden=\"true\">"
            + spicchio(GeometriaLogo.sinistra, opacita: 1) + spicchio(GeometriaLogo.destra, opacita: 0.66)
            + spicchio(GeometriaLogo.base, opacita: 0.38) + "</svg>"
    }

    // MARK: Risorse

    static func risorsa(_ percorso: String) -> String? {
        guard let url = Risorse.cartella?.appendingPathComponent(percorso) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// Per `Prisma --verifica-risorse`: nil = le risorse del lettore ci sono e il lettore non usa la rete.
    static func verificaRisorse() -> String? {
        guard let js = risorsa(lettore), !js.isEmpty else { return "\(lettore) non leggibile dal bundle" }
        guard let css = risorsa(stile), !css.isEmpty else { return "\(stile) non leggibile dal bundle" }
        for vietato in ["fetch(", "XMLHttpRequest", "WebSocket", "sendBeacon", "import(", "http://", "https://"] where js.contains(vietato) {
            return "\(lettore) contiene «\(vietato)»: il lettore non deve usare la rete"
        }
        guard js.contains("PrismaLettore") else { return "\(lettore) senza PrismaLettore" }
        return nil
    }
}
