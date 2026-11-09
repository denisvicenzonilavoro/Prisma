import SwiftUI

// Clienti › Passaparola (Design/template-luce-specifica.md §9.2.1 punto 1.2 e §9.2.4, «Luce» giro 12):
//
//   ┌ CHI TI HA PRESENTATO CHI · DAL 2016 ───────────────────────┐ ┌ I tuoi ambasciatori ─────────┐
//   │        ╭─ (Marco) ─┬─ (Davide Sala) 320.000 € · potenziale  │ │ Marco  4   portato · in arrivo│
//   │ (Tu) ──┤           └─ (Chiara Marino) 65.000 €              │ │ Il 38% del patrimonio nuovo…  │
//   │        ╰─ (Sofia) ──── (Elena Marchi) 140.000 €             │ ├ Il momento giusto per chiedere┤
//   └────────────────────────────────────────────────────────────┘ │ ├ Nuovi clienti dal passaparola ┤
//   La grandezza di ogni cerchio è il patrimonio. …                 └───────────────────────────────┘
//
// - L'albero, gli ambasciatori, la quota, i nuovi per anno e il momento giusto vengono da MotorePassaparola; qui solo
//   la disposizione. Cerchi: r = 14 + √(k€)·0,9 al primo livello, 8 + √(k€)·0,8 dopo; già clienti pieni #30B15C con il
//   legame pieno, potenziali `chip` con il bordo `inchiostro3` e il legame tratteggiato 4/5.
// - Passaggio su un nodo: il suggerimento (sul Mac); clic su un cliente: il dossier; clic su un potenziale: il suo
//   dettaglio in Potenziali; clic su un ambasciatore: i suoi rami (gli altri al 30%); «Prepara la richiesta» apre
//   Messaggi e diventa «✓ Messaggio pronto» solo quando il messaggio esiste.
// - Movimento: legami pieni tracciati, tratteggiati in dissolvenza, nodi da scala 0,6, colonne degli anni da 0 (valori
//   in Tema.Apple.Moto.Passaparola). «Riduci movimento» e istantanee: tutto fermo nello stato finale.

struct VistaPassaparola: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaStatoFinale) private var statoFinale
    @Environment(\.prismaCalmo) private var calmo
    @State private var tracciati = false

    private typealias P = Tema.Apple.Passaparola

    var body: some View {
        let _ = ContaCorpi.segna()
        let oggi = Date()
        let clienti = stato.dati.clienti
        let potenziali = stato.dati.potenziali
        let posizioni = stato.dati.posizioni
        let albero = MotorePassaparola.albero(clienti: clienti, potenziali: potenziali, posizioni: posizioni)
        let ambasciatori = MotorePassaparola.ambasciatori(clienti: clienti, potenziali: potenziali, posizioni: posizioni)
        let quota = MotorePassaparola.quotaPassaparola(clienti: clienti, posizioni: posizioni, oggi: oggi)
        let anni = MotorePassaparola.nuoviPerAnno(clienti: clienti, oggi: oggi)
        // Le pratiche non entrano nei calcoli in cache (DatiPrisma.stessiCalcoli): si leggono vive per la data della firma
        let momenti: [MomentoPerChiedere] = {
            guard !stato.solaLettura else { return [] }
            var x = stato.datiDeiCalcoli()
            x.pratiche = stato.dati.pratiche
            return MotorePassaparola.momentoGiusto(dati: x, oggi: oggi)
        }()
        let mostra = tracciati || statoFinale
        return HStack(alignment: .top, spacing: P.spazio) {
            VStack(alignment: .leading, spacing: P.spazio) {
                DisegnoAlbero(albero: albero, clienti: clienti, evidenziato: stato.potenziali.evidenziato, mostra: mostra,
                              calmo: calmo || statoFinale, tocca: tocca)
                    .frame(minWidth: P.larghezzaAlberoMinima, idealWidth: P.larghezzaAlbero, maxWidth: P.larghezzaAlbero,
                           maxHeight: .infinity, alignment: .topLeading)
                    .superficieApple(Tema.Apple.Superficie.cardPiatta)
                Text(albero.vuoto ? TestiPassaparola.vuotoAlbero : TestiPassaparola.notaAlbero)
                    .carattereApple(Tema.Apple.Potenziali.nota)
                    .foregroundColor(Tema.Apple.Potenziali.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: P.spazio) {
                    AmbasciatoriCard(ambasciatori: ambasciatori, quota: quota, evidenziato: stato.potenziali.evidenziato) { id in
                        stato.potenziali.evidenziato = stato.potenziali.evidenziato == id ? nil : id
                    }
                    if let m = momenti.first, let c = stato.cliente(m.clienteId) {
                        MomentoGiustoCard(momento: m, cliente: c, pronto: stato.richiestaPreparata(m)) {
                            stato.preparaRichiestaPresentazione(m)
                        }
                    }
                    ColonneAnniPassaparola(anni: anni, mostra: mostra, calmo: calmo || statoFinale)
                }
            }
            .frame(width: P.larghezzaColonnaDestra)
        }
        .padding(P.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            guard !statoFinale else { return }
            tracciati = true
        }
    }

    /// Clic su un nodo: il dossier del cliente o il dettaglio del potenziale.
    private func tocca(_ n: NodoPassaparola) {
        switch n.tipo {
        case .cliente(let id):
            stato.clienteAttivoId = id
            stato.schedaCliente = .panoramica
            stato.vistaClienti = .rubrica
        case .potenziale(let id):
            stato.potenziali.scelto = id
            stato.potenziali.dettaglioIstantanea = id
            stato.vistaClienti = .potenziali
        case .tu, .altri:
            break
        }
    }
}

