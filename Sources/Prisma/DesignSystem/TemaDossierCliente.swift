import SwiftUI

// MARK: - Gettoni e componenti delle schede Documenti e Obiettivi dentro il cliente (tema Liquid Glass)
// Le due app accorpate in Clienti sul Mac: i documenti a gruppi (personali, dei prodotti, da Prisma, da collegare)
// con le tessere dei conteggi in alto, e gli obiettivi con l'anello della quota coperta e le tessere con la barra.

extension Tema.Misura {
    /// Misure delle schede Documenti e Obiettivi del dossier del cliente.
    enum DossierCliente {
        /// Fascia delle tessere in cima alla scheda Documenti (fuori dallo scorrimento): i margini del dossier.
        static let fasciaDocumenti = EdgeInsets(top: 12, leading: 17, bottom: 12, trailing: 17)
        /// Tessera di un conteggio (filtro): margini, spazio tra cifra e nome, raggio, bordo della scelta.
        static let tesseraFiltro = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let spazioTesseraFiltro: CGFloat = 2
        static let minimaTesseraFiltro: CGFloat = 96
        static let bordoScelta: CGFloat = 1.5
        /// Pallino del tono accanto al nome della tessera.
        static let pallinoTono: CGFloat = 7
        /// Sotto questa larghezza elenco e dettaglio vanno uno sotto l'altro.
        static let documentiAffiancati: CGFloat = 720
        /// Elenco sopra il dettaglio, quando sono impilati: la sua quota d'altezza.
        static let quotaElencoImpilato: CGFloat = 0.42
        /// Testata del gruppo di una posizione nell'elenco (nome e canale), rientrata sotto la sezione.
        static let testataProdotto = EdgeInsets(top: 8, leading: 14, bottom: 3, trailing: 12)
        static let spazioTestataProdotto: CGFloat = 6

        /// Scheda Obiettivi: spazio tra i blocchi, la cifra principale accanto all'anello.
        static let spazioBlocchi: CGFloat = 14
        static let spazioCifra: CGFloat = 16
        static let spazioTestiCifra: CGFloat = 3
        /// La cifra principale (anello e totale) e i tre numeri accanto: sotto la somma delle due vanno uno sotto l'altro.
        static let cifraPrincipale: CGFloat = 330
        static let numeriCifra: CGFloat = 420
        /// L'anello della quota coperta e il suo spessore.
        static let anello: CGFloat = 108
        static let spessoreAnello: CGFloat = 14
        /// La sintesi a parole (Profilo) in cima: margini del riquadro.
        static let sintesi = EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12)
        static let spazioSintesi: CGFloat = 8
        /// Griglia delle tessere degli obiettivi: larghezza minima di una tessera, quante colonne al massimo (le
        /// tessere si allargano a occupare la riga) e spazio tra le tessere.
        static let tesseraObiettivoMinima: CGFloat = 280
        static let colonneTessereObiettivi = 3
        static let spazioGriglia: CGFloat = 12
        /// Tessera di un obiettivo: margini (la barretta dell'area a sinistra) e spazio tra le righe.
        static let tesseraObiettivo = EdgeInsets(top: 12, leading: 17, bottom: 12, trailing: 15)
        static let spazioTesseraObiettivo: CGFloat = 6
        /// Capsula della priorità.
        static let priorita = EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6)
        /// Posizioni collegate nella tessera: spazio tra le capsule, quante se ne mostrano.
        static let spazioCollegate: CGFloat = 4
        static let collegateMostrate = 2
        /// L'obiettivo scelto: colonna dei dati accanto a probabilità e posizioni, e sotto quale larghezza va sotto.
        static let colonnaDati: CGFloat = 320
        static let spazioLavoro: CGFloat = 16
        static let margineLavoro = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        /// Dettaglio dell'obiettivo: spazio tra le parti e larghezza delle etichette delle cifre.
        static let spazioDettaglio: CGFloat = 12
        static let etichettaDato: CGFloat = 130
        static let spazioAzioni: CGFloat = 6
        static let margineDettaglio: CGFloat = 14
        /// Suggerimenti dagli eventi di vita: righe e larghezza massima nel vuoto.
        static let spazioSuggerimenti: CGFloat = 6
        static let rigaSuggerimento: CGFloat = 4
        static let suggerimentiVuoto: CGFloat = 520
        static let pulsanteSuggerimento = EdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9)
        /// Spaziatura delle lettere: area in maiuscolo nelle tessere, occhielli delle sezioni.
        static let spaziaturaArea: CGFloat = 0.5
        static let spaziaturaOcchiello: CGFloat = 0.8

        /// Quadro d'insieme degli obiettivi (anello, totale, stati, mese): margini e larghezza della tessera del mese.
        static let quadroObiettivi = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        static let tesseraMese: CGFloat = 200
        /// Riepilogo degli stati nel quadro: pallino, spazio tra le righe e tra pallino e testo.
        static let pallinoStato: CGFloat = 8
        static let spazioStati: CGFloat = 4
        static let spazioPallinoStato: CGFloat = 6
        /// Anellino di avanzamento nella tessera di un obiettivo e il suo spessore.
        static let anelloTessera: CGFloat = 50
        static let spessoreAnelloTessera: CGFloat = 5
        /// Tessera: spazio tra l'anellino e i testi, tra le righe dei testi.
        static let spazioAnelloTessera: CGFloat = 12
        static let spazioTestiTessera: CGFloat = 2
        /// L'obiettivo scelto: spazio tra titolo, stato e nota nella testata, tra le azioni.
        static let spazioTestata: CGFloat = 4
        static let spazioTitoloStato: CGFloat = 10
        /// Probabilità: i dieci pallini e lo spazio tra loro; colonna della probabilità accanto al grafico.
        static let pallinoProbabilita: CGFloat = 12
        static let spazioPallini: CGFloat = 4
        static let colonnaProbabilita: CGFloat = 270
        static let graficoMinimo: CGFloat = 320
        /// Grafico della traiettoria (ventaglio degli scenari) dell'obiettivo scelto: altezza.
        static let traiettoria: CGFloat = 150
        /// Capsule delle posizioni da accendere o spegnere: margini e spazio tra le capsule.
        static let capsulaPosizione = EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 10)
        static let spazioCapsule: CGFloat = 6
        /// Le cifre dell'obiettivo nella colonna del dettaglio (iPad): due per riga.
        static let colonneCifre = 2
    }
}

