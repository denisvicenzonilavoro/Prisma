import Foundation

// La linea della vita nello stato (Orizzonte, giro 4; specifica §7.4): gli eventi del cliente (`DatiPrisma.eventiVita`)
// si aggiungono, si modificano, si spostano trascinando il gettone e si tolgono; la pensione trascinata si scrive
// nell'età di pensione del dossier. Ogni modifica passa da `dati`, quindi si salva come le altre.

extension StatoShell {
    /// Gli eventi della linea della vita del cliente, nell'ordine dell'archivio.
    func eventiVitaCliente(_ id: String) -> [EventoLineaVita] {
        dati.eventiVita.filter { $0.clienteId == id }
    }

    /// Aggiunge l'evento o sostituisce quello con lo stesso id.
    func salvaEventoVita(_ e: EventoLineaVita) {
        if let i = dati.eventiVita.firstIndex(where: { $0.id == e.id }) {
            dati.eventiVita[i] = e
        } else {
            dati.eventiVita.append(e)
        }
    }

    /// Toglie l'evento dalla linea della vita.
    func eliminaEventoVita(_ id: String) {
        dati.eventiVita.removeAll { $0.id == id }
    }

    /// Il gettone lasciato a un'altra età: l'età (e l'anno che le corrisponde) si scrive nell'evento.
    func spostaEventoVita(_ id: String, eta: Int, etaOggi: Int, oggi: Date = Date()) {
        guard let i = dati.eventiVita.firstIndex(where: { $0.id == id }) else { return }
        let anno = Calendar.current.component(.year, from: oggi)
        var e = dati.eventiVita[i]
        e.eta = MotoreLineaVita.limitaEtaEvento(eta, etaOggi: etaOggi)
        e.anno = anno + ((e.eta ?? eta) - etaOggi)
        dati.eventiVita[i] = e
    }

    /// Il gettone della pensione lasciato a un'altra età: si scrive nei dati del lavoro del cliente (Profilo ›
    /// Lavoro); senza dati del lavoro, nell'Analisi 360 salvata; senza nemmeno quella, nei dati del lavoro nuovi con
    /// la sola età (il resto resta da indicare).
    func impostaEtaPensioneLineaVita(clienteId id: String, eta: Int) {
        guard var c = cliente(id) else { return }
        let nuova = MotoreLineaVita.limitaEtaPensione(eta)
        if c.profilo.lavoro != nil {
            c.profilo.lavoro?.etaPensione = nuova
            salvaCliente(c)
        } else if var a = dati.analisi[id] {
            a.previdenza.etaPensione = nuova
            dati.analisi[id] = a
        } else {
            c.profilo.lavoro = DatiLavoro(etaPensione: nuova)
            salvaCliente(c)
        }
    }
}
