import Foundation

// MARK: - Studio › Parcelle e fatture: il file XML del tracciato FatturaPA (giro 2, specifica §3.5.3 e §3.6.3)
// Scrive il testo XML della fattura tra privati, formato FPR12 (schema 1.2.2), namespace
// http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2, codifica UTF-8, senza firma. Prisma prepara SOLO il
// file: non lo invia al Sistema di Interscambio (il consulente lo carica sul portale o lo dà al commercialista).
// Testo scritto a mano (niente XMLDocument, che c'è solo sul Mac): escape di & < > " ', caratteri fuori dal set latino del
// tracciato sostituiti, importi con il punto e 2 decimali, date aaaa-mm-gg. Nome del file: IT<partita IVA>_<progressivo
// di 5 caratteri>.xml. Se manca un dato, nessun file: l'elenco dei dati mancanti (`MotoreFattura.mancanti`).

enum GeneratoreFatturaPA {
    /// Il file pronto: nome e testo XML.
    struct File: Equatable {
        let nome: String
        let xml: String
        var dati: Data { Data(xml.utf8) }
    }

    enum Esito: Equatable {
        case pronto(File)
        case mancano([DatoMancante])

        var file: File? {
            if case .pronto(let f) = self { return f }
            return nil
        }

        var mancanti: [DatoMancante] {
            if case .mancano(let m) = self { return m }
            return []
        }
    }

    static let namespace = "http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2"
    static let formato = "FPR12"
    static let tipoDocumento = "TD01"
    static let divisa = "EUR"
    /// Il codice destinatario dei privati senza codice (con la PEC, o da consultare nell'area riservata).
    static let codiceSenzaDestinatario = "0000000"
    /// Il prefisso del nome dei file dei clienti di prova: non valgono per lo SdI (specifica §3.6.4).
    static let prefissoProva = "PROVA_"

    /// Il nome del file per lo SdI: IT + partita IVA + _ + progressivo + .xml.
    static func nomeFile(partitaIVA: String, progressivo: String) -> String {
        "IT\(MotoreFattura.normalizzato(partitaIVA))_\(progressivo).xml"
    }

    /// Il file XML della parcella. `progressivoInvio`: i 5 caratteri del nome (`MotoreParcelle.progressivoInvio`).
    static func genera(parcella p: Parcella, cliente c: Cliente?, consulente f: DatiFatturazione,
                       progressivoInvio: String, cal: Calendar = .current) -> Esito {
        var mancanti = MotoreFattura.mancanti(parcella: p, cliente: c, consulente: f)
        let progressivo = progressivoInvio.trimmingCharacters(in: .whitespacesAndNewlines)
        if !(1...10).contains(progressivo.count) || !progressivo.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) {
            mancanti.append(DatoMancante(.parcella, "parcella.progressivoInvio", "progressivo d'invio del file"))
        }
        let voci = MotoreFattura.voci(p, regime: f.regime)
        if case .mancano(let altri) = voci {
            for a in altri where !mancanti.contains(a) { mancanti.append(a) }
        }
        guard mancanti.isEmpty, let c, let v = voci.voci, let numero = p.numero else {
            return .mancano(mancanti)
        }
        let fc = c.fiscale ?? DatiFiscaliCliente()
        var x = ScrittoreFatturaXML()
        x.riga("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        x.riga("<p:FatturaElettronica versione=\"\(formato)\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" "
               + "xmlns:p=\"\(namespace)\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
               + "xsi:schemaLocation=\"\(namespace) http://www.fatturapa.gov.it/export/fatturazione/sdi/fatturapa/v1.2/Schema_del_file_xml_FatturaPA_versione_1.2.xsd\">")
        x.livello = 1

        // 1 · FatturaElettronicaHeader
        x.apri("FatturaElettronicaHeader")
        x.apri("DatiTrasmissione")
        x.apri("IdTrasmittente")
        x.elemento("IdPaese", "IT")
        let idTrasmittente = f.trasmittente.chi == .intermediario ? f.trasmittente.codiceFiscaleIntermediario : f.codiceFiscale
        x.elemento("IdCodice", MotoreFattura.normalizzato(idTrasmittente))
        x.chiudi("IdTrasmittente")
        x.elemento("ProgressivoInvio", progressivo)
        x.elemento("FormatoTrasmissione", formato)
        let codice = MotoreFattura.normalizzato(fc.codiceDestinatario)
        x.elemento("CodiceDestinatario", codice.isEmpty ? codiceSenzaDestinatario : codice)
        let pec = fc.pec.trimmingCharacters(in: .whitespacesAndNewlines)
        if (codice.isEmpty || codice == codiceSenzaDestinatario) && MotoreFattura.emailValida(pec) {
            x.elemento("PECDestinatario", testoLatino(pec, massimo: 256))
        }
        x.chiudi("DatiTrasmissione")

