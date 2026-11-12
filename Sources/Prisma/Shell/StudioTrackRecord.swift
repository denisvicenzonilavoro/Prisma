import SwiftUI

// Studio › Track record (Design/template-novita-specifica.md §4, template `studioHTML()` ramo track):
//
//   [Raccomandazioni dal 2024] [Accettate] [Ancora in essere dopo 12 mesi] [Rispetto all'alternativa, in media]
//   Le raccomandazioni e come sono andate   l'alternativa è ricostruita con i riferimenti del periodo
//   ┌ (MB) Fondo pensione aperto da 450 € al mese   [Accettata]   ╱╲╱── ┄┄    +4.180 € ┐
//   │      Marco Bianchi · settembre 2024 · invece di: …                    rispetto all'alternativa, stima
//   └ …
//
// - Le cifre vengono da MotoreTrackRecord sul registro delle raccomandazioni (`StatoShell.trackRecord()`, in cache):
//   le quattro tile si contano, le linee del confronto si disegnano, lo scarto è SEMPRE dichiarato «stima».
// - L'elenco è una sottovista `Equatable` che si rifà solo con una `ChiaveVista` nuova; il dettaglio nasce dalla card
//   toccata (`presentatoreDettaglio`), un solo dettaglio alla volta.
// - Il registro è immutabile: nel dettaglio si aggiungono solo note (con la data), mai modifiche. La riga
//   «Traccia per la conformità» lo dice.
// - Niente cifre inventate: senza raccomandazioni lo stato vuoto dice come si riempie; un'accettata senza valori
//   aggiornati o senza riferimenti dice «da misurare» e perché; un risultato negativo si mostra in rosso.
// - «Riduci movimento» e istantanee: lo fanno i componenti del tema (numeri, linee, cascata, inclinazione, dettaglio).
// Valori in DesignSystem/Apple/Tema.Apple+TrackRecord.swift.

// MARK: - Testi

enum TestiTrackRecord {
    static let titolo = "Le raccomandazioni e come sono andate"
    static let notaTitolo = "l’alternativa è ricostruita con i riferimenti del periodo"
    static let conformita = "Traccia per la conformità: le raccomandazioni registrate non si modificano. Le note si "
        + "aggiungono e restano con la loro data."
    static let piede = "Una traccia ordinata del tuo lavoro: utile anche per la conformità"
    static let vuotoTitolo = "Qui vedrai le tue raccomandazioni e come sono andate"
    static let vuotoTesto = "Ogni proposta che segni come presentata, accettata, rifiutata o rimandata entra qui da sola, "
        + "con le cifre di quel giorno. Quando il cliente sceglie, la scelta si aggiunge."
    static let vuotoNota = "Le proposte presentate prima di questa versione di Prisma non ci sono: la traccia parte dal "
        + "momento della presentazione."
    static let vaiAPosizioni = "Vai a Posizioni"
    static let motivoNonScritto = "Motivo non scritto nella scheda di adeguatezza."
    static let cifreDiQuelGiorno = "Le cifre di quel giorno, come le aveva calcolate Prisma."
    static let nessunaAlternativa = "Nessuna alternativa registrata."
    static let alternativaRicavata = "Ricavata da Prisma quando la proposta è stata registrata."
    static let senzaRiferimento = "Senza un riferimento l’alternativa non si ricostruisce: nessun confronto in cifre."
    static let nessunaNota = "Nessuna nota."
    static let segnapostoNota = "Scrivi una nota"
    static let aggiungiNota = "Aggiungi nota"
    static let senzaTitolo = "Raccomandazione senza titolo"
    static let clienteAssente = "Cliente non più in archivio"
    static let laTuaProposta = "la tua proposta"
    static let lAlternativa = "l’alternativa, stima"
    static let confrontoNelTempo = "Il confronto nel tempo · stima"
    static let testoOggi = "oggi"

    private static let formatoMeseAnno = Formati.formato("MMMM yyyy")
    private static let formatoGiorno = Formati.formato("d MMMM yyyy")

    /// «settembre 2024».
    static func meseAnno(_ d: Date) -> String { formatoMeseAnno.string(from: d).lowercased() }
    /// «12 marzo 2025».
    static func giorno(_ d: Date) -> String { formatoGiorno.string(from: d).lowercased() }

    /// «oggi» se la data è di questo mese, altrimenti «mese anno».
    static func fine(_ d: Date, oggi: Date = Date()) -> String {
        Calendar.current.isDate(d, equalTo: oggi, toGranularity: .month) ? testoOggi : meseAnno(d)
    }

    /// «+4.180 €», «−1.200 €», «0 €».
    static func euroConSegno(_ v: Double) -> String {
        (v.rounded() > 0 ? "+" : "") + FormatoCifra.euro.testo(v)
    }

    /// «+3,1% l’anno».
    static func puntiAnno(_ v: Double) -> String {
        (v > 0.04 ? "+" : "") + FormatoCifra.unDecimale(v) + "% l’anno"
    }

    /// La riga sotto il titolo della card: «Marco Bianchi · settembre 2024 · invece di: nessun versamento integrativo».
    static func sottotitolo(_ v: TrackRecord.Voce, cliente: Cliente?) -> String {
        var parti = [cliente?.nome ?? clienteAssente, meseAnno(v.raccomandazione.data)]
        let alternativa = v.raccomandazione.alternativa.descrizione.trimmingCharacters(in: .whitespacesAndNewlines)
        if !alternativa.isEmpty { parti.append("invece di: " + minuscolaIniziale(alternativa)) }
        return parti.joined(separator: " · ")
    }

