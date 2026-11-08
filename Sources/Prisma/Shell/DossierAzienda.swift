import SwiftUI

// Scheda «L'azienda» del dossier (Design/template-luce-specifica.md §9.3, «Luce» giro 7; decisioni 67, 74 e 96):
//
//   ┌──────────────────────────────────────────────────────────────────────────┐
//   │ [▣] Bianchi Serramenti S.r.l.                              Fatturato 2025 │
//   │     Azienda di prova · 14 dipendenti · Marco Bianchi socio…     2,1 mln € │
//   └──────────────────────────────────────────────────────────────────────────┘
//   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
//   │ ◯ 0%     │ │ ◯ 0%     │ │ ◯ 33%    │ │ ◯ 20%    │
//   │ Persona… │ │ TFM…     │ │ Welfare… │ │ Passag…  │
//   │ testo    │ │ testo    │ │ testo    │ │ testo    │
//   │ Proponi… │ │ I dati…  │ │ Proponi… │ │ Apri la… │
//   └──────────┘ └──────────┘ └──────────┘ └──────────┘
//   Dati aziendali di prova. Le valutazioni fiscali vanno sempre verificate con il commercialista dell'azienda.
//
// - Le cifre vengono da `MotoreAzienda` sui dati che l'utente ha scritto (`AziendaCliente`); dove un dato manca l'anello è
//   grigio con «—» e la scheda dice che cosa serve, con «Inserisci i dati ›».
// - Testata (clic) e ⌘E aprono `ModuloAzienda`; una scheda toccata apre il dettaglio che nasce da lei (`DettaglioApple`)
//   con il calcolo spiegato. I collegamenti: Pratiche › Proposta (persona chiave, welfare: prodotti dall'archivio
//   dell'utente, decisione 74), il dettaglio del TFM (nessun simulatore, decisione 67), Posizioni › passaggio
//   generazionale. In modalità cliente niente collegamenti verso Pratiche; su iPad in sola lettura.
// - Più aziende: la scelta in testa (segmentato con i nomi). Nessuna azienda (scheda aperta da «Altro › Azienda»): il
//   vuoto con «Aggiungi l'azienda di …».
// - Movimento: cascata del dossier, numeri contati, anelli che si riempiono (0,15 s dopo il cambio, + i·0,13), schede che
//   si inclinano di 5°. Calmo e istantanee: tutto fermo nello stato finale (lo fanno i componenti del tema).
// Valori in DesignSystem/Apple/Tema.Apple+Azienda.swift.

struct AziendaDossier: View {
    let cliente: Cliente
    @Environment(StatoShell.self) var stato
    @Environment(\.statoDettaglioApple) private var dettaglio
    @State private var scelta: String?
    @State private var modulo: ModificaAzienda?

    private typealias A = Tema.Apple.Azienda

