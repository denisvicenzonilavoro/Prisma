import Foundation

/// La scheda di adeguatezza nello stato di Prisma (giro 4, specifica 1): lettura e modifica della scheda,
/// esito calcolato a richiesta (una proposta sola, quando si apre il dettaglio o si preme un pulsante del PDF; il
/// pannello del dettaglio lo tiene in memoria con `esitoAdeguatezzaPannello`), consegne, firma ed elenco dei
/// documenti delle Impostazioni.
extension StatoShell {
    func schedaAdeguatezza(_ posizioneId: String) -> SchedaAdeguatezza? {
        dati.schedeAdeguatezza.first { $0.posizioneId == posizioneId }
    }

    /// Modifica la scheda (creandola se manca). Ignorata se è firmata. Imposta `aggiornataIl` al minuto.
    func modificaScheda(_ p: Posizione, _ modifica: (inout SchedaAdeguatezza) -> Void) {
        scriviScheda(p, ancheFirmata: false, modifica)
    }

    /// La scrittura vera: `ancheFirmata` serve solo a togliere la firma.
    private func scriviScheda(_ p: Posizione, ancheFirmata: Bool, _ modifica: (inout SchedaAdeguatezza) -> Void) {
        let adesso = Appuntamento.alMinuto(Date())
        if let i = dati.schedeAdeguatezza.firstIndex(where: { $0.posizioneId == p.id }) {
            let prima = dati.schedeAdeguatezza[i]
            guard ancheFirmata || !prima.firmata else { return }
            var s = prima
            modifica(&s)
            guard s != prima else { return }
            s.aggiornataIl = adesso
            dati.schedeAdeguatezza[i] = s
        } else {
            var s = SchedaAdeguatezza(posizioneId: p.id, clienteId: p.clienteId, creataIl: adesso)
            modifica(&s)
            s.aggiornataIl = adesso
            dati.schedeAdeguatezza.append(s)
        }
    }

    /// Tutto ciò che serve al motore, dai dati del cliente della proposta (nil se il cliente non c'è).
    func ingressoAdeguatezza(_ p: Posizione, oggi: Date = Date()) -> IngressoAdeguatezza? {
        guard let c = cliente(p.clienteId) else { return nil }
        let posizioni = posizioniCliente(p.clienteId)
        let analisi = analisi360(p.clienteId)
        // Per oggi i bisogni del cliente sono già in cache (`bisogniRilevati`, stessi ingressi; il motore guarda la data
        // solo per l'anno): il pannello della proposta non rifà il motore a ogni passata. Per un altro giorno si rifanno.
        let bisogni = Calendar.current.isDateInToday(oggi)
            ? bisogniRilevati(p.clienteId)
            : MotoreBisogni.rileva(cliente: c, posizioni: posizioni, analisi: analisi, oggi: oggi)
        return IngressoAdeguatezza(proposta: p, cliente: c, posizioni: posizioni, prodotti: dati.prodotti,
                                   obiettivi: obiettiviCliente(p.clienteId), bisogni: bisogni,
                                   protezione: analisi.protezione,
                                   ipotesiConfermate: analisiSalvata(p.clienteId) && analisi.confermate.contains(.protezione),
                                   scheda: schedaAdeguatezza(p.id), voci: dati.impostazioni.consegna.voci, oggi: oggi)
    }

    func esitoAdeguatezza(_ p: Posizione, oggi: Date = Date()) -> EsitoAdeguatezza? {
        ingressoAdeguatezza(p, oggi: oggi).map { MotoreAdeguatezza.calcola($0) }
    }

    /// L'esito per il pannello della proposta (PannelloAdeguatezza), in memoria per posizione e ora finché non cambiano i
    /// dati dei calcoli, il giorno o la modalità cliente (come ogni `ricavato`). La proposta, la scheda e l'elenco dei
    /// documenti si confrontano con quelli dell'ultimo esito (la scheda e l'elenco non sono dati dei calcoli): una
    /// spunta o una scelta rifanno subito i sette controlli, un corpo rifatto per altro (l'aspetto, un'altra scheda, il
    /// metodo aperto, un foglio) no.
    func esitoAdeguatezzaPannello(_ i: IngressoAdeguatezza) -> EsitoAdeguatezza {
        let memoria: MemoriaEsitoAdeguatezza = ricavato("adeguatezza|\(i.proposta.id)|\(DerivatiDati.ora(i.oggi))") {
            MemoriaEsitoAdeguatezza()
        }
        if let e = memoria.esito, memoria.proposta == i.proposta, memoria.scheda == i.scheda, memoria.voci == i.voci {
            return e
        }
        let e = MotoreAdeguatezza.calcola(i)
        memoria.proposta = i.proposta
        memoria.scheda = i.scheda
        memoria.voci = i.voci
        memoria.esito = e
        return e
    }

