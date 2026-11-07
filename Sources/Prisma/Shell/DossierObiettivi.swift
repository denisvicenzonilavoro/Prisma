import SwiftUI

/// Scheda «Obiettivi» del dossier nel tema Apple (Design/template-apple-specifica.md §4.2.3, PC C08-C16, C22;
/// MO 01, 06, 06b, 15, 16):
///
///   ┌──────────────┐ ┌──────────────┐ ┌ ─ ─ ─ ─ ─ ─ ─ ┐
///   │   ◯ 52%      │ │   ◯ 31%      │      ＋
///   │ Anticipo casa│ │  Pensione    │ │ Un nome al     │
///   │ 20.800 € di… │ │ …            │   futuro: nuovo
///   │ 550 € al mese│ │              │ │ obiettivo      │
///   │ Prova un altro versamento ›   │  ─ ─ ─ ─ ─ ─ ─ ─
///   └──────────────┘ └──────────────┘
///
/// - Le card (inclinazione 10) mostrano l'anello della quota già messa da parte, le cifre e il mese di arrivo con
///   il versamento di oggi (premi delle posizioni collegate più il versamento previsto dell'obiettivo); toccate,
///   si aprono nel dettaglio (PresentatoreDettaglio) che nasce dalla card.
/// - Il dettaglio: l'anello grande SEGUE il cursore e mostra la copertura alla scadenza; data di arrivo e scarto si
///   ricalcolano dal vivo (`CurvaObiettivo`, dai conti di `MotoreObiettivo` con il rendimento delle posizioni
///   collegate e quello dell'obiettivo per i versamenti nuovi). «Salva nel dossier» scrive il versamento previsto
///   nell'obiettivo (`Obiettivo.versamentoMensile`) e mostra il toast. Sotto il cursore resta il dettaglio completo
///   di Prisma: cifre, probabilità con la traiettoria, posizioni che lavorano per l'obiettivo, azioni.
/// - Con meno di tre obiettivi compare il posto libero tratteggiato, che apre il nuovo obiettivo.
/// - Riduci movimento e istantanee: tutto nello stato finale (lo fanno i componenti del tema).
struct ObiettiviDossierApple: View {
    @EnvironmentObject var stato: StatoShell
    @Environment(\.statoDettaglioApple) private var dettaglio
    let cliente: Cliente
    @State private var modulo: Obiettivo?

    var body: some View {
        let s = Tema.Apple.Clienti.Obiettivi.self
        let elenco = stato.obiettiviCliente(cliente.id)
        let posizioni = stato.posizioniCliente(cliente.id)
        let colonne = [GridItem(.adaptive(minimum: s.colonnaMinima), spacing: s.spazio, alignment: .top)]
        return VStack(alignment: .leading, spacing: s.sopraSeguito) {
            LazyVGrid(columns: colonne, alignment: .leading, spacing: s.spazio) {
                ForEach(Array(elenco.enumerated()), id: \.element.id) { i, o in
                    SchedaObiettivoApple(obiettivo: o, posizioni: posizioni, indice: i) { apri(o) }
                        .entrataDossier(i)
                }
                if elenco.count < s.postiDelTemplate {
                    PostoLiberoObiettivoApple(attivo: !stato.solaLettura) { nuovo() }
                        .entrataDossier(elenco.count)
                }
            }
            seguito(elenco)
                .entrataDossier(min(elenco.count, s.postiDelTemplate) + 1, sfocatura: false)
        }
        .sheet(item: $modulo) { o in
            ModuloObiettivo(bozza: o, nuovo: !stato.dati.obiettivi.contains { $0.id == o.id }) { stato.salvaObiettivo($0) }
        }
    }

