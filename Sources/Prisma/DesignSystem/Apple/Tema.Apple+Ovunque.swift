import SwiftUI

// Impostazioni › iPhone e iPad, «Prisma ovunque» (Design/template-novita-specifica.md §13, giro 8 di Orizzonte).
// Le viste stanno in DesignSystem/Apple/SchemaOvunqueApple.swift (lo schema Mac → iCloud Drive → iPhone, la pillola
// «Senza Mac · copia cifrata», il telefono d'esempio) e in Shell/ImpostazioniOvunque.swift (la pagina, il modulo della
// passphrase, «Modifiche in attesa» e «Da decidere»). Qui solo i valori, ricavati dal tema Apple e dal template.

extension Tema.Apple.Colore {
    /// Il testo arancio delle pillole (la pillola «Senza Mac · copia cifrata»): `#B45309` in chiaro; in scuro un arancio
    /// più chiaro (`#F5A84B`), perché `#B45309` sul fondo arancio al 16% del vetro scuro non si legge.
    static let arancioTesto = Color.dinamico(chiaro: Color(hex: "#B45309"), scuro: Color(hex: "#F5A84B"))
}

extension Tema.Apple {
    enum Ovunque {
        // MARK: Pagina

        enum Pagina {
            /// La colonna della card e delle righe (720) e lo spazio fino al telefono d'esempio.
            static let colonna: CGFloat = 720
            static let spazioTelefono: CGFloat = 30
            /// Sotto la card dello schema, 12; fra le righe, quelle delle Impostazioni.
            static let sottoCard: CGFloat = 12
            static let fraRighe: CGFloat = Impostazioni.Riga.fraRighe
            /// Fra i gruppi della pagina (modulo, modifiche, cartella).
            static let fraGruppi: CGFloat = 22
        }

        // MARK: Card dello schema (§2.2)

        enum Card {
            /// `.card` senza ombra, raggio 22, padding 20×24, 12 sotto.
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.padding(20, 24)
            /// Riga di stato sotto il disegno: spazio 16, 6 sopra; titolo 17 bold, frase `.k` 3 sotto il titolo.
            static let spazioStato: CGFloat = 16
            static let sopraStato: CGFloat = 6
            static let titolo = Carattere(dimensione: 17, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let frase = Carattere.secondario
            static let coloreFrase = Colore.inchiostro2
            static let sottoTitolo: CGFloat = 3
            static let coloreErrore = Colore.rosso
        }

        // MARK: Schema Mac → iCloud Drive → iPhone (§2.2, coordinate del disegno)

        enum Schema {
            /// Il disegno 670 di larghezza; 170 di altezza (non 150 come nel template) perché «solo un file cifrato»
            /// a y = 164 si veda. Scala con la larghezza disponibile, mai oltre 1.
            static let larghezza: CGFloat = 670
            static let altezza: CGFloat = 170

            /// Spessore dei contorni (Mac, nuvola, telefono, arco del lucchetto).
            static let spessore: CGFloat = 3
            static let colore = Colore.inchiostro
            /// La nuvola e il lucchetto: `--r2` `#0A84FF`, uguale nello scuro; spenta quando iCloud Drive non risponde.
            static let blu = Colore.anello2
            static let bluSpento = Colore.inchiostro3

            // Il Mac (translate 40,40)
            static let origineMac = CGPoint(x: 40, y: 40)
            static let schermoMac = CGRect(x: 0, y: 6, width: 96, height: 62)
            static let raggioSchermoMac: CGFloat = 8
            static let baseMac = CGRect(x: -12, y: 70, width: 120, height: 8)
            static let raggioBaseMac: CGFloat = 4
            static let etichettaMac = CGPoint(x: 48, y: 108)

