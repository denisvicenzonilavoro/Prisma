import Foundation

// MARK: - Studio › Parcelle e fatture: i testi della fattura su carta (giro 2, specifica §1.4, §5.3 e §6.4)
// Tutte le stringhe del foglio (FatturaCarta) e del PDF, ricavate dalla parcella, dal dossier del cliente e dai dati
// fiscali del consulente (Impostazioni › Studio). Puro, senza SwiftUI. Nessuna regola fiscale scelta qui: le voci
// vengono da `MotoreFattura` con il regime del consulente (o sono quelle congelate all'emissione). Un dato che manca
// si scrive «da completare» (in ambra sulla carta) e il piede porta «Documento di prova»; le diciture le scrive solo
// il consulente (`RegimeFatturazione.frasePiede`), mai Prisma.

struct TestiFattura: Equatable {
    /// Un testo del foglio: `daCompletare` quando il dato manca (in ambra sulla carta).
    struct Campo: Hashable {
        let testo: String
        var daCompletare = false
    }

    /// Una riga della tabella: descrizione, sottotitolo e importo.
    struct Riga: Hashable, Identifiable {
        let id: String
        let descrizione: String
        let sottotitolo: String
        let importo: String
    }

    /// Una voce fiscale sotto le righe (imponibile, contributo, IVA o natura, bollo, ritenuta).
    struct VoceFiscale: Hashable, Identifiable {
        var id: String { etichetta }
        let etichetta: String
        let valore: String
        var daCompletare = false
    }

    let parcellaId: String
    /// «Fattura», «Bozza di fattura» o «Fattura annullata».
    let sopratitolo: String
    /// «N. 2026/015», oppure «Senza numero» per la bozza.
    let numero: String
    /// «del 28 ott 2026».
    let data: String
    /// Il nome del cliente come va in fattura e le righe sotto (codice fiscale, partita IVA, indirizzo).
    let cliente: Campo
    let datiCliente: [Campo]
    let righe: [Riga]
    /// Le voci fiscali calcolate (vuote se il regime non è completo: allora `vociMancanti` è vero).
    let voci: [VoceFiscale]
    let vociMancanti: Bool
    /// «Totale» o «Totale provvisorio» (senza voci fiscali).
    let etichettaTotale: String
    let totale: String
    /// Con la ritenuta: la ritenuta sotto il totale e il netto a pagare.
    let dopoTotale: [VoceFiscale]
    let netto: String?
    /// I dati del pagamento (modalità, IBAN, banca, scadenza): uno per riga.
    let pagamento: [Campo]
    /// Il piede: i dati fiscali del consulente, la dicitura scritta da lui e «Documento di prova».
    let piede: [Campo]
    /// Il canale è sempre l'indipendente: «Denis Vicenzoni · Consulenza finanziaria».
    let intestazione: String
    /// Il nome del cliente (per il titolo del documento e il nome del file).
    let nomeCliente: String
    /// Mancano dati per il file XML (il foglio è di prova).
    let diProva: Bool

    static let sottotitoloRiga = "Consulenza finanziaria indipendente"
    static let daCompletare = "da completare"
    static let documentoDiProva = "Documento di prova"
    static let etichettaNetto = "Netto a pagare"

    private static let formatoData = Formati.formato("d MMM yyyy")

    /// «28 ott 2026».
    static func data(_ d: Date) -> String {
        formatoData.string(from: d).replacingOccurrences(of: ".", with: "")
    }

    /// «900 €», «1.250,50 €»: i centesimi solo se ci sono.
    static func importo(_ v: Double) -> String {
        let c = MotoreFattura.centesimi(v)
        return c % 100 == 0 ? Formati.euro(v) : Formati.euroDecimali(v)
    }

    /// «22%», «4,5%».
    static func aliquota(_ v: Double) -> String { Formati.percentuale(v) }

    /// Il nome del cliente per la fattura: denominazione, oppure nome e cognome del dossier fiscale, oppure il nome
    /// dell'anagrafica.
    static func nomeFattura(_ c: Cliente) -> String {
        let f = c.fiscale ?? DatiFiscaliCliente()
        let denominazione = f.denominazione.trimmingCharacters(in: .whitespacesAndNewlines)
        if !denominazione.isEmpty { return denominazione }
        let nome = [f.nome, f.cognome].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return nome.isEmpty ? c.nome : nome.joined(separator: " ")
    }

