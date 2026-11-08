import Foundation
import Observation
import SwiftUI

// «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1, «Luce» giro 13): lo stato della scena.
// - Sul Mac il pulsante «Nuovo cliente» della testata di Clienti (o ⌘N, o la voce 10 delle Novità) apre la scena del
//   telefono (`SovrapposizioneLuce.scena(.cartaIdentita)`): con il ponte acceso si aspetta la carta dall'iPhone, altrimenti
//   si trascina una foto o un PDF del documento, letti sul Mac con Vision. Fronte e retro si sommano.
// - I campi letti (MotoreCartaIdentita) compaiono a cascata nella scheda «Prisma sul Mac», con il contatore del tempo vero
//   (TimelineView, niente Timer); ogni riga si corregge sul posto.
// - Tutto **solo in memoria** (decisione 25): chiudere, bloccare Prisma o mettere a riposo il Mac scarta tutto; nessun
//   campo dell'archivio. Il cliente nasce solo con «Crea il dossier».
// - Sull'iPhone lo stesso oggetto tiene il foglio letto con la fotocamera e l'invio al Mac (iOS/CartaIdentitaTelefono.swift).
// I passi della cascata sono `asyncAfter` legati al giro, come `StatoInquadra`: chiudendo a metà non fanno più nulla.

/// A che punto è la scena.
enum FaseNuovoCliente: Equatable {
    /// Il ponte è acceso: si aspetta la carta dall'iPhone (si può anche trascinare un file).
    case attesa
    /// Il ponte è spento: si trascina una foto o un PDF.
    case trascina
    /// Il Mac sta leggendo un file.
    case lettura
    /// Qualcosa si è letto (tutto o una parte).
    case letto
    /// Il riconoscimento non ha trovato niente.
    case illeggibile
}

/// Lo stato della scena (un oggetto a parte: la cascata non pubblica StatoShell).
@Observable final class StatoNuovoCliente {
    private(set) var fase: FaseNuovoCliente = .trascina
    /// Le righe lette, di tutte le facce.
    private(set) var righe: [RigaLetta] = []
    private(set) var lettura = LetturaCartaIdentita()
    /// Le correzioni scritte a mano nella scheda.
    var correzioni: [CampoCarta: String] = [:]
    /// La riga in modifica (id della riga).
    var inModifica: String?
    /// Da dove viene il testo: «iPhone di Denis», «carta.jpg».
    private(set) var origine = ""
    /// La carta del ponte in uso.
    private(set) var cartaId: String?
    /// Solo per un file trascinato sul Mac: la copia nei Documenti (decisione 38), se l'utente accende l'interruttore.
    private(set) var fileOrigine: URL?
    /// «Salva la copia del documento nei Documenti di …»: spento di base.
    var salvaCopia = false
    /// L'inizio della lettura (per il contatore) e i secondi impiegati, fermi a lettura finita.
    private(set) var inizio: Date?
    private(set) var secondiImpiegati: Double?
    /// Quante righe della scheda si vedono (la cascata) e se la lettura è finita (tile e pulsanti).
    private(set) var mostrate = 0
    private(set) var finito = false
    /// Un file trascinato sopra la scena.
    var fileSopra = false
    /// iPhone: la schermata della fotocamera è aperta; l'invio al Mac in corso e la sua ricevuta.
    var telefonoAperto = false
    var inInvio = false
    var ricevuta: RicevutaPonte?
    /// Le facce lette sul telefono (1 o 2), per «Aggiungi il retro».
    private(set) var facce = 0
    /// Ogni apertura, foglio nuovo o chiusura cambia il giro: i passi in attesa di un giro vecchio non fanno nulla.
    @ObservationIgnored private(set) var giro = 0

    /// Il numero delle righe della scheda (cinque, come il template).
    static let righeScheda = 5

    /// La lettura con le correzioni scritte a mano.
    var letturaCorretta: LetturaCartaIdentita { lettura.conCorrezioni(correzioni) }

    /// I campi accesi sulla carta disegnata: quelli letti (mai quelli scritti a mano), fino alla riga della cascata.
    var campiAccesi: Set<CampoCarta> {
        guard fase == .letto else { return [] }
        let righe = MotoreCartaIdentita.righe(lettura, correzioni: [:], oggi: Date())
        var accesi: Set<CampoCarta> = []
        for riga in righe.prefix(mostrate) where riga.stato != .mancante {
            for c in riga.campi where lettura[c] != nil { accesi.insert(c) }
        }
        return accesi
    }

    func apri(fase: FaseNuovoCliente) {
        giro += 1
        svuota()
        self.fase = fase
    }

