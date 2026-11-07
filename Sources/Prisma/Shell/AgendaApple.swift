import SwiftUI

// L'Agenda nel tema Apple (Design/template-apple-specifica.md §4.4.1, riferimenti analisi-agenda/G01-G07):
//
//   ┌ Novembre      2026 ┐  [ Oggi | Mer 4 | Gio 5 | Ven 6 | Sab 7 | Dom 8 | Lun 9 ]
//   │ L M M G V S D      │  Martedì 3 novembre  2 impegni · 3 da fare
//   │ 2 ③ 4 5 6 7 8  · · │  ┌ DA FARE E DA RICORDARE  (● Richiamare… Marco) (● Preparare… Giulia) ┐
//   │ …                  │  │ 08:00 ──────────────────────────────────────────────────────────── │
//   │ QUESTA SETTIMANA   │  │ 09:00 ── ▌Giulia Rossi  09:30 – 10:15 · In studio                   │
//   │ 9 impegni 6 clienti│  │ 10:00 ●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │  ← la linea dell'ora
//   │ DA NON DIMENTICARE │  │ 11:00 ── ▌Marco Bianchi 11:00 – 12:00 · Videochiamata   [Alleanza]  │
//   └────────────────────┘  └─────────────────────────────────────────────────────────────────────┘
//
// - La barra laterale (vista «Settimana»): il mese con i puntini del giorno (appuntamenti, riesami, attività,
//   scadenze, occasioni), «Questa settimana» con tre cifre calcolate che si contano, «Da non dimenticare».
// - La settimana a pillola (SegmentatoPillola a tutta larghezza), la data e la giornata: le ore, la fascia «Da fare
//   e da ricordare» con le attività, le scadenze e le occasioni del giorno, gli impegni che entrano da destra
//   (`.entrataLaterale`) e si inclinano di 3 gradi sotto il puntatore, la linea rossa dell'ora che avanza a ogni
//   minuto (TimelineView, niente Timer; nelle istantanee alle 10:24).
// - Toccando un impegno si apre la traccia (PresentatoreDettaglio, TracciaImpegnoApple.swift).
// - «Riduci movimento» e istantanee: tutto nello stato finale (lo fanno i componenti del tema).
// - Prestazioni: un solo indice dei giorni per disegno (StatoShell.giorniAgenda), la linea dell'ora è l'unica cosa
//   che si ridisegna a ogni minuto, un solo dettaglio alla volta.

// MARK: - Testi

enum TestiAgendaApple {
    static let mese = Formati.formato("LLLL")
    static let anno = Formati.formato("yyyy")
    /// Le intestazioni del calendario della barra laterale.
    static let iniziali = ["L", "M", "M", "G", "V", "S", "D"]
    static let vuoto = "Nessun impegno. Un buon giorno per i riesami."
    static let fascia = "Da fare e da ricordare"
    static let questaSettimana = "Questa settimana"
    static let daNonDimenticare = "Da non dimenticare"
    static let puntiDaToccare = "Punti da toccare"

    static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// «Martedì 3 novembre».
    static func titoloGiorno(_ g: Date) -> String { maiuscola(Formati.dataLunga.string(from: g)) }

    /// «2 impegni · 3 da fare», «1 impegno», «giornata libera».
    static func notaGiorno(impegni: Int, daFare: Int) -> String {
        var parti: [String] = []
        if impegni > 0 { parti.append("\(impegni) \(impegni == 1 ? "impegno" : "impegni")") }
        if daFare > 0 { parti.append("\(daFare) da fare") }
        return parti.isEmpty ? "giornata libera" : parti.joined(separator: " · ")
    }

    /// La voce della settimana a pillola: «Oggi» o «Mer 4».
    static func vocePillola(_ g: Date) -> String {
        let cal = CalendarioAgenda.cal
        if cal.isDateInToday(g) { return "Oggi" }
        let colonna = (cal.component(.weekday, from: g) + 5) % 7
        return "\(CalendarioAgenda.nomiGiorni[colonna]) \(Formati.giorno.string(from: g))"
    }

    /// «09:30 – 10:15».
    static func orario(_ e: Appuntamento) -> String {
        "\(Formati.ora.string(from: e.inizio)) – \(Formati.ora.string(from: e.fine))"
    }

    /// «09:30 – 10:15 · In studio».
    static func quando(_ e: Appuntamento) -> String {
        e.luogo.isEmpty ? orario(e) : "\(orario(e)) · \(e.luogo)"
    }

