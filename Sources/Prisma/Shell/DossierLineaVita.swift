import SwiftUI

// Scheda «La linea della vita» del dossier (Orizzonte, giro 4; Design/template-novita-specifica.md §7): il patrimonio
// del cliente da oggi a 90 anni, in euro di oggi. Una card intera con:
// - la riga del titolo (`.lbl` «La linea della vita · da oggi a 90 anni», a destra «Trascina gli eventi…» e «＋ Evento»);
// - tre cifre: il patrimonio all'età della pensione e il massimo (si contano), «Il patrimonio basta» oltre i 90 in
//   verde o fino a N anni in rosso;
// - il grafico: zona viola della pensione, area e curva che si disegna (`TracciatoGrafico`), righe tratteggiate
//   degli eventi, punto rosso «finisce a N anni» se il patrimonio non arriva a 90; senza reddito desiderato la curva
//   dopo la pensione è tratteggiata (solo indicativa);
// - la linea del tempo con le tacche ogni 5 anni e i gettoni degli eventi su tre file: si trascinano sull'età
//   (`DragGesture`, a scatti di un anno), e a ogni passo `MotoreLineaVita.calcola` ricalcola tutto in modo sincrono
//   (≤ 60 passi annui, niente cache durante il gesto); al rilascio l'età si salva nel dossier. Un clic sul gettone
//   apre la modifica, «＋ Evento» il foglio di un evento nuovo. Gli obiettivi con scadenza sono gettoni fissi;
// - sotto, gli avvisi e le righe del metodo di `MotoreLineaVita.prepara` (le cifre di partenza vengono dai motori).
// In modalità cliente e in presentazione il foglio non mostra le note interne degli eventi.
// La scheda non scorre nel dossier (`SchedaCliente.scorreNelDossier`). Valori in Tema.Apple+LineaVita.swift.

struct LineaVitaDossier: View {
    let cliente: Cliente
    @EnvironmentObject var stato: StatoShell
    /// Il gettone preso: `idPensione` o l'id dell'evento; nil = nessuno.
    @State private var presa: String?
    @State private var etaInizio = 0
    @State private var etaPresa = 0
    /// Dopo il primo trascinamento le cifre non ricontano da 0 quando tornano a contare.
    @State private var toccata = false
    @State private var foglio: ModificaEventoLineaVita?

    static let idPensione = "pensione"
    private static let spazio = "linea-della-vita"

    var body: some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let prep = preparazione
        return VStack(alignment: .leading, spacing: 0) {
            intestazione(conEventi: prep.ingresso != nil)
            if let base = prep.ingresso {
                contenuto(prep, base: base)
            } else {
                vuoto(prep.motivoAssente ?? "")
            }
        }
        .padding(k.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(k.superficie)
        .entrataDossier(0)
        .sheet(item: $foglio) { m in
            ModuloEventoLineaVita(modifica: m, riservato: riservato,
                                  salva: { stato.salvaEventoVita($0) },
                                  elimina: { stato.eliminaEventoVita(m.evento.id) })
        }
    }

    /// Modalità cliente o presentazione: niente note interne degli eventi.
    private var riservato: Bool { stato.inModoCliente || stato.presentazione != nil }

    /// Le cifre di partenza dai dati del cliente (in cache finché non cambiano i dati o il giorno).
    private var preparazione: PreparazioneLineaVita {
        let id = cliente.id
        return CacheLineaVita.preparazione(cliente: stato.cliente(id) ?? cliente, posizioni: stato.posizioniCliente(id),
                                           obiettivi: stato.dati.obiettivi.filter { $0.clienteId == id },
                                           eventi: stato.eventiVitaCliente(id), analisi: stato.dati.analisi[id])
    }

    // MARK: Intestazione

