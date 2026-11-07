import SwiftUI

// Studio › Parcelle e fatture e Impostazioni › Studio › Dati per le fatture (versione «Orizzonte», giro 2,
// Design/template-novita-specifica.md §3.1-§3.4): misure, caratteri, colori e tempi della scheda, del modulo della
// nuova parcella e del foglio della fattura. Le viste stanno in Shell/StudioParcelle*.swift, Shell/FatturaCarta.swift e
// Shell/ImpostazioniFatture.swift; qui solo i valori, tutti ricavati dal tema Apple. La carta è sempre bianca, con i
// colori opachi e fissi di `Tema.Apple.Carta`: niente vetro sul foglio.

extension Tema.Apple {
    enum Parcelle {
        // MARK: Disposizione (§2.3)

        enum Disposizione {
            /// La barra laterale `.side` larga 440 con padding 16; 16 fra la barra e l'anteprima.
            static let larghezzaLaterale: CGFloat = 440
            /// Nelle finestre strette la barra scende fino a 300 (l'anteprima tiene il foglio e le azioni).
            static let larghezzaLateraleMinima: CGFloat = 300
            /// Sotto questa larghezza dell'area la barra si stringe in proporzione.
            static let quotaLaterale: CGFloat = 0.34
            static let spazio: CGFloat = 16
            static let paddingLaterale: CGFloat = 16
            static let superficieLaterale = Superficie.pannello
            static let raggioLaterale = Raggio.pannello
        }

        // MARK: Tile dei totali (§1.2.1)

        enum Totali {
            static let superficie = Superficie.tile
            static let raggio = Raggio.tile
            static let padding = Misura.Padding.tile
            /// Due tile in riga, 10 fra loro, 12 sopra l'elenco.
            static let spazio: CGFloat = 10
            static let sotto: CGFloat = 12
            /// `.k` «Incassato nel 2026» e il valore `.v` display 26 bold.
            static let etichetta = Carattere.secondario
            static let coloreEtichetta = Colore.inchiostro2
            static let valore = Carattere.valore
            static let coloreValore = Colore.inchiostro
            /// «Da incassare» in arancio quando c'è qualcosa da incassare.
            static let coloreDaIncassare = Colore.arancio
            static let riduzioneValore: CGFloat = 0.6
            static let spazioValore: CGFloat = 2
            /// «dati di prova» o «provvisorio» sotto il valore.
            static let nota = Carattere(dimensione: 11.5, peso: .regular)
            static let coloreNota = Colore.arancio
        }

        // MARK: Elenco (§1.2.2)

        enum Voce {
            /// Voce `.rub` con padding 10, raggio 14, 2 fra le voci.
            static let padding = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            static let raggio = Raggio.voce
            static let fraVoci: CGFloat = 2
            /// Avatar da 34 con il bordo 3 `cardPiena` e l'ombra `0 4px 10px rgba(0,0,0,.25)`.
            static let avatar: CGFloat = 34
            static let bordoAvatar: CGFloat = 3
            static let coloreBordoAvatar = Colore.cardPiena
            static let ombraAvatar = Color(r: 0, g: 0, b: 0, a: 0.25)
            static let raggioOmbraAvatar: CGFloat = 5
            static let yOmbraAvatar: CGFloat = 4
            static let spazioAvatar: CGFloat = 10
            /// Nome 14 bold; «numero · descrizione» 12 `inchiostro2` su una riga.
            static let nome = Carattere(dimensione: 14, peso: .bold)
            static let coloreNome = Colore.inchiostro
            static let sotto = Carattere(dimensione: 12, peso: .regular)
            static let coloreSotto = Colore.inchiostro2
            static let spazioTitoli: CGFloat = 1
            /// Importo 13,5 bold e stato 12 semibold, a destra.
            static let importo = Carattere(dimensione: 13.5, peso: .bold, tabellare: true)
            static let coloreImporto = Colore.inchiostro
            static let stato = Carattere(dimensione: 12, peso: .semibold)
            static let spazioDestra: CGFloat = 8
            /// Sotto il puntatore `chip`, scelta `selezioneVoce`, il fondo cambia in 0,25 s.
            static let fondoSopra = Colore.chip
            static let fondoScelta = Colore.selezioneVoce
            static let durataFondo = 0.25
            static var animazioneFondo: Animation { .easeInOut(duration: durataFondo) }

            /// Il colore dello stato: bozza `inchiostro3`, da incassare arancio, pagata verde, annullata `inchiostro3`.
            static func colore(_ s: StatoParcella, scaduta: Bool) -> Color {
                switch s {
                case .bozza, .annullata: return Colore.inchiostro3
                case .emessa: return scaduta ? Colore.rosso : Colore.arancio
                case .pagata: return Colore.verde
                }
            }
        }