    /// «Settimana del 9 novembre» se la settimana non è quella di oggi.
    static func titoloSettimana(_ giorni: [Date]) -> String {
        let cal = CalendarioAgenda.cal
        if giorni.contains(where: { cal.isDateInToday($0) }) { return questaSettimana }
        return "Settimana del \(giorni.first.map { Formati.giornoMese.string(from: $0) } ?? "")"
    }
}

// MARK: - Dati della giornata

/// Le tre cifre di «Questa settimana»: impegni, clienti diversi e ore riservate (dagli appuntamenti veri).
struct RiepilogoSettimanaAgenda: Equatable {
    var impegni = 0
    var clienti = 0
    /// Ore con un decimale.
    var ore: Double = 0

    init(giorni: [Date], indice: GiorniAgenda) {
        let eventi = giorni.flatMap { indice.appuntamenti($0) }
        impegni = eventi.count
        clienti = Set(eventi.map(\.clienteId)).count
        let minuti = eventi.reduce(0) { $0 + $1.durataMinuti }
        ore = (Double(minuti) / 60 * 10).rounded() / 10
    }
}

/// Una voce della fascia «Da fare e da ricordare»: un'attività, una scadenza o un'occasione del giorno.
struct VoceFasciaApple: Identifiable {
    enum Tipo {
        case attivita(String)
        case scadenza(Posizione)
        case occasione(Occasione)
    }

    let id: String
    let testo: String
    let cliente: String?
    let colore: Color
    let tipo: Tipo
}

/// Un puntino del calendario: pieno (appuntamenti, attività, scadenze) o ad anello (occasioni).
struct PuntinoGiornoApple: Identifiable {
    let id: Int
    let colore: Color
    let anello: Bool
}

extension StatoShell {
    /// Le voci della fascia della giornata: le rimaste indietro (solo oggi), le attività da fare, le scadenze e,
    /// con lo strato acceso, le occasioni.
    func vociFasciaAgenda(_ giorno: Date, indice: GiorniAgenda, strato: Bool) -> [VoceFasciaApple] {
        let s = Tema.Apple.Agenda.Segno.self
        let cal = Calendar.current
        let oggi = cal.isDateInToday(giorno)
        var voci: [VoceFasciaApple] = []
        if oggi {
            for t in attivitaRimasteIndietro() {
                voci.append(VoceFasciaApple(id: "attivita-" + t.id, testo: t.titolo, cliente: cliente(t.clienteId)?.nome,
                                            colore: s.attivitaScaduta, tipo: .attivita(t.id)))
            }
        }
        for t in indice.daFare(giorno) {
            voci.append(VoceFasciaApple(id: "attivita-" + t.id, testo: t.titolo, cliente: cliente(t.clienteId)?.nome,
                                        colore: s.attivita, tipo: .attivita(t.id)))
        }
        for p in indice.scadenze(giorno) {
            voci.append(VoceFasciaApple(id: "scadenza-" + p.id, testo: "Scade: \(p.nome)", cliente: cliente(p.clienteId)?.nome,
                                        colore: s.scadenza, tipo: .scadenza(p)))
        }
        if strato {
            for o in indice.occasioni(giorno) {
                voci.append(VoceFasciaApple(id: "occasione-" + o.id, testo: o.titolo, cliente: cliente(o.clienteId)?.nome,
                                            colore: s.occasione(o.canale), tipo: .occasione(o)))
            }
        }
        return voci
    }

    /// I puntini di un giorno del calendario, nell'ordine appuntamenti, riesami, attività, scadenze, occasioni.
    func puntiniGiornoAgenda(_ g: Date, indice: GiorniAgenda, strato: Bool) -> [PuntinoGiornoApple] {
        let s = Tema.Apple.Agenda.Segno.self
        let eventi = indice.appuntamenti(g)
        var colori: [(Color, Bool)] = []
        if eventi.contains(where: { $0.tipo != .revisione }) { colori.append((s.appuntamento, false)) }
        if eventi.contains(where: { $0.tipo == .revisione }) { colori.append((s.riesame, false)) }
        let daFare = indice.daFare(g)
        if !daFare.isEmpty {
            let scadute = g < Calendar.current.startOfDay(for: Date())
            colori.append((scadute ? s.attivitaScaduta : s.attivita, false))
        }
        if !indice.scadenze(g).isEmpty { colori.append((s.scadenza, false)) }
        if strato, let o = indice.occasioni(g).first { colori.append((s.occasione(o.canale), true)) }
        return colori.prefix(4).enumerated().map { PuntinoGiornoApple(id: $0.offset, colore: $0.element.0, anello: $0.element.1) }
    }

