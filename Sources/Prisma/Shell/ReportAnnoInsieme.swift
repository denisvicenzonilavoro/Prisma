import SwiftUI

private typealias K = Tema.Apple.CartaAnno.Colore
private typealias F = Tema.Apple.CartaAnno.Testo
private typealias M = Tema.Apple.CartaAnno.Misura
private typealias R = Tema.Apple.CartaAnno.Righe

/// Il report «Un anno insieme»: A4 orizzontale, per il cliente, su carta bianca (tema Apple §4.5.2 e la pagina di
/// riferimento del template). Prima pagina come nel template (canale in testa, «Un anno insieme.», le tre cifre, i
/// momenti dell'anno, come è andata, il prossimo anno), poi cosa è successo, gli obiettivi, la protezione, i mercati
/// e cosa ci aspetta. Ogni pagina ha le avvertenze in 9 pt nel piede. Colori opachi e fissi, niente vetro.
enum ReportAnnoInsieme {
    static func pagine(_ t: TestiAnnoInsieme) -> [AnyView] {
        var corpi: [AnyView] = [AnyView(PrimaAnno(t: t)), AnyView(SuccessoAnno(t: t))]
        if !t.a.obiettivi.isEmpty { corpi.append(AnyView(ObiettiviAnno(t: t))) }
        corpi.append(AnyView(ProtezioneAnno(t: t)))
        if t.a.esposte { corpi.append(AnyView(MercatiAnno(t: t))) }
        corpi.append(AnyView(ProssimoAnno(t: t)))
        let totale = corpi.count
        return corpi.enumerated().map { i, corpo in
            AnyView(FoglioAnno(t: t, numero: i + 1, totale: totale, prima: i == 0) { corpo })
        }
    }
}

// MARK: - Il foglio

/// Carta bianca A4 orizzontale: l'intestazione con il canale, il contenuto, il piede con le avvertenze e il numero.
private struct FoglioAnno<Contenuto: View>: View {
    @Environment(\.numerazioneFascicolo) private var fascicolo
    let t: TestiAnnoInsieme
    let numero: Int
    let totale: Int
    let prima: Bool
    @ViewBuilder let contenuto: () -> Contenuto

    /// «2 / 6» nel report, la pagina del fascicolo dentro il fascicolo.
    private var numerazione: String {
        guard let f = fascicolo else { return "\(numero) / \(totale)" }
        return "\(numero + f.scostamento) / \(f.totale)"
    }

    var body: some View {
        FoglioDocumento(formato: M.formato, sfondo: K.fondo) {
            // Il piede sta sempre in fondo, sopra il contenuto: le avvertenze non escono mai dal foglio
            ZStack(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    IntestazioneAnno(canali: t.a.canali)
                    contenuto()
                        .padding(.top, prima ? M.sottoIntestazione : M.sottoIntestazioneInterna)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.bottom, M.spazioPiede)
                .clipped()
                piede
                    .background(K.fondo)
            }
            .padding(EdgeInsets(top: M.margineAlto, leading: M.margineLati, bottom: M.piedeDalFondo, trailing: M.margineLati))
        }
        // La carta ha misure fisse: la «Dimensione del testo» dell'app non la ingrandisce (anteprima, sala e PDF uguali)
        .prismaScalaTesto(1)
    }

    private var piede: some View {
        HStack(alignment: .top, spacing: M.spazioColonne) {
            Text(verbatim: t.avvertenzaPiede)
                .carattereApple(F.piede)
                .foregroundColor(K.piede)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: numerazione)
                .carattereApple(F.numeroPagina)
                .foregroundColor(K.piede)
        }
        .padding(.top, M.sopraPiede)
        .overlay(Rectangle().fill(K.filetto).frame(height: M.filetto), alignment: .top)
    }
}

/// L'intestazione: il logo di Prisma e il canale. Solo indipendente: «DENIS VICENZONI · CONSULENZA FINANZIARIA» in
/// cuoio; solo Alleanza: il simbolo Alleanza e la scritta in blu; con i due canali, le due etichette da stampa.
private struct IntestazioneAnno: View {
    let canali: [Canale]