        x.apri("CedentePrestatore")
        x.apri("DatiAnagrafici")
        x.apri("IdFiscaleIVA")
        x.elemento("IdPaese", "IT")
        x.elemento("IdCodice", MotoreFattura.normalizzato(f.partitaIVA))
        x.chiudi("IdFiscaleIVA")
        x.elemento("CodiceFiscale", MotoreFattura.normalizzato(f.codiceFiscale))
        anagrafica(&x, nome: f.nome, cognome: f.cognome, denominazione: f.denominazione)
        x.elemento("RegimeFiscale", v.regimeFiscale.codice)
        x.chiudi("DatiAnagrafici")
        sede(&x, f.sede)
        let telefono = f.telefono.trimmingCharacters(in: .whitespacesAndNewlines)
        let telefonoValido = (5...12).contains(telefono.count) && telefono.allSatisfy { $0.isASCII }
        let email = f.email.trimmingCharacters(in: .whitespacesAndNewlines)
        if telefonoValido || MotoreFattura.emailValida(email) {
            x.apri("Contatti")
            if telefonoValido { x.elemento("Telefono", telefono) }
            if MotoreFattura.emailValida(email) { x.elemento("Email", testoLatino(email, massimo: 256)) }
            x.chiudi("Contatti")
        }
        x.chiudi("CedentePrestatore")

        x.apri("CessionarioCommittente")
        x.apri("DatiAnagrafici")
        if MotoreFattura.partitaIVAValida(fc.partitaIVA) {
            x.apri("IdFiscaleIVA")
            x.elemento("IdPaese", "IT")
            x.elemento("IdCodice", MotoreFattura.normalizzato(fc.partitaIVA))
            x.chiudi("IdFiscaleIVA")
        }
        if MotoreFattura.codiceFiscaleValido(c.codiceFiscale) {
            x.elemento("CodiceFiscale", MotoreFattura.normalizzato(c.codiceFiscale))
        }
        anagrafica(&x, nome: fc.nome, cognome: fc.cognome, denominazione: fc.denominazione)
        x.chiudi("DatiAnagrafici")
        sede(&x, fc.sede)
        x.chiudi("CessionarioCommittente")
        x.chiudi("FatturaElettronicaHeader")

        // 2 · FatturaElettronicaBody
        x.apri("FatturaElettronicaBody")
        x.apri("DatiGenerali")
        x.apri("DatiGeneraliDocumento")
        x.elemento("TipoDocumento", tipoDocumento)
        x.elemento("Divisa", divisa)
        x.elemento("Data", data(p.data, cal: cal))
        x.elemento("Numero", testoBase(numero, massimo: 20))
        if let r = v.ritenuta, let tipo = v.tipoRitenuta, let aliquota = v.aliquotaRitenuta, let causale = v.causaleRitenuta {
            x.apri("DatiRitenuta")
            x.elemento("TipoRitenuta", tipo.codice)
            x.elemento("ImportoRitenuta", importo(r))
            x.elemento("AliquotaRitenuta", aliquotaTesto(aliquota))
            x.elemento("CausalePagamento", causale)
            x.chiudi("DatiRitenuta")
        }
        if let b = v.bollo {
            x.apri("DatiBollo")
            x.elemento("BolloVirtuale", "SI")
            x.elemento("ImportoBollo", importo(b))
            x.chiudi("DatiBollo")
        }
        if let contributo = v.contributo, let tipo = v.tipoCassa, let aliquota = v.aliquotaCassa {
            x.apri("DatiCassaPrevidenziale")
            x.elemento("TipoCassa", tipo.codice)
            x.elemento("AlCassa", aliquotaTesto(aliquota))
            x.elemento("ImportoContributoCassa", importo(contributo))
            x.elemento("ImponibileCassa", importo(v.imponibile))
            x.elemento("AliquotaIVA", aliquotaTesto(v.aliquotaIVA ?? 0))
            if v.contributoSoggettoARitenuta { x.elemento("Ritenuta", "SI") }
            if let n = v.natura { x.elemento("Natura", n.codice) }
            x.chiudi("DatiCassaPrevidenziale")
        }
        x.elemento("ImportoTotaleDocumento", importo(v.totaleDocumento))
        for parte in pezzi(testoLatino(p.descrizione, massimo: 1_000), lunghezza: 200) {
            x.elemento("Causale", parte)
        }
        x.chiudi("DatiGeneraliDocumento")
        x.chiudi("DatiGenerali")