            // La nuvola (translate 285,40): M20 58 h62 a20 20 0 0 0 0-40 a28 28 0 0 0-54-4 a22 22 0 0 0-8 44 z
            static let origineNuvola = CGPoint(x: 285, y: 40)
            static let nuvolaInizio = CGPoint(x: 20, y: 58)
            static let nuvolaFondo = CGPoint(x: 82, y: 58)
            /// I tre archi del contorno, con i centri già risolti dagli archi SVG (stessi punti di partenza e arrivo).
            static let nuvolaDestra = (centro: CGPoint(x: 82, y: 38), arrivo: CGPoint(x: 82, y: 18))
            static let nuvolaAlto = (centro: CGPoint(x: 54.47, y: 23.12), arrivo: CGPoint(x: 28, y: 14))
            static let nuvolaSinistra = (centro: CGPoint(x: 24, y: 36), arrivo: CGPoint(x: 20, y: 58))
            /// Il lucchetto: corpo 22×18 a (40,28) raggio 3 pieno; arco M45 28 v-5 a6 6 0 0 1 12 0 v5.
            static let corpoLucchetto = CGRect(x: 40, y: 28, width: 22, height: 18)
            static let raggioLucchetto: CGFloat = 3
            static let centroArcoLucchetto = CGPoint(x: 51, y: 23)
            static let raggioArcoLucchetto: CGFloat = 6
            static let baseArcoLucchetto: CGFloat = 28
            static let etichettaNuvola = CGPoint(x: 50, y: 108)
            static let sottoNuvola = CGPoint(x: 50, y: 124)

            // Il telefono (translate 560,26)
            static let origineTelefono = CGPoint(x: 560, y: 26)
            static let corpoTelefono = CGRect(x: 0, y: 0, width: 52, height: 92)
            static let raggioTelefono: CGFloat = 12
            static let altoparlante = CGRect(x: 18, y: 6, width: 16, height: 5)
            static let raggioAltoparlante: CGFloat = 2.5
            static let etichettaTelefono = CGPoint(x: 26, y: 122)

            /// Le scritte: 13/600 `--ink`, la seconda riga della nuvola 11 `--ink2`. Le coordinate sono la linea di base
            /// (SVG): il centro del testo sta poco sopra.
            static let etichetta = Carattere(dimensione: 13, peso: .semibold)
            static let sottoEtichetta = Carattere(dimensione: 11, peso: .regular)
            static let coloreSottoEtichetta = Colore.inchiostro2
            static let alzataEtichetta: CGFloat = 4.5
            static let alzataSottoEtichetta: CGFloat = 3.8
            /// Larghezza massima delle scritte (centrate sul punto).
            static let larghezzaScritta: CGFloat = 150

            /// Gli archi tratteggiati: contorno 2 `--ink3`, 4 pieno · 6 vuoto.
            static let arcoMacNuvola = (CGPoint(x: 150, y: 80), CGPoint(x: 200, y: 40), CGPoint(x: 250, y: 40), CGPoint(x: 290, y: 78))
            static let arcoNuvolaTelefono = (CGPoint(x: 395, y: 78), CGPoint(x: 450, y: 40), CGPoint(x: 510, y: 40), CGPoint(x: 555, y: 72))
            static let spessoreArco: CGFloat = 2
            static let tratteggio: [CGFloat] = [4, 6]
            static let coloreArco = Colore.inchiostro3
            /// I campioni per misurare la lunghezza degli archi (i pallini vanno a velocità costante).
            static let campioniArco = 64

            /// I pallini: raggio 5, verdi `--r1`; grigi a copia spenta o senza iCloud Drive.
            static let pallino: CGFloat = 5
            static let colorePallino = Colore.anello1
            static let colorePallinoSpento = Colore.inchiostro3
            /// Fermi (istantanee, copia spenta, in attesa): andata al 25% del percorso, ritorno al 75%.
            static let fermoAndata: Double = 0.25
            static let fermoRitorno: Double = 0.75
            /// «Riduci movimento»: fermi a metà di ciascun arco (il verde dice «allineato»).
            static let fermoCalmo: Double = 0.5
        }

        // MARK: Pillola «Senza Mac · copia cifrata» (§2.4)

        enum Pillola {
            /// Padding 3×8, capsula, fondo arancio al 16%, testo `#B45309` 10,5.
            static let padding = Misura.padding(3, 8)
            static let fondo = Colore.arancio.opacity(0.16)
            static let testo = Colore.arancioTesto
            static let carattere = Carattere(dimensione: 10.5, peso: .semibold)
            /// Nella barra di iPhone e iPad: un filo più grande, alta quanto il marchio.
            static let carattereBarra = Carattere(dimensione: 12, peso: .semibold)
            static let paddingBarra = Misura.padding(5, 10)
        }

        // MARK: Telefono d'esempio (§2.4)

