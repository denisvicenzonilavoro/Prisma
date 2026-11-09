import Foundation
import SwiftUI

// Le cose date al cliente («Luce» giro 15, CLAUDE.md › Dati e privacy, «Cose date al cliente»): la cartella temporanea
// delle copie da spedire, i testi comuni, la traccia nel dossier e la riga «Dato al cliente» dei Documenti.

/// Le copie da spedire: nella cartella temporanea dell'app, mai in Download; si cancellano dopo la condivisione, al blocco
/// e alla chiusura (e all'avvio, se una chiusura forzata le ha lasciate).
enum CartellaUscite {
    static var cartella: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Prisma-uscite", isDirectory: true)
    }

    /// Scrive una copia con il nome dato (senza «/» e «:», senza punti in testa) e ne restituisce l'indirizzo. Su iPhone e
    /// iPad il file è protetto come il resto dei dati del dispositivo.
    static func scrivi(_ dati: Data, nome: String) throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        var pulito = nome.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        while pulito.hasPrefix(".") { pulito.removeFirst() }
        if pulito.trimmingCharacters(in: .whitespaces).isEmpty { pulito = "file" }
        let url = cartella.appendingPathComponent(pulito)
        #if os(iOS)
        try dati.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try dati.write(to: url, options: .atomic)
        #endif
        return url
    }

    /// true se l'indirizzo è dentro la cartella delle uscite (solo quelli si cancellano).
    static func dentro(_ url: URL) -> Bool {
        url.standardizedFileURL.path.hasPrefix(cartella.standardizedFileURL.path + "/")
    }

    /// Toglie una copia (mai un file fuori dalla cartella delle uscite).
    static func togli(_ url: URL) {
        guard dentro(url) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Toglie tutte le copie.
    static func svuota() {
        try? FileManager.default.removeItem(at: cartella)
    }
}

/// I testi comuni delle cose date al cliente.
enum TestiUscite {
    /// L'avviso alla prima uscita per cliente: «Il video contiene il nome di Giulia e le cifre del suo piano. Esce dal Mac
    /// con l'app che scegli: lo mandi tu.»
    static func avvisoPrimaVolta(nome: String, cosa: String, femminile: Bool = false) -> String {
        "\(cosa) contiene il nome di \(nome) e le cifre del suo piano. Esce dal Mac con l'app che scegli: \(femminile ? "la" : "lo") mandi tu."
    }

    static let whatsappSenzaConsenso = "WhatsApp compare solo con il consenso segnato nel dossier"
    /// Il prefisso del titolo del Documento del film («Il film del piano · novembre 2026»).
    static let titoloFilm = "Il film del piano"
    static let promemoriaBackup = "La copia nel dossier finisce nei backup in chiaro: proteggi i backup con una password (Impostazioni › Archivio)."
    static let datoAlCliente = "Dato al cliente"
    static let documentoTolto = "non più nei Documenti"
}

/// Solo istantanee: lo stato da disegnare delle tre esperienze nuove della Sala (non pubblicato, mai salvato).
struct ProvaUsciteSala {
    var prismaFilePronto = false
    var prismaPasswordMostrata = false
    var passwordDiProva: String?
    var filmScena: Int?
    var filmEsportato = false
    var capsulaApertaId: String?
    var capsulaChiaveMancante = false
}

extension StatoShell {
    /// Scrive la traccia di una cosa data al cliente (mai la password, mai il contenuto).
    @discardableResult
    func registraUscita(clienteId: String, genere: GenereUscita, descrizione: String, via: String?, documentoId: String?,
                        protetto: Bool) -> UscitaCliente {
        let adesso = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
        let viaPulita = via.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        let u = UscitaCliente(clienteId: clienteId, genere: genere, quando: adesso, descrizione: descrizione, via: viaPulita,
                              documentoId: documentoId, protetto: protetto)
        dati.uscite.append(u)
        return u
    }

    /// Le uscite del cliente, le più recenti prima.
    func usciteCliente(_ id: String) -> [UscitaCliente] {
        dati.uscite.filter { $0.clienteId == id }.sorted { $0.quando > $1.quando }
    }

