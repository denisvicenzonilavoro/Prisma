import SwiftUI

// Mercato, «Prisma conosce il mercato» (versione «Orizzonte», giro 7, Design/template-novita-specifica.md §12.2 e
// §12.3): disposizione, fascia della riservatezza, tessere della striscia con la mini linea, riquadri «Chi è toccato
// oggi» e «Avvisi», ricerca per ISIN, dettaglio della tessera, fogli di importazione e soglie, Impostazioni › Mercato
// e la versione dell'iPhone. Le viste stanno in Shell/AppMercato.swift, Shell/AppMercatoRiquadri.swift,
// Shell/FogliMercato.swift, Shell/ImpostazioniMercatoVista.swift e iOS/MercatoTelefono.swift; qui solo i valori,
// tutti ricavati dal tema Apple.

extension Tema.Apple.Grafico.Tracciato {
    /// La mini linea delle tessere di Mercato: 2,2, senza area né punto finale (§12.2.4).
    static let spessoreMini: CGFloat = 2.2
}

extension Tema.Apple.Colore {
    /// La fascia della riservatezza (Mercato) e il verde del consenso: fondo e bordo verdi, uguali in chiaro e in scuro.
    static let fasciaRiservatezza = Color(r: 47, g: 163, b: 90, a: 0.08)
    static let fasciaRiservatezzaBordo = Color(r: 47, g: 163, b: 90, a: 0.22)
}

extension Tema.Apple {
    enum Mercato {
        // MARK: Disposizione (§12.2.1)

        enum Disposizione {
            /// 12 fra la fascia e la striscia e fra le tessere; 13 fra la striscia e i riquadri; 14 fra i riquadri.
            static let spazioStriscia: CGFloat = 12
            static let sopraRiquadri: CGFloat = 13
            static let spazioRiquadri: CGFloat = 14
            /// Sei colonne uguali; nelle finestre strette (iPad in verticale) meno, mai sotto i 150 per tessera.
            static let colonne = 6
            static let larghezzaMinimaTessera: CGFloat = 150
            static let altezzaTessera: CGFloat = 139
            /// I riquadri affiancati 1,25 : 1; sotto questa larghezza uno sotto l'altro (e tutto scorre).
            static let proporzioneRiquadri: CGFloat = 1.25
            static let larghezzaAffiancati: CGFloat = 820
            /// Uno sotto l'altro, ogni riquadro è alto almeno così.
            static let altezzaRiquadroImpilato: CGFloat = 320
        }

        // MARK: Fascia della riservatezza (§12.2.2)

        enum Fascia {
            static let fondo = Colore.fasciaRiservatezza
            static let bordo = Colore.fasciaRiservatezzaBordo
            static let raggio = Raggio.card
            static let padding = Misura.padding(10, 16)
            static let spazio: CGFloat = 10
            static let simbolo = "lock.fill"
            static let carattereSimbolo = Carattere(dimensione: 16, peso: .semibold)
            static let coloreSimbolo = Colore.verde
            static let testo = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.35)
            static let forte = Carattere(dimensione: 13.5, peso: .bold, interlinea: 1.35)
            static let coloreTesto = Colore.inchiostro
        }

        // MARK: Tessera della striscia (§12.2.2, §12.2.3, §12.2.4)

        enum Tessera {
            static let superficie = Superficie.card
            static let raggio = Raggio.card
            static let padding = Misura.padding(14, 16)
            static let nome = Carattere(dimensione: 12.5, peso: .regular)
            static let coloreNome = Colore.inchiostro2
            /// `.v` a 24: SF Pro Display 700, −0,5, cifre tabellari.
            static let valore = Carattere(dimensione: 24, peso: .bold, tracking: -0.5, tabellare: true)
            static let coloreValore = Colore.inchiostro
            static let coloreSenzaValore = Colore.inchiostro3
            /// Il valore si stringe fino al 70% prima di andare a capo (tessere strette).
            static let riduzioneValore: CGFloat = 0.7
            static let variazione = Carattere(dimensione: 12.5, peso: .bold, tabellare: true)
            static let spazioRighe: CGFloat = 2
            /// «Da importare», «al 23 ottobre 2026»: `inchiostro3`.
            static let nota = Carattere(dimensione: 12.5, peso: .regular)
            static let coloreNota = Colore.inchiostro3
            /// La fonte e la data in fondo: 11, `inchiostro3`, su una riga.
            static let fonte = Carattere(dimensione: 11, peso: .regular)
            static let coloreFonte = Colore.inchiostro3
            static let sopraFonte: CGFloat = 6
            /// La mini linea: alta 40, 6 sotto la variazione.
            static let altezzaLinea: CGFloat = 40
            static let sopraLinea: CGFloat = 6
            static let spessoreLinea = Grafico.Tracciato.spessoreMini
            /// Il binario della linea mentre il valore non c'è ancora (`--track`).
            static let binario = Colore.binario
            static let spessoreBinario: CGFloat = 2.2
            /// Inclinazione delle familiari (6 gradi).
            static let inclinazione = Tema.Apple.Moto.Inclinazione.massimoFamiliari
        }