        x.apri("DatiBeniServizi")
        for l in v.linee {
            x.apri("DettaglioLinee")
            x.elemento("NumeroLinea", String(l.numero))
            x.elemento("Descrizione", testoLatino(l.descrizione, massimo: 1_000))
            x.elemento("PrezzoUnitario", importo(l.importo))
            x.elemento("PrezzoTotale", importo(l.importo))
            x.elemento("AliquotaIVA", aliquotaTesto(l.aliquotaIVA))
            if l.ritenuta { x.elemento("Ritenuta", "SI") }
            if let n = l.natura { x.elemento("Natura", n.codice) }
            x.chiudi("DettaglioLinee")
        }
        for r in v.riepiloghi {
            x.apri("DatiRiepilogo")
            x.elemento("AliquotaIVA", aliquotaTesto(r.aliquotaIVA))
            if let n = r.natura { x.elemento("Natura", n.codice) }
            x.elemento("ImponibileImporto", importo(r.imponibile))
            x.elemento("Imposta", importo(r.imposta))
            if let e = r.esigibilita { x.elemento("EsigibilitaIVA", e.rawValue) }
            if let rif = r.riferimentoNormativo, !rif.isEmpty { x.elemento("RiferimentoNormativo", testoLatino(rif, massimo: 100)) }
            x.chiudi("DatiRiepilogo")
        }
        x.chiudi("DatiBeniServizi")

