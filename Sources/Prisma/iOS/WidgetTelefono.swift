#if os(iOS)
import SwiftUI

// I riquadri della scrivania dell'iPhone nel tema Apple (Design/iphone.html, schermata 1): il vetro dei riquadri
// del Mac (raggio 26, padding 18×20), uno per riga, in ordine di importanza. In alto la mossa del giorno in grande
// con il prossimo incontro, poi ciò che richiede attenzione (rosso e arancio), la riga di Ruby con la sfera e il
// portafoglio con i tre anelli. Alla pressione scendono a 0,98 (`.inclinazione`, variante iOS); con «Riduci
// movimento» e nelle istantanee numeri e anelli sono già al loro valore. Tutte le cifre vengono dai motori di
// Prisma: mossa del giorno (MotoreMossaDelGiorno), stato del lavoro (MotoreStatoDelLavoro), riepilogo delle posizioni.

private typealias S = Tema.Apple.Telefono.Scrivania

extension View {
    /// Il riquadro di vetro della scrivania dell'iPhone: padding 18×20, vetro raggio 26, alla pressione 0,98.
    /// `apre` è ciò che fa un tocco sul riquadro fuori dai pulsanti.
    func riquadroTelefono(apre: (() -> Void)? = nil) -> some View {
        let forma = RoundedRectangle(cornerRadius: S.raggio, style: .continuous)
        return padding(Tema.Apple.Scrivania.Riquadro.padding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .superficieApple(Tema.Apple.Superficie.vetro, raggio: S.raggio)
            .contentShape(forma)
            .onTapGesture { apre?() }
            .inclinazione(massimo: Tema.Apple.Telefono.inclinazione, raggio: S.raggio)
    }
}

/// La testata di un riquadro: il titolo 14 bold e, a destra, il collegamento blu che apre l'app dal punto toccato.
struct TestataRiquadroTelefono: View {
    let titolo: String
    var collegamento: String? = nil
    var azione: ((CGPoint?) -> Void)? = nil
    @State private var origine = OrigineApertura()

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: S.spazioPulsanti) {
            Text(titolo)
                .carattereApple(S.testata)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let collegamento, let azione {
                Button { azione(origine.punto) } label: {
                    Text(collegamento)
                        .carattereApple(S.collegamento)
                        .foregroundColor(S.coloreCollegamento)
                        .lineLimit(1)
                        .frame(minHeight: Tema.Apple.Telefono.tocco)
                        .contentShape(Rectangle())
                }
                .buttonStyle(StileSemplice())
                .misuraOrigine(origine)
            }
        }
        // Il collegamento è alto 44 (il dito): la testata cresce con lui, il titolo resta al centro
        .frame(minHeight: S.sottoTestata * 2)
    }
}

// MARK: - La mossa del giorno