        enum Telefono {
            /// `.phone` 300×620 raggio 50, fondo `#0d0f12`, filo interno 2 `#2a2e34`, ridotto a 0,86 (258×533).
            static let larghezza: CGFloat = 300
            static let altezza: CGFloat = 620
            static let scala: CGFloat = 0.86
            static let raggio: CGFloat = 50
            static let corpo = Color(hex: "#0D0F12")
            static let filo = Color(hex: "#2A2E34")
            static let spessoreFilo: CGFloat = 2
            /// Ombra `0 40px 80px -20px rgba(0,0,0,.55)` (senza espansione in SwiftUI: opacità ridotta).
            static let ombra = Color(r: 0, g: 0, b: 0, a: 0.55 * 0.75)
            static let ombraRaggio: CGFloat = 40
            static let ombraY: CGFloat = 40
            /// L'isola 92×26 raggio 20 nera, a 22 dall'alto.
            static let isola = CGSize(width: 92, height: 26)
            static let raggioIsola: CGFloat = 20
            static let isolaDallAlto: CGFloat = 22
            static let coloreIsola = Color.black
            /// Lo schermo: rientro 11, raggio 40, sempre chiaro anche nello scuro.
            static let rientro: CGFloat = 11
            static let raggioSchermo: CGFloat = 40
            /// `linear-gradient(170deg, #E9F1F5, #C9DCE6)`.
            static let schermo = [Color(hex: "#E9F1F5"), Color(hex: "#C9DCE6")]
            static let inizioSchermo = UnitPoint(x: 0.41, y: 0)
            static let fineSchermo = UnitPoint(x: 0.59, y: 1)
            static let testo = Color(hex: "#14202B")
            static let testo2 = Color(hex: "#5A6873")
            static let paddingSchermo = EdgeInsets(top: 52, leading: 18, bottom: 18, trailing: 18)
            /// La riga di stato: 12 semibold («10:41» e la pillola).
            static let oraFinta = "10:41"
            static let stato = Carattere(dimensione: 12, peso: .semibold)
            /// Il nome 26 bold, 18 sopra; sotto 12 `#5A6873`.
            static let nome = Carattere(dimensione: 26, peso: .bold, tracking: -0.5)
            static let sopraNome: CGFloat = 18
            static let sottoNome = Carattere(dimensione: 12, peso: .regular)
            /// Le tessere bianche: patrimonio raggio 18 padding 14 (14 sopra, ombra `0 10px 20px -12px rgba(0,0,0,.3)`).
            static let tessera = Color.white
            static let raggioTessera: CGFloat = 18
            static let paddingTessera: CGFloat = 14
            static let sopraTessera: CGFloat = 14
            static let ombraTessera = Color(r: 0, g: 0, b: 0, a: 0.3 * 0.4)
            static let ombraTesseraRaggio: CGFloat = 10
            static let ombraTesseraY: CGFloat = 10
            static let etichettaTessera = Carattere(dimensione: 11, peso: .regular)
            /// Fra l'etichetta e la cifra di una tessera.
            static let fraEtichettaValore: CGFloat = 2
            static let cifra = Carattere(dimensione: 24, peso: .bold, tracking: -0.5, tabellare: true)
            /// Le due tessere affiancate: spazio 8, 10 sopra, raggio 16, padding 12; etichetta 10,5, valore 18 bold.
            static let spazioAffiancate: CGFloat = 8
            static let sopraAffiancate: CGFloat = 10
            static let raggioPiccola: CGFloat = 16
            static let paddingPiccola: CGFloat = 12
            static let etichettaPiccola = Carattere(dimensione: 10.5, peso: .regular)
            static let valorePiccola = Carattere(dimensione: 18, peso: .bold, tabellare: true)
            static let coloreArea1 = Colore.anello2
            static let coloreArea2 = Colore.rosso
            /// La tessera della nota: 12,5 interlinea 1,5.
            static let nota = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.5)
            static let titoloNota = Carattere(dimensione: 12.5, peso: .bold)
            static let sopraNota: CGFloat = 10
            /// Il piede: 14 sopra, centrato, 11,5 `#5A6873`.
            static let piede = Carattere(dimensione: 11.5, peso: .regular)
            static let sopraPiede: CGFloat = 14
        }

        // MARK: Modulo (cartella e passphrase)

