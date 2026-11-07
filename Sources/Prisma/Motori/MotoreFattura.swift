import Foundation

// MARK: - Studio › Parcelle e fatture: le voci fiscali della fattura (giro 2, specifica §3.5.3)
// Motore puro, senza SwiftUI. Calcola righe, imponibile, contributo previdenziale, IVA o natura, ritenuta, bollo, totale
// del documento e netto a pagare SOLO con i parametri del consulente (`RegimeFatturazione`, Impostazioni › Studio ›
// Fatturazione). Non sceglie nessuna regola fiscale: se un dato manca restituisce l'elenco dei dati mancanti
// (`DatoMancante`) e nessuna cifra. Gli importi si contano in centesimi interi, arrotondati al centesimo (metà per
// eccesso) riga per riga e nel riepilogo, come vuole il tracciato.
//
// Regole del conto (con i parametri dell'utente):
// - imponibile = somma delle righe; contributo = imponibile × aliquota della cassa;
// - base IVA (ImponibileImporto del riepilogo) = imponibile + contributo (il contributo segue l'IVA del documento);
// - IVA = base IVA × aliquota; con una natura non c'è IVA (imposta 0) e serve il riferimento normativo;
// - ritenuta = (imponibile × quota, o tutto l'imponibile, + il contributo se soggetto a ritenuta) × aliquota;
// - bollo: se «sì», dovuto sempre o, con una soglia, quando l'imponibile senza IVA (con una natura) la supera; entra nel
//   totale (e in una riga) solo se è a carico del cliente;
// - totale del documento = base IVA + IVA (+ bollo a carico del cliente); netto a pagare = totale − ritenuta.

/// Un dato che manca per preparare la fattura, con dove si inserisce.
struct DatoMancante: Hashable, Identifiable {
    enum Dove: String, CaseIterable {
        /// Impostazioni › Studio › Fatturazione.
        case consulente
        /// Il dossier del cliente.
        case cliente
        /// La parcella.
        case parcella
    }

    let dove: Dove
    /// Chiave stabile («consulente.partitaIVA», «regime.iva»…): per le prove e per portare al campo giusto.
    let codice: String
    /// Che cosa manca, in minuscolo («partita IVA», «regime fiscale (codice RF)»).
    let testo: String
    var id: String { codice }

    init(_ dove: Dove, _ codice: String, _ testo: String) {
        self.dove = dove
        self.codice = codice
        self.testo = testo
    }
}

/// Le voci fiscali di una fattura, calcolate con il regime del consulente e congelate all'emissione (`Parcella.voci`).
/// Gli importi sono in euro, già arrotondati al centesimo. Portano con sé i parametri usati, così il file XML di una
/// parcella emessa non cambia se poi cambia il regime.
struct VociFiscali: Codable, Hashable {
    /// Una riga del documento (DettaglioLinee).
    struct Linea: Codable, Hashable {
        let numero: Int
        let descrizione: String
        let importo: Double
        /// 0 con la natura.
        let aliquotaIVA: Double
        let natura: NaturaIVA?
        /// La riga è soggetta a ritenuta.
        let ritenuta: Bool
        /// È la riga del bollo addebitato al cliente.
        let bollo: Bool
    }

    /// Un riepilogo per aliquota o natura (DatiRiepilogo).
    struct Riepilogo: Codable, Hashable {
        let aliquotaIVA: Double
        let natura: NaturaIVA?
        let imponibile: Double
        let imposta: Double
        let riferimentoNormativo: String?
        let esigibilita: EsigibilitaIVA?
    }

