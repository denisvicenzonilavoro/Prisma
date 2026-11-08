#if os(macOS)
import AppKit
import Observation
#endif
import SwiftUI
import UniformTypeIdentifiers

// Ciò che Mercato chiede allo stato (giro 7, Design/template-novita-specifica.md §12): le tessere, l'occhiello, «Chi è
// toccato», gli avvisi con le soglie dell'utente, la ricerca per ISIN, lo scaricamento dalle fonti pubbliche, i file
// importati, i valori a mano e il passaggio a Messaggi.
//
// La rete: solo `aggiornaMercato`, solo sul Mac, solo con «Dati di mercato» acceso e solo attraverso ClienteMercato
// (che costruisce le richieste con i soli codici pubblici della configurazione). Nelle istantanee e nelle prove
// (`persistente` falso) non parte mai. Su iPhone e iPad Mercato si legge soltanto: i dati arrivano dal Mac.

/// I fogli di Mercato.
enum FoglioMercato: String, Identifiable {
    case importa, aMano, soglie

    var id: String { rawValue }
}

/// Una lettura di un file CSV in attesa di conferma (il foglio «Importa i dati del mercato»).
struct ImportazioneMercatoInAttesa: Equatable {
    var file: String
    var esito: ImportazioneMercatoCSV
}

/// Lo stato di Mercato che non si salva: il campo ISIN, il risultato, lo scaricamento in corso, il foglio aperto.
/// Un oggetto a parte (`StatoShell.sessioneMercato`): scrivere nel campo non pubblica StatoShell.
@Observable final class SessioneMercato {
    var testoISIN = ""
    /// nil = nessuna ricerca in vista.
    var risultatoISIN: RisultatoISIN?
    /// Cresce a ogni ricerca: il risultato rientra con il suo movimento.
    var giroRicerca = 0
    var inAggiornamento = false
    var foglio: FoglioMercato?
    var importazione: ImportazioneMercatoInAttesa?
    /// Istantanee: la tessera con il dettaglio già aperto.
    @ObservationIgnored var dettaglioIstantanea: String?

    /// La configurazione delle serie (file del consulente o del pacchetto), letta una volta per sessione.
    @ObservationIgnored private(set) lazy var configurazione: ConfigurazioneMercato? = ConfigurazioneMercato.carica()

    /// Rilegge la configurazione (dopo che il consulente ha cambiato il file).
    func ricaricaConfigurazione() { configurazione = ConfigurazioneMercato.carica() }
}

extension StatoShell {
    // MARK: - Lettura

    /// Mercato si cambia solo sul Mac, fuori dalla sola lettura: su iPhone e iPad i dati arrivano dal Mac.
    var mercatoModificabile: Bool {
        #if os(macOS)
        return !solaLettura
        #else
        return false
        #endif
    }

    /// I dati di Mercato sono quelli di prova delle istantanee (`MercatoDiProva`): l'occhiello lo dice.
    var mercatoDiProva: Bool { dati.mercato.serie.contains { $0.fonte == MercatoDiProva.fonte } }

    func tessereMercato(oggi: Date = Date()) -> [TesseraMercato] {
        MotoreMercato.tessere(archivio: dati.mercato, configurazione: sessioneMercato.configurazione,
                              impostazioni: dati.impostazioni.mercato, oggi: oggi)
    }

    /// «Aggiornato oggi alle 18:00 · valori di prova».
    func occhielloMercato(oggi: Date = Date()) -> String {
        MotoreMercato.occhiello(ultimo: MotoreMercato.ultimoArrivo(dati.mercato), inCorso: sessioneMercato.inAggiornamento,
                                datiDiProva: mercatoDiProva, oggi: oggi)
    }

    /// Gli eventi di «Chi è toccato» con le soglie dell'utente (in modalità cliente solo il suo).
    func eventiMercato(oggi: Date = Date()) -> [EventoMercato] {
        MotoreMercato.toccati(archivio: dati.mercato, impostazioni: dati.impostazioni.mercato, posizioni: posizioni,
                              clienti: clienti, obiettivi: dati.obiettivi, oggi: oggi)
    }