    var body: some View {
        HStack(alignment: .center, spacing: M.spazioLogo) {
            LogoPrisma(colore: K.logo)
                .frame(height: M.logo)
            if canali == [.alleanza] {
                simboloAlleanza
                Text(verbatim: "\(TestiValutazione.consulente) · Consulente \(Canale.alleanza.nome)")
                    .carattereApple(F.intestazione)
                    .foregroundColor(K.alleanza)
                    .lineLimit(1)
                Spacer(minLength: 0)
            } else if canali == [.indipendente] {
                Text(verbatim: Canale.indipendente.nome)
                    .carattereApple(F.intestazione)
                    .foregroundColor(K.indipendente)
                    .lineLimit(1)
                Spacer(minLength: 0)
            } else {
                Text(verbatim: TestiValutazione.consulente)
                    .carattereApple(F.intestazione)
                    .foregroundColor(K.etichetta)
                    .lineLimit(1)
                Spacer(minLength: M.spazioLogo)
                ForEach(canali, id: \.self) { c in
                    EtichettaCanaleStampa(canale: c)
                }
            }
        }
    }

    @ViewBuilder private var simboloAlleanza: some View {
        if let simbolo = Risorse.immagine("Loghi/Alleanza_simbolo.png") {
            Image(piattaforma: simbolo)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: M.simboloAlleanza)
                .foregroundColor(K.alleanza)
        }
    }
}

// MARK: - Pezzi comuni

/// Sopratitolo blu, titolo e sottotitolo (`.pl`, `h3`, `.ps`).
private struct TestaAnno: View {
    let sopratitolo: String
    let titolo: String
    var sottotitolo: String = ""
    var grande = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: sopratitolo)
                .carattereApple(F.sopratitolo)
                .foregroundColor(K.sopratitolo)
            Text(verbatim: titolo)
                .carattereApple(grande ? F.titolo : F.titoloPagina)
                .foregroundColor(K.titolo)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, M.sottoSopratitolo)
            if !sottotitolo.isEmpty {
                Text(verbatim: sottotitolo)
                    .carattereApple(F.sottotitolo)
                    .foregroundColor(K.sottotitolo)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, M.sottoTitolo)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// `.sec`: il titoletto di una sezione.
private struct SezioneAnno: View {
    let titolo: String
    var primo = false

    var body: some View {
        Text(verbatim: titolo)
            .carattereApple(F.sezione)
            .foregroundColor(K.titolo)
            .padding(.top, primo ? 0 : M.sopraSezione)
            .padding(.bottom, M.sottoSezione)
    }
}

/// `.kp`: una cifra in un riquadro con il bordo sottile.
private struct CifraAnno: View {
    let c: TestiAnnoInsieme.Cifra

    private var coloreNota: Color {
        switch c.tono {
        case .neutro: return K.etichetta
        case .positivo: return K.positivo
        case .attenzione: return K.ambra
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: M.righeKpi) {
            Text(verbatim: c.etichetta)
                .carattereApple(F.kpiEtichetta)
                .foregroundColor(K.etichetta)
                .lineLimit(1)
                // «Anticipo per la casa» sta nel riquadro rimpicciolito di poco, invece di finire con «…»
                .minimumScaleFactor(0.8)
            Text(verbatim: c.valore)
                .carattereApple(F.kpiValore)
                .foregroundColor(K.titolo)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if !c.nota.isEmpty {
                Text(verbatim: c.nota)
                    .carattereApple(F.kpiNota)
                    .foregroundColor(coloreNota)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(M.kpiPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: M.kpiRaggio, style: .continuous).strokeBorder(K.filetto, lineWidth: M.filetto))
    }
}

private struct FilaCifreAnno: View {
    let cifre: [TestiAnnoInsieme.Cifra]

    var body: some View {
        HStack(alignment: .top, spacing: M.spazioKpi) {
            ForEach(cifre) { CifraAnno(c: $0) }
        }
    }
}

/// Una riga di elenco con il pallino «◦» e il filetto sotto.
private struct VoceElencoAnno: View {
    let testo: String
    var nota = ""
    var colore: Color = K.linea

    var body: some View {
        HStack(alignment: .center, spacing: M.spazioRiga) {
            Circle().fill(colore).frame(width: M.pallino, height: M.pallino)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: testo)
                    .carattereApple(F.riga)
                    .foregroundColor(K.testo)
                    .fixedSize(horizontal: false, vertical: true)
                if !nota.isEmpty {
                    Text(verbatim: nota)
                        .carattereApple(F.rigaNota)
                        .foregroundColor(K.etichetta)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, M.spazioRiga / 2)
        .overlay(Rectangle().fill(K.filetto).frame(height: M.filetto), alignment: .bottom)
    }
}

private struct TestoAnno: View {
    let testo: String