    private func intestazione(conEventi: Bool) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        return HStack(alignment: .center, spacing: k.spazioIntestazione) {
            Text("La linea della vita · da oggi a \(MotoreLineaVita.etaFinePredefinita) anni")
                .carattereApple(k.titolo)
                .foregroundColor(k.coloreTitolo)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: k.spazioIntestazione)
            if conEventi {
                Text("Trascina gli eventi e la pensione: tutto si ricalcola")
                    .carattereApple(k.suggerimento)
                    .foregroundColor(k.coloreSuggerimento)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Button("＋ Evento") { nuovoEvento() }
                    .buttonStyle(.appleSobrio)
                    .fixedSize()
                    .help("Aggiungi un evento della vita: la casa, un figlio, un'eredità, un anno sabbatico")
            }
        }
    }

    private func nuovoEvento() {
        let eta = preparazione.ingresso.map { $0.etaOggi + 1 } ?? MotoreLineaVita.etaFinePredefinita
        foglio = ModificaEventoLineaVita(evento: EventoLineaVita(clienteId: cliente.id, tipo: .casa, eta: eta),
                                         nuovo: true, etaOggi: preparazione.ingresso?.etaOggi ?? eta - 1)
    }

    // MARK: Senza data di nascita

    private func vuoto(_ motivo: String) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        return VStack(alignment: .leading, spacing: k.spazioVuoto) {
            Text(motivo)
                .carattereApple(k.vuoto)
                .foregroundColor(k.coloreVuoto)
                .fixedSize(horizontal: false, vertical: true)
            Button("Completa l'anagrafica ›") {
                stato.richiestaCompletamento = RichiestaCompletamento(clienteId: cliente.id, destinazione: .cliente(.dataNascita))
            }
            .buttonStyle(.appleSobrio)
            .fixedSize()
        }
        .padding(.top, k.sopraVuoto)
    }

    // MARK: Cifre, grafico e linea

    @ViewBuilder private func contenuto(_ prep: PreparazioneLineaVita, base: IngressoLineaVita) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let attuale = ingresso(base)
        let esito = MotoreLineaVita.calcola(attuale)
        let elenco = gettoni(base: base, ipotesi: prep.etaPensioneIpotizzata)
        cifre(esito)
            .padding(.top, k.sopraCifre)
        GraficoLineaVita(esito: esito, etaOggi: attuale.etaOggi,
                         entrate: elenco.filter { $0.genere == .entrata }.map(etaMostrata),
                         uscite: elenco.filter { $0.genere == .uscita }.map(etaMostrata))
            .frame(height: k.altezzaGrafico)
            .padding(.top, k.sopraGrafico)
        lineaDelTempo(elenco, etaOggi: attuale.etaOggi, etaFine: esito.etaFine)
            .frame(height: k.altezzaLinea)
            .padding(.top, k.sopraLinea)
        note(prep)
            .padding(.top, k.sopraNote)
    }

    /// L'ingresso con il gettone preso all'età del gesto (la copia locale del trascinamento).
    private func ingresso(_ base: IngressoLineaVita) -> IngressoLineaVita {
        guard let presa else { return base }
        var i = base
        if presa == Self.idPensione {
            i.etaPensione = etaPresa
        } else if let k = i.movimenti.firstIndex(where: { $0.id == presa }) {
            i.movimenti[k].eta = etaPresa
        }
        return i
    }

    private func etaMostrata(_ g: GettoneLineaVita) -> Int { presa == g.id ? etaPresa : g.eta }

    private func cifre(_ e: EsitoLineaVita) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let basta: String = e.etaEsaurimento.map { "fino a \($0) anni" } ?? "oltre i \(e.etaFine) anni"
        return HStack(alignment: .top, spacing: k.spazioCifre) {
            cifra("A \(e.etaPensione) anni, in pensione", valore: max(0, e.allaPensione), indice: 0)
            cifra("Al massimo", valore: max(0, e.massimo), indice: 1)
            VStack(alignment: .leading, spacing: k.spazioEtichettaCifra) {
                Text("Il patrimonio basta")
                    .carattereApple(k.etichettaCifra)
                    .foregroundColor(k.coloreEtichettaCifra)
                Text(basta)
                    .carattereApple(k.cifra)
                    .foregroundColor(e.basta ? k.coloreBasta : k.coloreFinisce)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
    }

    /// Una cifra: si conta all'apertura; durante il trascinamento è scritta di colpo, e dopo non riconta da 0.
    private func cifra(_ etichetta: String, valore: Double, indice: Int) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        return VStack(alignment: .leading, spacing: k.spazioEtichettaCifra) {
            Text(etichetta)
                .carattereApple(k.etichettaCifra)
                .foregroundColor(k.coloreEtichettaCifra)
                .lineLimit(1)
            Group {
                if presa != nil {
                    Text(FormatoCifra.euro.testo(valore))
                        .monospacedDigit()
                } else {
                    NumeroCheConta(valore, indice: indice, da: toccata ? nil : 0)
                }
            }
            .carattereApple(k.cifra)
            .foregroundColor(k.coloreCifra)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: I gettoni

    /// Gli eventi del cliente (nell'ordine dell'archivio: la fila resta la stessa durante il gesto), gli obiettivi
    /// con scadenza che entrano nel calcolo (fissi) e la pensione.
    private func gettoni(base: IngressoLineaVita, ipotesi: Bool) -> [GettoneLineaVita] {
        let annoOggi = Calendar.current.component(.year, from: Date())
        var elenco: [GettoneLineaVita] = []
        for e in stato.eventiVitaCliente(cliente.id) {
            guard let eta = e.etaEvento(etaOggi: base.etaOggi, annoOggi: annoOggi) else { continue }
            let importo = e.importo.flatMap { $0.isFinite && $0 != 0 ? $0 : nil }
            var genere = GettoneEventoApple.Genere.senzaCifra
            if let importo { genere = importo > 0 ? .entrata : .uscita }
            elenco.append(GettoneLineaVita(id: e.id, nome: e.nome, eta: eta, genere: genere, fisso: false,
                                           importo: importo, perAnni: e.anniDurata, ipotesi: false))
        }
        for m in base.movimenti where m.daObiettivo {
            let titolo = stato.dati.obiettivi.first { $0.id == m.id }?.titolo ?? "Obiettivo"
            elenco.append(GettoneLineaVita(id: m.id, nome: titolo, eta: m.eta, genere: m.importo > 0 ? .entrata : .uscita,
                                           fisso: true, importo: m.importo, perAnni: m.perAnni, ipotesi: false))
        }
        elenco.append(GettoneLineaVita(id: Self.idPensione, nome: "Pensione", eta: base.etaPensione, genere: .pensione,
                                       fisso: false, importo: nil, perAnni: 1, ipotesi: ipotesi))
        return elenco
    }

    private func lineaDelTempo(_ elenco: [GettoneLineaVita], etaOggi: Int, etaFine: Int) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let anni = CGFloat(max(1, etaFine - etaOggi))
        return GeometryReader { g in
            let w = g.size.width
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(k.coloreBinario)
                    .frame(width: w, height: k.altezzaBinario)
                    .position(x: w / 2, y: k.yBinario + k.altezzaBinario / 2)
                ForEach(Self.tacche(etaOggi: etaOggi, etaFine: etaFine), id: \.self) { a in
                    let x = CGFloat(a - etaOggi) / anni * w
                    Rectangle()
                        .fill(k.coloreTacca)
                        .frame(width: k.tacca.width, height: k.tacca.height)
                        .position(x: x, y: k.yTacca + k.tacca.height / 2)
                    Text(verbatim: "\(a)")
                        .carattereApple(k.numeri)
                        .foregroundColor(k.coloreNumeri)
                        .fixedSize()
                        .position(x: x, y: k.centroNumeri)
                }
                .accessibilityHidden(true)
                ForEach(Array(elenco.enumerated()), id: \.element.id) { i, gt in
                    gettone(gt, fila: i % k.file, larghezza: w, anni: anni, etaOggi: etaOggi, etaFine: etaFine)
                }
            }
            .frame(width: w, height: g.size.height, alignment: .topLeading)
        }
        .coordinateSpace(name: Self.spazio)
    }

    /// Le tacche ogni 5 anni, dal primo multiplo di 5 dopo l'età di oggi fino alla fine.
    static func tacche(etaOggi: Int, etaFine: Int) -> [Int] {
        let passo = Tema.Apple.Clienti.LineaVita.passoTacche
        let prima = (etaOggi / passo + 1) * passo
        guard prima <= etaFine else { return [] }
        return Array(stride(from: prima, through: etaFine, by: passo))
    }

    private func gettone(_ g: GettoneLineaVita, fila: Int, larghezza w: CGFloat, anni: CGFloat, etaOggi: Int,
                         etaFine: Int) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let eta = etaMostrata(g)
        let x = CGFloat(min(max(eta, etaOggi), etaFine) - etaOggi) / anni * w
        // Il centro resta a 70 dai bordi della card (nella finestra stretta, al centro)
        let centro = w > 2 * k.margineGettoni ? min(max(x, k.margineGettoni), w - k.margineGettoni) : w / 2
        let preso = presa == g.id
        // I gesti sul gettone, prima di metterlo al suo posto: rispondono solo sulla capsula
        return GettoneEventoApple(nome: g.nome, dettaglio: g.dettaglio(eta), genere: g.genere, preso: preso, fisso: g.fisso)
            .onTapGesture { modifica(g) }
            .gesture(trascina(g, larghezza: w, anni: anni, etaOggi: etaOggi), including: g.fisso ? .none : .all)
            .contextMenu { menu(g) }
            .help(g.aiuto)
            .accessibilityLabel(Text(g.descrizione(eta)))
            .accessibilityAdjustableAction { verso in
                switch verso {
                case .increment: sposta(g, di: 1, etaOggi: etaOggi)
                case .decrement: sposta(g, di: -1, etaOggi: etaOggi)
                @unknown default: break
                }
            }
            .position(x: centro, y: CGFloat(fila) * k.passoFile + k.altezzaGettone / 2)
            .zIndex(preso ? 5 : 0)
    }

    @ViewBuilder private func menu(_ g: GettoneLineaVita) -> some View {
        if !g.fisso, g.id != Self.idPensione {
            Button("Modifica l'evento…") { modifica(g) }
            Button("Togli dalla linea", role: .destructive) { stato.eliminaEventoVita(g.id) }
        }
    }

    private func modifica(_ g: GettoneLineaVita) {
        guard !g.fisso, g.id != Self.idPensione, presa == nil,
              let e = stato.eventiVitaCliente(cliente.id).first(where: { $0.id == g.id }),
              let etaOggi = preparazione.ingresso?.etaOggi else { return }
        foglio = ModificaEventoLineaVita(evento: e, nuovo: false, etaOggi: etaOggi)
    }

    // MARK: Il trascinamento

    private func trascina(_ g: GettoneLineaVita, larghezza w: CGFloat, anni: CGFloat, etaOggi: Int) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named(Self.spazio))
            .onChanged { v in
                if presa != g.id {
                    etaInizio = g.eta
                    etaPresa = g.eta
                    presa = g.id
                    toccata = true
                }
                // A scatti di un anno: lo spostamento dall'inizio del gesto, in anni
                let passi = Int((v.translation.width / max(1, w) * anni).rounded())
                let nuova = limita(g, etaInizio + passi, etaOggi: etaOggi)
                if nuova != etaPresa { etaPresa = nuova }
            }
            .onEnded { _ in rilascia(g, etaOggi: etaOggi) }
    }

    private func limita(_ g: GettoneLineaVita, _ eta: Int, etaOggi: Int) -> Int {
        g.id == Self.idPensione ? MotoreLineaVita.limitaEtaPensione(eta) : MotoreLineaVita.limitaEtaEvento(eta, etaOggi: etaOggi)
    }

    /// Al rilascio l'età si salva nel dossier (il ricalcolo è già fatto durante il gesto).
    private func rilascia(_ g: GettoneLineaVita, etaOggi: Int) {
        guard presa == g.id else { return }
        if etaPresa != g.eta { salva(g, eta: etaPresa, etaOggi: etaOggi) }
        presa = nil
    }

    /// Con la tastiera (VoiceOver: regolabile): un anno alla volta, salvato subito.
    private func sposta(_ g: GettoneLineaVita, di passo: Int, etaOggi: Int) {
        guard !g.fisso, presa == nil else { return }
        let nuova = limita(g, g.eta + passo, etaOggi: etaOggi)
        if nuova != g.eta { salva(g, eta: nuova, etaOggi: etaOggi) }
    }

    private func salva(_ g: GettoneLineaVita, eta: Int, etaOggi: Int) {
        if g.id == Self.idPensione {
            stato.impostaEtaPensioneLineaVita(clienteId: cliente.id, eta: eta)
        } else {
            stato.spostaEventoVita(g.id, eta: eta, etaOggi: etaOggi)
        }
    }

    // MARK: Note

    private func note(_ prep: PreparazioneLineaVita) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let senzaEventi = stato.eventiVitaCliente(cliente.id).isEmpty
        let diProva = stato.haDatiDiProva && StatoShell.clientiDiProva.contains(cliente.id)
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: k.spazioNote) {
                if senzaEventi {
                    riga("Nessun evento nella linea della vita. Aggiungi la casa, i figli, un'eredità: Prisma ricalcola il futuro.",
                         colore: k.coloreNota)
                }
                if prep.eventiSenzaCifra > 0 {
                    riga(prep.eventiSenzaCifra == 1
                         ? "Un evento senza cifra: si vede sulla linea ma non entra nel calcolo."
                         : "\(prep.eventiSenzaCifra) eventi senza cifra: si vedono sulla linea ma non entrano nel calcolo.",
                         colore: k.coloreNota)
                }
                ForEach(prep.avvisi, id: \.self) { riga($0, colore: k.coloreAvviso) }
                ForEach(prep.ipotesi, id: \.self) { riga($0, colore: k.coloreNota) }
                if diProva { riga("Dati di prova.", colore: k.coloreNota) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func riga(_ testo: String, colore: Color) -> some View {
        Text(testo)
            .carattereApple(Tema.Apple.Clienti.LineaVita.nota)
            .foregroundColor(colore)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Un gettone della linea del tempo: un evento, un obiettivo (fisso) o la pensione.
struct GettoneLineaVita: Identifiable, Equatable {
    let id: String
    let nome: String
    let eta: Int
    let genere: GettoneEventoApple.Genere
    /// Non si trascina: un obiettivo del dossier (la scadenza si cambia negli Obiettivi).
    let fisso: Bool
    let importo: Double?
    let perAnni: Int
    /// L'età di pensione è un'ipotesi (67), non un dato del cliente.
    let ipotesi: Bool

    func dettaglio(_ eta: Int) -> String {
        if genere == .senzaCifra { return "\(eta) anni · senza cifra" }
        return ipotesi ? "\(eta) anni · ipotesi" : "\(eta) anni"
    }

    var aiuto: String {
        if fisso { return "Dall'obiettivo del dossier: la scadenza si cambia negli Obiettivi" }
        if genere == .pensione { return "Trascina per cambiare l'età della pensione (fra 55 e 72 anni)" }
        return "Trascina per cambiare l'età; un clic per modificare l'evento"
    }

    /// Per VoiceOver: «Casa, 40 anni, uscita di 40.000 euro, regolabile».
    func descrizione(_ eta: Int) -> String {
        var parti = [nome, "\(eta) anni"]
        if let importo {
            let cifra = FormatoCifra.migliaia(abs(importo)) + " euro"
            let volte = perAnni > 1 ? " ogni anno per \(perAnni) anni" : ""
            parti.append((importo > 0 ? "entrata di " : "uscita di ") + cifra + volte)
        } else if genere == .senzaCifra {
            parti.append("senza cifra")
        }
        if ipotesi { parti.append("ipotesi") }
        if !fisso { parti.append("regolabile") }
        return parti.joined(separator: ", ")
    }
}

// MARK: - Il grafico

/// Il patrimonio da oggi alla fine: zona della pensione, area e curva, righe degli eventi, punto della fine.
/// Scala da 0 al massimo × 1,08; sotto zero la curva corre sul fondo.
struct GraficoLineaVita: View {
    let esito: EsitoLineaVita
    let etaOggi: Int
    let entrate: [Int]
    let uscite: [Int]

    var body: some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let anni = Double(max(1, esito.etaFine - etaOggi))
        let alto = max(1, esito.massimo) * k.scala
        let punti = esito.punti.map {
            CGPoint(x: CGFloat(Double($0.eta - etaOggi) / anni), y: CGFloat(max(0, $0.valore) / alto))
        }
        let xPensione = CGFloat(Double(min(max(esito.etaPensione, etaOggi), esito.etaFine) - etaOggi) / anni)
        return ZStack(alignment: .topLeading) {
            zona(xPensione)
            curva(punti)
            RigheLineaVita(xs: entrate.map { x($0, anni) })
                .stroke(k.coloreEntrata, style: StrokeStyle(lineWidth: k.spessoreEventi, dash: k.tratteggioEventi))
                .opacity(k.opacitaEventi)
            RigheLineaVita(xs: uscite.map { x($0, anni) })
                .stroke(k.coloreUscita, style: StrokeStyle(lineWidth: k.spessoreEventi, dash: k.tratteggioEventi))
                .opacity(k.opacitaEventi)
            if let fine = esito.etaEsaurimento {
                puntoFine(fine, x: x(fine, anni))
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(descrizione))
    }

    private func x(_ eta: Int, _ anni: Double) -> CGFloat {
        CGFloat(Double(min(max(eta, etaOggi), esito.etaFine) - etaOggi) / anni)
    }

    private func zona(_ xPensione: CGFloat) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        return GeometryReader { g in
            let x0 = xPensione * g.size.width
            let larga = max(0, g.size.width - x0)
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(k.colorePensione.opacity(k.opacitaZona))
                    .frame(width: larga, height: g.size.height)
                if larga > 2 * k.margineGettoni {
                    Text("in pensione")
                        .carattereApple(k.scrittaZona)
                        .foregroundColor(k.coloreScrittaZona)
                        .fixedSize()
                        .padding(.leading, k.margineScrittaZona)
                        .padding(.bottom, k.margineScrittaZona)
                }
            }
            .frame(width: larga, height: g.size.height, alignment: .bottomLeading)
            .offset(x: x0)
        }
    }

    /// La curva: piena; senza prelievo calcolato, tratteggiata dopo la pensione (solo indicativa).
    @ViewBuilder private func curva(_ punti: [CGPoint]) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        if esito.dopoPensioneIndicativa, punti.count > 1 {
            let taglio = min(max(esito.etaPensione - etaOggi, 0), punti.count - 1)
            TracciatoGrafico(punti: Array(punti[0...taglio]), colore: k.coloreCurva, spessore: k.spessoreCurva,
                             area: true, opacitaArea: k.opacitaArea, indice: 0, ritardo: k.ritardoCurva)
            TracciatoGrafico(punti: Array(punti[taglio...]), colore: k.coloreCurva, spessore: k.spessoreCurva,
                             tratteggio: k.tratteggioIndicativa, area: true, opacitaArea: k.opacitaAreaIndicativa,
                             indice: 1, ritardo: k.ritardoCurva)
        } else {
            TracciatoGrafico(punti: punti, colore: k.coloreCurva, spessore: k.spessoreCurva,
                             area: true, opacitaArea: k.opacitaArea, indice: 0, ritardo: k.ritardoCurva)
        }
    }

    private func puntoFine(_ eta: Int, x: CGFloat) -> some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        return GeometryReader { g in
            let cx = x * g.size.width
            let r = k.raggioFine
            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(k.coloreFine)
                    .frame(width: 2 * r, height: 2 * r)
                    .position(x: cx, y: g.size.height)
                Text("finisce a \(eta) anni")
                    .carattereApple(k.scrittaFine)
                    .foregroundColor(k.coloreFine)
                    .fixedSize()
                    .position(x: min(max(cx, k.margineGettoni), max(k.margineGettoni, g.size.width - k.margineGettoni)),
                              y: g.size.height - k.sopraScrittaFine)
            }
        }
    }

    private var descrizione: String {
        let basta = esito.etaEsaurimento.map { "il patrimonio finisce a \($0) anni" } ?? "il patrimonio basta oltre i \(esito.etaFine) anni"
        return "Linea della vita: a \(esito.etaPensione) anni, in pensione, \(Formati.euro(max(0, esito.allaPensione))); "
            + "al massimo \(Formati.euro(max(0, esito.massimo))) a \(esito.etaMassimo) anni; \(basta)."
    }
}