    static func minuscolaIniziale(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.lowercased() + s.dropFirst()
    }

    /// Ciò che la colonna destra della card mostra.
    struct Risultato {
        enum Tono { case sale, scende, neutro }
        /// La cifra grande («+4.180 €», «200.000 €»); nil se non c'è.
        let cifra: String?
        /// Lo stato al posto della cifra («da misurare»); nil se c'è la cifra o se basta la didascalia.
        let stato: String?
        let tono: Tono
        let didascalia: String
    }

    static func risultato(_ v: TrackRecord.Voce) -> Risultato {
        if let c = PresentazioneTrackRecord.capitaleAssicurato(v) {
            return Risultato(cifra: FormatoCifra.euro.testo(c), stato: nil, tono: .neutro, didascalia: "di capitale assicurato")
        }
        switch v.misura {
        case .scarto(let s):
            let tono: Risultato.Tono = s.differenza.rounded() > 0 ? .sale : (s.differenza.rounded() < 0 ? .scende : .neutro)
            return Risultato(cifra: euroConSegno(s.differenza), stato: nil, tono: tono,
                             didascalia: "rispetto all’alternativa, stima")
        case .senzaRiferimento:
            return Risultato(cifra: nil, stato: "senza confronto", tono: .neutro,
                             didascalia: "l’alternativa non ha un riferimento")
        case .riferimentoMancante(let anno):
            return Risultato(cifra: nil, stato: "da misurare", tono: .neutro,
                             didascalia: "mancano i riferimenti dal \(String(anno))")
        case .pochiDati:
            return Risultato(cifra: nil, stato: "da misurare", tono: .neutro, didascalia: "serve un valore aggiornato")
        case .posizioneAssente:
            return Risultato(cifra: nil, stato: "da misurare", tono: .neutro, didascalia: "la posizione non è più in archivio")
        case .nonAccettata:
            switch PresentazioneTrackRecord.esito(v) {
            case .rifiutata:
                return Risultato(cifra: nil, stato: nil, tono: .neutro, didascalia: "il cliente ha scelto diversamente")
            case .rimandata(let quando):
                let testo = quando.map { "da riproporre a " + meseAnno($0) } ?? "rimandata dal cliente"
                return Risultato(cifra: nil, stato: nil, tono: .neutro, didascalia: testo)
            case .inAttesa, .accettata:
                return Risultato(cifra: nil, stato: nil, tono: .neutro, didascalia: "in attesa della scelta del cliente")
            }
        }
    }

    /// La frase al posto del grafico nel dettaglio, quando le linee non si possono disegnare.
    static func senzaLinee(_ v: TrackRecord.Voce) -> String {
        if PresentazioneTrackRecord.capitaleAssicurato(v) != nil {
            return "Una copertura non ha un rendimento: non c’è una linea da confrontare."
        }
        switch PresentazioneTrackRecord.esito(v) {
        case .rifiutata: return "Il cliente ha scelto diversamente: non c’è un risultato da misurare."
        case .inAttesa, .rimandata: return "Il confronto nel tempo comincia quando il cliente accetta."
        case .accettata:
            switch v.misura {
            case .posizioneAssente: return "La posizione collegata non è più in archivio: il confronto non si può disegnare."
            default: return "Il confronto nel tempo compare con almeno due valori della posizione: aggiungi un valore aggiornato in Posizioni."
            }
        }
    }

    /// La scelta del cliente con la data: «Accettata · 12 marzo 2025».
    static func scelta(_ r: Raccomandazione, esito: PresentazioneTrackRecord.Esito) -> String {
        guard let il = r.sceltaIl else { return esito.nome + " · presentata il " + giorno(r.data) }
        return esito.nome + " · " + giorno(il)
    }

    /// Le cifre delle tile.
    static func didascaliaRaccomandazioni(_ t: TrackRecord) -> String {
        "\(t.accettate) accettate · \(t.rifiutate) rifiutate · \(t.inAttesa) in attesa"
    }

    static func didascaliaAccettate(_ t: TrackRecord) -> String {
        let decise = t.accettate + t.rifiutate
        guard t.quotaAccettate != nil else { return "nessuna decisione ancora" }
        return decise == 1 ? "su 1 decisa" : "su \(decise) decise"
    }

    static func didascaliaInEssere(_ t: TrackRecord) -> String {
        if t.quotaInEssereDopo12Mesi != nil {
            let n = t.accettateDaAlmeno12Mesi
            return n == 1 ? "su 1 accettata da almeno 12 mesi" : "su \(n) accettate da almeno 12 mesi"
        }
        return t.accettate > 0 ? "nessuna accettata da 12 mesi" : "nessuna decisione ancora"
    }

    static func didascaliaScarto(_ t: TrackRecord) -> String {
        if t.scartoMedioAnnuo != nil {
            return t.misurate == 1 ? "stima su 1 misurata" : "stima su \(t.misurate) misurate"
        }
        return t.accettate > 0 ? "stima · servono valori aggiornati" : "stima · nessuna accettata"
    }
}

// MARK: - Richiesta delle istantanee

/// Il dettaglio che una scena delle istantanee chiede già aperto (Prisma --istantanee). Vale solo per lo stato della
/// scena (riferimento debole: le scene dopo non lo vedono), come `RichiestaIstantaneaPortafoglio`.
final class RichiestaIstantaneaTrack {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaTrack?

    private weak var stato: StatoShell?
    let dettaglio: String?

    private init(stato: StatoShell, dettaglio: String?) {
        self.stato = stato
        self.dettaglio = dettaglio
    }

    static func chiedi(_ s: StatoShell, dettaglio: String?) {
        attuale = RichiestaIstantaneaTrack(stato: s, dettaglio: dettaglio)
    }