        /// I colori dei toni: la cifra della variazione e la linea (fissi in chiaro e in scuro, §12.2.4, §12.2.5).
        enum Toni {
            static let cifraBuona = Colore.verde
            static let cifraCattiva = Colore.rosso
            static let cifraNeutra = Colore.inchiostro2
            static let lineaBuona = Colore.anello1
            static let lineaCattiva = Colore.rosso
            static let lineaNeutra = Colore.Composizione.liquidita
            /// Le schede di «Chi è toccato» e i pallini degli avvisi: rosso (soglia superata), arancio (da guardare),
            /// verde (buona notizia), grigio (visto).
            static let rosso = Colore.rosso
            static let arancio = Colore.arancio
            static let verde = Colore.verde
            static let spento = Colore.inchiostro3
        }

        // MARK: Riquadri «Chi è toccato oggi» e «Avvisi» (§12.1.3)

        enum Riquadro {
            static let superficie = Superficie.card
            static let raggio = Raggio.card
            static let padding = Misura.Padding.cardPiccola
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let sottoEtichetta: CGFloat = 10
            /// La frase al centro quando non c'è niente: `.k` 13, centrata, larga al massimo 340.
            static let vuoto = Carattere(dimensione: 13, peso: .regular, interlinea: 1.4)
            static let coloreVuoto = Colore.inchiostro2
            static let larghezzaVuoto: CGFloat = 340
        }

        enum Toccati {
            /// `.tile`: raggio 18, padding 14×16, nessuna ombra; filo del tono 4 a sinistra.
            static let superficie = Superficie.tile
            static let raggio = Raggio.tile
            static let padding = Misura.Padding.tile
            static let filo: CGFloat = 4
            static let fraSchede: CGFloat = 10
            static let titolo = Carattere(dimensione: 14.5, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let frase = Carattere(dimensione: 13, peso: .regular, interlinea: 1.4)
            static let coloreFrase = Colore.inchiostro2
            static let sottoTitolo: CGFloat = 2
            /// La fonte e la data del dato: 11, `inchiostro3`.
            static let fonte = Carattere(dimensione: 11, peso: .regular)
            static let coloreFonte = Colore.inchiostro3
            static let sottoFrase: CGFloat = 10
            static let spazioPiede: CGFloat = 10
            /// Avatar 30 sovrapposti di 8, con il bordo 2 `cardPiena` che li stacca (il disegno voluto, §12.1.5).
            static let avatar = Misura.Avatar.piccolo
            static let sovrapposizione: CGFloat = -8
            static let bordoAvatar: CGFloat = 2
            static let coloreBordoAvatar = Colore.cardPiena
            /// «+3»: il cerchio `chip` con il numero 10,5 semibold.
            static let fondoAltri = Colore.chip
            static let altri = Carattere(dimensione: 10.5, peso: .semibold, tabellare: true)
            static let coloreAltri = Colore.inchiostro2
        }

        enum Avviso {
            /// `.row`: padding 12×0, gap 12, filo sotto `separatore`.
            static let paddingVerticale: CGFloat = 12
            static let spazio: CGFloat = 12
            static let filo = Colore.separatore
            static let spessoreFilo = Misura.bordo
            static let pallino: CGFloat = 10
            static let avatar = Misura.Avatar.piccolo
            static let titolo = Carattere(dimensione: 14, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let descrizione = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.3)
            static let coloreDescrizione = Colore.inchiostro2
            static let fonte = Carattere(dimensione: 11, peso: .regular)
            static let coloreFonte = Colore.inchiostro3
            static let spazioTesti: CGFloat = 2
            static let spazioNome: CGFloat = 6
            /// L'alone del pallino rosso che pulsa: 6 di rosso al 18%.
            static let alone: CGFloat = 6
            static let coloreAlone = Color(r: 229, g: 72, b: 77, a: 0.18)
        }

        // MARK: Ricerca per ISIN (§12.2.2, §12.1.7)

        enum ISIN {
            /// La pillola `chip` con il campo largo 150 (13) e «Cerca» dentro.
            static let fondo = Colore.chip
            static let paddingPillola = EdgeInsets(top: 3, leading: 14, bottom: 3, trailing: 3)
            static let campo = Carattere(dimensione: 13, peso: .regular)
            static let larghezzaCampo: CGFloat = 150
            static let coloreCampo = Colore.inchiostro
            static let spazio: CGFloat = 6
            /// Il risultato: `.tile`, nome 14 bold, ISIN `.k`, etichette `.k`, cifre `.v` a 20.
            static let superficie = Superficie.tile
            static let raggio = Raggio.tile
            static let padding = Misura.Padding.tile
            static let nome = Carattere(dimensione: 14, peso: .bold)
            static let coloreNome = Colore.inchiostro
            static let codice = Carattere(dimensione: 12.5, peso: .regular, tabellare: true)
            static let coloreCodice = Colore.inchiostro2
            static let etichetta = Carattere(dimensione: 12.5, peso: .regular)
            static let coloreEtichetta = Colore.inchiostro2
            static let cifra = Carattere(dimensione: 20, peso: .bold, tracking: -0.3, tabellare: true)
            static let coloreCifra = Colore.inchiostro
            static let nota = Carattere(dimensione: 11, peso: .regular)
            static let coloreNota = Colore.inchiostro3
            static let spazioCifre: CGFloat = 18
            static let sopraCifre: CGFloat = 10
            static let sottoRisultato: CGFloat = 12
            /// «Codice ISIN non valido…»: rosso, 12,5.
            static let errore = Carattere(dimensione: 12.5, peso: .semibold)
            static let coloreErrore = Colore.rosso
        }

