import SwiftUI

/// App Agenda (.os-app-agenda) nel tema Apple (Design/template-apple-specifica.md §4.4): la barra in testa (frecce,
/// periodo, riepilogo delle cose da fare, viste a pillola, clienti, «Attività» e «Nuovo impegno»), la striscia dei
/// riesami del mese e quattro viste. Mese (predefinita, approvata): la griglia del mese con le attività e, a destra,
/// la giornata scelta. Settimana: la barra laterale con il mese a puntini, la settimana a pillola e la giornata con
/// le ore, gli impegni e la linea dell'ora (AgendaApple.swift). Giorno: la giornata con le ore e la colonna del
/// giorno con il dettaglio di sempre. Occasioni: le occasioni di 12 mesi (AgendaOccasioni.swift).
/// Sul Mac Attività è accorpata qui: ogni attività sta nel giorno della sua scadenza («Da fare»), quelle rimaste
/// indietro nella giornata di oggi. Nella giornata compaiono anche le posizioni in scadenza: ogni scadenza è
/// l'occasione per rivedere la posizione del cliente. Toccando un impegno nella giornata si apre la sua traccia
/// (TracciaImpegnoApple.swift). La griglia del mese e le sue celle sono in AgendaMese.swift.
struct AppAgenda: View {
    @Environment(StatoShell.self) var stato
    @State var modulo: Appuntamento?
    @State var moduloAttivita: Attivita?
    /// La striscia «Riesami del mese» ridotta a una riga (dura quanto la sessione, non va nell'archivio).
    @State var riesamiRidotti = false
    /// La riga in testa al modulo dopo «Pianifica» (nil per le altre aperture del modulo).
    @State var spiegazioneModulo: String?
    /// I conti delle schede della striscia, cliente per cliente (RiesamiAgenda.swift): dura quanto la finestra aperta.
    @State private var memoriaRiesami = MemoriaStrisciaRiesami()

    private var cal: Calendar { CalendarioAgenda.cal }
    private var giorno: Date { stato.giornoAgenda }

    /// Cosa mostra il dettaglio: un'occasione, un appuntamento o un'attività del giorno.
    private enum Scelta {
        case occasione(Occasione)
        case appuntamento(Appuntamento)
        case attivita(Attivita)
    }