    let regimeFiscale: CodiceRegimeFiscale
    let linee: [Linea]
    /// Somma delle righe della parcella (senza il bollo).
    let imponibile: Double
    /// Contributo previdenziale (cassa), se si applica.
    let contributo: Double?
    let tipoCassa: TipoCassa?
    let aliquotaCassa: Double?
    let contributoSoggettoARitenuta: Bool
    /// Imponibile ai fini IVA: imponibile più contributo.
    let baseIVA: Double
    let aliquotaIVA: Double?
    let natura: NaturaIVA?
    let riferimentoNormativo: String?
    let esigibilitaIVA: EsigibilitaIVA?
    /// nil con la natura (operazione senza IVA).
    let iva: Double?
    let ritenuta: Double?
    let tipoRitenuta: TipoRitenuta?
    let aliquotaRitenuta: Double?
    let causaleRitenuta: String?
    /// Il bollo, se dovuto.
    let bollo: Double?
    let bolloACaricoCliente: Bool
    let riepiloghi: [Riepilogo]
    let totaleDocumento: Double
    /// Totale del documento meno la ritenuta.
    let nettoAPagare: Double
    let frasePiede: String
}

enum MotoreFattura {
    /// L'esito del calcolo: le voci, oppure l'elenco di ciò che manca (nessuna cifra inventata).
    enum Esito: Equatable {
        case calcolata(VociFiscali)
        case mancano([DatoMancante])

        var voci: VociFiscali? {
            if case .calcolata(let v) = self { return v }
            return nil
        }

        var mancanti: [DatoMancante] {
            if case .mancano(let m) = self { return m }
            return []
        }
    }

    /// La descrizione della riga del bollo addebitato al cliente.
    static let descrizioneRigaBollo = "Imposta di bollo"

    // MARK: - Centesimi

    /// Euro → centesimi, arrotondati al centesimo (metà per eccesso, lontano dallo zero).
    static func centesimi(_ euro: Double) -> Int {
        guard euro.isFinite else { return 0 }
        let x = euro * 100
        // Il piccolo margine corregge i numeri come 1,005 che in binario sono appena sotto la metà
        return Int((x + (x >= 0 ? 1e-7 : -1e-7)).rounded(.toNearestOrAwayFromZero))
    }

    /// Centesimi → euro.
    static func euro(_ c: Int) -> Double { Double(c) / 100 }

    /// La percentuale di un importo in centesimi, arrotondata al centesimo.
    static func percentuale(_ base: Int, _ aliquota: Double) -> Int {
        let x = Double(base) * aliquota / 100
        guard x.isFinite else { return 0 }
        return Int((x + (x >= 0 ? 1e-7 : -1e-7)).rounded(.toNearestOrAwayFromZero))
    }

    /// Somma delle righe in centesimi (ognuna arrotondata al centesimo).
    static func imponibileCentesimi(_ righe: [RigaParcella]) -> Int {
        righe.reduce(0) { $0 + centesimi($1.importo) }
    }

    // MARK: - Dati mancanti