    /// true se al cliente non è ancora uscito nulla (per l'avviso della prima volta).
    func primaUscita(clienteId: String) -> Bool {
        !dati.uscite.contains { $0.clienteId == clienteId }
    }

    /// Come `archiviaPDF` ma per un file qualsiasi (il video del film): Documenti/<cliente>/<id>.<estensione>, niente
    /// testo da leggere. Lo stesso titolo dello stesso giorno sostituisce il documento di prima.
    @discardableResult
    func archiviaFile(_ dati: Data, estensione: String, titolo: String, tipo: Documento.Tipo, cliente: String) -> String? {
        if let vecchio = self.dati.documenti.first(where: { $0.clienteId == cliente && $0.titolo == titolo
            && Calendar.current.isDateInToday($0.importatoIl) }) {
            eliminaDocumento(vecchio.id)
        }
        var d = Documento(clienteId: cliente, titolo: titolo, tipo: tipo)
        d.importatoIl = Appuntamento.alMinuto(Date())
        d.lettura = .letto
        d.dimensione = Int64(dati.count)
        let ext = estensione.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        if persistente {
            let cartella = Archivio.cartellaDocumenti.appendingPathComponent(cliente, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
                try dati.write(to: cartella.appendingPathComponent("\(d.id).\(ext)"))
            } catch {
                mostraAvviso("Non riesco a salvare il file: \(error.localizedDescription)")
                return nil
            }
            d.file = "\(cliente)/\(d.id).\(ext)"
        }
        self.dati.documenti.append(d)
        return d.id
    }

    /// L'ultimo film del piano esportato per il cliente (titolo con il prefisso del film, file .mp4; nelle istantanee un
    /// documento senza file).
    func ultimoFilm(clienteId: String) -> Documento? {
        dati.documenti
            .filter { d in
                d.clienteId == clienteId && d.titolo.hasPrefix(TestiUscite.titoloFilm)
                    && (d.file.map { $0.lowercased().hasSuffix(".mp4") } ?? true)
            }
            .max { $0.importatoIl < $1.importatoIl }
    }
}

/// «Dato al cliente»: le ultime uscite del cliente, in cima alla scheda Documenti (data, cosa, via, lucchetto se
/// protetto). Non compare se non è uscito nulla.
struct UsciteDelCliente: View {
    let clienteId: String
    @Environment(StatoShell.self) private var stato
    private typealias T = Tema.Apple.UsciteCliente

    var body: some View {
        let _ = ContaCorpi.segna()
        let uscite = Array(stato.usciteCliente(clienteId).prefix(T.quante))
        if !uscite.isEmpty {
            VStack(alignment: .leading, spacing: T.spazio) {
                Text(TestiUscite.datoAlCliente)
                    .carattereApple(T.etichetta)
                    .foregroundStyle(T.coloreEtichetta)
                ForEach(uscite) { u in
                    riga(u)
                }
            }
            .padding(T.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: T.raggio, style: .continuous).fill(T.fondo))
            .padding(T.margine)
        }
    }

    private func riga(_ u: UscitaCliente) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: T.spazioRiga) {
            Text(Formati.giornoMeseBreve.string(from: u.quando))
                .carattereApple(T.dettaglio)
                .foregroundStyle(T.coloreDettaglio)
                .frame(width: T.larghezzaData, alignment: .leading)
            VStack(alignment: .leading, spacing: T.spazioStretto) {
                Text(u.genere.nome)
                    .carattereApple(T.titolo)
                    .foregroundStyle(T.coloreTitolo)
                Text(dettaglio(u))
                    .carattereApple(T.dettaglio)
                    .foregroundStyle(T.coloreDettaglio)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if u.protetto {
                Image(systemName: T.lucchetto)
                    .foregroundStyle(T.coloreLucchetto)
                    .help("Uscito protetto")
            }
        }
    }

    private func dettaglio(_ u: UscitaCliente) -> String {
        var parti = [u.descrizione].filter { !$0.isEmpty }
        if let via = u.via { parti.append("con \(via)") }
        if let id = u.documentoId, !stato.dati.documenti.contains(where: { $0.id == id }) {
            parti.append(TestiUscite.documentoTolto)
        }
        return parti.joined(separator: " · ")
    }
}