    var body: some View {
        Text(verbatim: testo)
            .carattereApple(F.corpo)
            .foregroundColor(K.testo)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// «…e altri N»: quello che non sta nella pagina.
private struct AltriAnno: View {
    let altri: Int

    var body: some View {
        if altri > 0 {
            Text(verbatim: "…e \(altri == 1 ? "un'altra voce" : "altre \(altri) voci") nel dossier")
                .carattereApple(F.rigaNota)
                .foregroundColor(K.etichetta)
                .padding(.top, M.spazioRiga)
        }
    }
}

// MARK: - 1. Prima pagina

private struct PrimaAnno: View {
    let t: TestiAnnoInsieme

    var body: some View {
        HStack(alignment: .top, spacing: M.spazioColonne) {
            sinistra.frame(width: M.colonnaSinistra, alignment: .topLeading)
            destra.frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var sinistra: some View {
        VStack(alignment: .leading, spacing: 0) {
            TestaAnno(sopratitolo: t.sopratitolo, titolo: t.titoloPrima, sottotitolo: t.sottotitolo, grande: true)
            FilaCifreAnno(cifre: t.cifrePrima)
                .padding(.top, M.sopraKpi)
            SezioneAnno(titolo: "Come è andata")
            TestoAnno(testo: t.comeEAndata)
        }
    }

    private var destra: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "I momenti dell'anno", primo: true)
            LineaAnno(momenti: t.a.momenti)
                .frame(height: M.lineaAltezza)
            SezioneAnno(titolo: TestiAnnoInsieme.titoloPeriodoAvanti)
            // Fra una voce e l'altra lo stesso spazio che fra le righe di una voce (interlinea CSS 1,8)
            VStack(alignment: .leading, spacing: F.elenco.spazioRighe) {
                ForEach(Array(t.nelProssimoAnno.enumerated()), id: \.offset) { _, riga in
                    HStack(alignment: .firstTextBaseline, spacing: M.spazioRiga) {
                        Text(verbatim: "◦").carattereApple(F.elenco).foregroundColor(K.testo)
                        Text(verbatim: riga)
                            .carattereApple(F.elenco)
                            .foregroundColor(K.testo)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

/// La linea dell'anno: i momenti a distanza uguale, con il mese e il titolo alternati sopra e sotto.
private struct LineaAnno: View {
    let momenti: [AnnoInsieme.Momento]

    var body: some View {
        GeometryReader { g in
            let larghezza = g.size.width
            let n = max(1, momenti.count)
            let passo = (larghezza - 2 * M.lineaRientro) / CGFloat(n)
            let etichetta = min(M.titoloMomentoMassimo, passo * 2 - M.spazioRiga)
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: M.lineaRientro, y: M.lineaY))
                    p.addLine(to: CGPoint(x: larghezza - M.lineaRientro, y: M.lineaY))
                }
                .stroke(K.linea, lineWidth: M.lineaSpessore)
                if momenti.isEmpty {
                    Text(verbatim: "Nessun momento registrato quest'anno.")
                        .carattereApple(F.titoloMomento)
                        .foregroundColor(K.etichetta)
                        .frame(width: larghezza)
                        .position(x: larghezza / 2, y: M.meseSotto)
                }
                ForEach(Array(momenti.enumerated()), id: \.offset) { i, m in
                    let x = M.lineaRientro + passo * (CGFloat(i) + 0.5)
                    MomentoAnno(momento: m, sopra: i % 2 == 1, larghezza: etichetta)
                        .frame(width: larghezza, height: M.lineaAltezza, alignment: .topLeading)
                        .offset(x: x - larghezza / 2)
                }
            }
        }
    }
}

/// Un momento: il cerchio sulla linea, il mese e il titolo.
private struct MomentoAnno: View {
    let momento: AnnoInsieme.Momento
    let sopra: Bool
    let larghezza: CGFloat

    var body: some View {
        let colore = K.momento(momento.tono)
        GeometryReader { g in
            let centro = g.size.width / 2
            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(K.fondo)
                    .overlay(Circle().strokeBorder(colore, lineWidth: M.cerchioBordo))
                    .frame(width: M.cerchio, height: M.cerchio)
                    .position(x: centro, y: M.lineaY)
                Text(verbatim: TestiAnnoInsieme.meseBreve(momento.data))
                    .carattereApple(F.meseMomento)
                    .foregroundColor(colore)
                    .lineLimit(1)
                    .frame(width: larghezza)
                    .position(x: centro, y: sopra ? M.meseSopra : M.meseSotto)
                Text(verbatim: momento.titolo)
                    .carattereApple(F.titoloMomento)
                    .foregroundColor(K.testo)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .frame(width: larghezza)
                    .position(x: centro, y: sopra ? M.titoloSopra : M.titoloSotto)
            }
        }
    }
}

// MARK: - 2. Cosa è successo

private struct SuccessoAnno: View {
    let t: TestiAnnoInsieme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TestaAnno(sopratitolo: "Cosa è successo", titolo: "Il tuo \(t.a.anno), in cifre.", sottotitolo: t.sottotitoloAnno)
            FilaCifreAnno(cifre: t.cifreAnno)
                .padding(.top, M.sopraKpi)
            HStack(alignment: .top, spacing: M.spazioColonne) {
                posizioni.frame(maxWidth: .infinity, alignment: .topLeading)
                laterale.frame(width: M.colonnaLaterale, alignment: .topLeading)
            }
        }
    }

    private var posizioni: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "Le tue posizioni finanziarie")
            if t.a.voci.isEmpty {
                TestoAnno(testo: "Nessuna posizione finanziaria in essere: il quadro dell'anno è nella protezione e negli obiettivi.")
            } else {
                HStack(spacing: M.spazioRiga) {
                    Text(verbatim: "Posizione").frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: "1° gennaio").frame(width: M.colonnaCifra, alignment: .trailing)
                    Text(verbatim: "Versato").frame(width: M.colonnaCifra, alignment: .trailing)
                    Text(verbatim: "Oggi").frame(width: M.colonnaCifra, alignment: .trailing)
                }
                .carattereApple(F.testaTabella)
                .foregroundColor(K.etichetta)
                .padding(.bottom, M.spazioRiga / 2)
                .overlay(Rectangle().fill(K.linea).frame(height: M.filetto), alignment: .bottom)
                ForEach(t.a.voci.prefix(R.posizioni)) { v in
                    RigaPosizioneAnno(v: v)
                }
                AltriAnno(altri: t.a.voci.count - R.posizioni)
            }
        }
    }

    private var laterale: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "Gli incontri")
            if t.a.incontri.isEmpty {
                TestoAnno(testo: "Nessun incontro registrato quest'anno.")
            }
            ForEach(t.a.incontri.suffix(R.incontri)) { i in
                VoceElencoAnno(testo: i.titolo, nota: CifreDoc.data(i.data), colore: K.sopratitolo)
            }
            SezioneAnno(titolo: "Le scelte dell'anno")
            if t.scelte.isEmpty {
                TestoAnno(testo: "Nessuna posizione nuova quest'anno.")
            }
            ForEach(Array(t.scelte.prefix(R.scelte).enumerated()), id: \.offset) { _, s in
                VoceElencoAnno(testo: s.nome, nota: "\(s.nota) · \(s.canale.nomeBreve)", colore: K.canale(s.canale))
            }
        }
    }
}

