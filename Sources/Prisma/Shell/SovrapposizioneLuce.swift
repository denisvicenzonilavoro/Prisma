import SwiftUI

// Le sovrapposizioni a tutto palco della versione «Luce» (Design/template-luce-specifica.md §1.4.4, §1.4.5): la storia
// della settimana e dell'anno, le carte della notte, la scena del telefono (Nuovo cliente, Nota vocale) e la
// presentazione di un'esperienza della Sala. Una sola alla volta, in `StatoFinestre.sovrapposizione`; aprirne una chiude
// Novità, notifiche, spazi, ricerca e guida (un pannello alla volta). Il blocco e il riposo del Mac le chiudono tutte
// (decisione 53, al contrario del template). Ordine di Esc: storia → notte → scena del telefono → Novità →
// presentazione → dettaglio → palco della Sala → notifiche → finestra.
// Nel giro 1 c'era solo la presentazione dell'esperienza; la storia arriva con il giro 5 (StoriaLuce.swift), le altre
// con i loro giri (13, 14).

/// La storia a tutto palco (giro 5).
enum TipoStoria: String, CaseIterable {
    case settimana, anno
}

/// Il contenuto della scena del telefono disegnato (uno alla volta). Inquadra e capisci ha ancora il suo strato
/// (`StratoInquadra`); Nuovo cliente e Nota vocale arrivano con il giro 13.
enum ScenaTelefono: String, CaseIterable {
    case inquadra, cartaIdentita, notaVocale
}

/// Una sovrapposizione a tutto palco.
enum SovrapposizioneLuce: Equatable {
    case storia(TipoStoria)
    case notte
    case scena(ScenaTelefono)
    case presentazioneEsperienza(EsperienzaSala)

    /// Copre tutta la scrivania con un velo opaco: sotto l'acqua si ferma (`StatoShell.scrivaniaCoperta`).
    var coprente: Bool {
        if case .presentazioneEsperienza = self { return true }
        return false
    }

    /// L'esperienza presentata sulla sala opaca (nil per le altre sovrapposizioni).
    var esperienzaPresentata: EsperienzaSala? {
        if case .presentazioneEsperienza(let e) = self { return e }
        return nil
    }

    /// La storia aperta (nil per le altre sovrapposizioni).
    var storiaAperta: TipoStoria? {
        if case .storia(let t) = self { return t }
        return nil
    }

    /// La posizione nell'ordine di Esc (più bassa = chiusa per prima).
    var ordineEsc: Int {
        switch self {
        case .storia: return 0
        case .notte: return 1
        case .scena: return 2
        case .presentazioneEsperienza: return 4
        }
    }
}

extension StatoShell {
    /// La sovrapposizione aperta (nil = nessuna).
    var sovrapposizione: SovrapposizioneLuce? {
        get { sistema.sovrapposizione }
        set { sistema.sovrapposizione = newValue }
    }

    /// Apre una sovrapposizione: chiude prima Novità, notifiche, spazi, app aperte, ricerca e guida. Mai sotto la
    /// schermata di benvenuto né durante la presentazione dei Prospetti.
    func apriSovrapposizione(_ s: SovrapposizioneLuce) {
        guard !bloccato, presentazione == nil else { return }
        // «Luce» giro 13: la scena del nuovo cliente sostituita da un'altra non lascia i dati letti in memoria
        if sistema.sovrapposizione == .scena(.cartaIdentita), s != .scena(.cartaIdentita) { nuovoCliente.chiudi() }
        withTransaction(Transaction(animation: nil)) {
            if sistema.pannelloNovita { sistema.pannelloNovita = false }
            if pannelloNotifiche { pannelloNotifiche = false }
            if pannelloSpazi { pannelloSpazi = false }
            if pannelloAppAperte { pannelloAppAperte = false }
            chiudiRicerca()
            if sistema.guida != nil { sistema.guida = nil }
        }
        Movimenti.anima(Tema.Moto.Pannelli.presentazione, durata: Tema.Moto.Pannelli.durataPresentazione, animato: persistente) {
            sistema.sovrapposizione = s
        }
    }

    /// Chiude la sovrapposizione aperta (Esc, «Chiudi», blocco, riposo del Mac). Se la presentazione di un'esperienza
    /// aveva acceso la modalità cliente, la spegne.
    func chiudiSovrapposizione(animato: Bool = true) {
        guard let s = sistema.sovrapposizione else { return }
        // «Luce» giro 13: chiudere la scena del nuovo cliente scarta tutto ciò che si è letto
        if s == .scena(.cartaIdentita) { nuovoCliente.chiudi() }
        Movimenti.anima(Tema.Moto.Pannelli.chiusuraPresentazione, durata: Tema.Moto.Pannelli.durataChiusuraPresentazione,
                        animato: animato && persistente) {
            sistema.sovrapposizione = nil
        }
        if case .presentazioneEsperienza = s, sala.presentazioneHaAccesoModoCliente {
            sala.presentazioneHaAccesoModoCliente = false
            esciModoCliente()
        }
    }

    /// «▶︎ Presenta» nel palco della Sala: l'esperienza a tutta finestra sopra la sala opaca, con la modalità cliente
    /// (accesa qui se non lo era già, spenta alla chiusura). Sotto il velo l'acqua si ferma (decisione 123).
    func presentaEsperienza(_ e: EsperienzaSala) {
        guard !bloccato, presentazione == nil, clienteAttivo != nil else { return }
        if !inModoCliente {
            entraModoCliente(avviso: false)
            sala.presentazioneHaAccesoModoCliente = inModoCliente
        }
        apriSovrapposizione(.presentazioneEsperienza(e))
    }
}