/// Righe verticali a tutta altezza alle x normalizzate (0…1).
private struct RigheLineaVita: Shape {
    let xs: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        for x in xs {
            let posizione = rect.minX + x * rect.width
            p.move(to: CGPoint(x: posizione, y: rect.minY))
            p.addLine(to: CGPoint(x: posizione, y: rect.maxY))
        }
        return p
    }
}

// MARK: - La cache della preparazione

/// `MotoreLineaVita.prepara` legge posizioni, pensione e obiettivi: si rifà solo se cambiano i dati del cliente o il
/// giorno, non a ogni passo del trascinamento.
enum CacheLineaVita {
    nonisolated(unsafe) private static var memoria: [Int: PreparazioneLineaVita] = [:]
    private static let massimo = 12

    static func preparazione(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita],
                             analisi: Analisi360?, oggi: Date = Date()) -> PreparazioneLineaVita {
        var h = Hasher()
        h.combine(cliente)
        h.combine(posizioni)
        h.combine(obiettivi)
        h.combine(eventi)
        h.combine(analisi != nil)
        if let a = analisi {
            h.combine(a.previdenza.etaPensione)
            h.combine(a.previdenza.redditoDesiderato)
            h.combine(a.previdenza.pensionePubblica)
            h.combine(a.previdenza.rendimentoReale)
        }
        h.combine(Calendar.current.startOfDay(for: oggi))
        let chiave = h.finalize()
        if let p = memoria[chiave] { return p }
        let p = MotoreLineaVita.prepara(cliente: cliente, posizioni: posizioni, obiettivi: obiettivi, eventi: eventi,
                                        analisi: analisi, oggi: oggi)
        if memoria.count >= massimo { memoria.removeAll() }
        memoria[chiave] = p
        return p
    }
}