    /// Sotto le card: gli obiettivi a parole del Profilo, «Nuovo obiettivo» (quando il posto libero non c'è più) e
    /// gli obiettivi suggeriti dagli eventi di vita.
    private func seguito(_ elenco: [Obiettivo]) -> some View {
        let s = Tema.Apple.Clienti.Obiettivi.self
        let testo = cliente.profilo.obiettivi.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(alignment: .leading, spacing: s.spazioSintesi) {
            HStack(alignment: .firstTextBaseline, spacing: s.spazioSintesi) {
                if !testo.isEmpty {
                    Image(systemName: "quote.opening")
                        .font(s.sintesi.font)
                        .foregroundColor(s.coloreSintesi)
                        .accessibilityHidden(true)
                    Text(testo)
                        .carattereApple(s.sintesi)
                        .foregroundColor(s.coloreSintesi)
                        .lineLimit(2)
                        .help(testo)
                    Button("Nel profilo") { stato.schedaCliente = .profilo }
                        .buttonStyle(.appleSobrio)
                        .help("Gli obiettivi principali a parole si modificano nel Profilo")
                }
                Spacer(minLength: 0)
                if elenco.count >= s.postiDelTemplate {
                    Button { nuovo() } label: { Label("Nuovo obiettivo", systemImage: "plus") }
                        .buttonStyle(.apple)
                        .disabled(stato.solaLettura)
                }
            }
            SuggerimentiObiettivi(eventi: cliente.bisogni.eventi, elenco: elenco) { titolo, area, anno in
                nuovo(titolo, area: area, anno: anno)
            }
        }
    }

    private func nuovo(_ titolo: String = "", area: AreaBisogno = .patrimonio, anno: Int? = nil) {
        modulo = AiutiObiettivi.nuovo(clienteId: cliente.id, titolo: titolo, area: area, anno: anno)
    }

    /// Il dettaglio nasce dalla card; fuori dal presentatore (non dovrebbe succedere) si apre il modulo.
    private func apri(_ o: Obiettivo) {
        stato.obiettivoSelezionato = o.id
        if let d = dettaglio {
            d.apri(o.id, misura: Tema.Apple.Clienti.DettaglioObiettivo.misura)
        } else {
            modulo = o
        }
    }
}

// MARK: - Testi

/// I testi delle card e del dettaglio degli obiettivi (cifre dai motori, mai scritte a mano).
enum TestiObiettivoApple {
    static func euro(_ v: Double) -> String { FormatoCifra.euro.testo(v) }

    /// «20.800 € di 40.000 €».
    static func cifre(_ messi: Double, di importo: Double) -> String {
        "\(euro(messi)) di \(euro(importo))"
    }

    /// «ottobre 2029» a `mesi` mesi da `curva.inizio`.
    static func mese(_ mesi: Int, curva: CurvaObiettivo) -> String {
        let data = Calendar.current.date(byAdding: .month, value: mesi, to: curva.inizio) ?? curva.inizio
        return Formati.meseAnno.string(from: data)
    }

    /// «550 € al mese · arriva a ottobre 2029», «… · già raggiunto» o «… · non ci arriva».
    static func riga(totale: Double, arrivo: Int?, curva: CurvaObiettivo) -> String {
        let quando: String
        if let m = arrivo {
            quando = m == 0 ? "già raggiunto" : "arriva a \(mese(m, curva: curva))"
        } else {
            quando = "non ci arriva"
        }
        return "\(euro(totale)) al mese · \(quando)"
    }

    /// «4 mesi prima», «2 mesi dopo», «Come con il versamento di oggi» o, se non ci arriva, quanto manca alla scadenza;
    /// sempre con la scadenza.
    static func scarto(nuovo: Int?, oggi: Int?, uguale: Bool, mancante: Double, scadenza: Date) -> String {
        let fine = " · scadenza " + Formati.meseAnno.string(from: scadenza)
        guard let n = nuovo else { return "Alla scadenza mancano \(euro(mancante))" + fine }
        if uguale { return "Con il versamento di oggi" + fine }
        guard let o = oggi else { return "Con il versamento di oggi non ci arriverebbe" + fine }
        let dm = o - n
        if dm == 0 { return "Come con il versamento di oggi" + fine }
        let quanti = abs(dm)
        return "\(quanti) \(quanti == 1 ? "mese" : "mesi") \(dm > 0 ? "prima" : "dopo")" + fine
    }

    /// I canali delle posizioni collegate in essere, nell'ordine di sempre.
    static func canali(_ o: Obiettivo, posizioni: [Posizione]) -> [Canale] {
        let presenti = Set(posizioni.filter { o.posizioniCollegate.contains($0.id) && $0.stato == .inEssere }.map(\.canale))
        return Canale.allCases.filter { presenti.contains($0) }
    }
}

