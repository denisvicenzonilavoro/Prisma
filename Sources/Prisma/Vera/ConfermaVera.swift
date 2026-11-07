import Foundation

// La scheda di conferma unica (Vera/BRIEF.md, regola 2 «Prima di agire, conferma»; template «Fallo tu»): ogni azione
// che cambia qualcosa in Prisma (agenda, attività, note, schede dei clienti, messaggi, posizioni) Vera la propone in
// una scheda con app, titolo e dettaglio, e Prisma la esegue solo dopo «Conferma». Vera non invia, non cancella e non
// firma da sola: i messaggi restano bozze da aprire in Mail o in Messaggi. Dopo l'esecuzione «Annulla» rimette le cose
// come erano (anche uno spostamento: la scheda conserva l'appuntamento di prima).
//
// La scheda vive nel messaggio di Vera (MessaggioVera.conferma), quindi nella conversazione salvata e nei backup;
// ogni campo si legge con tolleranza.

/// La scheda di conferma: le azioni proposte da Vera e il loro stato.
struct SchedaConfermaVera: Codable, Equatable, Identifiable {
    enum Stato: String, Codable {
        /// In attesa di «Conferma».
        case daConfermare
        /// Confermata ed eseguita (anche in parte: ogni azione ha il suo esito).
        case eseguita
        /// Annullata dopo l'esecuzione: ogni azione fatta è stata disfatta.
        case annullata
        /// «Modifica»: la richiesta è tornata nel campo di scrittura, una scheda nuova prende il suo posto.
        case sostituita
        /// Rinunciata prima di eseguirla («lascia stare», oppure tutte le azioni tolte).
        case rinunciata
    }

    /// Da dove vengono le azioni.
    enum Origine: String, Codable {
        /// Riconosciute dalle regole di Prisma (i comandi di sempre: «fissa un incontro…»).
        case regole
        /// Scelte da Qwen con la chiamata di strumenti («Fallo tu»).
        case qwen
        /// «Crea attività» di «Chiedi alla tua clientela».
        case clientela
        /// «La memoria»: i ricordi che Vera propone, salvati solo dopo «Ricorda».
        case memoria
        /// «Lascia cadere qui»: un documento trascinato, da archiviare con i dati letti.
        case documento
    }

    var id = "conferma-\(UUID().uuidString.prefix(8).lowercased())"
    /// La frase del consulente da cui nasce (torna nel campo di scrittura con «Modifica»).
    var richiesta: String
    var azioni: [AzioneConferma]
    var stato = Stato.daConfermare
    var origine = Origine.regole

    init(richiesta: String, azioni: [AzioneConferma], origine: Origine) {
        self.richiesta = richiesta
        self.azioni = azioni
        self.origine = origine
    }

    /// Le azioni ancora nella scheda (quelle tolte con ✕ non si eseguono).
    var attive: [AzioneConferma] { azioni.filter { !$0.tolta } }

    /// «Sono due azioni: le faccio appena confermi.»
    var intestazione: String {
        let n = attive.count
        switch stato {
        case .daConfermare:
            if n == 0 { return "Non è rimasta nessuna azione da fare." }
            return n == 1 ? "Ecco cosa faccio, appena confermi." : "Sono \(SchedaConfermaVera.numero(n)) azioni: le faccio appena confermi."
        case .eseguita:
            let fatte = attive.filter { $0.esito?.fatta == true }.count
            if fatte == n { return n == 1 ? "Fatto." : "Fatto: \(SchedaConfermaVera.numero(n)) azioni eseguite." }
            return "Fatte \(fatte) azioni su \(n): le altre non sono riuscite."
        case .annullata: return "Annullato: tutto è tornato com'era."
        case .sostituita: return "Scheda sostituita: correggi la richiesta e la rifaccio."
        case .rinunciata: return "Lasciato stare: non ho fatto niente."
        }
    }

    /// Due, tre… fino a dieci in lettere, poi in cifre.
    static func numero(_ n: Int) -> String {
        let lettere = ["zero", "una", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove", "dieci"]
        return n < lettere.count ? lettere[n] : String(n)
    }

    private enum CodingKeys: String, CodingKey { case id, richiesta, azioni, stato, origine }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? "conferma-letta"
        richiesta = (try? c.decodeIfPresent(String.self, forKey: .richiesta)) ?? ""
        azioni = ((try? c.decodeIfPresent(ElencoTollerante<AzioneConferma>.self, forKey: .azioni)) ?? nil)?.elementi ?? []
        stato = (try? c.decodeIfPresent(Stato.self, forKey: .stato)) ?? .rinunciata
        origine = (try? c.decodeIfPresent(Origine.self, forKey: .origine)) ?? .regole
    }
}

/// Un'azione della scheda: lo strumento del registro, gli argomenti già risolti da Prisma (id dei clienti e degli
/// appuntamenti, date in ISO 8601) e quello che si vede: app, titolo e dettaglio.
struct AzioneConferma: Codable, Equatable, Identifiable {
    var id = "azione-\(UUID().uuidString.prefix(8).lowercased())"
    /// Il nome nel registro (RegistroStrumenti): «agenda_sposta_impegno», «messaggi_prepara»…
    var strumento: String
    /// L'app su cui agisce (l'icona della riga).
    var app: AppPrisma
    var titolo: String
    var dettaglio: String
    /// Gli argomenti risolti, come testo: l'esecuzione non dipende più dal modello.
    var argomenti: [String: String] = [:]
    /// Un'avvertenza da leggere prima di confermare («a quell'ora c'è già…», «Pratiche non è ancora pronta…»).
    var avviso: String?
    /// Tolta dalla scheda prima della conferma (✕ sulla riga).
    var tolta = false
    /// Quello che è successo dopo «Conferma».
    var esito: EsitoAzioneVera?

    init(strumento: String, app: AppPrisma, titolo: String, dettaglio: String, argomenti: [String: String] = [:], avviso: String? = nil) {
        self.strumento = strumento
        self.app = app
        self.titolo = titolo
        self.dettaglio = dettaglio
        self.argomenti = argomenti
        self.avviso = avviso
    }

    private enum CodingKeys: String, CodingKey { case id, strumento, app, titolo, dettaglio, argomenti, avviso, tolta, esito }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        strumento = try c.decode(String.self, forKey: .strumento)
        app = (try? c.decodeIfPresent(AppPrisma.self, forKey: .app)) ?? .vera
        titolo = (try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? ""
        dettaglio = (try? c.decodeIfPresent(String.self, forKey: .dettaglio)) ?? ""
        argomenti = (try? c.decodeIfPresent([String: String].self, forKey: .argomenti)) ?? [:]
        avviso = (try? c.decodeIfPresent(String.self, forKey: .avviso)) ?? nil
        tolta = (try? c.decodeIfPresent(Bool.self, forKey: .tolta)) ?? false
        esito = (try? c.decodeIfPresent(EsitoAzioneVera.self, forKey: .esito)) ?? nil
    }
}

/// L'esito di un'azione eseguita: cosa ha creato o cambiato, e com'era prima (per «Annulla»).
struct EsitoAzioneVera: Codable, Equatable {
    var fatta: Bool
    /// «In agenda giovedì 5 novembre alle 10:00», oppure il motivo per cui non è riuscita.
    var messaggio: String
    /// L'id dell'oggetto creato o cambiato (appuntamento, attività, nota, messaggio, posizione, cliente).
    var oggetto: String?
    /// Com'era prima (JSON dell'appuntamento spostato, valore del campo cambiato): nil per le creazioni.
    var prima: String?
    var annullata = false
}