/// La mossa del giorno: la sfera con le iniziali, «La mossa del giorno» col canale, il titolo, il perché, poi
/// «Prepara con Ruby» e «Apri la scheda»; sotto il filo il prossimo incontro (un tocco apre l'Agenda).
struct RiquadroMossaTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mobile: StatoMobile
    @State private var origineRuby = OrigineApertura()
    @State private var origineScheda = OrigineApertura()

    private typealias M = Tema.Apple.Telefono.Mossa

    init() {}

    var body: some View {
        let esito = stato.mossaDelGiorno()
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: M.spazioSfera) {
                SferaMossaTelefono(iniziali: esito.mossa?.cliente.iniziali)
                testo(esito)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            pulsanti(esito)
                .padding(.top, S.pulsantiSopra)
            IncontroMossaTelefono()
                .padding(.top, M.incontroSopra)
        }
        .riquadroTelefono { apri(esito) }
    }

    private func testo(_ esito: EsitoMossaDelGiorno) -> some View {
        let titolo: String
        let frase: String
        switch esito {
        case .mossa(let m):
            titolo = m.titolo(oggi: Date())
            frase = m.motivo
        case .calma(let t, let f):
            titolo = t
            frase = f
        }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: S.spazioPulsanti) {
                Text("La mossa del giorno")
                    .carattereApple(M.etichetta)
                    .foregroundColor(M.coloreEtichetta)
                    .lineLimit(1)
                // Il canale del motivo, sempre riconoscibile (nil: neutro, senza etichetta)
                if let c = esito.mossa?.canale {
                    EtichettaCanaleApple(canale: c, compatta: true)
                }
            }
            Text(titolo)
                .carattereApple(M.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, M.titoloSopra)
            Text(frase)
                .carattereApple(M.corpo)
                .foregroundColor(M.coloreCorpo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, M.corpoSopra)
        }
    }

    @ViewBuilder private func pulsanti(_ esito: EsitoMossaDelGiorno) -> some View {
        if let m = esito.mossa {
            HStack(spacing: S.spazioPulsanti) {
                Button {
                    stato.rubyPortafoglio = false
                    stato.clienteAttivoId = m.cliente.id
                    mobile.apri(.ruby, da: origineRuby.punto)
                } label: {
                    Text("Prepara con Ruby")
                        .lineLimit(1)
                        .minimumScaleFactor(Tema.Apple.Telefono.Mossa.riduzionePulsanti)
                        .frame(maxWidth: .infinity, minHeight: Tema.Apple.Telefono.tocco)
                }
                .buttonStyle(StilePulsanteApple(.principale, grande: true))
                .misuraOrigine(origineRuby)
                .disabled(!stato.appConsentita(.ruby))
                Button {
                    apriScheda(m.cliente.id)
                } label: {
                    Text("Apri la scheda")
                        .lineLimit(1)
                        .minimumScaleFactor(Tema.Apple.Telefono.Mossa.riduzionePulsanti)
                        .frame(maxWidth: .infinity, minHeight: Tema.Apple.Telefono.tocco)
                }
                .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
                .misuraOrigine(origineScheda)
            }
        } else {
            Button {
                apriPortafoglio(da: origineScheda.punto)
            } label: {
                Text("Apri il portafoglio")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: Tema.Apple.Telefono.tocco)
            }
            .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
            .misuraOrigine(origineScheda)
        }
    }

    /// Un tocco sul riquadro: la scheda del cliente della mossa, o il portafoglio se non c'è una mossa.
    private func apri(_ esito: EsitoMossaDelGiorno) {
        if let m = esito.mossa {
            apriScheda(m.cliente.id)
        } else {
            apriPortafoglio(da: nil)
        }
    }

    private func apriScheda(_ id: String) {
        stato.clienteAttivoId = id
        mobile.apri(.clienti, da: origineScheda.punto)
        mobile.percorsoClienti = [.cliente(id)]
    }

    private func apriPortafoglio(da origine: CGPoint?) {
        stato.posizioneInDettaglio = nil
        stato.portafoglio = true
        mobile.apri(.posizioni, da: origine)
    }
}

/// La sfera della mossa: le iniziali del cliente sul gradiente radiale del tema (centro a 34% · 28%), come sul Mac.
/// Senza una mossa, una spunta: niente di urgente.
struct SferaMossaTelefono: View {
    let iniziali: String?

    var body: some View {
        let m = Tema.Apple.Scrivania.Mossa.self
        let lato = Tema.Apple.Telefono.Mossa.sfera
        ZStack {
            Circle()
                .fill(RadialGradient(stops: Tema.Apple.Colore.fermateSferaMossa, center: Tema.Apple.Colore.centroSfera,
                                     startRadius: 0, endRadius: lato * m.estensioneGradiente))
                .ombraApple(.sfera)
            Group {
                if let iniziali {
                    Text(iniziali)
                } else {
                    Image(systemName: m.simboloCalma)
                }
            }
            .carattereApple(Tema.Apple.Telefono.Mossa.iniziali)
            .foregroundColor(m.coloreIniziali)
            .shadow(color: m.ombraIniziali, radius: m.raggioOmbraIniziali, x: 0, y: m.yOmbraIniziali)
        }
        .frame(width: lato, height: lato)
        .accessibilityHidden(true)
    }
}

