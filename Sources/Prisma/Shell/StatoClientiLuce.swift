import SwiftUI

// Le viste nuove di Clienti (Rubrica · Potenziali · Passaparola) e di Messaggi (Messaggi · Campagne) di «Luce» giro 12
// (Design/template-luce-specifica.md §9 parte comune, §9.2, §9.4), e lo stato in memoria delle tre viste: oggetti a
// parte, così trascinare una scheda o scegliere un gruppo non pubblica StatoShell. Non si salvano.

/// La vista di Clienti.
enum VistaClienti: String, CaseIterable, Identifiable, Hashable {
    case rubrica, potenziali, passaparola

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .rubrica: return "Rubrica"
        case .potenziali: return "Potenziali"
        case .passaparola: return "Passaparola"
        }
    }

    /// La voce del pannello Novità che porta qui.
    var novita: NovitaLuce? {
        switch self {
        case .rubrica: return nil
        case .potenziali, .passaparola: return .passaparola
        }
    }
}

/// La vista di Messaggi.
enum VistaMessaggi: String, CaseIterable, Identifiable, Hashable {
    case messaggi, campagne

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .messaggi: return "Messaggi"
        case .campagne: return "Campagne"
        }
    }
}

/// Lo stato in memoria di Potenziali e Passaparola. Il dettaglio aperto non sta qui: è lo `StatoDettaglio` della vista
/// Potenziali (come in Pratiche › Dopo la firma).
@Observable final class StatoPotenziali {
    /// L'ambasciatore evidenziato nell'albero (gli altri rami al 30%).
    var evidenziato: String?
    /// La scheda che si sta trascinando.
    var trascinato: String?
    /// La scheda scelta con la tastiera.
    var scelto: String?
    /// Il modulo di un potenziale (nuovo o da modificare); nil = chiuso.
    var modulo: PotenzialeCliente?
    /// Il potenziale da eliminare (conferma).
    var daEliminare: String?
    /// I momenti giusti con il messaggio già preparato («✓ Messaggio pronto»).
    var richiestaPronta: Set<String> = []
    /// Le occasioni delle richieste preparate (momento → id dell'occasione): «✓» solo se il messaggio esiste.
    var occasioniRichieste: [String: String] = [:]
    /// Solo per le istantanee: il potenziale con il dettaglio già aperto.
    @ObservationIgnored var dettaglioIstantanea: String?
}

/// Lo stato in memoria di Messaggi › Campagne.
@Observable final class StatoCampagne {
    /// Il gruppo scelto (`GruppoCampagna.id`).
    var gruppo: String?
    /// I pallini radunati nei gruppi (dopo l'attesa); nelle istantanee e con «Riduci movimento» subito.
    var radunati = false
    /// I clienti tolti a mano dall'invio (per gruppo: id del gruppo + id del cliente).
    var esclusi: Set<String> = []
    /// I clienti inclusi a mano (senza consenso, già contattati), con la conferma.
    var inclusiAMano: Set<String> = []
    /// Gli orari tolti dalle chip.
    var chipTolti: Set<Date> = []
    /// Il cliente dell'anteprima.
    var anteprima: String?
    /// La campagna appena avviata (id), finché si resta sul gruppo.
    var avviata: String?
    /// I messaggi che Vera sta riscrivendo (uno alla volta).
    var inScrittura: Set<String> = []
    var tono = TonoMessaggio.cordiale
    var canale = CanaleMessaggio.mail
    /// La firma scelta con i canali misti (nil = da scegliere).
    var firmaCanale: Canale?
    /// La richiesta di conferma (includere senza consenso, aprire tutte).
    var conferma: ConfermaCampagna?
    /// Il compito di Vera che riscrive (interrompibile).
    @ObservationIgnored var compitoVera: Task<Void, Never>?

    /// La chiave di un cliente in un gruppo (le scelte valgono per gruppo).
    static func chiave(_ gruppo: String, _ cliente: String) -> String { gruppo + "|" + cliente }

    /// Torna allo stato di partenza quando si cambia gruppo.
    func scegli(_ id: String?) {
        guard gruppo != id else { return }
        gruppo = id
        anteprima = nil
        avviata = nil
        chipTolti = []
        firmaCanale = nil
    }
}

/// Una conferma chiesta dal pannello della campagna.
enum ConfermaCampagna: Identifiable, Equatable {
    case includi(cliente: String)
    case apriTutte(campagna: String, quante: Int)

    var id: String {
        switch self {
        case .includi(let c): return "includi-" + c
        case .apriTutte(let c, _): return "tutte-" + c
        }
    }
}

extension StatoShell {
    /// Clienti › Potenziali (non in modalità cliente: mostra persone che non sono il cliente).
    func apriPotenziali() {
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente i potenziali clienti non si aprono: si vede solo il dossier del cliente.")
            return
        }
        vistaClienti = .potenziali
        apri(.clienti)
    }

    /// Clienti › Passaparola.
    func apriPassaparola() {
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente il passaparola non si apre: mostra gli altri clienti.")
            return
        }
        vistaClienti = .passaparola
        apri(.clienti)
    }

    /// Messaggi › Campagne, sul gruppo del tipo dato se c'è (nil = il primo).
    func apriCampagne(_ tipo: TipoGruppoCampagna?) {
        guard !inModoCliente else {
            // `apri` dice perché in modalità cliente Messaggi non si apre
            apri(.messaggi)
            return
        }
        vistaMessaggi = .campagne
        if let tipo {
            campagne.scegli(gruppiCampagne().first { $0.tipo == tipo }?.id)
        }
        apri(.messaggi)
    }
}
