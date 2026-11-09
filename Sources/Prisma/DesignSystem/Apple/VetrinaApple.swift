import SwiftUI

// Vetrina del tema Apple: tutti i componenti di DesignSystem/Apple su una pagina, sopra l'acqua della scrivania.
// Serve alle istantanee «400-vetrina-apple» e «400-vetrina-apple-scuro» (Istantanee.swift), dove ogni componente
// si disegna subito nello stato finale: numeri completi, anelli pieni, linee tracciate, liste spuntate.
// Non è una schermata dell'app: i dati sono di prova, presi dal template (Design/template-apple.html).

extension Tema.Apple.Misura {
    /// Misure della vetrina (solo per le istantanee del tema).
    enum Vetrina {
        /// Distanza dai bordi della scrivania.
        static let margine: CGFloat = Spazio.margineScrivania
        /// Spazio fra i riquadri e fra le righe.
        static let spazio: CGFloat = Spazio.colonneScrivania
        /// Spazio fra gli elementi dentro un riquadro.
        static let spazioInterno: CGFloat = Spazio.cifre
        /// Larghezza della colonna dei controlli, accanto al grafico.
        static let colonnaControlli: CGFloat = 430
        /// Larghezza della scheda che si inclina.
        static let scheda: CGFloat = 300
        /// Larghezza del cursore.
        static let cursore: CGFloat = 260
        /// Pallino della legenda degli anelli.
        static let pallinoLegenda: CGFloat = 10
        /// Larghezza della barra dei canali nella vetrina (più stretta dei 520 del template).
        static let barraCanali: CGFloat = 360
        /// «Luce»: il telefono disegnato in piccolo e la tela di prova.
        static let scalaTelefono: CGFloat = 0.16
        static let tela = CGSize(width: 150, height: 90)
        static let voceNovita: CGFloat = 300
        /// «Luce» giro 15: la busta della capsula in piccolo e lo spazio fra i nodi della spedizione.
        static let scalaBusta: CGFloat = 0.24
        static let spazioNodi: CGFloat = Spazio.cifre * 2
        /// Il punto della barra del film nella vetrina (5 secondi su 20).
        static let tempoFilm: Double = 5
        static let durataFilm: Double = 20
    }
}

/// La vetrina dei componenti del tema Apple (per le istantanee).
struct VetrinaApple: View {
    /// Forza della pioggia dello sfondo (nelle istantanee l'acqua è comunque ferma).
    var intensita: Double = 0

    @State private var conProposte = true
    @State private var acqua = true
    @State private var versamento = 250.0

    private typealias M = Tema.Apple.Misura.Vetrina

    var body: some View {
        ZStack(alignment: .topLeading) {
            Materiale.SfondoScrivania(intensita: intensita)
            VStack(alignment: .leading, spacing: M.spazio) {
                intestazione
                rigaCifre
                rigaGrafico
                rigaSchede
                rigaLuce
                rigaUscite
                Spacer(minLength: 0)
            }
            .padding(M.margine)
        }
    }

    // MARK: Intestazione (sulla scrivania: qui sta l'unico vetro, mai sotto un altro vetro)

    private var intestazione: some View {
        HStack(alignment: .firstTextBaseline, spacing: M.spazio) {
            Text("Tema Apple")
                .carattereApple(Tema.Apple.Carattere.saluto)
                .foregroundColor(Tema.Apple.Colore.inchiostroAcqua)
            Text("Vetrina dei componenti, nello stato finale")
                .carattereApple(Tema.Apple.Carattere.corpo)
                .foregroundColor(Tema.Apple.Colore.inchiostroAcqua2)
            Spacer(minLength: 0)
            Button("Cerca ovunque") {}
                .buttonStyle(.appleVetro)
        }
    }

    // MARK: Numeri, anelli, completamento

