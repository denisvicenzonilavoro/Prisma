import Foundation

// MARK: - `Prisma --prova-fattura <cartella>`: fatture XML di esempio per la verifica contro lo schema nel workflow
// Scrive nella cartella due fatture del tracciato FatturaPA FPR12 (una con IVA, contributo e ritenuta; una senza IVA, con
// una natura e il bollo addebitato) e le rilegge con XMLParser. TUTTI I DATI SONO DI PROVA, FITTIZI E DICHIARATI:
// - consulente «Prova Consulente», partita IVA 01234567897 (fittizia, formalmente valida: la cifra di controllo torna), codice
//   fiscale PRVCNS75B02F205Y (fittizio, solo nel formato), sede in «Via di Prova», comune «Comune di Prova», provincia XX;
// - cliente «Cliente Di Prova», codice fiscale PRVCLN80A01H501Z (fittizio), codice destinatario 0000000;
// - IBAN IT51X0000000000000000000001 (fittizio, con le cifre di controllo giuste);
// - i regimi sono REGIMI DI PROVA scritti qui per provare le formule e il tracciato: NON sono una scelta del regime
//   fiscale del consulente (che resta vuoto finché non lo compila lui in Impostazioni › Studio › Fatturazione).
// Nessun invio al Sistema di Interscambio: sono solo file.

enum ProvaFatturaPA {
    /// Il consulente di prova (dati fittizi), con il regime di prova indicato.
    static func consulenteDiProva(regime: RegimeFatturazione) -> DatiFatturazione {
        var f = DatiFatturazione()
        f.nome = "Prova"
        f.cognome = "Consulente"
        f.partitaIVA = "01234567897"
        f.codiceFiscale = "PRVCNS75B02F205Y"
        var s = SedeFiscale()
        s.indirizzo = "Via di Prova"
        s.numeroCivico = "1"
        s.cap = "00000"
        s.comune = "Comune di Prova"
        s.provincia = "XX"
        s.nazione = "IT"
        f.sede = s
        f.email = "prova@example.com"
        f.iban = "IT51X0000000000000000000001"
        f.banca = "Banca di prova"
        f.beneficiario = "Prova Consulente"
        f.modalitaPagamento = .mp05
        f.condizioniPagamento = .completo
        f.regime = regime
        f.trasmittente = TrasmittenteFattura(chi: .consulente)
        return f
    }

    /// Regime di prova A (DICHIARATO, non una scelta): RF01, IVA di prova 22%, contributo di prova TC22 al 4% non soggetto
    /// a ritenuta, ritenuta di prova RT01 al 20% con causale A, niente bollo.
    static func regimeDiProvaConIVA() -> RegimeFatturazione {
        var r = RegimeFatturazione()
        r.regimeFiscale = .rf01
        r.aliquotaIVA = 22
        r.esigibilitaIVA = .immediata
        r.applicaCassa = true
        r.cassa = CassaPrevidenziale(tipo: .tc22, aliquota: 4, soggettoARitenuta: false)
        r.applicaRitenuta = true
        r.ritenuta = RitenutaAcconto(tipo: .rt01, aliquota: 20, causale: "A")
        r.applicaBollo = false
        return r
    }

    /// Regime di prova B (DICHIARATO, non una scelta): RF19, natura di prova N2.2 con un riferimento di prova, contributo
    /// di prova TC22 al 4%, niente ritenuta, bollo di prova di 2 € sopra 77,47 € addebitato al cliente con la natura N1.
    static func regimeDiProvaSenzaIVA() -> RegimeFatturazione {
        var r = RegimeFatturazione()
        r.regimeFiscale = .rf19
        r.natura = .n2_2
        r.riferimentoNormativo = "Riferimento normativo di prova"
        r.applicaCassa = true
        r.cassa = CassaPrevidenziale(tipo: .tc22, aliquota: 4)
        r.applicaRitenuta = false
        r.applicaBollo = true
        r.bollo = BolloVirtuale(importo: 2, soglia: 77.47, aCaricoCliente: true, naturaRiga: .n1,
                                riferimentoNormativoRiga: "Riferimento di prova del bollo")
        return r
    }

