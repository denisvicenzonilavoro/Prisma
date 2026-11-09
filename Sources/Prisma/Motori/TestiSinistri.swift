import Foundation

// I testi di Pratiche › Sinistri («Luce» giro 15, §7.4): barra, spedizione, card, telefono «Così lo vede …», modulo,
// notifica e occasione di Messaggi. Mai «in tempo reale» (decisione 10): il cliente vede lo stato quando riceve il
// messaggio o il file nuovo, e il telefono è un'anteprima sul Mac.

enum TestiSinistri {
    static let titoloBarra = "Sinistri aperti e recenti"
    static let nuovo = "+ Nuovo sinistro"
    static let nessunoAperto = "Nessun sinistro aperto"
    static let fraseVuota = "Quando un cliente ha un sinistro, lo segui qui come una spedizione."
    static let notaVuota = "Prisma non è collegato alla compagnia: ogni fase, data e importo li segni tu."
    /// Decisione 36: la nota fissa sotto i campi di testo.
    static let notaBreve = "Scrivi solo fatti brevi: niente diagnosi né referti (i referti vanno nei Documenti)"
    static let polizzaDaCollegare = "polizza da collegare"
    static let stato = "Stato"
    static let indennizzo = "Indennizzo"
    static let apertoDa = "Aperto da"
    static let cosaESuccesso = "Cosa è successo"
    static let documenti = "Documenti"
    static let aggiungi = "+ Aggiungi"
    static let nessunFatto = "Nessun fatto ancora: aggiungi il primo."
    static let nessunDocumento = "Nessun documento richiesto. Trascina qui un file: va nei Documenti del cliente."
    static let trascinaQui = "Trascina un file su un documento: va nei Documenti del cliente e risulta ricevuto."
    static let sollecita = "Sollecita la compagnia"
    static let promemoriaPortale = "Promemoria: sollecita dal portale"
    static let mettiInAgenda = "Mettilo in Agenda"
    static let sollecitoPronto = "Sollecito alla compagnia pronto da mandare: lo controlli e lo spedisci tu"
    static let promemoriaCreato = "Promemoria nelle attività: sollecita dal portale della compagnia"
    static let attivitaCreata = "Attività in Agenda per il cliente"
    static let senzaIndirizzo = "Scrivi l'indirizzo dei sinistri della compagnia in Impostazioni › Pratiche"
    static let datiDiProva = "dati di prova"
    static let nonPiuNeiDocumenti = "non più nei Documenti"
    static let fermo = "fermo"

    /// «Aggiorna Marco».
    static func aggiorna(_ nome: String) -> String { "Aggiorna \(nome)" }
    /// «Così lo vede Marco».
    static func cosiLoVede(_ nome: String) -> String { "Così lo vede \(nome)" }
    /// «Il Prisma di Marco».
    static func ilPrismaDi(_ nome: String) -> String { "Il Prisma di \(nome)" }
    /// «Aggiornato da Denis · 29 ott».
    static func aggiornatoDa(_ consulente: String, il data: Date) -> String {
        "Aggiornato da \(consulente) · \(Formati.giornoMeseBreve.string(from: data))"
    }
    /// «Gli aggiornamenti per Marco sono spenti».
    static func aggiornamentiSpenti(_ nome: String) -> String { "Gli aggiornamenti per \(nome) sono spenti" }
    static let comeAccenderli = "Accendili nel sinistro con «Il cliente riceve gli aggiornamenti»: il messaggio lo prepari tu, Prisma non spedisce niente."
    static let anteprima = "Un'anteprima sul Mac: il cliente vede lo stato quando riceve il messaggio o il suo file."
    static let riceveAggiornamenti = "Il cliente riceve gli aggiornamenti"
    static let mostraImporto = "Mostra l'importo pagato"

    /// «Aggiornamento per Marco pronto in Messaggi», con la nota del file se il blocco del sinistro c'è.
    static func aggiornamentoPronto(_ nome: String, nelFile: Bool) -> String {
        nelFile ? "Aggiornamento per \(nome) pronto in Messaggi: lo vedrà anche nel suo Prisma quando rifai il file"
            : "Aggiornamento per \(nome) pronto in Messaggi: lo controlli e lo mandi tu"
    }

    /// «18 giorni», «1 giorno», «oggi».
    static func giorni(_ n: Int) -> String {
        n <= 0 ? "oggi" : (n == 1 ? "1 giorno" : "\(n) giorni")
    }

    /// «titolo · fase» della voce della barra.
    static func voce(_ s: Sinistro) -> String { "\(s.titolo) · \(s.fase.nome)" }

    /// Il fatto che entra in «Cosa è successo» quando il sinistro passa a una fase.
    static func fattoDellaFase(_ f: FaseSinistro, pagato: Double?) -> String {
        switch f {
        case .denuncia: return "Denuncia inviata alla compagnia"
        case .documenti: return "Documenti in raccolta"
        case .perizia: return "Perizia"
        case .liquidazione: return "Liquidazione approvata"
        case .pagato: return pagato.map { "Pagati \(Formati.euro($0))" } ?? "Indennizzo pagato"
        case .respinto: return "La compagnia ha respinto il sinistro"
        }
    }

    // MARK: Messaggi

    /// «Aggiornamento: «Infortunio di Pietro»».
    static func titoloOccasione(_ s: Sinistro) -> String { "Aggiornamento sul sinistro «\(s.titolo)»" }
    /// «Fase: Perizia».
    static func percheOccasione(_ s: Sinistro) -> String { "Fase: \(s.fase.nome)" }
    /// L'oggetto della mail (senza numeri di polizza né di sinistro).
    static func oggettoOccasione(_ s: Sinistro) -> String { "Il sinistro «\(s.titolo)»: a che punto siamo" }

    // MARK: Notifica

    /// «Sinistro fermo da 16 giorni» o «3 sinistri fermi».
    static func titoloNotifica(quanti: Int, giorni: Int) -> String {
        quanti == 1 ? "Sinistro fermo da \(giorni) giorni" : "\(quanti) sinistri fermi"
    }

    // MARK: Agenda

    /// Il titolo dell'attività nata da un fatto con data futura.
    static func titoloAttivita(_ fatto: String, sinistro: String) -> String { "\(fatto) (sinistro «\(sinistro)»)" }
    static func titoloPromemoriaPortale(_ s: Sinistro) -> String { "Sollecita dal portale il sinistro «\(s.titolo)»" }

    // MARK: Modulo

    static let titoloModulo = "Nuovo sinistro"
    static let titoloModifica = "Modifica il sinistro"
    static let nessunaPolizza = "Nessuna polizza (da collegare)"
    static let tipo = "Tipo di sinistro"
    static let nessunTipo = "Nessun elenco di documenti"
    static let notaTipi = "Gli elenchi dei documenti per tipo li scrivi tu in Impostazioni › Pratiche."

    // MARK: Dossier

    /// «Sinistri aperti: 1 · Perizia ›».
    static func rigaDossier(aperti: Int, fase: FaseSinistro?) -> String {
        guard aperti > 0 else { return "Nessun sinistro aperto · Pratiche ›" }
        return "Sinistri aperti: \(aperti)" + (fase.map { " · \($0.nome)" } ?? "") + " ›"
    }
    static let apriUnSinistro = "Apri un sinistro…"
}
