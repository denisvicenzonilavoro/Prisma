import SwiftUI

// L'Agenda a vista mensile, con Attività accorpata (sul Mac Attività non ha più una finestra propria), nel tema
// Apple (Tema.Apple.Agenda: oggi su rosso, il giorno scelto sull'accento al 14%, i segni del giorno):
// la griglia del mese che riempie lo spazio, le celle con le pillole degli appuntamenti e i segni del giorno,
// il riepilogo delle cose da fare nella fascia in testa. La colonna del giorno è in AppAgenda.swift.

extension StatoShell {
    /// Ordine delle attività di un giorno: prima quelle da fare, poi per priorità, poi per titolo.
    static func ordineAttivita(_ a: Attivita, _ b: Attivita) -> Bool {
        if a.completata != b.completata { return !a.completata }
        if a.priorita.ordine != b.priorita.ordine { return a.priorita.ordine < b.priorita.ordine }
        return a.titolo.localizedCompare(b.titolo) == .orderedAscending
    }

    /// Le attività da fare con la scadenza già passata (prima di oggi), per il filtro cliente dell'Agenda:
    /// nella giornata di oggi stanno in «Rimaste indietro». Dalla memoria (`attivitaAperte`, per scadenza).
    func attivitaRimasteIndietro(_ oggi: Date = Date()) -> [Attivita] {
        let inizio = Calendar.current.startOfDay(for: oggi)
        let filtro = filtroClienteAgenda
        return attivitaAperte.filter { $0.scadenza < inizio && (filtro == nil || $0.clienteId == filtro) }
    }

    /// Il riepilogo delle attività nella fascia dell'Agenda: da svolgere, entro 7 giorni (scadute comprese), scadute.
    func riepilogoAttivitaAgenda(_ oggi: Date = Date()) -> (daSvolgere: Int, entroSette: Int, scadute: Int) {
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: oggi)
        let limite = cal.date(byAdding: .day, value: 7, to: inizio) ?? inizio
        let filtro = filtroClienteAgenda
        var daSvolgere = 0, entroSette = 0, scadute = 0
        for t in attivitaAperte where filtro == nil || t.clienteId == filtro {
            daSvolgere += 1
            if t.scadenza < limite { entroSette += 1 }
            if t.scadenza < inizio { scadute += 1 }
        }
        return (daSvolgere, entroSette, scadute)
    }

    /// Sceglie un'attività nella giornata dell'Agenda: il dettaglio la mostra al posto dell'appuntamento.
    func scegliAttivitaInAgenda(_ id: String) {
        attivitaSelezionata = id
        appuntamentoSelezionato = nil
        occasioneSelezionata = nil
    }

    /// Salva un'attività dall'Agenda e porta l'Agenda al giorno della scadenza, con l'attività aperta.
    /// Quella nata da un appuntamento aperto nel dettaglio lascia l'appuntamento davanti (se è lo stesso giorno).
    func salvaAttivitaInAgenda(_ a: Attivita) {
        salvaAttivita(a)
        let cal = Calendar.current
        giornoAgenda = cal.startOfDay(for: a.scadenza)
        if vistaAgenda == .occasioni { vistaAgenda = .mese }
        occasioneSelezionata = nil
        let restaAppuntamento = appuntamentoSelezionato.flatMap { id in
            id == a.appuntamentoId ? appuntamento(id) : nil
        }.map { cal.isDate($0.inizio, inSameDayAs: a.scadenza) } ?? false
        if !restaAppuntamento { appuntamentoSelezionato = nil }
        if filtroClienteAgenda != nil && filtroClienteAgenda != a.clienteId { filtroClienteAgenda = a.clienteId }
    }
}

// MARK: - Griglia del mese

/// Il mese come un calendario vero: le settimane si dividono l'altezza disponibile, le celle crescono con la
/// finestra e mostrano tante pillole quante ne stanno (al massimo tre, poi «+N»).
/// `Equatable` (con `.equatable()` in AppAgenda): le passate dell'Agenda che non toccano la griglia (un foglio, la
/// striscia dei riesami, la barra) non rifanno le 42 celle.
struct MeseAgenda: View, Equatable {
    /// Ciò da cui dipendono l'indice in cache e le celle oltre a settimane, giorno e strato: dati dei calcoli, giorno
    /// di oggi, ora e modalità cliente (`ChiaveVista`) e il filtro cliente dell'Agenda.
    struct Chiave: Equatable {
        let vista: ChiaveVista
        let filtro: String?
    }