    var body: some View {
        // La traccia dell'impegno nasce dagli impegni della giornata, sopra tutta l'Agenda (TracciaImpegnoApple)
        PresentatoreImpegniApple(stato: stato) {
            GeometryReader { geo in
                // I riesami del mese mostrato: in un mese passato la striscia non compare, e nemmeno nella vista
                // «Occasioni», che guarda 12 mesi mentre la striscia ne guarda uno
                let riesami: RiesamiDelMese? = stato.vistaAgenda == .occasioni ? nil : stato.riesamiDelMese(giorno)
                let mesePassato = giorno < (cal.dateInterval(of: .month, for: Date())?.start ?? giorno)
                let spazio = Tema.Apple.Agenda.Disposizione.spazioRighe
                VStack(spacing: 0) {
                    barra
                    if let riesami, !riesami.vuota && !mesePassato {
                        striscia(riesami, compatta: geo.size.height < Misure.RiesamiAgenda.sogliaAltezzaPiena)
                            .padding(.top, spazio)
                    }
                    contenuto
                        .padding(.top, spazio)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .sheet(item: $modulo) { a in
            ModuloAppuntamento(
                bozza: a,
                nuovo: !stato.appuntamenti.contains { $0.id == a.id },
                salva: { stato.salvaAppuntamento($0) },
                elimina: { stato.eliminaAppuntamento(a.id) },
                spiegazione: spiegazioneModulo
            )
            .environment(stato)
        }
        .sheet(item: $moduloAttivita) { t in
            // L'attività salvata si ritrova nel giorno della sua scadenza
            ModuloAttivita(bozza: t, nuova: !stato.attivita.contains { $0.id == t.id },
                           salva: { stato.salvaAttivitaInAgenda($0) }, elimina: { stato.eliminaAttivita(t.id) })
                .environment(stato)
        }
        #if os(macOS)
        // Sul Mac «Nuova attività» arriva qui: Attività è accorpata nell'Agenda (su iPad la apre Attività)
        .onAppear { controllaRichiesta(stato.richiestaNuovaAttivita) }
        .onChange(of: stato.richiestaNuovaAttivita) { controllaRichiesta($0) }
        #endif
    }

    private func controllaRichiesta(_ richiesta: Bool) {
        guard richiesta else { return }
        stato.richiestaNuovaAttivita = false
        nuovaAttivita()
    }

    private func nuovoAppuntamento() {
        spiegazioneModulo = nil
        modulo = Appuntamento.nuovo(clienteId: stato.filtroClienteAgenda ?? stato.clienteAttivoId, giorno: giorno)
    }

    /// Una nuova cosa da fare, con la scadenza nel giorno scelto.
    private func nuovaAttivita() {
        moduloAttivita = Attivita.nuova(clienteId: stato.filtroClienteAgenda ?? stato.clienteAttivoId, scadenza: giorno)
    }

    // MARK: - Riesami del mese

    private func striscia(_ r: RiesamiDelMese, compatta: Bool) -> some View {
        let oggi = Date()
        let massimo = Misure.RiesamiAgenda.massimoSchede
        // Le schede si calcolano solo per i clienti mostrati (il riesame di ognuno è in memoria per un'ora)
        let voci = r.daFissare.prefix(massimo).map { voceRiesame($0, oggi: oggi) }
        return StrisciaRiesami(
            titoloMese: Formati.meseAnno.string(from: giorno).capitalized,
            voci: voci,
            altri: max(0, r.daFissare.count - massimo),
            fissati: r.fissati.count,
            compatta: compatta,
            solaLettura: stato.solaLettura,
            ridotta: $riesamiRidotti,
            prepara: { id in
                stato.clienteAttivoId = id
                stato.apriProspetto(.riesame)
            },
            pianifica: { id in pianifica(id) },
            apriPortafoglio: {
                stato.portafoglio = true
                stato.apri(.posizioni)
            }
        )
    }

    /// La scheda di un riesame da fissare: stato, punti dell'ordine del giorno e canali delle posizioni.
    private func voceRiesame(_ d: RiesameDovuto, oggi: Date) -> VoceRiesameAgenda {
        let testo: String
        if let dal = d.dovutoDal {
            // L'anno solo se non è quello di oggi
            let stessoAnno = cal.component(.year, from: dal) == cal.component(.year, from: oggi)
            let data = stessoAnno ? Formati.giornoMese.string(from: dal) : Formati.dataEstesa.string(from: dal)
            testo = d.scaduto(oggi) ? "Scaduto dal \(data)" : "Dovuto dal \(data)"
        } else {
            testo = "Mai incontrato in Prisma"
        }
        // Dalla memoria della vista: dopo una modifica si rifà solo il riesame del cliente toccato, non tutta la striscia
        let conti = stato.contiStrisciaRiesami(d.id, memoria: memoriaRiesami)
        return VoceRiesameAgenda(
            id: d.id,
            nome: d.cliente.nome,
            iniziali: d.cliente.iniziali,
            tinta: d.cliente.tinta.colori,
            stato: testo,
            scaduto: d.scaduto(oggi),
            punti: conti.punti,
            alta: conti.alta,
            canali: MotorePianificazione.canali(stato.posizioniCliente(d.id))
        )
    }

    /// Il riesame nel primo spazio libero negli orari di lavoro, da completare nel modulo.
    private func pianifica(_ id: String) {
        guard let p = stato.pianificaRiesame(id, mese: giorno) else { return }
        spiegazioneModulo = p.spiegazione(orari: stato.dati.impostazioni.orari)
        modulo = p.appuntamento
    }

    // MARK: - Barra in testa (tema Apple)

    private func maiuscola(_ s: String) -> String { TestiAgendaApple.maiuscola(s) }

    private var periodo: String {
        switch stato.vistaAgenda {
        case .mese:
            return Formati.meseAnno.string(from: giorno).capitalized
        case .occasioni:
            // I 12 mesi della vista: dal primo del mese mostrato all'undicesimo mese dopo
            let inizio = cal.dateInterval(of: .month, for: giorno)?.start ?? giorno
            let fine = cal.date(byAdding: .month, value: RegoleOccasioni.mesiElenco - 1, to: inizio) ?? inizio
            return "\(Formati.meseAnno.string(from: inizio)) — \(Formati.meseAnno.string(from: fine))".capitalized
        case .settimana:
            let giorni = CalendarioAgenda.giorni(settimanaDi: giorno)
            guard let primo = giorni.first, let ultimo = giorni.last else { return "" }
            return "\(Formati.giornoMese.string(from: primo)) — \(Formati.dataEstesa.string(from: ultimo))"
        case .giorno:
            return maiuscola(Formati.dataLunga.string(from: giorno))
        }
    }

    /// La barra in testa, sempre su una riga: frecce e «Oggi», il periodo mostrato, il riepilogo delle cose da fare,
    /// le viste a pillola, i clienti, «Attività» e «Nuovo impegno» (il primario). Se non c'è posto si toglie prima
    /// il riepilogo, poi «Attività» e «Nuovo impegno» diventano icone (con il suggerimento).
    private var barra: some View {
        let r = stato.riepilogoAttivitaAgenda()
        let riepilogo = RiepilogoAttivitaAgenda(daSvolgere: r.daSvolgere, entroSette: r.entroSette, scadute: r.scadute)
        // Le voci del menu dei clienti una volta sola per le quattro versioni della riga (con 200 clienti sono 200 voci)
        let clienti: [(String?, String)] = [(String?.none, "Tutti i clienti")] + stato.clienti.map { (Optional($0.id), $0.nome) }
        return ViewThatFits(in: .horizontal) {
            rigaBarra(riepilogo, clienti: clienti, compatta: false)
            rigaBarra(EmptyView(), clienti: clienti, compatta: false)
            rigaBarra(EmptyView(), clienti: clienti, compatta: true)
            // Finestra molto stretta: la riga compatta scorre di lato, mai tagliata ai due bordi
            ScrollView(.horizontal, showsIndicators: false) {
                rigaBarra(EmptyView(), clienti: clienti, compatta: true)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: Tema.Apple.Agenda.Barra.altezza)
    }

    private var aiutiFrecce: (prima: String, dopo: String) {
        switch stato.vistaAgenda {
        case .settimana: return ("Settimana precedente", "Settimana successiva")
        case .giorno: return ("Giorno precedente", "Giorno successivo")
        case .mese, .occasioni: return ("Mese precedente", "Mese successivo")
        }
    }

    private func rigaBarra<Riepilogo: View>(_ riepilogo: Riepilogo, clienti: [(String?, String)], compatta: Bool) -> some View {
        let b = Tema.Apple.Agenda.Barra.self
        let viste: [(VistaAgenda, String)] = [(.mese, "Mese"), (.settimana, "Settimana"), (.giorno, "Giorno"), (.occasioni, "Occasioni")]
        let aiuti = aiutiFrecce
        return HStack(spacing: b.spazio) {
            HStack(spacing: b.spazioFrecce) {
                Button { sposta(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.apple)
                    .help(aiuti.prima)
                    .accessibilityLabel(aiuti.prima)
                Button {
                    stato.giornoAgenda = cal.startOfDay(for: Date())
                    azzeraScelta()
                } label: { Text("Oggi") }
                    .buttonStyle(.apple)
                    .help("Torna alla data di oggi")
                Button { sposta(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.apple)
                    .help(aiuti.dopo)
                    .accessibilityLabel(aiuti.dopo)
            }
            .fixedSize()
            Text(periodo)
                .carattereApple(b.periodo)
                .foregroundColor(b.colorePeriodo)
                .lineLimit(1)
                .fixedSize()
                .padding(.leading, b.spazioPeriodo - b.spazio)
            riepilogo
                .padding(.leading, b.spazioPeriodo - b.spazio)
            Spacer(minLength: 0)
            SegmentatoPillola(selezione: Bindable(stato).vistaAgenda, voci: viste)
                .fixedSize()
            MenuTendina(selezione: Bindable(stato).filtroClienteAgenda, opzioni: clienti,
                        larghezza: compatta ? b.menuClientiCompatto : b.menuClienti)
            if compatta {
                Button { nuovaAttivita() } label: { Image(systemName: "checklist") }
                    .buttonStyle(.apple)
                    .fixedSize()
                    .help("Nuova attività")
                    .accessibilityLabel("Nuova attività")
                Button { nuovoAppuntamento() } label: { Image(systemName: "plus") }
                    .buttonStyle(.applePrimario)
                    .fixedSize()
                    .help("Nuovo impegno")
                    .accessibilityLabel("Nuovo impegno")
            } else {
                Button { nuovaAttivita() } label: { Label("Attività", systemImage: "plus") }
                    .buttonStyle(.apple)
                    .fixedSize()
                    .help("Nuova attività, con la scadenza nel giorno scelto")
                Button { nuovoAppuntamento() } label: { Label("Nuovo impegno", systemImage: "plus") }
                    .buttonStyle(.applePrimario)
                    .fixedSize()
                    .help("Nuovo appuntamento nel giorno scelto")
            }
        }
    }

    private func sposta(_ verso: Int) {
        // Il mese anche per la vista «Occasioni»
        let componente: Calendar.Component
        switch stato.vistaAgenda {
        case .settimana: componente = .weekOfYear
        case .giorno: componente = .day
        case .mese, .occasioni: componente = .month
        }
        stato.giornoAgenda = cal.date(byAdding: componente, value: verso, to: giorno) ?? giorno
        azzeraScelta()
    }

    // MARK: - Contenuto: le quattro viste

    @ViewBuilder private var contenuto: some View {
        switch stato.vistaAgenda {
        case .mese: vistaMese
        case .settimana: vistaSettimana
        case .giorno: vistaGiorno
        case .occasioni: vistaOccasioni
        }
    }

    /// Il mese (approvato): la griglia che riempie lo spazio a sinistra, a destra la colonna del giorno scelto.
    private var vistaMese: some View {
        let settimane = CalendarioAgenda.settimane(meseDi: giorno)
        // Appuntamenti, attività, scadenze e occasioni dei giorni visibili, raggruppati una volta sola
        let indice = indiceGiorni(settimane.flatMap { $0 })
        return GeometryReader { geo in
            let larghezza = Misure.AgendaImpaginazione.dettaglio(geo.size.width)
            HStack(spacing: 0) {
                MeseAgenda(settimane: settimane, giorno: giorno, indice: indice, strato: strato,
                           canale: { stato.canaleAppuntamento($0) }, seleziona: { seleziona($0) })
                    .padding(Misure.AgendaImpaginazione.calendario)
                    .frame(width: max(0, geo.size.width - larghezza))
                ParteAgenda { colonnaMese(indice) }
                    .frame(width: larghezza)
            }
        }
        .cardAgendaApple()
    }

    /// La settimana del template: a sinistra il mese con i puntini e le cifre della settimana, a destra la
    /// settimana a pillola, la data e la giornata con gli impegni e la linea dell'ora.
    private var vistaSettimana: some View {
        let settimane = CalendarioAgenda.settimane(meseDi: giorno)
        let indice = indiceGiorni(settimane.flatMap { $0 })
        let s = Tema.Apple.Agenda.Settimana.self
        return HStack(alignment: .top, spacing: Tema.Apple.Agenda.Disposizione.spazio) {
            BarraLateraleAgendaApple(giorno: giorno, settimane: settimane, indice: indice, strato: strato,
                                     seleziona: { seleziona($0) })
            VStack(alignment: .leading, spacing: 0) {
                SegmentatoPillola(selezione: giornoScelto, voci: vociSettimana, larghezzaPiena: true)
                    .entrataCascata(0)
                titoloGiornata(indice)
                    .padding(.top, s.titoloSopra)
                    .padding(.bottom, s.titoloSotto)
                    .entrataCascata(1)
                giornata(indice)
                    .entrataCascata(2, sfocatura: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// Il giorno: la giornata con le ore a sinistra, a destra la colonna del giorno (appuntamenti, cose da fare,
    /// scadenze, occasioni e il dettaglio di sempre della riga scelta).
    private var vistaGiorno: some View {
        // Il giorno guarda la sua settimana: la nota della colonna conta la settimana
        let indice = indiceGiorni(CalendarioAgenda.giorni(settimanaDi: giorno))
        let s = Tema.Apple.Agenda.Settimana.self
        return GeometryReader { geo in
            let larghezza = Misure.AgendaImpaginazione.dettaglio(geo.size.width)
            HStack(alignment: .top, spacing: Tema.Apple.Agenda.Disposizione.spazio) {
                VStack(alignment: .leading, spacing: 0) {
                    titoloGiornata(indice)
                        .padding(.bottom, s.titoloSotto)
                        .entrataCascata(0)
                    giornata(indice)
                        .entrataCascata(1, sfocatura: false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                ParteAgenda { colonnaMese(indice, fondo: false) }
                    .frame(width: larghezza)
                    .cardAgendaApple()
                    .entrataCascata(2, sfocatura: false)
            }
        }
    }

    /// Le occasioni di 12 mesi, con il dettaglio dell'occasione scelta a destra.
    private var vistaOccasioni: some View {
        let elenco = stato.elencoOccasioniAgenda
        return GeometryReader { geo in
            let larghezza = Misure.AgendaImpaginazione.dettaglio(geo.size.width)
            HStack(spacing: 0) {
                ElencoOccasioniAgenda(elenco: elenco)
                    .frame(width: max(0, geo.size.width - larghezza))
                ParteAgenda { dettaglio(GiorniAgenda(), elenco: elenco) }
                    .frame(width: larghezza)
            }
        }
        .cardAgendaApple()
    }

    /// La settimana a pillola: il giorno mostrato tra i sette della sua settimana.
    private var giornoScelto: Binding<Date> {
        let giorni = CalendarioAgenda.giorni(settimanaDi: giorno)
        let attuale = giorno
        return Binding(
            get: { giorni.first { CalendarioAgenda.cal.isDate($0, inSameDayAs: attuale) } ?? attuale },
            set: { nuovo in seleziona(nuovo) }
        )
    }

    private var vociSettimana: [(Date, String)] {
        CalendarioAgenda.giorni(settimanaDi: giorno).map { ($0, TestiAgendaApple.vocePillola($0)) }
    }

    private func titoloGiornata(_ indice: GiorniAgenda) -> some View {
        let indietro = cal.isDateInToday(giorno) ? stato.attivitaRimasteIndietro().count : 0
        return TitoloGiornataApple(giorno: giorno, impegni: indice.appuntamenti(giorno).count,
                                   daFare: indice.daFare(giorno).count + indietro)
    }

    private func giornata(_ indice: GiorniAgenda) -> some View {
        GiornataImpegniApple(giorno: giorno, eventi: indice.appuntamenti(giorno),
                             voci: stato.vociFasciaAgenda(giorno, indice: indice, strato: strato),
                             sceglie: { scegliVoce($0) })
    }

    /// Una voce della fascia: l'attività e l'occasione si aprono nella colonna del giorno (vista Giorno),
    /// la scadenza apre la posizione in Posizioni.
    private func scegliVoce(_ v: VoceFasciaApple) {
        switch v.tipo {
        case .attivita(let id):
            stato.scegliAttivitaInAgenda(id)
            stato.vistaAgenda = .giorno
        case .scadenza(let p):
            stato.apriPosizione(p)
        case .occasione(let o):
            stato.occasioneSelezionata = o
            stato.appuntamentoSelezionato = nil
            stato.attivitaSelezionata = nil
            stato.vistaAgenda = .giorno
        }
    }

    // MARK: - Settimana e mese

    /// Il dettaglio torna libero: la colonna del mese mostra la giornata.
    private func azzeraScelta() {
        stato.appuntamentoSelezionato = nil
        stato.occasioneSelezionata = nil
        stato.attivitaSelezionata = nil
    }

    private func seleziona(_ g: Date) {
        stato.giornoAgenda = cal.startOfDay(for: g)
        azzeraScelta()
    }

    /// Lo strato delle occasioni nella settimana e nel mese (Impostazioni › Occasioni). Letto senza iscrivere la vista a
    /// tutte le impostazioni (aspetto, sfondo…): lo strato entra nei calcoli, quindi cambiandolo cambia `versioneCalcoli`,
    /// che l'Agenda segue già (riepilogo delle attività, riesami, giorni).
    private var strato: Bool { stato.dati.impostazioniDeiCalcoli.occasioni.inAgenda }

    /// I giorni mostrati raggruppati (`giorniAgenda`), dalla cache comune dei dati ricavati: con la cache piena il body
    /// non rilegge le impostazioni (la chiave di `giorniAgenda` legge lo strato da `dati.impostazioni`), così cambiare
    /// l'aspetto o un'impostazione che non tocca i calcoli non rifà tutta l'Agenda. Lo strato entra nei calcoli: se cambia,
    /// la cache si svuota con `versioneCalcoli`. Nella chiave il filtro cliente, che non è un dato dei calcoli.
    private func indiceGiorni(_ giorni: [Date]) -> GiorniAgenda {
        guard let primo = giorni.min(), let ultimo = giorni.max() else { return GiorniAgenda() }
        let chiave = "agenda-giorni|\(primo.timeIntervalSinceReferenceDate)|\(ultimo.timeIntervalSinceReferenceDate)|"
            + (stato.filtroClienteAgenda ?? "-")
        return stato.ricavato(chiave) { stato.giorniAgenda(giorni) }
    }

    /// La colonna destra del mese: la giornata scelta oppure, scelta una riga, il suo dettaglio (con il ritorno).
    /// `fondo`: il fondo e il filo della colonna (nella vista Giorno la colonna è una card a sé).
    private func colonnaMese(_ indice: GiorniAgenda, fondo: Bool = true) -> some View {
        Group {
            if let s = scelta(indice, elenco: [], ripiego: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Button { azzeraScelta() } label: {
                        Label(maiuscola(Formati.dataLunga.string(from: giorno)), systemImage: "chevron.left")
                    }
                    .buttonStyle(StileCollegamento())
                    .fixedSize()
                    .help("Torna alla giornata")
                    .padding(Misure.AgendaMese.ritorno)
                    vistaScelta(s)
                        .padding(Misure.AgendaMese.margineDettaglio)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                paginaGiorno(indice, targhetta: true, colonna: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(fondo ? Colori.Agenda.dettaglioFondo : Color.clear)
        .overlay(alignment: .leading) {
            if fondo {
                Rectangle().fill(Colori.Agenda.dettaglioBordo).frame(width: Tema.Misura.filo)
            }
        }
    }

    // MARK: - Pagina della giornata

    /// La giornata: appuntamenti, rimaste indietro (solo oggi), da fare, in scadenza, occasioni.
    /// `targhetta`: in testa la tessera della data (mese e giorno). `colonna`: nella colonna del mese, stretta,
    /// senza ripiego sul primo appuntamento e senza la nota della settimana.
    private func paginaGiorno(_ indice: GiorniAgenda, targhetta: Bool = false, colonna: Bool = false) -> some View {
        let eventi = indice.appuntamenti(giorno)
        let delGiorno = indice.attivita(giorno)
        let indietro = cal.isDateInToday(giorno) ? stato.attivitaRimasteIndietro() : []
        let scadenze = indice.scadenze(giorno)
        let occasioni = strato ? indice.occasioni(giorno) : []
        let mostrata = scelta(indice, elenco: [], ripiego: !colonna)
        let occasioneScelta = stato.occasioneSelezionata?.id
        let daFare = delGiorno.filter { !$0.completata }.count + indietro.count
        return VStack(spacing: 0) {
            if targhetta {
                testaGiorno(eventi.count, daFare: daFare, scadenze: scadenze.count)
            } else {
                rigaTesta(eventi.count, daFare: daFare)
            }

            ScrollView {
                // Pigro: con molti clienti una giornata ha decine di appuntamenti, attività e scadenze
                LazyVStack(spacing: 0) {
                    if !eventi.isEmpty {
                        occhiello("APPUNTAMENTI", Colori.Agenda.occhielloAppuntamenti)
                        ForEach(eventi) { e in
                            RigaEventoAgenda(
                                evento: e, cliente: stato.cliente(e.clienteId)?.nome ?? "Cliente",
                                canale: stato.canaleAppuntamento(e),
                                selezionato: idAppuntamento(mostrata) == e.id
                            ) {
                                stato.appuntamentoSelezionato = e.id
                                stato.occasioneSelezionata = nil
                                stato.attivitaSelezionata = nil
                            }
                        }
                    }
                    if !indietro.isEmpty {
                        occhiello("RIMASTE INDIETRO", Colori.Agenda.occhielloIndietro)
                        ForEach(indietro) { t in rigaAttivita(t, mostrata: mostrata, compatta: colonna) }
                    }
                    if !delGiorno.isEmpty {
                        occhiello("DA FARE", Colori.Agenda.occhielloDaFare)
                        ForEach(delGiorno) { t in rigaAttivita(t, mostrata: mostrata, compatta: colonna) }
                    }
                    if !scadenze.isEmpty {
                        occhiello("IN SCADENZA", Colori.Agenda.scadenzaTesto)
                        ForEach(scadenze) { p in
                            RigaScadenzaAgenda(posizione: p, cliente: stato.cliente(p.clienteId)?.nome ?? "Cliente") {
                                stato.apriPosizione(p)
                            }
                        }
                    }
                    if !occasioni.isEmpty {
                        Text("OCCASIONI")
                            .font(Tipo.paginaOcchiello)
                            .tracking(Misure.Occasioni.tracciaOcchiello)
                            .foregroundColor(Colori.Agenda.occasioneOcchiello)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Misure.Occasioni.occhiello)
                        ForEach(occasioni) { o in
                            RigaOccasioneAgenda(occasione: o, cliente: stato.cliente(o.clienteId)?.nome ?? "Cliente",
                                                selezionata: o.id == occasioneScelta) {
                                stato.occasioneSelezionata = o
                                stato.appuntamentoSelezionato = nil
                            }
                        }
                    }
                    if eventi.isEmpty && indietro.isEmpty && delGiorno.isEmpty && scadenze.isEmpty && occasioni.isEmpty {
                        vuoto
                    }
                }
            }
            .bordoAlto(Colori.Agenda.rigaBordo)

            if !colonna {
                notaSettimana(indice)
            }
        }
    }

    private func occhiello(_ testo: String, _ colore: Color) -> some View {
        Text(testo)
            .font(Tipo.paginaOcchiello)
            .tracking(Misure.AgendaMese.tracciaOcchiello)
            .foregroundColor(colore)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Misure.AgendaMese.occhiello)
    }

    /// Una cosa da fare: spunta, titolo, cliente, scadenza e priorità (le righe di Attività).
    private func rigaAttivita(_ t: Attivita, mostrata: Scelta?, compatta: Bool) -> some View {
        RigaRegistroAttivita(
            attivita: t,
            cliente: stato.cliente(t.clienteId)?.nome ?? "Cliente",
            daAppuntamento: t.appuntamentoId != nil,
            selezionata: idAttivita(mostrata) == t.id,
            compatta: compatta,
            spunta: { stato.alternaCompletata(t.id) },
            seleziona: { stato.scegliAttivitaInAgenda(t.id) }
        )
    }

    /// «2 appuntamenti · 1 da fare · 1 scadenza», o «Giornata libera».
    private func riassunto(_ eventi: Int, daFare: Int, scadenze: Int) -> String {
        var parti: [String] = []
        if eventi > 0 { parti.append("\(eventi) \(eventi == 1 ? "appuntamento" : "appuntamenti")") }
        if daFare > 0 { parti.append("\(daFare) da fare") }
        if scadenze > 0 { parti.append("\(scadenze) \(scadenze == 1 ? "scadenza" : "scadenze")") }
        return parti.isEmpty ? "Giornata libera" : parti.joined(separator: " · ")
    }

    /// La testa della giornata nella settimana: giorno, data e conteggi su una riga.
    private func rigaTesta(_ eventi: Int, daFare: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Formati.giornoSettimana.string(from: giorno).uppercased())
                .font(Tipo.paginaOcchiello)
                .tracking(0.8)
                .foregroundColor(Colori.Agenda.paginaOcchiello)
            Text(Formati.giornoMese.string(from: giorno))
                .font(Tipo.paginaTitolo)
                .foregroundColor(Colori.Agenda.paginaTitolo)
            Spacer(minLength: 0)
            Text(riassunto(eventi, daFare: daFare, scadenze: 0))
                .font(Tipo.paginaNota)
                .foregroundColor(Colori.Agenda.paginaNota)
                .lineLimit(1)
        }
        .padding(EdgeInsets(top: 10, leading: 16, bottom: 9, trailing: 16))
    }

    /// La testa della giornata nel mese e nel giorno: la tessera della data, il giorno e i conteggi.
    private func testaGiorno(_ eventi: Int, daFare: Int, scadenze: Int) -> some View {
        let m = Misure.AgendaMese.self
        return HStack(alignment: .center, spacing: m.spazioTesta) {
            TarghettaData(giorno: giorno)
            VStack(alignment: .leading, spacing: m.spazioTestaRighe) {
                Text(cal.isDateInToday(giorno) ? "OGGI" : Formati.giornoSettimana.string(from: giorno).uppercased())
                    .font(Tipo.paginaOcchiello)
                    .tracking(m.tracciaOcchiello)
                    .foregroundColor(Colori.Agenda.paginaOcchiello)
                Text(Formati.dataEstesa.string(from: giorno))
                    .font(Tipo.testaGiornoTitolo)
                    .foregroundColor(Colori.Agenda.testaGiornoTitolo)
                    .lineLimit(1)
                Text(riassunto(eventi, daFare: daFare, scadenze: scadenze))
                    .font(Tipo.testaGiornoNota)
                    .foregroundColor(Colori.Agenda.testaGiornoNota)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(m.testaGiorno)
    }

    private var vuoto: some View {
        VStack(spacing: 6) {
            Text(Formati.giorno.string(from: giorno))
                .font(Tipo.vuotoData)
                .foregroundColor(Colori.Agenda.vuotoData)
            Text("Una pagina ancora libera.")
                .font(Tipo.vuotoTitolo)
                .foregroundColor(Colori.Agenda.vuotoTitolo)
            Text("Niente in programma \(stato.filtroClienteAgenda == nil ? "" : "per questo cliente ")in questa giornata.")
                .font(Tipo.vuotoTesto)
                .foregroundColor(Colori.Agenda.vuotoTesto)
                .multilineTextAlignment(.center)
            // Il blu resta «Appuntamento» nella barra: qui l'azione consigliata in vetro dell'accento
            HStack(spacing: Misure.AgendaMese.spazioPulsantiVuoto) {
                Button { nuovoAppuntamento() } label: { Label("Incontro", systemImage: "plus") }
                    .buttonStyle(StileVetro(accento: true))
                    .fixedSize()
                Button { nuovaAttivita() } label: { Label("Attività", systemImage: "plus") }
                    .buttonStyle(StileVetro())
                    .fixedSize()
            }
            .padding(.top, 6)
        }
        .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
        .frame(maxWidth: .infinity)
    }

    private func notaSettimana(_ indice: GiorniAgenda) -> some View {
        let giorni = CalendarioAgenda.giorni(settimanaDi: giorno)
        let eventi = giorni.flatMap { indice.appuntamenti($0) }
        let daSvolgere = eventi.filter { $0.stato != .concluso }
        let minuti = daSvolgere.reduce(0) { $0 + $1.durataMinuti }
        let scadenze = giorni.reduce(0) { $0 + indice.scadenze($1).count }
        let occasioni = strato ? giorni.reduce(0, { $0 + indice.occasioni($1).count }) : 0
        // Il periodo dei conteggi: la settimana del giorno scelto, anche nella vista del giorno
        let corrente = giorni.contains { cal.isDateInToday($0) }
        let periodo = corrente ? "QUESTA SETTIMANA"
            : "SETTIMANA DEL \(giorni.first.map { Formati.giornoMeseBreve.string(from: $0) } ?? "")".uppercased()
        // Se la riga non ci sta, prima si toglie il tempo riservato: il periodo resta sempre intero
        return ViewThatFits(in: .horizontal) {
            rigaSettimana(periodo, daSvolgere: daSvolgere.count, riservati: CalendarioAgenda.durata(minuti),
                          scadenze: scadenze, occasioni: occasioni)
            rigaSettimana(periodo, daSvolgere: daSvolgere.count, riservati: nil, scadenze: scadenze, occasioni: occasioni)
        }
        .font(Tipo.notaSettimana)
        .foregroundColor(Colori.Agenda.notaSettimana)
        .lineLimit(1)
        .padding(EdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15))
        .bordoAlto(Colori.Agenda.notaSettimanaBordo)
    }

    private func rigaSettimana(_ periodo: String, daSvolgere: Int, riservati: String?, scadenze: Int, occasioni: Int) -> some View {
        HStack(spacing: 6) {
            Text(periodo)
                .font(Tipo.paginaOcchiello)
                .tracking(1.2)
                .fixedSize()
                .layoutPriority(1)
                .padding(.trailing, 5)
            Text("\(daSvolgere) da svolgere").font(Tipo.notaSettimanaForte)
            if let riservati {
                Text("·")
                Text("\(riservati) riservati").font(Tipo.notaSettimanaForte)
            }
            if scadenze > 0 {
                Text("·")
                Text("\(scadenze) \(scadenze == 1 ? "scadenza" : "scadenze")").font(Tipo.notaSettimanaForte)
            }
            if occasioni > 0 {
                Text("·")
                Text("\(occasioni) \(occasioni == 1 ? "occasione" : "occasioni")").font(Tipo.notaSettimanaForte)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Dettaglio

    /// Cosa mostra il dettaglio: l'occasione scelta, poi l'appuntamento scelto, poi l'attività scelta; con
    /// `ripiego` (settimana e giorno) il primo appuntamento del giorno, altrimenti nulla (il mese mostra la giornata).
    private func scelta(_ indice: GiorniAgenda, elenco: [Occasione], ripiego: Bool) -> Scelta? {
        if let o = occasioneMostrata(indice, elenco: elenco) { return .occasione(o) }
        guard stato.vistaAgenda != .occasioni else { return nil }
        let eventi = indice.appuntamenti(giorno)
        if let id = stato.appuntamentoSelezionato, let e = eventi.first(where: { $0.id == id }) { return .appuntamento(e) }
        if let t = attivitaMostrata(indice) { return .attivita(t) }
        if ripiego, let e = eventi.first { return .appuntamento(e) }
        return nil
    }

    /// L'attività scelta, se è nella giornata mostrata (o tra le rimaste indietro, se il giorno è oggi).
    private func attivitaMostrata(_ indice: GiorniAgenda) -> Attivita? {
        guard let id = stato.attivitaSelezionata else { return nil }
        if let t = indice.attivita(giorno).first(where: { $0.id == id }) { return t }
        guard cal.isDateInToday(giorno) else { return nil }
        return stato.attivitaRimasteIndietro().first { $0.id == id }
    }

    private func idAppuntamento(_ s: Scelta?) -> String? {
        if case .appuntamento(let e)? = s { return e.id }
        return nil
    }

    private func idAttivita(_ s: Scelta?) -> String? {
        if case .attivita(let t)? = s { return t.id }
        return nil
    }

    private func dettaglio(_ indice: GiorniAgenda, elenco: [Occasione]) -> some View {
        Group {
            if let s = scelta(indice, elenco: elenco, ripiego: true) {
                vistaScelta(s)
            } else if stato.vistaAgenda == .occasioni {
                QuietoOccasioni()
            } else {
                quieto
            }
        }
        .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Colori.Agenda.dettaglioFondo)
        .overlay(alignment: .leading) {
            Rectangle().fill(Colori.Agenda.dettaglioBordo).frame(width: Tema.Misura.filo)
        }
    }

    @ViewBuilder private func vistaScelta(_ s: Scelta) -> some View {
        switch s {
        case .occasione(let o):
            DettaglioOccasione(
                occasione: o,
                nuovoAppuntamento: {
                    spiegazioneModulo = nil
                    modulo = $0
                },
                nuovaAttivita: { moduloAttivita = $0 }
            )
        case .appuntamento(let e):
            DettaglioAppuntamento(
                evento: e,
                modifica: {
                    spiegazioneModulo = nil
                    modulo = e
                },
                nuovaAttivita: {
                    var t = Attivita.nuova(clienteId: e.clienteId, scadenza: e.inizio)
                    t.titolo = "Preparare: \(e.titolo)"
                    t.appuntamentoId = e.id
                    moduloAttivita = t
                }
            )
        case .attivita(let t):
            DettaglioAttivita(attivita: t) { moduloAttivita = t }
        }
    }

    /// L'occasione scelta, ritrovata per id tra quelle mostrate (il giorno o i 12 mesi): se i dati sono cambiati
    /// e non c'è più, il dettaglio torna quieto.
    private func occasioneMostrata(_ indice: GiorniAgenda, elenco: [Occasione]) -> Occasione? {
        guard let scelta = stato.occasioneSelezionata else { return nil }
        let mostrate = stato.vistaAgenda == .occasioni ? elenco : (strato ? indice.occasioni(giorno) : [])
        return mostrate.first { $0.id == scelta.id }
    }

    private var quieto: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "calendar")
                .font(Tipo.simboloQuieto)
                .foregroundColor(Colori.Agenda.quieto)
            Text("Il tempo per ciò che conta.")
                .font(Tipo.quietoTitolo)
                .foregroundColor(Colori.Agenda.dettaglioTitolo)
            Text("Scegli un appuntamento o una cosa da fare: cliente, note e azioni in un solo posto.")
                .font(Tipo.quietoTesto)
                .foregroundColor(Colori.Agenda.quietoTesto)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Giorno della settimana

struct GiornoSettimanaAgenda: View {
    let nome: String
    let giorno: Date
    let incontri: Int
    let scadenze: Int
    let selezionato: Bool
    let oggi: Bool
    /// Le occasioni del giorno (vuoto con lo strato spento).
    var occasioni = SegniOccasioni()
    /// Le attività da fare con scadenza nel giorno (il puntino arancio).
    var attivita = 0
    let azione: () -> Void
    @State var sopra = false

    private var nota: String {
        if incontri > 0 { return "\(incontri) \(incontri == 1 ? "incontro" : "incontri")" }
        if attivita > 0 { return "\(attivita) da fare" }
        if scadenze > 0 { return "\(scadenze) \(scadenze == 1 ? "scadenza" : "scadenze")" }
        if occasioni.numero > 0 { return "\(occasioni.numero) \(occasioni.numero == 1 ? "occasione" : "occasioni")" }
        return "Libero"
    }

    var body: some View {
        Button(action: azione) {
            VStack(spacing: 1) {
                Text(nome.uppercased())
                    .font(Tipo.giornoSettimana)
                    .tracking(0.4)
                Text(Formati.giorno.string(from: giorno))
                    .font(Tipo.giornoNumero)
                    .foregroundColor(selezionato ? Colori.Agenda.selezioneTesto : (oggi ? Colori.Agenda.giornoOggiNumero : Colori.Agenda.giornoNumero))
                Text(nota)
                    .font(Tipo.giornoNota)
                    .lineLimit(1)
                    .minimumScaleFactor(Misure.AgendaImpaginazione.scalaNotaGiorno)
                    .opacity(0.85)
                PuntiniGiorno(incontri: incontri, scadenze: scadenze, selezionato: selezionato, occasioni: occasioni,
                              attivita: attivita)
                    .padding(.top, 2)
            }
            .foregroundColor(selezionato ? Colori.Agenda.selezioneTesto : Colori.Agenda.giorno)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(sfondo)
        }
        .buttonStyle(StileSemplice())
        .onHover { sopra = $0 }
    }

    @ViewBuilder private var sfondo: some View {
        let forma = FormaVetro.arrotondata(Tema.Raggio.Dossier.giornoSettimana)
        if selezionato {
            forma.fill(Colori.Agenda.selezioneAlto)
        } else if oggi {
            forma.strokeBorder(Colori.Agenda.giornoOggiBordo, lineWidth: 1)
        } else if sopra {
            forma.fill(Colori.Agenda.giornoPassaggio)
        }
    }
}

/// Puntini sotto il giorno: grigio per gli incontri, arancio per le cose da fare, ambra per le scadenze; poi un anello vuoto per ogni
/// colore di occasione (Alleanza, indipendente, neutro): il pieno è di incontri e scadenze, l'anello delle
/// occasioni, così si distinguono anche con lo stesso colore.
struct PuntiniGiorno: View {
    let incontri: Int
    let scadenze: Int
    let selezionato: Bool
    var occasioni = SegniOccasioni()
    /// Le attività da fare del giorno.
    var attivita = 0

    var body: some View {
        HStack(spacing: 3) {
            if incontri > 0 {
                Circle().fill(selezionato ? Colori.Agenda.puntinoSelezione : Colori.Agenda.puntino)
                    .frame(width: Misure.Agenda.puntino, height: Misure.Agenda.puntino)
            }
            if attivita > 0 {
                Circle().fill(selezionato ? Colori.Agenda.puntinoSelezione : Colori.Agenda.segnoAttivita)
                    .frame(width: Misure.Agenda.puntino, height: Misure.Agenda.puntino)
            }
            if scadenze > 0 {
                Circle().fill(selezionato ? Colori.Agenda.puntinoSelezione : Colori.Agenda.scadenzaTesto)
                    .frame(width: Misure.Agenda.puntino, height: Misure.Agenda.puntino)
            }
            if !occasioni.vuoto {
                AnelliOccasioni(segni: occasioni, selezionato: selezionato)
            }
        }
        .frame(height: max(Misure.Agenda.puntino, Misure.Occasioni.anello))
    }
}

// MARK: - Righe della giornata

struct RigaEventoAgenda: View {
    let evento: Appuntamento
    let cliente: String
    /// Il canale dell'appuntamento o, se manca, quello della posizione collegata (`canaleAppuntamento`).
    let canale: Canale?
    let selezionato: Bool
    let azione: () -> Void

    var body: some View {
        let concluso = evento.stato == .concluso
        Button(action: azione) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    // Le ore non vanno mai a capo («09:3 / 0» con il testo molto grande)
                    Text(Formati.ora.string(from: evento.inizio))
                        .font(Tipo.eventoOra)
                        .foregroundColor(Colori.Agenda.ora)
                        .lineLimit(1)
                        .fixedSize()
                    Text(Formati.ora.string(from: evento.fine))
                        .font(Tipo.eventoFine)
                        .foregroundColor(Colori.Agenda.oraFine)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: Misure.Agenda.colonnaOra, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .top)
                VStack(alignment: .leading, spacing: 3) {
                    // Nella colonna stretta titolo e dettagli vanno a capo su due righe (mai «Nuovi progetti d…»)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(evento.titolo)
                            .font(Tipo.eventoTitolo)
                            .foregroundColor(concluso ? Colori.Agenda.eventoConcluso : Colori.Agenda.evento)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        if concluso {
                            EtichettaStato(testo: "✓ Concluso", colore: Colori.Agenda.conclusoTesto, fondo: Colori.Agenda.conclusoFondo)
                        }
                        // Proposto dal Territorio con «＋ Aggiungi … al giro» e non ancora confermato («Luce» giro 11)
                        if evento.daConfermare == true {
                            Pillola(testo: "Da confermare", tono: .attenzione)
                        }
                        if let c = canale {
                            EtichettaCanale(canale: c, compatta: true)
                        }
                    }
                    Text(cliente)
                        .font(Tipo.eventoCliente)
                        .foregroundColor(Colori.Agenda.eventoCliente)
                    Text("\(evento.luogo.isEmpty ? "Luogo da definire" : evento.luogo) · \(evento.durataMinuti) min · \(evento.tipo.nome)")
                        .font(Tipo.eventoDettagli)
                        .foregroundColor(Colori.Agenda.eventoDettagli)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text("›")
                    .font(Tipo.eventoFreccia)
                    .foregroundColor(Colori.Agenda.freccia)
            }
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 15))
            .background(selezionato ? Colori.Agenda.rigaSelezione : Color.clear)
            .overlay(alignment: .leading) {
                if selezionato {
                    FormaVetro.capsula.fill(Colori.Agenda.rigaSegno)
                        .frame(width: Misure.Agenda.segno)
                        .padding(.vertical, 10)
                }
            }
            .bordoBasso(Colori.Agenda.rigaBordo)
        }
        .buttonStyle(StileSemplice())
    }
}

struct RigaScadenzaAgenda: View {
    let posizione: Posizione
    let cliente: String
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            // «Scade» e «Analizza ›» sulla riga del nome, come l'ora nelle righe degli appuntamenti
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                EtichettaStato(testo: "Scade", colore: Colori.Agenda.scadenzaTesto, fondo: Colori.Agenda.scadenzaFondo)
                    .frame(width: Misure.Agenda.colonnaOra, alignment: .leading)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(posizione.nome)
                            .font(Tipo.eventoTitolo)
                            .foregroundColor(Colori.Agenda.evento)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        EtichettaCanale(canale: posizione.canale, compatta: true)
                    }
                    Text(cliente)
                        .font(Tipo.eventoCliente)
                        .foregroundColor(Colori.Agenda.eventoCliente)
                    Text([posizione.area.nome, posizione.tipologia, posizione.emittente].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(Tipo.eventoDettagli)
                        .foregroundColor(Colori.Agenda.eventoDettagli)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text("Analizza ›")
                    .font(Tipo.eventoDettagli)
                    .foregroundColor(Colori.Colonna.collegamento)
            }
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 15))
            .bordoBasso(Colori.Agenda.rigaBordo)
        }
        .buttonStyle(StileSemplice())
        .help("Apri la posizione in Posizioni")
    }
}

// MARK: - Dettaglio dell'appuntamento

struct DettaglioAppuntamento: View {
    @Environment(StatoShell.self) var stato
    let evento: Appuntamento
    let modifica: () -> Void
    let nuovaAttivita: () -> Void

    var body: some View {
        let _ = ContaCorpi.segna()
        let concluso = evento.stato == .concluso
        let cliente = stato.cliente(evento.clienteId)
        let posizione = evento.posizioneId.flatMap { id in stato.posizioni.first { $0.id == id } }
        let collegate = stato.attivitaCollegate(evento.id)
        let canale = stato.canaleAppuntamento(evento)
        // Una volta sola per body: le azioni compaiono in più versioni della fila (ViewThatFits) e ognuna rifaceva la
        // ricerca del fascicolo fra i documenti e dell'incontro fra gli incontri
        let archiviato = stato.fascicoloArchiviato(per: evento)
        let aperto = stato.dati.incontri.contains { $0.appuntamentoId == evento.id }
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(concluso ? "INCONTRO CONCLUSO" : "IL TUO APPUNTAMENTO")
                        .font(Tipo.dettaglioOcchiello)
                        .tracking(1.2)
                        .foregroundColor(Colori.Agenda.dettaglioOcchiello)
                    Text(evento.titolo)
                        .font(Tipo.dettaglioTitolo)
                        .foregroundColor(Colori.Agenda.dettaglioTitolo)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 5)
                    HStack(alignment: .firstTextBaseline, spacing: Misure.AgendaImpaginazione.spazioCliente) {
                        Text(cliente?.nome ?? "Cliente")
                            .font(Tipo.dettaglioCliente)
                            .foregroundColor(Colori.Agenda.dettaglioCliente)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        // La scheda del cliente a portata di clic, come «Apri dossier» nelle Note
                        Button { stato.apriCliente(evento.clienteId) } label: {
                            HStack(spacing: Tema.Misura.Componenti.spazioSimboloPulsante) {
                                Text("Scheda cliente")
                                Image(systemName: "arrow.up.right")
                            }
                        }
                        .buttonStyle(StileCollegamento())
                        .fixedSize()
                        .help("Apri la scheda del cliente")
                    }
                    .padding(.bottom, 7)

                    // Appuntamento concluso con una proposta da chiudere: l'esito si chiede subito, qui
                    if let p = stato.propostaDaChiudere(evento) {
                        RiquadroEsitoProposta(appuntamento: evento, posizione: p,
                                              passoIniziale: MotoreSeguitoProposte.passoIniziale(evento))
                            .padding(.bottom, Misure.RiesamiAgenda.sottoEsito)
                    }

                    VoceDettaglio(etichetta: "Quando") {
                        Text("\(Formati.dataLunga.string(from: evento.inizio))\n\(Formati.ora.string(from: evento.inizio)) – \(Formati.ora.string(from: evento.fine))")
                            .font(Tipo.voceValore)
                            .foregroundColor(Colori.Agenda.voceValore)
                    }
                    VoceDettaglio(etichetta: "Dove") { valore(evento.luogo.isEmpty ? "Luogo da definire" : evento.luogo) }
                    VoceDettaglio(etichetta: "Durata") { valore("\(evento.durataMinuti) minuti") }
                    VoceDettaglio(etichetta: "Tipo") { valore(evento.tipo.nome) }
                    // Proposto dal Territorio («Luce» giro 11): «Conferma in Agenda» porta qui, con l'appuntamento scelto
                    if evento.daConfermare == true {
                        VoceDettaglio(etichetta: "Da confermare") {
                            HStack(spacing: Misure.AgendaImpaginazione.spazioCliente) {
                                Pillola(testo: "Proposto dal Territorio", tono: .attenzione)
                                Button("Conferma") { stato.confermaAppuntamento(evento.id) }
                                    .buttonStyle(.apple)
                                    .fixedSize()
                                    .help("Conferma l'appuntamento proposto dal Territorio")
                            }
                        }
                    }
                    VoceDettaglio(etichetta: "Canale") {
                        if let c = canale {
                            EtichettaCanale(canale: c, compatta: true)
                        } else {
                            Pillola(testo: "Da indicare", tono: .neutro)
                                .help("Indica il canale con «Modifica» o collega una posizione all'appuntamento")
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("NOTE PER L'INCONTRO")
                            .font(Tipo.voceEtichetta)
                            .tracking(0.3)
                            .foregroundColor(Colori.Agenda.notaEtichetta)
                        Text(evento.note.isEmpty ? "Aggiungi i punti da affrontare e i documenti utili per arrivare preparato." : evento.note)
                            .font(Tipo.voceValore)
                            .foregroundColor(Colori.Agenda.notaTesto)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .vetro(.chip, forma: .arrotondata(Tema.Raggio.Dossier.riquadro), riempimento: Colori.Agenda.notaFondo)
                    .padding(.vertical, 8)

                    if let p = posizione {
                        riquadroPosizione(p)
                    }
                    if !collegate.isEmpty {
                        Text("ATTIVITÀ COLLEGATE")
                            .font(Tipo.voceEtichetta)
                            .tracking(0.3)
                            .foregroundColor(Colori.Agenda.notaEtichetta)
                            .padding(.top, 4)
                        ForEach(collegate) { t in
                            Button { stato.alternaCompletata(t.id) } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 7) {
                                    Image(systemName: t.completata ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(t.completata ? Colori.Attivita.spuntaFattaBasso : Colori.Agenda.voceEtichetta)
                                    Text(t.titolo)
                                        .font(Tipo.voceValore)
                                        .foregroundColor(t.completata ? Colori.Agenda.eventoConcluso : Colori.Agenda.voceValore)
                                        .strikethrough(t.completata)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(StileSemplice())
                            .help(t.completata ? "Segna come da fare" : "Segna come fatta")
                        }
                    }
                }
                .padding(.trailing, 4)
                .padding(.bottom, Misure.AgendaImpaginazione.sfumaturaDettaglio / 2)
            }
            // L'ultima riga sfuma sopra le azioni invece di finire tagliata a metà
            .sfumaturaBordiScorrimento(sotto: Misure.AgendaImpaginazione.sfumaturaDettaglio)

            // Le azioni in due gruppi: le principali in alto, le altre in una fila sola se c'è posto,
            // altrimenti due per riga (o una sotto l'altra): i titoli non si troncano mai
            // Nessun blu nel dettaglio (il blu è «Appuntamento» nella barra): per prima l'azione consigliata,
            // «Prepara l'incontro», in vetro dell'accento; l'analisi viene prima di Vera.
            let spazio = Misure.AgendaImpaginazione.spazioAzioni
            VStack(spacing: spazio) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: spazio) {
                        azioneIncontro(aperto)
                        azioneVera
                    }
                    VStack(spacing: spazio) {
                        azioneIncontro(aperto)
                        azioneVera
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: spazio) {
                        azioneConcluso(concluso)
                        azioneModifica
                        azioneAttivita
                        azioneFascicolo(archiviato)
                    }
                    VStack(spacing: spazio) {
                        HStack(spacing: spazio) {
                            azioneConcluso(concluso)
                            azioneModifica
                        }
                        HStack(spacing: spazio) {
                            azioneAttivita
                            azioneFascicolo(archiviato)
                        }
                    }
                    VStack(spacing: spazio) {
                        azioneConcluso(concluso)
                        azioneModifica
                        azioneAttivita
                        azioneFascicolo(archiviato)
                    }
                }
            }
            .padding(.top, 7)
            .bordoAlto(Colori.Agenda.azioniBordo)
        }
    }

