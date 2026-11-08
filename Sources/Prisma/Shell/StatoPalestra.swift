import Foundation
import Observation

// Lo stato della palestra della trattativa (Studio › Palestra, «Luce» giro 5): cliente, difficoltà, turni, convinzione,
// fase e il lavoro di Qwen, cancellabile. Un oggetto a parte da StatoShell (come la Sala e il copilota): ogni parola
// che arriva ridisegna solo la conversazione, non la shell. Le modifiche avvengono sul thread principale.
// La conversazione non si salva: alla fine si registra solo l'esito (`Impostazioni.palestra`).

@Observable final class StatoPalestra {
    enum Fase: Equatable {
        /// Prima di cominciare: si sceglie cliente e difficoltà.
        case attesa
        /// Vera sta scrivendo (l'obiezione o la replica).
        case veraScrive
        /// Tocca al consulente: le risposte sono attive.
        case tuoTurno
        case fine
        /// Qwen non è pronto: la palestra lo dice e non parte (nessuna obiezione finta).
        case nonPronta(String)
        /// Vera non è riuscita a recitare il turno (JSON illeggibile o cifre non di Prisma, due volte).
        case errore(String)
    }

    /// Il cliente recitato (nil: il cliente attivo della shell, se c'è).
    var clienteId: String?
    /// Il profilo inventato (solo età, lavoro e timori); usato al posto del cliente se `usaInventato`.
    var inventato = ProfiloInventatoPalestra()
    var usaInventato = false
    var difficolta = DifficoltaPalestra.realistica
    private(set) var turni: [TurnoPalestra] = []
    private(set) var fase = Fase.attesa
    private(set) var convinta = DifficoltaPalestra.realistica.convinzioneIniziale
    /// Il testo di Vera mentre si scrive (la replica o, al primo turno, l'obiezione).
    private(set) var parziale = ""
    /// Vera ci mette più di 20 s.
    private(set) var lenta = false
    /// Il campo «Oppure rispondi a parole tue…».
    var campo = ""
    /// Il punteggio finale (nil prima della fine).
    private(set) var punteggio: Int?
    /// Il microfono del campo è acceso (la voce del Mac già in Vera).
    var ascolta = false

    /// Gli strumenti indicati da Vera nei turni («Cosa potevi usare»).
    @ObservationIgnored private(set) var strumenti: [StrumentoPalestra] = []
    /// La scheda dell'allenamento in corso (fissata a «Inizia»).
    @ObservationIgnored private(set) var scheda: SchedaRecita?
    @ObservationIgnored private var compito: Task<Void, Never>?
    @ObservationIgnored private var compitoLento: Task<Void, Never>?
    /// Le prove passano una sessione con il Qwen finto.
    @ObservationIgnored var sessione: URLSession = .shared

    var inCorso: Bool { fase == .veraScrive || fase == .tuoTurno }

    /// Il cliente scelto, o quello attivo della shell.
    func clienteScelto(_ stato: StatoShell) -> Cliente? {
        if let id = clienteId, let c = stato.cliente(id) { return c }
        return stato.clienteAttivo
    }

    /// La scheda della recita per la scelta di adesso (nil: nessun cliente e nessun profilo inventato).
    func schedaScelta(_ stato: StatoShell) -> SchedaRecita? {
        if usaInventato { return inventato.vuoto ? nil : PalestraVera.scheda(inventato: inventato) }
        guard let c = clienteScelto(stato), let f = stato.fonteVera(c.id) else { return nil }
        return PalestraVera.scheda(f)
    }

    /// La scheda da mostrare: quella dell'allenamento in corso o quella della scelta.
    func schedaMostrata(_ stato: StatoShell) -> SchedaRecita? {
        if fase != .attesa, let scheda { return scheda }
        return schedaScelta(stato)
    }

    // MARK: - Scelte

    func scegli(cliente id: String) {
        guard !inCorso else { return }
        usaInventato = false
        clienteId = id
        azzera()
    }

    func scegliInventato() {
        guard !inCorso else { return }
        usaInventato = true
        azzera()
    }

