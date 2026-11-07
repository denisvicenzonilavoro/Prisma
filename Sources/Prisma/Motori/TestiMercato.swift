import Foundation

/// Le frasi di Mercato (giro 7), tutte qui e mai nelle viste: fonti da citare, errori del CSV, eventi e avvisi,
/// «nei portafogli di N clienti».
enum TestiMercato {
    // MARK: - Fonti

    /// «Fonte: BCE», «Fonte: BCE (dato di EMMI)», «Fonte: Eurostat», «Fonte: Borsa Italiana (file importato)»,
    /// «Inserito a mano».
    static func citazione(origine: OrigineDatoMercato, fonte: String, datoDiTerzi: String?) -> String {
        let terzi = datoDiTerzi.map { $0.trimmingCharacters(in: .whitespaces) }.flatMap { $0.isEmpty ? nil : $0 }
        switch origine {
        case .bce:
            return terzi.map { "Fonte: BCE (dato di \($0))" } ?? "Fonte: BCE"
        case .eurostat:
            return terzi.map { "Fonte: Eurostat (dato di \($0))" } ?? "Fonte: Eurostat"
        case .csv:
            let f = fonte.trimmingCharacters(in: .whitespaces)
            return f.isEmpty || f == origine.nome ? "Fonte: file importato" : "Fonte: \(f) (file importato)"
        case .aMano:
            let f = fonte.trimmingCharacters(in: .whitespaces)
            return f.isEmpty || f == origine.nome ? "Inserito a mano" : "Fonte: \(f) (inserito a mano)"
        }
    }

    /// La frase della fascia sulla riservatezza (Dubbio 2 del §12): con l'interruttore acceso escono solo richieste
    /// di dati pubblici, con l'interruttore spento niente.
    static func riservatezza(attivo: Bool) -> String {
        attivo
            ? "Dal Mac escono solo le richieste di dati pubblici (BCE, Eurostat): nessun dato dei clienti lascia Prisma."
            : "Nessun dato esce dal Mac."
    }

    // MARK: - Errori del CSV (Design/mercato-csv.md)

    static func erroreColonne(_ n: Int) -> String { "Servono almeno \(n) colonne." }
    static let erroreTroppeColonne = "Più colonne del previsto: con la virgola come separatore il decimale è il punto."
    static let erroreData = "Data non leggibile (aaaa-mm-gg oppure gg/mm/aaaa)."
    static let erroreDataFutura = "La data è nel futuro."
    static let erroreValore = "Valore non leggibile (niente separatore delle migliaia; con la virgola come separatore il decimale è il punto)."
    static let erroreISIN = "ISIN non valido: la cifra di controllo non torna."
    static let erroreQuotaNonPositiva = "La quota deve essere maggiore di zero."
    static let erroreRipetuta = "Data già presente più sopra: vale la prima."

    // MARK: - Ricerca per ISIN

    /// «Non è nei portafogli dei clienti», «Nel portafoglio di 1 cliente», «Nei portafogli di 3 clienti».
    static func neiPortafogli(_ n: Int) -> String {
        switch n {
        case ..<1: return "Non è nei portafogli dei clienti"
        case 1: return "Nel portafoglio di 1 cliente"
        default: return "Nei portafogli di \(n) clienti"
        }
    }

    static let isinNonValido = "Codice ISIN non valido: controlla le 12 cifre e lettere."
    static let mancaNumeroQuote = "manca il numero di quote"

    // MARK: - Numeri

    /// «+0,6%», «−1,8%» (meno tipografico).
    static func percentualeConSegno(_ v: Double, decimali: Int = 1) -> String {
        segno(v) + numero(abs(v), decimali: decimali) + "%"
    }

    /// «+0,15», «−0,02».
    static func puntiConSegno(_ v: Double) -> String { segno(v) + numero(abs(v), decimali: 2) }

    /// «3,42» con i decimali dati (separatori italiani).
    static func numero(_ v: Double, decimali: Int) -> String {
        let f = NumberFormatter()
        f.locale = Formati.localeImporti
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimali
        f.maximumFractionDigits = decimali
        f.minusSign = Formati.meno
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }

    private static func segno(_ v: Double) -> String { v > 0 ? "+" : (v < 0 ? Formati.meno : "") }

    /// «ottobre 2026» per i dati mensili, «23 ottobre 2026» per gli altri.
    static func dataDato(_ d: Date, frequenza: FrequenzaMercato) -> String {
        switch frequenza {
        case .giornaliera: return Formati.dataEstesa.string(from: d)
        case .mensile, .trimestrale: return Formati.meseAnno.string(from: d)
        case .annuale: return Formati.formato("yyyy").string(from: d)
        }
    }

