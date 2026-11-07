import Foundation

/// I testi di «Rispetto alle famiglie come la sua» e del caricamento delle tabelle (Impostazioni): frasi del
/// confronto, cautele ed errori del file. Le frasi non hanno genere: il soggetto è la famiglia del cliente.
/// Versione 1 (cella età × reddito): «… come la sua». Versione 2 (tavole a una dimensione): ogni frase dice con chi si
/// confronta («della sua età», «del suo quinto di reddito», «in Italia») e che cifra è (media, mediana, quota).
enum TestiFamiglie {
    // MARK: Le voci

    static func nome(_ v: VoceFamiglie) -> String {
        switch v {
        case .tassoRisparmio: return "Risparmio"
        case .ricchezzaFinanziaria: return "Patrimonio finanziario"
        case .ricchezzaNetta: return "Ricchezza netta"
        case .protezione: return "Protezione della famiglia"
        case .previdenzaComplementare: return "Previdenza complementare"
        }
    }

    /// L'inizio della frase quando la famiglia sta sopra («Risparmia più di»).
    private static func piuDi(_ v: VoceFamiglie) -> String {
        switch v {
        case .tassoRisparmio: return "Risparmia più di"
        case .ricchezzaFinanziaria: return "Ha più patrimonio finanziario di"
        case .ricchezzaNetta: return "Ha più ricchezza netta di"
        case .protezione: return "Spende per la protezione più di"
        case .previdenzaComplementare: return "Versa alla previdenza complementare più di"
        }
    }

    /// L'inizio della frase quando la famiglia sta sotto («Risparmia meno di»).
    private static func menoDi(_ v: VoceFamiglie) -> String {
        switch v {
        case .tassoRisparmio: return "Risparmia meno di"
        case .ricchezzaFinanziaria: return "Ha meno patrimonio finanziario di"
        case .ricchezzaNetta: return "Ha meno ricchezza netta di"
        case .protezione: return "Spende per la protezione meno di"
        case .previdenzaComplementare: return "Versa alla previdenza complementare meno di"
        }
    }

    /// «circa 7 famiglie su 10», «circa 1 famiglia su 10», «meno di 1 famiglia su 10», «quasi tutte le famiglie».
    static func suDieci(_ n: Int) -> String {
        switch n {
        case ..<1: return "meno di 1 famiglia su 10"
        case 1: return "circa 1 famiglia su 10"
        case 10...: return "quasi tutte le famiglie"
        default: return "circa \(n) famiglie su 10"
        }
    }

    // MARK: Le frasi del confronto

    /// Con i quantili: da 50 in su «più di circa N su 10» (N = percentile / 10 per difetto), sotto «meno di circa
    /// M su 10» (M = (100 − percentile) / 10 per difetto).
    /// Con le tavole a una dimensione dice con chi: «… di circa 6 famiglie su 10 in Italia.».
    static func frasePercentile(_ v: VoceFamiglie, percentile p: Int, ambito: AmbitoFamiglie = .cella) -> String {
        let chi = suffisso(ambito)
        if p >= 50 { return "\(piuDi(v)) \(suDieci(p / 10)) \(chi)." }
        return "\(menoDi(v)) \(suDieci((100 - p) / 10)) \(chi)."
    }

    /// Dopo «N famiglie su 10»: «come la sua», «della sua età», «del suo quinto di reddito», «in Italia».
    static func suffisso(_ a: AmbitoFamiglie) -> String {
        switch a {
        case .cella: return "come la sua"
        case .eta: return "della sua età"
        case .reddito: return "del suo quinto di reddito"
        case .tutte: return "in Italia"
        }
    }

    /// «delle famiglie della sua età», «delle famiglie del suo quinto di reddito», «delle famiglie italiane».
    static func famiglieDi(_ a: AmbitoFamiglie) -> String {
        switch a {
        case .cella: return "delle famiglie come la sua"
        case .eta: return "delle famiglie della sua età"
        case .reddito: return "delle famiglie del suo quinto di reddito"
        case .tutte: return "delle famiglie italiane"
        }
    }

    // MARK: Le cifre nelle frasi

    /// «28,7%» (una cifra decimale, come le tavole).
    static func percentuale(_ v: Double) -> String { FormatoCifra.unDecimale(v) + "%" }

    /// L'articolo davanti a una percentuale: «il 20,0%», ma «l'8,7%», «l'11,2%», «l'1,5%», «l'80%» (si guarda la
    /// parte intera come si legge: uno, otto, undici, ottanta…, ottocento…).
    static func articoloPercentuale(_ v: Double) -> String {
        guard v.isFinite, v >= 0 else { return "il " }
        let n = Int((v * 10).rounded()) / 10
        let vocale = n == 1 || n == 8 || n == 11 || (80...89).contains(n) || (800...899).contains(n)
        return vocale ? "l'" : "il "
    }