    func chiudi() {
        giro += 1
        svuota()
        fase = .trascina
    }

    /// Torna all'attesa (o al trascinamento) dopo «Riprova».
    func ricomincia(fase: FaseNuovoCliente) {
        giro += 1
        svuota()
        self.fase = fase
    }

    private func svuota() {
        righe = []
        lettura = LetturaCartaIdentita()
        correzioni = [:]
        inModifica = nil
        origine = ""
        cartaId = nil
        fileOrigine = nil
        salvaCopia = false
        inizio = nil
        secondiImpiegati = nil
        mostrate = 0
        finito = false
        fileSopra = false
        ricevuta = nil
        inInvio = false
        facce = 0
    }

    /// Il Mac comincia a leggere un file: il giro nuovo, da passare a `mostra`. Le facce già lette restano.
    func inizioLettura(origine da: String, file: URL?) -> Int {
        giro += 1
        origine = da
        if let file { fileOrigine = file }
        if inizio == nil { inizio = Date() }
        fase = .lettura
        return giro
    }

    /// Aggiunge le righe di una faccia: la lettura si somma alla precedente (fronte e retro), poi la cascata delle righe
    /// legata al giro. Calmo, istantanea o `subito`: tutto insieme.
    func mostra(righe nuove: [RigaLetta], origine da: String, carta: String? = nil, file: URL? = nil, giroAtteso: Int? = nil,
                subito: Bool = false) {
        if let g = giroAtteso, g != giro { return }
        giro += 1
        let g = giro
        if inizio == nil { inizio = Date() }
        let letta = MotoreCartaIdentita.leggi(nuove)
        righe += nuove
        lettura = lettura.unita(con: letta)
        origine = da
        if let carta { cartaId = carta }
        if let file { fileOrigine = file }
        facce += 1
        ricevuta = nil
        guard !lettura.vuota else {
            fase = .illeggibile
            mostrate = 0
            finito = true
            secondiImpiegati = inizio.map { Date().timeIntervalSince($0) }
            return
        }
        fase = .letto
        let n = Self.righeScheda
        if subito || Movimenti.calmo {
            let tutto = {
                self.mostrate = n
                self.finito = true
                self.secondiImpiegati = self.inizio.map { Date().timeIntervalSince($0) }
            }
            if subito { tutto() } else { withAnimation(Tema.Moto.dissolvenzaCalma, tutto) }
            return
        }
        // Una seconda faccia: le righe già mostrate restano, le altre arrivano a cascata
        let gia = mostrate
        finito = false
        let m = Tema.Apple.Moto.Inquadra.self
        let primo = gia == 0 ? m.ritardoPrimo : 0
        for i in gia..<n {
            DispatchQueue.main.asyncAfter(deadline: .now() + primo + Double(i - gia) * m.passoCampo) { [weak self] in
                guard let self, self.giro == g else { return }
                withAnimation(m.accensione) { self.mostrate = i + 1 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + primo + Double(n - gia) * m.passoCampo + m.codaFatto) { [weak self] in
            guard let self, self.giro == g else { return }
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                self.finito = true
                self.secondiImpiegati = self.inizio.map { Date().timeIntervalSince($0) }
            }
        }
    }

    /// Il riconoscimento non ha letto niente. Se c'era già una faccia letta, resta quella.
    func illeggibile(origine da: String, giroAtteso: Int? = nil) {
        if let g = giroAtteso, g != giro { return }
        giro += 1
        origine = da
        if lettura.vuota {
            fase = .illeggibile
            secondiImpiegati = inizio.map { Date().timeIntervalSince($0) }
        } else {
            fase = .letto
        }
        finito = true
    }

    /// La schermata della fotocamera sull'iPhone e sull'iPad.
    func apriTelefono() {
        giro += 1
        svuota()
        fase = .attesa
        telefonoAperto = true
    }

    func chiudiTelefono() {
        giro += 1
        telefonoAperto = false
        svuota()
        fase = .trascina
    }

    /// «Aggiungi il retro» sul telefono: la lettura resta, si scatta la seconda faccia.
    func preparaRetro() {
        giro += 1
        ricevuta = nil
        fase = .attesa
    }

    /// Solo per le istantanee: il contatore fermo a un valore dichiarato (3,6) e la cascata finita.
    func fermaPerIstantanea(secondi: Double) {
        giro += 1
        let adesso = Date()
        inizio = adesso.addingTimeInterval(-secondi)
        secondiImpiegati = secondi
        mostrate = Self.righeScheda
        finito = true
    }
}