    /// Gli avvisi dei clienti visibili, come li ha salvati l'ultimo calcolo.
    var avvisiMercato: [AvvisoMercato] {
        let visibili = Set(clienti.map(\.id))
        return dati.mercato.avvisi.filter { visibili.contains($0.clienteId) }
    }

    /// Il tono di un avviso: rosso il calo dal massimo, arancio la distanza e la cedola, la variazione col tono della
    /// serie; visto: spento.
    func tonoAvvisoMercato(_ a: AvvisoMercato) -> TonoAvvisoMercato {
        guard a.stato == .nuovo else { return .spento }
        switch a.tipo {
        case .caloDalMassimo: return .rosso
        case .distanzaDalRiferimento, .cedolaInArrivo: return .arancio
        case .variazioneSerie:
            guard let s = a.serieId.flatMap({ dati.mercato.serie($0) }) else { return .arancio }
            switch MotoreMercato.tono(s.tipo, variazione: a.valore, unita: s.unita) {
            case .buono: return .verde
            case .cattivo: return .rosso
            case .neutro: return .arancio
            }
        }
    }

    /// Il filo della scheda di «Chi è toccato»: la variazione col tono della serie, il calo rosso, il resto arancio.
    func tonoEventoMercato(_ e: EventoMercato) -> TonoAvvisoMercato {
        switch e.tipo {
        case .caloDalMassimo: return .rosso
        case .distanzaDalRiferimento, .cedolaInArrivo: return .arancio
        case .variazioneSerie:
            guard let s = e.serieId.flatMap({ dati.mercato.serie($0) }) else { return .arancio }
            switch MotoreMercato.tono(s.tipo, variazione: e.valore, unita: s.unita) {
            case .buono: return .verde
            case .cattivo: return .rosso
            case .neutro: return .arancio
            }
        }
    }

    // MARK: - Avvisi

    /// Ricalcola gli avvisi con le soglie dell'utente e li salva (solo se cambiano). Sul Mac; su iPhone e iPad gli
    /// avvisi arrivano dal Mac.
    func ricalcolaAvvisiMercato(oggi: Date = Date()) {
        #if os(macOS)
        guard !solaLettura else { return }
        let eventi = MotoreMercato.toccati(archivio: dati.mercato, impostazioni: dati.impostazioni.mercato, posizioni: dati.posizioni,
                                           clienti: dati.clienti, obiettivi: dati.obiettivi, oggi: oggi)
        let nuovi = MotoreMercato.avvisi(eventi: eventi, esistenti: dati.mercato.avvisi, oggi: oggi)
        if nuovi != dati.mercato.avvisi { dati.mercato.avvisi = nuovi }
        #endif
    }

    /// Visto (l'interruttore spento, il pallino grigio) o di nuovo da guardare.
    func segnaAvvisoMercato(_ id: String, visto: Bool) {
        guard !solaLettura else { return }
        if visto {
            MotoreMercato.segnaVisto(id, in: &dati.mercato.avvisi, il: Date())
        } else if let i = dati.mercato.avvisi.firstIndex(where: { $0.id == id }) {
            dati.mercato.avvisi[i].stato = .nuovo
            dati.mercato.avvisi[i].vistoIl = nil
        }
    }

    /// Apre ciò che l'avviso tocca: la posizione se è una, altrimenti il dossier del cliente.
    func apriAvvisoMercato(_ a: AvvisoMercato) {
        if a.posizioni.count == 1, let p = dati.posizioni.first(where: { $0.id == a.posizioni[0] }) {
            apriPosizione(p)
        } else {
            apriCliente(a.clienteId)
        }
    }

    // MARK: - Messaggi

    /// «Prepara un messaggio»: Messaggi con l'occasione dell'avviso di mercato per quel cliente (quella dell'avviso
    /// salvato, o nata dall'evento se l'avviso non c'è ancora). L'occasione la scrive MotoreOccasioniMessaggi, con le
    /// stesse cifre: nasce «oggi» perché il consulente l'ha chiesta adesso.
    func preparaMessaggioMercato(_ e: EventoMercato, clienteId: String) {
        let id = MotoreMercato.idAvviso(e, clienteId: clienteId)
        let toccato = e.toccati.first { $0.clienteId == clienteId }
        var a = dati.mercato.avvisi.first { $0.id == id }
            ?? AvvisoMercato(id: id, tipo: e.tipo, clienteId: clienteId, posizioni: toccato?.posizioni ?? [], isin: e.isin,
                             serieId: e.serieId, canale: toccato?.canaleUnico, titolo: e.titolo, dettaglio: e.dettaglio,
                             valore: e.valore, soglia: e.soglia, dataDato: e.data, fonte: e.fonte, creatoIl: Date())
        a.creatoIl = Date()
        preparaMessaggioAvviso(a)
    }