    /// Il cliente di prova (dati fittizi).
    static func clienteDiProva() -> Cliente {
        var c = Cliente(id: "cliente-prova-fattura", nome: "Cliente Di Prova", iniziali: "CP", tinta: .blu, tema: "", email: "",
                        telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2026, 1, 1))
        c.codiceFiscale = "PRVCLN80A01H501Z"
        var f = DatiFiscaliCliente()
        f.nome = "Cliente"
        f.cognome = "Di Prova"
        f.codiceDestinatario = "0000000"
        var s = SedeFiscale()
        s.indirizzo = "Via Fittizia"
        s.numeroCivico = "10"
        s.cap = "00000"
        s.comune = "Comune Fittizio"
        s.provincia = "XX"
        s.nazione = "IT"
        f.sede = s
        c.fiscale = f
        return c
    }

    /// Una parcella di prova emessa il 4 novembre 2026 con le righe date e il regime dato (numero «2026/001»).
    static func parcellaDiProva(righe: [RigaParcella], regime: RegimeFatturazione, descrizione: String) -> Parcella {
        let cal = Calendar(identifier: .gregorian)
        var n = NumerazioneFatture()
        n.modello = "{anno}/{numero:3}"
        var bozza = Parcella(id: "parcella-prova", clienteId: "cliente-prova-fattura", data: AiutiProva.data(2026, 11, 4),
                             descrizione: descrizione, righe: righe, cal: cal)
        bozza.scadenza = AiutiProva.data(2026, 12, 4)
        return MotoreParcelle.emessa(bozza, tra: [], data: AiutiProva.data(2026, 11, 4), numerazione: n, regime: regime, cal: cal)
    }

    /// Le due fatture di esempio (nome del file e testo), con i dati di prova. Vuoto se una non si può scrivere.
    static func esempi() -> [GeneratoreFatturaPA.Esito] {
        let cal = Calendar(identifier: .gregorian)
        let conIVA = regimeDiProvaConIVA()
        let senzaIVA = regimeDiProvaSenzaIVA()
        let a = parcellaDiProva(righe: [RigaParcella(id: "r1", descrizione: "Analisi & revisione <portafoglio> dell’anno", importo: 1_000),
                                        RigaParcella(id: "r2", descrizione: "Relazione «finale» – consulenza", importo: 250.50)],
                                regime: conIVA, descrizione: "Consulenza finanziaria di prova")
        let b = parcellaDiProva(righe: [RigaParcella(id: "r1", descrizione: "Consulenza di prova", importo: 500)],
                                regime: senzaIVA, descrizione: "")
        return [
            GeneratoreFatturaPA.genera(parcella: a, cliente: clienteDiProva(), consulente: consulenteDiProva(regime: conIVA),
                                       progressivoInvio: MotoreParcelle.progressivoInvio(1), cal: cal),
            GeneratoreFatturaPA.genera(parcella: b, cliente: clienteDiProva(), consulente: consulenteDiProva(regime: senzaIVA),
                                       progressivoInvio: MotoreParcelle.progressivoInvio(2), cal: cal),
        ]
    }

    /// Scrive le fatture di esempio nella cartella e le rilegge. 0 = tutto bene.
    static func esegui(cartella: URL) -> Int32 {
        do {
            try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
            var scritti = 0
            for esito in esempi() {
                guard let file = esito.file else {
                    print("ERRORE: fattura di esempio non preparata, mancano: \(esito.mancanti.map(\.testo).joined(separator: ", "))")
                    return 1
                }
                let lettore = LettoreFatturaXML()
                guard lettore.leggi(file.dati), lettore.nomi.contains("FatturaElettronicaBody") else {
                    print("ERRORE: \(file.nome) non si rilegge come XML")
                    return 1
                }
                try file.dati.write(to: cartella.appendingPathComponent(file.nome))
                print("OK    \(file.nome) (dati di prova fittizi, non valido per lo SdI)")
                scritti += 1
            }
            return scritti == 2 ? 0 : 1
        } catch {
            print("ERRORE: \(error.localizedDescription)")
            return 1
        }
    }
}

/// Rilegge un XML con XMLParser (Foundation, su tutte le piattaforme): i nomi degli elementi in ordine e il testo di
/// ognuno (per le prove).
final class LettoreFatturaXML: NSObject, XMLParserDelegate {
    private(set) var nomi: [String] = []
    /// Elemento e testo, in ordine.
    private(set) var valori: [(nome: String, testo: String)] = []
    private var corrente = ""

    /// true se il testo è XML ben formato.
    func leggi(_ dati: Data) -> Bool {
        nomi = []
        valori = []
        let p = XMLParser(data: dati)
        p.delegate = self
        return p.parse()
    }

    /// I testi di un elemento, in ordine.
    func testi(_ nome: String) -> [String] { valori.filter { $0.nome == nome }.map(\.testo) }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        nomi.append(elementName)
        corrente = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        corrente += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let t = corrente.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { valori.append((nome: elementName, testo: t)) }
        corrente = ""
    }
}
