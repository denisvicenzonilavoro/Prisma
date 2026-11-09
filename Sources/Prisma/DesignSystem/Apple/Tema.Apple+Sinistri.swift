import SwiftUI

// Pratiche › Sinistri, il sinistro come una spedizione (Design/template-luce-specifica.md §7.4.2 e §7.4.3, «Luce» giro
// 15): misure, colori, caratteri e tempi della scheda. La barra laterale è quella comune (`Tema.Apple.Pratiche`); qui la
// spedizione (linea delle fasi, cifre, card dei fatti e dei documenti), il telefono «Così lo vede …» (sempre chiaro, con
// la tavolozza fissa `Tema.Apple.MiniCliente`), il modulo, le righe di Impostazioni › Pratiche e il movimento. Le viste
// stanno in Shell/PraticheSinistri.swift, Shell/ModuloSinistro.swift e iOS/SinistriTelefono.swift.

extension Tema.Apple.Pratiche {
    enum Spedizione {
        typealias C = Tema.Apple.Colore
        typealias K = Tema.Apple.Carattere

        /// Le colonne: barra 300 (comune), principale, colonna del telefono 310, spazio 20.
        static let colonnaTelefono: CGFloat = 310
        static let spazio: CGFloat = 20
        /// La testata: tassello 44 arancio, titolo display 24 (comune), sottotitolo 13,5 `inchiostro2`.
        static let tassello: CGFloat = 44
        static let tinta = C.arancio
        static let sottotitolo = K.voceLista
        static let coloreSottotitolo = C.inchiostro2
        static let coloreDaCollegare = C.arancio
        static let spazioTestata: CGFloat = 14
        /// Le card: piatte, raggio 22; la spedizione con padding 24/26 e 16 sotto.
        static let superficie = Tema.Apple.Superficie.cardPiatta
        static let raggio = Tema.Apple.Raggio.card
        static let padding = Tema.Apple.Misura.padding(24, 26)
        static let sottoCard: CGFloat = 16
        /// La linea delle fasi: alta 44, 34 di margine ai lati, barra 4 (raggio 4) a 8 dall'alto, nodi 20 con bordo 3,
        /// alone 6, etichette 12,5 semigrassetto 8 sotto il nodo.
        static let margine: CGFloat = 34
        static let altezza: CGFloat = 44
        static let barra: CGFloat = 4
        static let raggioBarra: CGFloat = 4
        static let nodo: CGFloat = 20
        static let bordoNodo: CGFloat = 3
        static let alone: CGFloat = 6
        static let etichetta = K.pulsante
        static let sottoNodo: CGFloat = 8
        /// La barra si riempie dal verde all'arancio fino alla fase di adesso; a «Pagato» tutta verde (proposta).
        static let gradiente: [Color] = [C.verde, C.arancio]
        static let pieno = C.verde
        static let binario = C.binario
        /// I nodi: fatti verdi pieni, adesso con il bordo arancio e l'alone, futuri con il bordo del binario,
        /// «Respinto» rosso.
        static let fatto = C.verde
        static let adesso = C.arancio
        static let aloneAdesso = C.arancio.opacity(0.2)
        static let respinto = C.rosso
        static let aloneRespinto = C.rosso.opacity(0.2)
        static let futuro = C.binario
        static let fondoNodo = C.cardPiena
        static let spuntaNodo = C.spuntaSuVerde
        static let etichettaFatta = C.inchiostro2
        static let etichettaAdesso = C.arancio
        static let etichettaFutura = C.inchiostro3
        static let etichettaRespinta = C.rosso
        /// Le tre cifre: 46 sotto la linea, spazio 24; sopra l'etichetta 12,5, sotto la cifra 17 grassetto.
        static let sopraCifre: CGFloat = 46
        static let spazioCifre: CGFloat = 24
        static let etichettaCifra = K.secondario
        static let coloreEtichettaCifra = C.inchiostro2
        static let cifra = K.titoloFinestra
        static let coloreCifra = C.inchiostro
        static let spazioCifra: CGFloat = 2
        /// «Fermo» accanto all'«Aperto da».
        static let fermo = K(dimensione: 11, peso: .semibold)
        static let coloreFermo = C.arancio
        /// Le due card affiancate (1,2 e 1, spazio 14, 14 sotto): padding 18/20, data larga 52, righe 13,5 con 7 sopra e sotto.
        static let proporzioneCard: CGFloat = 1.2
        static let spazioCard: CGFloat = 14
        static let larghezzaDueCard: CGFloat = 560
        static let paddingCardPiccola = Tema.Apple.Misura.Padding.cardPiccola
        static let titoloCard = K.etichetta
        static let coloreTitoloCard = C.inchiostro2
        static let sottoTitoloCard: CGFloat = 6
        static let colonnaData: CGFloat = 52
        static let data = K(dimensione: 13.5, peso: .bold, tabellare: true)
        static let coloreData = C.inchiostro
        static let fatto13 = K.voceLista
        static let coloreFatto = C.inchiostro
        static let paddingRiga: CGFloat = 7
        static let spazioRiga: CGFloat = 10
        static let filo = C.separatore
        static let futuroFatto = C.inchiostro2
        static let collegamento = K(dimensione: 12.5, peso: .semibold)
        static let coloreCollegamento = C.accento
        static let nota = K(dimensione: 12, peso: .regular, interlinea: 1.35)
        static let coloreNota = C.inchiostro2
        /// I documenti: cerchietto 20 con bordo 2 (vuoto `binario`, ricevuto verde con la spunta bianca).
        static let cerchietto = Tema.Apple.Misura.TiPreparo.cerchietto
        static let bordoCerchietto = Tema.Apple.Misura.TiPreparo.bordoCerchietto
        static let spuntaTratto = Tema.Apple.Misura.TiPreparo.spuntaTratto
        static let ricevuto = C.verde
        static let mancante = C.binario
        static let rilascio = C.accento
        static let trattoRilascio: CGFloat = 1.5
        static let tratteggioRilascio: [CGFloat] = [6, 5]
        /// I pulsanti in fondo: 14 sopra, spazio 8.
        static let sopraPulsanti: CGFloat = 14
        static let spazioPulsanti: CGFloat = 8
        /// I popover (fatto nuovo, fase con la data, importo pagato): larghi 300, padding 16, spazio 10.
        static let larghezzaPopover: CGFloat = 300
        static let paddingPopover: CGFloat = 16
        static let spazioPopover: CGFloat = 10
        static let titoloPopover = K.barra
        /// La colonna principale sotto questa larghezza mette il telefono sotto (non accanto).
        static let larghezzaConTelefono: CGFloat = 900
        /// L'etichetta «dati di prova» accanto al titolo.
        static let spazioEtichetta: CGFloat = 8
    }

