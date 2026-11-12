import SwiftUI

/// App Prodotti (.os-app-products): l'archivio delle schede prodotto, Alleanza e indipendenti,
/// con condizioni, costi e fonte verificabile. Da una scheda nasce la proposta per il cliente.
struct AppProdotti: View {
    @Environment(StatoShell.self) var stato
    @State var modulo: Prodotto?
    @State var moduloCondizioni: Prodotto?
    /// «Metti su un cliente»: il prodotto sul cliente in due passi (ModuloProdottoSulCliente).
    @State var sulCliente: RichiestaProdottoCliente?
    /// «Dai documenti»: la scheda letta da KID, DIP e condizioni (ModuloSchedaDaiDocumenti).
    @State var daiDocumenti: RichiestaSchedaDocumenti?
    @State var confermaEliminazione = false
    @State var ricerca = ""

    /// Le schede in ordine di nome, ordinate una volta per dati dei calcoli (`stato.prodotti` riordina a ogni lettura).
    private var ordinati: [Prodotto] {
        stato.ricavato("prodotti-ordinati") { stato.prodotti }
    }

    /// Le schede con i filtri del canale e dell'area e la ricerca.
    private func filtrati(_ tutti: [Prodotto]) -> [Prodotto] {
        let testo = ricerca.trimmingCharacters(in: .whitespaces).lowercased()
        let canale = stato.filtroCanaleProdotti
        let area = stato.filtroAreaProdotti
        return tutti
            .filter { canale == nil || $0.canale == canale }
            .filter { area == nil || $0.area == area }
            .filter { testo.isEmpty || $0.nome.lowercased().contains(testo) || $0.emittente.lowercased().contains(testo) }
    }

    private static func schedaScelta(in elenco: [Prodotto], id: String?) -> Prodotto? {
        elenco.first { $0.id == id } ?? elenco.first
    }

    private var scelto: Prodotto? {
        Self.schedaScelta(in: filtrati(ordinati), id: stato.prodottoSelezionato)
    }

    /// Quante schede in tutto, da verificare, per canale e per area: in un passaggio, non un filtro per voce.
    private struct Conteggi {
        var totale = 0
        var daVerificare = 0
        var perCanale: [Canale: Int] = [:]
        var perArea: [AreaPosizione: Int] = [:]