    /// «Da non dimenticare»: la cosa rimasta indietro da più tempo oppure la scadenza più vicina (entro 90 giorni)
    /// dei clienti mostrati. Nil se non c'è niente.
    func daNonDimenticareAgenda(_ oggi: Date = Date()) -> String? {
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: oggi)
        let indietro = attivitaRimasteIndietro(oggi)
        if let t = indietro.first {
            let chi = cliente(t.clienteId).map { " per \($0.nome)" } ?? ""
            let data = Formati.giornoMese.string(from: t.scadenza)
            if indietro.count == 1 { return "«\(t.titolo)»\(chi): era da fare entro il \(data)." }
            return "\(indietro.count) cose rimaste indietro: la prima è «\(t.titolo)»\(chi), del \(data)."
        }
        let limite = cal.date(byAdding: .day, value: 90, to: inizio) ?? inizio
        let filtro = filtroClienteAgenda
        var prossima: (posizione: Posizione, data: Date)?
        for p in posizioni where p.stato == .inEssere && (filtro == nil || p.clienteId == filtro) {
            guard let s = p.scadenza, s >= inizio, s <= limite else { continue }
            if prossima == nil || s < (prossima?.data ?? s) { prossima = (posizione: p, data: s) }
        }
        if let x = prossima {
            let chi = cliente(x.posizione.clienteId).map { " di \($0.nome)" } ?? ""
            return "\(x.posizione.nome)\(chi): scade il \(Formati.giornoMese.string(from: x.data))."
        }
        return nil
    }
}

// MARK: - Richiesta delle istantanee

/// Ciò che una scena delle istantanee chiede all'Agenda (Prisma --istantanee): la traccia di un impegno già aperta.
/// Vale solo per lo stato della scena (riferimento debole: le scene dopo non la vedono).
final class RichiestaIstantaneaAgenda {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaAgenda?

    private weak var stato: StatoShell?
    let impegno: String?

    private init(stato: StatoShell, impegno: String?) {
        self.stato = stato
        self.impegno = impegno
    }

    static func chiedi(_ s: StatoShell, impegno: String?) {
        attuale = RichiestaIstantaneaAgenda(stato: s, impegno: impegno)
    }

    static func per(_ s: StatoShell) -> RichiestaIstantaneaAgenda? {
        guard let r = attuale, r.stato === s else { return nil }
        return r
    }
}

// MARK: - Presentatore della traccia

/// Mette sopra l'Agenda la traccia dell'impegno toccato (un solo dettaglio alla volta).
struct PresentatoreImpegniApple<Contenuto: View>: View {
    let stato: StatoShell
    @StateObject private var dettaglio: StatoDettaglio
    let contenuto: Contenuto

    init(stato: StatoShell, @ViewBuilder contenuto: () -> Contenuto) {
        self.stato = stato
        self.contenuto = contenuto()
        // L'oggetto nasce una volta sola (`StateObject` valuta l'espressione solo alla prima comparsa)
        _dettaglio = StateObject(wrappedValue: Self.dettaglioIniziale(stato))
    }

    private static func dettaglioIniziale(_ s: StatoShell) -> StatoDettaglio {
        guard let id = RichiestaIstantaneaAgenda.per(s)?.impegno else { return StatoDettaglio() }
        return StatoDettaglio(aperto: TracciaImpegnoApple.id(per: id), misura: Tema.Apple.Agenda.Traccia.misura)
    }

    var body: some View {
        contenuto
            .presentatoreDettaglio(dettaglio) { id in
                TracciaImpegnoApple(idDettaglio: id)
            }
            .onDisappear { dettaglio.chiudi(subito: true) }
    }
}

// MARK: - Barra laterale (vista «Settimana»)