    /// «il 20,0%», «l'8,7%».
    static func ilPercentuale(_ v: Double) -> String { articoloPercentuale(v) + percentuale(v) }

    /// «8.500 €».
    static func euro(_ v: Double) -> String { FormatoCifra.migliaia(v) + "\u{00A0}€" }

    /// La cifra di una voce che si confronta con un valore: % per il tasso di risparmio, euro per le altre.
    static func cifra(_ v: VoceFamiglie, _ x: Double) -> String { v == .tassoRisparmio ? percentuale(x) : euro(x) }

    /// La cifra del cliente con il suo nome: «il 15,0% del reddito risparmiato», «30.000 € di attività finanziarie».
    static func cifraCliente(_ v: VoceFamiglie, _ x: Double) -> String {
        switch v {
        case .tassoRisparmio: return "\(ilPercentuale(x)) del reddito risparmiato"
        case .ricchezzaFinanziaria: return "\(euro(x)) di attività finanziarie"
        case .ricchezzaNetta: return "\(euro(x)) di ricchezza netta"
        case .protezione: return "\(euro(x)) l'anno di premi di protezione"
        case .previdenzaComplementare: return "\(euro(x)) l'anno di contributi"
        }
    }

    /// Tavole a una dimensione, con la sola mediana, la media o il rapporto tra medie: «Con 30.000 € di attività
    /// finanziarie sta sopra almeno metà delle famiglie della sua età (mediana 8.500 €).». Nessun percentile.
    static func fraseValore(_ v: VoceFamiglie, metodo: MetodoConfrontoFamiglie, cliente x: Double, gruppo g: Double,
                            ambito: AmbitoFamiglie) -> String {
        let chi = famiglieDi(ambito)
        let pari = abs(x - g) < 1e-9
        switch metodo {
        case .mediana:
            if pari { return "Con \(cifraCliente(v, x)) sta proprio sulla mediana \(chi)." }
            return "Con \(cifraCliente(v, x)) sta \(x > g ? "sopra" : "sotto") almeno metà \(chi) (mediana \(cifra(v, g)))."
        default:
            if pari { return "Con \(cifraCliente(v, x)) è in linea con la media \(chi)." }
            return "Con \(cifraCliente(v, x)) sta \(x > g ? "sopra" : "sotto") la media \(chi) (\(cifra(v, g)))."
        }
    }

    static func fraseMediana(_ v: VoceFamiglie, sopra: Bool, pari: Bool) -> String {
        if pari { return "\(nome(v)): in linea con la famiglia di mezzo tra quelle come la sua." }
        return "\(sopra ? piuDi(v) : menoDi(v)) metà delle famiglie come la sua."
    }

    static func fraseMedia(_ v: VoceFamiglie, sopra: Bool, pari: Bool) -> String {
        if pari { return "\(nome(v)): in linea con la media delle famiglie come la sua." }
        return "\(sopra ? piuDi(v) : menoDi(v)) una famiglia media come la sua."
    }

    /// Tavole a una dimensione, con la quota (0-100) e la percentuale esatta. Protezione: solo le polizze vita, e la
    /// frase lo dice («Le tavole non contano le polizze danni.»).
    static func fraseQuota(_ v: VoceFamiglie, ha: Bool, quota: Double, ambito: AmbitoFamiglie) -> String {
        let chi = "\(ilPercentuale(quota)) \(famiglieDi(ambito))"
        switch (v, ha) {
        case (.previdenzaComplementare, true):
            return "Aderisce a una pensione integrativa, come \(chi)."
        case (.previdenzaComplementare, false):
            return "Non aderisce a una pensione integrativa; lo fa \(chi)."
        case (_, true):
            return "Ha una polizza vita, come \(chi). Le tavole non contano le polizze danni."
        case (_, false):
            return "Non ha polizze vita registrate; ce l'ha \(chi). Le tavole non contano le polizze danni."
        }
    }

    /// Con la quota delle famiglie che hanno la cosa (0-100).
    static func fraseQuota(_ v: VoceFamiglie, ha: Bool, quota: Double) -> String {
        let quanti = Int(((ha ? quota : 100 - quota) / 10).rounded())
        switch (v, ha) {
        case (.previdenzaComplementare, true):
            return "Aderisce alla previdenza complementare: lo fanno \(suDieci(quanti)) come la sua."
        case (.previdenzaComplementare, false):
            return "Non aderisce alla previdenza complementare: non lo fanno \(suDieci(quanti)) come la sua."
        case (_, true):
            return "Ha almeno una polizza di protezione: ce l'hanno \(suDieci(quanti)) come la sua."
        case (_, false):
            return "Non ha polizze di protezione: non ce l'hanno \(suDieci(quanti)) come la sua."
        }
    }