        init(_ prodotti: [Prodotto]) {
            for p in prodotti {
                totale += 1
                if p.daVerificare { daVerificare += 1 }
                perCanale[p.canale, default: 0] += 1
                perArea[p.area, default: 0] += 1
            }
        }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        // Una volta per passaggio: l'elenco ordinato dalla cache, i filtri e la scheda scelta qui e non per ogni riga
        let elenco = filtrati(ordinati)
        let attuale = Self.schedaScelta(in: elenco, id: stato.prodottoSelezionato)
        let conti = Conteggi(stato.dati.prodotti)
        CorniceStrumento(
            notaStato: "Schede compilate dal consulente · verifica sempre condizioni e costi sul KID in vigore",
            notaDestra: "\(conti.totale) schede · \(conti.daVerificare) da verificare"
        ) {
            rail(conti)
        } contenuto: {
            // Elenco e scheda nello stesso contenitore dell'elenco laterale, divisi da un filo
            ColonneAffiancate(larghezza: Misure.ColonneStrumento.elenco) {
                colonnaElenco(elenco, sceltoId: attuale?.id)
            } flessibile: {
                if let p = attuale {
                    dettaglio(p)
                } else {
                    VStack(spacing: 8) {
                        Text("Nessuna scheda con questi filtri.")
                            .font(Tema.Apple.AltreApp.titoloScheda.fontLeggibile)
                            .foregroundColor(Tema.Apple.AltreApp.testo)
                        Button { nuova() } label: { Label("Nuova scheda", systemImage: "plus") }.buttonStyle(StileBlu())
                        Button { daiDocumenti = RichiestaSchedaDocumenti() } label: {
                            Label("Dai documenti…", systemImage: "doc.text.magnifyingglass")
                        }
                        .buttonStyle(StileVetro())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
            }
        }
        // Tema Apple: barra laterale `.side`, card piatte, tessere, pulsanti, tendine ed etichette del canale
        .altreAppApple()
        .sheet(item: $modulo) { p in
            ModuloProdotto(bozza: p, nuovo: stato.prodotto(p.id) == nil) { stato.salvaProdotto($0) }
        }
        .sheet(item: $daiDocumenti) { r in
            ModuloSchedaDaiDocumenti(esistente: r.esistente)
                .environment(stato)
        }
        .sheet(item: $sulCliente) { r in
            ModuloProdottoSulCliente(prodotto: r.prodottoId.flatMap { stato.prodotto($0) }, statoIniziale: r.stato,
                                     clienteId: stato.clienteAttivoId, clienteScelto: r.clienteScelto)
                .environment(stato)
        }
        .sheet(item: $moduloCondizioni) { p in
            ModuloCondizioni(bozza: p.condizioni ?? CondizioniContratto(), prodotto: p.nome) { nuove in
                var x = p
                x.condizioni = nuove
                stato.salvaProdotto(x)
            }
        }
        .alert("Eliminare la scheda?", isPresented: $confermaEliminazione) {
            Button("Annulla", role: .cancel) {}
            Button("Elimina", role: .destructive) { if let p = scelto { stato.eliminaProdotto(p.id) } }
        } message: {
            Text("Le proposte già create restano nelle Posizioni, senza collegamento alla scheda.")
        }
    }

    /// Le condizioni dettagliate del contratto, per le valutazioni di riscatto (prospetto e report).
    private func condizioni(_ p: Prodotto) -> some View {
        PannelloAnalisi(titolo: "Condizioni del contratto",
                        nota: p.condizioni == nil ? "Per prospetti e report di valutazione" : "Per le valutazioni di riscatto") {
            EmptyView()
        } contenuto: {
            VStack(alignment: .leading, spacing: 0) {
                if let c = p.condizioni {
                    RigaDato("Parti", c.composizione)
                    RigaDato("Costo d'ingresso", "\(Formati.percentuale(c.costoIngresso))" + (c.costoIngressoMassimo.map { ", massimo \(Formati.euro($0))" } ?? ""))
                    RigaDato("Riscatto", (c.mesiBloccoRiscatto > 0 ? "bloccato per \(c.mesiBloccoRiscatto) mesi; " : "")
                             + (c.penali.isEmpty ? "senza penali" : "penali " + c.penali.map { CifreDoc.penale($0) }.joined(separator: " · ") + ", dal \(c.annoSenzaPenali)° anno nessuna"))
                    RigaDato("Imposte", "bollo \(CifreDoc.percento(c.bollo, decimali: 2)) · sostitutiva \(Formati.percentuale(c.aliquota)), titoli di Stato \(Formati.percentuale(c.aliquotaTitoliStato))")
                    RigaDato("KID", c.scenariKID.isEmpty ? "scenari non inseriti" : "\(c.scenariKID.count) scenari" + (c.dataDocumenti.map { " · \(Formati.dataBreve.string(from: $0))" } ?? ""))
                    RigaDato("Storico", c.componenti.map { "\($0.tipo.nome): \($0.storico.count) dati" }.joined(separator: " · "))
                } else {
                    Text("Parti, penali, bollo, scenari del KID e storico: Prisma calcola quanto si incassa anno per anno.")
                        .font(Tema.Apple.AltreApp.corpo.fontLeggibile).foregroundColor(Tema.Apple.AltreApp.testo)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 6)
                }
                HStack(spacing: 8) {
                    Button { moduloCondizioni = p } label: {
                        Label(p.condizioni == nil ? "Aggiungi le condizioni…" : "Modifica le condizioni…",
                              systemImage: p.condizioni == nil ? "plus" : "pencil")
                    }
                    .buttonStyle(StileVetro())
                    if p.condizioni != nil {
                        // Il blu della scheda è «Crea una proposta»: la valutazione va nel vetro d'accento
                        Button { stato.valutaProdotto(p.id) } label: {
                            Label("Valuta per \(stato.clienteAttivo?.nome ?? "il cliente")…", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .buttonStyle(StileVetro(accento: true))
                    }
                    // «Luce» §8.1.5.2 punto 6: il documento della Biblioteca collegato al prodotto (solo sul Mac)
                    if let d = stato.condizioniInBiblioteca(p.id) {
                        Button { stato.apriCondizioniInBiblioteca(p.id) } label: {
                            Label("Condizioni nella Biblioteca", systemImage: "books.vertical")
                        }
                        .buttonStyle(StileVetro())
                        .help("Apri «\(d.titolo)»" + (d.edizione.isEmpty ? "" : " (\(d.edizione))") + " nella Biblioteca")
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    /// I costi come nel KID: l'incidenza annua (RIY) dichiarata, quella che calcola Prisma su un esempio di
    /// 10.000 € in un'unica soluzione (stima, prima delle imposte) e il periodo raccomandato.
    private func testoKID(_ p: Prodotto) -> String {
        var parti: [String] = []
        if let dichiarato = p.incidenzaCostiKID {
            parti.append("RIY dichiarato \(Formati.percentuale(dichiarato)) l'anno")
        }
        var esempio = p.proposta(per: "")
        esempio.versamentoIniziale = 10_000
        if let incidenza = MotoreCosti.incidenzaKID(esempio, prodotto: p), let calcolato = incidenza.calcolato {
            parti.append("calcolato da Prisma \(Formati.percentuale(calcolato)) a \(incidenza.periodoRaccomandato) anni (stima su 10.000 € in un'unica soluzione)")
        }
        if let anni = p.periodoConsigliato {
            parti.append("periodo raccomandato \(anni) anni")
        }
        return parti.joined(separator: " · ")
    }

    /// I costi come nel KID in breve: «RIY 0,25% · Prisma 0,26% a 5 anni».
    private func testoKIDBreve(_ p: Prodotto) -> String {
        var parti: [String] = []
        if let dichiarato = p.incidenzaCostiKID {
            parti.append("RIY \(Formati.percentuale(dichiarato))")
        }
        var esempio = p.proposta(per: "")
        esempio.versamentoIniziale = 10_000
        if let incidenza = MotoreCosti.incidenzaKID(esempio, prodotto: p), let calcolato = incidenza.calcolato {
            parti.append("Prisma \(Formati.percentuale(calcolato)) a \(incidenza.periodoRaccomandato) anni")
        }
        return parti.joined(separator: " · ")
    }

    private func nuova() {
        var p = Prodotto(nome: "", canale: stato.filtroCanaleProdotti ?? .alleanza, area: stato.filtroAreaProdotti ?? .investimento)
        p.verificatoIl = Calendar.current.startOfDay(for: Date())
        modulo = p
    }

    // MARK: - Elenco laterale

    @ViewBuilder private func rail(_ conti: Conteggi) -> some View {
        DossierRail()
        // Il canale come in Documenti e in Posizioni: una voce per canale, un secondo clic toglie il filtro
        EtichettaRail(testo: "Canale")
        VStack(spacing: 0) {
            ForEach(Canale.allCases) { c in
                VoceNavigazione(titolo: c.nomeBreve, colore: Tema.Apple.AltreApp.canale(c),
                                conteggio: conti.perCanale[c] ?? 0,
                                attiva: stato.filtroCanaleProdotti == c) {
                    stato.filtroCanaleProdotti = stato.filtroCanaleProdotti == c ? nil : c
                }
                .help(Self.aiutoCanale(c, attivo: stato.filtroCanaleProdotti == c))
            }
        }
        EtichettaRail(testo: "Aree")
        VStack(spacing: 0) {
            VoceNavigazione(titolo: "Tutte le aree", conteggio: conti.totale, attiva: stato.filtroAreaProdotti == nil) {
                stato.filtroAreaProdotti = nil
            }
            ForEach([AreaPosizione.investimento, .risparmio, .previdenza, .protezione]) { a in
                VoceNavigazione(titolo: a.nome, colore: Colori.Analisi.area(a),
                                conteggio: conti.perArea[a] ?? 0, attiva: stato.filtroAreaProdotti == a) {
                    stato.filtroAreaProdotti = a
                }
            }
        }
        CollegatiRail(app: [.posizioni, .analisi360], strumenti: [.confronto, .simulatore])
    }

    /// L'aiuto di una voce del canale: il secondo clic sulla voce scelta toglie il filtro.
    static func aiutoCanale(_ c: Canale, attivo: Bool) -> String {
        if attivo { return "Clic di nuovo per vedere tutti i canali" }
        return c == .alleanza ? "Solo le schede Alleanza" : "Solo le schede indipendenti"
    }

    // MARK: - Elenco

    private func colonnaElenco(_ elenco: [Prodotto], sceltoId: String?) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Misure.ColonneStrumento.spazioTestata) {
                CampoRicerca(testo: $ricerca, segnaposto: "Cerca prodotto o compagnia")
                PulsanteIcona(simbolo: "doc.text.magnifyingglass", aiuto: "Nuova scheda dai documenti: KID, DIP, condizioni, scheda costi") {
                    daiDocumenti = RichiestaSchedaDocumenti()
                }
                PulsanteIcona(simbolo: "plus", aiuto: "Nuova scheda prodotto") { nuova() }
            }
            .testataColonna()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(elenco) { p in
                        Button { stato.prodottoSelezionato = p.id } label: { rigaElenco(p, attiva: p.id == sceltoId) }
                            .buttonStyle(StileSemplice())
                    }
                }
                .padding(.vertical, Tema.Misura.Strumenti.margineElenco)
            }
        }
    }

    private func rigaElenco(_ p: Prodotto, attiva: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            // Il nome va a capo (due righe) invece di troncarsi; canale e «da verificare» sulla prima riga
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                RoundedRectangle(cornerRadius: Tema.Raggio.quadratinoCanale, style: .continuous)
                    .fill(Colori.Analisi.area(p.area)).frame(width: 8, height: 8)
                Text(p.nome)
                    .font(Tema.Apple.AltreApp.titoloVoce.fontLeggibile)
                    .foregroundColor(Tema.Apple.AltreApp.testo)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Spacer(minLength: 4)
                if p.daVerificare {
                    Pillola(testo: "Da verificare", tono: .attenzione)
                }
                EtichettaCanale(canale: p.canale, compatta: true)
            }
            Text(Self.riassunto(p))
                .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                .foregroundColor(Tema.Apple.AltreApp.testoSecondario)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
        .voceElencoStrumento(attiva: attiva)
    }

    /// La riga sotto il nome nell'elenco: area, costo e SRI; per una multiramo con le due parti
    /// «GS 30% · trattenuto 1,30 — fondi 70% · costi 2,69 · SRI 3».
    static func riassunto(_ p: Prodotto) -> String {
        let q = p.proposta(per: "")
        guard q.multiramoDivisa else {
            return [p.area.nome, p.costoAnnuo.map { "costo \(Formati.percentuale($0))" } ?? "", p.sri.map { "SRI \($0)" } ?? ""]
                .filter { !$0.isEmpty }.joined(separator: " · ")
        }
        let punti: (Double) -> String = { String(CifreDoc.percento($0, decimali: 2).dropLast()) }
        let gestione = "GS \(Formati.percentuale(q.parteGestione * 100)) · trattenuto \(punti(q.trattenutoGestione))"
        let fondi = "fondi \(Formati.percentuale(q.parteFondi * 100)) · costi \(punti(q.costoParteFondi))"
        return "\(gestione) — \(fondi)" + (p.sri.map { " · SRI \($0)" } ?? "")
    }

    // MARK: - Condizioni e fonte

    private func pannelloCondizioni(_ p: Prodotto, cifre: CifreScheda) -> some View {
        PannelloAnalisi(titolo: "Condizioni") { EmptyView() } contenuto: {
            VStack(spacing: 0) {
                RigaDato("Garanzie", p.garanzie)
                RigaDato("Riscatto e liquidabilità", p.liquidabilita)
                RigaDato("Fiscalità", p.aliquotaFiscale.map { Formati.percentuale($0) + " sul rendimento" } ?? "")
                if p.area.proiettabile {
                    // Breve: dichiarato e calcolato; l'esempio e il periodo sono nell'aiuto e nella tessera
                    RigaDato("Costi come nel KID", cifre.kidBreve)
                        .help(cifre.kid)
                } else {
                    // Senza tessere in testa (protezione) il rischio resta nell'elenco
                    HStack(alignment: .center, spacing: 12) {
                        Text("Rischio (SRI)").font(Tema.Apple.AltreApp.secondario.fontLeggibile)
                            .foregroundColor(Tema.Apple.AltreApp.testoSecondario)
                            .frame(width: 150, alignment: .leading)
                        ScalaRischio(valore: p.sri)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bordoBasso(Colori.Analisi.tabellaRiga)
                }
                if !p.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    RigaDato("Note", p.note)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pannelloFonte(_ p: Prodotto) -> some View {
        PannelloAnalisi(titolo: "Fonte", nota: "Da dove vengono i dati") { EmptyView() } contenuto: {
            VStack(alignment: .leading, spacing: 8) {
                Text(p.fonte.isEmpty ? "Fonte non indicata" : p.fonte)
                    .font(Tema.Apple.AltreApp.corpo.fontLeggibile).foregroundColor(Tema.Apple.AltreApp.testo)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text(p.verificatoIl.map { "Verificata il \(Formati.dataEstesa.string(from: $0))" } ?? "Mai verificata")
                        .font(Tema.Apple.AltreApp.nota.fontLeggibile).foregroundColor(Tema.Apple.AltreApp.testoSecondario)
                    if p.daVerificare { Pillola(testo: "Da rileggere sul KID", tono: .attenzione) }
                }
                Button {
                    var x = p
                    x.verificatoIl = Calendar.current.startOfDay(for: Date())
                    stato.salvaProdotto(x)
                } label: {
                    Label("Segna verificata oggi", systemImage: "checkmark")
                }
                .buttonStyle(StileVetro(margine: EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)))
            }
        }
        .frame(minWidth: Misure.SchedaProdotto.fonteMinima, idealWidth: Misure.SchedaProdotto.fonte,
               maxWidth: Misure.SchedaProdotto.fonte, alignment: .leading)
    }

    // MARK: - Dettaglio

    /// Dove va l'etichetta del canale nella testata della scheda.
    enum PostoEtichetta { case completa, compatta, sotto }

    /// Barretta dell'area, nome, sottotitolo ed etichetta del canale.
    private func testata(_ p: Prodotto, etichetta: PostoEtichetta) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Capsule(style: .continuous).fill(Colori.Analisi.area(p.area)).frame(width: 8, height: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(p.nome)
                    .font(Tema.Apple.AltreApp.titoloGrande.fontLeggibile)
                    .tracking(Tema.Apple.AltreApp.titoloGrande.tracking)
                    .foregroundColor(Tema.Apple.AltreApp.testo)
                    .lineLimit(etichetta == .sotto ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: etichetta == .sotto)
                Text([p.area.nome, p.tipologia, p.emittente].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(Tema.Apple.AltreApp.secondario.fontLeggibile)
                    .foregroundColor(Tema.Apple.AltreApp.testoSecondario)
                    .lineLimit(etichetta == .sotto ? 2 : 1)
                if etichetta == .sotto {
                    EtichettaCanale(canale: p.canale, compatta: true)
                }
            }
            .layoutPriority(1)
            if etichetta != .sotto {
                Spacer(minLength: 8)
                EtichettaCanale(canale: p.canale, compatta: etichetta == .compatta)
            }
        }
    }

    /// Le tessere in testa alla scheda: costo annuo, costo d'ingresso, rendimento, rischio (SRI) e orizzonte.
    /// Le note restano brevi; il dettaglio (due parti della multiramo) è nell'aiuto al passaggio del puntatore.
    private func tessere(_ p: Prodotto, parametri: ParametriProiezione, dueParti: Bool, composizione: String) -> some View {
        let costoAnnuo = dueParti ? CifreDoc.percento(parametri.costoAnnuoEquivalente, decimali: 2)
            : (p.costoAnnuo.map { Formati.percentuale($0) } ?? "—")
        let rendimento = dueParti ? CifreDoc.percento(parametri.rendimentoEquivalente, decimali: 2)
            : (p.rendimentoAtteso.map { Formati.percentuale($0) } ?? "—")
        let orizzonte = p.periodoConsigliato.map { $0 == 1 ? "1 anno" : "\($0) anni" } ?? "—"
        return FasciaKPI {
            KPI(titolo: "Costo annuo", valore: costoAnnuo) {
                Text(dueParti ? "media delle due parti" : "sul capitale")
            }
            .help(dueParti ? "Pesato sulle due parti, senza bollo" : "All'anno sul capitale")
            KPI(titolo: "Costo d'ingresso", valore: p.costoIngresso.map { Formati.percentuale($0) } ?? "—") {
                Text("sui versamenti")
            }
            KPI(titolo: "Rendimento ipotizzato", valore: rendimento) {
                Text("non garantito")
            }
            .help(composizione.isEmpty ? "Dal KID, non garantito" : composizione)
            TesseraRischio(sri: p.sri)
            KPI(titolo: "Orizzonte", valore: orizzonte, ultimo: true) {
                Text(p.periodoConsigliato == nil ? "non indicato" : "consigliato dal KID")
            }
        }
    }

    /// Le cifre della scheda che non cambiano con la ricerca, i filtri o un'altra scheda aperta prima: la proiezione
    /// d'esempio, il peso dei costi, i costi come nel KID e le posizioni collegate.
    private struct CifreScheda {
        let parametri: ParametriProiezione
        let versato: Double
        let netto: Double
        let impatto: Double
        let composizione: String
        let kid: String
        let kidBreve: String
        let usi: [Posizione]
    }

    /// Le cifre della scheda una volta per dati dei calcoli (schede e posizioni), giorno e ora (i costi del KID guardano la
    /// data di oggi), non a ogni tasto nella ricerca: la scheda aperta si ridisegna con l'elenco.
    private func cifre(_ p: Prodotto) -> CifreScheda {
        stato.ricavato("prodotti-scheda|\(p.id)|\(DerivatiDati.ora())") { () -> CifreScheda in
            let parametri = p.parametriEsempio
            let esito = MotoreProiezione.calcola(parametri)
            return CifreScheda(parametri: parametri, versato: esito.versato, netto: esito.netto,
                               impatto: MotoreProiezione.impattoCosti(parametri),
                               composizione: MotoreMultiramo.rigaComposizione(p.proposta(per: "")),
                               kid: testoKID(p), kidBreve: testoKIDBreve(p), usi: stato.posizioniDelProdotto(p.id))
        }
    }

    private func dettaglio(_ p: Prodotto) -> some View {
        let c = cifre(p)
        let parametri = c.parametri
        // Multiramo a due parti: costo e rendimento pesati sulle due parti (dalla proiezione d'esempio)
        let dueParti = parametri.gestione != nil
        let composizione = c.composizione
        let usi = c.usi
        let cliente = stato.clienteAttivo?.nome ?? "il cliente"
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // L'etichetta del canale accanto al nome se c'è posto, poi compatta, poi sotto il titolo:
                // in una colonna stretta il nome non si legge mai una lettera per riga
                ViewThatFits(in: .horizontal) {
                    testata(p, etichetta: .completa)
                    testata(p, etichetta: .compatta)
                    testata(p, etichetta: .sotto)
                }
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                // In testa le cifre chiave a colpo d'occhio: costi, rendimento, rischio e orizzonte;
                // sotto, il peso dei costi su un esempio come grafico
                if p.area.proiettabile {
                    tessere(p, parametri: parametri, dueParti: dueParti, composizione: composizione)
                        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    PesoCostiProdotto(titolo: "Su 10.000 € in 10 anni", versato: c.versato, netto: c.netto,
                                      costi: c.impatto, coloreGuadagno: Colori.Analisi.area(p.area))
                        .inclinazione(massimo: Tema.Apple.AltreApp.inclinazioneGrande, raggio: Tema.Apple.AltreApp.raggioTile)
                        .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
                AvvisoNuovoKID(prodotto: p)
                // Condizioni e fonte affiancate se c'è posto, altrimenti una sotto l'altra (finestra non ingrandita)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Misure.SchedaProdotto.spazioAffiancate) {
                        pannelloCondizioni(p, cifre: c)
                        pannelloFonte(p)
                    }
                    .frame(idealWidth: Misure.SchedaProdotto.affiancate, maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: Misure.SchedaProdotto.spazioImpilate) {
                        pannelloCondizioni(p, cifre: c)
                        pannelloFonte(p)
                    }
                }
                .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                condizioni(p)
                    .entrataCascata(4, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                StoricoAggiornamentiProdotto(prodotto: p)
                PannelloAnalisi(titolo: "Dove è usata", nota: usi.isEmpty ? "Nessuna posizione o proposta collegata" : nil) { EmptyView() } contenuto: {
                    VStack(spacing: 0) {
                        ForEach(usi) { u in
                            Button { stato.apriPosizione(u) } label: {
                                HStack {
                                    Text(stato.cliente(u.clienteId)?.nome ?? "Cliente")
                                        .font(Tema.Apple.AltreApp.titoloVoce.fontLeggibile)
                                    EtichettaCanale(canale: u.canale, compatta: true)
                                    Text(u.stato == .proposta ? "Proposta · \((u.esito ?? .bozza).nome.lowercased())" : "In essere")
                                        .font(Tema.Apple.AltreApp.secondario.fontLeggibile)
                                        .foregroundColor(Tema.Apple.AltreApp.testoSecondario)
                                    Spacer()
                                    (Text("Apri ") + Text(Image(systemName: "chevron.right")))
                                        .font(Tema.Apple.AltreApp.collegamento.fontLeggibile)
                                        .foregroundColor(Tema.Apple.AltreApp.accento)
                                }
                                .foregroundColor(Tema.Apple.AltreApp.testo)
                                .padding(.vertical, 7)
                                .bordoBasso(Tema.Apple.AltreApp.separatore)
                            }
                            .buttonStyle(StileSemplice())
                        }
                    }
                }
                HStack(spacing: 8) {
                    Button { sulCliente = RichiestaProdottoCliente(prodottoId: p.id, stato: .proposta, clienteScelto: true) } label: {
                        Label("Metti su un cliente…", systemImage: "plus")
                    }
                    .buttonStyle(StileBlu())
                    .disabled(stato.solaLettura)
                    .help("Proposta o posizione in essere per \(cliente) o un altro cliente: scrivi solo importi e durata")
                    if p.area.proiettabile {
                        Button { stato.simula(p) } label: { Label("Simula", systemImage: "slider.horizontal.3") }
                            .buttonStyle(StileVetro())
                    }
                    Button { modulo = p } label: { Label("Modifica", systemImage: "pencil") }
                        .buttonStyle(StileVetro())
                    Button { daiDocumenti = RichiestaSchedaDocumenti(esistente: p) } label: {
                        Label("Aggiorna dai documenti…", systemImage: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(StileVetro())
                    .disabled(stato.solaLettura)
                    .help("Leggi il KID nuovo, il DIP aggiuntivo o le condizioni e aggiorna costi, scenari e penali della scheda")
                    Spacer()
                    Button { confermaEliminazione = true } label: {
                        Label("Elimina la scheda…", systemImage: "trash").foregroundColor(Tema.Apple.Colore.rosso)
                    }
                    .buttonStyle(StileVetro())
                }
                NotaMetodo(testo: "I costi della scheda entrano in proposte, simulazioni e confronti così come sono: tienili allineati al KID in vigore.")
                    .help("L'ISC di una forma pensionistica non è una commissione di gestione: inserisci i costi che il modello applica davvero.")
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 18, trailing: 16))
        }
        // Un'altra scheda: i blocchi rientrano a cascata
        .riavviaCascata(p.id)
    }
}

/// Modulo della scheda prodotto.
struct ModuloProdotto: View {
    @Environment(\.dismiss) var chiudi
    @State var bozza: Prodotto
    let nuovo: Bool
    let salva: (Prodotto) -> Void