    /// Ciò che manca nel regime per calcolare le voci fiscali.
    static func mancantiRegime(_ r: RegimeFatturazione) -> [DatoMancante] {
        var m: [DatoMancante] = []
        func manca(_ codice: String, _ testo: String) { m.append(DatoMancante(.consulente, codice, testo)) }
        if r.regimeFiscale == nil { manca("regime.codice", "regime fiscale (codice RF)") }
        switch (r.aliquotaIVA, r.natura) {
        case (nil, nil):
            manca("regime.iva", "IVA: l'aliquota oppure la natura dell'operazione")
        case (.some, .some):
            manca("regime.iva", "IVA: l'aliquota oppure la natura, non tutte e due")
        case (.some(let a), nil):
            if a <= 0 { manca("regime.iva", "IVA: con l'aliquota 0 serve la natura dell'operazione") }
        case (nil, .some):
            if r.riferimentoNormativo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                manca("regime.riferimentoNormativo", "riferimento normativo della natura")
            }
        }
        switch r.applicaCassa {
        case nil: manca("regime.cassa", "contributo previdenziale: si applica o no")
        case true?:
            if r.cassa.tipo == nil { manca("regime.cassa.tipo", "tipo di cassa previdenziale (TC)") }
            if r.cassa.aliquota == nil { manca("regime.cassa.aliquota", "aliquota del contributo previdenziale") }
            if r.applicaRitenuta == true && r.cassa.soggettoARitenuta == nil {
                manca("regime.cassa.ritenuta", "contributo previdenziale soggetto a ritenuta: sì o no")
            }
        case false?: break
        }
        switch r.applicaRitenuta {
        case nil: manca("regime.ritenuta", "ritenuta d'acconto: si applica o no")
        case true?:
            if r.ritenuta.tipo == nil { manca("regime.ritenuta.tipo", "tipo di ritenuta (RT)") }
            if r.ritenuta.aliquota == nil { manca("regime.ritenuta.aliquota", "aliquota della ritenuta") }
            if !causaleValida(r.ritenuta.causale) { manca("regime.ritenuta.causale", "causale di pagamento della ritenuta (codice del modello CU)") }
            if let q = r.ritenuta.quotaImponibile, q <= 0 || q > 100 {
                manca("regime.ritenuta.quota", "quota dell'imponibile soggetta a ritenuta (tra 0 e 100%)")
            }
        case false?: break
        }
        switch r.applicaBollo {
        case nil: manca("regime.bollo", "imposta di bollo: sì o no")
        case true?:
            if (r.bollo.importo ?? 0) <= 0 { manca("regime.bollo.importo", "importo del bollo") }
            switch r.bollo.aCaricoCliente {
            case nil: manca("regime.bollo.carico", "bollo a carico del cliente: sì o no")
            case true?:
                if let n = r.bollo.naturaRiga {
                    if n != r.natura && r.bollo.riferimentoNormativoRiga.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        manca("regime.bollo.riferimento", "riferimento normativo della riga del bollo")
                    }
                } else {
                    manca("regime.bollo.natura", "natura della riga del bollo addebitato al cliente")
                }
            case false?: break
            }
        case false?: break
        }
        if let a = r.aliquotaIVA, a > 100 { manca("regime.iva", "IVA: aliquota oltre il 100%") }
        if let a = r.cassa.aliquota, r.applicaCassa == true, a > 100 { manca("regime.cassa.aliquota", "aliquota del contributo oltre il 100%") }
        if let a = r.ritenuta.aliquota, r.applicaRitenuta == true, a > 100 { manca("regime.ritenuta.aliquota", "aliquota della ritenuta oltre il 100%") }
        return m
    }

    /// Ciò che manca nei dati del consulente (anagrafica, sede, regime, pagamento, trasmittente) per il file XML.
    static func mancantiConsulente(_ f: DatiFatturazione) -> [DatoMancante] {
        var m: [DatoMancante] = []
        func manca(_ codice: String, _ testo: String) { m.append(DatoMancante(.consulente, codice, testo)) }
        let conNome = !vuoto(f.nome) && !vuoto(f.cognome)
        if !conNome && vuoto(f.denominazione) { manca("consulente.anagrafica", "nome e cognome (o denominazione)") }
        if vuoto(f.partitaIVA) {
            manca("consulente.partitaIVA", "partita IVA")
        } else if !partitaIVAValida(f.partitaIVA) {
            manca("consulente.partitaIVA", "partita IVA (11 cifre con la cifra di controllo)")
        }
        if vuoto(f.codiceFiscale) {
            manca("consulente.codiceFiscale", "codice fiscale")
        } else if !codiceFiscaleValido(f.codiceFiscale) {
            manca("consulente.codiceFiscale", "codice fiscale (16 caratteri, o 11 cifre)")
        }
        m += mancantiSede(f.sede, dove: .consulente, prefisso: "consulente.sede", di: "")
        m += mancantiRegime(f.regime)
        m += mancantiPagamento(f)
        switch f.trasmittente.chi {
        case nil: manca("consulente.trasmittente", "chi carica il file allo SdI (trasmittente)")
        case .intermediario?:
            if !codiceFiscaleValido(f.trasmittente.codiceFiscaleIntermediario) {
                manca("consulente.trasmittente.cf", "codice fiscale dell'intermediario che carica il file")
            }
        case .consulente?: break
        }
        return m
    }

    /// Ciò che manca per i dati di pagamento (DatiPagamento).
    static func mancantiPagamento(_ f: DatiFatturazione) -> [DatoMancante] {
        var m: [DatoMancante] = []
        func manca(_ codice: String, _ testo: String) { m.append(DatoMancante(.consulente, codice, testo)) }
        if f.condizioniPagamento == nil { manca("consulente.condizioni", "condizioni di pagamento (TP)") }
        if let mp = f.modalitaPagamento {
            if mp.richiedeIBAN && !ibanValido(f.iban) { manca("consulente.iban", "IBAN") }
        } else {
            manca("consulente.modalita", "modalità di pagamento (MP)")
        }
        if !vuoto(f.iban) && !ibanValido(f.iban) && !m.contains(where: { $0.codice == "consulente.iban" }) {
            manca("consulente.iban", "IBAN (non valido)")
        }
        return m
    }

    /// Ciò che manca nel dossier del cliente per la fattura.
    static func mancantiCliente(_ c: Cliente) -> [DatoMancante] {
        let f = c.fiscale ?? DatiFiscaliCliente()
        var m: [DatoMancante] = []
        func manca(_ codice: String, _ testo: String) { m.append(DatoMancante(.cliente, codice, testo)) }
        if vuoto(f.denominazione) && (vuoto(f.nome) || vuoto(f.cognome)) {
            manca("cliente.anagrafica", "nome e cognome per la fattura (o denominazione)")
        }
        let cfScritto = !vuoto(c.codiceFiscale)
        let pivaScritta = !vuoto(f.partitaIVA)
        if !cfScritto && !pivaScritta {
            manca("cliente.codiceFiscale", "codice fiscale (o partita IVA)")
        }
        if cfScritto && !codiceFiscaleValido(c.codiceFiscale) {
            manca("cliente.codiceFiscale", "codice fiscale (16 caratteri, o 11 cifre)")
        }
        if pivaScritta && !partitaIVAValida(f.partitaIVA) {
            manca("cliente.partitaIVA", "partita IVA (11 cifre con la cifra di controllo)")
        }
        m += mancantiSede(f.sede, dove: .cliente, prefisso: "cliente.sede", di: " del cliente")
        let codice = normalizzato(f.codiceDestinatario)
        if codice.isEmpty {
            if !emailValida(f.pec) {
                manca("cliente.codiceDestinatario", "codice destinatario o PEC (0000000 per i privati senza codice)")
            }
        } else if !codiceDestinatarioValido(codice) {
            manca("cliente.codiceDestinatario", "codice destinatario (7 caratteri)")
        }
        if !vuoto(f.pec) && !emailValida(f.pec) { manca("cliente.pec", "PEC del cliente (non valida)") }
        return m
    }

    /// Ciò che manca nella parcella per farne una fattura.
    static func mancantiParcella(_ p: Parcella) -> [DatoMancante] {
        var m: [DatoMancante] = []
        func manca(_ codice: String, _ testo: String) { m.append(DatoMancante(.parcella, codice, testo)) }
        if p.righe.isEmpty {
            manca("parcella.righe", "almeno una riga")
        } else {
            if p.righe.contains(where: { vuoto($0.descrizione) }) { manca("parcella.descrizioni", "descrizione di ogni riga") }
            if imponibileCentesimi(p.righe) <= 0 { manca("parcella.importo", "importo della parcella") }
        }
        if !p.stato.numerata || (p.numero ?? "").isEmpty {
            manca("parcella.numero", "numero (la bozza si numera all'emissione)")
        } else if !numeroValido(p.numero ?? "") {
            manca("parcella.numero", "numero (fino a 20 caratteri, con almeno una cifra)")
        }
        if p.stato == .annullata { manca("parcella.annullata", "la parcella è annullata") }
        return m
    }

    /// Tutto ciò che manca per il file XML di una parcella. Con le voci già congelate il regime di oggi non conta.
    static func mancanti(parcella p: Parcella, cliente c: Cliente?, consulente f: DatiFatturazione) -> [DatoMancante] {
        var m = mancantiConsulente(f)
        if p.voci != nil { m.removeAll { $0.codice.hasPrefix("regime.") } }
        if let c {
            m += mancantiCliente(c)
        } else {
            m.append(DatoMancante(.cliente, "cliente", "il cliente della parcella"))
        }
        m += mancantiParcella(p)
        return m
    }

    private static func mancantiSede(_ s: SedeFiscale, dove: DatoMancante.Dove, prefisso: String, di: String) -> [DatoMancante] {
        var m: [DatoMancante] = []
        func manca(_ codice: String, _ testo: String) { m.append(DatoMancante(dove, "\(prefisso).\(codice)", testo + di)) }
        if vuoto(s.indirizzo) { manca("indirizzo", "indirizzo") }
        if !capValido(s.cap) { manca("cap", "CAP (5 cifre)") }
        if vuoto(s.comune) { manca("comune", "comune") }
        let nazione = normalizzato(s.nazione)
        if !siglaValida(nazione) { manca("nazione", "nazione (sigla di 2 lettere)") }
        if nazione == "IT" && !siglaValida(normalizzato(s.provincia)) { manca("provincia", "provincia (sigla di 2 lettere)") }
        return m
    }

    // MARK: - Calcolo

    /// Le voci di una parcella: quelle congelate all'emissione, altrimenti calcolate con il regime dato.
    static func voci(_ p: Parcella, regime: RegimeFatturazione) -> Esito {
        if let v = p.voci { return .calcolata(v) }
        return calcola(righe: p.righe, regime: regime)
    }

    /// Le voci fiscali delle righe con il regime del consulente. Senza un dato del regime: l'elenco dei mancanti.
    static func calcola(righe: [RigaParcella], regime r: RegimeFatturazione) -> Esito {
        var mancanti = mancantiRegime(r)
        if righe.isEmpty { mancanti.append(DatoMancante(.parcella, "parcella.righe", "almeno una riga")) }
        guard mancanti.isEmpty, let codiceRegime = r.regimeFiscale else { return .mancano(mancanti) }

        let aliquotaIVA = r.natura == nil ? r.aliquotaIVA : nil
        let aliquotaRighe = aliquotaIVA ?? 0
        let conRitenuta = r.applicaRitenuta == true
        let riferimento = r.natura == nil ? nil : r.riferimentoNormativo.trimmingCharacters(in: .whitespacesAndNewlines)
        var linee: [VociFiscali.Linea] = []
        var imponibile = 0
        for (i, riga) in righe.enumerated() {
            let c = centesimi(riga.importo)
            imponibile += c
            linee.append(VociFiscali.Linea(numero: i + 1, descrizione: riga.descrizione, importo: euro(c), aliquotaIVA: aliquotaRighe,
                                           natura: r.natura, ritenuta: conRitenuta, bollo: false))
        }
        // Contributo previdenziale (cassa)
        let contributo: Int? = r.applicaCassa == true ? percentuale(imponibile, r.cassa.aliquota ?? 0) : nil
        let baseIVA = imponibile + (contributo ?? 0)
        let iva: Int? = aliquotaIVA.map { percentuale(baseIVA, $0) }
        // Ritenuta
        let contributoARitenuta = conRitenuta && contributo != nil && r.cassa.soggettoARitenuta == true
        var ritenuta: Int?
        if conRitenuta {
            let quota = r.ritenuta.quotaImponibile.map { percentuale(imponibile, $0) } ?? imponibile
            let base = quota + (contributoARitenuta ? (contributo ?? 0) : 0)
            ritenuta = percentuale(base, r.ritenuta.aliquota ?? 0)
        }
        // Bollo
        var bollo: Int?
        if r.applicaBollo == true {
            let importo = centesimi(r.bollo.importo ?? 0)
            let senzaIVA = r.natura != nil ? baseIVA : 0
            let dovuto = r.bollo.soglia.map { senzaIVA > centesimi($0) } ?? true
            if dovuto && importo > 0 { bollo = importo }
        }
        let bolloAlCliente = bollo != nil && r.bollo.aCaricoCliente == true
        // Riepiloghi: uno per aliquota o natura
        var riepiloghi = [VociFiscali.Riepilogo(aliquotaIVA: aliquotaRighe, natura: r.natura, imponibile: euro(baseIVA),
                                                imposta: euro(iva ?? 0), riferimentoNormativo: riferimento,
                                                esigibilita: aliquotaIVA == nil ? nil : r.esigibilitaIVA)]
        if bolloAlCliente, let b = bollo, let naturaBollo = r.bollo.naturaRiga {
            linee.append(VociFiscali.Linea(numero: linee.count + 1, descrizione: descrizioneRigaBollo, importo: euro(b),
                                           aliquotaIVA: 0, natura: naturaBollo, ritenuta: false, bollo: true))
            if naturaBollo == r.natura {
                let primo = riepiloghi[0]
                riepiloghi[0] = VociFiscali.Riepilogo(aliquotaIVA: primo.aliquotaIVA, natura: primo.natura,
                                                      imponibile: euro(baseIVA + b), imposta: primo.imposta,
                                                      riferimentoNormativo: primo.riferimentoNormativo, esigibilita: primo.esigibilita)
            } else {
                let rif = r.bollo.riferimentoNormativoRiga.trimmingCharacters(in: .whitespacesAndNewlines)
                riepiloghi.append(VociFiscali.Riepilogo(aliquotaIVA: 0, natura: naturaBollo, imponibile: euro(b), imposta: 0,
                                                        riferimentoNormativo: rif, esigibilita: nil))
            }
        }
        let totale = baseIVA + (iva ?? 0) + (bolloAlCliente ? (bollo ?? 0) : 0)
        let netto = totale - (ritenuta ?? 0)
        let causale = normalizzato(r.ritenuta.causale)
        return .calcolata(VociFiscali(
            regimeFiscale: codiceRegime, linee: linee, imponibile: euro(imponibile), contributo: contributo.map(euro),
            tipoCassa: contributo == nil ? nil : r.cassa.tipo, aliquotaCassa: contributo == nil ? nil : r.cassa.aliquota,
            contributoSoggettoARitenuta: contributoARitenuta, baseIVA: euro(baseIVA), aliquotaIVA: aliquotaIVA,
            natura: r.natura, riferimentoNormativo: riferimento, esigibilitaIVA: aliquotaIVA == nil ? nil : r.esigibilitaIVA,
            iva: iva.map(euro), ritenuta: ritenuta.map(euro), tipoRitenuta: conRitenuta ? r.ritenuta.tipo : nil,
            aliquotaRitenuta: conRitenuta ? r.ritenuta.aliquota : nil, causaleRitenuta: conRitenuta ? causale : nil,
            bollo: bollo.map(euro), bolloACaricoCliente: bolloAlCliente, riepiloghi: riepiloghi,
            totaleDocumento: euro(totale), nettoAPagare: euro(netto),
            frasePiede: r.frasePiede.trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    // MARK: - Controlli formali

    /// Senza spazi e in maiuscolo.
    static func normalizzato(_ s: String) -> String {
        s.uppercased().filter { !$0.isWhitespace }
    }

    private static func vuoto(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private static func soloCifre(_ s: String) -> Bool { !s.isEmpty && s.allSatisfy { $0.isASCII && $0.isNumber } }

    private static func alfanumerico(_ s: String) -> Bool {
        !s.isEmpty && s.allSatisfy { $0.isASCII && ($0.isNumber || ($0.isLetter && $0.isUppercase)) }
    }

    /// Partita IVA italiana: 11 cifre con la cifra di controllo.
    static func partitaIVAValida(_ s: String) -> Bool {
        let p = normalizzato(s)
        guard p.count == 11, soloCifre(p) else { return false }
        let cifre = p.compactMap { $0.wholeNumberValue }
        guard cifre.count == 11 else { return false }
        var somma = 0
        for i in 0..<10 {
            if i % 2 == 0 {
                somma += cifre[i]
            } else {
                let d = cifre[i] * 2
                somma += d > 9 ? d - 9 : d
            }
        }
        return (10 - somma % 10) % 10 == cifre[10]
    }

    /// Codice fiscale: 16 caratteri alfanumerici (persona fisica) o 11 cifre (partita IVA di una società).
    static func codiceFiscaleValido(_ s: String) -> Bool {
        let c = normalizzato(s)
        if c.count == 11 { return partitaIVAValida(c) }
        return c.count == 16 && alfanumerico(c)
    }

    static func capValido(_ s: String) -> Bool {
        let c = normalizzato(s)
        return c.count == 5 && soloCifre(c)
    }

    /// Sigla di 2 lettere (provincia, nazione).
    static func siglaValida(_ s: String) -> Bool {
        let c = normalizzato(s)
        return c.count == 2 && c.allSatisfy { $0.isASCII && $0.isLetter }
    }

    /// Codice destinatario per le fatture tra privati: 7 caratteri alfanumerici.
    static func codiceDestinatarioValido(_ s: String) -> Bool {
        let c = normalizzato(s)
        return c.count == 7 && alfanumerico(c)
    }

    /// Le causali di pagamento ammesse dal tracciato 1.2.2 (CausalePagamentoType, codici del modello CU).
    static let causaliPagamento: [String] = ["A", "B", "C", "D", "E", "G", "H", "I", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
                                             "U", "V", "W", "X", "Y", "Z", "L1", "M1", "M2", "O1", "V1", "ZO"]

    /// Una causale di pagamento tra quelle del tracciato.
    static func causaleValida(_ s: String) -> Bool {
        causaliPagamento.contains(normalizzato(s))
    }

    /// Un indirizzo email (o PEC) plausibile.
    static func emailValida(_ s: String) -> Bool {
        let e = s.trimmingCharacters(in: .whitespacesAndNewlines)
        // Il tracciato vuole almeno 7 caratteri ASCII (EmailContattiType) e nessuno spazio
        guard e.count >= 7, e.count <= 256, e.allSatisfy({ $0.isASCII && !$0.isWhitespace }),
              let chiocciola = e.firstIndex(of: "@") else { return false }
        let dominio = e[e.index(after: chiocciola)...]
        return chiocciola != e.startIndex && dominio.contains(".") && !dominio.hasPrefix(".") && !dominio.hasSuffix(".")
    }

    /// IBAN: 2 lettere, 2 cifre, 11-30 caratteri, con il controllo modulo 97.
    static func ibanValido(_ s: String) -> Bool {
        let i = normalizzato(s)
        guard i.count >= 15, i.count <= 34, alfanumerico(i) else { return false }
        let caratteri = Array(i)
        guard caratteri[0].isLetter, caratteri[1].isLetter, caratteri[2].isNumber, caratteri[3].isNumber else { return false }
        let riordinato = caratteri[4...] + caratteri[0..<4]
        var resto = 0
        for ch in riordinato {
            if let d = ch.wholeNumberValue {
                resto = (resto * 10 + d) % 97
            } else if let v = ch.asciiValue {
                let n = Int(v) - 55   // A = 10 … Z = 35
                resto = (resto * 100 + n) % 97
            }
        }
        return resto == 1
    }

    /// Il numero della fattura: fino a 20 caratteri ASCII stampabili, con almeno una cifra.
    static func numeroValido(_ s: String) -> Bool {
        (1...20).contains(s.count) && s.allSatisfy { $0.isASCII && !$0.isNewline }
            && s.contains(where: { $0.isNumber })
    }
}
