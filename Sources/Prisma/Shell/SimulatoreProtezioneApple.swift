import SwiftUI

// Analisi 360 › Protezione: il simulatore dal vivo (Design/template-apple-specifica.md §4.3.3, riferimenti
// analisi-agenda A13-A16). Struttura come la Previdenza, in rosso:
//
//   PROTEZIONE · MARCO BIANCHI
//   Se domani non ci fosse il suo reddito
//   ╭────╮   Capitale che servirebbe   Già assicurato
//   │ 68%│   221.000 €                 150.000 €
//   │prot│   Capitale da aggiungere con una temporanea caso morte
//   ╰────╯   50.000 €  ──●────────────
//            Premio stimato l'anno [stima]   Al mese   Scoperto che resta
//   Ipotesi: …
//   [Salva come proposta] [Chiedi a Vera di spiegarlo]                    [Alleanza|Indipendente] (canale)
//
// - Fabbisogno e coperture vengono da MotoreAnalisi.protezione (le coperture caso morte in essere, non scadute);
//   il premio dalla tariffa delle coperture caso morte del cliente o, se non ne ha, dalla media di quelle in
//   archivio (MotoreSimulatoriAnalisi.tariffaCasoMorte): è sempre una «stima», con l'ipotesi scritta sotto. Se in
//   archivio nessuna copertura ha capitale e premio, il premio resta «—» e le ipotesi dicono perché. Niente premio
//   `v·0,0012·età/37` del template (§4.9.17).
// - Ricalcolo leggero: fabbisogno e tariffa una volta per disegno della cornice; a ogni passo solo somme.
// - Movimento come la Previdenza: le cifre contano all'apertura, poi cambiano subito; l'anello insegue.

private typealias SQ = Tema.Apple.SimulatoriAnalisi.Protezione

/// Il simulatore della protezione per `cliente`, sulle ipotesi della sua Analisi 360 (`analisi`).
struct SimulatoreProtezioneApple: View {
    @EnvironmentObject var stato: StatoShell
    let cliente: Cliente
    let analisi: Binding<Analisi360>

    var body: some View {
        let i = analisi.wrappedValue.protezione
        let posizioni = stato.posizioniCliente(cliente.id)
        let e = MotoreAnalisi.protezione(i, posizioni: posizioni)
        // In modalità cliente `stato.posizioni` sono solo le sue: la media dell'archivio non esce dal dossier
        let tariffa = MotoreSimulatoriAnalisi.tariffaCasoMorte(cliente: posizioni, archivio: stato.posizioni)
        let quadro = QuadroSimulatoreProtezione(
            clienteId: cliente.id, nome: cliente.nome, eta: cliente.eta, ipotesi: i, esito: e, tariffa: tariffa,
            canale: cliente.canali.first ?? .alleanza
        )
        return CorpoSimulatoreProtezioneApple(
            quadro: quadro, iniziale: SimulatoriAnalisiApple.valoreIniziale(stato, .protezione) ?? 0
        )
    }
}

/// Ciò che non cambia mentre si trascina il cursore.
struct QuadroSimulatoreProtezione {
    let clienteId: String
    let nome: String
    let eta: Int?
    let ipotesi: IpotesiProtezione
    let esito: MotoreAnalisi.EsitoProtezione
    let tariffa: MotoreSimulatoriAnalisi.TariffaCasoMorte?
    let canale: Canale

    /// Da 0 a max(100.000; fabbisogno·1,1 arrotondato a 10.000), passo 10.000 (§4.3.3).
    func massimo(_ iniziale: Double) -> Double {
        let daFabbisogno = (esito.fabbisogno * SQ.margineFabbisogno / SQ.passo).rounded(.up) * SQ.passo
        let daIniziale = (iniziale / SQ.passo).rounded(.up) * SQ.passo
        return max(SQ.massimoMinimo, daFabbisogno, daIniziale)
    }
}

private struct CorpoSimulatoreProtezioneApple: View {
    @EnvironmentObject var stato: StatoShell
    @Environment(\.statoDettaglioApple) private var dettaglio
    let quadro: QuadroSimulatoreProtezione
    private let massimo: Double
    /// Il capitale caso morte in più del cursore (parte da 0, come nel template).
    @State private var aggiunta: Double
    @State private var mosso = false
    @State private var canale: Canale