struct BarraLateraleAgendaApple: View {
    let giorno: Date
    let settimane: [[Date]]
    let indice: GiorniAgenda
    let strato: Bool
    let seleziona: (Date) -> Void
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        let l = Tema.Apple.Agenda.Laterale.self
        let settimana = CalendarioAgenda.giorni(settimanaDi: giorno)
        let avviso = stato.daNonDimenticareAgenda()
        // Negli schermi bassi la barra scorre: il mese resta sempre intero
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(TestiAgendaApple.maiuscola(TestiAgendaApple.mese.string(from: giorno)))
                        .carattereApple(l.mese)
                        .foregroundColor(l.coloreMese)
                    Spacer(minLength: 0)
                    Text(TestiAgendaApple.anno.string(from: giorno))
                        .carattereApple(l.anno)
                        .foregroundColor(l.coloreAnno)
                }
                .entrataCascata(0)
                MiniMeseAgendaApple(settimane: settimane, giorno: giorno, indice: indice, strato: strato,
                                    seleziona: seleziona)
                    .padding(.top, l.calendarioSopra)
                    .entrataCascata(1)
                cardSettimana(settimana)
                    .padding(.top, l.primaCardSopra)
                    .entrataCascata(2)
                if let avviso {
                    cardAvviso(avviso)
                        .padding(.top, l.cardSopra)
                        .entrataCascata(3)
                }
            }
            .padding(l.padding)
        }
        .frame(width: l.larghezza)
        .frame(maxHeight: .infinity, alignment: .top)
        .superficieApple(l.superficie, raggio: l.raggio)
    }

    private func cardSettimana(_ giorni: [Date]) -> some View {
        let l = Tema.Apple.Agenda.Laterale.self
        let r = RiepilogoSettimanaAgenda(giorni: giorni, indice: indice)
        return VStack(alignment: .leading, spacing: 0) {
            Text(TestiAgendaApple.titoloSettimana(giorni))
                .carattereApple(l.etichetta)
                .foregroundColor(l.coloreEtichetta)
                .lineLimit(1)
            HStack(alignment: .top, spacing: l.spazioCifre) {
                cifra(Double(r.impegni), formato: .intero, nome: r.impegni == 1 ? "impegno" : "impegni", indice: 0)
                cifra(Double(r.clienti), formato: .intero, nome: r.clienti == 1 ? "cliente" : "clienti", indice: 1)
                cifra(r.ore, formato: .mesi, nome: r.ore == 1 ? "ora" : "ore", indice: 2)
            }
            .padding(.top, l.cifreSopra)
        }
        .padding(l.paddingCard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(l.superficieCard, raggio: l.raggioCard)
    }

    private func cifra(_ valore: Double, formato: FormatoCifra, nome: String, indice: Int) -> some View {
        let l = Tema.Apple.Agenda.Laterale.self
        return VStack(alignment: .leading, spacing: 0) {
            NumeroCheConta(valore, formato: formato, indice: indice)
                .carattereApple(l.cifra)
                .foregroundColor(l.coloreCifra)
                .lineLimit(1)
            Text(nome)
                .carattereApple(l.nomeCifra)
                .foregroundColor(l.coloreNomeCifra)
                .lineLimit(1)
        }
    }

    private func cardAvviso(_ testo: String) -> some View {
        let l = Tema.Apple.Agenda.Laterale.self
        let forma = RoundedRectangle(cornerRadius: l.raggioCard, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Text(TestiAgendaApple.daNonDimenticare)
                .carattereApple(l.etichetta)
                .foregroundColor(l.coloreEtichettaAvviso)
            Text(testo)
                .carattereApple(l.avviso)
                .foregroundColor(l.coloreAvviso)
                .lineLimit(l.righeAvviso)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, l.avvisoSopra)
        }
        .padding(l.paddingCard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { forma.fill(l.fondoAvviso) }
        .overlay { forma.strokeBorder(l.bordoAvviso, lineWidth: Tema.Apple.Misura.bordo) }
    }
}

// MARK: - Calendario del mese con i puntini

struct MiniMeseAgendaApple: View {
    let settimane: [[Date]]
    let giorno: Date
    let indice: GiorniAgenda
    let strato: Bool
    let seleziona: (Date) -> Void
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        let c = Tema.Apple.Agenda.Calendario.self
        return VStack(spacing: c.spazio) {
            HStack(spacing: c.spazio) {
                ForEach(TestiAgendaApple.iniziali.indices, id: \.self) { i in
                    Text(TestiAgendaApple.iniziali[i])
                        .carattereApple(c.intestazione)
                        .foregroundColor(c.coloreIntestazione)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, c.sottoIntestazione)
            ForEach(settimane, id: \.self) { s in
                HStack(spacing: c.spazio) {
                    ForEach(s, id: \.self) { g in
                        casella(g)
                    }
                }
            }
        }
    }

