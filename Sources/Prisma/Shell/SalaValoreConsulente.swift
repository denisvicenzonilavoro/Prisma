import SwiftUI

// Quanto vale avermi accanto (Design/template-luce-specifica.md §4.4, «Luce» giro 8): il lavoro fatto con il cliente,
// in cifre, dai motori di Prisma.
//
//   IL LAVORO INSIEME · DA NOVEMBRE 2025                                                    (testo di prova)
//   In un anno il nostro lavoro vale circa 9.030 €.
//   ┌ Tasse risparmiate ┐┌ Costi tagliati ┐┌ Rispetto all'alternativa ┐┌ E in più, protetto ┐
//   │ 4.860 €           ││ 2.310 €        ││ 1.860 €                  ││ 150.000 €          │
//   │ spiegazione       ││ …              ││ …                        ││ …                  │
//   │ Alleanza · Indip. ││                ││                          ││                    │
//   └───────────────────┘└────────────────┘└──────────────────────────┘└────────────────────┘
//   ( Dall'inizio | Ultimi 12 mesi )                                    [ Metti nel riesame ]
//   VALORE E COMPENSO, A CONFRONTO                       ┌───────────────────────────────┐
//   Il valore portato     ██████████████████  9.030 €     │ Per ogni euro di compenso,    │
//   Il compenso           ████▌██             3.600 €     │ circa 2,5 euro di valore.     │
//                         (Alleanza · indipendente)       └───────────────────────────────┘
//   Stime basate su ipotesi, non garanzie di risultato.   └───────────────────────────────┘
//
// - Le cifre vengono da `MotoreValoreConsulente` (decisioni 58 e 85): solo ciò che è nato dalle raccomandazioni
//   accettate dopo l'inizio del rapporto, compenso diviso per canale, «Valore e costi» per i clienti solo Alleanza.
// - Titolo e avvertenza li scrive o approva l'utente (Impostazioni › Sala): finché non lo fa restano il titolo del
//   template segnato «testo di prova» e il segnaposto dichiarato della decisione 56.
// - Nessun pulsante a destra del palco: l'esperienza non va sul tavolo né nel Prisma del cliente; le cifre restano per il
//   consulente. «Metti nel riesame» (decisione 18, facoltativo) la porta nel prospetto del riesame, che è per lui: finché
//   non lo sceglie il riesame non la mostra. Il periodo «Dall'inizio · Ultimi 12 mesi» (§4.4.4). Un clic su un riquadro
//   apre il dettaglio delle voci; Esc chiude prima il dettaglio, poi il palco.
// - Movimento: cascata dei riquadri, cifre contate, barre che si allungano. «Riduci movimento» e istantanee: fermo.

extension StatoShell {
    /// Il valore del lavoro con un cliente, ricordato finché i dati non cambiano (il track record ricostruisce i
    /// versamenti: non si rifà a ogni disegno).
    func valoreConsulente(_ c: Cliente, periodo: PeriodoValore = .inizio) -> ValoreConsulente {
        let oggi = Calendar.current.startOfDay(for: Date())
        let chiave = "\(c.id)-\(periodo.rawValue)-\(versioneDati)-\(oggi.timeIntervalSinceReferenceDate)"
        if let m = sala.memoValore, m.chiave == chiave { return m.valore }
        let v = MotoreValoreConsulente.calcola(cliente: c, posizioni: posizioniCliente(c.id),
                                               raccomandazioni: dati.raccomandazioni.filter { $0.clienteId == c.id },
                                               schede: dati.schedeAdeguatezza.filter { $0.clienteId == c.id },
                                               parcelle: dati.parcelle.filter { $0.clienteId == c.id },
                                               studio: dati.impostazioni.studio,
                                               tabella: TabellaRiferimenti(dati.impostazioni.riferimenti), oggi: Date(),
                                               periodo: periodo)
        sala.memoValore = (chiave, v)
        return v
    }

    /// «Quanto vale avermi accanto» va nel riesame di questo cliente solo se il consulente l'ha messo (decisione 18).
    func valoreNelRiesame(_ id: String) -> Bool { sala.valoreNelRiesame.contains(id) }

    func mettiValoreNelRiesame(_ id: String, _ si: Bool) {
        if si { sala.valoreNelRiesame.insert(id) } else { sala.valoreNelRiesame.remove(id) }
    }
}

