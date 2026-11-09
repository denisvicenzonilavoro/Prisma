import SwiftUI

// Le novità (Design/template-luce-specifica.md §1.1; prima Design/template-novita-specifica.md §1.1, §1.2, §3.1, §4):
// la pillola «✦ Novità» della barra, il pannello «Le novità» e dove porta ogni voce. Dalla versione «Luce» il pannello
// mostra le 29 novità di Luce (NovitaLuce.swift); le undici di Orizzonte non ci sono più (decisione 116) e restano
// qui solo come elenco di dove vivono quelle funzioni. Il pannello si apre da solo una volta, al primo ingresso dopo
// l'aggiornamento (`Impostazioni.novitaViste` = «luce»), poi resta raggiungibile dalla pillola, dalla Guida di Prisma
// e dal menu Aiuto.

/// Le undici funzioni nuove di «Orizzonte», nell'ordine del pannello (testi del template, §1.2).
/// Le cifre e i dati non stanno qui: ogni voce porta all'app che la ospita, dove i motori danno i numeri.
enum NovitaOrizzonte: String, CaseIterable, Identifiable {
    case studio, scrivePerTe, mercato, ovunque, copilota, inquadra, provaDelFuoco, lineaDellaVita
    case trackRecord, famiglieComeLaSua, allenamentoOCF

    /// La versione delle novità: `Impostazioni.novitaViste` la ricorda dopo la prima apertura.
    static let versione = "orizzonte"

    var id: String { rawValue }

    /// Il numero nel pallino (1…11).
    var numero: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }

    var titolo: String {
        switch self {
        case .studio: return "Studio"
        case .scrivePerTe: return "Prisma scrive per te"
        case .mercato: return "Prisma conosce il mercato"
        case .ovunque: return "Prisma ovunque"
        case .copilota: return "Il copilota dell’incontro"
        case .inquadra: return "Inquadra e capisci"
        case .provaDelFuoco: return "La prova del fuoco"
        case .lineaDellaVita: return "La linea della vita"
        case .trackRecord: return "Il tuo track record"
        case .famiglieComeLaSua: return "Rispetto alle famiglie come la sua"
        case .allenamentoOCF: return "Allenamento OCF"
        }
    }

    var frase: String {
        switch self {
        case .studio: return "Il cruscotto del tuo lavoro: ricavi, obiettivi, proposte, incassi"
        case .scrivePerTe: return "Vera prepara i messaggi ai clienti, li spedisci tu"
        case .mercato: return "Quote e tassi aggiornati, avvisi, chi è toccato"
        case .ovunque: return "Una copia cifrata su iPhone e iPad, anche senza il Mac"
        case .copilota: return "Prisma ascolta e capisce mentre parli col cliente"
        case .inquadra: return "La polizza letta dalla fotocamera dell’iPhone"
        case .provaDelFuoco: return "Uno scenario, tutto il portafoglio ricalcolato"
        case .lineaDellaVita: return "Trascini gli eventi, il futuro si ricalcola"
        case .trackRecord: return "Le raccomandazioni e come sono andate"
        case .famiglieComeLaSua: return "Il cliente confrontato con chi gli somiglia"
        case .allenamentoOCF: return "Domande, ripasso e casi veri di Prisma"
        }
    }

    /// L'app che ospita la funzione: la voce del pannello porta lì (anche quando la funzione arriva in un giro
    /// successivo, porta all'app che la ospiterà).
    var app: AppPrisma {
        switch self {
        case .studio, .trackRecord, .allenamentoOCF: return .studio
        case .scrivePerTe: return .messaggi
        case .mercato: return .mercato
        case .ovunque: return .impostazioni
        case .copilota: return .incontri
        case .inquadra, .provaDelFuoco: return .posizioni
        case .lineaDellaVita: return .clienti
        case .famiglieComeLaSua: return .analisi360
        }
    }

    /// Dove vivrà la funzione, con le parole dell'interfaccia (per l'avviso e per VoiceOver).
    var dove: String {
        switch self {
        case .studio: return "Studio › Cruscotto"
        case .scrivePerTe: return "Messaggi"
        case .mercato: return "Mercato"
        case .ovunque: return "Impostazioni › iPhone e iPad"
        case .copilota: return "Incontri"
        case .inquadra: return "Posizioni, con l’iPhone"
        case .provaDelFuoco: return "Posizioni › La prova del fuoco"
        case .lineaDellaVita: return "Clienti, nel dossier: Linea della vita"
        case .trackRecord: return "Studio › Track record"
        case .famiglieComeLaSua: return "Analisi 360 › Rispetto alle famiglie come la sua"
        case .allenamentoOCF: return "Studio › Esame OCF"
        }
    }

    /// Vero per le funzioni già in Prisma (il cruscotto e il track record di Studio, Messaggi). Le altre arrivano nei
    /// giri successivi: la voce apre l'app che le ospiterà e un avviso dice che arrivano più avanti.
    var disponibile: Bool { self == .studio || self == .trackRecord || self == .scrivePerTe || self == .lineaDellaVita
        || self == .provaDelFuoco || self == .inquadra || self == .copilota || self == .mercato
        || self == .famiglieComeLaSua || self == .allenamentoOCF || self == .ovunque }

    /// La scheda di Studio su cui si apre la voce (nil per le voci delle altre app).
    var schedaStudio: SchedaStudio? {
        switch self {
        case .studio: return .cruscotto
        case .trackRecord: return .track
        case .allenamentoOCF: return .ocf
        default: return nil
        }
    }

    /// L'avviso per una funzione che arriva più avanti (nil se c'è già, o se l'app stessa lo dice: le schede di Studio
    /// che non ci sono ancora hanno la loro nota).
    var avvisoInArrivo: String? {
        guard !disponibile, app != .messaggi, app != .mercato, app != .studio else { return nil }
        return "«\(titolo)» arriva con un prossimo aggiornamento: vivrà in \(dove)."
    }
}