    private func casella(_ g: Date) -> CasellaMiniMeseApple {
        let cal = CalendarioAgenda.cal
        return CasellaMiniMeseApple(
            giorno: g,
            nelMese: cal.isDate(g, equalTo: giorno, toGranularity: .month),
            scelto: cal.isDate(g, inSameDayAs: giorno),
            oggi: cal.isDateInToday(g),
            puntini: stato.puntiniGiornoAgenda(g, indice: indice, strato: strato),
            azione: { seleziona(g) }
        )
    }
}

/// Una casella del calendario della barra laterale: oggi su rosso, il giorno scelto sull'accento al 14%,
/// i puntini in basso.
struct CasellaMiniMeseApple: View {
    let giorno: Date
    let nelMese: Bool
    let scelto: Bool
    let oggi: Bool
    let puntini: [PuntinoGiornoApple]
    let azione: () -> Void
    @State private var sopra = false
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    var body: some View {
        let c = Tema.Apple.Agenda.Calendario.self
        let forma = RoundedRectangle(cornerRadius: c.raggio, style: .continuous)
        return Button(action: azione) {
            ZStack(alignment: .bottom) {
                Text(Formati.giorno.string(from: giorno))
                    .carattereApple(oggi || scelto ? c.numeroForte : c.numero)
                    .foregroundColor(colore)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if !puntini.isEmpty {
                    HStack(spacing: c.spazioPuntini) {
                        ForEach(puntini) { p in puntino(p) }
                    }
                    .padding(.bottom, c.puntinoDalFondo)
                }
            }
            .frame(height: c.altezza)
            .frame(maxWidth: .infinity)
            .background { forma.fill(fondo) }
            .contentShape(forma)
        }
        .buttonStyle(.plain)
        .onHover { dentro in
            guard !istantanea else { return }
            // Con «Riduci movimento» il passaggio cambia senza animazione
            withAnimation(calmo ? nil : c.animazionePassaggio) { sopra = dentro }
        }
        .accessibilityLabel(Formati.dataLunga.string(from: giorno))
        .accessibilityAddTraits(scelto ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    private var colore: Color {
        let c = Tema.Apple.Agenda.Calendario.self
        if oggi { return c.testoOggi }
        return nelMese ? c.coloreNumero : c.coloreFuori
    }

    private var fondo: Color {
        let c = Tema.Apple.Agenda.Calendario.self
        if oggi { return c.fondoOggi }
        if scelto { return c.fondoScelto }
        return sopra ? c.fondoPassaggio : Color.clear
    }

    @ViewBuilder private func puntino(_ p: PuntinoGiornoApple) -> some View {
        let c = Tema.Apple.Agenda.Calendario.self
        let tinta = oggi ? c.puntinoSuOggi : p.colore
        if p.anello {
            Circle()
                .strokeBorder(tinta, lineWidth: c.spessoreOccasione)
                .frame(width: c.puntino, height: c.puntino)
        } else {
            Circle()
                .fill(tinta)
                .frame(width: c.puntino, height: c.puntino)
        }
    }
}

// MARK: - Titolo della giornata

/// «Martedì 3 novembre» `.h2` con «2 impegni · 3 da fare» `.k`.
struct TitoloGiornataApple: View {
    let giorno: Date
    let impegni: Int
    let daFare: Int

    var body: some View {
        let s = Tema.Apple.Agenda.Settimana.self
        return HStack(alignment: .firstTextBaseline, spacing: s.spazioTitolo) {
            Text(TestiAgendaApple.titoloGiorno(giorno))
                .carattereApple(s.titolo)
                .foregroundColor(s.coloreTitolo)
                .lineLimit(1)
            Text(TestiAgendaApple.notaGiorno(impegni: impegni, daFare: daFare))
                .carattereApple(s.nota)
                .foregroundColor(s.coloreNota)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, s.rientroTitolo)
    }
}

// MARK: - Giornata

/// La giornata: la fascia «Da fare e da ricordare», le ore, gli impegni (affiancati se si sovrappongono) e la
/// linea rossa dell'ora. Toccando un impegno nasce la sua traccia.
struct GiornataImpegniApple: View {
    let giorno: Date
    let eventi: [Appuntamento]
    let voci: [VoceFasciaApple]
    let sceglie: (VoceFasciaApple) -> Void

    var body: some View {
        let g = Tema.Apple.Agenda.Giornata.self
        let forma = RoundedRectangle(cornerRadius: g.raggio, style: .continuous)
        return VStack(spacing: 0) {
            if !voci.isEmpty {
                FasciaDaFareApple(voci: voci, sceglie: sceglie)
                Rectangle()
                    .fill(Tema.Apple.Agenda.Fascia.filo)
                    .frame(height: Tema.Apple.Misura.bordo)
            }
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    OreGiornataApple(giorno: giorno, eventi: eventi, larghezza: geo.size.width)
                }
            }
        }
        .clipShape(forma)
        .superficieApple(g.superficie, raggio: g.raggio)
    }
}

