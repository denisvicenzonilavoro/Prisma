import Foundation

// Il film del piano nello stato della shell («Luce» giro 15, §3.2): i dati del film del cliente (ricordati finché i dati
// non cambiano), l'avvertenza (dell'utente o il segnaposto, decisione 56), il video esportato come Documento del cliente
// (D-F6) con l'impronta dei dati in `Cliente.prismaCliente` («il piano è cambiato dopo il …: esporta di nuovo»), la copia
// da condividere in `CartellaUscite` e la traccia nel dossier quando il video esce dal foglio di condivisione.

extension StatoShell {
    /// I dati del film del cliente (nil se restano solo titolo e chiusura).
    func datiFilm(_ c: Cliente, oggi: Date = Date()) -> DatiFilm? {
        let attuale = cliente(c.id) ?? c
        let avvertenza = ImpostazioniSala.avvertenza(dati.impostazioni.sala.avvertenzaFilm).testo
        let diProva = StatoShell.clientiDiProva.contains(c.id)
        return CacheFilm.dati(cliente: attuale, posizioni: posizioniCliente(c.id), obiettivi: obiettiviCliente(c.id),
                              eventi: eventiVitaCliente(c.id), analisi: dati.analisi[c.id], scheda: schedaLettera(attuale),
                              avvertenza: avvertenza, diProva: diProva, oggi: oggi)
    }

    /// true se l'avvertenza del film è ancora il segnaposto (avviso sotto i comandi).
    var avvertenzaFilmSegnaposto: Bool {
        ImpostazioniSala.avvertenza(dati.impostazioni.sala.avvertenzaFilm).segnaposto
    }

    /// Il video già esportato per questi dati (stessa impronta), se il suo Documento c'è ancora.
    func filmAggiornato(_ c: Cliente, dati d: DatiFilm) -> Documento? {
        guard let doc = ultimoFilm(clienteId: c.id), let s = cliente(c.id)?.prismaCliente, s.filmImpronta == d.impronta else {
            return nil
        }
        return doc
    }

    /// La data dell'ultimo video se i dati sono cambiati dopo (nil se non c'è un video o se è aggiornato).
    func filmCambiatoDal(_ c: Cliente, dati d: DatiFilm) -> Date? {
        guard ultimoFilm(clienteId: c.id) != nil, let s = cliente(c.id)?.prismaCliente,
              let impronta = s.filmImpronta, impronta != d.impronta else { return nil }
        return s.filmEsportatoIl ?? ultimoFilm(clienteId: c.id)?.importatoIl
    }

    /// Dopo l'esportazione: il video come Documento del cliente («Il film del piano · novembre 2026», tipo `.report`) e
    /// l'impronta dei dati in `Cliente.prismaCliente`. Restituisce l'id del Documento.
    @discardableResult
    func registraFilmEsportato(_ c: Cliente, dati d: DatiFilm, video: Data, oggi: Date = Date()) -> String? {
        guard let id = archiviaFile(video, estensione: "mp4", titolo: TestiFilm.titoloDocumento(oggi), tipo: .report, cliente: c.id) else {
            return nil
        }
        if let i = dati.clienti.firstIndex(where: { $0.id == c.id }) {
            var s = dati.clienti[i].prismaCliente ?? StatoPrismaCliente()
            s.filmImpronta = d.impronta
            s.filmEsportatoIl = Date(timeIntervalSinceReferenceDate: oggi.timeIntervalSinceReferenceDate.rounded(.down))
            dati.clienti[i].prismaCliente = s
        }
        return id
    }

    /// La copia da condividere del video nei Documenti, in `CartellaUscite` con il nome «Il piano di Giulia.mp4» (il foglio
    /// la toglie dopo l'esito; il Documento resta).
    func copiaFilmDaCondividere(_ doc: Documento, nome: String) -> URL? {
        guard let sorgente = urlDocumento(doc), FileManager.default.fileExists(atPath: sorgente.path),
              let video = try? Data(contentsOf: sorgente) else { return nil }
        return try? CartellaUscite.scrivi(video, nome: TestiFilm.nomeFile(nome))
    }

    /// La traccia nel dossier quando il video esce dal foglio di condivisione (mai il contenuto).
    func registraUscitaFilm(_ c: Cliente, dati d: DatiFilm, via: String, documentoId: String?) {
        registraUscita(clienteId: c.id, genere: .film, descrizione: TestiFilm.descrizioneUscita(d.durataTotale), via: via,
                       documentoId: documentoId, protetto: false)
    }
}

/// La memoria dei dati del film: `MotoreFilm.dati` prepara anche la linea della vita, non va rifatto a ogni disegno.
enum CacheFilm {
    nonisolated(unsafe) private static var memoria: [Int: DatiFilm?] = [:]
    private static let massimo = 8

    static func dati(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita], analisi: Analisi360?,
                     scheda: SchedaLettera?, avvertenza: String, diProva: Bool, oggi: Date) -> DatiFilm? {
        var h = Hasher()
        h.combine(cliente)
        h.combine(posizioni)
        h.combine(obiettivi)
        h.combine(eventi)
        h.combine(analisi != nil)
        if let a = analisi {
            h.combine(a.confermate)
            h.combine(a.previdenza.etaPensione)
            h.combine(a.previdenza.redditoDesiderato)
            h.combine(a.previdenza.pensionePubblica)
            h.combine(a.previdenza.rendimentoReale)
        }
        h.combine(scheda?.arrivoConPiano)
        h.combine(scheda?.obiettivo)
        h.combine(avvertenza)
        h.combine(diProva)
        h.combine(Calendar.current.startOfDay(for: oggi))
        let chiave = h.finalize()
        if let d = memoria[chiave] { return d }
        let d = MotoreFilm.dati(cliente: cliente, posizioni: posizioni, obiettivi: obiettivi, eventi: eventi, analisi: analisi,
                                scheda: scheda, firme: TestiFilm.firme(cliente: cliente), avvertenza: avvertenza, oggi: oggi,
                                diProva: diProva)
        if memoria.count >= massimo { memoria.removeAll() }
        memoria[chiave] = d
        return d
    }
}
