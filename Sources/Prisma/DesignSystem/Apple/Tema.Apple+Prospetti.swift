import SwiftUI

// Prospetti del tema Apple (Design/template-apple-specifica.md §4.5, riferimenti PIE p01-p14).
// Le viste stanno in Shell/ProspettiApple.swift (barra laterale, anteprima su carta, scorrimento) e in
// Shell/Presentazione.swift (la sala); la transizione della pagina in DesignSystem/Apple/PaginaApple.swift.
// Qui solo i valori. La carta resta sempre bianca, con i colori fissi di `Tema.Apple.Carta` (mai vetro).

extension Tema.Apple {
    enum Prospetti {
        // MARK: Disposizione

        enum Disposizione {
            /// Barra laterale 290 (`.side`), l'anteprima comincia a 306 da sinistra.
            static let larghezzaLaterale: CGFloat = Misura.Laterale.prospetti
            static let spazioLaterale: CGFloat = 16
            /// Fra la barra delle azioni e l'anteprima.
            static let spazioBarra: CGFloat = 12
        }

        // MARK: Barra laterale

        enum Laterale {
            static let superficie = Superficie.pannello
            static let raggio = Raggio.pannello
            static let padding = Misura.Padding.barraLaterale
            /// Riga del cliente: avatar 30, nome 14 bold, 12 sotto; la freccia della tendina 9 bold.
            static let avatar: CGFloat = Misura.Avatar.piccolo
            static let spazioCliente: CGFloat = 10
            static let nomeCliente = Carattere(dimensione: 14, peso: .bold)
            static let coloreNome = Colore.inchiostro
            static let frecciaCliente = Carattere(dimensione: 9, peso: .bold)
            static let coloreFreccia = Colore.inchiostro2
            static let sottoCliente: CGFloat = 12
            /// `.lbl` «Per l'incontro», 8 sotto; i gruppi dopo il primo 14 sopra.
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let sottoEtichetta: CGFloat = 8
            static let sopraGruppo: CGFloat = 14
            /// Voce `.rub` con padding 11×12, raggio 14, 2 fra le voci: titolo 14 bold, sottotitolo 12 `inchiostro2`.
            static let paddingVoce = Misura.padding(11, 12)
            static let raggioVoce: CGFloat = Raggio.voce
            static let fraVoci: CGFloat = 2
            static let titoloVoce = Carattere(dimensione: 14, peso: .bold)
            static let sottotitoloVoce = Carattere(dimensione: 12, peso: .regular)
            static let coloreTitoloVoce = Colore.inchiostro
            static let coloreSottotitoloVoce = Colore.inchiostro2
            /// «nuovo» nell'accento.
            static let coloreNuovo = Colore.accento
            static let spazioTitoli: CGFloat = 1
            /// Sotto il puntatore `chip`, scelta `rgba(0,122,255,.13)`, il fondo cambia in 0,25 s.
            static let fondoSopra = Colore.chip
            static let fondoScelta = Colore.selezioneVoce
            static let durataFondo = 0.25
            static var animazioneFondo: Animation { .easeInOut(duration: durataFondo) }
            /// Le scelte del documento sotto la voce scelta (Prisma: il template non le ha).
            static let paddingScelte = EdgeInsets(top: 4, leading: 0, bottom: 10, trailing: 0)
            /// Le scelte hanno già 12 di margine (la colonna di sempre): dentro la card del fascicolo si tolgono.
            static let rientroScelte: CGFloat = 12
            /// Card «Fascicolo dell'incontro»: 14 sopra, padding 14×16, senza ombra; testo `.k` 4 sotto il titolo,
            /// pulsante 10 sotto il testo.
            static let superficieFascicolo = Superficie.cardPiatta
            static let raggioFascicolo = Raggio.card
            static let sopraFascicolo: CGFloat = 14
            static let paddingFascicolo = Misura.padding(14, 16)
            static let testoFascicolo = Carattere.secondario
            static let coloreTestoFascicolo = Colore.inchiostro2
            static let sottoTitoloFascicolo: CGFloat = 4
            static let sopraPulsanteFascicolo: CGFloat = 10
            /// Il bordo della card quando il fascicolo è il documento scelto.
            static let bordoFascicoloScelto = Colore.accento
            /// Piede della barra: `.k` piccolo, 12 sopra.
            static let piede = Carattere(dimensione: 11.5, peso: .regular)
            static let colorePiede = Colore.inchiostro3
            static let sopraPiede: CGFloat = 12
            static let spazioCollegati: CGFloat = 2
        }

        // MARK: Scelte del documento (la colonna di sempre, dentro la barra laterale)

        enum Scelte {
            static let nota = Carattere(dimensione: 12, peso: .regular)
            static let coloreNota = Colore.inchiostro2
            static let testo = Carattere(dimensione: 13, peso: .regular)
            static let coloreTesto = Colore.inchiostro
            static let forte = Carattere(dimensione: 13, peso: .semibold)
            static let piccolo = Carattere(dimensione: 11.5, peso: .regular)
            static let etichetta = Carattere(dimensione: 11, peso: .semibold, tracking: 0.6, maiuscolo: true)
            static let coloreEtichetta = Colore.inchiostro2
            static let punto = Colore.inchiostro3
            static let errore = Colore.rosso
        }