    // MARK: Cautele e avvisi

    static let avvisoDiProva = "Dati di prova, non statistiche vere: per il confronto usa le tavole della Banca d'Italia (Impostazioni)."
    static let servonoEtaReddito = "Per il confronto servono l'età e il reddito della famiglia: completali nel dossier."
    static let cellaNonTrovata = "Le tabelle non hanno un gruppo per questa età e questo reddito."
    static let redditoSoloFamiliari = "Reddito del cliente non indicato: conto solo quello dei familiari."
    static func pocheFamiglie(_ n: Int) -> String {
        "Poche famiglie nel campione (\(n)): prendilo come indicazione."
    }
    static let famiglieNonDichiarate = "Le tabelle non dicono quante famiglie ci sono nel gruppo: prendilo come indicazione."
    static let voceSenzaDati = "Le tabelle non hanno dati per questa voce."
    static let risparmioSoloVersamenti = "Risparmio libero non indicato: conto solo i versamenti delle posizioni."
    static let soloRegistrate = "Conto solo ciò che è registrato nelle posizioni di Prisma."
    static let soloMediana = "La fonte dà solo la mediana: si sa solo se sta sopra o sotto la metà."
    static let soloMedia = "La fonte dà solo la media: il confronto è solo con la famiglia media."
    /// Il rapporto tra medie (tavole a una dimensione): per il risparmio, 100 meno la propensione al consumo.
    static func rapportoTraMedie(_ v: VoceFamiglie) -> String {
        guard v == .tassoRisparmio else { return "È un rapporto tra medie del gruppo, non la media delle singole famiglie." }
        return "È un rapporto tra medie: il risparmio medio del gruppo diviso il suo reddito medio (100 meno la propensione al consumo), non la media dei tassi delle singole famiglie. Nelle tavole il risparmio è reddito meno consumi (comprende anche le rate di mutuo rimborsate); quello del cliente in Prisma è il risparmio libero più i versamenti nelle posizioni: le due misure non coincidono."
    }
    static let distribuzioneComplessiva = "Distribuzione di tutte le famiglie italiane, non della sua età né del suo reddito: le tavole non la danno per gruppo."
    static let nettaSoloRegistrate = "Conto immobili, posizioni e debiti registrati in Prisma."
    static let mancaEta = "Manca la data di nascita: confronto solo con le famiglie del suo quinto di reddito."
    static let mancaReddito = "Manca il reddito della famiglia: confronto solo con le famiglie della sua età."
    static let etaFuoriClassi = "Le tabelle non hanno una classe per questa età."
    static let redditoFuoriClassi = "Le tabelle non hanno una classe per questo reddito."
    /// Le soglie dei quinti sono i redditi dell'anno dell'indagine.
    static func sogliePerAnno(_ anno: Int) -> String {
        "I quinti di reddito sono quelli del \(anno), in euro di allora e non rivalutati: per un reddito vicino a una soglia il quinto è solo indicativo."
    }
    static let capofamiglia = "Il cliente è preso come capofamiglia; per l'indagine il capofamiglia è chi ha il reddito più alto della famiglia."

    static func manca(_ v: VoceFamiglie) -> String {
        switch v {
        case .tassoRisparmio: return "Manca il risparmio della famiglia: indicalo nel dossier per il confronto."
        case .ricchezzaFinanziaria: return "Manca il patrimonio finanziario: nessuna posizione finanziaria in essere nel dossier."
        case .ricchezzaNetta: return "Manca la ricchezza netta: nessuna posizione in essere nel dossier."
        case .protezione: return "Manca il dato della protezione: indicalo nel dossier per il confronto."
        case .previdenzaComplementare: return "Manca il dato della previdenza complementare: indicalo nel dossier per il confronto."
        }
    }

    // MARK: Errori del file delle tabelle