    static func per(_ s: StatoShell) -> RichiestaIstantaneaTrack? {
        guard let r = attuale, r.stato === s else { return nil }
        return r
    }
}

// MARK: - Ordine e linee, in memoria

/// Le linee del confronto delle raccomandazioni, calcolate alla prima card (o al primo dettaglio) che le chiede e tenute
/// finché valgono i dati dei calcoli: la memoria sta in `StatoShell.ricavato`, con la stessa validità del track record
/// da cui vengono le voci. Così né l'elenco (anche a ogni passo del ridimensionamento) né il dettaglio rifanno
/// MotoreAndamento e il confronto con il riferimento a ogni disegno. Solo dal thread principale.
private final class MemoriaTrackRecord {
    /// La tabella dei riferimenti di questi dati (i riferimenti entrano nei calcoli).
    let tabella: TabellaRiferimenti
    /// Le linee per id della voce; nil = la voce non ha linee (anche questo resta in memoria).
    private var fatte: [String: PresentazioneTrackRecord.Linee?] = [:]

    init(tabella: TabellaRiferimenti) {
        self.tabella = tabella
    }

    func linee(_ v: TrackRecord.Voce) -> PresentazioneTrackRecord.Linee? {
        if let l = fatte[v.id] { return l }
        let l = PresentazioneTrackRecord.linee(v, tabella: tabella)
        fatte.updateValue(l, forKey: v.id)
        return l
    }
}

private extension StatoShell {
    /// Le voci del track record di oggi nell'ordine dell'elenco, ordinate una volta per dati dei calcoli e giorno.
    func vociTrackRecordOrdinate() -> [TrackRecord.Voce] {
        ricavato("studio.track.ordine") { PresentazioneTrackRecord.ordinate(trackRecord().voci) }
    }

    /// La memoria delle linee (con la tabella dei riferimenti) per i dati dei calcoli di adesso. I riferimenti si leggono
    /// senza iscrivere la vista alle impostazioni: entrano nei calcoli, quindi in `versioneCalcoli`.
    func memoriaTrackRecord() -> MemoriaTrackRecord {
        ricavato("studio.track.linee") { MemoriaTrackRecord(tabella: TabellaRiferimenti(dati.impostazioniDeiCalcoli.riferimenti)) }
    }
}

// MARK: - La scheda

struct TrackRecordStudioVista: View {
    let stato: StatoShell
    /// La base della cascata (0,14 all'apertura, 0 dopo un cambio di scheda).
    let base: Double
    @StateObject private var dettaglio: StatoDettaglio

    init(stato: StatoShell, base: Double) {
        self.stato = stato
        self.base = base
        _dettaglio = StateObject(wrappedValue: Self.dettaglioIniziale(stato))
    }

    private static func dettaglioIniziale(_ s: StatoShell) -> StatoDettaglio {
        guard let id = RichiestaIstantaneaTrack.per(s)?.dettaglio else { return StatoDettaglio() }
        return StatoDettaglio(aperto: id, misura: Tema.Apple.Studio.Track.Dettaglio.misura)
    }

    var body: some View {
        let d = dettaglio
        let apri: (String) -> Void = { id in
            d.apri(id, misura: Tema.Apple.Studio.Track.Dettaglio.misura)
        }
        return ElencoTrackRecord(stato: stato, chiave: stato.chiaveVista, base: base, apri: apri)
            .equatable()
            .presentatoreDettaglio(dettaglio) { id in
                DettaglioRaccomandazione(stato: stato, id: id)
            }
            .onDisappear { dettaglio.chiudi(subito: true) }
    }
}