    /// Messaggi con l'occasione di un avviso salvato.
    func preparaMessaggioAvviso(_ avviso: AvvisoMercato) {
        var a = avviso
        a.creatoIl = Date()
        let perCliente = Dictionary(dati.clienti.map { ($0.id, $0) }, uniquingKeysWith: { primo, _ in primo })
        let perPosizioni = Dictionary(grouping: dati.posizioni, by: \.clienteId)
        guard let o = MotoreOccasioniMessaggi.avvisiMercato([a], clienti: perCliente, posizioni: perPosizioni, oggi: Date(),
                                                            cal: .current).first else {
            mostraAvviso(TestiAppMercato.messaggioNonPreparato)
            return
        }
        preparaMessaggio(clienteId: a.clienteId, occasione: o)
    }

    // MARK: - Ricerca per ISIN

    /// Cerca l'ISIN del campo: con il campo vuoto non fa nulla (§12.4).
    func cercaISINMercato() {
        let s = sessioneMercato
        let testo = s.testoISIN.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testo.isEmpty else { return }
        s.risultatoISIN = MotoreMercato.cercaISIN(testo, posizioni: posizioni, quote: dati.mercato.quote)
        s.giroRicerca += 1
    }

    /// Esc: svuota il campo e toglie il risultato.
    func chiudiRicercaISIN() {
        sessioneMercato.testoISIN = ""
        sessioneMercato.risultatoISIN = nil
    }

    // MARK: - Impostazioni

    /// L'interruttore «Dati di mercato». Acceso: il primo scaricamento parte subito (sul Mac).
    @MainActor
    func impostaDatiDiMercato(_ acceso: Bool) {
        guard dati.impostazioni.mercato.attivo != acceso else { return }
        dati.impostazioni.mercato.attivo = acceso
        if acceso { aggiornaMercato(forza: true) }
    }

    /// Una soglia cambiata: gli avvisi si ricalcolano.
    func impostaSogliaMercato(_ modifica: (inout ImpostazioniMercato) -> Void) {
        var m = dati.impostazioni.mercato
        modifica(&m)
        guard m != dati.impostazioni.mercato else { return }
        dati.impostazioni.mercato = m
        ricalcolaAvvisiMercato()
    }

    /// Accende o spegne una serie della configurazione (l'ordine resta quello del file).
    func impostaSerieMercato(_ id: String, attiva: Bool) {
        guard let c = sessioneMercato.configurazione else { return }
        var scelte = Set(c.attive(dati.impostazioni.mercato).map(\.id))
        if attiva { scelte.insert(id) } else { scelte.remove(id) }
        let elenco = c.serie.map(\.id).filter { scelte.contains($0) }
        dati.impostazioni.mercato.serieAttive = elenco.count == c.serie.count ? nil : elenco
    }

    // MARK: - Rete (solo sul Mac, solo con l'interruttore acceso)

    /// All'apertura di Mercato: gli avvisi si ricalcolano e, con l'interruttore acceso, le serie si scaricano se
    /// l'ultimo aggiornamento ha più di `ClienteMercato.intervalloMinimo`.
    @MainActor
    func aperturaMercato() {
        guard persistente else { return }
        ricalcolaAvvisiMercato()
        aggiornaMercato(forza: false)
    }