// MARK: - L'albero

/// Un nodo con la sua posizione nell'albero.
private struct NodoDisposto: Identifiable {
    let nodo: NodoPassaparola
    let centro: CGPoint
    let raggio: CGFloat
    let padre: CGPoint
    let raggioPadre: CGFloat
    let indice: Int
    /// L'id del cliente del primo livello da cui scende (per evidenziare i rami di un ambasciatore).
    let ramo: String?
    var id: String { nodo.id }
}

/// La disposizione dell'albero nella larghezza data (le x del template, scalate).
private struct DisposizioneAlbero {
    var nodi: [NodoDisposto] = []
    var altezza: CGFloat = 0
    var tagliati = 0
    let tu: CGPoint

    private typealias P = Tema.Apple.Passaparola

    init(_ albero: AlberoPassaparola, larghezza: CGFloat) {
        let s = max(0.5, larghezza / P.larghezzaAlbero)
        let xPrimo = P.xPrimo * s, xSecondo = P.xSecondo * s, xTerzo = min(P.xTerzo * s, larghezza - P.margineDestro)
        var y = P.margineSopra
        var elenco: [NodoDisposto] = []
        var tagliati = 0
        func spazio(_ n: NodoPassaparola) -> Int {
            max(1, n.figli.reduce(0) { $0 + max(1, $1.figli.count) })
        }
        // La y del «Tu»: a metà dei gruppi
        let righe = albero.primoLivello.map { CGFloat(spazio($0)) * P.passoSecondo }
        let totale = righe.reduce(0) { $0 + max(P.passoPrimo, $1) } + CGFloat(max(0, albero.primoLivello.count - 1)) * (P.distanzaGruppi - P.passoSecondo)
        let tu = CGPoint(x: P.xTu * s, y: P.margineSopra + max(P.passoPrimo, totale) / 2)
        self.tu = tu
        for (gi, primo) in albero.primoLivello.enumerated() {
            let alto = max(P.passoPrimo, righe[gi])
            let rPrimo = P.raggio(patrimonio: primo.patrimonio, livello: 1)
            let cPrimo = CGPoint(x: xPrimo, y: y + alto / 2)
            let ramo: String? = { if case .cliente(let id) = primo.tipo { return id } else { return nil } }()
            if elenco.count < P.nodiMassimi {
                elenco.append(NodoDisposto(nodo: primo, centro: cPrimo, raggio: rPrimo, padre: tu, raggioPadre: P.raggioTu,
                                           indice: elenco.count, ramo: ramo))
            } else {
                tagliati += 1
            }
            var riga = y + (alto - CGFloat(spazio(primo)) * P.passoSecondo) / 2 + P.passoSecondo / 2
            for (j, secondo) in primo.figli.enumerated() {
                let righeSecondo = CGFloat(max(1, secondo.figli.count))
                let c2 = CGPoint(x: xSecondo + (j % 2 == 0 ? 0 : P.scartoAlterno * s * 0.5), y: riga + (righeSecondo - 1) * P.passoSecondo / 2)
                let r2 = P.raggio(patrimonio: secondo.patrimonio, livello: 2)
                if elenco.count < P.nodiMassimi {
                    elenco.append(NodoDisposto(nodo: secondo, centro: c2, raggio: r2, padre: cPrimo, raggioPadre: rPrimo,
                                               indice: elenco.count, ramo: ramo))
                } else {
                    tagliati += 1
                }
                for (k, terzo) in secondo.figli.enumerated() {
                    let c3 = CGPoint(x: xTerzo, y: riga + CGFloat(k) * P.passoSecondo)
                    let r3 = P.raggio(patrimonio: terzo.patrimonio, livello: 3)
                    if elenco.count < P.nodiMassimi {
                        elenco.append(NodoDisposto(nodo: terzo, centro: c3, raggio: r3, padre: c2, raggioPadre: r2,
                                                   indice: elenco.count, ramo: ramo))
                    } else {
                        tagliati += 1
                    }
                }
                riga += righeSecondo * P.passoSecondo
            }
            y += alto + (P.distanzaGruppi - P.passoSecondo)
        }
        nodi = elenco
        self.tagliati = tagliati
        altezza = max(y, tu.y + P.raggioTu + P.margineSopra)
    }
}