    // MARK: - Azioni del dettaglio

    private var azioneVera: some View {
        PulsanteAzione(titolo: "Prepara con Vera", simbolo: "sparkles") {
            // Un blocco «Non disponibile» non ha cliente: Vera si apre su quello di prima
            if !evento.clienteId.isEmpty { stato.clienteAttivoId = evento.clienteId }
            stato.apri(.vera)
        }
    }

    private var azioneModifica: some View {
        PulsanteAzione(titolo: "Modifica", simbolo: "pencil", azione: modifica)
    }

    private func azioneConcluso(_ concluso: Bool) -> some View {
        PulsanteAzione(titolo: concluso ? "Riapri incontro" : "Segna concluso",
                       simbolo: concluso ? "arrow.uturn.backward" : "checkmark") { stato.alternaConcluso(evento.id) }
    }

    private var azioneAttivita: some View {
        PulsanteAzione(titolo: "Attività collegata", simbolo: "checklist", azione: nuovaAttivita)
    }

    /// `archiviato`: il fascicolo già in Documenti, cercato una volta dal body (al tocco si cerca di nuovo).
    private func azioneFascicolo(_ archiviato: Documento?) -> some View {
        PulsanteAzione(titolo: archiviato == nil ? "Prepara il fascicolo" : "Apri il fascicolo",
                       simbolo: "doc.text") {
            if let d = stato.fascicoloArchiviato(per: evento) {
                if !evento.clienteId.isEmpty { stato.clienteAttivoId = evento.clienteId }
                stato.documentoSelezionato = d.id
                stato.apri(.documenti)
            } else {
                stato.preparaFascicolo(per: evento)
            }
        }
        .help(archiviato == nil ? "Unisci in un PDF i report da consegnare al cliente"
                                : "Il fascicolo consegnato è in Documenti: aprilo")
    }

