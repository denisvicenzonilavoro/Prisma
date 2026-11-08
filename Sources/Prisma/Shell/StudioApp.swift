import SwiftUI

// L'app Studio (versione «Orizzonte», Design/template-novita-specifica.md §1.6 e §2): il lavoro del consulente visto
// come un portafoglio. Testata «Il tuo studio. · Il tuo lavoro, come un portafoglio» (`AppPrisma.titoloIntestazione` e
// `occhiello`) con il segmentato a pillola Cruscotto · Parcelle e fatture · Track record · Esame OCF a destra.
// Cruscotto (StudioCruscotto.swift), Parcelle e fatture (StudioParcelle.swift), Track record (StudioTrackRecord.swift) ed
// Esame OCF (StudioEsameOCF.swift); una scheda che non c'è ancora direbbe con una nota sobria cosa arriverà.
//
// - Le cifre vengono da MotoreStudio, tenute in cache da StatoShell (`cruscottoStudio()`, DerivatiDati): il corpo è una
//   vista `Equatable` che si rifà solo con una `ChiaveVista` nuova (dati dei calcoli, giorno, ora, modalità cliente).
// - Cambio di scheda (`rimonta`): il contenuto svanisce in 0,13 s fino a scala 0,99, poi rientra a cascata da 0.
// - Modalità cliente: Studio è il lavoro del consulente (provvigioni, parcelle, obiettivi), non si mostra al cliente.
// - «Riduci movimento» e istantanee: tutto subito fermo nello stato finale.
// Valori in DesignSystem/Apple/Tema.Apple+Studio.swift.

/// Le schede di Studio, nell'ordine del segmentato.
enum SchedaStudio: String, CaseIterable, Identifiable, Hashable {
    case cruscotto, fatture, track, ocf, palestra

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .cruscotto: return "Cruscotto"
        // Con «Luce» i titoli si accorciano per farci stare le schede nuove (Design/template-luce-specifica.md, riga 2085)
        case .fatture: return "Parcelle"
        case .track: return "Track record"
        case .ocf: return "OCF"
        case .palestra: return "Palestra"
        }
    }

    /// Cosa arriverà nelle schede che in questo giro non ci sono ancora (nil per il Cruscotto).
    var prossima: String? {
        switch self {
        case .cruscotto:
            return nil
        case .fatture:
            // C'è dal giro 2 (StudioParcelle.swift)
            return nil
        case .track:
            // C'è dal giro 2 (StudioTrackRecord.swift)
            return nil
        case .ocf:
            // C'è dal giro 6 (StudioEsameOCF.swift)
            return nil
        case .palestra:
            // C'è dal giro 5 di Luce (StudioPalestra.swift)
            return nil
        }
    }
}

// MARK: - Testi

/// I testi di Studio che servono in più viste (cruscotto, scrivania, impostazioni).
enum TestiStudio {
    static let titoloRiservato = "Studio resta tuo"
    static let testoRiservato = "In modalità cliente le cifre del tuo lavoro (provvigioni, parcelle e obiettivi) non si "
        + "mostrano. Esci dalla modalità cliente per rivederle."
    static let parcelleInArrivo = "Le parcelle arrivano con Parcelle e fatture"
    static let provvigioniStimate = "provvigioni stimate dalle tue aliquote"
    static let parcelleConsulenza = "parcelle della consulenza"
    static let primoAnno = "primo anno in Prisma"
    static let datiDiProva = "dati di prova"
    static let obiettiviScrivania = "Dai a Studio gli obiettivi dell’anno"
    static let senzaAliquoteScrivania = "stima senza le tue aliquote"
    static let inserisciAliquote = "Inserisci le tue aliquote"
    static let imposta = "Imposta gli obiettivi"
    static let didascaliaValore = "Ogni punto è un cliente: ore che gli dedichi nell’anno e ricavi che genera."
    static let senzaOre = "Servono appuntamenti con una durata per contare le ore."
    static let zona = "molto tempo, poco valore"

    /// «novembre»: il mese in minuscolo, per la testata del riquadro della scrivania.
    private static let formatoMese = Formati.formato("MMMM")
    /// «dic»: il mese abbreviato sotto le colonne degli incassi.
    private static let formatoMeseBreve = Formati.formato("MMM")

    static func mese(_ d: Date) -> String { formatoMese.string(from: d).lowercased() }
    static func meseBreve(_ d: Date) -> String {
        formatoMeseBreve.string(from: d).lowercased().replacingOccurrences(of: ".", with: "")
    }

    /// «410.000 €» con il punto delle migliaia (come i numeri che si contano).
    static func euro(_ v: Double) -> String { FormatoCifra.euro.testo(v) }

    /// «+18% sul 2025» (meno tipografico se scende).
    static func variazione(_ v: Double, annoPrima: Int) -> String {
        let percento = (v * 100).rounded()
        return (percento > 0 ? "+" : "") + FormatoCifra.migliaia(percento) + "% sul \(annoPrima)"
    }