private struct RigaPosizioneAnno: View {
    let v: AnnoInsieme.VoceAnno

    var body: some View {
        HStack(alignment: .center, spacing: M.spazioRiga) {
            // Etichetta del canale sopra il nome: il nome ha tutta la colonna e non tocca i filetti
            VStack(alignment: .leading, spacing: M.spazioNomeCanale) {
                EtichettaCanaleStampa(canale: v.posizione.canale, compatta: true)
                Text(verbatim: v.posizione.nome)
                    .carattereApple(F.rigaForte)
                    .foregroundColor(K.titolo)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: v.nuova ? "nuova" : CifreDoc.euro(v.inizio))
                .carattereApple(F.riga)
                .foregroundColor(K.etichetta)
                .frame(width: M.colonnaCifra, alignment: .trailing)
            Text(verbatim: CifreDoc.euro(v.versato))
                .carattereApple(F.riga)
                .foregroundColor(K.testo)
                .frame(width: M.colonnaCifra, alignment: .trailing)
            Text(verbatim: CifreDoc.euro(v.fine))
                .carattereApple(F.rigaCifra)
                .foregroundColor(K.titolo)
                .frame(width: M.colonnaCifra, alignment: .trailing)
        }
        .frame(minHeight: M.riga)
        .padding(.vertical, M.spazioRiga / 2)
        .overlay(Rectangle().fill(K.filetto).frame(height: M.filetto), alignment: .bottom)
    }
}