// MARK: - Card dell'obiettivo

/// La card di un obiettivo: anello 150/15 nel colore dell'obiettivo con la percentuale già messa da parte, nome,
/// «20.800 € di 40.000 €», «550 € al mese · arriva a …», i canali delle posizioni collegate e «Prova un altro
/// versamento ›». Si inclina sotto il puntatore; il clic apre il dettaglio, che nasce da lei.
struct SchedaObiettivoApple: View {
    let obiettivo: Obiettivo
    let posizioni: [Posizione]
    let indice: Int
    let apri: () -> Void

    var body: some View {
        let s = Tema.Apple.Clienti.Obiettivi.self
        let o = obiettivo
        let a = AvanzamentoObiettivo(o, posizioni: posizioni)
        let curva = CacheMotoriAnalisi.curva(o, posizioni: posizioni)
        let colore = s.colore(o.area)
        let canali = TestiObiettivoApple.canali(o, posizioni: posizioni)
        let totale = a.versamentiAttivi + o.versamentoMensile
        let forma = RoundedRectangle(cornerRadius: s.raggio, style: .continuous)
        return Button(action: apri) {
            VStack(spacing: 0) {
                Anello(frazione: a.quota, colore: colore, misura: s.anello, spessore: s.spessoreAnello,
                       ritardo: Tema.Apple.Clienti.Moto.ritardoAnelli + Double(indice) * s.passoAnelli) {
                    // «oggi»: la copertura di adesso (il dettaglio mostra quella alla scadenza)
                    VStack(spacing: 0) {
                        NumeroCheConta(a.quota * 100, formato: .percentuale, indice: indice)
                            .carattereApple(s.centroAnello)
                            .foregroundColor(s.coloreCentro)
                        Text("oggi")
                            .carattereApple(s.sottoCentro)
                            .foregroundColor(s.coloreSottoCentro)
                    }
                }
                Text(o.titolo.isEmpty ? "Obiettivo" : o.titolo)
                    .carattereApple(s.nome)
                    .foregroundColor(s.coloreNome)
                    .lineLimit(2)
                    .padding(.top, s.sopraNome)
                Text(TestiObiettivoApple.cifre(a.accantonato, di: o.importo))
                    .carattereApple(s.testo)
                    .foregroundColor(s.coloreTesto)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.top, s.sopraTesto)
                Text(TestiObiettivoApple.riga(totale: totale, arrivo: curva.mesiArrivo(versamento: o.versamentoMensile),
                                              curva: curva))
                    .carattereApple(s.testo)
                    .foregroundColor(s.coloreTesto)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if !canali.isEmpty {
                    HStack(spacing: s.spazioCanali) {
                        ForEach(canali) { EtichettaCanaleApple(canale: $0, compatta: true) }
                    }
                    .padding(.top, s.sopraCanali)
                }
                Spacer(minLength: s.sopraCollegamento)
                Text("Prova un altro versamento ›")
                    .carattereApple(s.collegamento)
                    .foregroundColor(s.coloreCollegamento)
            }
            .multilineTextAlignment(.center)
            .padding(s.padding)
            .frame(maxWidth: .infinity, minHeight: s.altezzaMinima, alignment: .top)
            .superficieApple(s.superficie)
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .inclinazione(massimo: s.inclinazione, raggio: s.raggio)
        .origineDettaglio(id: o.id)
        .accessibilityHint("Apre il dettaglio dell'obiettivo")
    }
}

/// Il posto libero (meno di tre obiettivi): card trasparente tratteggiata «＋ Un nome al futuro: nuovo obiettivo».
/// In Prisma apre la creazione dell'obiettivo.
struct PostoLiberoObiettivoApple: View {
    let attivo: Bool
    let azione: () -> Void