    /// «12 proposte», «1 proposta».
    static func proposte(_ n: Int) -> String { n == 1 ? "1 proposta" : "\(n) proposte" }

    /// «stima · 2 posizioni senza aliquota».
    static func senzaAliquota(_ n: Int) -> String {
        n == 1 ? "1 posizione senza aliquota" : "\(n) posizioni senza aliquota"
    }

    /// Il fumetto di un punto della dispersione: «Giulia Rossi · 14 ore · 2.900 €».
    static func punto(_ p: CruscottoStudio.PuntoCliente) -> String {
        "\(p.cliente.nome) · \(FormatoCifra.mesi.testo(p.ore)) ore · \(euro(p.ricavi))"
    }

    /// Il fumetto di una colonna degli incassi: «dicembre · Alleanza 1.200 € · Indipendente 0 €».
    static func mese(_ m: CruscottoStudio.MeseIncasso) -> String {
        let alleanza = m.alleanza.map(euro) ?? "senza aliquote"
        return "\(mese(m.inizio)) · Alleanza \(alleanza) · Indipendente \(euro(m.indipendente))"
    }
}

// MARK: - Azioni dello stato

extension StatoShell {
    /// Apre Studio sulla scheda data (dalla scrivania, dalle novità, dal dock con la scheda di prima).
    func apriStudio(_ scheda: SchedaStudio = .cruscotto) {
        schedaStudio = scheda
        apri(.studio)
    }

    /// Apre Impostazioni › Studio (aliquote e obiettivi).
    func apriImpostazioniStudio() {
        ancoraImpostazioni = nil
        schedaImpostazioni = .studio
        apri(.impostazioni)
    }

    /// Scrive (o toglie, con nil) un'aliquota provvigionale Alleanza di un tipo di prodotto, in percentuale.
    /// Un valore negativo o non finito non si scrive; oltre 100 si ferma a 100.
    func impostaAliquotaStudio(_ area: AreaPosizione, _ tipo: MotoreStudio.TipoProvvigione, _ valore: Double?) {
        let pulito: Double? = valore.flatMap { v in (v.isFinite && v >= 0) ? min(v, 100) : nil }
        var studio = dati.impostazioni.studio
        var a = studio.aliquote[area] ?? AliquoteProvvigione()
        switch tipo {
        case .nuovaProduzione: a.nuovaProduzione = pulito
        case .ricorrente: a.ricorrenti = pulito
        case .rinnovo: a.rinnovi = pulito
        }
        studio.aliquote[area] = a.vuota ? nil : a
        guard studio != dati.impostazioni.studio else { return }
        dati.impostazioni.studio = studio
    }

    /// Scrive (o toglie, con nil) un obiettivo dell'anno. Un valore negativo o non finito non si scrive.
    func impostaObiettivoStudio(anno: Int, _ voce: VoceObiettivoStudio, _ valore: Double?) {
        // Oltre mille miliardi è un errore di battitura: non si scrive (le cifre si formattano come interi)
        let pulito: Double? = valore.flatMap { v in (v.isFinite && v >= 0 && v <= 1e12) ? v : nil }
        var studio = dati.impostazioni.studio
        var o = studio.obiettivi[anno] ?? ObiettiviStudio()
        switch voce {
        case .produzioneAlleanza: o.produzioneAlleanza = pulito
        // Un numero enorme (incollato per sbaglio) non si scrive: Int(_:) fermerebbe l'app oltre Int.max
        case .nuoviClienti: o.nuoviClienti = pulito.flatMap { $0 < Double(Int32.max) ? Int($0.rounded()) : nil }
        case .ricaviConsulenza: o.ricaviConsulenza = pulito
        }
        studio.obiettivi[anno] = o.vuoto ? nil : o
        guard studio != dati.impostazioni.studio else { return }
        dati.impostazioni.studio = studio
    }
}

// MARK: - Il segmentato della testata

/// «▶︎ Il tuo anno» e il segmentato a pillola delle quattro schede, a destra nella testata della finestra.
struct AzioniStudio: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        HStack(spacing: Tema.Apple.Scrivania.Saluto.spazioPulsanti) {
            // «▶︎ Il tuo anno» in tutte le schede (Luce giro 5, StoriaLuce.swift); non in modalità cliente
            if !stato.inModoCliente {
                Button {
                    stato.apriStoria(.anno)
                } label: {
                    Label("Il tuo anno", systemImage: "play.fill")
                }
                .buttonStyle(.appleVetro)
                .fixedSize()
                .help("Il tuo anno da consulente, in un minuto")
            }
            SegmentatoPillola(selezione: Bindable(stato).schedaStudio, valori: SchedaStudio.allCases, titolo: { $0.titolo })
                .fixedSize()
        }
    }
}

// MARK: - L'app

/// Il contenuto della finestra di Studio.
struct AppStudio: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        CorpoStudio(stato: stato, chiave: stato.chiaveVista, scheda: stato.schedaStudio)
            .equatable()
    }
}

