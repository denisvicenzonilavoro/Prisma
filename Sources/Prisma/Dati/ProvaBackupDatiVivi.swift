import Combine
import Foundation
import Observation

// I dati a pezzi (DatiVivi, giro 0 di «Prisma istantaneo») dentro `Prisma --prova-backup`: la sola strada verso il
// disco e i backup è `istantanea`, quindi deve contenere tutto l'archivio; ogni modifica, anche annidata, deve far
// partire il salvataggio (il segnale `modificheDati`, su cui il salvataggio aspetta 0,8 s) e muovere i contatori delle
// cache con la stessa regola di `DatiPrisma.stessiCalcoli`; un'istantanea presa prima resta com'era; `carica` sostituisce
// tutto con un solo segnale; ogni campo si osserva da solo.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaDatiVivi() -> String? {
        // Andata e ritorno: i dati di prova e i 30 clienti fittizi, uguali e con lo stesso JSON
        for (nome, d) in [("dati di prova", DatiPrisma.demo()), ("clienti fittizi", ClientiFittizi.completi())] {
            let vivi = DatiVivi(d)
            guard vivi.istantanea == d else { return "dati a pezzi: l'istantanea dei \(nome) non è l'archivio di partenza" }
            guard (try? Archivio.nuovoCodificatore().encode(vivi.istantanea)) == (try? Archivio.nuovoCodificatore().encode(d)) else {
                return "dati a pezzi: l'istantanea dei \(nome) non si salva come l'archivio di partenza"
            }
        }
        // Nessun campo dimenticato: DatiVivi ha tanti campi quanti DatiPrisma
        let campi = Mirror(reflecting: DatiPrisma.demo()).children.count
        guard campi == DatiVivi.numeroCampi else {
            return "dati a pezzi: DatiPrisma ha \(campi) campi, DatiVivi ne copia \(DatiVivi.numeroCampi)"
        }

        let stato = StatoShell(persistente: false)
        var segnali = 0
        var clientiAttivi: [String] = []
        var abbonamenti = Set<AnyCancellable>()
        stato.modificheDati.sink { segnali += 1 }.store(in: &abbonamenti)
        stato.clienteAttivoCambiato.sink { clientiAttivi.append($0) }.store(in: &abbonamenti)

        // Una modifica annidata: un segnale (il salvataggio parte), una generazione nuova, le cache dei calcoli rifatte
        let fotografia = stato.dati.istantanea
        let (d0, c0, n0) = (stato.versioneDati, stato.versioneCalcoli, stato.versioneNote)
        stato.dati.clienti[0].nome += " modificato"
        guard segnali == 1, stato.versioneDati == d0 + 1 else {
            return "dati a pezzi: una modifica annidata a un cliente non fa partire il salvataggio (\(segnali) segnali)"
        }
        guard stato.versioneCalcoli == c0 + 1, stato.versioneNote == n0 else {
            return "dati a pezzi: una modifica a un cliente non rifà le cache dei calcoli"
        }
        // L'istantanea presa prima resta com'era (è un valore, non lo stesso oggetto)
        guard fotografia.clienti[0].nome != stato.dati.clienti[0].nome, fotografia == DatiPrisma.demo() else {
            return "dati a pezzi: un'istantanea presa prima di una modifica è cambiata con i dati"
        }

        // La regola dei contatori, campo per campo, uguale a `stessiCalcoli` (calcoli) e alle note (versioneNote)
        let altroCliente = stato.dati.clienti.last!.id
        let modifiche: [(String, (DatiVivi) -> Void)] = [
            ("una nota", { $0.note[0].testo += "·" }),
            ("una nota nuova", { $0.note.append(Nota(clienteId: altroCliente, titolo: "Prova", testo: "")) }),
            ("le conversazioni", { $0.conversazioni["prova"] = [] }),
            ("gli spazi", { $0.spazi = [] }),
            ("il cliente attivo", { $0.clienteAttivoId = altroCliente }),
            ("le schede di adeguatezza", { $0.schedeAdeguatezza = [] }),
            ("i confronti del TFR", { $0.confrontiTFR = [:] }),
            ("le pratiche", { $0.pratiche = [] }),
            ("l'aspetto", { $0.impostazioni.aspetto = .scuro }),
            ("le impostazioni di Vera", { $0.impostazioni.vera.leggiTutto.toggle() }),
            ("le impostazioni di Vera su misura", { $0.impostazioni.vera.suMisura.modelloPrecedente = "qwen3.5:4b" }),
            ("il tipo di motore esterno", { $0.impostazioni.vera.motoreEsterno.tipo = .servizio }),
            ("il nome dell'utente", { $0.impostazioni.nomeUtente += " prova" }),
            ("la tolleranza del radar", { $0.impostazioni.tolleranzaRadar = 0.07 }),
            ("una posizione", { $0.posizioni[0].nome += " prova" }),
            ("un appuntamento", { $0.appuntamenti[0].titolo += " prova" }),
            ("un'attività", { $0.attivita.removeLast() }),
            ("il mercato", { $0.mercato = ArchivioMercato() }),
            ("i portafogli modello", { $0.portafogliModello = [] }),
            // Vera, fase 4: routine, tagliando, spiegazioni in tre livelli e profilo di stile e voci chiuse del sussurro neutri
            ("le routine", { $0.routine = ArchivioRoutine(routine: [RoutineVera.pronte()[0]]) }),
            ("il tagliando", { $0.tagliando.ignorate.append("prova") }),
            ("le impostazioni del tagliando", { $0.impostazioni.tagliando.ora = 4 }),
            ("le spiegazioni in tre livelli", { $0.spiegazioniTreLivelli = [] }),
            ("il profilo di stile", { $0.impostazioni.stileVera.firma = .scritta("Prova") }),
            ("le voci chiuse del sussurro", { $0.sussurriChiusi.append(SussurroChiuso(clienteId: altroCliente, chiave: "prova", chiusoIl: Date())) }),
        ]
        for (nome, modifica) in modifiche {
            let prima = stato.dati.istantanea
            let (s, c, n) = (segnali, stato.versioneCalcoli, stato.versioneNote)
            modifica(stato.dati)
            let dopo = stato.dati.istantanea
            guard segnali == s + 1 else { return "dati a pezzi: \(nome): \(segnali - s) segnali di modifica invece di uno" }
            // Una scrittura che non cambia nulla (lo stesso valore) può rifare le cache: costa un ricalcolo, non un errore
            let ricalcolate = stato.versioneCalcoli != c
            guard ricalcolate == !dopo.stessiCalcoli(di: prima) || (ricalcolate && dopo == prima) else {
                return "dati a pezzi: \(nome): le cache dei calcoli non seguono la regola di stessiCalcoli"
            }
            guard (stato.versioneNote != n) == (dopo.note != prima.note) else {
                return "dati a pezzi: \(nome): la versione delle note non segue le note"
            }
        }
        guard clientiAttivi == [altroCliente] else { return "dati a pezzi: il cambio del cliente attivo non si annuncia una volta sola" }
        stato.dati.clienteAttivoId = altroCliente
        guard clientiAttivi.count == 1 else { return "dati a pezzi: lo stesso cliente attivo annunciato di nuovo" }

        // Ogni campo si osserva da solo: una nota non tocca chi legge i clienti, un cliente sì
        var clientiToccati = false
        withObservationTracking { _ = stato.dati.clienti } onChange: { clientiToccati = true }
        stato.dati.note[0].testo += "·"
        guard !clientiToccati else { return "dati a pezzi: una nota avvisa anche chi legge solo i clienti" }
        stato.dati.clienti[0].nome += "·"
        guard clientiToccati else { return "dati a pezzi: una modifica a un cliente non avvisa chi legge i clienti" }

        if let errore = provaOsservazioniMirate(stato) { return errore }

        // `carica` sostituisce tutto, con un solo segnale e le cache rifatte
        let fittizi = ClientiFittizi.completi()
        let (s1, c1) = (segnali, stato.versioneCalcoli)
        stato.dati.carica(fittizi)
        guard stato.dati.istantanea == fittizi else { return "dati a pezzi: carica non sostituisce tutto l'archivio" }
        guard segnali == s1 + 1 else { return "dati a pezzi: carica manda \(segnali - s1) segnali invece di uno" }
        guard stato.versioneCalcoli == c1 + 1 else {
            return "dati a pezzi: dopo carica le cache dei calcoli non si rifanno"
        }
        // Dopo carica le modifiche continuano a partire (l'aggancio resta)
        stato.dati.clienti[0].nome += "·"
        guard segnali == s1 + 2 else { return "dati a pezzi: dopo carica le modifiche non fanno più partire il salvataggio" }
        return nil
    }

    /// Le letture mirate della revisione della tappa 1: l'ora e il giorno arrivano alle viste dei dati ricavati,
    /// le impostazioni dei calcoli si leggono senza iscriversi a tutte le impostazioni, l'elenco dei confronti legge
    /// solo clienti, posizioni e simulazioni.
    static func provaOsservazioniMirate(_ stato: StatoShell) -> String? {
        // L'ora e il giorno: chi legge la ChiaveVista o una cache giornaliera si rifà allo scoccare dell'ora
        let adesso = Date()
        stato.aggiornaOrologioVista(adesso)
        var chiaveToccata = false
        var prossimiToccati = false
        withObservationTracking { _ = stato.chiaveVista } onChange: { chiaveToccata = true }
        withObservationTracking { _ = stato.prossimiAppuntamenti } onChange: { prossimiToccati = true }
        stato.aggiornaOrologioVista(adesso)
        guard !chiaveToccata, !prossimiToccati else {
            return "dati a pezzi: lo stesso giorno e la stessa ora ridisegnano le viste dei dati ricavati"
        }
        stato.aggiornaOrologioVista(adesso.addingTimeInterval(3600))
        guard chiaveToccata else { return "dati a pezzi: allo scoccare dell'ora chi legge la chiave delle viste non si rifà" }
        guard prossimiToccati else { return "dati a pezzi: allo scoccare dell'ora chi legge i prossimi appuntamenti non si rifà" }
        var giornoToccato = false
        withObservationTracking { _ = stato.chiaveVista } onChange: { giornoToccato = true }
        stato.riverificaGiornoDerivati()
        stato.aggiornaOrologioVista(adesso.addingTimeInterval(86_400))
        guard giornoToccato else { return "dati a pezzi: a mezzanotte chi legge la chiave delle viste non si rifà" }
        stato.aggiornaOrologioVista(adesso)

        // Le impostazioni dei calcoli: l'aspetto non rifà chi le legge; i giorni del seguito e i riferimenti cambiano
        // la versione dei calcoli, quindi la chiave dei corpi Equatable che le leggono
        var impostazioniToccate = false
        withObservationTracking { _ = stato.dati.impostazioniDeiCalcoli } onChange: { impostazioniToccate = true }
        stato.dati.impostazioni.aspetto = stato.dati.impostazioni.aspetto == .scuro ? .chiaro : .scuro
        stato.dati.impostazioni.nomeUtente += "·"
        guard !impostazioniToccate else { return "dati a pezzi: le impostazioni dei calcoli si rifanno per l'aspetto o il nome" }
        let c0 = stato.versioneCalcoli
        let altriGiorni = Impostazioni.sceltaGiorniSeguito.first { $0 != stato.dati.impostazioni.giorniSeguitoProposte }
        stato.dati.impostazioni.giorniSeguitoProposte = altriGiorni ?? stato.dati.impostazioni.giorniSeguitoProposte + 1
        guard stato.versioneCalcoli != c0 else { return "dati a pezzi: i giorni del seguito non cambiano la chiave del portafoglio" }
        let c1 = stato.versioneCalcoli
        stato.dati.impostazioni.riferimenti.perMercato = "prova"
        guard stato.versioneCalcoli != c1 else { return "dati a pezzi: i riferimenti non cambiano la chiave del track record" }

        // L'elenco dei confronti dai dati vivi: lo stesso di quello dall'istantanea, e una nota non lo tocca
        let cliente = stato.dati.clienti[0].id
        let daVivi = ElementoConfronto.elenco(stato.dati, cliente: cliente).map(\.voce)
        let daIstantanea = ElementoConfronto.elenco(stato.dati.istantanea, cliente: cliente).map(\.voce)
        guard daVivi == daIstantanea else { return "dati a pezzi: l'elenco dei confronti dai dati vivi non è quello dell'archivio" }
        var confrontiToccati = false
        withObservationTracking { _ = ElementoConfronto.elenco(stato.dati, cliente: cliente) } onChange: { confrontiToccati = true }
        stato.dati.note[0].testo += "·"
        guard !confrontiToccati else { return "dati a pezzi: una nota rifà l'elenco dei confronti di Prospetti" }
        stato.dati.posizioni[0].nome += "·"
        guard confrontiToccati else { return "dati a pezzi: una posizione cambiata non rifà l'elenco dei confronti" }
        return nil
    }
}