/// Le tile, il titolo e le card: si rifà solo con una `ChiaveVista` nuova (non a ogni passo del dettaglio).
private struct ElencoTrackRecord: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    let base: Double
    let apri: (String) -> Void

    nonisolated static func == (a: ElencoTrackRecord, b: ElencoTrackRecord) -> Bool {
        a.stato === b.stato && a.chiave == b.chiave && a.base == b.base
    }

    var body: some View {
        // Dalla cache (DerivatiDati): calcolato una volta per versione dei dati e per giorno, mai qui
        let t = stato.trackRecord()
        let prova = stato.haDatiDiProva
        // Anche l'ordine e le linee delle card vengono dalla cache, fuori dal GeometryReader: a ogni passo del
        // ridimensionamento cambiano solo la larghezza e ciò che ne dipende (grafico e colonne delle tile)
        let voci: [TrackRecord.Voce] = t.raccomandazioni == 0 ? [] : stato.vociTrackRecordOrdinate()
        let memoria = stato.memoriaTrackRecord()
        return GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                contenuto(t, voci: voci, memoria: memoria, prova: prova, larghezza: geo.size.width)
                    .frame(width: geo.size.width, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder private func contenuto(_ t: TrackRecord, voci: [TrackRecord.Voce], memoria: MemoriaTrackRecord,
                                        prova: Bool, larghezza: CGFloat) -> some View {
        if t.raccomandazioni == 0 {
            VuotoTrackRecord(apriPosizioni: { stato.apri(.posizioni) })
                .entrataCascata(0, base: base)
        } else {
            pieno(t, voci: voci, memoria: memoria, prova: prova, larghezza: larghezza)
        }
    }

    private func pieno(_ t: TrackRecord, voci: [TrackRecord.Voce], memoria: MemoriaTrackRecord, prova: Bool,
                       larghezza: CGFloat) -> some View {
        let d = Tema.Apple.Studio.Track.Disposizione.self
        let conGrafico = larghezza >= d.larghezzaConGrafico
        let colonne = larghezza < d.larghezzaTileStrette ? d.colonneTileStrette : d.colonneTile
        return VStack(alignment: .leading, spacing: 0) {
            TileTrackRecord(t: t, colonne: colonne, base: base)
            TitoloTrackRecord(prova: prova)
                .padding(.top, d.titoloSopra)
                .padding(.horizontal, d.titoloLati)
                .padding(.bottom, d.titoloSotto)
                .entrataCascata(d.primaCard - 1, base: base)
            VStack(alignment: .leading, spacing: d.spazioCard) {
                ForEach(Array(voci.enumerated()), id: \.element.id) { i, v in
                    // `.equatable()`: a un ridimensionamento o a un cambio d'altre voci le card uguali non rifanno il corpo
                    CardRaccomandazione(voce: v, cliente: stato.cliente(v.raccomandazione.clienteId),
                                        linee: conGrafico ? memoria.linee(v) : nil,
                                        conGrafico: conGrafico, indiceLinee: 2 * i,
                                        apri: { apri(v.id) })
                        .equatable()
                        .entrataCascata(min(d.primaCard + i, d.indiceMassimoCascata), base: base)
                }
            }
            .padding(.bottom, d.fondo)
        }
    }
}

// MARK: - Le quattro tile

private struct TileTrackRecord: View {
    let t: TrackRecord
    let colonne: Int
    let base: Double

    var body: some View {
        let d = Tema.Apple.Studio.Track.Disposizione.self
        let tile = Tema.Apple.Studio.Track.Tile.self
        let griglia = Array(repeating: GridItem(.flexible(), spacing: d.spazioTile, alignment: .topLeading), count: colonne)
        let scarto = t.scartoMedioAnnuo
        let coloreScarto: Color = {
            guard let s = scarto else { return tile.coloreValore }
            if s > 0.04 { return Tema.Apple.Studio.Track.coloreSale }
            if s < -0.04 { return Tema.Apple.Studio.Track.coloreScende }
            return tile.coloreValore
        }()
        return LazyVGrid(columns: griglia, alignment: .leading, spacing: d.spazioTile) {
            TileCifraTrack(etichetta: t.dal.map { "Raccomandazioni dal \(String($0))" } ?? "Raccomandazioni",
                           valore: Double(t.raccomandazioni), formato: .intero, indice: 0, colore: tile.coloreValore,
                           didascalia: TestiTrackRecord.didascaliaRaccomandazioni(t))
                .entrataCascata(0, base: base)
            TileCifraTrack(etichetta: "Accettate", valore: t.quotaAccettate.map { $0 * 100 }, formato: .percentuale,
                           indice: 1, colore: tile.coloreValore, didascalia: TestiTrackRecord.didascaliaAccettate(t))
                .entrataCascata(1, base: base)
            TileCifraTrack(etichetta: "Ancora in essere dopo 12 mesi", valore: t.quotaInEssereDopo12Mesi.map { $0 * 100 },
                           formato: .percentuale, indice: 2, colore: tile.coloreValore,
                           didascalia: TestiTrackRecord.didascaliaInEssere(t))
                .entrataCascata(2, base: base)
            TileCifraTrack(etichetta: "Rispetto all’alternativa, in media", valore: scarto,
                           formato: .personalizzato(TestiTrackRecord.puntiAnno), indice: 3, colore: coloreScarto,
                           didascalia: TestiTrackRecord.didascaliaScarto(t))
                .entrataCascata(3, base: base)
        }
    }
}

/// Una tile: etichetta `.k`, cifra `.v` che si conta (o «—»), didascalia.
private struct TileCifraTrack: View {
    let etichetta: String
    let valore: Double?
    let formato: FormatoCifra
    let indice: Int
    let colore: Color
    let didascalia: String

    var body: some View {
        let t = Tema.Apple.Studio.Track.Tile.self
        return VStack(alignment: .leading, spacing: t.spazio) {
            Text(etichetta)
                .carattereApple(t.etichetta)
                .foregroundColor(t.coloreEtichetta)
                .lineLimit(1)
                .minimumScaleFactor(Tema.Apple.Studio.Card.riduzioneTesto)
            Group {
                if let valore {
                    NumeroCheConta(valore, formato: formato, indice: indice)
                } else {
                    Text(verbatim: "—")
                }
            }
            .carattereApple(t.valore)
            .foregroundColor(valore == nil ? t.coloreValore : colore)
            .lineLimit(1)
            .minimumScaleFactor(t.riduzioneValore)
            Text(didascalia)
                .carattereApple(t.didascalia)
                .foregroundColor(t.coloreDidascalia)
                .lineLimit(1)
                .minimumScaleFactor(Tema.Apple.Studio.Card.riduzioneTesto)
        }
        .padding(t.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(t.superficie, raggio: t.raggio)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Riga del titolo

private struct TitoloTrackRecord: View {
    let prova: Bool

    var body: some View {
        let t = Tema.Apple.Studio.Track.Titolo.self
        let d = Tema.Apple.Studio.Track.Disposizione.self
        return HStack(alignment: .firstTextBaseline, spacing: d.spazioNota) {
            Text(TestiTrackRecord.titolo)
                .carattereApple(t.titolo)
                .foregroundColor(t.coloreTitolo)
                .lineLimit(1)
                .layoutPriority(1)
            Text(TestiTrackRecord.notaTitolo)
                .carattereApple(t.nota)
                .foregroundColor(t.coloreNota)
                .lineLimit(1)
            if prova {
                Text(TestiStudio.datiDiProva)
                    .carattereApple(t.nota)
                    .foregroundColor(t.coloreProva)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Stato vuoto

private struct VuotoTrackRecord: View {
    let apriPosizioni: () -> Void

    var body: some View {
        let v = Tema.Apple.Studio.Track.Vuoto.self
        return VStack(alignment: .leading, spacing: v.spazio) {
            Text(TestiTrackRecord.vuotoTitolo)
                .carattereApple(v.titolo)
                .foregroundColor(v.coloreTitolo)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiTrackRecord.vuotoTesto)
                .carattereApple(v.testo)
                .foregroundColor(v.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiTrackRecord.vuotoNota)
                .carattereApple(v.nota)
                .foregroundColor(v.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
            Button(TestiTrackRecord.vaiAPosizioni, action: apriPosizioni)
                .buttonStyle(.apple)
                .padding(.top, v.pulsanteSopra)
        }
        .padding(v.padding)
        .frame(maxWidth: v.larghezza, alignment: .leading)
        .superficieApple(v.superficie, raggio: v.raggio)
        .padding(.top, v.sopra)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - La card di una raccomandazione

/// L'avatar del cliente (con un segno neutro se il cliente non c'è più).
private struct AvatarTrackRecord: View {
    let cliente: Cliente?
    let lato: CGFloat

    var body: some View {
        AvatarCliente(iniziali: cliente?.iniziali ?? "?", tinta: (cliente?.tinta ?? .blu).colori, lato: lato)
    }
}

private struct CardRaccomandazione: View, Equatable {
    let voce: TrackRecord.Voce
    let cliente: Cliente?
    let linee: PresentazioneTrackRecord.Linee?
    let conGrafico: Bool
    /// Indice del primo tracciato della card nella schermata (alternativa, poi proposta).
    let indiceLinee: Int
    /// Apre il dettaglio di questa voce: chiama sempre lo stesso presentatore della scheda, quindi non conta nel confronto.
    let apri: () -> Void

    nonisolated static func == (a: CardRaccomandazione, b: CardRaccomandazione) -> Bool {
        a.voce == b.voce && a.cliente == b.cliente && a.linee == b.linee && a.conGrafico == b.conGrafico
            && a.indiceLinee == b.indiceLinee
    }

    var body: some View {
        let c = Tema.Apple.Studio.Track.Card.self
        let forma = RoundedRectangle(cornerRadius: c.raggio, style: .continuous)
        return HStack(alignment: .center, spacing: c.spazio) {
            AvatarTrackRecord(cliente: cliente, lato: c.avatar)
            testi
                .frame(maxWidth: conGrafico ? c.larghezzaTesto : .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: c.spazioTesti) {
                PillolaEsitoApple(esito: PresentazioneTrackRecord.esito(voce))
                if let canale = voce.raccomandazione.canale {
                    EtichettaCanaleApple(canale: canale, compatta: true)
                }
            }
            if conGrafico {
                Spacer(minLength: 0)
                Group {
                    if let linee {
                        GraficoLineeTrackRecord(linee: linee, indice: indiceLinee)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: c.grafico.width, height: c.grafico.height)
                .accessibilityHidden(true)
            }
            RisultatoCardTrackRecord(risultato: TestiTrackRecord.risultato(voce))
                .frame(width: c.larghezzaDestra, alignment: .trailing)
        }
        .padding(c.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(forma)
        .onTapGesture(perform: apri)
        .superficieApple(c.superficie, raggio: c.raggio)
        .inclinazione(massimo: c.inclinazione, raggio: c.raggio)
        .origineDettaglio(id: voce.id)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var testi: some View {
        let c = Tema.Apple.Studio.Track.Card.self
        let proposta = voce.raccomandazione.proposta.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: c.spazioTesti) {
            Text(proposta.isEmpty ? TestiTrackRecord.senzaTitolo : proposta)
                .carattereApple(c.titolo)
                .foregroundColor(c.coloreTitolo)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(TestiTrackRecord.sottotitolo(voce, cliente: cliente))
                .carattereApple(c.sotto)
                .foregroundColor(c.coloreSotto)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// La colonna destra della card: la cifra (o lo stato) e la didascalia.
private struct RisultatoCardTrackRecord: View {
    let risultato: TestiTrackRecord.Risultato

    var body: some View {
        let c = Tema.Apple.Studio.Track.Card.self
        return VStack(alignment: .trailing, spacing: c.spazioDestra) {
            if let cifra = risultato.cifra {
                Text(cifra)
                    .carattereApple(c.risultato)
                    .foregroundColor(ColoriTrackRecord.tono(risultato.tono))
                    .lineLimit(1)
                    .minimumScaleFactor(c.riduzione)
            } else if let stato = risultato.stato {
                Text(stato)
                    .carattereApple(c.daMisurare)
                    .foregroundColor(Tema.Apple.Studio.Track.coloreNeutro)
                    .lineLimit(1)
                    .minimumScaleFactor(c.riduzione)
            }
            Text(risultato.didascalia)
                .carattereApple(c.didascalia)
                .foregroundColor(c.coloreDidascalia)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum ColoriTrackRecord {
    static func tono(_ t: TestiTrackRecord.Risultato.Tono) -> Color {
        let k = Tema.Apple.Studio.Track.self
        switch t {
        case .sale: return k.coloreSale
        case .scende: return k.coloreScende
        case .neutro: return Tema.Apple.Colore.inchiostro
        }
    }
}

/// Le due linee del confronto: l'alternativa (tratteggiata, stima) e la proposta, che si disegnano.
private struct GraficoLineeTrackRecord: View {
    let linee: PresentazioneTrackRecord.Linee
    let indice: Int

    var body: some View {
        let t = Tema.Apple.Studio.Track.self
        return ZStack {
            if !linee.alternativa.isEmpty {
                TracciatoGrafico(punti: linee.alternativa, colore: t.lineaAlternativa, spessore: t.spessoreAlternativa,
                                 tratteggio: t.tratteggioAlternativa, indice: min(indice, t.indiceMassimoLinee))
            }
            TracciatoGrafico(punti: linee.proposta, colore: t.lineaProposta, spessore: t.spessoreProposta,
                             indice: min(indice + 1, t.indiceMassimoLinee))
        }
    }
}

/// Il segno della legenda: un tratto orizzontale, pieno o tratteggiato.
private struct SegnoLegendaTrack: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

// MARK: - Il dettaglio

struct DettaglioRaccomandazione: View {
    let stato: StatoShell
    let id: String

    @Environment(\.statoDettaglioApple) private var dettaglio

    var body: some View {
        if let v = stato.trackRecord().voci.first(where: { $0.id == id }) {
            contenuto(v)
        }
    }

    private func contenuto(_ v: TrackRecord.Voce) -> some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        let cliente = stato.cliente(v.raccomandazione.clienteId)
        // Tabella e linee dalla memoria dell'elenco (stessa validità del track record), senza iscrivere il dettaglio a
        // tutte le impostazioni: i riferimenti entrano nei calcoli, quindi nel track record
        let memoria = stato.memoriaTrackRecord()
        return VStack(alignment: .leading, spacing: 0) {
            TestataDettaglioTrack(voce: v, cliente: cliente)
            HStack(alignment: .top, spacing: d.spazioColonne) {
                ScrollView(.vertical, showsIndicators: false) {
                    ColonnaSinistraTrack(voce: v, tabella: memoria.tabella, solaLettura: stato.solaLettura,
                                         aggiungi: { testo in aggiungi(testo, a: v) })
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                ColonnaDestraTrack(voce: v, linee: memoria.linee(v))
                    .frame(width: d.larghezzaDestra, alignment: .topLeading)
            }
            .padding(.top, d.corpoSopra)
            .frame(maxHeight: .infinity, alignment: .top)
            piede(v)
                .padding(.top, d.piedeSopra)
        }
    }

    private func piede(_ v: TrackRecord.Voce) -> some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return HStack(spacing: d.spazioPiede) {
            Button("Chiudi") { dettaglio?.chiudi() }
                .buttonStyle(.appleGrande)
            if let p = v.posizione {
                Button("Apri la posizione") {
                    dettaglio?.chiudi(subito: true)
                    stato.apriPosizione(p)
                }
                .buttonStyle(.apple)
            }
            Text(TestiTrackRecord.piede)
                .carattereApple(d.nota)
                .foregroundColor(d.coloreNota)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Aggiunge la nota alla raccomandazione: solo un'aggiunta, con la data di oggi. Le note di prima restano.
    /// true = aggiunta (il campo si svuota).
    private func aggiungi(_ testo: String, a v: TrackRecord.Voce) -> Bool {
        guard !stato.solaLettura else { return false }
        return stato.aggiungiNota(testo, aRaccomandazione: v.raccomandazione.id)
    }
}

/// Testata del dettaglio: avatar 54, «SETTEMBRE 2024 · MARCO BIANCHI», la proposta in grande, il canale.
private struct TestataDettaglioTrack: View {
    let voce: TrackRecord.Voce
    let cliente: Cliente?

    var body: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        let r = voce.raccomandazione
        let proposta = r.proposta.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(alignment: .center, spacing: d.spazioTestata) {
            AvatarTrackRecord(cliente: cliente, lato: d.avatar)
            VStack(alignment: .leading, spacing: d.spazioEtichettaTitolo) {
                Text(TestiTrackRecord.meseAnno(r.data) + " · " + (cliente?.nome ?? TestiTrackRecord.clienteAssente))
                    .carattereApple(d.etichetta)
                    .foregroundColor(d.coloreEtichetta)
                    .lineLimit(1)
                Text(proposta.isEmpty ? TestiTrackRecord.senzaTitolo : proposta)
                    .carattereApple(d.titolo)
                    .foregroundColor(d.coloreTitolo)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: d.larghezzaTitolo, alignment: .leading)
            }
            Spacer(minLength: 0)
            if let canale = r.canale {
                EtichettaCanaleApple(canale: canale)
            }
        }
        .padding(.trailing, d.margineChiudi)
    }
}

/// Un blocco della colonna sinistra: etichetta `.lbl` e il suo contenuto.
private struct BloccoTrack<Contenuto: View>: View {
    let titolo: String
    let contenuto: Contenuto

    init(_ titolo: String, @ViewBuilder contenuto: () -> Contenuto) {
        self.titolo = titolo
        self.contenuto = contenuto()
    }

    var body: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return VStack(alignment: .leading, spacing: d.sottoEtichetta) {
            Text(titolo)
                .carattereApple(d.etichetta)
                .foregroundColor(d.coloreEtichetta)
            contenuto
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Una frase piccola del dettaglio.
private struct NotaDettaglioTrack: View {
    let testo: String
    var colore: Color = Tema.Apple.Studio.Track.Dettaglio.coloreNota

    var body: some View {
        Text(testo)
            .carattereApple(Tema.Apple.Studio.Track.Dettaglio.nota)
            .foregroundColor(colore)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Perché, l'alternativa, la scelta del cliente e le note.
private struct ColonnaSinistraTrack: View {
    let voce: TrackRecord.Voce
    let tabella: TabellaRiferimenti
    let solaLettura: Bool
    /// Aggiunge la nota scritta; true = aggiunta.
    let aggiungi: (String) -> Bool

    var body: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return VStack(alignment: .leading, spacing: d.fraBlocchi) {
            perche
            alternativa
            scelta
            note
        }
    }

    private var r: Raccomandazione { voce.raccomandazione }

    private var perche: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        let motivo = r.motivazione.trimmingCharacters(in: .whitespacesAndNewlines)
        return BloccoTrack("Perché l’avevi proposta") {
            Text(motivo.isEmpty ? TestiTrackRecord.motivoNonScritto : motivo)
                .carattereApple(d.testo)
                .foregroundColor(motivo.isEmpty ? d.mancante : d.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
            if !r.cifre.righe.isEmpty {
                CifreRegistrateTrack(righe: r.cifre.righe)
                    .padding(.top, d.notaSopra)
                NotaDettaglioTrack(testo: TestiTrackRecord.cifreDiQuelGiorno)
            }
        }
    }

    private var alternativa: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        let a = r.alternativa
        let testo = a.descrizione.trimmingCharacters(in: .whitespacesAndNewlines)
        let serie = a.serieRiferimento.flatMap { tabella.serie($0) }
        return BloccoTrack("L’alternativa") {
            Text(testo.isEmpty ? TestiTrackRecord.nessunaAlternativa : testo)
                .carattereApple(d.testo)
                .foregroundColor(testo.isEmpty ? d.mancante : d.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
            if let serie {
                NotaDettaglioTrack(testo: "Ricostruita al ritmo di: \(serie.nome).")
            } else if !testo.isEmpty {
                NotaDettaglioTrack(testo: TestiTrackRecord.senzaRiferimento)
            }
            if a.ricavata && !testo.isEmpty {
                NotaDettaglioTrack(testo: TestiTrackRecord.alternativaRicavata)
            }
        }
    }

    private var scelta: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        let esito = PresentazioneTrackRecord.esito(voce)
        let prima = Array(r.scelte.dropLast())
        let riprendere: Date? = {
            if case .rimandata(let quando) = esito { return quando }
            return nil
        }()
        return BloccoTrack("Cosa ha scelto il cliente") {
            Text(TestiTrackRecord.scelta(r, esito: esito))
                .carattereApple(d.scelta)
                .foregroundColor(d.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
            if let quando = riprendere {
                NotaDettaglioTrack(testo: "Da riproporre a " + TestiTrackRecord.meseAnno(quando) + ".")
            }
            ForEach(Array(prima.enumerated()), id: \.offset) { _, s in
                NotaDettaglioTrack(testo: "Prima: " + s.scelta.nome.lowercased() + " dal " + TestiTrackRecord.giorno(s.data))
            }
        }
    }

    private var note: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return BloccoTrack("Note") {
            if r.note.isEmpty {
                NotaDettaglioTrack(testo: TestiTrackRecord.nessunaNota, colore: d.mancante)
            }
            VStack(alignment: .leading, spacing: d.fraNote) {
                ForEach(Array(r.note.enumerated()), id: \.offset) { _, n in
                    VStack(alignment: .leading, spacing: d.spazioEtichettaTitolo) {
                        Text(TestiTrackRecord.giorno(n.data))
                            .carattereApple(d.dataNota)
                            .foregroundColor(d.coloreDataNota)
                        Text(n.testo)
                            .carattereApple(d.testoNota)
                            .foregroundColor(d.coloreTesto)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            CampoNotaTrack(solaLettura: solaLettura, aggiungi: aggiungi)
            NotaDettaglioTrack(testo: TestiTrackRecord.conformita)
                .padding(.top, d.notaSopra)
        }
    }
}

/// Il campo della nota nuova con «Aggiungi nota». La bozza vive qui: un tasto ridisegna solo il campo, non il dettaglio
/// (colonne, linee, testata). In sola lettura non c'è niente (e nemmeno spazio), ma la bozza resta.
private struct CampoNotaTrack: View {
    let solaLettura: Bool
    let aggiungi: (String) -> Bool

    /// La nota che si sta scrivendo (si aggiunge con «Aggiungi nota», poi il campo si svuota).
    @State private var bozza = ""

    var body: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        let vuota = bozza.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !solaLettura {
            HStack(spacing: d.spazioCampo) {
                TextField(TestiTrackRecord.segnapostoNota, text: $bozza)
                    .campoTesto()
                    .onSubmit(invia)
                Button(TestiTrackRecord.aggiungiNota, action: invia)
                    .buttonStyle(.apple)
                    .disabled(vuota)
            }
            .padding(.top, d.campoSopra)
        }
    }

    private func invia() {
        if aggiungi(bozza) { bozza = "" }
    }
}

/// Le cifre registrate al momento della raccomandazione: etichetta a sinistra, valore a destra, il filo fra le righe.
private struct CifreRegistrateTrack: View {
    let righe: [RigaRaccomandazione]

    var body: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(righe.enumerated()), id: \.offset) { i, riga in
                HStack(alignment: .firstTextBaseline, spacing: d.spazioCampo) {
                    Text(riga.etichetta)
                        .carattereApple(d.rigaCifre)
                        .foregroundColor(d.coloreEtichettaCifre)
                        .lineLimit(1)
                    Spacer(minLength: d.spazioCampo)
                    Text(riga.valore)
                        .carattereApple(d.rigaCifre)
                        .foregroundColor(d.coloreValoreCifre)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
                .padding(.vertical, d.paddingRigaCifre)
                .overlay(alignment: .top) {
                    if i > 0 {
                        Rectangle()
                            .fill(d.filo)
                            .frame(height: Tema.Apple.Misura.bordo)
                    }
                }
            }
        }
    }
}

/// Il confronto nel tempo (stima), la legenda e la cifra del risultato.
private struct ColonnaDestraTrack: View {
    let voce: TrackRecord.Voce
    let linee: PresentazioneTrackRecord.Linee?

    var body: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return VStack(alignment: .leading, spacing: 0) {
            Text(TestiTrackRecord.confrontoNelTempo)
                .carattereApple(d.etichetta)
                .foregroundColor(d.coloreEtichetta)
                .padding(.bottom, d.sottoEtichetta)
            if let linee {
                grafico(linee)
                legenda(alternativa: !linee.alternativa.isEmpty)
                    .padding(.top, d.legendaSopra)
            } else {
                Text(TestiTrackRecord.senzaLinee(voce))
                    .carattereApple(d.nota)
                    .foregroundColor(d.coloreNota)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(d.paddingVuoto)
                    .frame(width: d.grafico.width, height: d.grafico.height)
                    .superficieApple(d.fondoVuoto, raggio: d.raggioVuoto)
            }
            risultato
                .padding(.top, d.cifraSopra)
        }
    }

    private func grafico(_ l: PresentazioneTrackRecord.Linee) -> some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return VStack(spacing: 0) {
            GraficoLineeTrackRecord(linee: l, indice: 0)
                .frame(height: d.altezzaLinee)
            HStack {
                Text(TestiTrackRecord.meseAnno(l.dal))
                Spacer(minLength: 0)
                Text(TestiTrackRecord.fine(l.al))
            }
            .carattereApple(d.asse)
            .foregroundColor(d.coloreAsse)
            .lineLimit(1)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: d.grafico.width, height: d.grafico.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Il confronto nel tempo tra la proposta e l’alternativa, stima"))
    }

    private func legenda(alternativa: Bool) -> some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        let t = Tema.Apple.Studio.Track.self
        return HStack(spacing: d.spazioLegenda) {
            voceLegenda(TestiTrackRecord.laTuaProposta, colore: t.lineaProposta, tratteggio: nil)
            if alternativa {
                voceLegenda(TestiTrackRecord.lAlternativa, colore: t.lineaAlternativa, tratteggio: t.tratteggioAlternativa)
            }
        }
    }

    private func voceLegenda(_ testo: String, colore: Color, tratteggio: [CGFloat]?) -> some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        return HStack(spacing: d.spazioSegno) {
            SegnoLegendaTrack()
                .stroke(colore, style: StrokeStyle(lineWidth: d.segno.height, lineCap: .round, dash: tratteggio ?? []))
                .frame(width: d.segno.width, height: d.segno.height)
            Text(testo)
                .carattereApple(d.legenda)
                .foregroundColor(d.coloreLegenda)
                .lineLimit(1)
        }
    }

    private var scarto: TrackRecord.Scarto? {
        if case .scarto(let s) = voce.misura { return s }
        return nil
    }

    @ViewBuilder private var risultato: some View {
        let d = Tema.Apple.Studio.Track.Dettaglio.self
        if let c = PresentazioneTrackRecord.capitaleAssicurato(voce) {
            VStack(alignment: .leading, spacing: d.notaSopra) {
                NumeroCheConta(c, formato: .euro, indice: 0)
                    .carattereApple(d.cifra)
                    .foregroundColor(d.coloreTesto)
                    .lineLimit(1)
                    .minimumScaleFactor(d.riduzioneCifra)
                NotaDettaglioTrack(testo: "di capitale assicurato: una copertura non ha un rendimento da confrontare")
            }
        } else if let s = scarto {
            VStack(alignment: .leading, spacing: d.notaSopra) {
                NumeroCheConta(abs(s.differenza), formato: .euro, indice: 0)
                    .carattereApple(d.cifra)
                    .foregroundColor(ColoriTrackRecord.tono(Self.tono(s.differenza)))
                    .lineLimit(1)
                    .minimumScaleFactor(d.riduzioneCifra)
                NotaDettaglioTrack(testo: Self.frase(s))
            }
        } else {
            let r = TestiTrackRecord.risultato(voce)
            VStack(alignment: .leading, spacing: d.notaSopra) {
                if let stato = r.stato {
                    Text(stato)
                        .carattereApple(Tema.Apple.Studio.Track.Card.daMisurare)
                        .foregroundColor(Tema.Apple.Studio.Track.coloreNeutro)
                }
                NotaDettaglioTrack(testo: r.didascalia)
            }
        }
    }

    private static func tono(_ differenza: Double) -> TestiTrackRecord.Risultato.Tono {
        let x = differenza.rounded()
        return x > 0 ? .sale : (x < 0 ? .scende : .neutro)
    }

    /// «in più rispetto all’alternativa, stima · +2,9 punti l’anno · 2026 stimato dall’ultimo valore noto».
    private static func frase(_ s: TrackRecord.Scarto) -> String {
        let x = s.differenza.rounded()
        var parti = [x > 0 ? "in più rispetto all’alternativa, stima"
                     : (x < 0 ? "in meno rispetto all’alternativa, stima" : "in linea con l’alternativa, stima")]
        if let p = s.puntiAnnui, p.isFinite {
            parti.append(TestiTrackRecord.puntiAnno(p).replacingOccurrences(of: "%", with: " punti"))
        }
        if !s.anniStimati.isEmpty {
            let anni = s.anniStimati.map { String($0) }.joined(separator: ", ")
            parti.append(s.anniStimati.count == 1 ? "\(anni) stimato dall’ultimo valore noto"
                         : "\(anni) stimati dall’ultimo valore noto")
        }
        return parti.joined(separator: " · ")
    }
}