        // MARK: Barra delle azioni

        enum Barra {
            /// Titolo del documento 15 bold (accorciato nel mezzo), sotto `.k`.
            static let titolo = Carattere(dimensione: 15, peso: .bold, tracking: -0.2)
            static let coloreTitolo = Colore.inchiostro
            static let sottotitolo = Carattere.secondario
            static let coloreSottotitolo = Colore.inchiostro2
            static let spazioTitoli: CGFloat = 1
            /// Spazio minimo del titolo: sotto questa misura le azioni passano alle sole icone.
            static let larghezzaMinimaTitolo: CGFloat = 180
            static let spazioAzioni: CGFloat = 8
            static let padding = EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0)
        }

        // MARK: Anteprima

        enum Anteprima {
            /// Fondo `chip` con raggio 20; la carta in alto al centro a 22 dal bordo.
            static let fondo = Colore.chip
            static let raggio = Raggio.pannello
            static let margineAlto: CGFloat = 22
            static let margineLati: CGFloat = 24
            /// Spazio per i comandi delle pagine sotto la carta (frecce 32 a 14 dal fondo).
            static let margineBasso: CGFloat = 60
            static let comandiFondo: CGFloat = 14
            /// La carta non si ingrandisce oltre la misura vera.
            static let scalaMassima: CGFloat = 1
            static let scalaMinima: CGFloat = 0.2
            static let carta = Superficie.carta
            /// Comandi delle pagine: frecce da 32 (`.arr`) e «2 di 5» 13 medium, largo almeno 70.
            static let freccia: CGFloat = Misura.Controllo.freccia
            static let carattereFreccia = Carattere(dimensione: 15, peso: .semibold)
            static let coloreFreccia = Colore.inchiostro
            static let fondoFreccia = Colore.cardPiena
            static let bordoFreccia = Colore.separatore
            static let contatore = Carattere(dimensione: 13, peso: .medium, tabellare: true)
            static let coloreContatore = Colore.inchiostro2
            static let larghezzaContatore: CGFloat = 70
            static let spazioComandi: CGFloat = 10
            /// Opacità della freccia senza pagina in quella direzione.
            static let opacitaFrecciaSpenta: Double = 0.35
            /// Lo scorrimento (rotella o trackpad) sull'anteprima: 60 pt di trackpad per una pagina, un giro di
            /// rotella per una pagina; dopo un cambio la rotella tace per 0,35 s.
            static let sogliaScorrimento: CGFloat = 60
            static let pausaRotella: Double = 0.35
            /// Riga vuota (nessun documento): `.k` centrato.
            static let vuotoTitolo = Carattere(dimensione: 15, peso: .bold)
            static let vuotoTesto = Carattere.secondario
            static let vuotoLarghezza: CGFloat = 380
        }

        // MARK: Sala della presentazione (§4.5.3)

        enum Sala {
            /// Velo `rgba(6,14,20,.92)` sopra tutto, uguale in chiaro e in scuro.
            static let velo = Colore.sala
            /// Il foglio occupa lo spazio tra 40 dall'alto e i comandi (32, a 24 dal fondo, 20 sopra di loro).
            static let margineAlto: CGFloat = 40
            static let margineLati: CGFloat = 40
            static let comandiFondo: CGFloat = 24
            static let altezzaComandi: CGFloat = 32
            static let sopraComandi: CGFloat = 20
            /// Frecce `rgba(255,255,255,.12)` da 32 con il segno bianco, spazio 10.
            static let freccia: CGFloat = Misura.Controllo.freccia
            static let fondoFreccia = Color(r: 255, g: 255, b: 255, a: 0.12)
            static let testo = Color.white
            static let carattereFreccia = Carattere(dimensione: 15, peso: .semibold)
            static let spazio: CGFloat = 10
            /// «1 di 4» 13, largo almeno 90.
            static let contatore = Carattere(dimensione: 13, peso: .regular, tabellare: true)
            static let larghezzaContatore: CGFloat = 90
            /// «Chiudi» bianco con il testo `#14202B`, 20 dopo la freccia.
            static let fondoChiudi = Color.white
            static let testoChiudi = Carta.testo
            static let sopraChiudi: CGFloat = 20
            static let carattereChiudi = Carattere.pulsante
            static let paddingChiudi = Misura.Padding.pulsante
            /// «Annota» (Prisma): capsula come le frecce, a sinistra di «Chiudi».
            static let fondoAnnota = fondoFreccia
            /// Titolo del documento in alto a sinistra, discreto (Prisma).
            static let titolo = Carattere(dimensione: 12, peso: .medium)
            static let coloreTitolo = Color(r: 255, g: 255, b: 255, a: 0.55)
            /// Riga dell'annotazione: campo su fondo bianco al 12%.
            static let fondoCampo = Color(r: 255, g: 255, b: 255, a: 0.12)
            static let paddingCampo = Misura.padding(7, 14)
            static let larghezzaCampo: CGFloat = 460
            static let segnapostoCampo = Color(r: 255, g: 255, b: 255, a: 0.5)
        }
    }
}