    var body: some View {
        let _ = ContaCorpi.segna()
        let aziende = cliente.elencoAziende
        return Group {
            if let a = aziende.first(where: { $0.id == scelta }) ?? aziende.first {
                contenuto(a, aziende: aziende)
            } else {
                vuoto
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .sheet(item: $modulo) { m in
            ModuloAzienda(modifica: m, cliente: cliente, posizioni: stato.posizioniCliente(cliente.id),
                          salva: { stato.salvaAzienda($0, cliente: cliente.id) },
                          elimina: { stato.eliminaAzienda($0, cliente: cliente.id) })
        }
    }

    /// Su iPad la scheda è in sola lettura (§9.3.4); in sola lettura e in modalità cliente niente modifiche.
    private var puoModificare: Bool {
        #if os(iOS)
        return false
        #else
        return !stato.solaLettura && !stato.inModoCliente
        #endif
    }

    @ViewBuilder private func contenuto(_ a: AziendaCliente, aziende: [AziendaCliente]) -> some View {
        let valutazioni = MotoreAzienda.valuta(a, cliente: cliente, posizioni: stato.posizioniCliente(cliente.id))
        VStack(alignment: .leading, spacing: 0) {
            if aziende.count > 1 {
                SegmentatoPillola(selezione: Binding(get: { a.id }, set: { scelta = $0 }),
                                  valori: aziende.map(\.id),
                                  titolo: { id in aziende.first { $0.id == id }?.nomeMostrato ?? "" })
                    .padding(.bottom, A.sottoScelta)
                    .entrataDossier(0)
            }
            TestataAzienda(azienda: a, cliente: cliente, modifica: puoModificare ? { modifica(a) } : nil)
                .entrataDossier(1)
            griglia(a, valutazioni: valutazioni)
                .padding(.top, A.sopraSchede)
            Text(TestiAzienda.piede(a))
                .carattereApple(A.piede)
                .foregroundColor(A.colorePiede)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, A.sopraPiede)
                .entrataDossier(6)
            if puoModificare, aziende.count == 1 {
                Button { modulo = ModificaAzienda(azienda: AziendaCliente(ragioneSociale: ""), nuova: true) } label: {
                    Label("Aggiungi un'altra azienda", systemImage: "plus")
                }
                .buttonStyle(.appleSobrio)
                .padding(.top, A.sopraPiede)
                .entrataDossier(7)
            }
        }
        // Un'altra azienda scelta: le schede si rifanno e ricontano
        .id(a.id)
    }

    /// Quattro colonne; nella finestra stretta due (ViewThatFits: le schede hanno una larghezza minima).
    private func griglia(_ a: AziendaCliente, valutazioni: [ValutazioneAreaAzienda]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: A.spazioSchede) {
                ForEach(Array(valutazioni.enumerated()), id: \.element.id) { i, v in scheda(a, v, indice: i) }
            }
            VStack(spacing: A.spazioSchede) {
                ForEach(0..<2, id: \.self) { riga in
                    HStack(alignment: .top, spacing: A.spazioSchede) {
                        ForEach(Array(valutazioni.enumerated()).filter { $0.offset / 2 == riga }, id: \.element.id) { i, v in
                            scheda(a, v, indice: i)
                        }
                    }
                }
            }
        }
    }

    private func scheda(_ a: AziendaCliente, _ v: ValutazioneAreaAzienda, indice: Int) -> some View {
        SchedaAreaAzienda(valutazione: v, indice: indice, collegamento: collegamento(a, v),
                          apri: { apriDettaglio(a, v.area) })
            // La larghezza ideale fissata dice a ViewThatFits quanto chiede la scheda (senza, il testo su una riga la farebbe enorme)
            .frame(minWidth: A.larghezzaMinimaScheda, idealWidth: A.larghezzaMinimaScheda, maxWidth: .infinity,
                   maxHeight: .infinity, alignment: .top)
            .origineDettaglio(id: DettaglioAziendaId(cliente: cliente.id, azienda: a.id, area: v.area).testo)
            .entrataDossier(2 + indice)
    }

    /// Il collegamento in fondo alla scheda (testo e azione), o nil.
    private func collegamento(_ a: AziendaCliente, _ v: ValutazioneAreaAzienda) -> (String, () -> Void)? {
        if v.nonPertinente { return nil }
        if v.daCompletare {
            guard puoModificare else { return nil }
            return ("Inserisci i dati ›", { modifica(a) })
        }
        switch v.area.azione {
        case .proposta:
            // In modalità cliente niente collegamenti verso Pratiche
            guard !stato.inModoCliente, !stato.solaLettura else { return nil }
            let id = cliente.id
            let nome = TestiAzienda.nome(cliente)
            let area = v.area
            return (v.area.collegamento, {
                stato.clienteAttivoId = id
                stato.apriPratiche(.proposta)
                stato.mostraAvviso(TestiAzienda.avvisoProposta(area, nome: nome))
            })
        case .dettaglio:
            return (v.area.collegamento, { apriDettaglio(a, v.area) })
        case .pianificazione:
            let id = cliente.id
            return (v.area.collegamento, {
                stato.clienteAttivoId = id
                stato.portafoglio = false
                stato.posizioneInDettaglio = nil
                stato.ancoraPosizioni = "successione"
                stato.apri(.posizioni)
            })
        }
    }

    private func apriDettaglio(_ a: AziendaCliente, _ area: AreaAzienda) {
        dettaglio?.apri(DettaglioAziendaId(cliente: cliente.id, azienda: a.id, area: area).testo, misura: A.misuraDettaglio)
    }

    private func modifica(_ a: AziendaCliente) {
        modulo = ModificaAzienda(azienda: stato.cliente(cliente.id)?.elencoAziende.first { $0.id == a.id } ?? a, nuova: false)
    }

    /// Nessuna azienda registrata (la scheda aperta da «Altro › Azienda»).
    private var vuoto: some View {
        let nome = TestiAzienda.nome(cliente)
        return VStack(alignment: .leading, spacing: A.spazioVuoto) {
            HStack(spacing: A.spazioTestata) {
                TasselloGlifo(glifo: .azienda, lato: A.tassello)
                VStack(alignment: .leading, spacing: A.spazioNomeSotto) {
                    Text("Nessuna azienda registrata per \(nome)")
                        .carattereApple(A.vuotoFrase)
                        .foregroundColor(A.coloreNome)
                    Text("Se \(nome) ha un'azienda, registrala: quota, ruolo, dipendenti e fatturato li scrivi tu, e la scheda analizza persona chiave, TFM, welfare e passaggio dell'impresa.")
                        .carattereApple(A.vuotoNota)
                        .foregroundColor(A.coloreSotto)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if puoModificare {
                Button { modulo = ModificaAzienda(azienda: AziendaCliente(ragioneSociale: ""), nuova: true) } label: {
                    Label("Aggiungi l'azienda di \(nome)", systemImage: "plus")
                }
                .buttonStyle(.applePrimario)
            }
        }
        .padding(A.paddingTestata)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(A.superficie)
        .entrataDossier(0)
    }
}

/// Il modulo dell'azienda da aprire: l'azienda e se è nuova.
struct ModificaAzienda: Identifiable {
    var azienda: AziendaCliente
    var nuova: Bool
    var id: String { azienda.id }
}

// MARK: - Testata

/// Tassello 48, ragione sociale 21 bold, la riga sotto `.k`; a destra «Fatturato 2025» e la cifra 20 grassetto contata.
/// Il clic (o ⌘E) apre il modulo.
struct TestataAzienda: View {
    let azienda: AziendaCliente
    let cliente: Cliente
    let modifica: (() -> Void)?

    private typealias A = Tema.Apple.Azienda

    var body: some View {
        let contenuto = HStack(alignment: .center, spacing: A.spazioTestata) {
            TasselloGlifo(glifo: .azienda, lato: A.tassello)
            VStack(alignment: .leading, spacing: A.spazioNomeSotto) {
                Text(azienda.nomeMostrato)
                    .carattereApple(A.nome)
                    .foregroundColor(A.coloreNome)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(TestiAzienda.sottotitolo(azienda, cliente: cliente))
                    .carattereApple(A.sotto)
                    .foregroundColor(A.coloreSotto)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            Spacer(minLength: A.spazioTestata)
            VStack(alignment: .trailing, spacing: A.spazioNomeSotto) {
                Text(TestiAzienda.etichettaFatturato(azienda))
                    .carattereApple(A.etichettaFatturato)
                    .foregroundColor(A.coloreEtichettaFatturato)
                if let f = azienda.fatturato {
                    NumeroCheConta(f, formato: .personalizzato(TestiAzienda.fatturatoBreve), indice: 0)
                        .carattereApple(A.fatturato)
                        .foregroundColor(A.coloreFatturato)
                } else {
                    Text("da inserire")
                        .carattereApple(A.fatturatoMancante)
                        .foregroundColor(A.coloreFatturatoMancante)
                }
            }
            .lineLimit(1)
            .fixedSize()
        }
        .padding(A.paddingTestata)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(A.superficie)
        .contentShape(RoundedRectangle(cornerRadius: A.raggio, style: .continuous))
        return Group {
            if let modifica {
                Button(action: modifica) { contenuto }
                    .buttonStyle(StileSemplice())
                    .keyboardShortcut("e", modifiers: .command)
                    .help("Modifica i dati dell'azienda (⌘E)")
                    .accessibilityHint("Apre il modulo dell'azienda")
            } else {
                contenuto
            }
        }
    }
}

// MARK: - Scheda di un'area

/// Anello 76/9 nel colore dell'area con la percentuale (grigio con «—» se manca un dato o non è pertinente), titolo 15
/// bold, testo 12,5 e il collegamento blu in fondo. Si inclina di 5°; il clic apre il dettaglio.
struct SchedaAreaAzienda: View {
    let valutazione: ValutazioneAreaAzienda
    let indice: Int
    let collegamento: (String, () -> Void)?
    let apri: () -> Void

    private typealias A = Tema.Apple.Azienda

    var body: some View {
        let v = valutazione
        let forma = RoundedRectangle(cornerRadius: A.raggio, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Button(action: apri) {
                VStack(alignment: .leading, spacing: 0) {
                    anello
                    Text(v.area.titolo)
                        .carattereApple(A.titolo)
                        .foregroundColor(v.nonPertinente ? A.coloreTitoloSpento : A.coloreTitolo)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, A.sopraTitolo)
                    Text(v.frase)
                        .carattereApple(A.testo)
                        .foregroundColor(A.coloreTesto)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, A.sopraTesto)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(StileSemplice())
            .accessibilityHint("Apre il dettaglio con il calcolo spiegato")
            Spacer(minLength: A.sopraCollegamento)
            piede
        }
        .padding(A.paddingScheda)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(A.superficie)
        .opacity(v.nonPertinente ? A.opacitaNonPertinente : 1)
        .contentShape(forma)
        .inclinazione(massimo: A.inclinazioneMassima, raggio: A.raggio, attiva: !v.nonPertinente)
    }

    @ViewBuilder private var anello: some View {
        let v = valutazione
        let ritardo = Tema.Apple.Moto.Anello.ritardo(indice: indice, base: A.ritardoAnelli)
        if let p = v.percentuale {
            Anello(frazione: p / 100, colore: A.Tinta.colore(v.area), misura: A.anello, spessore: A.spessoreAnello,
                   ritardo: ritardo) {
                NumeroCheConta(p, formato: .percentuale, indice: indice)
                    .carattereApple(A.percentuale)
                    .foregroundColor(A.colorePercentuale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        } else {
            Anello(frazione: 0, colore: A.anelloVuoto, misura: A.anello, spessore: A.spessoreAnello, ritardo: ritardo) {
                Text("—")
                    .carattereApple(A.percentuale)
                    .foregroundColor(A.coloreTrattino)
            }
            .accessibilityLabel(v.nonPertinente ? "Non pertinente" : "Da valutare: mancano dei dati")
        }
    }

    @ViewBuilder private var piede: some View {
        if valutazione.nonPertinente {
            Text("Non pertinente")
                .carattereApple(A.collegamento)
                .foregroundColor(A.coloreCollegamentoSpento)
        } else if let c = collegamento {
            Button(action: c.1) {
                Text(c.0)
                    .carattereApple(A.collegamento)
                    .foregroundColor(A.coloreCollegamento)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .buttonStyle(StileSemplice())
        }
    }
}

// MARK: - Dettaglio di un'area

/// L'id del dettaglio di un'area: «azienda|cliente|azienda|area».
struct DettaglioAziendaId: Equatable {
    let cliente: String
    let azienda: String
    let area: AreaAzienda

    var testo: String { ["azienda", cliente, azienda, area.rawValue].joined(separator: "|") }

    init(cliente: String, azienda: String, area: AreaAzienda) {
        self.cliente = cliente
        self.azienda = azienda
        self.area = area
    }

    init?(_ testo: String) {
        let parti = testo.components(separatedBy: "|")
        guard parti.count == 4, parti[0] == "azienda", let area = AreaAzienda(rawValue: parti[3]) else { return nil }
        self.init(cliente: parti[1], azienda: parti[2], area: area)
    }
}

/// Il dettaglio che nasce dalla scheda: anello grande, la frase, il calcolo riga per riga (la cifra, da dove viene, cosa
/// manca), la nota sul commercialista e «Non pertinente» per l'azienda.
struct DettaglioAreaAzienda: View {
    @Environment(StatoShell.self) var stato
    let id: DettaglioAziendaId

    private typealias A = Tema.Apple.Azienda

    var body: some View {
        let _ = ContaCorpi.segna()
        if let c = stato.cliente(id.cliente), let a = c.elencoAziende.first(where: { $0.id == id.azienda }),
           let v = MotoreAzienda.valuta(a, cliente: c, posizioni: stato.posizioniCliente(c.id)).first(where: { $0.area == id.area }) {
            corpo(c, a, v)
        }
    }

    private func corpo(_ c: Cliente, _ a: AziendaCliente, _ v: ValutazioneAreaAzienda) -> some View {
        let colore = v.percentuale == nil ? A.anelloVuoto : A.Tinta.colore(v.area)
        let chiave = MotoreAzienda.chiaveNonPertinente(azienda: a.id, area: v.area)
        return ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: A.spazioDettaglio) {
                HStack(alignment: .center, spacing: A.spazioDettaglio) {
                    Anello(frazione: (v.percentuale ?? 0) / 100, colore: colore, misura: A.anelloDettaglio,
                           spessore: A.spessoreAnelloDettaglio, ritardo: Tema.Apple.Moto.Anello.ritardoDettaglio) {
                        if let p = v.percentuale {
                            NumeroCheConta(p, formato: .percentuale)
                                .carattereApple(A.percentualeDettaglio)
                                .foregroundColor(A.colorePercentuale)
                        } else {
                            Text("—")
                                .carattereApple(A.percentualeDettaglio)
                                .foregroundColor(A.coloreTrattino)
                        }
                    }
                    VStack(alignment: .leading, spacing: A.spazioNomeSotto) {
                        Text(a.nomeMostrato)
                            .carattereApple(A.etichettaDettaglio)
                            .foregroundColor(colore)
                            .lineLimit(1)
                        Text(v.area.titolo)
                            .carattereApple(A.titoloDettaglio)
                            .foregroundColor(A.coloreNome)
                        Text(v.frase)
                            .carattereApple(A.testo)
                            .foregroundColor(A.coloreTesto)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(v.righe, id: \.self) { r in
                        HStack(alignment: .firstTextBaseline, spacing: A.spazioRighe) {
                            Text(r.etichetta)
                                .carattereApple(A.rigaEtichetta)
                                .foregroundColor(A.coloreSotto)
                            Spacer(minLength: A.spazioRighe)
                            Text(r.valore)
                                .carattereApple(A.rigaValore)
                                .foregroundColor(A.coloreNome)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, A.spazioRighe)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(A.filo).frame(height: Tema.Apple.Misura.bordo)
                        }
                    }
                }
                Text(nota(v.area))
                    .carattereApple(A.piede)
                    .foregroundColor(A.colorePiede)
                    .fixedSize(horizontal: false, vertical: true)
                if !stato.solaLettura, !stato.inModoCliente {
                    Button(v.nonPertinente ? "Torna a valutarla" : "Non pertinente per questa azienda") {
                        if v.nonPertinente {
                            stato.ripristinaDatoNonPertinente(chiave, cliente: c.id)
                        } else {
                            stato.segnaDatoNonPertinente(chiave, cliente: c.id)
                        }
                    }
                    .buttonStyle(.appleSobrio)
                }
            }
            .padding(Tema.Apple.Misura.Padding.dettaglio)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    /// Da dove viene la cifra, e il rimando al commercialista dove tocca regole fiscali.
    private func nota(_ area: AreaAzienda) -> String {
        switch area {
        case .personaChiave:
            return "I mesi a rischio sono una tua valutazione; le coperture sono le posizioni in essere che hai collegato nel modulo dell'azienda. Le caratteristiche dei prodotti key man vengono dal tuo archivio prodotti."
        case .tfm:
            return TestiAzienda.notaTFM
        case .welfare:
            return "La percentuale conta le voci attive fra quelle che hai scelto. " + TestiAzienda.piedeFiscale
        case .passaggio:
            return "La percentuale conta i passi fatti fra quelli che hai scelto. Patto di famiglia e clausole sono da valutare con il commercialista e il notaio."
        }
    }
}

// MARK: - Archivio

extension StatoShell {
    /// Aggiunge o sostituisce un'azienda del cliente (ripulita: gli insiemi vuoti tornano nil).
    func salvaAzienda(_ azienda: AziendaCliente, cliente id: String) {
        guard !solaLettura, let i = dati.clienti.firstIndex(where: { $0.id == id }) else { return }
        var a = azienda
        a.ripulisci()
        var elenco = dati.clienti[i].elencoAziende
        if let j = elenco.firstIndex(where: { $0.id == a.id }) {
            elenco[j] = a
        } else {
            elenco.append(a)
        }
        dati.clienti[i].aziende = elenco
    }

    /// Toglie un'azienda dal cliente (con le sue aree segnate «non pertinenti»).
    func eliminaAzienda(_ azienda: AziendaCliente, cliente id: String) {
        guard !solaLettura, let i = dati.clienti.firstIndex(where: { $0.id == id }) else { return }
        let elenco = dati.clienti[i].elencoAziende.filter { $0.id != azienda.id }
        dati.clienti[i].aziende = elenco.isEmpty ? nil : elenco
        if var segnate = dati.clienti[i].datiNonPertinenti {
            for area in AreaAzienda.allCases {
                segnate.removeValue(forKey: MotoreAzienda.chiaveNonPertinente(azienda: azienda.id, area: area))
            }
            dati.clienti[i].datiNonPertinenti = segnate.isEmpty ? nil : segnate
        }
    }

    /// Una sola voce «non pertinente» torna a contare.
    func ripristinaDatoNonPertinente(_ voce: String, cliente id: String) {
        guard let i = dati.clienti.firstIndex(where: { $0.id == id }), var segnate = dati.clienti[i].datiNonPertinenti else { return }
        segnate.removeValue(forKey: voce)
        dati.clienti[i].datiNonPertinenti = segnate.isEmpty ? nil : segnate
    }

    /// Dal pannello Novità: il dossier del primo cliente (per nome) con un'azienda, sulla scheda «L'azienda»; se nessuno
    /// ne ha una, Clienti con l'avviso.
    func apriClientiImprenditori() {
        guard let c = MotoreAzienda.primoConAzienda(dati.clienti) else {
            apri(.clienti)
            mostraAvviso(TestiAzienda.nessunaAzienda)
            return
        }
        clienteAttivoId = c.id
        schedaCliente = .azienda
        apri(.clienti)
    }
}