    let settimane: [[Date]]
    /// Il giorno scelto (decide anche il mese mostrato).
    let giorno: Date
    let indice: GiorniAgenda
    /// Lo strato delle occasioni (Impostazioni › Occasioni).
    let strato: Bool
    let chiave: Chiave
    let canale: (Appuntamento) -> Canale?
    let seleziona: (Date) -> Void

    /// L'indice resta fuori dal confronto (è quello in cache per giorni, filtro e chiave), e le azioni pure: fanno
    /// sempre la stessa cosa con l'appuntamento o il giorno che ricevono.
    nonisolated static func == (a: MeseAgenda, b: MeseAgenda) -> Bool {
        a.settimane == b.settimane && a.giorno == b.giorno && a.strato == b.strato && a.chiave == b.chiave
    }

    var body: some View {
        let m = Misure.AgendaMese.self
        GeometryReader { geo in
            let righe = CGFloat(max(1, settimane.count))
            let libero = geo.size.height - m.testaGiorni - m.spazioCelle * righe
            let altezza = max(m.cellaMinima, libero / righe)
            let pillole = m.pillole(altezza: altezza)
            VStack(spacing: m.spazioCelle) {
                HStack(spacing: m.spazioCelle) {
                    ForEach(CalendarioAgenda.nomiGiorni, id: \.self) { n in
                        Text(n.uppercased())
                            .carattereApple(Tema.Apple.Agenda.Mese.nomeGiorno)
                            .foregroundColor(Tema.Apple.Agenda.Mese.coloreNomeGiorno)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: m.testaGiorni)
                ForEach(settimane, id: \.self) { s in
                    HStack(spacing: m.spazioCelle) {
                        ForEach(s, id: \.self) { g in
                            cella(g, pillole: pillole)
                                .frame(height: altezza)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    /// La cella di un giorno (a parte, per tenere leggero il controllo dei tipi della griglia).
    private func cella(_ g: Date, pillole: Int) -> CellaGiornoMese {
        let cal = CalendarioAgenda.cal
        let daFare = indice.daFare(g)
        let scadute = !daFare.isEmpty && g < cal.startOfDay(for: Date())
        let occasioni = strato ? SegniOccasioni(indice.occasioni(g)) : SegniOccasioni()
        return CellaGiornoMese(
            giorno: g,
            nelMese: cal.isDate(g, equalTo: giorno, toGranularity: .month),
            selezionato: cal.isDate(g, inSameDayAs: giorno),
            oggi: cal.isDateInToday(g),
            appuntamenti: indice.appuntamenti(g),
            daFare: daFare.count,
            scadute: scadute,
            scadenze: indice.scadenze(g).count,
            occasioni: occasioni,
            pillole: pillole,
            canale: canale,
            azione: { seleziona(g) }
        )
    }
}

/// Una cella del mese: numero (oggi nel cerchio rosso), segni del giorno e pillole degli appuntamenti.
struct CellaGiornoMese: View {
    let giorno: Date
    let nelMese: Bool
    let selezionato: Bool
    let oggi: Bool
    let appuntamenti: [Appuntamento]
    /// Le attività ancora da fare con scadenza in questo giorno.
    let daFare: Int
    /// Il giorno è passato e ha attività non fatte: il segno diventa rosso.
    let scadute: Bool
    let scadenze: Int
    var occasioni = SegniOccasioni()
    /// Quante pillole stanno nella cella (0: solo numero e segni).
    let pillole: Int
    let canale: (Appuntamento) -> Canale?
    let azione: () -> Void
    @State var sopra = false

    var body: some View {
        let m = Misure.AgendaMese.self
        let forma = RoundedRectangle(cornerRadius: Tema.Apple.Agenda.Mese.raggio, style: .continuous)
        // Se gli appuntamenti sono più delle pillole, l'ultima riga diventa «+N»
        let mostrate = appuntamenti.count > pillole ? max(0, pillole - 1) : appuntamenti.count
        let altri = appuntamenti.count - mostrate
        Button(action: azione) {
            VStack(alignment: .leading, spacing: m.spazioPillole) {
                testa
                ForEach(appuntamenti.prefix(mostrate)) { e in
                    PillolaAppuntamento(evento: e, canale: canale(e))
                }
                if altri > 0 && pillole > 0 {
                    Text("+\(altri)")
                        .font(Tipo.altriAppuntamenti)
                        .foregroundColor(Colori.Agenda.altriAppuntamenti)
                        .lineLimit(1)
                        .padding(m.marginePillola)
                        .frame(height: m.pillola)
                }
                Spacer(minLength: 0)
            }
            .padding(m.margineCella)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background { sfondo(forma) }
            .contentShape(forma)
            .opacity(nelMese ? 1 : m.opacitaFuoriMese)
        }
        .buttonStyle(StileSemplice())
        .onHover { sopra = $0 }
        .help(descrizione)
        .accessibilityLabel(descrizione)
    }

    /// Il numero del giorno a sinistra, i segni a destra.
    private var testa: some View {
        let m = Misure.AgendaMese.self
        return HStack(spacing: m.spazioSegni) {
            if oggi {
                Text(Formati.giorno.string(from: giorno))
                    .carattereApple(Tema.Apple.Agenda.Mese.numeroOggi)
                    .foregroundColor(Tema.Apple.Agenda.Mese.testoOggi)
                    .frame(minWidth: m.cerchioOggi, minHeight: m.cerchioOggi)
                    .background { Capsule(style: .continuous).fill(Tema.Apple.Agenda.Mese.fondoOggi) }
            } else {
                Text(Formati.giorno.string(from: giorno))
                    .carattereApple(Tema.Apple.Agenda.Mese.numero)
                    .foregroundColor(Tema.Apple.Agenda.Mese.coloreNumero)
            }
            Spacer(minLength: 0)
            // Con la cella troppo bassa per le pillole, un puntino dice che ci sono appuntamenti
            if pillole == 0 && !appuntamenti.isEmpty {
                segno(Tema.Apple.Agenda.Segno.appuntamento, conteggio: appuntamenti.count)
            }
            // I riesami (appuntamenti di revisione) hanno il loro segno anche quando le pillole ci sono
            if riesami > 0 {
                segno(Tema.Apple.Agenda.Segno.riesame, conteggio: riesami)
            }
            if daFare > 0 {
                segno(scadute ? Tema.Apple.Agenda.Segno.attivitaScaduta : Tema.Apple.Agenda.Segno.attivita, conteggio: daFare)
            }
            if scadenze > 0 {
                segno(Tema.Apple.Agenda.Segno.scadenza, conteggio: scadenze)
            }
            if !occasioni.vuoto {
                AnelliOccasioni(segni: occasioni, selezionato: false)
            }
        }
        .lineLimit(1)
        .frame(height: m.testaCella)
    }

    /// Un segno pieno, con il numero se sono più di uno.
    private func segno(_ colore: Color, conteggio: Int) -> some View {
        let m = Misure.AgendaMese.self
        return HStack(spacing: m.spazioConteggio) {
            Circle().fill(colore).frame(width: m.segno, height: m.segno)
            if conteggio > 1 {
                Text("\(conteggio)")
                    .font(Tipo.conteggioSegno)
                    .foregroundColor(Colori.Agenda.conteggioSegno)
                    .fixedSize()
            }
        }
    }

    /// Il giorno scelto sull'accento al 14%, il passaggio del puntatore in `chip`, il filo `separatore`.
    @ViewBuilder private func sfondo(_ forma: RoundedRectangle) -> some View {
        let m = Misure.AgendaMese.self
        let a = Tema.Apple.Agenda.Mese.self
        if selezionato {
            forma.fill(a.fondoScelto)
                .overlay { forma.strokeBorder(a.bordoScelto, lineWidth: m.bordoSelezione) }
        } else if sopra {
            forma.fill(a.fondoPassaggio)
                .overlay { forma.strokeBorder(a.bordo, lineWidth: Tema.Apple.Misura.bordo) }
        } else {
            forma.strokeBorder(a.bordo, lineWidth: Tema.Apple.Misura.bordo)
        }
    }

    /// Gli appuntamenti di revisione del giorno (i riesami).
    private var riesami: Int { appuntamenti.filter { $0.tipo == .revisione }.count }

    private var descrizione: String {
        var parti = [Formati.dataLunga.string(from: giorno)]
        if oggi { parti.append("oggi") }
        if !appuntamenti.isEmpty {
            parti.append("\(appuntamenti.count) \(appuntamenti.count == 1 ? "appuntamento" : "appuntamenti")")
        }
        if riesami > 0 { parti.append("\(riesami) \(riesami == 1 ? "riesame" : "riesami")") }
        if daFare > 0 { parti.append("\(daFare) da fare") }
        if scadenze > 0 { parti.append("\(scadenze) \(scadenze == 1 ? "scadenza" : "scadenze")") }
        if occasioni.numero > 0 { parti.append("\(occasioni.numero) \(occasioni.numero == 1 ? "occasione" : "occasioni")") }
        return parti.joined(separator: " · ")
    }
}

/// La pillola di un appuntamento nella cella del mese: barretta e fondo del canale, ora e titolo.
struct PillolaAppuntamento: View {
    let evento: Appuntamento
    let canale: Canale?

    var body: some View {
        let m = Misure.AgendaMese.self
        let concluso = evento.stato == .concluso
        // Nelle celle strette: ora e titolo, poi solo l'ora, poi solo un puntino (mai un testo tagliato a metà)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: m.spazioPillola) {
                segno
                ora(concluso)
                Text(evento.titolo)
                    .font(Tipo.pillolaTitolo)
                    .foregroundColor(concluso ? Colori.Agenda.pillolaConclusa : Colori.Agenda.pillolaTesto)
                    .lineLimit(1)
                    .frame(minWidth: 0, idealWidth: m.titoloMinimoPillola, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: m.spazioPillola) {
                segno
                ora(concluso)
                Spacer(minLength: 0)
            }
            HStack(spacing: 0) {
                Circle()
                    .fill(Colori.Agenda.pillola(canale))
                    .frame(width: m.puntinoPillola, height: m.puntinoPillola)
                Spacer(minLength: 0)
            }
        }
        .padding(m.marginePillola)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: m.pillola)
        .background { FormaVetro.arrotondata(m.raggioPillola).fill(Colori.Agenda.pillolaFondo(canale)) }
    }

    /// La barretta del canale davanti alla pillola.
    private var segno: some View {
        let m = Misure.AgendaMese.self
        return FormaVetro.capsula.fill(Colori.Agenda.pillola(canale))
            .frame(width: m.segnoPillola)
            .padding(.vertical, m.rientroSegnoPillola)
    }

    private func ora(_ concluso: Bool) -> some View {
        Text(Formati.ora.string(from: evento.inizio))
            .font(Tipo.pillolaOra)
            .foregroundColor(concluso ? Colori.Agenda.pillolaConclusa : Colori.Agenda.pillolaOra)
            .fixedSize()
    }
}

// MARK: - Riepilogo delle attività

/// Nella fascia dell'Agenda: quante cose da fare, quante entro 7 giorni, quante scadute.
struct RiepilogoAttivitaAgenda: View {
    let daSvolgere: Int
    let entroSette: Int
    let scadute: Int

    var body: some View {
        let m = Misure.AgendaMese.self
        HStack(spacing: m.spazioRiepilogo) {
            Circle().fill(Colori.Agenda.segnoAttivita).frame(width: m.puntoRiepilogo, height: m.puntoRiepilogo)
            voce(daSvolgere, "da svolgere")
            Text("·")
            voce(entroSette, "entro 7 giorni")
            if scadute > 0 {
                Text("·")
                (Text("\(scadute)").font(Tipo.riepilogoAttivitaForte) + Text(scadute == 1 ? " scaduta" : " scadute"))
                    .foregroundColor(Colori.Agenda.riepilogoScadute)
            }
        }
        .font(Tipo.riepilogoAttivita)
        .foregroundColor(Colori.Agenda.riepilogo)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    private func voce(_ n: Int, _ testo: String) -> Text {
        Text("\(n)").font(Tipo.riepilogoAttivitaForte).foregroundColor(Colori.Agenda.riepilogoForte) + Text(" " + testo)
    }
}
