#if os(macOS)
import CryptoKit
import Foundation
import SwiftUI

/// La prova a circuito chiuso del tavolo con l'iPad (`Prisma --prova-tavolo`, eseguita dal workflow sul Mac).
/// Mac e iPad nello stesso processo su 127.0.0.1: il Mac è `TavoloMac` (lo stesso dell'app, con uno stato di prova),
/// l'iPad è `ClienteTavolo`, il lato iPad del protocollo senza viste. Si controllano: il protocollo (cornici, chiave
/// propria del tavolo, contenuti sconosciuti, limiti del cursore), l'abbinamento con il codice giusto e il rifiuto con
/// quello sbagliato, una pagina mostrata, il cursore con il ricalcolo dei motori, la presa visione con la scritta
/// esatta nel PDF archiviato nei Documenti, il cambio di cliente, la caduta della connessione (di colpo e per
/// silenzio) con la schermata neutra, la chiusura del tavolo e nessun dato di altri clienti nei messaggi.
@MainActor
enum ProvaTavolo {
    /// Il battito accorciato: la prova dura pochi secondi.
    static let tempi = ProtocolloTavolo.Tempi(battito: 0.1, silenzio: 1.5, abbinamento: 3)
    static let presente = "giulia"
    /// L'espressione che non deve comparire in nessun testo del tavolo (composta qui, così non compare nemmeno nel codice).
    private static let parolaVietata = ["firma", "elettronica"].joined(separator: " ")

    static func esegui() -> Int32 {
        var errori = 0
        func controlla(_ ok: Bool, _ descrizione: String) {
            print("\(ok ? "OK   " : "ERRORE") \(descrizione)")
            if !ok { errori += 1 }
        }
        protocollo(controlla)
        rete(controlla)
        print(errori == 0 ? "Prova del tavolo superata" : "Prova del tavolo: \(errori) errori")
        return errori == 0 ? 0 : 1
    }

    // MARK: - Il protocollo, senza rete

    private static func protocollo(_ controlla: (Bool, String) -> Void) {
        let codice = PonteRuby.nuovoCodice()
        guard let k = ProtocolloTavolo.chiave(codice), let ruby = PonteRuby.chiave(codice),
              let altra = ProtocolloTavolo.chiave(PonteRuby.nuovoCodice()) else {
            return controlla(false, "Tavolo: chiave dal codice di abbinamento")
        }
        let m = MessaggioTavolo(sessione: "sessione-di-prova", numero: 1, contenuto: .neutra)
        guard let cornice = try? ProtocolloTavolo.cornice(m, chiave: k), cornice.count > 4 else {
            return controlla(false, "Tavolo: la cornice si scrive")
        }
        let testa = [UInt8](cornice.prefix(4))
        let lunghezza = Int(testa[0]) << 24 | Int(testa[1]) << 16 | Int(testa[2]) << 8 | Int(testa[3])
        let scatola = Data(cornice.dropFirst(4))
        controlla(lunghezza == scatola.count, "Tavolo: la cornice dice la lunghezza della scatola (\(lunghezza) byte)")
        controlla(ProtocolloTavolo.apri(scatola, chiave: k)?.messaggio == m, "Tavolo: il messaggio si apre con lo stesso codice")
        controlla(ProtocolloTavolo.apri(scatola, chiave: altra) == nil, "Tavolo: con un altro codice il messaggio non si apre")
        controlla(PonteRuby.apri(scatola, ruby) == nil, "Tavolo: la chiave del tavolo non è quella del ponte di Ruby (sale proprio)")
        controlla(!String(decoding: scatola, as: UTF8.self).contains("sessione-di-prova"), "Tavolo: il contenuto non si legge in chiaro")

        // Un contenuto di una versione più nuova non rompe il messaggio: si ignora
        let futuro = "{\"versione\":2,\"sessione\":\"s\",\"numero\":1,\"quando\":\(Date().timeIntervalSince1970),\"contenuto\":{\"ologramma\":{}}}"
        let sigillato = (try? PonteRuby.sigilla(Data(futuro.utf8), k)) ?? Data()
        let aperto = ProtocolloTavolo.apri(sigillato, chiave: k)
        controlla(aperto != nil && aperto?.messaggio.contenuto == nil, "Tavolo: un contenuto sconosciuto (versione 2) si ignora")

        let x = CursoreTavolo(id: "c", titolo: "Versamento mensile", unita: "€ al mese", valore: 100, minimo: 50, massimo: 1_000,
                              passo: 25, posizione: "Piano", canale: .alleanza, risultato: nil)
        controlla(x.valido(99_999) == 1_000 && x.valido(-3) == 50 && x.valido(63) == 75 && x.valido(.nan) == 50,
                  "Tavolo: il cursore resta nei limiti e sul passo decisi dal Mac")
        controlla(ProtocolloTavolo.testoPresaVisione == "Presa visione del documento: non costituisce firma contrattuale",
                  "Tavolo: la scritta della presa visione è quella esatta")
        let testi = [ProtocolloTavolo.testoPresaVisione] + TavoloMac(stato: StatoShell(persistente: false))
            .azioni(ContestoTavolo(documento: nil, pagina: 0, clienteId: presente)).flatMap { [$0.titolo, $0.aiuto] }
        controlla(!testi.contains { $0.lowercased().contains(parolaVietata) }, "Tavolo: nessun testo promette una firma con valore legale")
    }