    private static let numero = FloatingPointFormatStyle<Double>.number.locale(Formati.italiano)

    var body: some View {
        CorniceModulo(titolo: nuovo ? "Nuova scheda prodotto" : "Modifica la scheda") {
            VStack(alignment: .leading, spacing: 14) {
                CampoModulo(etichetta: "Nome del prodotto") { TextField("", text: $bozza.nome).textFieldStyle(.roundedBorder) }
                CampoModulo(etichetta: "Canale") {
                    SegmentatoPillola(selezione: $bozza.canale, valori: Canale.allCases, titolo: { $0.nomeBreve })
                        .frame(width: 240, alignment: .leading)
                }
                CampoModulo(etichetta: "Area") {
                    MenuTendina(selezione: $bozza.area,
                                opzioni: [AreaPosizione.investimento, .risparmio, .previdenza, .protezione].map { ($0, $0.nome) },
                                larghezza: 200)
                }
                CampoModulo(etichetta: "Compagnia o emittente") { TextField("", text: $bozza.emittente).textFieldStyle(.roundedBorder) }
                CampoModulo(etichetta: "Tipologia") { TextField("", text: $bozza.tipologia).textFieldStyle(.roundedBorder) }
                CampoModulo(etichetta: multiramo ? "Rendimento complessivo" : "Rendimento ipotizzato") {
                    percento($bozza.rendimentoAtteso, multiramo ? "% annuo lordo, delle due parti insieme" : "% annuo")
                }
                CampoModulo(etichetta: "Costo d'ingresso") { percento($bozza.costoIngresso, "% dei versamenti") }
                CampoModulo(etichetta: "Costo annuo") {
                    percento($bozza.costoAnnuo, multiramo ? "% all'anno: commissioni, senza il trattenuto" : "% all'anno")
                }
                CampoModulo(etichetta: "Costi nel KID (RIY)") {
                    percento($bozza.incidenzaCostiKID, "% l'anno al periodo raccomandato · Prisma lo confronta con il suo calcolo")
                }
                CampoModulo(etichetta: "Periodo raccomandato") {
                    CampoInteroFacoltativo(valore: $bozza.periodoRaccomandato, unita: notaPeriodo)
                }
                CampoModulo(etichetta: "Fiscalità") { percento($bozza.aliquotaFiscale, "% sul rendimento") }
                CampoModulo(etichetta: "Rischio (SRI)") {
                    HStack(spacing: Tema.Misura.Inserimento.spazioRiga) {
                        MenuTendina(selezione: $bozza.sri,
                                    opzioni: [(Int?.none, "Non indicato")] + (1...7).map { (Optional($0), "\($0)") },
                                    larghezza: Tema.Misura.Multiramo.tendinaSRI)
                        if multiramo {
                            Text("della combinazione, dal KID")
                                .font(Tipo.campoEtichetta).foregroundColor(Colori.Rubrica.secondario)
                        }
                    }
                }
                if multiramo {
                    composizione
                } else if gestioneSeparata {
                    garanziaGestione
                }
                CampoModulo(etichetta: "Garanzie") { TextField("", text: $bozza.garanzie).textFieldStyle(.roundedBorder) }
                CampoModulo(etichetta: "Riscatto e liquidabilità") { TextField("", text: $bozza.liquidabilita).textFieldStyle(.roundedBorder) }
                CampoModulo(etichetta: "Fonte (KID, versione)") {
                    TextField("Per esempio KID del 1/2026, pagina 2", text: $bozza.fonte).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Verificata il") {
                    CampoDataFacoltativa(data: $bozza.verificatoIl, predefinita: Date())
                }
                CampoModulo(etichetta: "Note") { TextField("", text: $bozza.note).textFieldStyle(.roundedBorder) }
            }
        } piede: {
            Spacer()
            Button("Annulla") { chiudi() }
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(nuovo ? "Aggiungi" : "Salva") {
                var p = bozza
                p.nome = p.nome.trimmingCharacters(in: .whitespacesAndNewlines)
                salva(p)
                chiudi()
            }
            .buttonStyle(StileBlu())
            .disabled(bozza.nome.trimmingCharacters(in: .whitespaces).isEmpty)
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: Misure.Analisi.modulo.width, height: Misure.Analisi.modulo.height)
        // Il modulo nel tema Apple, come l'app
        .altreAppApple()
    }