    /// Il telefono «Così lo vede …»: `TelefonoDisegnato` scala 0,82 dall'alto, schermo sempre chiaro (tavolozza fissa
    /// `Tema.Apple.MiniCliente`, la stessa della mini-app del Prisma del cliente).
    enum TelefonoCliente {
        typealias K = Tema.Apple.Carattere
        typealias M = Tema.Apple.MiniCliente

        static let scala: CGFloat = 0.82
        static let larghezza = Tema.Apple.Apparecchio.larghezza
        static let altezza = Tema.Apple.Apparecchio.altezza
        static var fondo: Color { M.fondo }
        static var testo: Color { M.testo }
        static var occhiello: Color { M.testo2 }
        static var futuro: Color { M.futuro }
        static var cerchioVuoto: Color { M.cerchioVuoto }
        static var fatta: Color { M.fatta }
        static var adesso: Color { M.adesso }
        static var aloneAdesso: Color { M.adesso.opacity(0.2) }
        static var respinta: Color { M.nonBasta }
        static var piede: Color { M.piede }
        static var card: Color { M.card }
        /// 56 dall'alto, 18 ai lati; occhiello 11 grassetto spaziato 1; titolo 23 grassetto interlinea 1,15.
        static let sopra: CGFloat = 56
        static let lati: CGFloat = 18
        static let occhielloCarattere = K(dimensione: 11, peso: .bold, tracking: 1, maiuscolo: true)
        static let titolo = K(dimensione: 23, peso: .bold, interlinea: 1.15)
        static let spazioTitolo: CGFloat = 4
        /// La card bianca: raggio 18, padding 16, 14 sopra, ombra 0 8 18 −12 nero al 30%.
        static let raggioCard = Tema.Apple.Raggio.tile
        static let paddingCard: CGFloat = 16
        static let sopraCard: CGFloat = 14
        static let ombra = Color(r: 0, g: 0, b: 0, a: 0.3)
        static let ombraRaggio: CGFloat = 6
        static let ombraY: CGFloat = 8
        /// Le fasi in colonna: riga con spazio 10, padding 6; cerchio 16 (adesso con alone 4), vuoto con bordo 2.
        static let spazioFase: CGFloat = 10
        static let paddingFase: CGFloat = 6
        static let cerchio: CGFloat = 16
        static let aloneCerchio: CGFloat = 4
        static let bordoVuoto: CGFloat = 2
        static let fase = K(dimensione: 13, peso: .regular)
        static let faseForte = K(dimensione: 13, peso: .semibold)
        /// Sotto: l'ultimo fatto 12 interlinea 1,45 e «Aggiornato da …» 11.
        static let sopraUltimo: CGFloat = 12
        static let ultimo = K(dimensione: 12, peso: .regular, interlinea: 1.45)
        static let aggiornato = K(dimensione: 11, peso: .regular)
        static let spazioPiede: CGFloat = 6
        /// Colonna spenta: frase 13,5 e nota 12,5, centrate, larghe al più 260.
        static let spenta = K.voceLista
        static let notaSpenta = K.secondario
        static let larghezzaSpenta: CGFloat = 260
        static let titoloColonna = Tema.Apple.Carattere.etichetta
        static let coloreTitoloColonna = Tema.Apple.Colore.inchiostro2
        static let sottoTitoloColonna: CGFloat = 10
        static let notaColonna = K(dimensione: 11.5, peso: .regular, interlinea: 1.35)
        static let coloreNotaColonna = Tema.Apple.Colore.inchiostro3
    }

