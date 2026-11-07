import Foundation

/// Le frasi dell'app Mercato e di Impostazioni › Mercato (giro 7), tutte qui e mai nelle viste. Le frasi degli eventi,
/// degli avvisi e delle fonti stanno in TestiMercato (fondamenta).
enum TestiAppMercato {
    // MARK: - Testata e stati

    static let titoloFinestra = "Prisma conosce il mercato."
    static let maiAggiornato = "Mai aggiornato"
    static let inCorso = "Aggiornamento in corso…"
    static let valoriDiProva = "valori di prova"
    static let senzaValore = "—"
    static let invariato = "invariato"
    static let daImportare = "Da importare"
    static let inArrivo = "Al prossimo aggiornamento"

    /// La fascia della riservatezza: la frase di TestiMercato e, spento, come accenderlo.
    static func fascia(attivo: Bool) -> (testo: String, forte: String) {
        attivo
            ? ("Dal Mac escono solo le richieste di dati pubblici (BCE, Eurostat): ", "nessun dato dei clienti lascia Prisma.")
            : ("Nessun dato esce dal Mac. ", "Dati di mercato spenti: accendili in Impostazioni › Mercato. Escono solo codici pubblici, mai dati dei clienti.")
    }

    static let apriImpostazioni = "Impostazioni › Mercato"
    static let aggiornaOra = "Aggiorna ora"
    static let importaFile = "Importa un file CSV"
    static let aMano = "Inserisci a mano"
    static let soglie = "Soglie degli avvisi"

    // MARK: - Mai aggiornato

    static let vuotoTitolo = "Prisma non ha ancora i dati del mercato."
    static func vuotoTesto(attivo: Bool) -> String {
        attivo
            ? "Scarica le serie pubbliche di BCE ed Eurostat, oppure importa un file CSV con indici e quote dei fondi."
            : "Con «Dati di mercato» spento i valori arrivano solo dai file che importi o da ciò che scrivi a mano."
    }
    static let scaricaDatiPubblici = "Scarica i dati pubblici"
    #if os(iOS)
    static let soloDalMac = "Su iPhone e iPad Mercato si legge soltanto: serie, quote e avvisi arrivano dal Mac."
    #endif

    // MARK: - Tessere

    /// «ottobre 2026» (mensili), «23 ottobre 2026» (giornalieri), «dall'11 giugno 2025» (tasso BCE, in vigore da allora).
    static func dataTessera(_ d: Date, frequenza: FrequenzaMercato, tipo: TipoSerieMercato) -> String {
        if tipo == .tassoUfficiale {
            let testo = Formati.dataEstesa.string(from: d)
            let elide = testo.hasPrefix("1 ") || testo.hasPrefix("11 ") || testo.hasPrefix("8 ")
            return (elide ? "dall'" : "dal ") + testo
        }
        return TestiMercato.dataDato(d, frequenza: frequenza)
    }

    /// «al 23 ottobre 2026» al posto della variazione quando il dato è vecchio.
    static func alDato(_ testo: String) -> String { "al " + testo }

    /// «+0,15», «−0,2» con i decimali dati (meno tipografico).
    static func conSegno(_ v: Double, decimali: Int) -> String {
        let segno = v > 0 ? "+" : (v < 0 ? Formati.meno : "")
        return segno + TestiMercato.numero(abs(v), decimali: decimali)
    }

    /// VoiceOver della tessera.
    static func voceTessera(_ t: TesseraMercato) -> String {
        var parti = [t.nome, t.valoreTesto == senzaValore ? daImportare : t.valoreTesto]
        if let v = t.variazioneTesto { parti.append(v) }
        if let d = t.dataTesto { parti.append(d) }
        parti.append(t.citazione)
        return parti.joined(separator: ", ")
    }

    // MARK: - Chi è toccato

    static func titoloToccati(vecchi: Bool) -> String { vecchi ? "Chi è toccato dall’ultimo aggiornamento" : "Chi è toccato oggi" }
    static let nessunoToccato = "Oggi i movimenti del mercato non toccano in modo visibile i tuoi clienti."
    static let toccatiSenzaSoglie = "Scegli le soglie in Impostazioni › Mercato: senza soglie Prisma non segnala nessun movimento."
    static let toccatiSenzaDati = "Chi è toccato compare quando ci sono i dati del giorno."
    static let preparaMessaggio = "Prepara un messaggio"