// MARK: - 3. Gli obiettivi

private struct ObiettiviAnno: View {
    let t: TestiAnnoInsieme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TestaAnno(sopratitolo: "Gli obiettivi", titolo: t.titoloObiettivi,
                      sottotitolo: "La barra chiara è il 1° gennaio, quella piena è oggi: quanto è già da parte per ogni progetto.")
            VStack(alignment: .leading, spacing: M.sopraSezione) {
                ForEach(t.a.obiettivi.prefix(R.obiettivi)) { o in
                    RigaObiettivoAnno(t: t, o: o)
                }
            }
            .padding(.top, M.sopraSezione)
            AltriAnno(altri: t.a.obiettivi.count - R.obiettivi)
        }
    }
}

private struct RigaObiettivoAnno: View {
    let t: TestiAnnoInsieme
    let o: AnnoInsieme.ObiettivoAnno

    var body: some View {
        HStack(alignment: .center, spacing: M.spazioColonne) {
            VStack(alignment: .leading, spacing: M.spazioBarre) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: o.obiettivo.titolo)
                        .carattereApple(F.rigaForte)
                        .foregroundColor(K.titolo)
                        .lineLimit(1)
                    Spacer(minLength: M.spazioRiga)
                    Text(verbatim: t.notaObiettivo(o))
                        .carattereApple(F.rigaNota)
                        .foregroundColor(K.etichetta)
                        .lineLimit(1)
                }
                BarreObiettivoAnno(inizio: o.quotaInizio, fine: o.quotaFine)
                    .frame(height: M.barra * 2 + M.spazioBarre)
            }
            VStack(alignment: .trailing, spacing: 1) {
                Text(verbatim: TestiAnnoInsieme.quota(o.quotaFine))
                    .carattereApple(F.percento)
                    .foregroundColor(o.avvicinato ? K.positivo : K.titolo)
                Text(verbatim: t.confrontoObiettivo(o))
                    .carattereApple(F.rigaNota)
                    .foregroundColor(K.etichetta)
                    .lineLimit(1)
            }
            .frame(width: M.colonnaPercento, alignment: .trailing)
        }
    }
}

/// Due barre sul binario: il 1° gennaio (chiara) e oggi (piena).
private struct BarreObiettivoAnno: View {
    let inizio: Double
    let fine: Double

    var body: some View {
        GeometryReader { g in
            VStack(alignment: .leading, spacing: M.spazioBarre) {
                barra(quota: inizio, colore: K.bluInizio, larghezza: g.size.width)
                barra(quota: fine, colore: K.bluGrafico, larghezza: g.size.width)
            }
        }
    }

    private func barra(quota: Double, colore: Color, larghezza: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: M.raggioBarra, style: .continuous).fill(K.binario)
            RoundedRectangle(cornerRadius: M.raggioBarra, style: .continuous)
                .fill(colore)
                .frame(width: max(M.barraMinima, larghezza * CGFloat(min(1, max(0, quota)))))
        }
        .frame(height: M.barra)
    }
}

// MARK: - 4. La protezione

