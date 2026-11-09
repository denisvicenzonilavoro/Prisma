import Foundation
#if os(macOS)
import AppKit
#endif

// I collegamenti verso Messaggi dalle altre app (Design/template-novita-specifica.md §5.1.1, §5.4, §5.5.2 punto 10,
// §3.4 «Manda con Messaggi»): Studio › Parcelle e fatture, il dossier del cliente (scheda Note), l'incontro concluso
// e il pannello Novità. Ognuno apre Messaggi con il contesto da cui parte: il cliente, l'occasione e, per la fattura,
// il PDF da allegare. Prisma non spedisce mai: Messaggi apre Mail o Messaggi già compilati e la spedizione la fa il
// consulente. Gli allegati sono copie temporanee sul Mac, mai fuori.
//
// Come la legge l'app Messaggi: all'apertura e quando `richiestaMessaggi` cambia, `prendiRichiestaMessaggi()` dà
// (e toglie) la richiesta; `occasioniMessaggiConRichieste(oggi:)` è l'elenco con in testa le occasioni su richiesta
// (una parcella fuori dalle regole del motore). `apriMessaggio` allega da solo i file dell'occasione.

/// Da dove si apre Messaggi. Tutto facoltativo: senza niente Messaggi parte dalla prima occasione.
struct RichiestaMessaggi: Equatable, Identifiable {
    /// Ogni richiesta è nuova, anche se uguale a quella di prima (lo stesso pulsante premuto due volte).
    let id = UUID()
    /// Il cliente su cui aprire (senza occasione: la sua prima occasione).
    var clienteId: String?
    /// L'occasione da scegliere (`OccasioneMessaggio.id`).
    var occasioneId: String?
    /// Un messaggio già salvato o aperto da mostrare (dal dossier).
    var messaggioId: String?
    /// Una bozza non salvata da mostrare («Apri ›» di una carta della notte, «Luce» giro 14): entra nel pannello, ma nel
    /// dossier solo se la salva l'utente.
    var bozza: MessaggioCliente? = nil
}

extension StatoShell {
    /// Quante occasioni su richiesta restano in memoria (le più recenti): poche righe, liberate alla chiusura di Prisma.
    static let massimoOccasioniSuRichiesta = 4

    /// Apre Messaggi con il contesto: cliente, occasione dell'elenco (`occasioneId`) o su richiesta (`occasione`, che
    /// entra in testa all'elenco), messaggio salvato, file da allegare all'apertura in Mail o in Messaggi.
    func preparaMessaggio(clienteId: String? = nil, occasioneId: String? = nil, occasione: OccasioneMessaggio? = nil,
                          messaggioId: String? = nil, allegati: [URL] = [], bozza: MessaggioCliente? = nil) {
        guard appConsentita(.messaggi) else {
            // `apri` dice perché in modalità cliente non si apre
            apri(.messaggi)
            return
        }
        if let o = occasione {
            occasioniSuRichiesta.removeAll { vecchia in vecchia.id == o.id }
            occasioniSuRichiesta.insert(o, at: 0)
            if occasioniSuRichiesta.count > Self.massimoOccasioniSuRichiesta {
                occasioniSuRichiesta.removeLast(occasioniSuRichiesta.count - Self.massimoOccasioniSuRichiesta)
            }
        }
        let scelta = occasione?.id ?? occasioneId
        if let scelta, !allegati.isEmpty { allegatiMessaggi[scelta] = allegati }
        richiestaMessaggi = RichiestaMessaggi(clienteId: clienteId ?? occasione?.clienteId ?? bozza?.clienteId, occasioneId: scelta,
                                              messaggioId: messaggioId, bozza: bozza)
        // Un messaggio si prepara nella vista Messaggi, non in Campagne («Luce» giro 12)
        if vistaMessaggi != .messaggi { vistaMessaggi = .messaggi }
        apri(.messaggi)
    }