/// Le ore, gli impegni e la linea dell'ora (alto quanto serve: dentro uno scorrimento).
private struct OreGiornataApple: View {
    let giorno: Date
    let eventi: [Appuntamento]
    let larghezza: CGFloat
    @Environment(\.modoIstantanea) private var istantanea

    var body: some View {
        let g = Tema.Apple.Agenda.Giornata.self
        let ore = Self.intervallo(eventi)
        let altezza = g.lineaSopra + CGFloat(ore.ultima - ore.prima) * g.altezzaOra + g.sottoUltima
        return ZStack(alignment: .topLeading) {
            righe(ore)
            impegni(ore)
                // Un giorno nuovo: gli impegni rientrano da destra
                .id(CalendarioAgenda.cal.startOfDay(for: giorno))
            if eventi.isEmpty {
                vuoto
                    .frame(width: larghezza, height: altezza)
            }
            if CalendarioAgenda.cal.isDateInToday(giorno) {
                if istantanea {
                    // La stessa ora ferma dell'orologio della barra nelle istantanee
                    lineaOra(Self.ora(OraIstantanee.data(giorno)), ore)
                } else {
                    TimelineView(.everyMinute) { contesto in
                        lineaOra(Self.ora(contesto.date), ore)
                    }
                }
            }
        }
        .frame(width: larghezza, height: altezza, alignment: .topLeading)
    }

    /// Dalle 8 alle 19, allargato se un impegno esce dall'orario.
    static func intervallo(_ eventi: [Appuntamento]) -> (prima: Int, ultima: Int) {
        let g = Tema.Apple.Agenda.Giornata.self
        let cal = Calendar.current
        var prima = g.primaOra
        var ultima = g.ultimaOra
        for e in eventi {
            prima = min(prima, cal.component(.hour, from: e.inizio))
            let fine = e.fine
            if cal.isDate(fine, inSameDayAs: e.inizio) {
                let extra = cal.component(.minute, from: fine) > 0 ? 1 : 0
                ultima = max(ultima, cal.component(.hour, from: fine) + extra)
            } else {
                ultima = 24
            }
        }
        return (prima, min(24, max(ultima, prima + 1)))
    }

    /// L'ora come numero (10:24 = 10,4).
    static func ora(_ d: Date) -> Double {
        let cal = Calendar.current
        return Double(cal.component(.hour, from: d)) + Double(cal.component(.minute, from: d)) / 60
    }

    private func y(_ ora: Double, _ ore: (prima: Int, ultima: Int)) -> CGFloat {
        let g = Tema.Apple.Agenda.Giornata.self
        return CGFloat(ora - Double(ore.prima)) * g.altezzaOra
    }