        /// «＋ Nuova parcella»: pulsante principale grande, largo quanto la barra, 16 sopra.
        static let nuovaSopra: CGFloat = 12
        /// Elenco vuoto: `.k`, 4 dai lati.
        static let vuoto = Carattere.secondario
        static let coloreVuoto = Colore.inchiostro2
        static let rientroVuoto: CGFloat = 4

        // MARK: Anteprima (§1.3)

        enum Anteprima {
            /// Il «tavolo» `chip` con raggio 20, senza bordo né ombra; il foglio 20 dall'alto.
            static let fondo = Colore.chip
            static let raggio = Raggio.pannello
            static let margineAlto: CGFloat = 20
            static let margineBasso: CGFloat = 20
            /// Il foglio è centrato nello spazio a sinistra della colonna delle azioni, 24 dai lati.
            static let margineLati: CGFloat = 24
            /// Scala del template (0,66) come tetto; con meno spazio il foglio si rimpicciolisce.
            static let scalaMassima: CGFloat = 0.66
            static let scalaMinima: CGFloat = 0.3
            static let carta = Superficie.carta
            /// Tavolo vuoto: «Qui vedrai la fattura su carta», `.k` al centro.
            static let vuoto = Carattere.secondario
            static let coloreVuoto = Colore.inchiostro2
            /// Il foglio a grandezza piena (istantanea 515): il fondo chiaro fisso intorno alla carta.
            static let tavoloCarta = Carta.binario
        }

        // MARK: Colonna delle azioni (§1.3, §1.5)

        enum Azioni {
            /// Larga 220, 18 dal bordo destro e dall'alto, 8 fra i pulsanti.
            static let larghezza: CGFloat = 220
            static let margine: CGFloat = 18
            static let spazio: CGFloat = 8
            /// La nota sotto i pulsanti: 6 sopra, `.k` con interlinea 1,45.
            static let notaSopra: CGFloat = 6
            static let nota = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
            static let coloreNota = Colore.inchiostro2
            /// Le tile dello stato del file XML: 10 sopra, `.tile`.
            static let statoSopra: CGFloat = 10
            static let superficieStato = Superficie.tile
            static let raggioStato = Raggio.tile
            static let paddingStato = Misura.Padding.tile
            /// Bordo verde `rgba(47,163,90,.4)` (pronto) e arancio `rgba(224,138,0,.4)` (mancano dati).
            static let bordoPronto = Color(r: 47, g: 163, b: 90, a: 0.4)
            static let bordoMancano = Color(r: 224, g: 138, b: 0, a: 0.4)
            static let spessoreBordo: CGFloat = 1
            /// «✓ File XML pronto» 14 bold verde; sotto, 4 più in basso, `.k`.
            static let pronto = Carattere(dimensione: 14, peso: .bold)
            static let colorePronto = Colore.verde
            static let titoloMancano = Carattere(dimensione: 13, peso: .bold)
            static let coloreTitoloMancano = Colore.arancio
            static let dettaglio = Carattere(dimensione: 12, peso: .regular, interlinea: 1.4)
            static let coloreDettaglio = Colore.inchiostro2
            static let sottoTitolo: CGFloat = 4
            static let collegamentoSopra: CGFloat = 6
            /// La parcella pagata: «Pagata il …» nella colonna, `.k` verde.
            static let incasso = Carattere(dimensione: 12.5, peso: .semibold)
            static let coloreIncasso = Colore.verde
        }

        // MARK: Modulo «Nuova parcella» (§4.1)

        enum Modulo {
            static let larghezza: CGFloat = 620
            static let altezza: CGFloat = 640
            static let superficie = Superficie.dettaglio
            static let raggio = Raggio.card
            static let padding = Misura.Padding.cardMedia
            /// Titolo come quello del dettaglio (26) e sezioni `.lbl`.
            static let titolo = Carattere.titoloDettaglio(26)
            static let coloreTitolo = Colore.inchiostro
            static let sottotitolo = Carattere.secondario
            static let coloreSottotitolo = Colore.inchiostro2
            static let sezione = Carattere.etichetta
            static let coloreSezione = Colore.inchiostro2
            static let spazioSezioni: CGFloat = 18
            static let sottoSezione: CGFloat = 8
            static let fraCampi: CGFloat = 10
            /// Etichetta del campo a sinistra, larga 150.
            static let etichetta = Carattere(dimensione: 13, peso: .medium)
            static let coloreEtichetta = Colore.inchiostro2
            static let larghezzaEtichetta: CGFloat = 150
            static let spazioCampo: CGFloat = 12
            static let campoImporto: CGFloat = 120
            static let campoMenu: CGFloat = 320
            /// Il riquadro delle voci fiscali: `cardPiatta`, padding 14×16, righe 13 con le cifre tabellari.
            static let superficieVoci = Superficie.tile
            static let raggioVoci = Raggio.tile
            static let paddingVoci = Misura.Padding.tile
            static let rigaVoce = Carattere(dimensione: 13, peso: .regular, tabellare: true)
            static let rigaTotale = Carattere(dimensione: 14, peso: .bold, tabellare: true)
            static let coloreRiga = Colore.inchiostro
            static let coloreRigaSecondaria = Colore.inchiostro2
            static let fraVoci: CGFloat = 4
            static let notaVoci = Carattere(dimensione: 12, peso: .regular, interlinea: 1.4)
            static let coloreNotaVoci = Colore.inchiostro2
            static let coloreAvviso = Colore.arancio
            /// Il segno ✕ per togliere una riga.
            static let togli = Carattere(dimensione: 12, peso: .semibold)
            static let coloreTogli = Colore.inchiostro3
            static let piedeSopra: CGFloat = 16
            static let spazioPiede: CGFloat = 8
            /// Nelle istantanee il modulo sta sopra la scheda, con il velo.
            static let velo = Color(r: 0, g: 0, b: 0, a: 0.18)
        }

