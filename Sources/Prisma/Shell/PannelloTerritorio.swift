import SwiftUI

// Territorio · il pannello sopra la mappa («Luce» giro 11, §5.1.1, §5.1.5-§5.1.6): Oggi (totali contati, tre tile,
// legenda), La crescita (anno, valori contati, cursore, «Guarda la crescita»), Il giro di domani (visite e stime
// dichiarate, tappe, «Lungo la strada» con «＋ Aggiungi … al giro»), gli stati vuoti, l'elenco dei clienti non sulla mappa
// e la riga «Posizione sulla mappa» del dossier. Tutti i testi sono onesti: stime «in linea d'aria», niente CAP, nessun
// dato demografico (decisione 71), il nome di battesimo al posto di «Aggiungila» (Prisma non conosce il genere).

private typealias P = Tema.Apple.Territorio.Pannello
private typealias G = Tema.Apple.Territorio.Giro

/// L'etichetta in maiuscolo del pannello (`.lbl` del template).
private struct EtichettaPannello: View {
    let testo: String

    var body: some View {
        Text(testo)
            .carattereApple(P.etichetta)
            .foregroundColor(P.coloreEtichetta)
    }
}

/// Una tile del pannello: titolo, valore, nota; un clic la accende (filtro).
struct TileTerritorio: View {
    let titolo: String
    let valore: String
    var nota: String? = nil
    var coloreValore: Color = Tema.Apple.Territorio.Pannello.coloreTesto
    var bordo: Color = Tema.Apple.Territorio.Pannello.bordoTile
    var accesa = false
    var azione: (() -> Void)? = nil