    /// Torna all'inizio (conversazione vuota), senza chiamare Qwen.
    func azzera() {
        compito?.cancel()
        compitoLento?.cancel()
        compito = nil
        turni = []
        fase = .attesa
        parziale = ""
        lenta = false
        punteggio = nil
        strumenti = []
        scheda = nil
        campo = ""
        convinta = difficolta.convinzioneIniziale
    }

    // MARK: - L'allenamento

    /// «Inizia l'allenamento» (e «Rifai»): se Qwen non è pronto lo dice e non parte.
    func inizia(_ stato: StatoShell) {
        guard let s = schedaScelta(stato) else { return }
        azzera()
        self.stato = stato
        scheda = s
        fase = .veraScrive
        let vera = stato.dati.impostazioni.vera
        let verifica = !stato.disponibilitaLocale.pronto
        compito = Task { @MainActor [weak self] in
            if verifica {
                let d = await MotoreLocale.verificaDispositivo(vera)
                if stato.disponibilitaLocale != d { stato.disponibilitaLocale = d }
            }
            guard let self, !Task.isCancelled else { return }
            guard stato.disponibilitaLocale.pronto else {
                self.fase = .nonPronta(stato.disponibilitaLocale.motivo ?? "Qwen non risponde.")
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(Tema.Apple.Moto.Palestra.attesaInizio * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self.chiama(vera: vera, scheda: s)
        }
    }

    /// Il consulente risponde (una suggerita o parole sue).
    func rispondi(_ testo: String, stato: StatoShell) {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard fase == .tuoTurno, !t.isEmpty, let s = scheda, !turni.isEmpty else { return }
        campo = ""
        turni[turni.count - 1].risposta = t
        fase = .veraScrive
        let vera = stato.dati.impostazioni.vera
        compito = Task { @MainActor [weak self] in
            await self?.chiama(vera: vera, scheda: s)
        }
    }

    /// Esc o «Annulla»: interrompe Vera se scrive. La risposta del turno torna da scrivere.
    func annulla() {
        guard fase == .veraScrive else { return }
        compito?.cancel()
        compitoLento?.cancel()
        compito = nil
        parziale = ""
        lenta = false
        if turni.isEmpty {
            fase = .attesa
            scheda = nil
        } else {
            if turni[turni.count - 1].replica == nil { turni[turni.count - 1].risposta = nil }
            fase = .tuoTurno
        }
    }

    /// Dopo un errore: riprova lo stesso turno.
    func riprova(_ stato: StatoShell) {
        guard case .errore = fase, let s = scheda else { return }
        if turni.isEmpty {
            inizia(stato)
            return
        }
        fase = .veraScrive
        let vera = stato.dati.impostazioni.vera
        compito = Task { @MainActor [weak self] in
            await self?.chiama(vera: vera, scheda: s)
        }
    }

    @MainActor private func chiama(vera: ImpostazioniVera, scheda s: SchedaRecita) async {
        parziale = ""
        lenta = false
        compitoLento?.cancel()
        compitoLento = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Tema.Apple.Palestra.attesaLenta * 1_000_000_000))
            guard !Task.isCancelled, let self, self.fase == .veraScrive else { return }
            self.lenta = true
        }
        defer { compitoLento?.cancel() }
        let motore = MotoreLocale(vera, disponibilita: .pronto, sessione: sessione)
        let giocati = turni
        do {
            let r = try await PalestraVera.turno(motore: motore, vera: vera, scheda: s, difficolta: difficolta, turni: giocati) { testo in
                Task { @MainActor [weak self] in
                    guard let self, self.fase == .veraScrive else { return }
                    self.parziale = testo
                }
            }
            guard !Task.isCancelled, fase == .veraScrive else { return }
            applica(r, scheda: s)
            if fase == .veraScrive, let prossima = r.prossimaObiezione, !prossima.isEmpty {
                // La replica resta un momento, poi l'obiezione dopo
                try? await Task.sleep(nanoseconds: UInt64(Tema.Apple.Moto.Palestra.pausaTurno * 1_000_000_000))
                guard !Task.isCancelled, fase == .veraScrive else { return }
                turni.append(TurnoPalestra(id: turni.count, obiezione: prossima, suggerite: r.suggerite))
                fase = .tuoTurno
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            parziale = ""
            fase = .errore((error as? ErroreVera)?.messaggio ?? "Vera non è riuscita a recitare il turno: riprova.")
        }
    }