        // MARK: Impostazioni › Studio › Dati per le fatture

        enum Impostazioni {
            /// Larghezze dei campi a destra delle righe: corti (CAP, sigle, aliquote), medi, lunghi e i menu dei codici.
            static let campoCorto: CGFloat = 90
            static let campoMedio: CGFloat = 220
            static let campoLungo: CGFloat = 300
            static let menu: CGFloat = 320
            static let menuBreve: CGFloat = 160
            /// L'unità accanto al campo numerico («%», «€», «giorni»).
            static let unita = Carattere.secondario
            static let coloreUnita = Colore.inchiostro2
            static let spazioUnita: CGFloat = 4
            /// Le righe della dicitura (testo su più righe).
            static let righeDicitura = 2...5
        }

        // MARK: Movimento (§3.2-§3.3)

        enum Moto {
            /// Il foglio esce in 0,16 s (lineare) verso il basso di 20 del foglio, entra in 0,48 s con la curva
            /// `uscita` dall'alto; scala relativa 0,64 / 0,66.
            static let durataUscita = 0.16
            static let durataEntrata = 0.48
            static let spostamento: CGFloat = 20
            static let scala: CGFloat = 0.64 / 0.66
            static var uscita: Animation { .linear(duration: durataUscita) }
            static var entrata: Animation { Tema.Apple.Moto.Curva.uscita.animazione(durataEntrata) }
            /// «✓ File XML pronto» entra con la molla in 0,45 s: scala 0,9 → 1.
            static let durataPronto = 0.45
            static let scalaPronto: CGFloat = 0.9
            static var animazionePronto: Animation { Tema.Apple.Moto.Curva.molla.animazione(durataPronto) }
        }
    }

    // MARK: - La fattura su carta (§1.4, §2.4): sempre chiara, colori opachi e fissi

    enum CartaFattura {
        enum Colore {
            static let fondo = Carta.fondo
            static let testo = Carta.testo
            static let sottotitolo = Carta.sottotitolo
            static let testoCorrente = Carta.testoCorrente
            static let etichetta = Carta.etichetta
            static let piede = Carta.piede
            static let filetto = Carta.filetto
            static let sopratitolo = Carta.sopratitolo
            /// I campi «da completare» (§6.4).
            static let daCompletare = Carta.ambra
            /// Il logo di Prisma (#0F2433).
            static let logo = Tema.Colore.logoStampa
            /// L'intestazione del canale indipendente: il cuoio da stampa, opaco.
            static let canale = Tema.Colore.canaleIndipendenteStampa
        }