    /// Il nome del consulente per la fattura (vuoto se non c'è).
    static func nomeConsulente(_ f: DatiFatturazione) -> String {
        let denominazione = f.denominazione.trimmingCharacters(in: .whitespacesAndNewlines)
        if !denominazione.isEmpty { return denominazione }
        return [f.nome, f.cognome].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// «Via di Prova 1, 00000 Comune di Prova (XX)»; vuoto se la sede non c'è.
    static func sede(_ s: SedeFiscale) -> String {
        let pulito = { (t: String) in t.trimmingCharacters(in: .whitespacesAndNewlines) }
        let via = [pulito(s.indirizzo), pulito(s.numeroCivico)].filter { !$0.isEmpty }.joined(separator: " ")
        var luogo = [pulito(s.cap), pulito(s.comune)].filter { !$0.isEmpty }.joined(separator: " ")
        let provincia = pulito(s.provincia)
        if !provincia.isEmpty { luogo += luogo.isEmpty ? provincia : " (\(provincia))" }
        let nazione = MotoreFattura.normalizzato(s.nazione)
        if !nazione.isEmpty && nazione != "IT" { luogo += luogo.isEmpty ? nazione : " · \(nazione)" }
        return [via, luogo].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// I testi della parcella. `mancanti`: ciò che manca per il file XML (MotoreFattura.mancanti); `prova`: i clienti
    /// sono quelli di prova.
    init(parcella p: Parcella, cliente c: Cliente?, consulente f: DatiFatturazione, mancanti: [DatoMancante], prova: Bool) {
        parcellaId = p.id
        switch p.stato {
        case .bozza: sopratitolo = "Bozza di fattura"
        case .annullata: sopratitolo = "Fattura annullata"
        case .emessa, .pagata: sopratitolo = "Fattura"
        }
        numero = p.numero.map { "N. \($0)" } ?? "Senza numero"
        data = "del " + Self.data(p.data)
        intestazione = Canale.indipendente.nome

        // Il cliente
        let mancaCliente = Set(mancanti.filter { $0.dove == .cliente }.map(\.codice))
        if let c {
            nomeCliente = c.nome
            cliente = Campo(testo: Self.nomeFattura(c))
            var dati: [Campo] = []
            let cf = MotoreFattura.normalizzato(c.codiceFiscale)
            dati.append(cf.isEmpty || mancaCliente.contains("cliente.codiceFiscale")
                        ? Campo(testo: "Codice fiscale " + (cf.isEmpty ? Self.daCompletare : cf), daCompletare: true)
                        : Campo(testo: "Codice fiscale " + cf))
            let piva = MotoreFattura.normalizzato(c.fiscale?.partitaIVA ?? "")
            if !piva.isEmpty {
                dati.append(Campo(testo: "P. IVA " + piva, daCompletare: mancaCliente.contains("cliente.partitaIVA")))
            }
            let sede = Self.sede(c.fiscale?.sede ?? SedeFiscale())
            let sedeIncompleta = mancaCliente.contains { $0.hasPrefix("cliente.sede.") }
            if sede.isEmpty {
                let indirizzo = c.indirizzo.trimmingCharacters(in: .whitespacesAndNewlines)
                dati.append(Campo(testo: indirizzo.isEmpty ? "Indirizzo " + Self.daCompletare : indirizzo, daCompletare: true))
            } else {
                dati.append(Campo(testo: sede, daCompletare: sedeIncompleta))
            }
            datiCliente = dati
        } else {
            nomeCliente = "Cliente"
            cliente = Campo(testo: "Cliente " + Self.daCompletare, daCompletare: true)
            datiCliente = []
        }

        // Le righe
        righe = p.righe.map { r in
            let descrizione = r.descrizione.trimmingCharacters(in: .whitespacesAndNewlines)
            return Riga(id: r.id, descrizione: descrizione.isEmpty ? "Descrizione " + Self.daCompletare : descrizione,
                        sottotitolo: Self.sottotitoloRiga, importo: Self.importo(r.importo))
        }

        // Le voci fiscali: congelate, oppure calcolate con il regime di oggi (bozza), oppure nessuna
        if let v = MotoreFattura.voci(p, regime: f.regime).voci {
            var voci: [VoceFiscale] = [VoceFiscale(etichetta: "Imponibile", valore: Self.importo(v.imponibile))]
            if let contributo = v.contributo {
                var etichetta = "Contributo previdenziale"
                if let a = v.aliquotaCassa { etichetta += " " + Self.aliquota(a) }
                if let t = v.tipoCassa { etichetta += " · " + t.codice }
                voci.append(VoceFiscale(etichetta: etichetta, valore: Self.importo(contributo)))
            }
            if let iva = v.iva, let a = v.aliquotaIVA {
                voci.append(VoceFiscale(etichetta: "IVA " + Self.aliquota(a) + " su " + Self.importo(v.baseIVA),
                                        valore: Self.importo(iva)))
            } else if let n = v.natura {
                var etichetta = "Senza IVA · " + n.codice
                if let rif = v.riferimentoNormativo, !rif.isEmpty { etichetta += " · " + rif }
                voci.append(VoceFiscale(etichetta: etichetta, valore: Self.importo(0)))
            }
            if let b = v.bollo {
                voci.append(VoceFiscale(etichetta: v.bolloACaricoCliente ? "Imposta di bollo" : "Imposta di bollo (non addebitata)",
                                        valore: Self.importo(b)))
            }
            vociMancanti = false
            etichettaTotale = "Totale"
            totale = Self.importo(v.totaleDocumento)
            if let r = v.ritenuta {
                var etichetta = "Ritenuta d'acconto"
                if let a = v.aliquotaRitenuta { etichetta += " " + Self.aliquota(a) }
                dopoTotale = [VoceFiscale(etichetta: etichetta, valore: Formati.meno + Self.importo(r))]
                netto = Self.importo(v.nettoAPagare)
            } else {
                dopoTotale = []
                netto = nil
            }
            self.voci = voci
        } else {
            voci = [VoceFiscale(etichetta: "Voci fiscali", valore: "secondo il regime impostato · " + Self.daCompletare,
                                daCompletare: true)]
            vociMancanti = true
            etichettaTotale = "Totale provvisorio"
            totale = Self.importo(MotoreParcelle.imponibile(p))
            dopoTotale = []
            netto = nil
        }

        // Il pagamento
        var pagamento: [Campo] = []
        let mancaConsulente = Set(mancanti.filter { $0.dove == .consulente }.map(\.codice))
        if let mp = f.modalitaPagamento {
            var testo = mp.descrizione
            let iban = MotoreFattura.normalizzato(f.iban)
            if !iban.isEmpty { testo += " · IBAN " + iban }
            let banca = f.banca.trimmingCharacters(in: .whitespacesAndNewlines)
            if !banca.isEmpty { testo += " · " + banca }
            pagamento.append(Campo(testo: testo, daCompletare: mancaConsulente.contains("consulente.iban")))
            let beneficiario = f.beneficiario.trimmingCharacters(in: .whitespacesAndNewlines)
            if !beneficiario.isEmpty { pagamento.append(Campo(testo: "Beneficiario " + beneficiario)) }
        } else {
            pagamento.append(Campo(testo: "Modalità di pagamento " + Self.daCompletare, daCompletare: true))
        }
        if let s = p.scadenza {
            pagamento.append(Campo(testo: "Entro il " + Self.data(s)))
        } else if let g = f.giorniPagamento {
            pagamento.append(Campo(testo: g == 1 ? "Entro 1 giorno" : "Entro \(g) giorni"))
        }
        if p.stato == .pagata, let il = p.incassataIl {
            pagamento.append(Campo(testo: "Pagata il " + Self.data(il)))
        }
        self.pagamento = pagamento

        // Il piede: chi emette, la dicitura del consulente, «Documento di prova»
        var piede: [Campo] = []
        let nome = Self.nomeConsulente(f)
        piede.append(Campo(testo: nome.isEmpty ? "Consulente " + Self.daCompletare : nome, daCompletare: nome.isEmpty))
        let piva = MotoreFattura.normalizzato(f.partitaIVA)
        piede.append(Campo(testo: "P. IVA " + (piva.isEmpty ? Self.daCompletare : piva),
                           daCompletare: mancaConsulente.contains("consulente.partitaIVA")))
        let cf = MotoreFattura.normalizzato(f.codiceFiscale)
        piede.append(Campo(testo: "C.F. " + (cf.isEmpty ? Self.daCompletare : cf),
                           daCompletare: mancaConsulente.contains("consulente.codiceFiscale")))
        let sede = Self.sede(f.sede)
        piede.append(Campo(testo: sede.isEmpty ? "Sede " + Self.daCompletare : sede,
                           daCompletare: mancaConsulente.contains { $0.hasPrefix("consulente.sede.") }))
        let frase = (p.voci?.frasePiede ?? f.regime.frasePiede).trimmingCharacters(in: .whitespacesAndNewlines)
        if !frase.isEmpty { piede.append(Campo(testo: frase)) }
        diProva = !mancanti.isEmpty || prova
        if diProva { piede.append(Campo(testo: Self.documentoDiProva)) }
        self.piede = piede
    }
}