        enum Modulo {
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.padding(20, 24)
            static let spazio: CGFloat = 12
            static let titolo = Carattere(dimensione: 17, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let testo = Carattere.secondario
            static let coloreTesto = Colore.inchiostro2
            /// L'avviso «senza passphrase la copia non si apre»: il fondo e il bordo degli avvisi arancio.
            static let fondoAvviso = Colore.avvisoFondo
            static let bordoAvviso = Colore.avvisoBordo
            static let raggioAvviso: CGFloat = Raggio.voce
            static let paddingAvviso = Misura.padding(10, 14)
            static let testoAvviso = Carattere(dimensione: 12.5, peso: .semibold)
            static let coloreAvviso = Colore.scadenza
            /// I campi: `chip`, raggio 12, alti 34 (sul Mac) o 44 (sul tocco).
            static let fondoCampo = Colore.chip
            static let raggioCampo: CGFloat = Raggio.giorno
            static let altezzaCampo: CGFloat = 34
            static let altezzaCampoTocco: CGFloat = Tema.Apple.Telefono.tocco
            static let paddingCampo: CGFloat = 12
            static let campo = Carattere(dimensione: 13.5, peso: .regular)
            /// Il percorso della cartella scelta, `.k` tabellare.
            static let percorso = Carattere(dimensione: 12, peso: .medium)
            static let colorePercorso = Colore.inchiostro2
            static let coloreErrore = Colore.rosso
        }

        // MARK: Modifiche in attesa e «Da decidere»

        enum Modifiche {
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.padding(18, 20)
            static let spazio: CGFloat = 14
            static let fraVoci: CGFloat = 8
            /// Le sezioni `.lbl` («Da decidere», «In arrivo», «Arrivate di recente»).
            static let sezione = Carattere.etichetta
            static let coloreSezione = Colore.inchiostro2
            /// Il gruppo «iPhone · stamattina alle 9.12» 13 semibold, le voci 13 regolari con il pallino del tipo.
            static let gruppo = Carattere(dimensione: 13, peso: .semibold)
            static let coloreGruppo = Colore.inchiostro
            static let voce = Carattere(dimensione: 13, peso: .regular)
            static let coloreVoce = Colore.inchiostro
            static let pallino: CGFloat = 6
            static let colorePallino = Colore.anello1
            static let coloreConflitto = Colore.arancio
            static let spazioPallino: CGFloat = 8
            /// Il conflitto: card `cardPiena` raggio 18, le due versioni affiancate (spazio 10) su `chip` raggio 12.
            static let fondoConflitto = Colore.cardPiena
            static let bordoConflitto = Colore.separatore
            static let raggioConflitto: CGFloat = Raggio.tile
            static let paddingConflitto = Misura.padding(14, 16)
            static let fondoVersione = Colore.chip
            static let raggioVersione: CGFloat = Raggio.giorno
            static let paddingVersione = Misura.padding(10, 12)
            static let spazioVersioni: CGFloat = 10
            static let etichettaVersione = Carattere(dimensione: 11, peso: .semibold, tracking: 0.4, maiuscolo: true)
            static let coloreEtichettaVersione = Colore.inchiostro2
            static let valoreVersione = Carattere(dimensione: 13, peso: .regular, interlinea: 1.4)
            static let coloreValoreVersione = Colore.inchiostro
            static let motivo = Carattere.secondario
            static let coloreMotivo = Colore.inchiostro2
            /// Righe massime di un valore lungo (il testo di una nota).
            static let righeValore = 4
            /// Le cose arrivate mostrate (le più recenti).
            static let massimoArrivi = 8
        }

        // MARK: Movimento (§3)

        enum Moto {
            /// Un giro dei pallini lungo l'arco: 2,4 s a velocità costante; con «Sincronizza ora» 0,8 s, finché la
            /// sincronizzazione lavora (il template: 1,8 s). La velocità cambia senza salti: la fase è continua.
            static let giro: Double = 2.4
            static let giroVeloce: Double = 0.8
            /// «Sincronizzo…» resta almeno 1,8 s dopo «Sincronizza ora» (i pallini veloci del template), poi la fine vera.
            static let durataVeloce: Double = 1.8
            /// Le partenze sfalsate: Mac→iCloud 0 s, iCloud→iPhone 0,6 s, iCloud→Mac 1,2 s, iPhone→iCloud 1,8 s.
            static let partenze: [Double] = [0, 0.6, 1.2, 1.8]
            /// I fotogrammi dei pallini (4 cerchi: pochi bastano).
            static let fotogrammi: Double = 30
            /// Il cambio dei testi dello stato.
            static var testo: Animation { Tema.Apple.Moto.uscita(0.35) }
            /// A fine sincronizzazione il lucchetto rimbalza: da 0,3 a 1 in 500 ms con la molla.
            static let scalaRimbalzo: CGFloat = 0.3
            static var rimbalzo: Animation { Tema.Apple.Moto.molla(0.5) }
            /// L'apertura delle modifiche in attesa e del modulo.
            static var apertura: Animation { Tema.Apple.Moto.uscita(0.45) }
        }
    }
}