    // MARK: - Mac e iPad su 127.0.0.1

    private static func rete(_ controlla: (Bool, String) -> Void) {
        let stato = StatoShell(persistente: false)
        stato.clienteAttivoId = presente
        let codice = PonteRuby.nuovoCodice()
        stato.dati.impostazioni.ruby.ponte.codice = codice
        let tavolo = stato.tavolo
        controlla(tavolo.porta == nil && !tavolo.acceso, "Tavolo: chiuso finché il consulente non lo apre (nessun ascolto in rete)")
        tavolo.avvia(porta: 0, annuncia: false, tempi: tempi)
        guard attendi(5, { tavolo.porta != nil }), let porta = tavolo.porta else {
            return controlla(false, "Tavolo: il Mac ascolta in rete locale")
        }
        defer { tavolo.chiudi() }
        controlla(true, "Tavolo: aperto, il Mac ascolta (porta \(porta))")

        // Il codice sbagliato: respinto, e niente arriva
        let intruso = ClienteTavolo(nome: "iPad estraneo", tempi: tempi)
        intruso.registra = true
        intruso.collega(codice: PonteRuby.nuovoCodice(), host: "127.0.0.1", porta: porta)
        let respinto = attendi(5) { intruso.collegamento == .rifiutato }
        controlla(respinto && !tavolo.collegato && intruso.registro.isEmpty && intruso.schermo == .neutra,
                  "Tavolo: con il codice sbagliato l'iPad è respinto e non riceve niente (\(intruso.collegamento))")

        // Il codice giusto
        let ipad = ClienteTavolo(nome: "iPad di prova", tempi: tempi)
        ipad.registra = true
        ipad.collega(codice: codice, host: "127.0.0.1", porta: porta)
        let abbinati = attendi(5) { ipad.collegato && tavolo.collegato }
        controlla(abbinati, "Tavolo: con il codice giusto Mac e iPad si abbinano (\(ipad.collegamento) · \(tavolo.descrizione))")
        guard abbinati else { return }
        controlla(ipad.schermo == .neutra, "Tavolo: appena collegato l'iPad mostra la schermata neutra")

        // Una pagina della presentazione
        guard let d = stato.documentoProspetto(.checkUp(report: true)), !d.pagine.isEmpty else {
            return controlla(false, "Tavolo: il report del check-up di Giulia")
        }
        let contesto = ContestoTavolo(documento: d, pagina: 0, clienteId: presente)
        tavolo.mandaPagina(contesto)
        let pagina = attendi(10) { mostrato(ipad)?.genere == .pagina }
        let m = mostrato(ipad)
        let immagine = m?.pagine.first.flatMap { ProtocolloTavolo.immagine($0.png) }
        let larghezza = Int((d.formato.width * Tema.Apple.Tavolo.scalaPagina).rounded())
        controlla(pagina && m?.pagine.count == 1 && m?.cliente == stato.cliente(presente)?.nome && immagine?.width == larghezza,
                  "Tavolo: l'iPad mostra la pagina in PNG, impaginata dal Mac (\(immagine?.width ?? 0)×\(immagine?.height ?? 0) pixel)")

        // Il cursore: il valore torna dall'iPad, il Mac ricalcola con i motori
        tavolo.lasciaCursore(contesto, minimo: 50, massimo: 1_000, passo: 25)
        let conCursore = attendi(5) { cursore(ipad)?.risultato != nil }
        controlla(conCursore && cursore(ipad)?.minimo == 50 && cursore(ipad)?.massimo == 1_000,
                  "Tavolo: il cursore arriva con titolo, limiti e passo decisi dal Mac")
        if let x = cursore(ipad) {
            let primo = x.risultato?.cifra ?? 0
            ipad.mandaValore(400, cursore: x.id)
            let ricalcolato = attendi(5) { cursore(ipad)?.risultato?.valore == 400 }
            var q = TavoloMac.parametriCursore(TavoloMac.posizioneCursore(stato.posizioniCliente(presente)))
            q.versamento = 400
            let atteso = MotoreProiezione.calcola(q).netto
            let cifra = cursore(ipad)?.risultato?.cifra ?? -1
            controlla(ricalcolato && abs(cifra - atteso) < 0.01 && (x.valore == 400 || abs(cifra - primo) > 0.01),
                      "Tavolo: 400 € al mese dall'iPad, il Mac ricalcola: \(Formati.euro(cifra)) (atteso \(Formati.euro(atteso)))")
            ipad.mandaValore(99_999, cursore: x.id)
            let limitato = attendi(5) { cursore(ipad)?.risultato?.valore == 1_000 }
            controlla(limitato && tavolo.cursore?.valore == 1_000, "Tavolo: fuori dai limiti il valore resta a 1.000 €")
        }

        // La macchina del tempo e la famiglia: cifre già calcolate, minime
        tavolo.mandaNelTempo(contesto)
        let nelTempo = attendi(5) { mostrato(ipad)?.genere == .nelTempo }
        let t = mostrato(ipad)?.nelTempo
        controlla(nelTempo && t?.passato.count == StoriaNelTempo.mesiIndietro + 1 && t?.centrale.count == StoriaNelTempo.mesiAvanti + 1,
                  "Tavolo: la macchina del tempo arriva già calcolata (37 mesi passati, 25 di stima)")
        tavolo.mandaFamiglia(contesto)
        let famiglia = attendi(5) { mostrato(ipad)?.genere == .famiglia }
        let persone = mostrato(ipad)?.famiglia?.persone ?? []
        let attese = (stato.cliente(presente)?.famiglia.count ?? 0) + 1
        controlla(famiglia && persone.count == attese && persone.first?.titolare == true,
                  "Tavolo: la famiglia arriva con \(persone.count) persone, il titolare per primo")
        // La linea della vita (giro 4): già calcolata, un valore per anno da oggi a 90, senza le note interne
        tavolo.mandaLineaVita(contesto)
        let vita = attendi(5) { mostrato(ipad)?.genere == .lineaVita }
        let linea = mostrato(ipad)?.lineaVita
        controlla(vita && linea.map { $0.valori.count == $0.etaFine - $0.etaOggi + 1 && !$0.eventi.isEmpty } == true,
                  "Tavolo: la linea della vita arriva già calcolata, un valore per anno fino a \(MotoreLineaVita.etaFinePredefinita) anni")

        // La presa visione: la scritta esatta nel PDF, archiviato nei Documenti del cliente
        controlla(tavolo.puoChiederePresaVisione(presente), "Tavolo: la presa visione si può chiedere dopo aver mostrato un documento")
        tavolo.chiediPresaVisione(contesto)
        let richiesta = attendi(5) { presaVisione(ipad) != nil }
        let r = presaVisione(ipad)
        controlla(richiesta && r?.testo == ProtocolloTavolo.testoPresaVisione && r?.pagine == d.pagine.count,
                  "Tavolo: l'iPad riceve la richiesta di presa visione con la scritta esatta")
        if let r, let tratto = TrattoProvaTavolo.immagine(), let png = ProtocolloTavolo.png(tratto) {
            let prima = stato.dati.documenti.count
            ipad.mandaPresaVisione(richiesta: r.id, tratto: png)
            let archiviata = attendi(15) { tavolo.ultimaPresaVisione != nil }
            let documento = tavolo.ultimaPresaVisione.flatMap { id in stato.dati.documenti.first { $0.id == id } }
            controlla(archiviata && documento?.clienteId == presente && stato.dati.documenti.count == prima + 1,
                      "Tavolo: la presa visione è nei Documenti del cliente («\(documento?.titolo ?? "—")»)")
            if let documento {
                let pagine = stato.testoDocumento(documento, memorizza: false)
                let ultima = normalizza(pagine.last ?? "")
                controlla(pagine.count == d.pagine.count + 1 && ultima.contains(ProtocolloTavolo.testoPresaVisione),
                          "Tavolo: nel PDF, dopo le \(d.pagine.count) pagine, la pagina della presa visione con la scritta esatta")
                controlla(!pagine.joined().lowercased().contains(parolaVietata), "Tavolo: il PDF non promette una firma con valore legale")
            }
            controlla(attendi(5) { ipad.schermo == .neutra }, "Tavolo: dopo la presa visione l'iPad torna alla schermata neutra")
        } else {
            controlla(false, "Tavolo: il tratto di prova in PNG")
        }

        // Un altro cliente sul Mac: l'iPad torna subito neutro
        tavolo.mandaFamiglia(contesto)
        _ = attendi(5) { mostrato(ipad)?.genere == .famiglia }
        stato.clienteAttivoId = "marco"
        controlla(attendi(5) { ipad.schermo == .neutra }, "Tavolo: aperto un altro cliente sul Mac, l'iPad torna alla schermata neutra")
        stato.clienteAttivoId = presente

        // Nessun dato di altri clienti nei messaggi
        nessunAltroCliente(ipad.registro, stato: stato, controlla)

        // La connessione cade di colpo: schermata neutra
        tavolo.mandaFamiglia(contesto)
        _ = attendi(5) { mostrato(ipad)?.genere == .famiglia }
        tavolo.interrompiPerProva()
        let caduta = attendi(5) { ipad.collegamento == .caduto && ipad.schermo == .neutra }
        controlla(caduta, "Tavolo: la connessione cade e l'iPad torna subito alla schermata neutra (\(ipad.collegamento))")
        controlla(attendi(5) { !tavolo.collegato && tavolo.acceso }, "Tavolo: il Mac vede l'iPad scollegato e resta in ascolto")

        // Il Mac tace: dopo il silenzio del battito l'iPad torna neutro
        let ipad2 = ClienteTavolo(nome: "iPad di prova", tempi: tempi)
        ipad2.collega(codice: codice, host: "127.0.0.1", porta: porta)
        if attendi(5, { ipad2.collegato && tavolo.collegato }) {
            tavolo.mandaNelTempo(contesto)
            _ = attendi(5) { mostrato(ipad2)?.genere == .nelTempo }
            tavolo.silenziaPerProva()
            let silenzio = attendi(5) { ipad2.collegamento == .caduto && ipad2.schermo == .neutra }
            controlla(silenzio, "Tavolo: senza battito dal Mac l'iPad lo dà per caduto e mostra la schermata neutra")
            controlla(attendi(5) { !tavolo.collegato }, "Tavolo: il Mac vede la connessione chiusa")
        } else {
            controlla(false, "Tavolo: un iPad si ricollega dopo la caduta")
        }

        // «Chiudi il tavolo»: fine, schermata neutra e niente più ascolto
        let ipad3 = ClienteTavolo(nome: "iPad di prova", tempi: tempi)
        ipad3.collega(codice: codice, host: "127.0.0.1", porta: porta)
        if attendi(5, { ipad3.collegato && tavolo.collegato }) {
            tavolo.mandaFamiglia(contesto)
            _ = attendi(5) { mostrato(ipad3)?.genere == .famiglia }
            tavolo.chiudi()
            let chiuso = attendi(5) { ipad3.collegamento == .scollegato && ipad3.schermo == .neutra }
            controlla(chiuso && !tavolo.acceso, "Tavolo: «Chiudi il tavolo» chiude con garbo e l'iPad torna neutro (\(ipad3.collegamento))")
            // Il tempo di spegnere l'ascolto sulla coda della rete
            _ = attendi(0.5) { false }
            let tardi = ClienteTavolo(nome: "iPad di prova", tempi: tempi)
            tardi.collega(codice: codice, host: "127.0.0.1", porta: porta)
            controlla(attendi(5) { tardi.collegamento == .irraggiungibile || tardi.collegamento == .rifiutato },
                      "Tavolo: a tavolo chiuso il Mac non risponde più (\(tardi.collegamento))")
        } else {
            controlla(false, "Tavolo: un terzo iPad si collega")
        }
    }