extension Tema.Testo {
    /// Caratteri della scheda Obiettivi del dossier.
    enum DossierCliente {
        /// La percentuale dentro l'anellino della tessera.
        static let percentualeAnello = Tema.Testo.sf(12, .bold)
        /// Il titolo dell'obiettivo scelto.
        static let titoloObiettivo = Tema.Testo.sf(19, .bold)
        static let spaziaturaTitolo = Tema.Testo.spaziatura(-0.012, 19)
        /// Il conteggio accanto al pallino dello stato nel quadro.
        static let conteggioStato = Tema.Testo.sf(13, .bold)
        /// Simbolo della capsula di una posizione (spunta o cerchio).
        static let simboloCapsula = Tema.Testo.sf(12, .semibold)
    }
}

extension Tema.Colore {
    /// Colori delle schede Documenti e Obiettivi del dossier.
    enum DossierCliente {
        /// Toni delle tessere dei conteggi: da leggere (accento), con differenze (arancio della proposta),
        /// da collegare (secondario).
        static let daLeggere = Tema.Colore.accento
        static let conDifferenze = Tema.Colore.testoProposta
        static let daCollegare = Tema.Colore.inchiostroSecondario
        /// Anello degli obiettivi: la parte mancante resta nel pozzetto.
        static let anelloFondo = Tema.Colore.pozzetto
        /// Stato dell'obiettivo, a semaforo (gli stessi colori della probabilità di arrivarci).
        static let statoRaggiunto = Colori.Bisogni.confermato
        static let statoInLinea = Tema.Colore.MotoriAnalisi.probabilitaAlta
        static let statoDaRinforzare = Tema.Colore.MotoriAnalisi.probabilitaMedia
        static let statoNonCiArriva = Tema.Colore.MotoriAnalisi.probabilitaBassa
        /// Pallini della probabilità spenti.
        static let pallinoSpento = Tema.Colore.pozzettoScuro
        /// Capsula di una posizione: accesa (lavora per l'obiettivo) o spenta.
        static let capsulaAccesa = Tema.Colore.selezione
        static let capsulaSpenta = Tema.Colore.pozzetto
        static let simboloAcceso = Tema.Colore.accento
        static let simboloSpento = Tema.Colore.inchiostroTerziario
    }
}

// MARK: - Componenti

/// Tessera di un conteggio che fa anche da filtro (Documenti: da leggere, con differenze, da collegare): la cifra
/// grande, il nome con il pallino del tono; scelta con il contorno d'accento. Con zero resta spenta.
struct TesseraFiltroDocumenti: View {
    let titolo: String
    let valore: Int
    var tono: Color? = nil
    let attiva: Bool
    let azione: () -> Void