/// Il corpo di Studio: si rifà solo quando cambiano i dati dei calcoli (chiave) o la scheda.
private struct CorpoStudio: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    let scheda: SchedaStudio

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    /// La scheda mostrata: resta quella di prima finché il contenuto non è uscito.
    @State private var mostrata: SchedaStudio?
    @State private var esce = false
    /// Dopo il primo cambio di scheda la cascata parte da 0 e gli anelli a 0,15 s.
    @State private var cambiato = false

    nonisolated static func == (a: CorpoStudio, b: CorpoStudio) -> Bool {
        a.stato === b.stato && a.chiave == b.chiave && a.scheda == b.scheda
    }

    private var base: Double {
        let m = Tema.Apple.Studio.Moto.self
        return cambiato ? m.baseCambio : m.baseApertura
    }

    private var ritardoAnelli: Double {
        let m = Tema.Apple.Studio.Moto.self
        return cambiato ? m.anelliCambio : m.anelliApertura
    }

    var body: some View {
        let s = mostrata ?? scheda
        let m = Tema.Apple.Studio.Moto.self
        return contenuto(s)
            .id(s)
            .opacity(esce ? 0 : 1)
            .scaleEffect(esce ? m.scalaRimonta : 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // Nelle istantanee la scheda non cambia mai: niente da scrivere alla comparsa
            .onAppear { if mostrata == nil && !istantanea { mostrata = scheda } }
            .onChange(of: scheda) { nuova in cambia(nuova) }
    }

    @ViewBuilder private func contenuto(_ s: SchedaStudio) -> some View {
        if chiave.modo != nil {
            RiservatoStudio()
                .entrataCascata(0, base: base)
        } else if s == .cruscotto {
            CruscottoStudioVista(stato: stato, base: base, ritardoAnelli: ritardoAnelli)
        } else if s == .fatture {
            // Studio › Parcelle e fatture (giro 2): StudioParcelle.swift; osserva lo stato da sé
            ParcelleStudioVista(base: base)
        } else if s == .track {
            // Studio › Track record (giro 2): StudioTrackRecord.swift
            TrackRecordStudioVista(stato: stato, base: base)
        } else if s == .ocf {
            // Studio › Esame OCF (giro 6): StudioEsameOCF.swift; osserva lo stato da sé (le risposte non cambiano la chiave)
            EsameOCFStudioVista(stato: stato, base: base, ritardoAnelli: ritardoAnelli)
        } else if s == .palestra {
            // Studio › Palestra («Luce» giro 5): StudioPalestra.swift; osserva da sé lo stato della palestra
            PalestraStudioVista(stato: stato, palestra: stato.palestra, base: base)
        } else {
            ProssimaSchedaStudio(scheda: s)
                .entrataCascata(0, base: base)
        }
    }

    private func cambia(_ nuova: SchedaStudio) {
        guard nuova != mostrata else {
            esce = false
            return
        }
        if istantanea || calmo {
            let mostra: () -> Void = {
                cambiato = true
                mostrata = nuova
                esce = false
            }
            if istantanea {
                mostra()
            } else {
                withAnimation(Tema.Moto.dissolvenzaCalma) { mostra() }
            }
            return
        }
        let m = Tema.Apple.Studio.Moto.self
        withAnimation(m.uscitaRimonta) { esce = true }
        Movimenti.dopo(m.durataRimonta) {
            // Un clic su un'altra scheda nel frattempo: entra quella, con il suo giro
            guard stato.schedaStudio == nuova else { return }
            cambiato = true
            mostrata = nuova
            esce = false
        }
    }
}

// MARK: - Schede che arrivano e modalità cliente

/// Una scheda di Studio che in questo giro non c'è ancora: il suo nome e cosa arriverà, senza cifre finte.
private struct ProssimaSchedaStudio: View {
    let scheda: SchedaStudio

    var body: some View {
        let p = Tema.Apple.Studio.Prossime.self
        VStack(alignment: .leading, spacing: p.spazio) {
            Text(scheda.titolo)
                .carattereApple(p.titolo)
                .foregroundColor(p.coloreTitolo)
            Text(scheda.prossima ?? "")
                .carattereApple(p.testo)
                .foregroundColor(p.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(p.padding)
        .frame(maxWidth: p.larghezza, alignment: .leading)
        .superficieApple(p.superficie, raggio: p.raggio)
        .padding(.top, p.sopra)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// In modalità cliente: Studio non mostra le cifre del consulente.
private struct RiservatoStudio: View {
    var body: some View {
        let p = Tema.Apple.Studio.Prossime.self
        let r = Tema.Apple.Studio.Riservato.self
        VStack(alignment: .leading, spacing: p.spazio) {
            Text(TestiStudio.titoloRiservato)
                .carattereApple(r.titolo)
                .foregroundColor(r.coloreTitolo)
            Text(TestiStudio.testoRiservato)
                .carattereApple(r.testo)
                .foregroundColor(r.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(p.padding)
        .frame(maxWidth: p.larghezza, alignment: .leading)
        .superficieApple(p.superficie, raggio: p.raggio)
        .padding(.top, p.sopra)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
