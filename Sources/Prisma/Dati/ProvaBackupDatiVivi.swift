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
            ("il nome dell'utente", { $0.impostazioni.nomeUtente += " prova" }),
            ("la tolleranza del radar", { $0.impostazioni.tolleranzaRadar = 0.07 }),
            ("una posizione", { $0.posizioni[0].nome += " prova" }),
            ("un appuntamento", { $0.appuntamenti[0].titolo += " prova" }),
            ("un'attività", { $0.attivita.removeLast() }),
            ("il mercato", { $0.mercato = ArchivioMercato() }),
            ("i portafogli modello", { $0.portafogliModello = [] }),
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
}