    /// Il modulo «Nuovo sinistro»: largo 520, padding 24, campi a 10.
    enum ModuloSinistro {
        static let larghezza: CGFloat = 520
        static let padding: CGFloat = 24
        static let spazio: CGFloat = 12
        static let spazioCampi: CGFloat = 8
        static let titolo = Tema.Apple.Carattere.titoloFinestra
        static let etichetta = Tema.Apple.Carattere.secondario
        static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
        static let campoImporto: CGFloat = 110
        static let colonnaEtichetta: CGFloat = 150
        static let nota = Tema.Apple.Carattere(dimensione: 12, peso: .regular, interlinea: 1.35)
        static let coloreNota = Tema.Apple.Colore.inchiostro2
        static let contatore = Tema.Apple.Carattere(dimensione: 11, peso: .regular, tabellare: true)
        static let coloreContatore = Tema.Apple.Colore.inchiostro3
        /// Il riquadro del modulo nelle istantanee e sopra la scheda: card piena, raggio 22.
        static let superficie = Tema.Apple.Superficie.cardPiatta
        static let raggio = Tema.Apple.Raggio.card
    }

    /// Impostazioni › Pratiche, la parte dei sinistri: i campi delle compagnie e dei tipi.
    enum ImpostazioniSinistri {
        static let spazioCampi: CGFloat = 6
        static let campoCompagnia: CGFloat = 160
        static let campoEmail: CGFloat = 210
        static let campoTipo: CGFloat = 150
        static let campoDocumenti: CGFloat = 300
        static let carattereCampi = Tema.Apple.Carattere.secondario
    }

    /// La riga «Sinistri aperti» nella panoramica del dossier.
    enum DossierSinistri {
        static let riga = Tema.Apple.Carattere(dimensione: 13, peso: .semibold)
        static let coloreRiga = Tema.Apple.Colore.accento
        static let dettaglio = Tema.Apple.Carattere.secondario
        static let coloreDettaglio = Tema.Apple.Colore.inchiostro2
        static let spazio: CGFloat = 6
    }
}

extension Tema.Apple.Pratiche.Moto {
    /// La barra della spedizione: da 0 alla fase in 1,40 s (uscita, come l'anello) dopo 0,25 s.
    enum Spedizione {
        static let ritardo = 0.25
        static let durata = Tema.Apple.Moto.Anello.durata
        static var animazione: Animation { Tema.Apple.Moto.Curva.uscita.animazione(durata).delay(ritardo) }
        /// Nodi e colori: 0,4 s (ease).
        static let durataNodo = 0.40
        static var nodo: Animation { Tema.Apple.Moto.Curva.ease.animazione(durataNodo) }
    }

    /// Il nodo di adesso respira: periodo 2 s, scala 1,045, senza alone blu (si ferma con calma e nelle istantanee).
    enum RespiroNodo {
        static let periodo = 2.0
        static let scala: CGFloat = 1.045
        static var animazione: Animation { .easeInOut(duration: periodo / 2).repeatForever(autoreverses: true) }
    }
}