        enum Testo {
            typealias C = Tema.Apple.Carattere
            /// Testata: 11 semibold, spaziatura 1, maiuscolo.
            static let testata = C(dimensione: 11, peso: .semibold, tracking: 1, maiuscolo: true)
            /// «FATTURA»: 11 bold, spaziatura 1,4.
            static let sopratitolo = C(dimensione: 11, peso: .bold, tracking: 1.4, maiuscolo: true)
            /// Il numero: display 32 bold, spaziatura −1, interlinea 1,05.
            static let numero = C(dimensione: 32, peso: .bold, tracking: -1, interlinea: 1.05, tabellare: true)
            /// La data: 13, 8 sopra.
            static let data = C(dimensione: 13, peso: .regular)
            /// I dati del cliente: 12 con interlinea 1,6; il nome in grassetto.
            static let cliente = C(dimensione: 12, peso: .regular, interlinea: 1.6)
            static let clienteNome = C(dimensione: 12, peso: .bold, interlinea: 1.6)
            /// Testata della tabella: 11 bold, spaziatura .4.
            static let testaTabella = C(dimensione: 11, peso: .bold, tracking: 0.4, maiuscolo: true)
            /// La riga: 13,5; il sottotitolo 11,5 `etichetta`; l'importo in grassetto.
            static let riga = C(dimensione: 13.5, peso: .regular)
            static let rigaSotto = C(dimensione: 11.5, peso: .regular)
            static let rigaImporto = C(dimensione: 13.5, peso: .bold, tabellare: true)
            /// Le voci fiscali: 13 `etichetta`.
            static let voce = C(dimensione: 13, peso: .regular, tabellare: true)
            /// Il totale: 17 bold; il netto a pagare 15 bold.
            static let totale = C(dimensione: 17, peso: .bold, tabellare: true)
            static let netto = C(dimensione: 15, peso: .bold, tabellare: true)
            /// «PAGAMENTO»: 11,5 bold, spaziatura .4, 30 sopra; il testo 12,5 con interlinea 1,55.
            static let sezione = C(dimensione: 11.5, peso: .bold, tracking: 0.4, maiuscolo: true)
            static let corpo = C(dimensione: 12.5, peso: .regular, interlinea: 1.55)
            /// Il piede: 9 con interlinea 1,4.
            static let piede = C(dimensione: 9, peso: .regular, interlinea: 1.4)
            /// «segue» in fondo alla tabella di una pagina che continua.
            static let segue = C(dimensione: 11, peso: .regular)
        }

        enum Misura {
            /// A4 verticale (595×842, come i prospetti).
            static let formato = Misure.Documento.prospetto
            /// Padding 40 sopra e sotto, 46 ai lati; il piede 26 dal fondo.
            static let margineAlto: CGFloat = 40
            static let margineLati: CGFloat = 46
            static let piedeDalFondo: CGFloat = 26
            /// Spazio lasciato al piede sotto il contenuto.
            static let spazioPiede: CGFloat = 56
            static let logo: CGFloat = 22
            /// Il numero lungo si stringe fino al 60% per stare su una riga.
            static let riduzioneNumero: CGFloat = 0.6
            static let spazioLogo: CGFloat = 8
            /// 34 dalla testata al numero e dal numero alla tabella.
            static let sottoTestata: CGFloat = 34
            static let sopraTabella: CGFloat = 34
            static let sopraData: CGFloat = 8
            static let spazioColonne: CGFloat = 24
            /// Filetti: forti 2 (`testo`), sottili 1 (`filetto`).
            static let filettoForte: CGFloat = 2
            static let filettoSottile: CGFloat = 1
            static let sottoTestaTabella: CGFloat = 10
            /// La riga: 14 sopra e sotto; le voci fiscali 6 (12 la prima e l'ultima); il totale 14.
            static let paddingRiga: CGFloat = 14
            static let paddingVoce: CGFloat = 5
            static let paddingVoci: CGFloat = 12
            static let paddingTotale: CGFloat = 14
            static let spazioRiga: CGFloat = 2
            /// «PAGAMENTO» 30 sopra, il testo 6 sotto.
            static let sopraSezione: CGFloat = 30
            static let sottoSezione: CGFloat = 6
            /// Il piede: filetto sopra 1, padding 8.
            static let paddingPiede: CGFloat = 8
            /// Righe della parcella per pagina: oltre, la tabella continua sulla pagina dopo con «segue».
            static let righePrimaPagina = 8
            static let righeAltrePagine = 14
        }
    }
}

// MARK: - Il foglio della fattura che cambia (§3.2)

extension AnyTransition {
    /// Il foglio della fattura scelta: esce in 0,16 s verso il basso (scala 0,64/0,66, opacità 0), poi il nuovo
    /// entra in 0,48 s dall'alto con la curva `uscita`. Sempre nella stessa direzione. Con «Riduci movimento» una
    /// dissolvenza di 0,15 s.
    static func cambioFattura(calmo: Bool) -> AnyTransition {
        if calmo { return AnyTransition.opacity.animation(Tema.Moto.dissolvenzaCalma) }
        let m = Tema.Apple.Parcelle.Moto.self
        let entrata = AnyTransition.modifier(
            active: EffettoPaginaApple(scala: m.scala, x: 0, y: -m.spostamento, opacita: 0),
            identity: EffettoPaginaApple.riposo
        )
        .animation(m.entrata.delay(m.durataUscita))
        let uscita = AnyTransition.modifier(
            active: EffettoPaginaApple(scala: m.scala, x: 0, y: m.spostamento, opacita: 0),
            identity: EffettoPaginaApple.riposo
        )
        .animation(m.uscita)
        return AnyTransition.asymmetric(insertion: entrata, removal: uscita)
    }
}