    /// I messaggi ricevuti dall'iPad (in chiaro, senza le immagini) non nominano nessun altro cliente.
    private static func nessunAltroCliente(_ registro: [Data], stato: StatoShell, _ controlla: (Bool, String) -> Void) {
        guard let c = stato.cliente(presente) else { return controlla(false, "Tavolo: il cliente presente") }
        let suoi = Set([c.nome] + c.famiglia.map(\.nome))
        let altri = stato.dati.clienti.filter { $0.id != presente }
        let nomi = Set(altri.flatMap { [$0.nome] + $0.famiglia.map(\.nome) }).subtracting(suoi).filter { $0.count >= 4 }
        let identificativi = Set(stato.dati.clienti.map { "\"\($0.id)\"" })
        let testi = registro.map(senzaImmagini)
        let estranei = testi.flatMap { t in nomi.filter { t.contains($0) } }
        let conId = testi.contains { t in identificativi.contains { t.contains($0) } }
        let soloDalMac = registro.allSatisfy { d in
            (try? JSONDecoder().decode(MessaggioTavolo.self, from: d))?.contenuto?.delMac ?? false
        }
        controlla(!registro.isEmpty && estranei.isEmpty && !conId && soloDalMac,
                  "Tavolo: \(registro.count) messaggi, nessun dato di altri clienti né identificativi" + (estranei.isEmpty ? "" : " (trovati: \(Set(estranei).sorted().joined(separator: ", ")))"))
    }