    /// `aperto`: c'è già un incontro per questo appuntamento (dal body).
    private func azioneIncontro(_ aperto: Bool) -> some View {
        PulsanteAzione(titolo: aperto ? "Apri l'incontro" : "Prepara l'incontro", principale: true,
                       simbolo: "list.bullet.rectangle") {
            stato.apriIncontro(per: evento)
        }
        .help(aperto ? "Apri l'incontro: appunti e decisioni" : "Prepara l'incontro: temi, ascolto, prossimi passi")
    }

    private func valore(_ testo: String) -> some View {
        Text(testo).font(Tipo.voceValore).foregroundColor(Colori.Agenda.voceValore)
    }

    private func riquadroPosizione(_ p: Posizione) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(p.stato == .proposta ? "PROPOSTA DI CUI SI PARLA" : "POSIZIONE DI CUI SI PARLA")
                .font(Tipo.voceEtichetta)
                .tracking(0.3)
                .foregroundColor(Colori.Agenda.notaEtichetta)
            HStack(spacing: 6) {
                Text(p.nome)
                    .font(Tipo.voceValore.weight(.semibold))
                    .foregroundColor(Colori.Agenda.dettaglioTitolo)
                    .lineLimit(1)
                EtichettaCanale(canale: p.canale, compatta: true)
            }
            Text([p.area.nome, p.stato.nome, p.scadenza.map { "scadenza \(Formati.dataEstesa.string(from: $0))" } ?? ""]
                    .filter { !$0.isEmpty }.joined(separator: " · "))
                .font(Tipo.voceEtichetta)
                .foregroundColor(Colori.Agenda.voceEtichetta)
            // La proposta ha già un esito: presentata, accettata, rifiutata o rimandata
            if let e = p.esito, e != .bozza {
                Text(TestiSeguito.esito(p, adesso: Date()))
                    .font(Tipo.voceEtichetta)
                    .foregroundColor(Colori.Agenda.voceEtichetta)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button { stato.apriPosizione(p) } label: { Label("Analizza in Posizioni", systemImage: "chart.pie") }
                .buttonStyle(StileVetro(taglia: .compatta))
                .fixedSize()
                .padding(.top, 2)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .vetro(.sottile, forma: .arrotondata(Tema.Raggio.Dossier.riquadro))
        .padding(.bottom, 8)
    }
}