private struct ProtezioneAnno: View {
    let t: TestiAnnoInsieme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TestaAnno(sopratitolo: "La protezione", titolo: t.titoloProtezione, sottotitolo: t.fraseProtezione)
            HStack(alignment: .top, spacing: M.spazioColonne) {
                coperture.frame(maxWidth: .infinity, alignment: .topLeading)
                daCompletare.frame(width: M.colonnaLaterale, alignment: .topLeading)
            }
        }
    }

    private var coperture: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "Le coperture")
            if t.a.coperture.isEmpty {
                TestoAnno(testo: "Nessuna copertura in essere.")
            }
            ForEach(t.a.coperture.prefix(R.coperture)) { c in
                RigaCoperturaAnno(c: c, stato: t.statoCopertura(c))
            }
            AltriAnno(altri: t.a.coperture.count - R.coperture)
            if let frase = t.fraseCasoMorte() {
                SezioneAnno(titolo: "Se mancasse il tuo reddito")
                BarraCasoMorteAnno(fabbisogno: t.a.fabbisognoVita, divario: t.a.divarioVita)
                    .frame(height: M.barraProtezione)
                TestoAnno(testo: frase)
                    .padding(.top, M.sottoSezione)
            }
        }
    }

    private var daCompletare: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "Da completare")
            if t.a.scoperti.isEmpty && t.a.inProposta.isEmpty {
                TestoAnno(testo: "Nessun rischio importante per la tua famiglia resta scoperto.")
            }
            ForEach(t.a.scoperti.prefix(R.daCompletare)) { r in
                VoceElencoAnno(testo: r.rischio.nome, nota: r.perche.isEmpty ? "scoperto" : r.perche, colore: K.rosso)
            }
            ForEach(t.a.inProposta.prefix(R.daCompletare)) { r in
                VoceElencoAnno(testo: r.rischio.nome, nota: "proposta da valutare insieme", colore: K.ambra)
            }
        }
    }
}

private struct RigaCoperturaAnno: View {
    let c: AnnoInsieme.CoperturaAnno
    let stato: String

    var body: some View {
        let p = c.posizione
        return HStack(alignment: .center, spacing: M.spazioRiga) {
            EtichettaCanaleStampa(canale: p.canale, compatta: true)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: (p.rischio ?? .altro).nome)
                    .carattereApple(F.rigaForte)
                    .foregroundColor(K.titolo)
                    .lineLimit(1)
                Text(verbatim: p.nome)
                    .carattereApple(F.rigaNota)
                    .foregroundColor(K.etichetta)
                    .lineLimit(1)
            }
            Spacer(minLength: M.spazioRiga)
            VStack(alignment: .trailing, spacing: 1) {
                Text(verbatim: (p.capitaleAssicurato ?? 0) > 0.5 ? CifreDoc.euro(p.capitaleAssicurato ?? 0) : "—")
                    .carattereApple(F.rigaCifra)
                    .foregroundColor(K.titolo)
                Text(verbatim: stato)
                    .carattereApple(F.rigaNota)
                    .foregroundColor(c.tuttoAnno ? K.positivo : K.etichetta)
                    .lineLimit(1)
            }
        }
        .frame(minHeight: M.riga)
        .padding(.vertical, M.spazioRiga / 2)
        .overlay(Rectangle().fill(K.filetto).frame(height: M.filetto), alignment: .bottom)
    }
}

/// «Già assicurato · Servirebbe»: la barra rossa sul binario rosa, come la pagina Protezione del template.
private struct BarraCasoMorteAnno: View {
    let fabbisogno: Double
    let divario: Double

    var body: some View {
        GeometryReader { g in
            let quota = fabbisogno > 0 ? max(0, min(1, (fabbisogno - divario) / fabbisogno)) : 0
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: M.raggioBarraProtezione, style: .continuous).fill(K.binarioRosso)
                RoundedRectangle(cornerRadius: M.raggioBarraProtezione, style: .continuous)
                    .fill(K.rosso)
                    .frame(width: max(M.barraMinima, g.size.width * CGFloat(quota)))
            }
        }
    }
}

// MARK: - 5. I mercati

private struct MercatiAnno: View {
    let t: TestiAnnoInsieme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TestaAnno(sopratitolo: "I mercati", titolo: t.titoloMercati,
                      sottotitolo: "Com'è andata per le tue posizioni finanziarie, con i valori registrati: un dato del passato, non un'indicazione per il futuro.")
            HStack(alignment: .top, spacing: M.spazioColonne) {
                VStack(alignment: .leading, spacing: M.sottoSezione) {
                    SezioneAnno(titolo: "Com'è andata")
                    ForEach(Array(t.testoMercati.enumerated()), id: \.offset) { _, frase in
                        TestoAnno(testo: frase)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                if !t.crisiAConfronto.isEmpty {
                    crisi.frame(width: M.colonnaLaterale + M.colonnaCifra, alignment: .topLeading)
                }
            }
        }
    }