// MARK: - Il foglio di un evento

/// L'evento da aggiungere o modificare nel foglio.
struct ModificaEventoLineaVita: Identifiable {
    let id = UUID()
    let evento: EventoLineaVita
    let nuovo: Bool
    let etaOggi: Int
}

/// Il foglio di un evento della linea della vita: tipo, nome sul gettone, età, entrata o uscita con l'importo in euro
/// di oggi (o senza cifra: si vede ma non entra nel calcolo), una volta o ogni anno per N anni, la nota interna
/// (non in modalità cliente né in presentazione). Nessun importo suggerito: la cifra la dà il consulente.
struct ModuloEventoLineaVita: View {
    enum Verso: Hashable { case uscita, entrata, senzaCifra }

    let nuovo: Bool
    let etaOggi: Int
    let riservato: Bool
    let salva: (EventoLineaVita) -> Void
    let elimina: () -> Void

    @Environment(\.dismiss) private var chiudi
    @State private var bozza: EventoLineaVita
    @State private var eta: Int
    @State private var verso: Verso
    @State private var importo: Double
    @State private var durata: Int

    private static let numero = FloatingPointFormatStyle<Double>.number.locale(Formati.localeImporti)

    init(modifica m: ModificaEventoLineaVita, riservato: Bool, salva: @escaping (EventoLineaVita) -> Void,
         elimina: @escaping () -> Void) {
        nuovo = m.nuovo
        etaOggi = m.etaOggi
        self.riservato = riservato
        self.salva = salva
        self.elimina = elimina
        let annoOggi = Calendar.current.component(.year, from: Date())
        let etaEvento = m.evento.etaEvento(etaOggi: m.etaOggi, annoOggi: annoOggi) ?? m.etaOggi + 1
        _bozza = State(initialValue: m.evento)
        _eta = State(initialValue: MotoreLineaVita.limitaEtaEvento(etaEvento, etaOggi: m.etaOggi))
        let cifra = m.evento.importo.flatMap { $0.isFinite && $0 != 0 ? $0 : nil }
        _verso = State(initialValue: cifra.map { $0 > 0 ? Verso.entrata : Verso.uscita } ?? (m.nuovo ? .uscita : .senzaCifra))
        _importo = State(initialValue: abs(cifra ?? 0))
        _durata = State(initialValue: m.evento.anniDurata)
    }