    private func righe(_ ore: (prima: Int, ultima: Int)) -> some View {
        let g = Tema.Apple.Agenda.Giornata.self
        return ForEach(Array(ore.prima...ore.ultima), id: \.self) { o in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(g.linea)
                    .frame(height: Tema.Apple.Misura.bordo)
                    .padding(.leading, g.lineaDalBordo)
                    .padding(.top, g.lineaSopra + y(Double(o), ore))
                Text(String(format: "%02d:00", o))
                    .carattereApple(g.ora)
                    .foregroundColor(g.coloreOra)
                    .padding(.leading, g.oraDalBordo)
                    .padding(.top, max(0, g.lineaSopra + y(Double(o), ore) - g.oraSopraLinea))
            }
            .frame(width: larghezza, alignment: .topLeading)
            .accessibilityHidden(true)
        }
    }

    private func impegni(_ ore: (prima: Int, ultima: Int)) -> some View {
        let g = Tema.Apple.Agenda.Giornata.self
        let posti = CorsieImpegni.disponi(eventi)
        let libera = max(0, larghezza - g.impegnoSinistra - g.impegnoDestra)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(posti.enumerated()), id: \.element.evento.id) { i, p in
                let n = CGFloat(max(1, p.corsie))
                let w = max(0, (libera - g.spazioCorsie * (n - 1)) / n)
                let x = g.impegnoSinistra + CGFloat(p.corsia) * (w + g.spazioCorsie)
                let alto = y(Self.ora(p.evento.inizio), ore) + g.impegnoSopra
                let h = max(g.impegnoMinimo, CGFloat(p.evento.durataMinuti) / 60 * g.altezzaOra - g.impegnoStacco)
                ImpegnoGiornataApple(evento: p.evento, larghezza: w, altezza: h)
                    .entrataLaterale(i)
                    .padding(.leading, x)
                    .padding(.top, alto)
            }
        }
        .frame(width: larghezza, alignment: .topLeading)
    }

    @ViewBuilder private func lineaOra(_ ora: Double, _ ore: (prima: Int, ultima: Int)) -> some View {
        let g = Tema.Apple.Agenda.Giornata.self
        if ora >= Double(ore.prima) && ora <= Double(ore.ultima) {
            let alto = g.lineaSopra + y(ora, ore)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(g.coloreLinea)
                    .frame(height: g.spessoreLinea)
                Circle()
                    .fill(g.coloreLinea)
                    .frame(width: g.pallinoOra, height: g.pallinoOra)
                    .offset(x: -g.pallinoOra / 2)
            }
            .frame(width: max(0, larghezza - g.lineaOraDalBordo), height: g.pallinoOra)
            .padding(.leading, g.lineaOraDalBordo)
            .padding(.top, max(0, alto - g.pallinoOra / 2))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var vuoto: some View {
        let g = Tema.Apple.Agenda.Giornata.self
        return VStack(spacing: g.spazioVuoto) {
            Image(systemName: g.simboloVuoto)
                .carattereApple(g.carattereSimboloVuoto)
                .foregroundColor(g.coloreVuoto)
            Text(TestiAgendaApple.vuoto)
                .carattereApple(g.vuoto)
                .foregroundColor(g.coloreVuoto)
                .multilineTextAlignment(.center)
        }
        .padding(.leading, g.impegnoSinistra / 2)
        .allowsHitTesting(false)
    }
}

/// Gli impegni che si sovrappongono stanno affiancati: ognuno nella prima corsia libera del suo gruppo.
enum CorsieImpegni {
    struct Posto {
        let evento: Appuntamento
        let corsia: Int
        let corsie: Int
    }

    static func disponi(_ eventi: [Appuntamento]) -> [Posto] {
        let g = Tema.Apple.Agenda.Giornata.self
        // Anche l'impegno breve occupa l'altezza minima: per le sovrapposizioni conta quella
        let minimo = TimeInterval(g.impegnoMinimo / g.altezzaOra * 3600)
        let ordinati = eventi.sorted { $0.inizio < $1.inizio }
        var posti: [Posto] = []
        var gruppo: [(evento: Appuntamento, corsia: Int)] = []
        var finiCorsie: [Date] = []
        var fineGruppo = Date.distantPast
        for e in ordinati {
            if !gruppo.isEmpty && e.inizio >= fineGruppo {
                let n = max(1, finiCorsie.count)
                posti += gruppo.map { Posto(evento: $0.evento, corsia: $0.corsia, corsie: n) }
                gruppo = []
                finiCorsie = []
            }
            let fine = max(e.fine, e.inizio.addingTimeInterval(minimo))
            if let i = finiCorsie.firstIndex(where: { $0 <= e.inizio }) {
                finiCorsie[i] = fine
                gruppo.append((evento: e, corsia: i))
            } else {
                finiCorsie.append(fine)
                gruppo.append((evento: e, corsia: finiCorsie.count - 1))
            }
            fineGruppo = max(fineGruppo, fine)
        }
        let n = max(1, finiCorsie.count)
        posti += gruppo.map { Posto(evento: $0.evento, corsia: $0.corsia, corsie: n) }
        return posti
    }
}

/// Un impegno della giornata: bordo sinistro di 4 e fondo al 13% nel colore del cliente, nome, orario e luogo,
/// il titolo se c'è posto, il canale riconoscibile. Si inclina di 3 gradi e il tocco apre la traccia.
struct ImpegnoGiornataApple: View {
    let evento: Appuntamento
    let larghezza: CGFloat
    let altezza: CGFloat
    @EnvironmentObject var stato: StatoShell
    @Environment(\.statoDettaglioApple) private var dettaglio