    init(quadro: QuadroSimulatoreProtezione, iniziale: Double) {
        self.quadro = quadro
        let m = quadro.massimo(iniziale)
        massimo = m
        _aggiunta = State(initialValue: min(max(0, iniziale), m))
        _canale = State(initialValue: quadro.canale)
    }

    var body: some View {
        let s = Tema.Apple.SimulatoriAnalisi.self
        let colore = SQ.colore
        // Il solo calcolo di ogni passo: somme e il premio dalla tariffa
        let p = MotoreSimulatoriAnalisi.protezione(quadro.esito, aggiunta: aggiunta, tariffa: quadro.tariffa)
        return VStack(alignment: .leading, spacing: 0) {
            TestataSimulatoreApple(etichetta: "Protezione · \(quadro.nome)",
                                   titolo: "Se domani non ci fosse il suo reddito", colore: colore)
            HStack(alignment: .center, spacing: s.spazioAnello) {
                AnelloSimulatoreApple(frazione: p.copertura, colore: colore,
                                      sotto: p.fabbisogno > 0 ? "protetto" : "nessun fabbisogno", mosso: mosso)
                colonna(p, colore: colore)
            }
            .padding(.top, s.sopraCorpo)
            Spacer(minLength: 0)
            IpotesiSimulatoreApple(testo: ipotesi)
                .padding(.top, s.sopraIpotesi)
            piede
                .padding(.top, s.sopraPiede)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: aggiunta) { _ in
            if !mosso { mosso = true }
        }
    }

    // MARK: Parti

    private func colonna(_ p: MotoreSimulatoriAnalisi.PassoProtezione, colore: Color) -> some View {
        let s = Tema.Apple.SimulatoriAnalisi.self
        let stima = quadro.tariffa != nil
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: s.spazioCifre) {
                CifraSimulatoreApple(titolo: "Capitale che servirebbe", valore: p.fabbisogno, indice: 0,
                                     aiuto: "Debiti, spese immediate e sostegno alla famiglia, meno il capitale già destinato ai superstiti")
                CifraSimulatoreApple(titolo: "Già assicurato", valore: p.giaAssicurato, indice: 1,
                                     aiuto: "Coperture caso morte in essere e non scadute, dalle posizioni")
            }
            VStack(alignment: .leading, spacing: s.spazioEtichettaCursore) {
                Text("Capitale da aggiungere con una temporanea caso morte")
                    .carattereApple(s.etichettaCursore)
                    .foregroundColor(s.coloreEtichetta)
                CursoreApple(valore: $aggiunta, intervallo: 0...massimo, passo: SQ.passo,
                             etichetta: "Capitale da aggiungere con una temporanea caso morte", formato: .euro,
                             carattereValore: s.valoreCursore, coloreValore: colore)
                    .frame(maxWidth: s.larghezzaCursore)
                    .padding(.vertical, s.margineCursore)
            }
            .padding(.top, s.sopraCursore)
            HStack(alignment: .top, spacing: s.spazioCifre) {
                CifraSimulatoreApple(titolo: "Premio stimato l'anno", valore: p.premioAnnuo, indice: 2, mosso: mosso,
                                     stima: stima, aiuto: "Indicativo: le condizioni vere vengono dal preventivo del prodotto")
                CifraSimulatoreApple(titolo: "Al mese", valore: p.premioMensile, indice: 3, mosso: mosso, stima: stima)
                CifraSimulatoreApple(titolo: "Scoperto che resta", valore: p.scoperto, indice: 4, mosso: mosso,
                                     colore: p.scoperto >= 0.5 ? colore : s.colorePositivo,
                                     aiuto: "Capitale che servirebbe meno quello già assicurato e quello in più")
            }
            .padding(.top, s.sopraRisultati)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Le ipotesi vere del calcolo: da dove viene il fabbisogno, che cosa conta come assicurato, come si stima il premio.
    private var ipotesi: String {
        let i = quadro.ipotesi
        let anni = i.anniSostegno == 1 ? "1 anno" : "\(i.anniSostegno) anni"
        var voci: [String] = []
        if i.debiti >= 0.5 { voci.append("debiti \(Formati.euro(i.debiti))") }
        voci.append("spese immediate \(Formati.euro(i.speseImmediate))")
        voci.append("\(Formati.euro(i.fabbisognoMensile)) al mese per \(anni)")
        var testo = "Ipotesi: fabbisogno = " + voci.joined(separator: " + ")
        if i.capitaleDisponibile >= 0.5 { testo += " − capitale ai superstiti \(Formati.euro(i.capitaleDisponibile))" }
        testo += ", senza sconto dei flussi futuri; già assicurato = coperture caso morte in essere (le proposte aperte non contano). "
        testo += premio
        return testo
    }

