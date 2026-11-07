import Foundation

// MARK: - Studio › Parcelle e fatture nello stato (giro 2)
// Le parcelle dell'archivio (`DatiPrisma.parcelle`), i dati fiscali del consulente (`Impostazioni.studio.fatturazione`) e
// il file XML del tracciato FatturaPA. Prisma prepara SOLO il file: nessun invio al Sistema di Interscambio.
// Una parcella emessa non si cancella e non cambia righe, numero e voci fiscali: si segna pagata o si annulla.

extension StatoShell {
    /// Le parcelle dei clienti visibili (in modalità cliente solo le sue).
    var parcelle: [Parcella] { modoCliente.map { id in dati.parcelle.filter { $0.clienteId == id } } ?? dati.parcelle }

    func parcella(_ id: String) -> Parcella? { dati.parcelle.first { $0.id == id } }

    /// I dati fiscali del consulente (Impostazioni › Studio › Fatturazione).
    var datiFatturazione: DatiFatturazione { dati.impostazioni.studio.fatturazione }

    /// Modifica i dati fiscali del consulente (solo se cambiano davvero).
    func modificaDatiFatturazione(_ modifica: (inout DatiFatturazione) -> Void) {
        var f = dati.impostazioni.studio.fatturazione
        modifica(&f)
        guard f != dati.impostazioni.studio.fatturazione else { return }
        dati.impostazioni.studio.fatturazione = f
    }

    /// Modifica i dati per la fattura di un cliente (li crea se mancano; vuoti tornano nil).
    func modificaDatiFiscaliCliente(_ clienteId: String, _ modifica: (inout DatiFiscaliCliente) -> Void) {
        guard let i = dati.clienti.firstIndex(where: { $0.id == clienteId }) else { return }
        var f = dati.clienti[i].fiscale ?? DatiFiscaliCliente()
        modifica(&f)
        let nuovo: DatiFiscaliCliente? = f.vuoti ? nil : f
        guard nuovo != dati.clienti[i].fiscale else { return }
        dati.clienti[i].fiscale = nuovo
    }

    /// I totali dell'anno (oggi: il giorno di adesso) delle parcelle visibili.
    func totaliParcelle(anno: Int? = nil, oggi: Date = Date()) -> TotaliParcelle {
        MotoreParcelle.totali(parcelle, anno: anno ?? Calendar.current.component(.year, from: oggi), oggi: oggi)
    }

    /// Il numero che prenderebbe la prossima parcella emessa oggi (o alla data indicata).
    func prossimoNumeroParcella(data: Date = Date()) -> String {
        MotoreParcelle.prossimoNumero(dati.parcelle, anno: Calendar.current.component(.year, from: data),
                                      numerazione: datiFatturazione.numerazione)
    }

    /// Ciò che manca per il file XML di una parcella (vuoto = si può preparare).
    func mancantiFattura(_ id: String) -> [DatoMancante] {
        guard let p = parcella(id) else { return [DatoMancante(.parcella, "parcella", "la parcella")] }
        return MotoreFattura.mancanti(parcella: p, cliente: dati.clienti.first { $0.id == p.clienteId }, consulente: datiFatturazione)
    }

    /// Salva una parcella. Una bozza si salva com'è (senza numero); di una parcella già numerata restano numero, anno,
    /// data, righe e voci fiscali: cambiano solo le altre informazioni (scadenza, collegamenti, ricorrenza).
    func salvaParcella(_ p: Parcella) {
        guard !solaLettura else { return }
        if let i = dati.parcelle.firstIndex(where: { $0.id == p.id }) {
            let prima = dati.parcelle[i]
            var nuova = p
            if prima.stato.numerata {
                nuova.stato = prima.stato
                nuova.anno = prima.anno
                nuova.progressivo = prima.progressivo
                nuova.numero = prima.numero
                nuova.data = prima.data
                nuova.righe = prima.righe
                nuova.voci = prima.voci
                nuova.clienteId = prima.clienteId
                nuova.incassataIl = prima.incassataIl
                nuova.annullataIl = prima.annullataIl
                nuova.notaDiCredito = prima.notaDiCredito
                nuova.progressivoInvio = prima.progressivoInvio
                nuova.documenti = prima.documenti
            } else {
                nuova.stato = .bozza
                nuova.progressivo = nil
                nuova.numero = nil
                nuova.voci = nil
            }
            guard nuova != prima else { return }
            dati.parcelle[i] = nuova
        } else {
            var nuova = p
            nuova.stato = .bozza
            nuova.progressivo = nil
            nuova.numero = nil
            nuova.voci = nil
            dati.parcelle.append(nuova)
        }
    }