    /// «Prepara un messaggio a Marco».
    static func preparaMessaggioA(_ nome: String) -> String { "Prepara un messaggio a \(primoNome(nome))" }

    static func clienti(_ n: Int) -> String { n == 1 ? "1 cliente" : "\(n) clienti" }

    /// La frase della scheda (§12.1.5): quanti clienti e, con la cifra, il più toccato «circa 3.000 €» con i canali
    /// separati; senza cifra la frase qualitativa del tipo di serie.
    static func fraseToccati(_ e: EventoMercato, tipoSerie: TipoSerieMercato?, nomi: [String: String]) -> String {
        let n = e.toccati.count
        guard let primo = e.toccati.first else { return nessunoToccato }
        if let impatto = primo.impatto, abs(impatto) >= 1 {
            let nome = primoNome(nomi[primo.clienteId] ?? "")
            let verbo = impatto < 0 ? "perde" : "guadagna"
            var frase = clienti(n) + " con questa esposizione: il portafoglio di " + nome + " " + verbo + " circa "
                + Formati.euro(abs(MotoreMercato.circa(impatto)))
            let canali = Canale.allCases.filter { primo.perCanale[$0] != nil }
            if canali.count > 1 {
                let parti = canali.compactMap { k -> String? in
                    guard let v = primo.perCanale[k] else { return nil }
                    return "\(k.nomeBreve) " + Formati.euro(abs(MotoreMercato.circa(v)))
                }
                frase += " (" + parti.joined(separator: ", ") + ")"
            }
            return frase + "."
        }
        let quanti = clienti(n)
        switch e.tipo {
        case .variazioneSerie:
            switch tipoSerie {
            case .rendimentoStato?, .spread?:
                return e.valore > 0
                    ? "\(quanti) con titoli di Stato: il valore scende un po’, la cedola resta quella."
                    : "\(quanti) con titoli di Stato: il valore sale un po’, la cedola resta quella."
            case .tassoInterbancario?, .tassoUfficiale?:
                return "\(quanti) con liquidità o debiti: i tassi cambiano rendimenti e rate."
            case .inflazione?:
                return e.valore > 0
                    ? "\(quanti) con obiettivi lontani: il potere d’acquisto si riduce un po’."
                    : "Buona notizia per chi ha obiettivi lontani (\(clienti(n))): il potere d’acquisto tiene."
            default:
                return "\(quanti) con questa esposizione."
            }
        case .caloDalMassimo, .distanzaDalRiferimento:
            return "\(quanti) con questa posizione nel portafoglio."
        case .cedolaInArrivo:
            return "Per \(primoNome(nomi[primo.clienteId] ?? "")): la cedola arriva sul conto."
        }
    }

    /// «+3»: gli altri clienti oltre gli avatar mostrati.
    static func altri(_ n: Int) -> String { "+\(n)" }

    static func primoNome(_ nome: String) -> String {
        nome.split(separator: " ").first.map(String.init) ?? nome
    }

    // MARK: - Avvisi

    static let avvisi = "Avvisi"
    static let nessunAvviso = "Nessun avviso. Scegli le soglie con «Soglie degli avvisi»: senza soglie Prisma non ne crea."
    static let nessunAvvisoConSoglie = "Nessun avviso: oggi nessuna soglia è superata."
    static let daGuardare = "Da guardare"
    static let segnaVisto = "Segna come visto"
    static let segnaNuovo = "Segna come da guardare"
    static let apriPosizione = "Apri la posizione"
    static let apriDossier = "Apri il dossier"

    /// Il pulsante dell'avviso per VoiceOver.
    static func voceAvviso(_ a: AvvisoMercato, cliente: String) -> String {
        "\(cliente). \(a.titolo). \(a.stato == .nuovo ? "Da guardare" : "Visto")"
    }

    // MARK: - Ricerca per ISIN