/// Il prossimo incontro sotto il filo della mossa: «tra 25 minuti», l'ora, il titolo, il cliente con i canali.
/// Un tocco apre l'appuntamento nell'Agenda.
struct IncontroMossaTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mobile: StatoMobile
    @State private var origine = OrigineApertura()

    private typealias M = Tema.Apple.Telefono.Mossa

    var body: some View {
        TimelineView(.everyMinute) { contesto in
            let adesso = contesto.date
            let prossimo = stato.prossimiAppuntamenti.first {
                $0.inizio.addingTimeInterval(Double($0.durataMinuti) * 60) >= adesso
            }
            if let a = prossimo {
                riga(a, adesso: adesso)
            }
        }
    }

    private func riga(_ a: Appuntamento, adesso: Date) -> some View {
        let cliente = stato.cliente(a.clienteId)
        let sotto = [cliente?.nome ?? "", a.luogo].filter { !$0.isEmpty }.joined(separator: " · ")
        return Button {
            mobile.apri(.agenda, da: origine.punto)
            mobile.percorsoAgenda = [.appuntamento(a.id)]
        } label: {
            VStack(alignment: .leading, spacing: Tema.Apple.Telefono.Elenco.spazioTesto) {
                Text("Prossimo incontro · " + Self.quando(a.inizio, adesso: adesso))
                    .carattereApple(M.quando)
                    .foregroundColor(M.coloreQuando)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: M.spazioIncontro) {
                    Text(Formati.ora.string(from: a.inizio))
                        .carattereApple(M.ora)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(a.titolo)
                        .carattereApple(M.incontro)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                if !sotto.isEmpty || cliente != nil {
                    HStack(spacing: Tema.Apple.Telefono.Elenco.spazioEtichette) {
                        Text(sotto)
                            .carattereApple(Tema.Apple.Telefono.Elenco.dettaglio)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                            .lineLimit(1)
                        if let c = cliente {
                            PuntiniCanaliTelefono(canali: c.canali)
                        }
                    }
                }
            }
            .padding(.top, M.incontroPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Tema.Apple.Colore.separatore)
                    .frame(height: Tema.Apple.Misura.bordo)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(StileSemplice())
        .misuraOrigine(origine)
    }

    /// «tra 25 minuti», «oggi tra 2 ore», «domani»…
    static func quando(_ inizio: Date, adesso: Date) -> String {
        let minuti = Int(inizio.timeIntervalSince(adesso) / 60)
        if minuti <= 0 { return "adesso" }
        if minuti < 60 { return "tra \(minuti) \(minuti == 1 ? "minuto" : "minuti")" }
        if Calendar.current.isDate(inizio, inSameDayAs: adesso) {
            let ore = minuti / 60
            return "oggi tra \(ore) \(ore == 1 ? "ora" : "ore")"
        }
        return Formati.giornoRelativo(inizio)
    }
}

/// I puntini dei canali del cliente (versione compatta: resta il colore del canale, blu Alleanza e cuoio).
struct PuntiniCanaliTelefono: View {
    let canali: [Canale]

    var body: some View {
        let lato = Tema.Apple.Misura.Controllo.pallinoCanale
        HStack(spacing: Tema.Apple.Telefono.Elenco.spazioTesto) {
            ForEach(canali) { c in
                Circle()
                    .fill(c == .alleanza ? Tema.Apple.Colore.canaleAlleanza : Tema.Apple.Colore.canaleIndipendente)
                    .frame(width: lato, height: lato)
            }
        }
        .accessibilityLabel(canali.map(\.nome).joined(separator: " e "))
    }
}