    // MARK: - Multiramo e gestione separata

    /// La scheda descrive una multiramo: solo Investimento e Risparmio, perché una scheda di previdenza dà
    /// posizioni con il regime della previdenza, mai multiramo.
    private var multiramo: Bool {
        Posizione.multiramo(tipologia: bozza.tipologia) && (bozza.area == .investimento || bozza.area == .risparmio)
    }

    /// La scheda descrive un Ramo I puro (come lo vedrà la proposta).
    private var gestioneSeparata: Bool { !multiramo && bozza.proposta(per: "").gestioneSeparata }

    /// Le due parti della multiramo, con gli stessi campi del modulo della posizione e i limiti della quota.
    private var composizione: some View {
        let m = Tema.Misura.Multiramo.self
        let limiti: ClosedRange<Double>? = {
            guard bozza.quotaGestioneMinima != nil || bozza.quotaGestioneMassima != nil else { return nil }
            let minima = min(max(bozza.quotaGestioneMinima ?? 0, 0), 100)
            let massima = min(max(bozza.quotaGestioneMassima ?? 100, 0), 100)
            return minima <= massima ? minima...massima : nil
        }()
        // L'accreditato della parte in gestione separata, come lo vedrà la proposta (con le condizioni)
        let accreditato = MotoreGestioneSeparata.calcolaParte(bozza.proposta(per: "")).map {
            "\(Formati.percentuale($0.accreditato)) l'anno su un lordo ipotizzato del \(Formati.percentuale($0.lordo)) (stima, prima delle imposte)"
        }
        return VStack(alignment: .leading, spacing: m.spazioRighe) {
            OcchielloSezione(titolo: "Composizione: gestione separata e fondi")
            if let c = bozza.condizioni, !c.componenti.isEmpty {
                Text("Le condizioni del contratto hanno già le parti (\(c.composizioneBreve)): i campi vuoti si prendono da lì.")
                    .font(Tema.Testo.Multiramo.nota)
                    .foregroundColor(Tema.Colore.Multiramo.nota)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SezioneComposizione(
                quotaGestione: $bozza.quotaGestioneSeparata,
                rendimentoGestione: $bozza.rendimentoGestione,
                trattenuto: $bozza.trattenuto,
                retrocessione: $bozza.retrocessione,
                minimoGarantito: $bozza.minimoGarantito,
                consolidamento: $bozza.consolidamento,
                titoliStatoGestione: $bozza.titoliStatoGestione,
                rendimentoFondi: $bozza.rendimentoFondi,
                costoFondi: $bozza.costoFondi,
                sriFondi: $bozza.sriFondi,
                volatilitaFondi: $bozza.volatilitaFondi,
                quotaAzionariaFondi: $bozza.quotaAzionariaFondi,
                titoliStatoFondi: $bozza.titoliStatoFondi,
                ribilanciamento: $bozza.ribilanciamento,
                conGestione: true,
                limiti: limiti,
                accreditato: accreditato)
            CampoModulo(etichetta: "Quota GS ammessa") {
                HStack(spacing: Tema.Misura.Inserimento.spazioRiga) {
                    Text("da").font(Tipo.campoEtichetta).foregroundColor(Colori.Rubrica.secondario)
                    CampoCifraFacoltativa(valore: $bozza.quotaGestioneMinima, unita: "%")
                    Text("a").font(Tipo.campoEtichetta).foregroundColor(Colori.Rubrica.secondario)
                    CampoCifraFacoltativa(valore: $bozza.quotaGestioneMassima, unita: "% · dalle condizioni, solo per avvisare")
                }
            }
        }
    }

    /// Ramo I puro: le condizioni della gestione separata che la proposta eredita.
    private var garanziaGestione: some View {
        VStack(alignment: .leading, spacing: Tema.Misura.Inserimento.spazioCampi) {
            OcchielloSezione(titolo: "Gestione separata")
            CampoModulo(etichetta: "Trattenuto") { percento($bozza.trattenuto, "punti l'anno sul rendimento") }
            CampoModulo(etichetta: "Retrocessione") { percento($bozza.retrocessione, "% del rendimento lordo · al posto del trattenuto") }
            CampoModulo(etichetta: "Minimo garantito") { percento($bozza.minimoGarantito, "% l'anno · 0 = garantito solo il capitale") }
            CampoModulo(etichetta: "Consolidamento") {
                MenuTendina(selezione: $bozza.consolidamento,
                            opzioni: [(Bool?.none, "Non indicato · si considera annuo"),
                                      (Optional(true), "Annuo: l'accreditato non si perde"),
                                      (Optional(false), "Solo a scadenza o al decesso")],
                            larghezza: Tema.Misura.Inserimento.tendinaConsolidamento)
            }
        }
    }

    private func percento(_ valore: Binding<Double?>, _ unita: String) -> some View {
        HStack(spacing: 6) {
            TextField("—", value: valore, format: Self.numero)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text(unita).font(Tipo.campoEtichetta).foregroundColor(Colori.Rubrica.secondario)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Il periodo raccomandato della scheda prevale su quello delle condizioni del contratto.
    private var notaPeriodo: String {
        if bozza.periodoRaccomandato == nil, let anni = bozza.condizioni?.periodoRaccomandato {
            return "anni, dal KID · se vuoto, \(anni) dalle condizioni del contratto"
        }
        return "anni, dal KID"
    }
}