    var body: some View {
        let s = Tema.Apple.Clienti.Obiettivi.self
        let forma = RoundedRectangle(cornerRadius: s.raggio, style: .continuous)
        return Button(action: azione) {
            VStack(spacing: s.spazioPostoLibero) {
                Text("＋")
                    .carattereApple(s.segnoPostoLibero)
                Text("Un nome al futuro:\nnuovo obiettivo")
                    .carattereApple(s.testoPostoLibero)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(s.colorePostoLibero)
            .frame(maxWidth: .infinity, minHeight: s.altezzaMinima)
            .overlay {
                forma.strokeBorder(s.bordoPostoLibero,
                                   style: StrokeStyle(lineWidth: s.spessorePostoLibero, dash: s.tratteggioPostoLibero))
                    .allowsHitTesting(false)
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .disabled(!attivo)
        .accessibilityLabel("Nuovo obiettivo")
    }
}

// MARK: - Dettaglio dell'obiettivo

/// L'altezza del piede del dettaglio dell'obiettivo (pulsanti e nota), per il margine del contenuto che scorre.
struct ChiaveAltezzaPiedeObiettivo: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Il dettaglio dell'obiettivo (920×520): `.lbl` nel colore e nome 30; l'anello 220/22 della copertura alla
/// scadenza, che segue il cursore; «Già messi da parte» e «Obiettivo» che contano; il versamento mensile con il
/// cursore; «Arriva a <mese anno>» e lo scarto, ricalcolati a ogni passo; sotto, il dettaglio completo di Prisma.
/// Piede: «Salva nel dossier», «Annulla» e la nota sul rendimento.
struct DettaglioObiettivoApple: View {
    @EnvironmentObject var stato: StatoShell
    @Environment(\.statoDettaglioApple) private var dettaglio
    let obiettivo: Obiettivo
    let posizioni: [Posizione]
    /// Calcolati una volta quando cambiano obiettivo o posizioni, non a ogni passo del cursore (che cambia solo
    /// `versamento`: il corpo si ridisegna senza rifare l'avanzamento, che cerca il versamento per bisezione).
    private let avanzamento: AvanzamentoObiettivo
    private let curva: CurvaObiettivo
    /// Il versamento mensile in più del cursore (parte da quello previsto dell'obiettivo).
    @State private var versamento: Double
    @State private var modulo: Obiettivo?
    @State private var daEliminare = false
    /// L'altezza del piede: il contenuto che scorre ha in fondo un margine pari a questa.
    @State private var altezzaPiede: CGFloat = 0

    init(obiettivo: Obiettivo, posizioni: [Posizione]) {
        self.obiettivo = obiettivo
        self.posizioni = posizioni
        avanzamento = AvanzamentoObiettivo(obiettivo, posizioni: posizioni)
        curva = CacheMotoriAnalisi.curva(obiettivo, posizioni: posizioni)
        _versamento = State(initialValue: obiettivo.versamentoMensile)
    }

    var body: some View {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        let o = obiettivo
        let colore = Tema.Apple.Clienti.Obiettivi.colore(o.area)
        let curva = self.curva
        let a = avanzamento
        // Il contenuto scorre fino sopra il piede (margine in fondo pari al piede) e sfuma prima dei pulsanti:
        // le tessere del dettaglio completo non restano mai coperte dalla barra in basso
        return ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    testata(o, colore: colore)
                    corpo(o, avanzamento: a, curva: curva, colore: colore)
                        .padding(.top, d.sopraCorpo)
                    // Uguale finché non cambiano obiettivo e posizioni: il cursore non lo ridisegna
                    DettaglioCompletoObiettivoApple(obiettivo: o, avanzamento: a, posizioni: posizioni,
                                                    modifica: { modulo = o }, elimina: { daEliminare = true })
                        .equatable()
                        .padding(.top, d.sopraCompleto)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, altezzaPiede + d.sfumaturaPiede)
            }
            .mask {
                VStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: d.sfumaturaPiede)
                    Color.clear
                        .frame(height: altezzaPiede)
                }
            }
            piede(o)
                .padding(.top, d.sopraPiede)
                .background {
                    GeometryReader { g in
                        Color.clear.preference(key: ChiaveAltezzaPiedeObiettivo.self, value: g.size.height)
                    }
                }
        }
        .onPreferenceChange(ChiaveAltezzaPiedeObiettivo.self) { altezzaPiede = $0 }
        .sheet(item: $modulo) { m in
            ModuloObiettivo(bozza: m, nuovo: false) { stato.salvaObiettivo($0) }
        }
        .alert("Eliminare l'obiettivo?", isPresented: $daEliminare) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina", role: .destructive) { elimina() }
        } message: {
            Text("Le posizioni collegate restano in Posizioni.")
        }
    }

    // MARK: Parti

    private func testata(_ o: Obiettivo, colore: Color) -> some View {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        return VStack(alignment: .leading, spacing: d.spazioTestata) {
            Text("Obiettivo · " + o.area.nome)
                .carattereApple(d.etichetta)
                .foregroundColor(colore)
            Text(o.titolo.isEmpty ? "Obiettivo" : o.titolo)
                .carattereApple(d.titolo)
                .foregroundColor(d.coloreTitolo)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        // Lo spazio del ✕ del dettaglio, in alto a destra
        .padding(.trailing, Tema.Apple.Misura.Padding.chiudiDettaglio * 2)
    }

    private func corpo(_ o: Obiettivo, avanzamento a: AvanzamentoObiettivo, curva: CurvaObiettivo, colore: Color) -> some View {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        let copertura = curva.copertura(versamento: versamento)
        return HStack(alignment: .center, spacing: d.spazioAnello) {
            Anello(frazione: copertura, colore: colore, misura: d.anello, spessore: d.spessoreAnello,
                   ritardo: Tema.Apple.Moto.Anello.ritardoDettaglio) {
                VStack(spacing: 0) {
                    NumeroCheConta(copertura * 100, formato: .percentuale)
                        .carattereApple(d.centroAnello)
                        .foregroundColor(d.coloreCentro)
                    Text("alla scadenza")
                        .carattereApple(d.sottoCentro)
                        .foregroundColor(d.coloreSottoCentro)
                }
            }
            .accessibilityLabel("Copertura alla scadenza")
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: d.spazioCifre) {
                    cifra("Già messi da parte", a.accantonato, indice: 0)
                    cifra("Obiettivo", o.importo, indice: 1)
                }
                Text("Versamento mensile")
                    .carattereApple(d.etichettaVersamento)
                    .foregroundColor(d.coloreEtichetta)
                    .padding(.top, d.sopraVersamento)
                CursoreApple(valore: $versamento, intervallo: 0...massimo(o, curva: curva), passo: d.passoCursore,
                             etichetta: "Versamento mensile", formato: .euro,
                             carattereValore: d.valoreVersamento, coloreValore: colore)
                    .frame(maxWidth: d.larghezzaCursore)
                    .padding(.top, d.sopraCursore)
                    .disabled(stato.solaLettura)
                if a.versamentiAttivi > 0 {
                    Text("in più dei \(TestiObiettivoApple.euro(a.versamentiAttivi)) al mese delle posizioni collegate")
                        .carattereApple(d.scarto)
                        .foregroundColor(d.coloreScarto)
                        .padding(.top, d.sopraNotaCollegate)
                }
                arrivo(curva: curva, attivi: a.versamentiAttivi)
                    .padding(.top, d.sopraArrivo)
                Text(TestiObiettivoApple.scarto(nuovo: curva.mesiArrivo(versamento: versamento),
                                                oggi: curva.mesiArrivo(versamento: o.versamentoMensile),
                                                uguale: versamento == o.versamentoMensile,
                                                mancante: curva.mancante(versamento: versamento),
                                                scadenza: o.scadenza))
                    .carattereApple(d.scarto)
                    .foregroundColor(d.coloreScarto)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, d.sopraScarto)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cifra(_ titolo: String, _ valore: Double, indice: Int) -> some View {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        return VStack(alignment: .leading, spacing: d.spazioTestata) {
            Text(titolo)
                .carattereApple(d.etichettaCifra)
                .foregroundColor(d.coloreEtichetta)
            NumeroCheConta(valore, indice: indice)
                .carattereApple(d.valoreCifra)
                .foregroundColor(d.coloreValore)
                .lineLimit(1)
        }
    }

    /// «Arriva a **ottobre 2029**», «Già raggiunto» o, se non ci arriva, «Con 0 € al mese non ci arriva».
    private func arrivo(curva: CurvaObiettivo, attivi: Double) -> some View {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        let testo: Text
        if let m = curva.mesiArrivo(versamento: versamento) {
            if m == 0 {
                testo = Text("Già raggiunto").font(d.arrivoForte.font)
            } else {
                testo = Text("Arriva a ").font(d.arrivo.font)
                    + Text(TestiObiettivoApple.mese(m, curva: curva)).font(d.arrivoForte.font)
            }
        } else if versamento <= 0 && attivi > 0 {
            testo = Text("Senza versamenti in più non ci arriva").font(d.arrivo.font)
        } else {
            testo = Text("Con \(TestiObiettivoApple.euro(versamento)) al mese non ci arriva").font(d.arrivo.font)
        }
        return testo
            .foregroundColor(d.coloreArrivo)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Da 0 a max(v·2,4 arrotondato a 10; fabbisogno·1,2 arrotondato a 50; 300), mai sotto il versamento salvato.
    private func massimo(_ o: Obiettivo, curva: CurvaObiettivo) -> Double {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        let daVersamento = (o.versamentoMensile * d.moltiplicatoreCursore / d.passoCursore).rounded() * d.passoCursore
        let fabbisogno = curva.versamentoNecessario ?? 0
        let daFabbisogno = (fabbisogno * d.margineFabbisogno / d.arrotondamentoFabbisogno).rounded(.up) * d.arrotondamentoFabbisogno
        return max(d.minimoCursore, daVersamento, daFabbisogno, o.versamentoMensile)
    }

    private func piede(_ o: Obiettivo) -> some View {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        return HStack(alignment: .center, spacing: d.spazioPiede) {
            Button("Salva nel dossier", action: salva)
                .buttonStyle(.applePrimarioGrande)
                .disabled(stato.solaLettura)
            Button("Annulla") { dettaglio?.chiudi() }
                .buttonStyle(.appleGrande)
            Text("Versamenti nuovi al \(Formati.percentuale(o.rendimento)) annuo, le posizioni collegate con le loro ipotesi, al netto di costi e imposte.")
                .carattereApple(d.nota)
                .foregroundColor(d.coloreNota)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, d.spazioNota - d.spazioPiede)
            Spacer(minLength: 0)
        }
    }

    // MARK: Azioni

    /// Scrive il versamento previsto nell'obiettivo, chiude il dettaglio e mostra il toast.
    private func salva() {
        guard !stato.solaLettura,
              var nuovo = stato.dati.obiettivi.first(where: { $0.id == obiettivo.id }) else { return }
        nuovo.versamentoMensile = versamento
        stato.salvaObiettivo(nuovo)
        let testo = versamento > 0
            ? "Nuovo versamento salvato nel dossier: \(TestiObiettivoApple.euro(versamento)) al mese"
            : "Versamento previsto tolto dall'obiettivo"
        let s = stato
        if let d = dettaglio {
            d.chiudi(poi: { s.mostraAvviso(testo) })
        } else {
            s.mostraAvviso(testo)
        }
    }

    private func elimina() {
        let id = obiettivo.id
        dettaglio?.chiudi(subito: true)
        stato.eliminaObiettivo(id)
    }
}