    var body: some View {
        let k = Tema.Apple.Clienti.LineaVita.self
        let minima = min(etaOggi + 1, MotoreLineaVita.etaEventoMassima)
        return CorniceModulo(titolo: nuovo ? "Nuovo evento della vita" : "Modifica l'evento") {
            VStack(alignment: .leading, spacing: k.spazioModulo) {
                CampoModulo(etichetta: "Che cosa") {
                    Picker("", selection: $bozza.tipo) {
                        ForEach(EventoLineaVita.Tipo.allCases.filter { $0 != .pensione }) { Text($0.nome).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: k.larghezzaSceltaModulo)
                }
                CampoModulo(etichetta: "Nome sul gettone") {
                    TextField(bozza.tipo.nome, text: titolo)
                        .textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "A che età") {
                    Stepper(value: $eta, in: minima...MotoreLineaVita.etaEventoMassima) {
                        Text(verbatim: "\(eta) anni")
                            .monospacedDigit()
                    }
                }
                CampoModulo(etichetta: "Movimento") {
                    Picker("", selection: $verso) {
                        Text("Uscita").tag(Verso.uscita)
                        Text("Entrata").tag(Verso.entrata)
                        Text("Senza cifra").tag(Verso.senzaCifra)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: k.larghezzaSceltaModulo)
                }
                if verso != .senzaCifra {
                    CampoModulo(etichetta: "Importo, in euro di oggi") {
                        HStack(spacing: k.spazioCampoModulo) {
                            TextField("0", value: $importo, format: Self.numero)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.trailing)
                                .frame(width: k.larghezzaImportoModulo)
                            Text(verbatim: durata > 1 ? "€ ogni anno" : "€")
                                .font(Tipo.campoEtichetta)
                                .foregroundColor(Colori.Rubrica.secondario)
                        }
                    }
                    CampoModulo(etichetta: "Quante volte") {
                        Stepper(value: $durata, in: 1...k.massimoAnniModulo) {
                            Text(verbatim: durata > 1 ? "Ogni anno per \(durata) anni" : "Una volta")
                        }
                    }
                }
                if !riservato {
                    CampoModulo(etichetta: "Nota interna") {
                        TextField("", text: $bozza.nota)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        } piede: {
            if !nuovo {
                Button("Togli dalla linea", role: .destructive) {
                    elimina()
                    chiudi()
                }
                .buttonStyle(StileVetro())
            }
            Spacer()
            Button("Annulla") { chiudi() }
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(nuovo ? "Aggiungi" : "Salva") {
                salva(evento)
                chiudi()
            }
            .buttonStyle(StileBlu())
            .disabled(verso != .senzaCifra && !(importo > 0))
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: k.larghezzaModulo, height: k.altezzaModulo)
    }

    private var titolo: Binding<String> {
        Binding(get: { bozza.titolo ?? "" }, set: { bozza.titolo = $0.isEmpty ? nil : $0 })
    }

    /// L'evento come si salva: età e anno, importo con il segno (nil senza cifra), durata (nil = una volta).
    private var evento: EventoLineaVita {
        var e = bozza
        let annoOggi = Calendar.current.component(.year, from: Date())
        e.eta = eta
        e.anno = annoOggi + (eta - etaOggi)
        if verso == .senzaCifra || !(importo > 0) || !importo.isFinite {
            e.importo = nil
            e.durataAnni = nil
        } else {
            e.importo = verso == .entrata ? importo : -importo
            e.durataAnni = durata > 1 ? durata : nil
        }
        let nome = (e.titolo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        e.titolo = nome.isEmpty ? nil : nome
        return e
    }
}