    /// I dati del PDF: controlli (registrati alla firma, se firmata), griglia dell'esperienza, bisogno e date.
    func paginaDatiAdeguatezza(_ p: Posizione) -> PaginaDatiAdeguatezza? {
        guard let c = cliente(p.clienteId), let esito = esitoAdeguatezza(p) else { return nil }
        let scheda = schedaAdeguatezza(p.id)
        let griglia = c.profilo.esperienzaProdotti
        let collegamento = esito.controllo(.bisogno)?.esito ?? "Non indicato"
        return PaginaDatiAdeguatezza(esito: esito, scheda: scheda, cliente: c.nome,
                                     esperienza: MotoreEsperienza.righe(griglia), capacita: griglia?.capacitaPerdite,
                                     esperienzaRilevata: griglia?.compilata == true, collegamento: collegamento,
                                     periodo: p.periodoRaccomandato ?? prodotto(p.prodottoId)?.periodoConsigliato,
                                     data: scheda?.firmataIl ?? Date())
    }

    func documentoAdeguatezza(_ p: Posizione) -> DocumentoStampabile? {
        paginaDatiAdeguatezza(p).map { DocumentoStampabile($0) }
    }

    /// Spunta o toglie la consegna di un documento (data al minuto). Un documento consegnato serve: si toglie
    /// dai non pertinenti.
    func segnaConsegna(_ p: Posizione, voce: String, consegnato: Bool) {
        let adesso = Appuntamento.alMinuto(Date())
        modificaScheda(p) { s in
            s.consegne.removeAll { $0.voceId == voce }
            if consegnato {
                s.consegne.append(ConsegnaDocumento(voceId: voce, consegnatoIl: adesso))
                s.nonPertinenti.removeAll { $0 == voce }
            }
        }
    }

    /// «Non serve per questa proposta»: toglie anche la consegna.
    func segnaDocumentoNonPertinente(_ p: Posizione, voce: String, nonPertinente: Bool) {
        modificaScheda(p) { s in
            s.nonPertinenti.removeAll { $0 == voce }
            if nonPertinente {
                s.nonPertinenti.append(voce)
                s.consegne.removeAll { $0.voceId == voce }
            }
        }
    }

    /// Segna la scheda come firmata: i colori e le frasi dei controlli di adesso restano registrati.
    func firmaScheda(_ p: Posizione) {
        let registrati: [EsitoRegistrato] = (esitoAdeguatezza(p)?.controlli ?? []).map {
            EsitoRegistrato(controllo: $0.tipo.rawValue, semaforo: $0.semaforo.rawValue, esito: $0.esito)
        }
        let adesso = Appuntamento.alMinuto(Date())
        modificaScheda(p) { s in
            s.firmataIl = adesso
            s.esitiAllaFirma = registrati
        }
    }

    func togliFirmaScheda(_ p: Posizione) {
        guard schedaAdeguatezza(p.id)?.firmata == true else { return }
        scriviScheda(p, ancheFirmata: true) { s in
            s.firmataIl = nil
            s.esitiAllaFirma = nil
        }
    }

    /// Torna all'elenco dei documenti di Prisma: le spunte già messe nelle schede restano.
    func ripristinaDocumentiConsegna() {
        dati.impostazioni.consegna = ImpostazioniConsegna()
    }
}

/// L'ultimo esito del pannello di una proposta, con la proposta, la scheda e l'elenco dei documenti da cui è nato
/// (vedi `StatoShell.esitoAdeguatezzaPannello`). Vive nei dati ricavati: si butta con loro.
final class MemoriaEsitoAdeguatezza {
    var proposta: Posizione?
    var scheda: SchedaAdeguatezza?
    var voci: [VoceDocumento] = []
    var esito: EsitoAdeguatezza?
}