        // MARK: Mai aggiornato (§12.1.9)

        enum Vuoto {
            static let superficie = Superficie.card
            static let raggio = Raggio.card
            static let padding = Misura.Padding.cardMedia
            static let titolo = Carattere(dimensione: 17, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let testo = Carattere(dimensione: 13, peso: .regular, interlinea: 1.4)
            static let coloreTesto = Colore.inchiostro2
            static let spazio: CGFloat = 6
            static let sopraPulsanti: CGFloat = 12
            static let spazioPulsanti: CGFloat = 8
        }

        // MARK: Dettaglio della tessera (§12.4)

        enum Dettaglio {
            static let misura = CGSize(width: 780, height: 460)
            static let titolo = Carattere(dimensione: 23, peso: .bold, tracking: -0.4)
            static let coloreTitolo = Colore.inchiostro
            static let sottotitolo = Carattere.secondario
            static let coloreSottotitolo = Colore.inchiostro2
            static let spazioTitolo: CGFloat = 2
            static let valore = Carattere.valore
            static let altezzaGrafico: CGFloat = 200
            static let spessoreGrafico = Grafico.Tracciato.spessore
            static let spazio: CGFloat = 14
            static let asse = Carattere.asse
            static let coloreAsse = Colore.inchiostro3
            static let spazioPiede: CGFloat = 10
        }

        // MARK: Fogli (importazione, a mano, soglie)

        enum Foglio {
            static let larghezza: CGFloat = 520
            static let padding = Misura.Padding.cardGrande
            static let titolo = Carattere.h2
            static let coloreTitolo = Colore.inchiostro
            static let testo = Carattere(dimensione: 13, peso: .regular, interlinea: 1.4)
            static let coloreTesto = Colore.inchiostro2
            static let etichetta = Carattere(dimensione: 12.5, peso: .semibold)
            static let coloreEtichetta = Colore.inchiostro2
            static let errore = Carattere(dimensione: 12, peso: .regular)
            static let coloreErrore = Colore.rosso
            static let spazio: CGFloat = 12
            static let spazioCampo: CGFloat = 4
            static let spazioRighe: CGFloat = 2
            static let righeErroriMassime = 6
            static let larghezzaCampoNumero: CGFloat = 72
        }

        // MARK: Movimento (§12.3)

        enum Moto {
            /// Pallino rosso che pulsa: 1,6 s senza fine (mezzo ciclo all'alone), mai con «Riduci movimento» e nelle istantanee.
            static let durataPulsazione = 1.6
            static var pulsazione: Animation { .easeInOut(duration: durataPulsazione / 2).repeatForever(autoreverses: true) }
            /// Il risultato ISIN: da y +10 e opacità 0, 0,42 s con la curva d'uscita.
            static let durataRisultato = 0.42
            static let spostamentoRisultato: CGFloat = 10
            static var animazioneRisultato: Animation { Tema.Apple.Moto.uscita(durataRisultato) }
            /// Cascata: fascia 0, le tessere 1…6, «Chi è toccato» 7, «Avvisi» 8 (base 0,14, passo 0,048).
            static let base = Tema.Apple.Moto.Cascata.baseFinestra
            static let indiceMassimoTessere = 6
        }

        // MARK: Impostazioni › Mercato

        enum Impostazioni {
            static let larghezzaCampo: CGFloat = 72
            static let unita = Carattere(dimensione: 12.5, peso: .regular)
            static let coloreUnita = Colore.inchiostro2
            static let codice = Carattere(dimensione: 11, peso: .regular, tabellare: true)
            static let coloreCodice = Colore.inchiostro3
            static let errore = Carattere(dimensione: 12, peso: .regular)
            static let coloreErrore = Colore.arancio
            static let spazio: CGFloat = 6
            static let larghezzaScelta: CGFloat = 220
        }

        // MARK: iPhone (gerarchia approvata: una cosa grande in alto, poi ciò che serve, il resto a un tocco)

        enum Telefono {
            static let spazio: CGFloat = 12
            static let margine: CGFloat = 16
            /// La tessera principale grande: valore 34 bold, linea alta 56.
            static let valorePrincipale = Carattere(dimensione: 34, peso: .bold, tracking: -1, tabellare: true)
            static let altezzaLineaPrincipale: CGFloat = 56
            static let colonne = 2
            static let altezzaLinea: CGFloat = 30
        }
    }
}