    var body: some View {
        let corpo = VStack(alignment: .leading, spacing: P.spazio / 2) {
            Text(titolo)
                .carattereApple(P.titoloTile)
                .foregroundColor(P.coloreTesto2)
            Text(valore)
                .carattereApple(P.valoreTile)
                .foregroundColor(coloreValore)
                .fixedSize(horizontal: false, vertical: true)
            if let nota {
                Text(nota)
                    .carattereApple(P.notaTile)
                    .foregroundColor(P.coloreTesto2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(P.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: P.raggioTile, style: .continuous).fill(accesa ? P.fondoTileAcceso : P.fondoTile))
        .overlay(RoundedRectangle(cornerRadius: P.raggioTile, style: .continuous).stroke(bordo, lineWidth: P.spessoreBordoTile))
        if let azione {
            Button(action: azione) { corpo }
                .buttonStyle(.plain)
                .accessibilityAddTraits(accesa ? .isSelected : [])
        } else {
            corpo
        }
    }
}

/// «1 cliente non è sulla mappa», «3 clienti non sono sulla mappa».
private func testoNonSullaMappa(_ n: Int) -> String {
    n == 1 ? "1 cliente non è sulla mappa" : "\(n) clienti non sono sulla mappa"
}

// MARK: - Oggi

struct PannelloOggi: View {
    let oggi: TerritorioOggi
    let diProva: Bool

    @Environment(StatoShell.self) private var stato

    var body: some View {
        let t = stato.territorio
        VStack(alignment: .leading, spacing: P.spazio) {
            if t.tabellaNonLeggibile {
                EtichettaPannello(testo: "OGGI")
                Text("La tabella dei comuni non si legge: reinstalla Prisma.")
                    .carattereApple(P.testo)
                    .foregroundColor(P.coloreTesto)
            } else if oggi.luci.isEmpty {
                EtichettaPannello(testo: "OGGI")
                    .entrataCascata(0)
                Text("Nessun cliente ha ancora un indirizzo che Prisma sa mettere sulla mappa.")
                    .carattereApple(P.testo)
                    .foregroundColor(P.coloreTesto)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrataCascata(1)
                Button("Completa gli indirizzi") { t.elencoSenzaLuogo = true }
                    .buttonStyle(.applePrimario)
                    .disabled(oggi.senzaLuogo.isEmpty)
                    .entrataCascata(2)
                Spacer(minLength: 0)
            } else {
                EtichettaPannello(testo: "OGGI")
                    .entrataCascata(0)
                HStack(alignment: .firstTextBaseline, spacing: P.spazio / 2) {
                    NumeroCheConta(Double(oggi.luci.count), formato: .intero, indice: 0)
                        .carattereApple(P.totale)
                        .foregroundColor(P.coloreTesto)
                    Text(oggi.luci.count == 1 ? "cliente" : "clienti")
                        .carattereApple(P.testoForte)
                        .foregroundColor(P.coloreTesto)
                }
                .entrataCascata(1)
                HStack(alignment: .firstTextBaseline, spacing: P.spazio / 2) {
                    NumeroCheConta(oggi.totale, formato: .euro, indice: 1)
                        .carattereApple(P.testoForte)
                        .foregroundColor(P.coloreTesto)
                    Text("seguiti nella tua zona")
                        .carattereApple(P.testo)
                        .foregroundColor(P.coloreTesto2)
                }
                .entrataCascata(2)
                tile
                    .padding(.top, P.sopraTile)
                if t.soloDaFare { elencoDaFare }
                Spacer(minLength: P.spazio)
                if !oggi.senzaLuogo.isEmpty {
                    Button(testoNonSullaMappa(oggi.senzaLuogo.count)) {
                        t.elencoSenzaLuogo = true
                    }
                    .buttonStyle(.appleSobrio)
                }
                LegendaTerritorio(diProva: diProva)
            }
        }
    }

    private var tile: some View {
        let t = stato.territorio
        let conZone = !stato.dati.impostazioni.territorio.zone.isEmpty
        return VStack(spacing: P.spazioTile) {
            if let z = oggi.zonaPiuRicca {
                TileTerritorio(titolo: conZone ? "La zona con più patrimonio" : "Il comune con più patrimonio", valore: z.nome,
                               accesa: t.filtroZona == z.nome) {
                    t.soloDaFare = false
                    t.filtroZona = t.filtroZona == z.nome ? nil : z.nome
                }
                .entrataCascata(3)
            }
            if let z = oggi.zonaUnCliente {
                TileTerritorio(titolo: "Dove hai un solo cliente", valore: z.nome, accesa: t.filtroZona == z.nome) {
                    t.soloDaFare = false
                    t.filtroZona = t.filtroZona == z.nome ? nil : z.nome
                }
                .entrataCascata(4)
            }
            TileTerritorio(titolo: "Con qualcosa da fare",
                           valore: oggi.conQualcosaDaFare == 1 ? "1 cliente" : "\(oggi.conQualcosaDaFare) clienti",
                           nota: "sono i punti con l'anello arancio", coloreValore: P.testoDaFare, bordo: P.bordoDaFare,
                           accesa: t.soloDaFare) {
                t.filtroZona = nil
                t.soloDaFare.toggle()
            }
            .entrataCascata(5)
        }
    }

    private var elencoDaFare: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: P.spazio / 2) {
                ForEach(oggi.luci.filter { $0.daFare != nil }) { l in
                    Button { stato.apriCliente(l.id) } label: {
                        HStack(spacing: P.spazio) {
                            AvatarCliente(iniziali: l.cliente.iniziali, tinta: l.cliente.tinta.colori, lato: P.avatar)
                            VStack(alignment: .leading, spacing: P.spazioRighe) {
                                Text(l.cliente.nome).carattereApple(P.testoForte).foregroundColor(P.coloreTesto)
                                Text(l.daFare?.perche ?? "").carattereApple(P.piccolo).foregroundColor(P.testoDaFare).lineLimit(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// La legenda e la frase sulla provenienza delle posizioni (niente CAP), con «dati di prova» se la tabella è di prova.
struct LegendaTerritorio: View {
    let diProva: Bool

    private typealias Lg = Tema.Apple.Territorio.Legenda
    private typealias L = Tema.Apple.Territorio.Luce

    var body: some View {
        VStack(alignment: .leading, spacing: Lg.spazio) {
            HStack(spacing: Lg.spazio * 2) {
                voce(colore: L.alleanza, "Alleanza")
                voce(colore: L.indipendente, "Indipendente")
                HStack(spacing: Lg.spazio) {
                    Circle().stroke(Lg.bordoEntrambi, lineWidth: Lg.spessoreBordo).frame(width: Lg.pallino, height: Lg.pallino)
                    Text("entrambi").carattereApple(Lg.testo).foregroundColor(Lg.colore)
                }
            }
            Text("La luce cresce con il patrimonio. Le posizioni vengono dalle coordinate dei comuni incluse in Prisma (ISTAT): gli indirizzi non escono dal Mac.")
                .carattereApple(Lg.testo)
                .foregroundColor(Lg.colore)
                .fixedSize(horizontal: false, vertical: true)
            if diProva { EtichettaDatiDiProvaPratiche() }
        }
        .accessibilityElement(children: .combine)
    }

    private func voce(colore: Color, _ nome: String) -> some View {
        HStack(spacing: Lg.spazio) {
            Circle().fill(colore).frame(width: Lg.pallino, height: Lg.pallino)
            Text(nome).carattereApple(Lg.testo).foregroundColor(Lg.colore)
        }
    }
}

// MARK: - La crescita

struct PannelloCrescita: View {
    let crescita: CrescitaTerritorio

    @Environment(StatoShell.self) private var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaStatoFinale) private var fermo

    private typealias Mo = Tema.Apple.Territorio.Moto

    var body: some View {
        let t = stato.territorio
        VStack(alignment: .leading, spacing: P.spazio) {
            EtichettaPannello(testo: "LA CRESCITA")
            if let primo = crescita.anni.first, let ultimo = crescita.anni.last {
                let anno = t.annoCrescita.map { min(max($0, primo.anno), ultimo.anno) } ?? ultimo.anno
                let a = crescita.anni.first { $0.anno == anno } ?? ultimo
                Text(verbatim: "\(anno)")
                    .carattereApple(P.anno)
                    .foregroundColor(P.coloreTesto)
                    .contentTransition(.numericText())
                HStack(alignment: .top, spacing: P.spazioSezione) {
                    VStack(alignment: .leading, spacing: P.spazioRigheLargo) {
                        NumeroCheConta(Double(a.clienti), formato: .intero, da: nil, durataCambio: Mo.conteggio)
                            .carattereApple(P.valoreCrescita)
                            .foregroundColor(P.coloreTesto)
                        Text(a.clienti == 1 ? "cliente" : "clienti").carattereApple(P.piccolo).foregroundColor(P.coloreTesto2)
                    }
                    VStack(alignment: .leading, spacing: P.spazioRigheLargo) {
                        if let p = a.patrimonio {
                            NumeroCheConta(p, formato: .euro, da: nil, durataCambio: Mo.conteggio)
                                .carattereApple(P.valoreCrescita)
                                .foregroundColor(P.coloreTesto)
                            Text("seguiti").carattereApple(P.piccolo).foregroundColor(P.coloreTesto2)
                        } else {
                            Text("patrimonio di quell'anno non disponibile")
                                .carattereApple(P.piccolo)
                                .foregroundColor(P.coloreTesto2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if primo.anno < ultimo.anno {
                    CursoreApple(valore: Binding(get: { Double(anno) }, set: { v in
                                     t.fermaCrescita()
                                     t.annoCrescita = Int(v.rounded())
                                 }),
                                 intervallo: Double(primo.anno)...Double(ultimo.anno), passo: 1, etichetta: "Anno della crescita")
                        .padding(.vertical, P.spazioCursore)
                    Button {
                        let parti = anno >= ultimo.anno ? primo.anno : anno
                        t.annoCrescita = parti
                        t.avviaCrescita(primo: parti, ultimo: ultimo.anno, attesa: 0, passo: calmo ? Mo.passoAnnoCalmo : Mo.passoAnno)
                    } label: {
                        Text("▶︎ Guarda la crescita")
                    }
                    .buttonStyle(.applePrimarioGrande)
                    .disabled(t.crescitaInCorso)
                }
                Text("Ogni luce che si accende è una famiglia che ha cominciato con te.")
                    .carattereApple(P.testo)
                    .foregroundColor(P.coloreTesto2)
                    .fixedSize(horizontal: false, vertical: true)
                if crescita.stimati > 0 {
                    Text(crescita.stimati == 1 ? String("1 cliente ha l'anno d'inserimento in Prisma, non quello d'inizio.")
                                               : String("\(crescita.stimati) clienti hanno l'anno d'inserimento in Prisma, non quello d'inizio."))
                        .carattereApple(P.piccolo)
                        .foregroundColor(P.coloreTesto3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            } else {
                Text("Nessun cliente è ancora sulla mappa.")
                    .carattereApple(P.testo)
                    .foregroundColor(P.coloreTesto)
                Spacer(minLength: 0)
            }
        }
        .onAppear(perform: avvio)
        .onDisappear { stato.territorio.fermaCrescita() }
    }

    /// Partenza da sola 0,7 s dopo l'entrata, solo la prima volta; con calmo (o nelle istantanee) si vede l'ultimo anno.
    private func avvio() {
        let t = stato.territorio
        guard !t.avvioCrescitaFatto, let primo = crescita.anni.first?.anno, let ultimo = crescita.anni.last?.anno else { return }
        t.avvioCrescitaFatto = true
        guard !fermo, primo < ultimo else { return }
        t.annoCrescita = primo
        t.avviaCrescita(primo: primo, ultimo: ultimo, attesa: Mo.attesaAvvio, passo: Mo.passoAnno)
    }
}

// MARK: - Il giro di domani

struct PannelloGiro: View {
    let giro: GiroGiorno
    let partenza: PartenzaGiro?

    @Environment(StatoShell.self) private var stato

    private static let giornoNumero = Formati.formato("EEEE d")

    var body: some View {
        VStack(alignment: .leading, spacing: P.spazio) {
            testata
            if giro.vuoto {
                vuoto
            } else {
                Text(titoloGiro)
                    .carattereApple(P.titoloGiro)
                    .foregroundColor(P.coloreTesto)
                Text("circa \(durata(giro.minuti)) in auto · stima in linea d'aria")
                    .carattereApple(P.piccolo)
                    .foregroundColor(P.coloreTesto2)
                if let partenza {
                    Text(partenza.descrizione).carattereApple(P.piccolo).foregroundColor(P.coloreTesto3)
                } else {
                    senzaPartenza
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: G.spazioRighe) {
                        ForEach(Array(giro.tappe.enumerated()), id: \.element.id) { i, t in
                            riga(t, indice: i)
                        }
                        note
                    }
                }
                if let s = giro.suggerimenti.first { lungoLaStrada(s) }
                ForEach(giro.suggerimenti.dropFirst()) { s in altroSuggerimento(s) }
            }
        }
    }

    // MARK: Testata con le frecce

    private var testata: some View {
        let cal = Calendar.current
        let domani = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
        let titolo = cal.isDate(giro.giorno, inSameDayAs: domani)
            ? "IL GIRO DI DOMANI · \(Self.giornoNumero.string(from: giro.giorno).uppercased())"
            : "IL GIRO DI \(Self.giornoNumero.string(from: giro.giorno).uppercased())"
        return HStack(spacing: P.spazio) {
            EtichettaPannello(testo: titolo)
            Spacer(minLength: 0)
            Button { sposta(-1) } label: { Text("‹") }
                .buttonStyle(.appleSobrio)
                .accessibilityLabel("Giorno prima")
            Button { sposta(1) } label: { Text("›") }
                .buttonStyle(.appleSobrio)
                .accessibilityLabel("Giorno dopo")
        }
    }

    private func sposta(_ giorni: Int) {
        let cal = Calendar.current
        stato.territorio.rigaNuovaId = nil
        stato.territorio.giornoGiro = cal.date(byAdding: .day, value: giorni, to: giro.giorno)
    }

    // MARK: Stati

    private var vuoto: some View {
        VStack(alignment: .leading, spacing: P.spazio) {
            Text(Calendar.current.isDateInTomorrow(giro.giorno) ? "Domani non hai visite fuori studio." : "Questo giorno non hai visite fuori studio.")
                .carattereApple(P.testo)
                .foregroundColor(P.coloreTesto)
            if let p = giro.prossimoGiorno {
                Button("Il prossimo giro: \(Self.giornoNumero.string(from: p))") { stato.territorio.giornoGiro = p }
                    .buttonStyle(.apple)
            }
            note
            Spacer(minLength: 0)
        }
    }

    private var senzaPartenza: some View {
        VStack(alignment: .leading, spacing: P.spazio / 2) {
            Text("Aggiungi l'indirizzo dello studio per contare anche l'andata e il ritorno.")
                .carattereApple(P.piccolo)
                .foregroundColor(P.coloreTesto2)
                .fixedSize(horizontal: false, vertical: true)
            Button("Impostazioni › Territorio") {
                stato.schedaImpostazioni = .territorio
                stato.apri(.impostazioni)
            }
            .buttonStyle(.appleSobrio)
        }
    }

    @ViewBuilder private var note: some View {
        ForEach(giro.luogoDaIndicare) { a in
            HStack(spacing: P.spazio) {
                VStack(alignment: .leading, spacing: P.spazioRighe) {
                    Text(nomeCliente(a.clienteId)).carattereApple(P.testoForte).foregroundColor(P.coloreTesto)
                    Text("\(Formati.ora.string(from: a.inizio)) · luogo da indicare").carattereApple(P.piccolo).foregroundColor(P.coloreTesto2)
                }
                Spacer(minLength: 0)
                Button("Dove sarà?") { stato.apriAppuntamentoInAgenda(a) }
                    .buttonStyle(.appleSobrio)
            }
        }
        if giro.altrove > 0 {
            Text(giro.altrove == 1 ? String("1 visita altrove non è nel giro.") : String("\(giro.altrove) visite altrove non sono nel giro."))
                .carattereApple(P.piccolo)
                .foregroundColor(P.coloreTesto3)
        }
        if !giro.senzaLuogo.isEmpty {
            Text(giro.senzaLuogo.count == 1 ? String("1 visita è da un cliente che non è sulla mappa.")
                                            : String("\(giro.senzaLuogo.count) visite sono da clienti che non sono sulla mappa."))
                .carattereApple(P.piccolo)
                .foregroundColor(P.coloreTesto3)
        }
    }

    // MARK: Le tappe

    private func nomeCliente(_ id: String) -> String {
        stato.dati.clienti.first { $0.id == id }?.nome ?? "Cliente"
    }

    /// L'ora della tappa: la visita ha la sua; la partenza è la prima visita meno il tratto; il rientro l'ultima più il tratto.
    private func ora(_ t: TappaGiro, indice i: Int) -> Date? {
        switch t.genere {
        case .visita: return t.appuntamento?.inizio
        case .partenza:
            guard giro.tappe.indices.contains(i + 1), let a = giro.tappe[i + 1].appuntamento else { return nil }
            return a.inizio.addingTimeInterval(-TimeInterval(giro.tappe[i + 1].minutiDaPrima * 60))
        case .rientro:
            guard i > 0, let a = giro.tappe[i - 1].appuntamento else { return nil }
            return a.fine.addingTimeInterval(TimeInterval(t.minutiDaPrima * 60))
        }
    }

    @ViewBuilder private func riga(_ t: TappaGiro, indice i: Int) -> some View {
        let nuova = t.appuntamento.map { $0.id == stato.territorio.rigaNuovaId || $0.daConfermare == true } ?? false
        let contenuto = HStack(alignment: .center, spacing: P.spazio) {
            Text(ora(t, indice: i).map { Formati.ora.string(from: $0) } ?? "")
                .carattereApple(G.ora)
                .foregroundColor(P.coloreTesto2)
                .frame(width: G.larghezzaOra, alignment: .leading)
            if let c = t.cliente {
                AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: G.avatar)
            } else {
                Text(G.casa)
                    .carattereApple(G.casaCarattere)
                    .foregroundColor(P.coloreTesto2)
                    .frame(width: G.avatar, height: G.avatar)
            }
            VStack(alignment: .leading, spacing: P.spazioRighe) {
                Text(t.cliente?.nome ?? (t.genere == .partenza ? "Partenza" : "Rientro"))
                    .carattereApple(G.nome)
                    .foregroundColor(P.coloreTesto)
                    .lineLimit(1)
                Text(motivo(t))
                    .carattereApple(G.motivo)
                    .foregroundColor(P.coloreTesto2)
                    .lineLimit(1)
                if nuova {
                    Text("✓ Conferma in Agenda")
                        .carattereApple(G.motivo)
                        .foregroundColor(G.titoloSuggerimento)
                }
            }
            Spacer(minLength: 0)
            if giro.tappe.indices.contains(i + 1) {
                Text("\(giro.tappe[i + 1].minutiDaPrima) min ›")
                    .carattereApple(G.tratto)
                    .foregroundColor(P.coloreTesto3)
            }
        }
        .padding(G.paddingRiga)
        .background(RoundedRectangle(cornerRadius: G.raggioRigaNuova, style: .continuous).fill(nuova ? G.fondoRigaNuova : Color.clear))
        if let a = t.appuntamento {
            Button { stato.apriAppuntamentoInAgenda(a) } label: { contenuto.contentShape(Rectangle()) }
                .buttonStyle(.plain)
        } else {
            contenuto
        }
    }

    private func motivo(_ t: TappaGiro) -> String {
        switch t.genere {
        case .partenza: return "partenza"
        case .rientro: return "rientro"
        case .visita:
            let titolo = t.appuntamento?.titolo.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return titolo.isEmpty ? (t.appuntamento?.tipo.nome ?? "visita") : titolo
        }
    }

    // MARK: Lungo la strada

    private func fra(_ s: SuggerimentoGiro) -> String {
        let a = giro.tappe.indices.contains(s.dopoTappa) ? giro.tappe[s.dopoTappa].cliente.map(MotoreTerritorio.nomeBattesimo) : nil
        let b = giro.tappe.indices.contains(s.primaDiTappa) ? giro.tappe[s.primaDiTappa].cliente.map(MotoreTerritorio.nomeBattesimo) : nil
        guard let a, let b else { return "" }
        return " tra \(a) e \(b)"
    }

    private func lungoLaStrada(_ s: SuggerimentoGiro) -> some View {
        let nome = MotoreTerritorio.nomeBattesimo(s.cliente)
        let minuti = s.deviazioneMinuti == 1 ? "1 minuto" : "\(s.deviazioneMinuti) minuti"
        return VStack(alignment: .leading, spacing: P.spazio) {
            Text("LUNGO LA STRADA")
                .carattereApple(P.etichetta)
                .foregroundColor(G.titoloSuggerimento)
            (Text(s.cliente.nome).bold() + Text(" è a \(minuti)\(fra(s)): \(s.motivo)."))
                .carattereApple(P.testo)
                .foregroundColor(P.coloreTesto)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: P.spazio) {
                Button("＋ Aggiungi \(nome) al giro") { stato.aggiungiAlGiro(s) }
                    .buttonStyle(.applePrimario)
                if s.tipoVoce == .conformita {
                    Button("Scrivi a \(nome)") { stato.preparaMessaggio(clienteId: s.cliente.id) }
                        .buttonStyle(.appleSobrio)
                }
            }
        }
        .padding(P.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: P.raggioTile, style: .continuous).fill(G.fondoSuggerimento))
        .overlay(RoundedRectangle(cornerRadius: P.raggioTile, style: .continuous).stroke(G.bordoSuggerimento, lineWidth: P.spessoreBordoTile))
    }

    private func altroSuggerimento(_ s: SuggerimentoGiro) -> some View {
        let nome = MotoreTerritorio.nomeBattesimo(s.cliente)
        return HStack(spacing: P.spazio) {
            VStack(alignment: .leading, spacing: P.spazioRighe) {
                Text(s.cliente.nome).carattereApple(P.testoForte).foregroundColor(P.coloreTesto)
                Text("\(s.deviazioneMinuti) min in più · \(s.motivo)").carattereApple(P.piccolo).foregroundColor(P.coloreTesto2).lineLimit(2)
            }
            Spacer(minLength: 0)
            Button("＋ Aggiungi \(nome) al giro") { stato.aggiungiAlGiro(s) }
                .buttonStyle(.apple)
        }
    }

    // MARK: Testi delle stime

    private var titoloGiro: String {
        let visite = giro.visite == 1 ? "1 visita" : "\(giro.visite) visite"
        return "\(visite) · circa \(km(giro.km))"
    }

    private func km(_ v: Double) -> String { "\(Int(v.rounded())) km" }

    private func durata(_ minuti: Int) -> String {
        minuti < 60 ? "\(minuti) min" : String(format: "%d h %02d", minuti / 60, minuti % 60)
    }
}

// MARK: - I clienti non sulla mappa

struct ElencoSenzaLuogo: View {
    let senzaLuogo: [ClienteSenzaLuogo]

    @Environment(StatoShell.self) private var stato

    var body: some View {
        VStack(alignment: .leading, spacing: P.spazioSezione) {
            HStack {
                Text(testoNonSullaMappa(senzaLuogo.count))
                    .carattereApple(P.titoloGiro)
                    .foregroundColor(P.coloreTesto)
                Spacer()
                Button("Fine") { stato.territorio.elencoSenzaLuogo = false }
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
            }
            Text("Prisma riconosce il comune nell'indirizzo (con la sigla per i comuni con lo stesso nome) oppure usa la posizione che metti a mano. Il CAP non serve.")
                .carattereApple(P.piccolo)
                .foregroundColor(P.coloreTesto2)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                VStack(alignment: .leading, spacing: P.spazio) {
                    ForEach(senzaLuogo) { s in
                        HStack(alignment: .top, spacing: P.spazio) {
                            AvatarCliente(iniziali: s.cliente.iniziali, tinta: s.cliente.tinta.colori, lato: P.avatar)
                            VStack(alignment: .leading, spacing: P.spazioRigheLargo) {
                                Text(s.cliente.nome).carattereApple(P.testoForte).foregroundColor(P.coloreTesto)
                                Text(s.cliente.indirizzo.isEmpty ? "—" : s.cliente.indirizzo)
                                    .carattereApple(P.piccolo).foregroundColor(P.coloreTesto2)
                                Text(s.motivo.testo).carattereApple(P.piccolo).foregroundColor(P.testoDaFare)
                            }
                            Spacer(minLength: 0)
                            VStack(alignment: .trailing, spacing: P.spazioRigheLargo) {
                                Button("Apri l'anagrafica") {
                                    stato.territorio.elencoSenzaLuogo = false
                                    stato.clienteAttivoId = s.cliente.id
                                    stato.schedaCliente = .anagrafica
                                    stato.apri(.clienti)
                                }
                                .buttonStyle(.appleSobrio)
                                Button("Mettilo a mano") {
                                    stato.territorio.elencoSenzaLuogo = false
                                    stato.apriTerritorioSposta(s.cliente.id)
                                }
                                .buttonStyle(.appleSobrio)
                            }
                        }
                    }
                }
            }
        }
        .padding(P.padding)
        .frame(minWidth: P.larghezza + P.larghezza / 2, minHeight: P.larghezza)
    }
}

// MARK: - La riga «Posizione sulla mappa» del dossier

/// Nell'anagrafica del dossier, sotto «Indirizzo»: da dove viene la posizione sulla mappa, con «Mettila a mano» (apre
/// Territorio in modalità «Sposta») o «Togli la posizione a mano». La tabella si legge al primo uso, fuori dal `body`.
struct RigaPosizioneMappa: View {
    let cliente: Cliente

    @Environment(StatoShell.self) private var stato

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tema.Misura.Componenti.rigaCampo * 2) {
            Text("Posizione sulla mappa")
                .font(Tema.Testo.corpo)
                .foregroundColor(Tema.Colore.inchiostroSecondario)
                .frame(width: Tema.Misura.Componenti.etichettaCampo, alignment: .leading)
            Text(testo)
                .font(Tema.Testo.corpo)
                .foregroundColor(Tema.Colore.inchiostro)
                .frame(maxWidth: .infinity, alignment: .leading)
            if cliente.luogo != nil {
                Button("Togli la posizione a mano") { stato.impostaLuogoManuale(cliente.id, nil) }
                    .buttonStyle(.appleSobrio)
            } else {
                Button("Mettila a mano") { stato.apriTerritorioSposta(cliente.id) }
                    .buttonStyle(.appleSobrio)
            }
        }
        .padding(.vertical, Tema.Misura.Componenti.rigaCampo)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Tema.Colore.separatore).frame(height: Tema.Misura.filo)
        }
        .task { stato.territorio.caricaSeServe() }
    }

    private var testo: String {
        if cliente.luogo != nil {
            return cliente.luogo?.nota == TerritorioDiProva.nota ? "a mano · dati di prova" : "a mano"
        }
        guard let t = stato.territorio.tabella else { return "posizione dal comune dell'indirizzo" }
        let r = MotoreTerritorio.luoghi(clienti: [cliente], tabella: t, zone: [])
        if let l = r.luoghi[cliente.id], let c = l.comune { return "dal comune di \(c.nome)" }
        if let s = r.senzaLuogo.first { return "non sulla mappa: \(s.motivo.testo)" }
        return "non sulla mappa"
    }
}