    /// La richiesta in attesa, tolta dallo stato (nil se non c'è): la chiama l'app Messaggi.
    func prendiRichiestaMessaggi() -> RichiestaMessaggi? {
        guard let r = richiestaMessaggi else { return nil }
        richiestaMessaggi = nil
        return r
    }

    /// Le occasioni di Messaggi con in testa a «Da mandare oggi» quelle su richiesta che il motore non dà (dei clienti
    /// che ci sono ancora; in modalità cliente solo le sue). Quelle preparate oggi hanno la spunta, come le altre.
    func occasioniMessaggiConRichieste(oggi: Date = Date()) -> OccasioniMessaggi {
        let base = occasioniMessaggi(oggi: oggi)
        guard !occasioniSuRichiesta.isEmpty else { return base }
        let cal = Calendar.current
        let presenti = Set(base.tutte.map(\.id))
        let clienti = Set(dati.clienti.map(\.id))
        let extra = occasioniSuRichiesta.compactMap { o -> OccasioneMessaggio? in
            guard !presenti.contains(o.id), clienti.contains(o.clienteId) else { return nil }
            if let solo = modoCliente, o.clienteId != solo { return nil }
            // Chiesta apposta: resta anche se un messaggio di giorni fa la copriva (si manda di nuovo); con la spunta se
            // un messaggio aperto o salvato oggi la copre
            var copia = o
            copia.preparatoIl = dati.messaggi
                .filter { m in m.occasioneId == o.id && m.stato.copreOccasione && cal.isDate(m.dataMostrata, inSameDayAs: oggi) }
                .map(\.dataMostrata).max()
            return copia
        }
        guard !extra.isEmpty else { return base }
        return OccasioniMessaggi(festeggiare: base.festeggiare, oggi: extra + base.oggi, settimana: base.settimana)
    }

    /// L'occasione di una parcella per «Manda con Messaggi»: quella del motore se c'è (da mandare o da saldare),
    /// altrimenti una su richiesta con le stesse cifre (emessa da più di sette giorni o già pagata). nil per una bozza
    /// (senza numero non si manda), un'annullata o un cliente che non c'è più.
    func occasioneParcella(_ p: Parcella, oggi: Date = Date()) -> OccasioneMessaggio? {
        guard p.stato == .emessa || p.stato == .pagata,
              let c = dati.clienti.first(where: { cliente in cliente.id == p.clienteId }) else { return nil }
        let cal = Calendar.current
        let delMotore = MotoreOccasioniMessaggi.parcelle([p], clienti: [c.id: c], oggi: oggi, cal: cal)
        // Da saldare prima, se è scaduta: è il messaggio che serve
        if let o = delMotore.first(where: { o in o.origine.riferimento.hasSuffix("-sollecito") }) ?? delMotore.first {
            return o
        }
        let numero = (p.numero ?? "").trimmingCharacters(in: .whitespaces)
        var cifre: [CifraMessaggio] = []
        if !numero.isEmpty { cifre.append(CifraMessaggio(.parcella, "n. \(numero)")) }
        cifre.append(CifraMessaggio(.importo, Formati.euroDecimali(MotoreParcelle.importo(p))))
        cifre.append(CifraMessaggio(.emessaIl, Formati.dataEstesa.string(from: p.data)))
        if p.stato == .emessa, let s = p.scadenza { cifre.append(CifraMessaggio(.scadenza, Formati.dataEstesa.string(from: s))) }
        let nome = numero.isEmpty ? "La parcella" : "La parcella n. \(numero)"
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .parcella, riferimento: "\(p.id)-invio"), clienteId: c.id,
                                  canale: .indipendente, gruppo: .oggi, titolo: nome + " da mandare",
                                  perche: "Emessa " + MotoreOccasioniMessaggi.alGiorno(p.data),
                                  oggetto: numero.isEmpty ? "La parcella della consulenza" : "La parcella n. \(numero)",
                                  cifre: cifre, priorita: .alta, data: p.data)
    }

    /// L'occasione del riepilogo di un incontro concluso, se Messaggi la propone (concluso da al massimo sei giorni e
    /// non ancora coperto da un messaggio; preparato oggi resta con la spunta).
    func occasioneRiepilogo(_ i: Incontro) -> OccasioneMessaggio? {
        guard i.stato == .concluso else { return nil }
        return occasioniMessaggi().occasione(OccasioneMessaggio.id(tipo: .riepilogoIncontro, clienteId: i.clienteId,
                                                                   riferimento: i.id))
    }
}