/// Il dettaglio di sempre sotto il cursore: le cifre, la probabilità con la traiettoria, le posizioni che lavorano
/// per l'obiettivo e le azioni (Simula, Modifica, prospetto, attività, elimina). Usa la scheda salvata. Equatable
/// su obiettivo e posizioni: trascinando il cursore non si ridisegna.
struct DettaglioCompletoObiettivoApple: View, Equatable {
    let obiettivo: Obiettivo
    let avanzamento: AvanzamentoObiettivo
    let posizioni: [Posizione]
    let modifica: () -> Void
    let elimina: () -> Void

    static func == (a: DettaglioCompletoObiettivoApple, b: DettaglioCompletoObiettivoApple) -> Bool {
        a.obiettivo == b.obiettivo && a.posizioni == b.posizioni
    }

    var body: some View {
        let d = Tema.Apple.Clienti.DettaglioObiettivo.self
        let o = obiettivo
        return VStack(alignment: .leading, spacing: d.spazioCompleto) {
            Rectangle()
                .fill(d.filo)
                .frame(height: Tema.Apple.Misura.bordo)
            HStack(alignment: .center, spacing: d.spazioTitoloCompleto) {
                Text("Il dettaglio completo")
                    .carattereApple(d.titoloCompleto)
                    .foregroundColor(d.coloreTitoloCompleto)
                Spacer(minLength: d.spazioTitoloCompleto)
                AzioniObiettivo(obiettivo: o, modifica: modifica, elimina: elimina)
            }
            CifreObiettivo(obiettivo: o, avanzamento: avanzamento)
            if o.scadenza > Date() {
                ProbabilitaObiettivo(esito: CacheMotoriAnalisi.scenari(o, posizioni: posizioni), importo: o.importo)
            }
            PosizioniObiettivo(obiettivo: o, posizioni: posizioni)
        }
    }
}