        if let condizioni = f.condizioniPagamento, let modalita = f.modalitaPagamento {
            x.apri("DatiPagamento")
            x.elemento("CondizioniPagamento", condizioni.codice)
            x.apri("DettaglioPagamento")
            let beneficiario = testoLatino(f.beneficiario, massimo: 200)
            if !beneficiario.isEmpty { x.elemento("Beneficiario", beneficiario) }
            x.elemento("ModalitaPagamento", modalita.codice)
            if let s = p.scadenza { x.elemento("DataScadenzaPagamento", data(s, cal: cal)) }
            x.elemento("ImportoPagamento", importo(v.nettoAPagare))
            let banca = testoLatino(f.banca, massimo: 80)
            if !banca.isEmpty { x.elemento("IstitutoFinanziario", banca) }
            if MotoreFattura.ibanValido(f.iban) { x.elemento("IBAN", MotoreFattura.normalizzato(f.iban)) }
            x.chiudi("DettaglioPagamento")
            x.chiudi("DatiPagamento")
        }
        x.chiudi("FatturaElettronicaBody")
        x.livello = 0
        x.riga("</p:FatturaElettronica>")
        return .pronto(File(nome: nomeFile(partitaIVA: f.partitaIVA, progressivo: progressivo), xml: x.testo))
    }

    private static func anagrafica(_ x: inout ScrittoreFatturaXML, nome: String, cognome: String, denominazione: String) {
        x.apri("Anagrafica")
        let d = testoLatino(denominazione, massimo: 80)
        if !d.isEmpty {
            x.elemento("Denominazione", d)
        } else {
            x.elemento("Nome", testoLatino(nome, massimo: 60))
            x.elemento("Cognome", testoLatino(cognome, massimo: 60))
        }
        x.chiudi("Anagrafica")
    }

    private static func sede(_ x: inout ScrittoreFatturaXML, _ s: SedeFiscale) {
        x.apri("Sede")
        x.elemento("Indirizzo", testoLatino(s.indirizzo, massimo: 60))
        let civico = testoBase(s.numeroCivico, massimo: 8)
        if !civico.isEmpty { x.elemento("NumeroCivico", civico) }
        x.elemento("CAP", MotoreFattura.normalizzato(s.cap))
        x.elemento("Comune", testoLatino(s.comune, massimo: 60))
        let provincia = MotoreFattura.normalizzato(s.provincia)
        if MotoreFattura.siglaValida(provincia) { x.elemento("Provincia", provincia) }
        x.elemento("Nazione", MotoreFattura.normalizzato(s.nazione))
        x.chiudi("Sede")
    }

    // MARK: - Formati

    /// Un importo con il punto e 2 decimali («1234.50», «-3.00»).
    static func importo(_ euro: Double) -> String {
        let c = MotoreFattura.centesimi(euro)
        let assoluto = abs(c)
        let decimi = assoluto % 100
        return (c < 0 ? "-" : "") + String(assoluto / 100) + "." + (decimi < 10 ? "0" : "") + String(decimi)
    }

    /// Un'aliquota in percentuale con 2 decimali («22.00», «0.00»).
    static func aliquotaTesto(_ percento: Double) -> String { importo(abs(percento)) }

    /// Una data aaaa-mm-gg nel calendario dato.
    static func data(_ d: Date, cal: Calendar = .current) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        func due(_ n: Int) -> String { n < 10 ? "0\(n)" : String(n) }
        let anno = c.year ?? 1970
        let annoTesto = String(repeating: "0", count: max(0, 4 - String(anno).count)) + String(anno)
        return "\(annoTesto)-\(due(c.month ?? 1))-\(due(c.day ?? 1))"
    }

    /// Escape dei caratteri speciali dell'XML.
    static func escape(_ s: String) -> String {
        var r = ""
        r.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": r += "&amp;"
            case "<": r += "&lt;"
            case ">": r += "&gt;"
            case "\"": r += "&quot;"
            case "'": r += "&apos;"
            default: r.append(ch)
            }
        }
        return r
    }

    /// Il testo nel set latino del tracciato (Basic Latin e Latin-1 Supplement): apostrofi e virgolette tipografici,
    /// trattini, puntini ed euro diventano i loro equivalenti; a capo e tabulazioni diventano spazi; il resto «?».
    /// Senza spazi in testa e in coda, al massimo `massimo` caratteri. L'escape lo fa lo scrittore.
    static func testoLatino(_ s: String, massimo: Int) -> String {
        sostituito(s, massimo: massimo, ammesso: { v in (0x20...0x7E).contains(v) || (0xA0...0xFF).contains(v) })
    }

    /// Come `testoLatino`, ma solo Basic Latin (numero del documento, numero civico).
    static func testoBase(_ s: String, massimo: Int) -> String {
        sostituito(s, massimo: massimo, ammesso: { v in (0x20...0x7E).contains(v) })
    }

    private static func sostituito(_ s: String, massimo: Int, ammesso: (UInt32) -> Bool) -> String {
        var r = ""
        for u in s.unicodeScalars {
            switch u.value {
            case 0x2018, 0x2019, 0x201A, 0x2032: r += "'"
            case 0x201C, 0x201D, 0x201E: r += "\""
            case 0x2010...0x2015, 0x2212: r += "-"
            case 0x2026: r += "..."
            case 0x20AC: r += "EUR"
            case 0x09, 0x0A, 0x0D, 0x00A0: r += " "
            default: r += ammesso(u.value) ? String(Character(u)) : "?"
            }
        }
        let pulito = r.trimmingCharacters(in: .whitespaces)
        return String(pulito.prefix(max(0, massimo)))
    }

    /// Il testo in pezzi di al massimo `lunghezza` caratteri (la Causale ne ammette 200 per elemento).
    static func pezzi(_ s: String, lunghezza: Int) -> [String] {
        guard !s.isEmpty, lunghezza > 0 else { return [] }
        var risultato: [String] = []
        var resto = Substring(s)
        while !resto.isEmpty {
            risultato.append(String(resto.prefix(lunghezza)))
            resto = resto.dropFirst(lunghezza)
        }
        return risultato.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

/// Lo scrittore del testo XML, con il rientro di due spazi per livello. I valori passano dall'escape.
struct ScrittoreFatturaXML {
    private(set) var testo = ""
    var livello = 0

    mutating func riga(_ s: String) {
        testo += String(repeating: "  ", count: livello) + s + "\n"
    }

    mutating func apri(_ nome: String) {
        riga("<\(nome)>")
        livello += 1
    }

    mutating func chiudi(_ nome: String) {
        livello = max(0, livello - 1)
        riga("</\(nome)>")
    }

    mutating func elemento(_ nome: String, _ valore: String) {
        riga("<\(nome)>\(GeneratoreFatturaPA.escape(valore))</\(nome)>")
    }
}