/// Il contenuto del palco per «Quanto vale avermi accanto».
struct ValoreConsulenteVista: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    var modificabile = true

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo
    @State private var aperto: TipoVoceAperta?

    private typealias V = Tema.Apple.SalaEsperienze.Valore

    var body: some View {
        let _ = ContaCorpi.segna()
        let nome = StatoShell.nomeBreve(cliente)
        let periodo = stato.sala.periodoValore
        let v = stato.valoreConsulente(cliente, periodo: periodo)
        let sala = stato.dati.impostazioni.sala
        let dettaglio = aperto ?? (istantanea ? stato.sala.valoreDettaglioIstantanea.map(TipoVoceAperta.voce) : nil)
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                testa(v, nome: nome, sala: sala)
                    .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                if !v.presto && modificabile {
                    comandi()
                        .padding(.top, V.sopraComandi)
                        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
                riquadri(v, nome: nome)
                    .padding(.top, V.sopraRiquadri)
                if !v.presto, v.totale != nil {
                    confronto(v)
                        .padding(.top, V.sopraConfronto)
                        .entrataCascata(6, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
                Spacer(minLength: 0)
                nota(v, sala: sala)
                    .padding(.top, V.sopraNota)
            }
            .padding(V.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            if let dettaglio {
                V.veloDettaglio
                    .contentShape(Rectangle())
                    .onTapGesture { chiudi() }
                    .transition(.opacity)
                DettaglioValoreVista(titolo: dettaglio.titolo, righe: righe(dettaglio, v), nota: notaDettaglio(dettaglio, v),
                                     chiudi: chiudi)
                    .transition(calmo || istantanea ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .onDisappear { stato.sala.dettaglioValoreAperto = false }
    }

    // MARK: Periodo e riesame

    private func comandi() -> some View {
        let nelRiesame = stato.valoreNelRiesame(cliente.id)
        return HStack(spacing: V.spazioComandi) {
            SegmentatoPillola(selezione: Binding(get: { stato.sala.periodoValore }, set: { stato.sala.periodoValore = $0 }),
                              valori: PeriodoValore.allCases, titolo: \.titolo)
                .fixedSize()
                .help("Il valore dall’inizio del rapporto o solo degli ultimi 12 mesi")
            Spacer(minLength: V.spazioComandi)
            Button { stato.mettiValoreNelRiesame(cliente.id, !nelRiesame) } label: {
                Text(nelRiesame ? "✓ Nel riesame" : "Metti nel riesame")
            }
            .buttonStyle(.apple)
            .help(nelRiesame ? "Il prospetto del riesame (per te) mostra queste cifre: premi per toglierle"
                  : "Porta queste cifre nel prospetto del riesame, che è per te: niente parte verso il cliente")
        }
    }

    // MARK: Testa

    private func testa(_ v: ValoreConsulente, nome: String, sala: ImpostazioniSala) -> some View {
        let da = Formati.meseAnno.string(from: v.dal)
        let origine: String
        switch v.inizio {
        case .clienteDal: origine = "da \(da)"
        case .primaRaccomandazione: origine = "dalla prima raccomandazione accettata, \(da)"
        case .scheda: origine = "da \(da), dalla scheda"
        }
        return VStack(alignment: .leading, spacing: V.sopraTitolo) {
            HStack(spacing: Tema.Apple.Studio.Card.spazioProva) {
                Text("Il lavoro insieme · \(origine)")
                    .carattereApple(V.etichetta)
                    .foregroundColor(V.coloreEtichetta)
                    .lineLimit(1)
                if StatoShell.clientiDiProva.contains(cliente.id) && stato.haDatiDiProva {
                    Text("dati di prova").carattereApple(V.prova).foregroundColor(V.coloreProva)
                }
                if sala.titoloValore == nil && !v.presto && v.totale != nil {
                    Text("testo di prova").carattereApple(V.prova).foregroundColor(V.coloreProva)
                        .help("Il titolo è quello del template: scrivilo o approvalo in Impostazioni › Sala (decisione 58)")
                }
            }
            if v.presto || v.totale == nil {
                Text(v.presto ? "Ne parleremo al primo riesame: oggi è presto per misurare." : "Il lavoro con \(nome) non ha ancora cifre da misurare.")
                    .carattereApple(V.testoPresto)
                    .foregroundColor(V.coloreTitolo)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: V.larghezzaPresto, alignment: .leading)
            } else if let totale = v.totale {
                titolo(totale, v: v, modello: sala.titoloValore ?? ImpostazioniSala.titoloValoreDiProva)
            }
        }
    }

    /// Il titolo con la cifra in blu che si conta: il testo dell'utente (o di prova) diviso attorno a {valore}.
    @ViewBuilder
    private func titolo(_ totale: Double, v: ValoreConsulente, modello: String) -> some View {
        let periodo = MotoreValoreConsulente.periodo(mesi: v.mesi)
        let base = modello.replacingOccurrences(of: "{periodo}", with: periodo)
        let parti = base.components(separatedBy: "{valore}")
        let primaPulita: String = {
            let prima = parti.first ?? base
            guard v.parziale, parti.count > 1 else { return prima }
            return prima.hasSuffix("circa ") ? String(prima.dropLast("circa ".count)) + "almeno " : prima + "almeno "
        }()
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(primaPulita)
            if parti.count > 1 {
                NumeroCheConta(totale)
                    .foregroundColor(V.coloreCifra)
                Text(parti.dropFirst().joined(separator: ""))
            }
        }
        .carattereApple(V.titolo)
        .foregroundColor(V.coloreTitolo)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
    }

    // MARK: I riquadri

    private func riquadri(_ v: ValoreConsulente, nome: String) -> some View {
        HStack(alignment: .top, spacing: V.spazioRiquadri) {
            if !v.presto {
                ForEach(Array(v.voci.enumerated()), id: \.element.tipo) { i, voce in
                    riquadro(titolo: voce.tipo.titolo, cifra: voce.totale, spiegazione: spiegazione(voce),
                             assente: voce.motivoAssente, perCanale: voce.totale == nil ? [:] : voce.perCanale, indice: i + 1,
                             apri: voce.dettagli.isEmpty ? nil : .voce(voce.tipo))
                        .entrataCascata(2 + i, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
            }
            riquadro(titolo: "E in più, protetto", cifra: v.protetto,
                     spiegazione: "di capitale per la famiglia, se succede qualcosa (non entra nel totale)",
                     assente: v.protetto == nil ? "Nessuna copertura caso morte nata dal consiglio" : nil, perCanale: [:],
                     indice: 4, apri: v.protettoDettagli.isEmpty ? nil : .protetto)
                .entrataCascata(5, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                .frame(maxWidth: v.presto ? V.larghezzaPresto / 2 : .infinity)
            if v.presto { Spacer(minLength: 0) }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func spiegazione(_ voce: VoceValore) -> String {
        switch voce.tipo {
        case .tasse: return "deduzioni dei fondi pensione e detrazioni delle polizze nati dal consiglio (stima con il reddito di oggi)"
        case .costi: return "posizioni più care sostituite, sul valore di oggi per gli anni passati"
        case .alternativa: return "le scelte fatte insieme rispetto all’alternativa, dal track record (stima)"
        }
    }

    private func riquadro(titolo: String, cifra: Double?, spiegazione: String, assente: String?, perCanale: [Canale: Double],
                          indice: Int, apri: TipoVoceAperta?) -> some View {
        let contenuto = VStack(alignment: .leading, spacing: 0) {
            Text(titolo)
                .carattereApple(V.etichettaRiquadro)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            if let cifra {
                NumeroCheConta(cifra, indice: indice)
                    .carattereApple(V.cifra)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(spiegazione)
                    .carattereApple(V.spiegazione)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, V.sopraSpiegazione)
                if let assente {
                    Text(assente)
                        .carattereApple(V.spiegazione)
                        .foregroundColor(V.coloreAssente)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, V.sopraSpiegazione)
                }
                if perCanale.count > 1 || (perCanale.count == 1 && perCanale.keys.first != nil) {
                    HStack(spacing: V.sopraSpiegazione * 2) {
                        ForEach(Canale.allCases.filter { perCanale[$0] != nil }, id: \.self) { c in
                            HStack(spacing: V.sopraSpiegazione) {
                                EtichettaCanaleApple(canale: c, compatta: true)
                                Text(Formati.euro(perCanale[c] ?? 0))
                                    .carattereApple(V.canali)
                                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                            }
                        }
                    }
                    .padding(.top, V.sopraCanali)
                }
            } else {
                Text(assente ?? "Nessun dato")
                    .carattereApple(V.assente)
                    .foregroundColor(V.coloreAssente)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, V.sopraSpiegazione * 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(V.paddingRiquadro)
        .superficieApple(V.superficieRiquadro, raggio: V.raggioRiquadro)
        .contentShape(RoundedRectangle(cornerRadius: V.raggioRiquadro, style: .continuous))
        return Group {
            if let apri, modificabile {
                Button { apriDettaglio(apri) } label: { contenuto }
                    .buttonStyle(StileSemplice())
                    .help("Le voci che compongono la cifra")
            } else {
                contenuto
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Il confronto con il compenso

    private func confronto(_ v: ValoreConsulente) -> some View {
        let totale = v.totale ?? 0
        let compenso = v.compenso
        let scala = max(totale, compenso, 1)
        return HStack(alignment: .bottom, spacing: V.spazioConfronto) {
            VStack(alignment: .leading, spacing: V.spazioBarre) {
                Text(v.soloAlleanza && v.parcellePagate == 0 ? "Valore e costi, a confronto" : "Valore e compenso, a confronto")
                    .carattereApple(V.etichetta)
                    .foregroundColor(V.coloreEtichetta)
                barra("Il valore portato", valore: totale, frazione: totale / scala, colore: V.coloreValore, indice: 0)
                // Una sola barra del compenso, a due segmenti nei colori dei canali (§4.4.2)
                barraCompenso(v, scala: scala)
                if v.provvigioniNonStimate {
                    Text("Provvigioni Alleanza non stimate: scrivi le aliquote in Impostazioni › Studio.")
                        .carattereApple(V.nota)
                        .foregroundColor(V.coloreNota)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if let r = v.rapporto {
                    Text(v.rapportoSoloParcelle
                         ? "Per ogni euro di parcella, circa \(rapporto(r)) euro di valore\(r < 1 ? " misurabile" : "") sul canale indipendente."
                         : "Per ogni euro di \(v.provvigioniStimate == nil ? "parcella" : "compenso"), circa \(rapporto(r)) euro di valore\(r < 1 ? " misurabile" : "").")
                        .carattereApple(V.rapporto)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                } else {
                    // Stato vuoto: una nota, non la frase grande del rapporto
                    Text("Nessun compenso registrato: il rapporto non si calcola.")
                        .carattereApple(V.nota)
                        .foregroundColor(V.coloreNota)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(V.paddingRapporto)
            .frame(width: V.larghezzaRapporto, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: V.raggioRapporto, style: .continuous).fill(V.fondoRapporto))
            .overlay(RoundedRectangle(cornerRadius: V.raggioRapporto, style: .continuous).strokeBorder(V.filoRapporto, lineWidth: V.filoRapportoSpessore))
        }
    }

    private func barraCompenso(_ v: ValoreConsulente, scala: Double) -> some View {
        let provvigioni = v.provvigioniStimate ?? 0
        let titolo = v.soloAlleanza && v.parcellePagate == 0 ? "I costi (provvigioni)" : "Il compenso"
        return HStack(spacing: V.spazioBarre) {
            Text(titolo)
                .carattereApple(V.etichettaBarra)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .frame(width: V.larghezzaEtichetta, alignment: .leading)
            BarraPienaSegmenti(pezzi: [
                PezzoBarraPiena(id: "alleanza", peso: provvigioni, colore: V.coloreAlleanza),
                PezzoBarraPiena(id: "indipendente", peso: v.parcellePagate, colore: V.coloreIndipendente),
                // Il resto fino alla scala del valore, vuoto: la barra è lunga quanto il compenso
                PezzoBarraPiena(id: "resto", peso: max(0, scala - provvigioni - v.parcellePagate), colore: V.coloreResto),
            ], indice: 1, altezza: V.altezzaBarra, spazio: V.spazioSegmenti, raggioPezzo: V.raggioBarra, raggioContenitore: V.raggioBarra)
            Text(Formati.euro(v.compenso))
                .carattereApple(V.cifraBarra)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .frame(width: V.larghezzaCifra, alignment: .trailing)
        }
        .help("Alleanza (provvigioni stimate) \(Formati.euro(provvigioni)) · Indipendente (parcelle) \(Formati.euro(v.parcellePagate))")
    }

    private func barra(_ etichetta: String, valore: Double, frazione: Double, colore: Color, indice: Int) -> some View {
        HStack(spacing: V.spazioBarre) {
            Text(etichetta)
                .carattereApple(V.etichettaBarra)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .frame(width: V.larghezzaEtichetta, alignment: .leading)
            BarraPiena(frazione: frazione, colore: colore, indice: indice, altezza: V.altezzaBarra, raggio: V.raggioBarra, binario: nil)
            Text(Formati.euro(valore))
                .carattereApple(V.cifraBarra)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .frame(width: V.larghezzaCifra, alignment: .trailing)
        }
    }

    private func rapporto(_ r: Double) -> String {
        String(format: "%.1f", r).replacingOccurrences(of: ".", with: ",")
    }

    private func nota(_ v: ValoreConsulente, sala: ImpostazioniSala) -> some View {
        let a = ImpostazioniSala.avvertenza(sala.avvertenzaValore)
        return Text("Stime dai motori di Prisma e dal track record, solo per ciò che è nato dalle raccomandazioni accettate. " + a.testo)
            .carattereApple(V.nota)
            .foregroundColor(V.coloreNota)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Il dettaglio

    private func righe(_ d: TipoVoceAperta, _ v: ValoreConsulente) -> [DettaglioValore] {
        switch d {
        case .voce(let t): return v.voce(t)?.dettagli ?? []
        case .protetto: return v.protettoDettagli
        }
    }

    private func notaDettaglio(_ d: TipoVoceAperta, _ v: ValoreConsulente) -> String? {
        switch d {
        case .voce(.alternativa): return "Il dettaglio di ogni raccomandazione è in Studio › Track record."
        case .voce(let t): return v.voce(t)?.motivoAssente
        case .protetto: return nil
        }
    }

    private func apriDettaglio(_ d: TipoVoceAperta) {
        // Esc della Sala si mette da parte finché il dettaglio è aperto: Esc chiude prima il dettaglio (§1.4.4)
        stato.sala.dettaglioValoreAperto = true
        withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : Tema.Apple.Moto.SalaEsperienze.passaggio) { aperto = d }
    }

    private func chiudi() {
        stato.sala.dettaglioValoreAperto = false
        withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : Tema.Apple.Moto.SalaEsperienze.ritorno) { aperto = nil }
    }
}

/// Quale dettaglio è aperto.
enum TipoVoceAperta: Equatable {
    case voce(TipoVoceValore)
    case protetto

    var titolo: String {
        switch self {
        case .voce(let t): return t.titolo
        case .protetto: return "E in più, protetto"
        }
    }
}

/// Il dettaglio di una voce: le righe che compongono la cifra.
private struct DettaglioValoreVista: View {
    let titolo: String
    let righe: [DettaglioValore]
    let nota: String?
    let chiudi: () -> Void

    private typealias V = Tema.Apple.SalaEsperienze.Valore

    var body: some View {
        VStack(alignment: .leading, spacing: V.fraRighe) {
            HStack {
                Text(titolo)
                    .carattereApple(V.titoloDettaglio)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Spacer()
                Button("Chiudi", action: chiudi)
                    .buttonStyle(.apple)
                    .keyboardShortcut(.cancelAction)
            }
            ForEach(righe) { r in
                HStack(alignment: .firstTextBaseline, spacing: V.fraRighe) {
                    VStack(alignment: .leading, spacing: V.fraTitoloSottotitolo) {
                        Text(r.titolo)
                            .carattereApple(V.rigaDettaglio)
                            .foregroundColor(Tema.Apple.Colore.inchiostro)
                        Text(r.sottotitolo)
                            .carattereApple(V.sottoRigaDettaglio)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    }
                    Spacer(minLength: V.fraRighe)
                    if let c = r.canale { EtichettaCanaleApple(canale: c, compatta: true) }
                    Text(Formati.euro(r.cifra))
                        .carattereApple(V.cifraBarra)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
                Divider()
            }
            if let nota {
                Text(nota)
                    .carattereApple(V.sottoRigaDettaglio)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(V.paddingDettaglio)
        .frame(width: V.larghezzaDettaglio)
        .background(RoundedRectangle(cornerRadius: V.raggioDettaglio, style: .continuous).fill(V.fondoDettaglio))
        .superficieApple(V.superficieDettaglio, raggio: V.raggioDettaglio)
    }
}