// MARK: - Presentatore dei dettagli del dossier

/// Mette sopra Clienti (rubrica e dossier) il dettaglio che nasce da una card del dossier: oggi gli obiettivi.
/// Il dettaglio si centra in tutta l'app e la sfoca dietro con una sola sfocatura; si chiude da solo cambiando
/// cliente o scheda. Le istantanee possono chiederlo già aperto (`RichiestaIstantaneaDossier`).
struct PresentatoreDettaglioDossier<Contenuto: View>: View {
    @ObservedObject var stato: StatoShell
    @StateObject private var dettaglio: StatoDettaglio
    let contenuto: Contenuto

    init(stato: StatoShell, @ViewBuilder contenuto: () -> Contenuto) {
        _stato = ObservedObject(wrappedValue: stato)
        self.contenuto = contenuto()
        // L'oggetto nasce una volta sola (`StateObject` valuta l'espressione solo alla prima comparsa)
        _dettaglio = StateObject(wrappedValue: Self.dettaglioIniziale(stato))
    }

    private static func dettaglioIniziale(_ stato: StatoShell) -> StatoDettaglio {
        guard let id = RichiestaIstantaneaDossier.per(stato)?.dettaglio else { return StatoDettaglio() }
        return StatoDettaglio(aperto: id, misura: Tema.Apple.Clienti.DettaglioObiettivo.misura)
    }