    // MARK: - Eventi e avvisi (frasi che possono entrare anche nei messaggi)

    /// ««Euro Stoxx 50» è sceso del 2,1% a ottobre 2026» oppure ««Euribor 3 mesi» è salito di 0,15 punti a ottobre 2026».
    static func titoloVariazione(_ s: SerieMercato, variazione: Double, data: Date) -> String {
        let verbo = variazione >= 0 ? "è salito" : "è sceso"
        let misura = s.unita.variazioneInPercentuale
            ? "del " + numero(abs(variazione), decimali: 1) + "%"
            : "di " + numero(abs(variazione), decimali: 2) + " punti"
        let quando = s.frequenza == .giornaliera ? "il " + dataDato(data, frequenza: s.frequenza) : "a " + dataDato(data, frequenza: s.frequenza)
        return "«\(s.nome)» \(verbo) \(misura) \(quando)"
    }

    static func dettaglioVariazione(_ s: SerieMercato, prima: PuntoMercato, dopo: PuntoMercato, soglia: Double) -> String {
        let unita = s.unita == .percentuale ? "%" : ""
        let misuraSoglia = s.unita.variazioneInPercentuale ? numero(soglia, decimali: 1) + "%" : numero(soglia, decimali: 2) + " punti"
        return "Da \(numero(prima.valore, decimali: 2))\(unita) (\(dataDato(prima.data, frequenza: s.frequenza))) a "
            + "\(numero(dopo.valore, decimali: 2))\(unita) (\(dataDato(dopo.data, frequenza: s.frequenza))) · soglia \(misuraSoglia) · \(s.citazione)"
    }

    /// ««Fondo azionario» è sceso del 6,1% dal massimo dell'ultimo anno».
    static func titoloCalo(nome: String, calo: Double) -> String {
        "«\(nome)» è sceso del \(numero(calo, decimali: 1))% dal massimo dell'ultimo anno"
    }

    static func dettaglioCalo(ultimo: PuntoMercato, massimo: PuntoMercato, soglia: Double, fonte: String) -> String {
        "Quota \(Formati.euroDecimali(ultimo.valore)) del \(Formati.dataEstesa.string(from: ultimo.data)), massimo "
            + "\(Formati.euroDecimali(massimo.valore)) del \(Formati.dataEstesa.string(from: massimo.data)) · soglia "
            + "\(Formati.meno)\(numero(soglia, decimali: 1))% · \(fonte)"
    }

    /// ««Fondo azionario» si è allontanato di 4,0 punti dal suo riferimento in un mese».
    static func titoloDistanza(nome: String, distanza: Double) -> String {
        "«\(nome)» si è allontanato di \(numero(abs(distanza), decimali: 1)) punti dal suo riferimento in un mese"
    }

    static func dettaglioDistanza(variazioneQuota: Double, riferimento: SerieMercato, variazioneRiferimento: Double,
                                  soglia: Double, fonte: String) -> String {
        "In un mese: quota \(percentualeConSegno(variazioneQuota)), «\(riferimento.nome)» \(percentualeConSegno(variazioneRiferimento)) · "
            + "soglia \(numero(soglia, decimali: 1)) punti · \(fonte) · \(riferimento.citazione)"
    }

    /// «la cedola di «BTP 2030» arriva tra 12 giorni, il 14 novembre 2026».
    static func titoloCedola(nome: String, giorni: Int, data: Date) -> String {
        let quando: String
        switch giorni {
        case 0: quando = "oggi"
        case 1: quando = "domani"
        default: quando = "tra \(giorni) giorni, il \(Formati.dataEstesa.string(from: data))"
        }
        return "La cedola di «\(nome)» arriva \(quando)"
    }

    static func dettaglioCedola(_ c: CedolaTitolo, data: Date, soglia: Int) -> String {
        let volte = c.volteAllAnno == 1 ? "1 cedola" : "\(c.volteAllAnno) cedole"
        return "Il \(Formati.dataEstesa.string(from: data)), tasso annuo \(numero(c.tassoAnnuo, decimali: 2))% in \(volte) l'anno · "
            + "avviso \(soglia) giorni prima · dato della posizione"
    }

    /// L'oggetto della mail per un avviso di mercato.
    static func oggettoMessaggio(_ tipo: TipoEventoMercato) -> String {
        switch tipo {
        case .variazioneSerie: return "I mercati di questi giorni"
        case .caloDalMassimo, .distanzaDalRiferimento: return "Un'occhiata al tuo investimento"
        case .cedolaInArrivo: return "La cedola in arrivo"
        }
    }
}