/// Le copie temporanee dei file da allegare (il PDF della fattura con il suo nome, non quello dell'archivio).
/// Stanno nella cartella temporanea del Mac, che il sistema svuota da solo.
enum AllegatiMessaggi {
    static var cartella: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Prisma-allegati", isDirectory: true)
    }

    /// Scrive la copia da allegare e ne dà l'indirizzo (nil se non si riesce: il messaggio si apre senza allegato).
    static func copia(_ dati: Data, nome: String) -> URL? {
        let pulito = nome.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        guard !pulito.isEmpty else { return nil }
        do {
            try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
            let url = cartella.appendingPathComponent(pulito)
            try dati.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

extension AperturaMessaggi {
    /// Come `apri(testo:oggetto:canale:cliente:)`, con i file da allegare. Sul Mac il servizio di condivisione del
    /// sistema li allega (Mail e Messaggi). Gli indirizzi mailto: e sms: non portano allegati: allora il messaggio si
    /// apre senza, il file resta salvato, sul Mac il Finder lo mostra e l'avviso dice di allegarlo. Mai un invio.
    @MainActor
    static func apri(testo: String, oggetto: String?, canale: CanaleMessaggio, cliente: Cliente, allegati: [URL]) -> EsitoApertura {
        let file = allegati.filter { url in FileManager.default.fileExists(atPath: url.path) }
        guard !file.isEmpty else { return apri(testo: testo, oggetto: oggetto, canale: canale, cliente: cliente) }
        guard let a = recapito(cliente, canale: canale) else { return .mancaRecapito(mancante(canale)) }
        #if os(macOS)
        let servizio: NSSharingService.Name = canale == .mail ? .composeEmail : .composeMessage
        var elementi: [Any] = [testo]
        elementi.append(contentsOf: file.map { url -> Any in url })
        if let s = NSSharingService(named: servizio), s.canPerform(withItems: elementi) {
            s.recipients = [a]
            if canale == .mail { s.subject = oggetto ?? "" }
            s.perform(withItems: elementi)
            return .aperto("Aperto in \(canale.nome) con \(nomeAllegati(file)) allegato: lo controlli e lo spedisci tu")
        }
        #endif
        let esito = apri(testo: testo, oggetto: oggetto, canale: canale, cliente: cliente)
        guard esito.aperto else { return esito }
        #if os(macOS)
        NSWorkspace.shared.activateFileViewerSelecting(file)
        return .aperto(esito.messaggio + ". " + "\(maiuscola(nomeAllegati(file))) non si allega da solo: è salvato e il Finder "
                       + "te lo mostra, lo alleghi tu")
        #else
        return .aperto(esito.messaggio + ". " + "\(maiuscola(nomeAllegati(file))) non si allega da solo: è nei Documenti del "
                       + "cliente, lo alleghi tu")
        #endif
    }

    /// «il PDF «Fattura 2026-015 · Laura Moretti.pdf»» o «i 2 file».
    static func nomeAllegati(_ file: [URL]) -> String {
        guard file.count == 1, let f = file.first else { return "i \(file.count) file" }
        let tipo = f.pathExtension.lowercased() == "pdf" ? "il PDF" : "il file"
        return "\(tipo) «\(f.lastPathComponent)»"
    }

    private static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }
}