    // MARK: - Aiuti

    /// Aspetta che la condizione sia vera, facendo girare il ciclo principale (lì il tavolo del Mac riceve la rete).
    @discardableResult
    private static func attendi(_ secondi: TimeInterval, _ condizione: () -> Bool) -> Bool {
        let fine = Date().addingTimeInterval(secondi)
        while !condizione() && Date() < fine {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        return condizione()
    }

    private static func mostrato(_ c: ClienteTavolo) -> MostraTavolo? {
        if case .mostra(let m) = c.schermo { return m }
        return nil
    }

    private static func cursore(_ c: ClienteTavolo) -> CursoreTavolo? {
        if case .cursore(let x) = c.schermo { return x }
        return nil
    }

    private static func presaVisione(_ c: ClienteTavolo) -> RichiestaPresaVisioneTavolo? {
        if case .presaVisione(let r) = c.schermo { return r }
        return nil
    }

    /// Gli spazi del testo estratto dal PDF ridotti a uno.
    private static func normalizza(_ testo: String) -> String {
        testo.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Il messaggio in chiaro senza i PNG (che in base64 potrebbero contenere qualsiasi sequenza di lettere).
    private static func senzaImmagini(_ chiaro: Data) -> String {
        guard var m = try? JSONDecoder().decode(MessaggioTavolo.self, from: chiaro) else { return String(decoding: chiaro, as: UTF8.self) }
        if case .mostra(var x)? = m.contenuto {
            for i in x.pagine.indices { x.pagine[i].png = Data() }
            m.contenuto = .mostra(x)
        }
        if case .presaVisione(var p)? = m.contenuto {
            p.tratto = Data()
            m.contenuto = .presaVisione(p)
        }
        return (try? JSONEncoder().encode(m)).map { String(decoding: $0, as: UTF8.self) } ?? ""
    }
}
#endif