    static let cercaISIN = "Cerca un ISIN"
    static let cerca = "Cerca"
    static let quota = "Quota"
    static let daInizioAnno = "Da inizio anno"
    static let neiPortafogliEtichetta = "Nei portafogli"
    static let importaQuote = "Importa le quote"
    static func nessunaQuota(_ isin: String) -> String { "Nessuna quota per \(isin)" }
    static func quotaDel(_ d: Date) -> String { "del " + Formati.dataEstesa.string(from: d) }
    static let chiudiRicerca = "Chiudi la ricerca"

    // MARK: - Dettaglio della tessera

    static func dettaglioSottotitolo(_ s: SerieMercato) -> String {
        let codice = s.codice.isEmpty ? nil : s.codice
        return ([s.citazione, codice].compactMap { $0 }).joined(separator: " · ")
    }
    static func valoriInArchivio(_ n: Int) -> String { n == 1 ? "1 valore in archivio" : "\(n) valori in archivio" }
    static let ultimiMesi = "Ultimi 12 mesi"

    // MARK: - Importazione e inserimento a mano

    static let importaTitolo = "Importa i dati del mercato"
    static let importaSpiegazione = "Un file CSV con «data;valore» per una serie (un indice, un tasso) oppure «data;isin;valore» per le quote dei fondi. Il formato è descritto in Design/mercato-csv.md."
    static let fonteFile = "Da dove viene il file"
    static let fonteFileAiuto = "Per esempio «Estratto della piattaforma Alleanza», «Borsa Italiana», «SGR»: Prisma la cita accanto a ogni valore."
    static let nomeSerie = "Nome della serie"
    static let tipoSerie = "Che cosa misura"
    static let unitaSerie = "Unità"
    static let frequenzaSerie = "Ogni quanto esce"
    static let scegliFile = "Scegli il file…"
    static let registra = "Registra"
    static let annulla = "Annulla"
    static func letti(_ n: Int, righe: Int) -> String { "\(n) valori letti su \(righe) righe" }
    static func erroreRiga(_ e: ErroreRigaMercato) -> String { "Riga \(e.riga): \(e.motivo)" }
    static let fileNonLeggibile = "Il file non si legge come testo."
    static let nienteDaRegistrare = "Nessun valore da registrare."
    static func registrati(_ n: Int) -> String { n == 1 ? "1 valore registrato in Mercato" : "\(n) valori registrati in Mercato" }
    static let manoTitolo = "Inserisci un valore a mano"
    static let manoSerie = "Una serie"
    static let manoQuota = "La quota di un ISIN"
    static let data = "Data"
    static let valore = "Valore"
    static let isin = "ISIN"
    static let valoreNonValido = "Valore o data non leggibili."
    static let aggiornaPosizioni = "Aggiorna le posizioni dalle quote"
    static func posizioniDaAggiornare(_ n: Int) -> String {
        n == 1 ? "1 posizione ha una quota più recente del suo valore" : "\(n) posizioni hanno una quota più recente del loro valore"
    }

    static func nomeTipo(_ t: TipoSerieMercato) -> String {
        switch t {
        case .indiceAzionario: return "Indice azionario"
        case .rendimentoStato: return "Rendimento dei titoli di Stato"
        case .spread: return "Spread"
        case .tassoInterbancario: return "Tasso interbancario"
        case .tassoUfficiale: return "Tasso ufficiale"
        case .inflazione: return "Inflazione"
        case .altro: return "Altro"
        }
    }

    static func nomeUnita(_ u: UnitaMercato) -> String {
        switch u {
        case .percentuale: return "Percentuale"
        case .punti: return "Punti"
        case .euro: return "Euro"
        }
    }

    static func nomeFrequenza(_ f: FrequenzaMercato) -> String {
        switch f {
        case .giornaliera: return "Giornaliera"
        case .mensile: return "Mensile"
        case .trimestrale: return "Trimestrale"
        case .annuale: return "Annuale"
        }
    }

    // MARK: - Impostazioni › Mercato