    /// Mette nella conversazione la risposta di un turno (le prove la usano senza Qwen).
    func applica(_ r: RispostaPalestra, scheda s: SchedaRecita) {
        parziale = ""
        lenta = false
        if let st = r.strumento { strumenti.append(st) }
        if turni.isEmpty {
            convinta = difficolta.convinzioneIniziale
            turni = [TurnoPalestra(id: 0, obiezione: r.prossimaObiezione ?? "", suggerite: r.suggerite)]
            fase = .tuoTurno
            return
        }
        let i = turni.count - 1
        guard let risposta = turni[i].risposta else { return }
        let ammesse = PalestraVera.cifreAmmesse(scheda: s, turni: Array(turni.prefix(i)))
        let regole = PalestraVera.giudizioRegole(risposta, scheda: s, ammesse: ammesse)
        let finale = PalestraVera.giudizioFinale(regole: regole.massimo, qwen: r.giudizio)
        turni[i].giudizio = finale
        turni[i].motivo = finale == r.giudizio && !r.motivo.isEmpty ? r.motivo : (regole.motivo ?? r.motivo)
        turni[i].replica = r.replica
        convinta = PalestraVera.convinzione(precedente: convinta, proposta: r.convinta, difficolta: difficolta)
        if turni.count >= PalestraVera.obiezioni || (r.prossimaObiezione ?? "").isEmpty {
            concludi()
        }
    }

    /// La fine: punteggio e registro leggero (mai la conversazione).
    private func concludi() {
        let p = PalestraVera.punteggio(turni.compactMap(\.giudizio), obiezioni: max(turni.count, 1))
        punteggio = p
        fase = .fine
        stato?.registraEsitoPalestra(EsitoPalestra(data: Date(), clienteId: scheda?.clienteId, difficolta: difficolta, punteggio: p))
    }

    /// La shell che registra l'esito nelle impostazioni (debole: la palestra vive dentro StatoShell).
    @ObservationIgnored private weak var stato: StatoShell?

    // MARK: - Istantanee

    /// Una conversazione già scritta (le istantanee, nello stato finale): frasi di prova del codice, mai di Qwen.
    func prepara(scheda s: SchedaRecita, turni t: [TurnoPalestra], fase f: Fase, convinta c: Int, parziale p: String = "",
                 strumenti st: [StrumentoPalestra] = []) {
        scheda = s
        turni = t
        fase = f
        convinta = c
        parziale = p
        strumenti = st
        punteggio = f == .fine ? PalestraVera.punteggio(t.compactMap(\.giudizio), obiezioni: max(t.count, 1)) : nil
    }
}

extension StatoShell {
    /// Registra l'esito di un allenamento finito nelle impostazioni (mai in sola lettura, nelle prove o nelle istantanee).
    func registraEsitoPalestra(_ e: EsitoPalestra) {
        guard persistente, !solaLettura else { return }
        dati.impostazioni.palestra.registra(e)
    }

    /// «Linea della vita», «Lancia l'anno», «Il film del piano» dalla fine dell'allenamento: per il cliente recitato.
    func apriDallaPalestra(_ s: StrumentoPalestra, cliente id: String?) {
        switch s {
        case .lineaVita:
            if let id, cliente(id) != nil { clienteAttivoId = id }
            schedaCliente = .lineaVita
            apri(.clienti)
        case .lanciaAnno:
            apriEsperienza(.lanciaAnno, cliente: id)
        case .film:
            apriEsperienza(.film, cliente: id)
        case .provaFuoco:
            if let id, cliente(id) != nil { clienteAttivoId = id }
            apriProvaDelFuoco()
        }
    }
}