/// La curva di un legame: Bézier orizzontale dal padre al figlio.
private struct CurvaLegame: Shape {
    let da: CGPoint
    let a: CGPoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mezzo = (da.x + a.x) / 2
        p.move(to: da)
        p.addCurve(to: a, control1: CGPoint(x: mezzo, y: da.y), control2: CGPoint(x: mezzo, y: a.y))
        return p
    }
}

private struct DisegnoAlbero: View {
    let albero: AlberoPassaparola
    let clienti: [Cliente]
    let evidenziato: String?
    let mostra: Bool
    let calmo: Bool
    let tocca: (NodoPassaparola) -> Void

    private typealias P = Tema.Apple.Passaparola
    private typealias M = Tema.Apple.Moto.Passaparola

    var body: some View {
        GeometryReader { g in
            let d = DisposizioneAlbero(albero, larghezza: g.size.width)
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    Text(TestiPassaparola.etichettaAlbero(anno: albero.annoPiuVecchio))
                        .carattereApple(Tema.Apple.Carattere.etichetta)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .padding(.leading, P.padding)
                        .padding(.top, P.padding / 2)
                    legami(d)
                    tu(d.tu)
                    ForEach(d.nodi) { n in
                        NodoPassaparolaVista(disposto: n, mostra: mostra, calmo: calmo,
                                             spento: evidenziato != nil && n.ramo != evidenziato, tocca: tocca)
                    }
                    piedeAlbero(d)
                        .padding(.leading, P.padding)
                        .offset(y: d.altezza - P.padding)
                }
                .frame(width: g.size.width, height: d.altezza + P.margineSopra, alignment: .topLeading)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(TestiPassaparola.etichettaAlbero(anno: albero.annoPiuVecchio))
    }

    @ViewBuilder private func legami(_ d: DisposizioneAlbero) -> some View {
        ForEach(d.nodi) { n in
            let spento = evidenziato != nil && n.ramo != evidenziato
            let curva = CurvaLegame(da: CGPoint(x: n.padre.x + n.raggioPadre, y: n.padre.y),
                                    a: CGPoint(x: n.centro.x - n.raggio, y: n.centro.y))
            if n.nodo.giaCliente {
                curva
                    .trim(from: 0, to: mostra ? 1 : 0)
                    .stroke(P.cliente, lineWidth: n.nodo.livello <= 1 ? P.spessoreTronco : P.spessorePotenziale)
                    .opacity(spento ? P.opacitaSpenta : 1)
                    .animation(calmo ? nil : M.animazioneLegame.delay(M.ritardoLegame(n.indice)), value: mostra)
            } else {
                curva
                    .stroke(P.bordoPotenziale, style: StrokeStyle(lineWidth: P.spessorePotenziale, dash: P.tratteggio))
                    .opacity((mostra ? P.opacitaPotenziale : 0) * (spento ? P.opacitaSpenta : 1))
                    .animation(calmo ? nil : M.animazioneTratteggio.delay(M.ritardoLegame(n.indice)), value: mostra)
            }
        }
    }

    private func tu(_ c: CGPoint) -> some View {
        Text(TestiPassaparola.tu)
            .carattereApple(P.iniziali)
            .foregroundColor(P.testoTu)
            .frame(width: P.raggioTu * 2, height: P.raggioTu * 2)
            .background(Circle().fill(LinearGradient(colors: [P.tuAlto, P.tuBasso], startPoint: .top, endPoint: .bottom)))
            .position(c)
    }