// MARK: - Richiede attenzione

/// Ciò che richiede attenzione: scadenze vicine, attività di oggi o rimaste indietro, proposte ferme. In rosso e
/// arancio; al massimo tre righe, «Tutto» apre Attività.
struct RiquadroAttenzioneTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mobile: StatoMobile

    private typealias A = Tema.Apple.Telefono.Attenzione
    private typealias E = Tema.Apple.Telefono.Elenco

    private struct Voce: Identifiable {
        enum Livello { case urgente, vicino, oggi }
        let id: String
        let livello: Livello
        let titolo: String
        let sotto: String
        var canale: Canale?
        let apri: () -> Void
    }

    var body: some View {
        let voci = Array(elenco.prefix(A.massimo))
        VStack(alignment: .leading, spacing: 0) {
            TestataRiquadroTelefono(titolo: "Richiede attenzione", collegamento: "Tutto") { origine in
                mobile.apri(.attivita, da: origine)
            }
            if voci.isEmpty {
                Text("Niente di urgente: tutto in ordine.")
                    .carattereApple(E.vuoto)
                    .foregroundColor(E.coloreDettaglio)
            }
            ForEach(Array(voci.enumerated()), id: \.element.id) { i, v in
                Button(action: v.apri) { riga(v) }
                    .buttonStyle(StileSemplice())
                    .overlay(alignment: .top) {
                        if i > 0 {
                            Rectangle()
                                .fill(Tema.Apple.Colore.separatore)
                                .frame(height: Tema.Apple.Misura.bordo)
                        }
                    }
            }
        }
        .riquadroTelefono { mobile.apri(.attivita) }
    }

    private func riga(_ v: Voce) -> some View {
        HStack(alignment: .top, spacing: E.spazioRiga) {
            ZStack {
                Circle().fill(colore(v.livello))
                Image(systemName: simbolo(v.livello))
                    .carattereApple(A.simbolo)
                    .foregroundColor(A.coloreSimbolo)
            }
            .frame(width: A.segno, height: A.segno)
            VStack(alignment: .leading, spacing: E.spazioTesto) {
                Text(v.titolo)
                    .carattereApple(E.nome)
                    .foregroundColor(E.coloreNome)
                    .fixedSize(horizontal: false, vertical: true)
                // Il nome resta intero: il canale va sotto, mai al posto del nome
                if !v.sotto.isEmpty {
                    Text(v.sotto)
                        .carattereApple(E.dettaglio)
                        .foregroundColor(E.coloreDettaglio)
                        .lineLimit(1)
                }
                if let c = v.canale {
                    EtichettaCanaleApple(canale: c, compatta: true)
                        .padding(.top, E.spazioTesto)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, A.paddingRiga)
        .frame(minHeight: E.rigaMinima, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func colore(_ l: Voce.Livello) -> Color {
        switch l {
        case .urgente: return A.urgente
        case .vicino: return A.vicino
        case .oggi: return A.oggi
        }
    }

    private func simbolo(_ l: Voce.Livello) -> String {
        switch l {
        case .urgente: return "exclamationmark"
        case .vicino: return "clock"
        case .oggi: return "checkmark"
        }
    }

    private var elenco: [Voce] {
        var voci: [Voce] = []
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        // Le posizioni in scadenza: entro 30 giorni in rosso, poi in arancio
        for p in stato.riepilogoTuttePosizioni.inScadenza.prefix(3) {
            let giorni = max(0, cal.dateComponents([.day], from: oggi, to: cal.startOfDay(for: p.scadenza ?? oggi)).day ?? 0)
            let titolo: String
            if p.scaduta {
                titolo = "\(p.nome) è scaduta"
            } else if giorni == 0 {
                titolo = "\(p.nome) scade oggi"
            } else {
                titolo = "\(p.nome) scade tra \(giorni) \(giorni == 1 ? "giorno" : "giorni")"
            }
            voci.append(Voce(id: "p-" + p.id, livello: p.scaduta || giorni <= 30 ? .urgente : .vicino, titolo: titolo,
                             sotto: stato.cliente(p.clienteId)?.nome ?? "", canale: p.canale) {
                stato.apriPosizione(p)
                mobile.apri(.posizioni)
                mobile.percorsoPosizioni = [.posizione(p.id)]
            })
        }
        // Le attività di oggi (e quelle rimaste indietro)
        let domani = cal.date(byAdding: .day, value: 1, to: oggi) ?? oggi
        let daFare = stato.attivitaAperte.filter { $0.scadenza < domani }
        if !daFare.isEmpty {
            let indietro = daFare.contains { $0.scadenza < oggi }
            voci.append(Voce(id: "attivita", livello: indietro ? .urgente : .oggi,
                             titolo: "\(daFare.count) attività per oggi",
                             sotto: daFare.prefix(2).map(\.titolo).joined(separator: " · ")) { mobile.apri(.attivita) })
        }
        // Le proposte che aspettano una risposta
        let ferme = stato.proposteInSospeso
        if !ferme.isEmpty {
            voci.append(Voce(id: "proposte", livello: ferme.contains { $0.urgente } ? .urgente : .vicino,
                             titolo: TestiSeguito.aspettano(ferme.count),
                             sotto: ferme.prefix(2).map(\.cliente.nome).joined(separator: " · ")) {
                stato.posizioneInDettaglio = nil
                stato.portafoglio = true
                mobile.apri(.posizioni)
            })
        }
        return voci.sorted { ordine($0.livello) < ordine($1.livello) }
    }

    private func ordine(_ l: Voce.Livello) -> Int {
        switch l {
        case .urgente: return 0
        case .vicino: return 1
        case .oggi: return 2
        }
    }
}

// MARK: - Ruby

/// La riga di Ruby: la sfera (l'unico simbolo di Ruby), «Ruby», la frase e lo stato di Qwen sul Mac. Un tocco apre Ruby.
struct RiquadroRubyTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mobile: StatoMobile
    @State private var origine = OrigineApertura()

    private typealias R = Tema.Apple.Telefono.RigaRuby

    init() {}

    var body: some View {
        let pronto = stato.disponibilitaLocale.pronto
        HStack(spacing: R.spazio) {
            SferaRuby(misura: R.sfera, viva: pronto, pensa: stato.rubyInCorso)
                // Mentre Ruby risponde l'acqua vibra intorno a questa sfera (OsservatoreAcqua)
                .puntoAcqua(.sferaRuby)
                .misuraOrigine(origine)
            VStack(alignment: .leading, spacing: Tema.Apple.Telefono.Elenco.spazioTesto) {
                Text("Ritrova il filo con Ruby.")
                    .carattereApple(R.nome)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                Text(pronto ? "Qwen sul Mac · sintesi e prossimi passi" : "Collegala a Qwen del tuo Mac")
                    .carattereApple(R.frase)
                    .foregroundColor(pronto ? R.coloreFrase : R.coloreNonPronto)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .carattereApple(Tema.Apple.Telefono.Elenco.chevron)
                .foregroundColor(Tema.Apple.Colore.inchiostro3)
        }
        .riquadroTelefono {
            if stato.appConsentita(.ruby) { mobile.apri(.ruby, da: origine.punto) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Portafoglio

/// Il portafoglio dei clienti: il totale in essere che conta, i tre anelli dello stato del lavoro (in regola,
/// riesami, proposte concluse) con la legenda, poi la barra dei due canali, sempre distinti.
struct RiquadroPortafoglioTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mobile: StatoMobile

    private typealias P = Tema.Apple.Telefono.Portafoglio

    var body: some View {
        let r = stato.riepilogoTuttePosizioni
        let lavoro = stato.statoDelLavoro()
        let clienti = stato.clienti.count
        VStack(alignment: .leading, spacing: 0) {
            TestataRiquadroTelefono(titolo: "Portafoglio clienti", collegamento: "Apri") { origine in
                apri(da: origine)
            }
            NumeroCheConta(r.attivita, formato: .euro, indice: 1)
                .carattereApple(P.totale)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(P.riduzioneTotale)
            Text("in essere · \(clienti) \(clienti == 1 ? "cliente" : "clienti")")
                .carattereApple(P.nota)
                .foregroundColor(P.coloreNota)
                .lineLimit(1)
            HStack(alignment: .center, spacing: P.spazioAnelli) {
                AnelliConcentrici(voci: Self.voci(lavoro), misura: P.anelli, spessore: P.spessoreAnelli,
                                  ritardo: P.ritardoAnelli)
                legenda(lavoro)
                Spacer(minLength: 0)
            }
            .padding(.top, P.anelliSopra)
            if r.attivita > 0 {
                canali(r)
                    .padding(.top, P.canaliSopra)
            }
        }
        .riquadroTelefono { apri(da: nil) }
    }

    private func apri(da origine: CGPoint?) {
        stato.posizioneInDettaglio = nil
        stato.portafoglio = true
        mobile.apri(.posizioni, da: origine)
    }

    /// Dall'esterno: in regola (verde), riesami dell'anno (blu), proposte concluse (viola), come sul Mac.
    private static func voci(_ l: StatoDelLavoro) -> [VoceAnello] {
        [
            VoceAnello(id: "inRegola", valore: Double(l.inRegola.fatti), massimo: Double(l.inRegola.totale), colore: P.coloreInRegola),
            VoceAnello(id: "riesami", valore: Double(l.riesami.fatti), massimo: Double(l.riesami.totale), colore: P.coloreRiesami),
            VoceAnello(id: "proposte", valore: Double(l.proposte.fatti), massimo: Double(l.proposte.totale), colore: P.coloreProposte),
        ]
    }

    private func legenda(_ l: StatoDelLavoro) -> some View {
        VStack(alignment: .leading, spacing: P.spazioLegenda) {
            voce("In regola", l.inRegola, colore: P.coloreInRegola)
            voce("Riesami", l.riesami, colore: P.coloreRiesami)
            voce("Proposte", l.proposte, colore: P.coloreProposte)
        }
        .fixedSize()
    }

    private func voce(_ nome: String, _ c: StatoDelLavoro.Conteggio, colore: Color) -> some View {
        let prima = Text(nome + " ").font(P.legenda.font)
        let fatti = Text("\(c.fatti)").font(P.legendaForte.font)
        let totale = Text("/\(c.totale)").font(P.legenda.font)
        let testo = prima + fatti + totale
        return HStack(spacing: P.spazioPallino) {
            Circle()
                .fill(colore)
                .frame(width: P.pallino, height: P.pallino)
            testo
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
        }
    }

    /// La barra dei canali (Alleanza blu, indipendente cuoio) e, sotto, le due etichette con l'importo.
    private func canali(_ r: RiepilogoPosizioni) -> some View {
        let alleanza = r.perCanale[.alleanza] ?? 0
        let indipendente = r.perCanale[.indipendente] ?? 0
        return VStack(alignment: .leading, spacing: P.spazioCanali) {
            BarraPienaSegmenti.canali(alleanza: max(alleanza, 0), indipendente: max(indipendente, 0), indice: 2)
            ForEach(Canale.allCases) { c in
                HStack(spacing: P.spazioCanali) {
                    EtichettaCanaleApple(canale: c, compatta: true)
                    Spacer(minLength: 0)
                    Text(FormatoCifra.euro.testo(r.perCanale[c] ?? 0))
                        .carattereApple(P.canale)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(1)
                }
            }
        }
    }
}
#endif