    /// Nel tema Apple: la tile del template (raggio 18) con il numero che si conta; la scelta col bordo accento.
    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        let forma = RoundedRectangle(cornerRadius: Tema.Apple.AltreApp.raggioTile, style: .continuous)
        let a = Tema.Apple.Colore.self
        Button(action: azione) {
            VStack(alignment: .leading, spacing: m.spazioTesseraFiltro) {
                NumeroCheConta(Double(valore), formato: .intero)
                    .carattereApple(Tema.Apple.AltreApp.cifraPiccola)
                    .foregroundColor(valore == 0 ? a.inchiostro3 : a.inchiostro)
                HStack(spacing: m.spazioTestataProdotto) {
                    if let tono {
                        Circle().fill(valore == 0 ? a.inchiostro3 : tono)
                            .frame(width: m.pallinoTono, height: m.pallinoTono)
                    }
                    Text(titolo)
                        .font(Tema.Apple.AltreApp.secondario.fontLeggibile)
                        .foregroundColor(a.inchiostro2)
                        .lineLimit(1)
                }
            }
            .padding(m.tesseraFiltro)
            .frame(minWidth: m.minimaTesseraFiltro, alignment: .leading)
            .fondoPassaggio(.arrotondata(Tema.Apple.AltreApp.raggioTile), sopra: Tema.Apple.AltreApp.sopra)
            .superficieApple(Tema.Apple.Superficie.tile)
            .overlay {
                if attiva {
                    forma.strokeBorder(a.accento, lineWidth: m.bordoScelta).allowsHitTesting(false)
                }
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .help(attiva ? "Mostra tutti i documenti" : "Mostra solo: \(titolo.lowercased())")
        .accessibilityLabel("\(titolo): \(valore)")
    }
}

/// Testata del gruppo di una posizione o di una scheda nell'elenco dei documenti: nome, canale, conteggio.
struct TestataProdottoDocumenti: View {
    let titolo: String
    let canale: Canale?
    let conteggio: Int

    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        HStack(spacing: m.spazioTestataProdotto) {
            Text(titolo)
                .font(Tema.Testo.titolo)
                .foregroundColor(Tema.Colore.inchiostro)
                .lineLimit(1)
            if let canale { EtichettaCanale(canale: canale, compatta: true) }
            Spacer(minLength: m.spazioTestataProdotto)
            Text("\(conteggio)")
                .font(Tema.Testo.chipPiccolo)
                .foregroundColor(Tema.Colore.inchiostroTerziario)
        }
        .padding(m.testataProdotto)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Anello della quota coperta degli obiettivi: una fetta per obiettivo (colore dell'area, quanto è già da parte),
/// il resto nel pozzetto; al centro la percentuale.
struct AnelloObiettivi: View {
    struct Fetta: Identifiable {
        let id: String
        /// Quota del totale degli obiettivi (0–1).
        let quota: Double
        let colore: Color
    }

    let fette: [Fetta]
    let etichetta: String
    let valore: String

    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        let inizi = fette.indices.map { i in fette[..<i].reduce(0.0) { $0 + $1.quota } }
        ZStack {
            Circle().stroke(Tema.Colore.DossierCliente.anelloFondo, lineWidth: m.spessoreAnello)
            ForEach(Array(fette.enumerated()), id: \.element.id) { i, f in
                Circle()
                    .trim(from: CGFloat(min(inizi[i], 1)), to: CGFloat(min(inizi[i] + f.quota, 1)))
                    .stroke(f.colore, style: StrokeStyle(lineWidth: m.spessoreAnello, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 0) {
                Text(valore).font(Tema.Testo.valoreTessera).foregroundColor(Tema.Colore.inchiostro)
                Text(etichetta).font(Tema.Testo.didascalia).foregroundColor(Tema.Colore.inchiostroSecondario)
            }
        }
        .padding(m.spessoreAnello / 2)
        .frame(width: m.anello, height: m.anello)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(etichetta): \(valore)")
    }
}

/// Anellino di avanzamento di un obiettivo (tessera): la quota già da parte del colore dell'area, il resto nel
/// pozzetto, la percentuale al centro.
struct AnelloAvanzamento: View {
    /// Quota raggiunta (0–1).
    let quota: Double
    let colore: Color

    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        let q = min(max(quota, 0), 1)
        ZStack {
            Circle().stroke(Tema.Colore.DossierCliente.anelloFondo, lineWidth: m.spessoreAnelloTessera)
            Circle()
                .trim(from: 0, to: CGFloat(q))
                .stroke(colore, style: StrokeStyle(lineWidth: m.spessoreAnelloTessera, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((q * 100).rounded()))%")
                .font(Tema.Testo.DossierCliente.percentualeAnello)
                .foregroundColor(Tema.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(m.spessoreAnelloTessera / 2)
        .frame(width: m.anelloTessera, height: m.anelloTessera)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Raggiunto al \(Int((q * 100).rounded())) per cento")
    }
}

/// La probabilità a colpo d'occhio: dieci pallini, accesi quante sono le possibilità su dieci.
struct PalliniProbabilita: View {
    /// Possibilità su dieci (0–10).
    let suDieci: Int
    let colore: Color

    var body: some View {
        let m = Tema.Misura.DossierCliente.self
        HStack(spacing: m.spazioPallini) {
            ForEach(0..<10, id: \.self) { i in
                Circle()
                    .fill(i < suDieci ? colore : Tema.Colore.DossierCliente.pallinoSpento)
                    .frame(width: m.pallinoProbabilita, height: m.pallinoProbabilita)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(suDieci) possibilità su 10")
    }
}