    /// Scarica le serie configurate (ClienteMercato.aggiorna): niente con l'interruttore spento, nelle istantanee,
    /// in sola lettura o su iPhone e iPad. Le serie arrivate sostituiscono le loro; tutto il resto dell'archivio
    /// (quote, serie importate, avvisi) resta com'è adesso.
    @MainActor
    func aggiornaMercato(forza: Bool) {
        #if os(macOS)
        let s = sessioneMercato
        guard persistente, !solaLettura, dati.impostazioni.mercato.attivo, !s.inAggiornamento else { return }
        guard let configurazione = s.configurazione else {
            mostraAvviso(TestiAppMercato.configurazioneMancante)
            return
        }
        let archivio = dati.mercato
        let impostazioni = dati.impostazioni.mercato
        let oggi = Date()
        s.inAggiornamento = true
        Task { @MainActor [weak self] in
            let esito = await ClienteMercato.aggiorna(archivio, impostazioni: impostazioni, configurazione: configurazione,
                                                      oggi: oggi, forza: forza)
            guard let self else { return }
            self.sessioneMercato.inAggiornamento = false
            guard !esito.saltato, self.dati.impostazioni.mercato.attivo else { return }
            var m = self.dati.mercato
            let arrivate = Set(esito.scaricate).union(configurazione.calcolate.map(\.id))
            for nuova in esito.archivio.serie where arrivate.contains(nuova.id) {
                if let i = m.serie.firstIndex(where: { $0.id == nuova.id }) { m.serie[i] = nuova } else { m.serie.append(nuova) }
            }
            m.ultimoAggiornamento = esito.archivio.ultimoAggiornamento
            m.ultimoErrore = esito.archivio.ultimoErrore
            self.dati.mercato = m
            self.ricalcolaAvvisiMercato()
            if !esito.errori.isEmpty {
                self.mostraAvviso(TestiAppMercato.erroreScaricamento(scaricate: esito.scaricate.count, errori: esito.errori.count))
            } else if forza {
                self.mostraAvviso(TestiAppMercato.scaricate(esito.scaricate.count))
            }
        }
        #endif
    }

    // MARK: - File e valori a mano

    /// Sceglie un file CSV e lo legge: la lettura va nel foglio «Importa i dati del mercato» per la conferma.
    @MainActor
    func scegliFileMercato() {
        #if os(macOS)
        guard !solaLettura else { return }
        let pannello = NSOpenPanel()
        pannello.allowedContentTypes = [.commaSeparatedText, .tabSeparatedText, .plainText]
        pannello.allowsMultipleSelection = false
        pannello.message = TestiAppMercato.importaSpiegazione
        guard pannello.runModal() == .OK, let url = pannello.url else { return }
        guard let testo = Self.testoFile(url) else {
            mostraAvviso(TestiAppMercato.fileNonLeggibile)
            return
        }
        sessioneMercato.importazione = ImportazioneMercatoInAttesa(file: url.lastPathComponent,
                                                                   esito: LettoreMercato.importaCSV(testo, oggi: Date()))
        sessioneMercato.foglio = .importa
        #endif
    }

    /// Il testo del file in UTF-8 o, se non lo è, in Latin-1 (gli export di Excel).
    static func testoFile(_ url: URL) -> String? {
        guard let dati = try? Data(contentsOf: url) else { return nil }
        return String(data: dati, encoding: .utf8) ?? String(data: dati, encoding: .isoLatin1)
    }

    /// Registra una lettura confermata: una serie (con nome, tipo, unità e frequenza scelti) o le quote per ISIN, con
    /// la fonte scritta dal consulente. Restituisce quanti valori sono entrati.
    @discardableResult
    func registraImportazioneMercato(_ i: ImportazioneMercatoCSV, fonte: String, nome: String, tipo: TipoSerieMercato,
                                     unita: UnitaMercato, frequenza: FrequenzaMercato) -> Int {
        guard !solaLettura else { return 0 }
        let oggi = Date()
        let f = fonte.trimmingCharacters(in: .whitespacesAndNewlines)
        var m = dati.mercato
        switch i.forma {
        case .serie:
            let n = nome.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !n.isEmpty, !i.punti.isEmpty else { return 0 }
            MotoreMercato.registraImportata(id: Self.idSerieMercato(n, archivio: m), nome: n, punti: i.punti, fonte: f, origine: .csv,
                                            unita: unita, tipo: tipo, frequenza: frequenza, in: &m, il: oggi)
        case .quote:
            guard !i.quote.isEmpty else { return 0 }
            MotoreMercato.registraQuote(i.quote, fonte: f, origine: .csv, in: &m, il: oggi)
        }
        dati.mercato = m
        ricalcolaAvvisiMercato()
        return i.valoriLetti
    }