extension StatoShell {
    /// Il pannello «Le novità» è aperto.
    var pannelloNovita: Bool {
        get { sistema.pannelloNovita }
        set { sistema.pannelloNovita = newValue }
    }

    /// La pillola «✦ Novità»: apre il pannello o lo chiude se è aperto.
    func alternaNovita() {
        if sistema.pannelloNovita { chiudiNovita() } else { apriNovita() }
    }

    /// Apre il pannello: chiude notifiche, spazi, app aperte, ricerca e guida (un pannello alla volta, come in
    /// macOS). Mai sotto la schermata di benvenuto, durante la presentazione o in modalità cliente (le voci portano
    /// anche a Studio e Messaggi, che parlano di tutti i clienti). Aprirlo segna le novità come viste.
    func apriNovita() {
        guard !bloccato, presentazione == nil, !inModoCliente else { return }
        // Senza animazione nello stato: il contenitore di ShellView anima l'entrata (come la guida)
        withTransaction(Transaction(animation: nil)) {
            if pannelloNotifiche { pannelloNotifiche = false }
            if pannelloSpazi { pannelloSpazi = false }
            if pannelloAppAperte { pannelloAppAperte = false }
            chiudiRicerca()
            if sistema.guida != nil { sistema.guida = nil }
            if !sistema.pannelloNovita { sistema.pannelloNovita = true }
        }
        segnaNovitaViste()
    }

