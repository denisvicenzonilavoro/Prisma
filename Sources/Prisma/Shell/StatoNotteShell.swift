import Foundation

// Ciò che «Stanotte Prisma ha lavorato» chiede allo stato e che serve anche ai file che compilano su iPhone e iPad
// («Luce» giro 14, §6.1, Revisione R9): la notte di oggi, il pallino, l'apertura delle carte (sul Mac; su iPhone e iPad le
// carte non ci sono e lo dice), l'apertura da sola dopo lo sblocco, il controllo del lavoro, lo stop e le impostazioni.
// I corpi solo Mac stanno dentro `#if os(macOS)`; approvazioni, «Apri ›», le due fasi del lavoro e il pianificatore in
// StatoNotteMac.swift (tutto Mac).

extension StatoShell {
    /// Il testo per iPhone e iPad (le carte non vanno sugli altri dispositivi: decisione 101).
    static let notteSoloSulMac = "Le carte della notte le trovi sul Mac."

    /// La notte da mostrare: quella del giorno servito adesso se ha già carte o lavora, altrimenti quella di oggi.
    var notteDiOggi: NotteDiLavoro? {
        let adesso = Date()
        let cal = Calendar.current
        let servito = MotoreNotte.giornoServito(adesso, inizio: dati.impostazioni.notte.inizio, cal: cal)
        if let n = MotoreNotte.notte(per: servito, in: dati.notti, cal: cal), !n.carte.isEmpty || n.esito == .inCorso { return n }
        return MotoreNotte.notte(per: cal.startOfDay(for: adesso), in: dati.notti, cal: cal)
    }

    /// Le carte da decidere (pallino e voce delle notifiche): 0 in modalità cliente, con la presentazione e fuori dal Mac.
    var carteDaDecidere: Int {
        #if os(macOS)
        guard !inModoCliente, presentazione == nil else { return 0 }
        return MotoreNotte.daDecidere(notteDiOggi)
        #else
        return 0
        #endif
    }

    /// Le carte si possono aprire adesso.
    var puoAprireNotte: Bool {
        #if os(macOS)
        return !inModoCliente && presentazione == nil && !bloccato
        #else
        return false
        #endif
    }

    /// La carta (e dove sta) nella notte di oggi.
    func cartaNotte(_ id: String) -> CartaNotte? {
        notteDiOggi?.carte.first { $0.id == id }
    }