    /// Un valore scritto a mano per una serie (dell'archivio o della configurazione). false se non si legge.
    func registraValoreAMano(serie id: String, data: String, valore: String, fonte: String) -> Bool {
        guard !solaLettura, let d = LettoreMercato.dataAMano(data), let v = LettoreMercato.valoreAMano(valore) else { return false }
        let punto = PuntoMercato(data: d, valore: v)
        var m = dati.mercato
        if let s = m.serie(id) {
            MotoreMercato.registraImportata(id: s.id, nome: s.nome, punti: [punto], fonte: Self.fonteAMano(fonte, altrimenti: s.fonte),
                                            origine: .aMano, unita: s.unita, tipo: s.tipo, frequenza: s.frequenza, in: &m, il: Date())
        } else if let c = sessioneMercato.configurazione?.serie(id) {
            MotoreMercato.registraImportata(id: c.id, nome: c.nome, punti: [punto], fonte: Self.fonteAMano(fonte, altrimenti: ""),
                                            origine: .aMano, unita: c.unita, tipo: c.tipo, frequenza: c.frequenza, in: &m, il: Date())
        } else {
            return false
        }
        dati.mercato = m
        ricalcolaAvvisiMercato()
        return true
    }

    /// La quota di un ISIN scritta a mano. false se l'ISIN, la data o il valore non vanno.
    func registraQuotaAMano(isin: String, data: String, valore: String, fonte: String) -> Bool {
        let codice = MotoreMercato.normalizzaISIN(isin)
        guard !solaLettura, MotoreMercato.isinValido(codice), let d = LettoreMercato.dataAMano(data),
              let v = LettoreMercato.valoreAMano(valore), v > 0 else { return false }
        var m = dati.mercato
        MotoreMercato.registraQuote([codice: [PuntoMercato(data: d, valore: v)]], fonte: Self.fonteAMano(fonte, altrimenti: ""),
                                    origine: .aMano, in: &m, il: Date())
        dati.mercato = m
        ricalcolaAvvisiMercato()
        return true
    }

    private static func fonteAMano(_ fonte: String, altrimenti: String) -> String {
        let f = fonte.trimmingCharacters(in: .whitespacesAndNewlines)
        return f.isEmpty ? altrimenti : f
    }

    /// «serie-ftse-mib» (con un numero se l'id c'è già per un'altra serie con un altro nome).
    static func idSerieMercato(_ nome: String, archivio: ArchivioMercato) -> String {
        let pezzi = nome.lowercased().folding(options: .diacriticInsensitive, locale: Formati.italiano)
            .map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
            .split(separator: "-").joined(separator: "-")
        let base = "serie-" + (pezzi.isEmpty ? "consulente" : pezzi)
        var id = base
        var n = 2
        while let s = archivio.serie(id), s.nome != nome {
            id = "\(base)-\(n)"
            n += 1
        }
        return id
    }

    // MARK: - Posizioni dalle quote

    /// I valori nuovi delle posizioni con un ISIN e una quota più recente (quota × numero di quote).
    func valoriDaQuoteMercato(oggi: Date = Date()) -> [ValoreDaMercato] {
        MotoreMercato.valoriDaQuote(posizioni: dati.posizioni, quote: dati.mercato.quote, oggi: oggi)
    }

    /// Li registra con lo stesso percorso di «Aggiorna i valori» (dopo un backup, con lo storico e il riepilogo).
    func aggiornaPosizioniDaQuote() {
        let righe = MotoreMercato.righeAggiornamento(valoriDaQuoteMercato())
        guard !righe.isEmpty else {
            mostraAvviso(TestiAppMercato.nienteDaRegistrare)
            return
        }
        let oggi = Date()
        let esiti = AggiornaValori.esiti(righe, posizioni: dati.posizioni, clienti: dati.clienti, dataComune: oggi, oggi: oggi)
        guard AggiornaValori.daRegistrare(esiti, esclusi: []) > 0 else {
            mostraAvviso(TestiAppMercato.nienteDaRegistrare)
            return
        }
        registraValoriInBlocco(esiti, esclusi: [])
    }
}

/// Il colore del pallino di un avviso (§12.1.6).
enum TonoAvvisoMercato: Equatable {
    case rosso, arancio, verde, spento
}