    /// Gli anni difficili del passato, per confronto: il calo delle azioni e quanto ci è voluto per recuperare.
    private var crisi: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "Anni difficili del passato")
            ForEach(t.crisiAConfronto) { k in
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: "\(k.anno) · \(k.titolo)")
                            .carattereApple(F.rigaForte)
                            .foregroundColor(K.titolo)
                        Spacer(minLength: M.spazioRiga)
                        Text(verbatim: "azioni \(CifreDoc.percento(k.variazione(.azioni), decimali: 0))")
                            .carattereApple(F.rigaCifra)
                            .foregroundColor(K.ambra)
                    }
                    Text(verbatim: k.recupero)
                        .carattereApple(F.rigaNota)
                        .foregroundColor(K.etichetta)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, M.spazioRiga / 2)
                .overlay(Rectangle().fill(K.filetto).frame(height: M.filetto), alignment: .bottom)
            }
            Text(verbatim: "Variazioni indicative, arrotondate, da indici pubblici.")
                .carattereApple(F.rigaNota)
                .foregroundColor(K.etichetta)
                .padding(.top, M.spazioRiga)
        }
    }
}

// MARK: - 6. Cosa ci aspetta

private struct ProssimoAnno: View {
    let t: TestiAnnoInsieme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TestaAnno(sopratitolo: "Cosa ci aspetta", titolo: t.titoloProssimo,
                      sottotitolo: "Le scadenze \(TestiAnnoInsieme.periodoAvanti), il prossimo incontro e i passi da fare insieme.")
            HStack(alignment: .top, spacing: M.spazioColonne) {
                scadenze.frame(maxWidth: .infinity, alignment: .topLeading)
                passi.frame(width: M.colonnaLaterale + M.colonnaCifra, alignment: .topLeading)
            }
        }
    }

    private var scadenze: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "Il prossimo incontro")
            VoceElencoAnno(testo: t.incontroProssimo, colore: K.sopratitolo)
            SezioneAnno(titolo: "Le scadenze")
            if t.a.scadenze.isEmpty {
                TestoAnno(testo: "Nessuna scadenza nei prossimi 12 mesi.")
            }
            ForEach(t.a.scadenze.prefix(R.scadenze)) { s in
                HStack(alignment: .firstTextBaseline, spacing: M.spazioRiga) {
                    Text(verbatim: CifreDoc.data(s.data))
                        .carattereApple(F.rigaCifra)
                        .foregroundColor(K.titolo)
                        .lineLimit(1)
                        .frame(width: M.colonnaData, alignment: .leading)
                    Text(verbatim: s.titolo)
                        .carattereApple(F.riga)
                        .foregroundColor(K.testo)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                    if let c = s.canale {
                        EtichettaCanaleStampa(canale: c, compatta: true)
                    }
                }
                .frame(minHeight: M.riga)
                .overlay(Rectangle().fill(K.filetto).frame(height: M.filetto), alignment: .bottom)
            }
            AltriAnno(altri: t.a.scadenze.count - R.scadenze)
        }
    }

    private var passi: some View {
        VStack(alignment: .leading, spacing: 0) {
            SezioneAnno(titolo: "I prossimi passi")
            if t.prossimiPassi.isEmpty {
                TestoAnno(testo: "Continuiamo così e ci rivediamo al prossimo riesame.")
            }
            ForEach(Array(t.prossimiPassi.enumerated()), id: \.offset) { _, passo in
                VoceElencoAnno(testo: passo, colore: K.positivo)
            }
        }
    }
}

// MARK: - Il documento

extension DocumentoStampabile {
    /// Il report «Un anno insieme» (A4 orizzontale, per il cliente).
    init(_ t: TestiAnnoInsieme) {
        self.init(report: t.titoloDocumento, cliente: t.cliente, pagine: ReportAnnoInsieme.pagine(t))
    }
}

extension StatoShell {
    /// I testi e i numeri di «Un anno insieme» di un cliente (nil senza il cliente).
    func testiAnnoInsieme(_ id: String, oggi: Date = Date()) -> TestiAnnoInsieme? {
        guard let c = cliente(id) else { return nil }
        let mie = posizioniCliente(id)
        let protezione = MotoreProtezioneFamiglia.calcola(mie, cliente: c, analisi: analisi360(id).protezione, data: oggi)
        let a = MotoreAnnoInsieme.calcola(cliente: c, posizioni: mie, appuntamenti: appuntamentiCliente(id),
                                          incontri: incontriCliente(id), obiettivi: obiettiviCliente(id),
                                          protezione: protezione, oggi: oggi)
        return TestiAnnoInsieme(a)
    }
}