    /// Come si stima il premio, con i numeri della tariffa usata.
    private var premio: String {
        let chiusura = "Le condizioni vere (età, durata, fumo, salute) vengono dal preventivo del prodotto."
        guard let t = quadro.tariffa else {
            return "Premio: nessuna copertura caso morte in archivio ha capitale e premio, quindi non si può stimare. " + chiusura
        }
        let costo = "\(Formati.euroDecimali(t.perMille)) l'anno ogni 1.000 € assicurati"
        switch t.fonte {
        case .cliente:
            let quante = t.coperture == 1 ? "della sua copertura caso morte" : "delle sue \(t.coperture) coperture caso morte"
            return "Premio: stima dal costo \(quante), \(costo). " + chiusura
        case .archivio:
            let eta = quadro.eta.map { " (qui \($0) anni)" } ?? ""
            return "Premio: stima dal costo medio di \(t.coperture == 1 ? "1 copertura" : "\(t.coperture) coperture") caso morte in archivio, \(costo), senza correggere per l'età\(eta). " + chiusura
        }
    }

    private var piede: some View {
        let s = Tema.Apple.SimulatoriAnalisi.self
        let salvabile = !stato.solaLettura && aggiunta >= SQ.passo / 2
        return HStack(alignment: .center, spacing: s.spazioPiede) {
            Button("Salva come proposta", action: salva)
                .buttonStyle(.applePrimarioGrande)
                .disabled(!salvabile)
                .help(salvabile
                      ? "Crea in Posizioni una proposta di temporanea caso morte da \(Formati.euro(aggiunta)), sul canale scelto"
                      : "Sposta il cursore per scegliere il capitale da aggiungere")
            Button("Chiedi a Vera di spiegarlo", action: chiediVera)
                .buttonStyle(.appleGrande)
                .disabled(stato.veraInCorso)
            Spacer(minLength: s.spazioPiede)
            CanaleSimulatoreApple(canale: $canale)
        }
    }

    // MARK: Azioni

    /// Il capitale in più diventa una proposta di temporanea caso morte (bozza) nel dossier, sul canale scelto,
    /// con il premio stimato (0 se non stimabile): conta subito nello «Scoperto con le proposte» dell'area.
    private func salva() {
        let capitale = aggiunta.rounded()
        guard !stato.solaLettura, capitale > 0 else { return }
        let stimato = MotoreSimulatoriAnalisi.protezione(quadro.esito, aggiunta: capitale, tariffa: quadro.tariffa).premioAnnuo
        var p = Posizione(clienteId: quadro.clienteId, canale: canale, stato: .proposta, area: .protezione,
                          nome: "Temporanea caso morte")
        p.esito = .bozza
        p.tipologia = "Dal simulatore di Analisi 360"
        p.contraente = quadro.nome
        p.assicurato = quadro.nome
        p.rischio = .vita
        p.capitaleAssicurato = capitale
        p.premio = (stimato ?? 0).rounded()
        p.frequenza = .annuale
        p.note = stimato == nil
            ? "Proposta dal simulatore: capitale \(Formati.euro(capitale)). Premio da chiedere al preventivo del prodotto."
            : "Proposta dal simulatore: capitale \(Formati.euro(capitale)), premio stimato \(Formati.euro(stimato ?? 0)) l'anno. Verifica il premio sul preventivo del prodotto."
        stato.salvaPosizione(p)
        let testo = "Proposta salvata nel dossier di \(quadro.nome)"
        let s = stato
        if let d = dettaglio {
            d.chiudi(poi: { s.mostraAvviso(testo) })
        } else {
            s.mostraAvviso(testo)
        }
    }

    /// Chiude subito il dettaglio, apre Vera e manda la domanda sulla protezione dopo 0,7 s.
    private func chiediVera() {
        let s = stato
        dettaglio?.chiudi(subito: true)
        s.apri(.vera)
        DispatchQueue.main.asyncAfter(deadline: .now() + Tema.Apple.SimulatoriAnalisi.ritardoDomandaVera) {
            s.chiediVera(SpuntoVera.protezione.domanda, spunto: .protezione)
        }
    }
}