    @ViewBuilder private func piedeAlbero(_ d: DisposizioneAlbero) -> some View {
        VStack(alignment: .leading, spacing: P.spazioPiccolo) {
            if albero.senzaPresentazioni > 0 {
                Text(TestiPassaparola.senzaPresentazioni(albero.senzaPresentazioni))
            }
            if d.tagliati > 0 {
                Text("+ \(d.tagliati) non disegnati: troppe persone per una schermata")
            }
            if !albero.ciclo.isEmpty {
                Text(TestiPassaparola.ciclo(albero.ciclo.compactMap { id in clienti.first { $0.id == id }?.nome }))
                    .foregroundColor(P.coloreCiclo)
            }
        }
        .carattereApple(P.avvisoCiclo)
        .foregroundColor(Tema.Apple.Colore.inchiostro2)
    }
}

private struct NodoPassaparolaVista: View {
    let disposto: NodoDisposto
    let mostra: Bool
    let calmo: Bool
    let spento: Bool
    let tocca: (NodoPassaparola) -> Void

    private typealias P = Tema.Apple.Passaparola
    private typealias M = Tema.Apple.Moto.Passaparola

    var body: some View {
        let n = disposto.nodo
        let r = disposto.raggio
        let eAltri: Bool = { if case .altri = n.tipo { return true } else { return false } }()
        HStack(spacing: P.spazioNodo) {
            cerchio(n, r: r)
            VStack(alignment: .leading, spacing: P.spazioMinimo) {
                Text(n.nome)
                    .carattereApple(n.livello <= 1 ? P.nomePrimo : P.nomeSecondo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                if !eAltri {
                    Text(TestiPassaparola.cifraNodo(n))
                        .carattereApple(P.cifra)
                        .foregroundColor(P.coloreCifra)
                        .lineLimit(1)
                }
            }
            .fixedSize()
        }
        .scaleEffect(mostra ? 1 : M.scalaNodo, anchor: .leading)
        .opacity((mostra ? 1 : 0) * (spento ? P.opacitaSpenta : 1))
        .animation(calmo ? nil : M.animazioneNodo.delay(M.ritardoNodo(disposto.indice)), value: mostra)
        .position(x: disposto.centro.x - r + larghezzaStimata(n, r: r) / 2, y: disposto.centro.y)
        .onTapGesture { tocca(n) }
        .help(TestiPassaparola.suggerimento(n))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// La larghezza approssimata di cerchio e scritte (per posizionare il gruppo con il cerchio sul centro calcolato).
    private func larghezzaStimata(_ n: NodoPassaparola, r: CGFloat) -> CGFloat {
        2 * r + P.spazioNodo + CGFloat(max(n.nome.count, TestiPassaparola.cifraNodo(n).count)) * (n.livello <= 1 ? P.larghezzaLetteraPrimo : P.larghezzaLettera)
    }

    @ViewBuilder private func cerchio(_ n: NodoPassaparola, r: CGFloat) -> some View {
        switch n.tipo {
        case .cliente:
            Circle()
                .fill(P.cliente)
                .overlay(Circle().strokeBorder(Tema.Apple.Colore.card, lineWidth: n.livello <= 1 ? P.bordoPrimo : 1))
                .overlay {
                    if r >= 16 {
                        Text(n.iniziali).carattereApple(P.iniziali).foregroundColor(P.testoTu)
                    }
                }
                .frame(width: 2 * r, height: 2 * r)
        case .potenziale:
            Circle()
                .fill(P.potenziale)
                .overlay(Circle().strokeBorder(P.bordoPotenziale, lineWidth: 1))
                .frame(width: 2 * r, height: 2 * r)
        case .altri, .tu:
            Circle()
                .fill(Tema.Apple.Colore.chip)
                .frame(width: 2 * r, height: 2 * r)
        }
    }
}

// MARK: - Colonna destra

private struct AmbasciatoriCard: View {
    let ambasciatori: [Ambasciatore]
    let quota: QuotaPassaparola?
    let evidenziato: String?
    let scegli: (String) -> Void

    private typealias P = Tema.Apple.Passaparola

    var body: some View {
        VStack(alignment: .leading, spacing: P.spazioRighe) {
            Text(TestiPassaparola.ambasciatori.uppercased())
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            if ambasciatori.isEmpty {
                Text(TestiPassaparola.nessunAmbasciatore)
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro3)
            }
            ForEach(ambasciatori) { a in
                Button { scegli(a.id) } label: {
                    VStack(alignment: .leading, spacing: P.spazioMinimo * 3) {
                        HStack {
                            Text(a.nome).carattereApple(P.rigaAmbasciatore).foregroundColor(Tema.Apple.Colore.inchiostro)
                            Spacer()
                            Text(TestiPassaparola.presentati(a.presentati))
                                .carattereApple(P.cifraAmbasciatore).foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                        HStack(spacing: P.spazio - 2) {
                            Text(Formati.euro(a.portato) + " " + TestiPassaparola.portato)
                                .foregroundColor(P.cliente)
                            Text(Formati.euro(a.inArrivo) + " " + TestiPassaparola.inArrivo)
                                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        }
                        .carattereApple(P.cifraAmbasciatore)
                    }
                    .padding(P.spazioMedio)
                    .background {
                        if evidenziato == a.id {
                            RoundedRectangle(cornerRadius: Tema.Apple.Raggio.voce, style: .continuous).fill(Tema.Apple.Colore.chip)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Evidenzia i rami di \(a.nome)")
            }
            if let q = quota {
                Text(TestiPassaparola.quota(q))
                    .carattereApple(Tema.Apple.Carattere.corpo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .fixedSize(horizontal: false, vertical: true)
                if let nota = TestiPassaparola.notaQuota(q) {
                    Text(nota)
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .foregroundColor(Tema.Apple.Colore.inchiostro3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(P.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.cardPiatta)
        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }
}

private struct MomentoGiustoCard: View {
    let momento: MomentoPerChiedere
    let cliente: Cliente
    let pronto: Bool
    let prepara: () -> Void

    private typealias P = Tema.Apple.Passaparola

    var body: some View {
        VStack(alignment: .leading, spacing: P.spazioMedio) {
            Text(TestiPassaparola.momentoTitolo.uppercased())
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(P.etichettaMomento)
            Text(cliente.nome + " " + momento.fatto + ".")
                .carattereApple(Tema.Apple.Carattere.corpo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
            Button(pronto ? TestiPassaparola.messaggioPronto : TestiPassaparola.preparaRichiesta, action: prepara)
                .buttonStyle(.apple)
                .disabled(pronto)
        }
        .padding(P.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.card, style: .continuous).fill(P.fondoMomento))
        .overlay(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.card, style: .continuous).strokeBorder(P.bordoMomento, lineWidth: 1))
        .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }
}

private struct ColonneAnniPassaparola: View {
    let anni: [(anno: Int, dalPassaparola: Int, totali: Int)]
    let mostra: Bool
    let calmo: Bool

    private typealias P = Tema.Apple.Passaparola
    private typealias M = Tema.Apple.Moto.Passaparola

    var body: some View {
        let massimo = max(1, anni.map { $0.dalPassaparola }.max() ?? 1)
        VStack(alignment: .leading, spacing: P.spazioRighe) {
            Text(TestiPassaparola.nuoviTitolo.uppercased())
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            HStack(alignment: .bottom, spacing: P.spazioRighe) {
                ForEach(Array(anni.enumerated()), id: \.offset) { i, a in
                    VStack(spacing: P.spazioPiccolo) {
                        Text("\(a.dalPassaparola)")
                            .carattereApple(P.cifraAmbasciatore)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        UnevenRoundedRectangle(topLeadingRadius: P.raggioColonna, bottomLeadingRadius: P.raggioColonnaBasso,
                                               bottomTrailingRadius: P.raggioColonnaBasso, topTrailingRadius: P.raggioColonna,
                                               style: .continuous)
                            .fill(i == anni.count - 1 ? P.colonnaUltima : P.colonna)
                            .frame(height: max(P.spazioMinimo * 2, P.altezzaColonne * CGFloat(a.dalPassaparola) / CGFloat(massimo)) * (mostra ? 1 : 0.001))
                            .animation(calmo ? nil : M.animazioneColonna.delay(M.ritardoColonna(i)), value: mostra)
                        Text(String(a.anno))
                            .carattereApple(P.etichettaAnno)
                            .foregroundColor(Tema.Apple.Colore.inchiostro3)
                    }
                    .frame(maxWidth: .infinity)
                    .help(TestiPassaparola.colonnaAnno(anno: a.anno, dal: a.dalPassaparola, totali: a.totali))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(TestiPassaparola.colonnaAnno(anno: a.anno, dal: a.dalPassaparola, totali: a.totali))
                }
            }
            .frame(height: P.altezzaColonne + P.sopraColonne, alignment: .bottom)
        }
        .padding(P.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.cardPiatta)
        .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }
}