    static let notaPagina = "Mercato porta in Prisma tassi, inflazione e indici pubblici, e le quote dei fondi che importi tu. Ogni valore ha la sua data e la sua fonte; Prisma non scrive nessun valore da sola."
    static let interruttore = "Dati di mercato"
    static let interruttoreSpiegazione = "Scarica le serie pubbliche di BCE ed Eurostat. Escono solo i codici pubblici delle serie: mai nomi, importi, portafogli o ISIN dei clienti. Niente account né chiavi."
    static let interruttoreAiuto = "Spento (come all'inizio) Prisma non esce mai su internet: i valori arrivano solo dai file che importi o da ciò che scrivi a mano."
    static let ultimoAggiornamento = "Ultimo aggiornamento"
    static func ultimo(_ d: Date?) -> String { d.map { Formati.dataOra.string(from: $0) } ?? "Mai" }
    static let ultimoErrore = "L'ultimo scaricamento non è riuscito del tutto"
    static let serieGruppo = "Serie da scaricare"
    static let serieNota = "Le chiavi delle serie stanno nel file serie-mercato.json (nel pacchetto di Prisma o, se lo metti, nella cartella dell'archivio): si possono cambiare senza toccare l'app."
    static let configurazioneMancante = "Il file delle serie non si legge: nessuna serie da scaricare."
    static func datoDiTerzi(_ chi: String) -> String { "Dato di \(chi), ridistribuito dalla fonte" }
    static let soglieGruppo = "Soglie degli avvisi"
    static let soglieNota = "Tutte vuote all'inizio: senza una soglia Prisma non crea avvisi e «Chi è toccato» resta vuoto. Le soglie le decidi tu."
    static let caloDalMassimo = "Calo dal massimo"
    static let caloDalMassimoSpiegazione = "La quota di un ISIN scende dal massimo degli ultimi 12 mesi di almeno…"
    static let distanza = "Distanza dal riferimento"
    static let distanzaSpiegazione = "In un mese la quota si allontana dalla sua serie di riferimento di almeno…"
    static let cedola = "Cedola in arrivo"
    static let cedolaSpiegazione = "La cedola di un titolo arriva entro…"
    static let variazioneIndici = "Variazione di un indice"
    static let variazioneIndiciSpiegazione = "«Chi è toccato»: un indice azionario si muove sull'ultimo dato di almeno…"
    static let variazioneTassi = "Variazione di un tasso"
    static let variazioneTassiSpiegazione = "«Chi è toccato»: un tasso o l'inflazione si muove sull'ultimo dato di almeno…"
    static let riferimentiGruppo = "Riferimento di ogni ISIN"
    static let riferimentiNota = "Per la distanza dal riferimento: la serie (un indice) con cui confrontare ogni ISIN."
    static let nessunRiferimento = "Nessuno"
    static let nessunISIN = "Nessun ISIN con quote in archivio: importa le quote per sceglierne il riferimento."
    static let datiGruppo = "Dati importati e a mano"
    static let datiNota = "Quote dei fondi per ISIN, indici e tutto ciò che non arriva da BCE ed Eurostat."
    static let unitaPunti = "punti"
    static let unitaGiorni = "giorni"
}

extension TestiAppMercato {
    static let messaggioNonPreparato = "Il messaggio non si è potuto preparare: il cliente non è più in Prisma."
    static func scaricate(_ n: Int) -> String { n == 1 ? "1 serie aggiornata da BCE ed Eurostat" : "\(n) serie aggiornate da BCE ed Eurostat" }
    /// La fonte non risponde: i valori restano quelli di prima, niente errore a tutta finestra (§12.1.9).
    static func erroreScaricamento(scaricate: Int, errori: Int) -> String {
        scaricate == 0
            ? "BCE ed Eurostat non rispondono: restano i valori di prima. I dettagli in Impostazioni › Mercato."
            : (errori == 1 ? "1 serie non è arrivata" : "\(errori) serie non sono arrivate")
                + ": restano i valori di prima. I dettagli in Impostazioni › Mercato."
    }
}

extension TestiAppMercato {
    static let chiudi = "Chiudi"
}

extension TestiAppMercato {
    static let fine = "Fine"
}

extension TestiAppMercato {
    static let isinInvito = "12 caratteri, come nel KID o nell'estratto conto"
}