    var body: some View {
        contenuto
            .presentatoreDettaglio(dettaglio) { id in
                DettaglioDossierApple(id: id)
            }
            .onChange(of: stato.clienteAttivoId) { _ in dettaglio.chiudi(subito: true) }
            .onChange(of: stato.schedaCliente) { _ in dettaglio.chiudi(subito: true) }
            .onDisappear { dettaglio.chiudi(subito: true) }
    }
}

/// Il contenuto del dettaglio aperto, secondo l'id dell'elemento da cui è nato.
struct DettaglioDossierApple: View {
    @EnvironmentObject var stato: StatoShell
    let id: String

    var body: some View {
        if let o = stato.dati.obiettivi.first(where: { $0.id == id }) {
            DettaglioObiettivoApple(obiettivo: o, posizioni: stato.posizioniCliente(o.clienteId))
                // Un altro obiettivo: il cursore riparte dal suo versamento
                .id(o.id)
        }
    }
}

/// Ciò che una scena delle istantanee chiede al dossier (Prisma --istantanee): il dettaglio di un elemento già aperto.
/// Vale solo per lo stato della scena (riferimento debole: le scene dopo non lo vedono).
final class RichiestaIstantaneaDossier {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaDossier?

    private weak var stato: StatoShell?
    let dettaglio: String

    private init(stato: StatoShell, dettaglio: String) {
        self.stato = stato
        self.dettaglio = dettaglio
    }

    static func chiedi(_ s: StatoShell, dettaglio: String) {
        attuale = RichiestaIstantaneaDossier(stato: s, dettaglio: dettaglio)
    }

    static func per(_ s: StatoShell) -> RichiestaIstantaneaDossier? {
        guard let r = attuale, r.stato === s else { return nil }
        return r
    }
}