extension StatoShell {
    /// Il canale da mostrare per un appuntamento: il suo o, se non è indicato, quello della posizione collegata.
    func canaleAppuntamento(_ e: Appuntamento) -> Canale? {
        if let c = e.canale { return c }
        guard let id = e.posizioneId else { return nil }
        // Il canale di ogni posizione in un dizionario, una volta per dati dei calcoli: le pillole del mese lo chiedono
        // per ogni appuntamento e prima ogni richiesta scorreva tutte le posizioni (con due posizioni con lo stesso id
        // vale la prima, come con `first(where:)`)
        let canali: [String: Canale] = ricavato("agenda-canali-posizioni") {
            Dictionary(posizioni.map { ($0.id, $0.canale) }, uniquingKeysWith: { primo, _ in primo })
        }
        return canali[id]
    }
}

/// Una parte dell'Agenda costruita nel body di questa vista e non in quello dell'Agenda: ciò che legge di StatoShell (la
/// riga scelta nella colonna del giorno) iscrive solo lei. Un clic su un appuntamento, un'attività o un'occasione rifà
/// la colonna, non la barra, la striscia dei riesami e le celle del mese. Stessa impaginazione del contenuto.
private struct ParteAgenda<Contenuto: View>: View {
    let contenuto: () -> Contenuto

    var body: some View { contenuto() }
}

private extension View {
    /// Una card del contenuto dell'Agenda nel tema Apple: piatta, con il contenuto tagliato alla sua forma.
    func cardAgendaApple() -> some View {
        let d = Tema.Apple.Agenda.Disposizione.self
        let forma = RoundedRectangle(cornerRadius: d.raggio, style: .continuous)
        return clipShape(forma)
            .superficieApple(d.superficie, raggio: d.raggio)
    }
}
