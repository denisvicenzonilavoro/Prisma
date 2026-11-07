import Foundation

// Ciò che la scrivania del tema Apple chiede allo stato (Design/template-apple-specifica.md §3.6), oltre alla
// mossa del giorno (StatoMossaDelGiorno.swift): i tre anelli del Portafoglio clienti e le domande suggerite a Vera.
// Tutto viene dalle cache e dai motori di Prisma: nessuna cifra scritta a mano.

/// Una domanda suggerita sulla scrivania: il testo della capsula e di chi parla (tutto il portafoglio o un cliente).
struct DomandaScrivania: Identifiable, Equatable {
    enum Ambito: Equatable {
        case portafoglio(SpuntoPortafoglio)
        case cliente(id: String, spunto: SpuntoVera)
    }

    let testo: String
    let ambito: Ambito

    var id: String { testo }
}

/// Il riquadro di Vera: la frase e le domande suggerite.
struct SuggerimentiVeraScrivania: Equatable {
    let frase: String
    let domande: [DomandaScrivania]
}

extension StatoShell {
    /// I tre anelli dei clienti visibili (in modalità cliente solo il suo). La conformità viene dalla cache delle
    /// notifiche; il resto è un conteggio leggero. Lo chiede il riquadro, che si ridisegna solo con una `ChiaveVista` nuova.
    /// Per oggi tenuto da parte come la mossa del giorno (stessa chiave, per un'ora); per un altro giorno calcolato.
    func statoDelLavoro(oggi: Date = Date()) -> StatoDelLavoro {
        let calcola = {
            MotoreStatoDelLavoro.calcola(clienti: self.clienti, posizioni: self.posizioni, appuntamenti: self.appuntamenti,
                                         incontri: self.dati.incontri, conformita: self.conformitaClienti(oggi: oggi), oggi: oggi)
        }
        guard Calendar.current.isDateInToday(oggi) else { return calcola() }
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.statoDelLavoro, c.ora == ora { return c.valore }
        let v = calcola()
        d.statoDelLavoro = (ora, v)
        return v
    }

    /// La frase di Vera e due o tre domande, dagli incontri di oggi e dalla mossa del giorno.
    func suggerimentiVeraScrivania(oggi: Date = Date()) -> SuggerimentiVeraScrivania {
        let diOggi = appuntamentiDiOggi.sorted { $0.inizio < $1.inizio }
        let primo = diOggi.lazy.compactMap { self.cliente($0.clienteId) }.first
        let mossa = mossaDelGiorno(oggi: oggi).mossa
        let quanti = diOggi.count

        // La frase: solo ciò che dicono l'agenda e la mossa
        let frase: String
        if quanti > 0, let c = primo {
            frase = quanti == 1
                ? "Oggi hai un incontro con \(c.nome): vuoi un riepilogo?"
                : "Oggi hai \(quanti) incontri. Vuoi partire da \(Self.nomeBreve(c))?"
        } else if quanti > 0 {
            frase = quanti == 1 ? "Oggi hai un impegno in agenda. Vuoi vedere la settimana?" : "Oggi hai \(quanti) impegni in agenda. Vuoi vedere la settimana?"
        } else if let m = mossa {
            frase = "Oggi niente incontri in agenda. Partirei da \(Self.nomeBreve(m.cliente)): vuoi un riepilogo?"
        } else {
            frase = inModoCliente ? "Chiedimi del dossier: ti mostro le cifre di Prisma."
                                  : "Oggi niente incontri in agenda. Vuoi il quadro del portafoglio?"
        }

        // Le domande: il portafoglio (non in modalità cliente) e il cliente da cui partire
        var domande: [DomandaScrivania] = []
        if !inModoCliente {
            domande.append(DomandaScrivania(testo: SpuntoPortafoglio.settimana.domanda, ambito: .portafoglio(.settimana)))
        }
        let protagonista = primo ?? mossa?.cliente ?? (inModoCliente ? clienteAttivo : nil)
        if let c = protagonista {
            domande.append(DomandaScrivania(testo: "Riepilogo di \(Self.nomeBreve(c))", ambito: .cliente(id: c.id, spunto: .riepilogo)))
        }
        if let m = mossa, m.cliente.id != protagonista?.id {
            domande.append(DomandaScrivania(testo: "Prepara l'incontro con \(Self.nomeBreve(m.cliente))",
                                            ambito: .cliente(id: m.cliente.id, spunto: .incontro)))
        } else if !inModoCliente {
            domande.append(DomandaScrivania(testo: SpuntoPortafoglio.ricontattare.domanda, ambito: .portafoglio(.ricontattare)))
        } else if let c = protagonista {
            domande.append(DomandaScrivania(testo: "Cosa scade?", ambito: .cliente(id: c.id, spunto: .scadenze)))
        }
        return SuggerimentiVeraScrivania(frase: frase, domande: Array(domande.prefix(3)))
    }

    /// Un suggerimento della scrivania: apre Vera sulla scrivania (la pagina a destra, VeraScrivania.swift) su chi
    /// riguarda la domanda e la manda dopo 0,7 s, quando la pagina è arrivata (subito con «Riduci movimento»).
    func chiediDallaScrivania(_ d: DomandaScrivania) {
        guard appConsentita(.vera), !veraInCorso else { return }
        switch d.ambito {
        case .portafoglio:
            guard !inModoCliente else { return }
            if !veraPortafoglio { veraPortafoglio = true }
        case .cliente(let id, _):
            if veraPortafoglio { veraPortafoglio = false }
            if clienteAttivoId != id { clienteAttivoId = id }
        }
        #if os(iOS)
        // Su iPhone e iPad Vera non ha la pagina a destra della scrivania: la domanda va nella sua app
        apri(.vera)
        #else
        mostraVeraScrivania()
        #endif
        let attesa = Movimenti.calmo ? 0 : Tema.Apple.Scrivania.Vera.attesaDomanda
        DispatchQueue.main.asyncAfter(deadline: .now() + attesa) { [weak self] in
            guard let self else { return }
            switch d.ambito {
            case .portafoglio(let spunto):
                self.chiediVeraPortafoglio(spunto.domanda, spunto: spunto)
            case .cliente(_, let spunto):
                self.chiediVera(spunto.domanda, spunto: spunto)
            }
        }
    }

    /// Il nome proprio del cliente (la prima parola), per le frasi brevi.
    static func nomeBreve(_ c: Cliente) -> String {
        c.nome.split(separator: " ").first.map(String.init) ?? c.nome
    }
}