    private var rigaCifre: some View {
        HStack(alignment: .top, spacing: M.spazio) {
            RiquadroVetrinaApple(titolo: "Numeri che si contano") { numeri }
            RiquadroVetrinaApple(titolo: "Anelli concentrici") { anelli }
            RiquadroVetrinaApple(titolo: "Spunta e «Ti preparo»") { completamento }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var numeri: some View {
        VStack(alignment: .leading, spacing: M.spazioInterno) {
            CifraVetrinaApple(etichetta: "Patrimonio") {
                NumeroCheConta(318_400, indice: 0).carattereApple(Tema.Apple.Carattere.valore)
            }
            CifraVetrinaApple(etichetta: "Quota Alleanza") {
                NumeroCheConta(48, formato: .percentuale, indice: 1).carattereApple(Tema.Apple.Carattere.valore)
            }
            CifraVetrinaApple(etichetta: "Mesi di riserva") {
                NumeroCheConta(4.5, formato: .mesi, indice: 2).carattereApple(Tema.Apple.Carattere.valore)
            }
        }
    }

    private static let vociAnelli: [AnelloVetrinaApple] = [
        AnelloVetrinaApple(voce: VoceAnello(id: "previdenza", valore: 72, colore: Tema.Apple.Colore.anello1),
                           nome: "Previdenza"),
        AnelloVetrinaApple(voce: VoceAnello(id: "protezione", valore: 52, colore: Tema.Apple.Colore.anello2),
                           nome: "Protezione"),
        AnelloVetrinaApple(voce: VoceAnello(id: "investimenti", valore: 86, colore: Tema.Apple.Colore.anello3),
                           nome: "Investimenti"),
    ]

    private var anelli: some View {
        let g = Tema.Apple.Grafico.Anello.aree
        return HStack(spacing: M.spazio) {
            AnelliConcentrici(voci: Self.vociAnelli.map { $0.voce }, misura: g.misura, spessore: g.spessore) {
                NumeroCheConta(70, formato: .percentuale)
                    .carattereApple(.centroAnello(Tema.Apple.Carattere.dimensioniCentroAnello[4]))
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
            }
            VStack(alignment: .leading, spacing: M.spazioInterno) {
                ForEach(Self.vociAnelli) { a in
                    VoceLegendaVetrinaApple(nome: a.nome, valore: a.voce.valore, colore: a.voce.colore)
                }
            }
        }
    }

    private var completamento: some View {
        HStack(alignment: .top, spacing: M.spazio) {
            SpuntaDisegnata(disegnata: true)
            ListaTiPreparo(voci: ["Il quadro di Giulia", "Le scadenze dei prossimi mesi",
                                  "Il confronto con le proposte"],
                           avviata: true)
        }
    }

    // MARK: Grafico e controlli

    private var rigaGrafico: some View {
        HStack(alignment: .top, spacing: M.spazio) {
            RiquadroVetrinaApple(titolo: "Portafoglio · in essere e con le proposte") { grafico }
            RiquadroVetrinaApple(titolo: "Controlli") { controlli }
                .frame(width: M.colonnaControlli)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var grafico: some View {
        VStack(alignment: .leading, spacing: M.spazioInterno) {
            SegmentatoPillola(selezione: $conProposte, voci: [(false, "In essere"), (true, "Con le proposte")])
            GraficoPortafoglio(dati: Self.datiGrafico, progresso: conProposte ? 1 : 0)
        }
    }

    /// I valori del template (migliaia di euro): fascia v + i·4,2 sopra e v − i·3,6 sotto.
    private static let datiGrafico: DatiGraficoPortafoglio = {
        let storia: [Double] = [1086, 1091, 1097, 1102, 1088, 1079, 1093, 1101, 1108, 1112, 1119, 1124.35]
        let stima: [Double] = [1124.35, 1131, 1140, 1149, 1157, 1164, 1171]
        let alta = stima.enumerated().map { $0.element + Double($0.offset) * 4.2 }
        let bassa = stima.enumerated().map { $0.element - Double($0.offset) * 3.6 }
        let mesi = ["dic", "gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov",
                    "dic", "gen", "feb", "mar", "apr", "mag", "giu"]
        return DatiGraficoPortafoglio(storia: storia, stima: stima, stimaAlta: alta, stimaBassa: bassa, mesi: mesi,
                                      minimo: 1060, massimoInEssere: 1130, massimoConProposte: 1185,
                                      etichettaStima: "stima giugno 2027")
    }()

    private var controlli: some View {
        VStack(alignment: .leading, spacing: M.spazioInterno) {
            Toggle(isOn: $acqua) { Text("L'acqua della scrivania") }
                .toggleStyle(.apple)
            CursoreApple(valore: $versamento, intervallo: 50...1_000, passo: 50, etichetta: "Versamento mensile",
                         formato: .euro)
                .frame(width: M.cursore)
            HStack(spacing: M.spazioInterno) {
                Button("Crea backup") {}.buttonStyle(.applePrimario)
                Button("Annulla") {}.buttonStyle(.apple)
                Button("Dettagli") {}.buttonStyle(.appleSobrio)
            }
            // Le chip della prova del fuoco (Orizzonte, giro 4): accesa e spenta
            HStack(spacing: M.spazioInterno) {
                ChipApple(titolo: "Mercati \(Formati.meno)25%", accesa: true) {}
                ChipApple(titolo: "Come nel 2008", accesa: false) {}
            }
        }
    }

    // MARK: Scheda, barre, canali

    private var rigaSchede: some View {
        HStack(alignment: .top, spacing: M.spazio) {
            RiquadroVetrinaApple(titolo: "Scheda che si inclina") { scheda }
            RiquadroVetrinaApple(titolo: "Barre") { barre }
            RiquadroVetrinaApple(titolo: "Canali") { canali }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var scheda: some View {
        VStack(alignment: .leading, spacing: M.spazioInterno) {
            Text("Prossimo incontro")
                .carattereApple(Tema.Apple.Carattere.sottotitolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro3)
            Text("Giulia Rossi · riesame annuale")
                .carattereApple(Tema.Apple.Carattere.titoloRiga)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            EtichettaCanaleApple(canale: .alleanza, compatta: true)
        }
        .padding(Tema.Apple.Misura.Padding.cardPiccola)
        .frame(width: M.scheda, alignment: .leading)
        .superficieApple(.cardPiatta)
        .inclinazione(massimo: Tema.Apple.Moto.Inclinazione.massimoAree)
    }

    private var barre: some View {
        VStack(alignment: .leading, spacing: M.spazioInterno) {
            BarraPiena(frazione: 0.64, colore: Tema.Apple.Colore.Area.previdenza)
            BarraPienaSegmenti.composizione([
                PezzoBarraPiena(id: "azionario", peso: 45, colore: Tema.Apple.Colore.Composizione.azionario),
                PezzoBarraPiena(id: "obbligazionario", peso: 30, colore: Tema.Apple.Colore.Composizione.obbligazionario),
                PezzoBarraPiena(id: "gestione", peso: 15, colore: Tema.Apple.Colore.Composizione.gestioneSeparata),
                PezzoBarraPiena(id: "liquidita", peso: 10, colore: Tema.Apple.Colore.Composizione.liquidita),
            ], indice: 1)
            BarraPienaSegmenti.canali(alleanza: 48, indipendente: 52, indice: 2)
                .frame(width: M.barraCanali)
            // La barra oggi/dopo della prova del fuoco (Orizzonte, giro 4) nei tre colori del calo
            HStack(spacing: M.spazioInterno) {
                BarraOggiDopo(oggi: 0.62, dopo: 0.58, colore: Tema.Apple.Posizioni.Fuoco.Barra.tranquillo)
                BarraOggiDopo(oggi: 0.70, dopo: 0.62, colore: Tema.Apple.Posizioni.Fuoco.Barra.attenzione)
                BarraOggiDopo(oggi: 0.90, dopo: 0.74, colore: Tema.Apple.Posizioni.Fuoco.Barra.allarme)
            }
            .frame(width: M.barraCanali)
        }
    }

    private var canali: some View {
        VStack(alignment: .leading, spacing: M.spazioInterno) {
            EtichettaCanaleApple(canale: .alleanza)
            EtichettaCanaleApple(canale: .indipendente)
            HStack(spacing: M.spazioInterno) {
                EtichettaCanaleApple(canale: .alleanza, compatta: true)
                EtichettaCanaleApple(canale: .indipendente, compatta: true)
            }
            // I gettoni della linea della vita (Orizzonte, giro 4): entrata, uscita, pensione
            HStack(spacing: M.spazioInterno) {
                GettoneEventoApple(nome: "Eredità", dettaglio: "62 anni", genere: .entrata)
                GettoneEventoApple(nome: "Casa", dettaglio: "40 anni", genere: .uscita)
                GettoneEventoApple(nome: "Pensione", dettaglio: "67 anni", genere: .pensione)
            }
            // La pillola della copia cifrata (Orizzonte, giro 8): sul telefono quando il Mac non risponde
            PillolaSenzaMacApple()
        }
    }
}

// MARK: - «Luce»: tasselli, voce delle novità, telefono, tele (Design/template-luce-specifica.md §1.4.7)

extension VetrinaApple {
    var rigaLuce: some View {
        HStack(alignment: .top, spacing: M.spazio) {
            RiquadroVetrinaApple(titolo: "Tasselli e glifi di Luce") {
                VStack(alignment: .leading, spacing: M.spazioInterno) {
                    HStack(alignment: .bottom, spacing: M.spazioInterno) {
                        TasselloGlifo(glifo: .prisma, lato: Tema.Apple.Tassello.latoVoce)
                        TasselloGlifo(glifo: .luce, lato: Tema.Apple.Tassello.latoSala, raggio: Tema.Apple.Raggio.voce)
                        TasselloGlifo(glifo: .dadi, lato: Tema.Apple.Tassello.latoSalaGrande, raggio: Tema.Apple.Raggio.voce)
                        TasselloGlifo(glifo: .notte, lato: Tema.Apple.Tassello.latoSala, raggio: Tema.Apple.Raggio.voce)
                    }
                    VoceNovitaVetrina()
                        .frame(width: M.voceNovita, alignment: .leading)
                }
            }
            RiquadroVetrinaApple(titolo: "Telefono disegnato") {
                // «Luce» giro 13: la carta d'identità fac-simile (dati di prova) e il pulsante della nota vocale, fermi
                TelefonoDisegnato {
                    ZStack(alignment: .top) {
                        SchermoTelefonoVuoto()
                        CartaIdentitaDisegnata(accesi: [.cognome, .nome, .dataNascita])
                            .rotationEffect(.degrees(Tema.Apple.NuovoCliente.Carta.rotazione))
                            .padding(.horizontal, Tema.Apple.NuovoCliente.Carta.lati)
                            .padding(.top, Tema.Apple.NuovoCliente.Carta.dallAlto)
                        VStack {
                            Spacer(minLength: 0)
                            FacciaPulsanteRegistra(ascolta: false, fatto: false)
                                .padding(.bottom, Tema.Apple.NotaVocale.Registra.dalFondo)
                        }
                    }
                }
                    .scaleEffect(M.scalaTelefono)
                    .frame(width: Tema.Apple.Apparecchio.larghezza * M.scalaTelefono,
                           height: Tema.Apple.Apparecchio.altezza * M.scalaTelefono)
            }
            RiquadroVetrinaApple(titolo: "Tela animata e shader (fermi)") {
                HStack(spacing: M.spazioInterno) {
                    TelaAnimata(tempoFinale: 1) { c, misura, t in
                        let r = CGRect(origin: .zero, size: misura)
                        c.fill(Path(roundedRect: r, cornerRadius: Tema.Apple.Raggio.giorno), with: .color(Tema.Apple.Colore.chip))
                        let lato = misura.height * 0.5 * CGFloat(min(1, max(0, t)))
                        c.fill(Path(ellipseIn: CGRect(x: misura.width / 2 - lato / 2, y: misura.height / 2 - lato / 2,
                                                      width: lato, height: lato)),
                               with: .color(Tema.Apple.Colore.Glifi.luce))
                    }
                    .frame(width: M.tela.width, height: M.tela.height)
                    TelaShader(sorgente: ShaderTela.prova, parametri: SIMD4<Float>(0.36, 0.29, 0.78, 1)) {
                        RoundedRectangle(cornerRadius: Tema.Apple.Raggio.giorno, style: .continuous)
                            .fill(LinearGradient(colors: [Tema.Apple.Colore.Glifi.luce, Tema.Apple.Colore.Glifi.prisma],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .frame(width: M.tela.width, height: M.tela.height)
                    .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.Raggio.giorno, style: .continuous))
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - «Luce» giro 15: le cose date al cliente (condivisione, film, capsula, spedizione del sinistro)

extension VetrinaApple {
    var rigaUscite: some View {
        HStack(alignment: .top, spacing: M.spazio) {
            RiquadroVetrinaApple(titolo: "Foglio di condivisione") {
                // Nella vetrina non prepara nulla: il clic non apre il foglio
                PulsanteCondividi(titolo: "Condividi…", consensoWhatsApp: false, prepara: { nil })
            }
            RiquadroVetrinaApple(titolo: "Comandi del film") {
                comandiFilm
            }
            RiquadroVetrinaApple(titolo: "Busta della capsula") {
                HStack(spacing: M.spazioInterno) {
                    bustaPiccola(pronta: false)
                    bustaPiccola(pronta: true)
                }
            }
            RiquadroVetrinaApple(titolo: "Spedizione del sinistro") {
                HStack(spacing: M.spazioNodi) {
                    NodoSpedizione(stato: .fatta)
                    NodoSpedizione(stato: .adesso)
                    NodoSpedizione(stato: .futura)
                    NodoSpedizione(stato: .respinta)
                }
                .padding(.horizontal, Tema.Apple.Pratiche.Spedizione.alone)
                .padding(.vertical, Tema.Apple.Pratiche.Spedizione.alone)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// I comandi sotto lo schermo del film, fermi: pausa, barra e tempo (le misure di `Tema.Apple.SalaRacconti.Film`).
    private var comandiFilm: some View {
        HStack(spacing: Tema.Apple.SalaRacconti.Film.spazioComandi) {
            Text("❚❚")
                .carattereApple(Tema.Apple.SalaRacconti.Film.simboloPulsante)
                .foregroundColor(Tema.Apple.SalaRacconti.Film.coloreSimbolo)
                .frame(width: Tema.Apple.SalaRacconti.Film.pulsanteTondo, height: Tema.Apple.SalaRacconti.Film.pulsanteTondo)
                .background(Circle().fill(Tema.Apple.SalaRacconti.Film.fondoPulsanteTondo))
            BarraFilm(frazione: M.tempoFilm / M.durataFilm, attiva: false) { _ in }
            Text(TestiFilm.tempo(M.tempoFilm, totale: M.durataFilm))
                .carattereApple(Tema.Apple.SalaRacconti.Film.tempo)
                .foregroundColor(Tema.Apple.SalaRacconti.Film.coloreTempo)
                .frame(width: Tema.Apple.SalaRacconti.Film.larghezzaTempo)
                .lineLimit(1)
        }
    }

    /// La busta chiusa con il sigillo: viola mentre si sigilla, arancio quando è pronta.
    private func bustaPiccola(pronta: Bool) -> some View {
        BustaCapsula(lemboChiuso: true, sigilloImpresso: true, pronta: pronta)
            .scaleEffect(M.scalaBusta)
            .frame(width: Tema.Apple.SalaRacconti.Capsula.busta.width * M.scalaBusta,
                   height: Tema.Apple.SalaRacconti.Capsula.busta.height * M.scalaBusta)
    }
}

/// Una voce della griglia del pannello Novità, ferma, con il fondo del passaggio (per la vetrina).
private struct VoceNovitaVetrina: View {
    private typealias N = Tema.Apple.Novita

    var body: some View {
        let voce = NovitaLuce.dopoLaFirma
        HStack(spacing: N.spazioVoceGriglia) {
            TasselloGlifo(glifo: voce.glifo, lato: N.tasselloVoce)
            VStack(alignment: .leading, spacing: 0) {
                Text(voce.titolo)
                    .carattereApple(N.titoloVoceGriglia)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text(voce.frase)
                    .carattereApple(N.fraseVoceGriglia)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            .lineLimit(1)
        }
        .padding(N.paddingVoceGriglia)
        .background { RoundedRectangle(cornerRadius: N.raggioVoce, style: .continuous).fill(N.fondoPassaggio) }
    }
}

/// Un anello della vetrina con il nome della sua voce di legenda.
private struct AnelloVetrinaApple: Identifiable {
    let voce: VoceAnello
    let nome: String
    var id: String { voce.id }
}

/// Un riquadro della vetrina: titolo piccolo e contenuto su un pannello senza sfocatura (niente vetri annidati).
private struct RiquadroVetrinaApple<Contenuto: View>: View {
    let titolo: String
    let contenuto: Contenuto

    init(titolo: String, @ViewBuilder contenuto: () -> Contenuto) {
        self.titolo = titolo
        self.contenuto = contenuto()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tema.Apple.Misura.Vetrina.spazioInterno) {
            Text(titolo)
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            contenuto
        }
        .padding(Tema.Apple.Misura.Padding.cardMedia)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(.card)
    }
}

/// Un numero con la sua etichetta sopra.
private struct CifraVetrinaApple<Numero: View>: View {
    let etichetta: String
    let numero: Numero

    init(etichetta: String, @ViewBuilder numero: () -> Numero) {
        self.etichetta = etichetta
        self.numero = numero()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(etichetta)
                .carattereApple(Tema.Apple.Carattere.sottotitolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro3)
            numero
                .foregroundColor(Tema.Apple.Colore.inchiostro)
        }
    }
}

/// Una voce della legenda degli anelli: pallino, nome e percentuale.
private struct VoceLegendaVetrinaApple: View {
    let nome: String
    let valore: Double
    let colore: Color

    var body: some View {
        let lato = Tema.Apple.Misura.Vetrina.pallinoLegenda
        HStack(spacing: Tema.Apple.Misura.Spazio.etichettaCanale) {
            Circle()
                .fill(colore)
                .frame(width: lato, height: lato)
            Text(nome)
                .carattereApple(Tema.Apple.Carattere.voceLista)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            NumeroCheConta(valore, formato: .percentuale)
                .carattereApple(Tema.Apple.Carattere.barra)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
        }
    }
}