    /// Dal menu Aiuto e dalla Guida di Prisma: come la pillola, ma con la schermata di benvenuto davanti prima sblocca
    /// (come `apriGuida`), e in modalità cliente dice perché non si apre.
    func apriNovitaDaMenu() {
        guard presentazione == nil else { return }
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente le novità non si aprono: portano anche ad app che parlano di tutti i clienti.")
            return
        }
        if bloccato {
            sblocca()
            // Nelle istantanee e nelle prove lo sblocco è di colpo: si apre subito
            guard persistente else {
                apriNovita()
                return
            }
            Movimenti.dopo(Tema.Moto.Sblocco.durataEntrata) { [weak self] in
                guard let self, !self.bloccato else { return }
                self.apriNovita()
            }
            return
        }
        apriNovita()
    }

    /// Chiude il pannello (Esc, clic fuori, una voce scelta): sparisce subito, come nel template.
    func chiudiNovita() {
        guard sistema.pannelloNovita else { return }
        withTransaction(Transaction(animation: nil)) { sistema.pannelloNovita = false }
    }

    /// Una voce del pannello: chiude Novità e notifiche e apre l'app che ospita la funzione. Se la funzione arriva
    /// in un giro successivo, un avviso lo dice e dice dove vivrà.
    func apriVoceNovita(_ voce: NovitaOrizzonte) {
        chiudiNovita()
        if pannelloNotifiche { pannelloNotifiche = false }
        guard appConsentita(voce.app) else {
            // `apri` dice perché in modalità cliente non si apre
            apri(voce.app)
            return
        }
        if let scheda = voce.schedaStudio {
            apriStudio(scheda)
        } else if voce == .lineaDellaVita {
            // Il dossier del cliente attivo sulla scheda «Linea della vita» (giro 4)
            schedaCliente = .lineaVita
            apriApp(voce.app)
        } else if voce == .scrivePerTe {
            // Messaggi sulla prima occasione, senza avvisi (CollegamentiMessaggi.swift)
            preparaMessaggio()
        } else if voce == .copilota {
            // Incontri sul passo «Ascolto», con il copilota dell'incontro (giro 5, CopilotaIncontro.swift)
            copilota.modo = .copilota
            schedaIncontro = .ascolto
            apriApp(voce.app)
        } else if voce == .inquadra {
            // Posizioni › Portafoglio, poi la scena di Inquadra e capisci (giro 5, StatoInquadra.swift)
            apriInquadraDaNovita()
        } else if voce == .ovunque {
            // Impostazioni già sulla sezione «iPhone e iPad» (giro 8, ImpostazioniOvunque.swift)
            schedaImpostazioni = .ovunque
            apriApp(voce.app)
        } else if voce == .famiglieComeLaSua {
            // Analisi 360 sulla vista «Rispetto alle famiglie come la sua» (giro 6, FamiglieComeLaSua.swift)
            apriFamiglieComeLaSua()
        } else if voce == .provaDelFuoco {
            // Posizioni › Portafoglio sulla vista «Prova del fuoco» (giro 4, ProvaDelFuocoApple.swift)
            apriProvaDelFuoco()
        } else {
            apriApp(voce.app)
        }
        if let avviso = voce.avvisoInArrivo { mostraAvviso(avviso) }
    }

    /// Una voce del pannello di «Luce»: chiude Novità e notifiche e porta dove vive (o vivrà) la funzione. Le
    /// esperienze aprono la Sala sul loro palco, sul cliente attivo (senza cliente la griglia dice di sceglierlo);
    /// Pratiche si apre sulla scheda giusta; «La tua settimana» e «Stanotte» stanno sopra la scrivania. Le funzioni che
    /// arrivano con un giro successivo lo dicono con un avviso (o con la schermata «in arrivo» della loro app).
    func apriVoceNovita(_ voce: NovitaLuce) {
        chiudiNovita()
        if pannelloNotifiche { pannelloNotifiche = false }
        if voce == .settimanaAnno {
            // La storia della settimana sopra la scrivania (giro 5, StoriaLuce.swift)
            mostraScrivania()
            apriStoria(.settimana)
            return
        }
        guard let app = voce.app else {
            mostraScrivania()
            if let avviso = voce.avvisoInArrivo { mostraAvviso(avviso) }
            return
        }
        guard appConsentita(app) else {
            // `apri` dice perché in modalità cliente non si apre
            apri(app)
            return
        }
        if let e = voce.esperienza {
            // Le esperienze della Sala sul loro palco (giro 4: luce, disegno, rischio, giornata; giro 8: la lettera dal
            // futuro, Lancia l'anno, Quanto vale avermi accanto)
            apriEsperienza(e)
        } else if let scheda = voce.schedaPratiche {
            // Pratiche sulla scheda della voce: Proposta e Dopo la firma (giro 3), Moduli con «Compila da solo» (giro 10)
            apriPratiche(scheda)
        } else if voce == .territorio {
            apriTerritorio(.oggi)
        } else if voce == .radar {
            // Posizioni › Radar (giro 2, RadarPortafoglio.swift)
            apriRadar()
        } else if voce == .smontaggio {
            // Posizioni › Smontaggio (giro 2, SmontaggioApple.swift)
            apriSmontaggio()
        } else if voce == .traguardi {
            // Messaggi sul primo traguardo da festeggiare (giro 5, PannelloTraguardo.swift)
            apriTraguardo(nil, clienteId: nil)
        } else if voce == .palestra {
            // Studio › Palestra (giro 5, StudioPalestra.swift)
            apriStudio(.palestra)
        } else if voce == .speseScadenze {
            // Studio › Spese (giro 9, StudioSpese.swift)
            apriStudio(.spese)
        } else if voce == .trovaLaPagina {
            // La Biblioteca con la domanda pronta (giro 6, AppBiblioteca.swift): i documenti a sinistra, la domanda in alto
            apriBibliotecaTrovaPagina()
        } else if voce == .imprenditori {
            // Il dossier del primo cliente con un'azienda, sulla scheda «L'azienda» (giro 7, DossierAzienda.swift)
            apriClientiImprenditori()
        } else if voce == .passaparola {
            // Clienti › Passaparola (giro 12, ClientiPassaparola.swift)
            apriPassaparola()
        } else if voce == .campagne {
            // Messaggi › Campagne sul primo gruppo (giro 12, MessaggiCampagne.swift)
            apriCampagne(nil)
        } else if voce == .nuovoCliente {
            // Clienti, poi la scena della carta d'identità (giro 13, NuovoClienteShell.swift)
            apriNuovoClienteDaNovita()
        } else if voce == .notaVocale {
            // Incontri, poi «Come funziona» della nota vocale (giro 13, NotaVocaleShell.swift)
            apriNotaVocaleDaNovita()
        } else if app == .studio {
            apriStudio(.cruscotto)
        } else {
            apriApp(app)
        }
        if let avviso = voce.avvisoInArrivo { mostraAvviso(avviso) }
    }

    /// Ricorda che le novità di questa versione sono state viste: il pannello non si riapre più da solo.
    /// Mai nelle istantanee, nelle prove o in sola lettura.
    func segnaNovitaViste() {
        guard persistente, !solaLettura, dati.impostazioni.novitaViste != NovitaLuce.versione else { return }
        dati.impostazioni.novitaViste = NovitaLuce.versione
    }

    /// Dopo lo sblocco (con l'introduzione già vista): se le novità di questa versione non sono ancora state viste,
    /// il pannello si apre da solo 1,7 s dopo lo sblocco (`Tema.Apple.Moto.PannelloNovita.aperturaAutomatica`,
    /// contati dall'inizio dello sblocco), solo sul Mac e solo se nel frattempo non si è aperto altro.
    func proponiNovitaDopoSblocco() {
        #if os(macOS)
        guard persistente, !solaLettura, dati.impostazioni.novitaViste != NovitaLuce.versione else { return }
        let attesa = max(0, Tema.Apple.Moto.PannelloNovita.aperturaAutomatica - Tema.Moto.Sblocco.durataEntrata)
        Movimenti.dopo(attesa) { [weak self] in
            guard let self, !self.bloccato, self.presentazione == nil, !self.inModoCliente,
                  self.sistema.guida == nil, !self.pannelloRicerca, !self.pannelloSpazi, !self.pannelloAppAperte,
                  !self.sistema.pannelloNovita,
                  self.dati.impostazioni.novitaViste != NovitaLuce.versione else { return }
            self.apriNovita()
        }
        #endif
    }
}