    static let nonJSON = "il file non è un JSON leggibile."
    static let campoMancante = "campo obbligatorio mancante."
    static let tipoSbagliato = "tipo di valore sbagliato (per esempio un testo dove serve un numero)."
    static let valoreVuoto = "valore vuoto dove serve un dato."
    static func formatoSconosciuto(_ f: String) -> String {
        "formato «\(f)» non riconosciuto: serve «\(TabelleFamiglie.formatoAtteso)»."
    }
    static func versioneSconosciuta(_ v: Int) -> String {
        let lette = TabelleFamiglie.versioniLette.map(String.init).joined(separator: " e ")
        return "versione \(v) non riconosciuta: Prisma legge le versioni \(lette)."
    }
    static let fonteVuota = "manca la fonte delle tabelle."
    static let edizioneFuori = "l'anno dell'indagine non è valido."
    static let sogliaFuori = "la soglia delle famiglie deve essere almeno 1."
    static func classeSconosciuta(_ id: String) -> String { "la classe «\(id)» non è tra quelle dichiarate." }
    static func cellaDoppia(_ e: String, _ r: String) -> String { "la cella «\(e)» × «\(r)» compare due volte." }
    static func cellaMancante(_ e: String, _ r: String) -> String { "manca la cella «\(e)» × «\(r)»." }
    static let famiglieFuori = "il numero di famiglie deve essere un intero maggiore di zero."
    static let numeroNonValido = "numero non valido."
    static let quantiliDecrescenti = "i quantili devono crescere (o restare uguali) da p10 a p90."
    static let quotaFuori = "la quota deve stare tra 0 e 100."
    static let tassoFuori = "il tasso di risparmio è in percentuale del reddito: deve stare tra −100 e 100."
    static let classiVuote = "serve almeno una classe."
    static let idVuoto = "manca l'identificativo della classe."
    static func idDoppio(_ id: String) -> String { "l'identificativo «\(id)» compare due volte." }
    static let daMancante = "solo la prima classe può non avere l'estremo «da»."
    static let aMancante = "solo l'ultima classe può non avere l'estremo «a»."
    static let estremiInvertiti = "l'estremo «a» deve essere maggiore di «da»."
    static let etaIntera = "le età sono anni interi."
    static let sovrapposte = "si sovrappone alla classe precedente."
    static let buco = "lascia un buco dopo la classe precedente."
    static let valoreSconosciuto = "valore non riconosciuto (per esempio una dimensione o una statistica che Prisma non conosce)."
    static let gruppiVuoti = "serve almeno un gruppo."
    static func dimensioneDoppia(_ d: String) -> String { "c'è già un gruppo per la dimensione «\(d)»." }
    static let tutteUnaClasse = "il gruppo di tutte le famiglie ha una sola classe, senza «da» né «a»."
    static func voceSconosciuta(_ v: String) -> String {
        let note = VoceFamiglie.allCases.map(\.rawValue).joined(separator: ", ")
        return "voce «\(v)» non riconosciuta: le voci sono \(note)."
    }
    static let servonoQuantili = "con la statistica «quantili» servono almeno due quantili."
    static let quotaSoloPossesso = "la quota vale solo per la protezione e la previdenza complementare."

    // MARK: Impostazioni

    static let gruppo = "Famiglie italiane"
    static let titoloDiProva = "Dati di prova"
    /// Senza un file caricato: le tavole della Banca d'Italia incluse in Prisma.
    static func titoloPredefinite(_ t: TabelleFamiglie?) -> String {
        guard let t else { return "Tavole non disponibili" }
        if t.diProva { return titoloDiProva }
        guard let e = t.edizione else { return "Banca d'Italia" }
        return "Banca d'Italia, edizione \(e)"
    }
    static let spiegaPredefinite = "Tavole pubblicate dell'Indagine sui bilanci delle famiglie italiane, incluse in Prisma: età del capofamiglia e quinti di reddito familiare netto. Puoi caricare un file aggiornato."
    static let spiegaDiProva = "Il confronto «Rispetto alle famiglie come la sua» usa valori segnaposto, non statistiche: carica le tabelle della fonte."
    static func titoloCaricate(_ fonte: String, edizione: Int?) -> String {
        edizione.map { "\(fonte), \($0)" } ?? fonte
    }
    static func spiegaCaricate(_ nomeFile: String, il data: Date) -> String {
        "File «\(nomeFile)» caricato il \(data.formatted(date: .long, time: .omitted)). Resta sul Mac e nel backup."
    }
    static let pillolaDiProva = "dati di prova"
    static let pillolaCaricate = "caricate"
    static let pillolaPredefinite = "incluse"
    static let carica = "Carica tabelle…"
    static let usaPredefinite = "Usa le tavole incluse"
    static let pannelloMessaggio = "Scegli il file JSON delle tabelle delle famiglie (formato «prisma-famiglie»)."
    static let pannelloPulsante = "Carica"
    static let fileIlleggibile = "Non riesco a leggere il file."
    static func erroreFile(_ messaggio: String) -> String { "File non valido, restano le tabelle di prima. \(messaggio)" }
    static let senzaPredefinite = "Le tavole incluse non si leggono: carica un file delle tabelle."
}