    var body: some View {
        let g = Tema.Apple.Agenda.Giornata.self
        let cliente = stato.cliente(evento.clienteId)
        let colore = Tema.Apple.Agenda.colore(cliente)
        let canale = stato.canaleAppuntamento(evento)
        let concluso = evento.stato == .concluso
        let forma = RoundedRectangle(cornerRadius: g.raggioImpegno, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: g.spazioRiga) {
                Text(cliente?.nome ?? evento.titolo)
                    .carattereApple(g.nome)
                    .foregroundColor(g.coloreNome)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text(TestiAgendaApple.quando(evento))
                    .carattereApple(g.quando)
                    .foregroundColor(g.coloreQuando)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let canale, larghezza >= g.larghezzaConCanale {
                    EtichettaCanaleApple(canale: canale, compatta: true)
                }
            }
            if altezza > g.altezzaConTitolo {
                Text(cliente == nil ? evento.tipo.nome : evento.titolo)
                    .carattereApple(g.titolo)
                    .foregroundColor(g.coloreTitolo)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(g.paddingImpegno)
        .padding(.leading, g.bordoImpegno)
        .frame(width: larghezza, height: altezza, alignment: .topLeading)
        .background {
            ZStack(alignment: .leading) {
                forma.fill(colore.opacity(g.opacitaFondo))
                Rectangle()
                    .fill(colore)
                    .frame(width: g.bordoImpegno)
            }
            .clipShape(forma)
        }
        .opacity(concluso ? g.opacitaConcluso : 1)
        .contentShape(forma)
        .onTapGesture(perform: apri)
        .inclinazione(massimo: g.inclinazione, raggio: g.raggioImpegno)
        .origineDettaglio(id: TracciaImpegnoApple.id(per: evento.id))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { apri() }
    }

    private func apri() {
        dettaglio?.apri(TracciaImpegnoApple.id(per: evento.id), misura: Tema.Apple.Agenda.Traccia.misura)
    }
}

// MARK: - Fascia «Da fare e da ricordare»

struct FasciaDaFareApple: View {
    let voci: [VoceFasciaApple]
    let sceglie: (VoceFasciaApple) -> Void

    var body: some View {
        let f = Tema.Apple.Agenda.Fascia.self
        let mostrate = Array(voci.prefix(f.massimo))
        let altre = voci.count - mostrate.count
        return VStack(alignment: .leading, spacing: f.spazio) {
            Text(TestiAgendaApple.fascia)
                .carattereApple(f.etichetta)
                .foregroundColor(f.coloreEtichetta)
            // Se le voci stanno, ferme; se no la striscia scorre e sfuma sul bordo destro (mai «Marco B» tagliato)
            ViewThatFits(in: .horizontal) {
                striscia(mostrate, altre: altre)
                ScrollView(.horizontal, showsIndicators: false) {
                    striscia(mostrate, altre: altre)
                        .padding(.trailing, f.sfumatura)
                }
                .sfumaturaBordoDestro(f.sfumatura)
            }
        }
        .padding(f.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func striscia(_ mostrate: [VoceFasciaApple], altre: Int) -> some View {
        let f = Tema.Apple.Agenda.Fascia.self
        return HStack(spacing: f.spazio) {
            ForEach(mostrate) { v in voce(v) }
            if altre > 0 {
                Text("+\(altre)")
                    .carattereApple(f.cliente)
                    .foregroundColor(f.coloreCliente)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    private func voce(_ v: VoceFasciaApple) -> some View {
        let f = Tema.Apple.Agenda.Fascia.self
        return Button { sceglie(v) } label: {
            HStack(spacing: f.spazioVoce) {
                Circle()
                    .fill(v.colore)
                    .frame(width: f.pallino, height: f.pallino)
                Text(v.testo)
                    .carattereApple(f.voce)
                    .foregroundColor(f.coloreVoce)
                    .lineLimit(1)
                if let c = v.cliente {
                    Text(c)
                        .carattereApple(f.cliente)
                        .foregroundColor(f.coloreCliente)
                        .lineLimit(1)
                }
            }
            .padding(f.paddingVoce)
            .background { Capsule(style: .continuous).fill(f.fondoVoce) }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