    /// Le carte della pila di questa apertura ancora da decidere, nell'ordine (la prima è davanti).
    var carteRimanentiNotte: [CartaNotte] {
        guard let n = notteDiOggi else { return [] }
        let decise = Set(notte.registro.map(\.id))
        let perId = Dictionary(n.carte.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return notte.pila.filter { !decise.contains($0) }.compactMap { perId[$0] }
    }

    /// «☾ Stanotte», la voce di Novità e quella delle notifiche: la pila si fissa, il registro riparte vuoto, la
    /// sovrapposizione si apre. In modalità cliente e con la presentazione dice perché no.
    func apriNotte() {
        #if os(macOS)
        if inModoCliente {
            mostraAvviso(TestiNotte.avvisoModoCliente)
            return
        }
        if presentazione != nil || sistema.sovrapposizione?.coprente == true {
            mostraAvviso(TestiNotte.avvisoPresentazione)
            return
        }
        guard !bloccato else { return }
        fissaPilaNotte()
        let chiave = NotteDiLavoro.chiave(Date())
        notte.primaApertura = notte.giornoApertura != chiave
        notte.giornoApertura = chiave
        apriSovrapposizione(.notte)
        #else
        mostraAvviso(StatoShell.notteSoloSulMac)
        #endif
    }

    /// La pila di un'apertura: le carte da decidere, poi le rimandate, poi quelle di ieri. Il registro riparte vuoto.
    func fissaPilaNotte() {
        notte.pila = notteDiOggi.map { MotoreNotte.pila($0).map(\.id) } ?? []
        notte.registro = []
    }

    /// Dopo lo sblocco del mattino: le carte nuove si aprono da sole una volta (o, con il lavoro acceso e la notte saltata,
    /// la carta «Stanotte il Mac dormiva.» con «Prepara adesso»). Solo sul Mac, mai in modalità cliente; come la storia
    /// del lunedì, 1,7 s dopo lo sblocco e solo se nel frattempo non si è aperto altro.
    func proponiNotteDopoSblocco(oggi: Date = Date()) {
        #if os(macOS)
        let imp = dati.impostazioni.notte
        guard persistente, !solaLettura, imp.apriAlMattino, !inModoCliente, presentazione == nil,
              dati.impostazioni.novitaViste == NovitaLuce.versione,
              !MotoreNotte.nellaFinestra(oggi, inizio: imp.inizio) else { return }
        let cal = Calendar.current
        let giorno = cal.startOfDay(for: oggi)
        let n = MotoreNotte.notte(per: giorno, in: dati.notti, cal: cal)
        if let n, n.apertaDaSola { return }
        let daDecidere = MotoreNotte.daDecidere(n, cal: cal)
        // Senza carte nuove si apre da sola solo la notte saltata, con il lavoro acceso
        guard daDecidere > 0 || (imp.attivo && (n == nil || n?.carte.isEmpty == true) && n?.esito != .inCorso) else { return }
        let attesa = max(0, Tema.Apple.Moto.PannelloNovita.aperturaAutomatica - Tema.Moto.Sblocco.durataEntrata)
        Movimenti.dopo(attesa) { [weak self] in
            guard let self, !self.bloccato, self.presentazione == nil, !self.inModoCliente,
                  self.sistema.guida == nil, !self.pannelloRicerca, !self.pannelloSpazi, !self.pannelloAppAperte,
                  !self.sistema.pannelloNovita, self.sistema.sovrapposizione == nil else { return }
            self.segnaNotteApertaDaSola(giorno: giorno, saltata: daDecidere == 0)
            self.apriNotte()
        }
        #endif
    }

    /// Una volta sola: la notte del giorno segna «aperta da sola» (senza notte, ne nasce una «saltata»).
    func segnaNotteApertaDaSola(giorno: Date, saltata: Bool) {
        guard !solaLettura else { return }
        let chiave = NotteDiLavoro.chiave(giorno)
        var notti = dati.notti
        if let i = notti.firstIndex(where: { $0.giornoChiave == chiave }) {
            notti[i].apertaDaSola = true
            if saltata, notti[i].carte.isEmpty, notti[i].esito != .inCorso, notti[i].esito != .fatta { notti[i].esito = .saltata }
        } else {
            var n = NotteDiLavoro(giorno: giorno, inizio: nil)
            n.esito = .saltata
            n.apertaDaSola = true
            notti.append(n)
        }
        dati.notti = MotoreNotte.pota(notti, adesso: Date(), inCorsoAdesso: notte.inCorso ? notteInLavoro : nil)
    }

    /// La chiave della notte che sta lavorando (nil se nessuna).
    var notteInLavoro: String? {
        guard notte.inCorso else { return nil }
        return dati.notti.first { $0.esito == .inCorso }?.giornoChiave
    }

    /// A fine avvio, al risveglio e dal pianificatore di macOS: se le condizioni ci sono, il lavoro parte.
    func controllaNotte(adesso: Date = Date()) {
        #if os(macOS)
        controllaNotteMac(adesso: adesso)
        #endif
    }

    /// Ferma il lavoro (stop del Mac, avviso di memoria, 20 minuti, chiusura): le carte fatte restano.
    func fermaLavoroNotte(_ motivo: MotivoStopNotte) {
        guard notte.inCorso else { return }
        notte.lavoro.ferma(motivo)
    }

    /// Impostazioni › Vera › «Stanotte»: una sola assegnazione, solo se cambia.
    func impostaNotte(_ cambia: (inout ImpostazioniNotte) -> Void) {
        #if os(iOS)
        mostraAvviso(StatoShell.notteSoloSulMac)
        #else
        guard !solaLettura else {
            mostraAvviso(TestiSeguito.solaLettura)
            return
        }
        var n = dati.impostazioni.notte
        cambia(&n)
        if n != dati.impostazioni.notte { dati.impostazioni.notte = n }
        #endif
    }

    /// A fine avvio: le notti oltre le ultime 14 via, le «in corso» lasciate da un'uscita a metà diventano «interrotte».
    func potaNotti() {
        guard !solaLettura else { return }
        let potate = MotoreNotte.pota(dati.notti, adesso: Date())
        if potate != dati.notti { dati.notti = potate }
    }
}