    /// Elimina una bozza (una parcella emessa non si elimina: si annulla).
    func eliminaBozzaParcella(_ id: String) {
        guard !solaLettura else { return }
        dati.parcelle.removeAll { $0.id == id && $0.stato == .bozza }
    }

    /// Emette una bozza alla data: prende il numero progressivo dell'anno e congela le voci fiscali (se il regime è
    /// completo). Restituisce la parcella emessa (nil se non è una bozza).
    @discardableResult
    func emettiParcella(_ id: String, data: Date = Posizione.oggiArrotondato) -> Parcella? {
        guard !solaLettura, let i = dati.parcelle.firstIndex(where: { $0.id == id }), dati.parcelle[i].stato == .bozza else { return nil }
        let e = MotoreParcelle.emessa(dati.parcelle[i], tra: dati.parcelle, data: data, numerazione: datiFatturazione.numerazione,
                                      regime: datiFatturazione.regime)
        dati.parcelle[i] = e
        return e
    }

    /// Segna incassata una parcella emessa.
    func segnaParcellaPagata(_ id: String, il data: Date = Posizione.oggiArrotondato) {
        guard !solaLettura, let i = dati.parcelle.firstIndex(where: { $0.id == id }), dati.parcelle[i].stato == .emessa else { return }
        dati.parcelle[i].stato = .pagata
        dati.parcelle[i].incassataIl = data
    }

    /// Torna da incassare (un incasso segnato per errore).
    func annullaIncassoParcella(_ id: String) {
        guard !solaLettura, let i = dati.parcelle.firstIndex(where: { $0.id == id }), dati.parcelle[i].stato == .pagata else { return }
        dati.parcelle[i].stato = .emessa
        dati.parcelle[i].incassataIl = nil
    }

    /// Annulla una parcella emessa o pagata, con il riferimento facoltativo della nota di credito. Il numero resta.
    func annullaParcella(_ id: String, notaDiCredito: String? = nil, il data: Date = Posizione.oggiArrotondato) {
        guard !solaLettura, let i = dati.parcelle.firstIndex(where: { $0.id == id }), dati.parcelle[i].stato.numerata,
              dati.parcelle[i].stato != .annullata else { return }
        let nota = notaDiCredito?.trimmingCharacters(in: .whitespacesAndNewlines)
        dati.parcelle[i].stato = .annullata
        dati.parcelle[i].annullataIl = data
        dati.parcelle[i].notaDiCredito = (nota ?? "").isEmpty ? nil : nota
    }

    /// Registra un file generato (PDF o XML) nella parcella.
    func aggiungiDocumentoParcella(_ id: String, _ d: DocumentoParcella) {
        guard !solaLettura, let i = dati.parcelle.firstIndex(where: { $0.id == id }) else { return }
        dati.parcelle[i].documenti.append(d)
    }

    /// Prepara il file XML della parcella: assegna il progressivo d'invio la prima volta (cresce nelle impostazioni e non
    /// si ripete), scrive il testo e lo registra tra i documenti della parcella. Solo il file: nessun invio allo SdI.
    /// Se manca un dato, nessun progressivo consumato e l'elenco dei mancanti.
    func preparaFatturaPA(_ id: String, adesso: Date = Posizione.oggiArrotondato) -> GeneratoreFatturaPA.Esito {
        guard let i = dati.parcelle.firstIndex(where: { $0.id == id }) else {
            return .mancano([DatoMancante(.parcella, "parcella", "la parcella")])
        }
        let p = dati.parcelle[i]
        let cliente = dati.clienti.first { $0.id == p.clienteId }
        let f = datiFatturazione
        let progressivo = p.progressivoInvio ?? MotoreParcelle.progressivoInvio(f.numerazione.ultimoProgressivoInvio + 1)
        let esito = GeneratoreFatturaPA.genera(parcella: p, cliente: cliente, consulente: f, progressivoInvio: progressivo)
        guard let file = esito.file, !solaLettura else { return esito }
        if p.progressivoInvio == nil {
            dati.impostazioni.studio.fatturazione.numerazione.ultimoProgressivoInvio += 1
            dati.parcelle[i].progressivoInvio = progressivo
        }
        dati.parcelle[i].documenti.append(DocumentoParcella(formato: .xml, nomeFile: nomeFileFatturaPA(file, clienteId: p.clienteId),
                                                            creatoIl: adesso))
        return esito
    }

    /// Il nome con cui si salva il file XML: per i clienti di prova comincia con «PROVA_» (non valido per lo SdI,
    /// specifica §3.6.4), per gli altri è quello del tracciato (IT + partita IVA + _ + progressivo).
    func nomeFileFatturaPA(_ file: GeneratoreFatturaPA.File, clienteId: String) -> String {
        Self.clientiDiProva.contains(clienteId) ? GeneratoreFatturaPA.prefissoProva + file.nome : file.nome
    }
}
