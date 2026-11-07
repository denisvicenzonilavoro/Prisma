import SwiftUI

// MARK: - Gettoni dell'app Documenti (tema Apple: colori e caratteri da Tema.Apple, AltreAppApple.swift)
// I fogli stampati hanno i loro gettoni in ComponentiDocumenti.swift e StileDocumenti.swift: questi sono solo
// dell'app (elenco stile Finder, anteprima, scheda dei dati, confronto dei documenti del cliente).

extension Tema.Misura {
    /// Misure dell'app Documenti.
    enum Documenti {
        /// Pannello dei dati accanto all'anteprima: snello, il documento è il protagonista.
        static let scheda: CGFloat = 340
        /// La stessa colonna quando mostra il confronto con il dossier: la tabella ha bisogno di più spazio.
        static let schedaConfronto: CGFloat = 560
        /// Sotto questa larghezza la colonna dei dati non si stringe più.
        static let schedaMinima: CGFloat = 300
        /// Lo spazio minimo della pagina: sotto questa larghezza il pannello dei dati non sta più accanto al foglio (si
        /// chiude da solo o, se il consulente lo apre, diventa un cassetto in basso) e l'elenco si stringe alle tessere.
        static let anteprimaMinima: CGFloat = 520
        /// Il pannello dei dati come cassetto sotto la pagina (dettaglio stretto): questa quota dell'altezza, tra il
        /// minimo e il massimo. Non passa mai sopra il foglio.
        static let quotaCassetto: CGFloat = 0.45
        static let cassettoMinimo: CGFloat = 140
        static let cassettoMassimo: CGFloat = 360
        /// L'elenco dei documenti: aperto, oppure stretto (le sole tessere) quando un documento è aperto.
        static let elencoAperto: CGFloat = 264
        static let elencoStretto: CGFloat = 60
        /// Sotto questa larghezza della scheda l'elenco resta stretto da solo (se nessun filtro è attivo). E si apre da
        /// solo soltanto se, con l'elenco e il pannello dei dati accanto, alla pagina resta almeno `anteprimaMinima`.
        static let elencoAutomatico: CGFloat = 1240
        /// Spazio tra le tessere dell'elenco stretto e tra i gruppi.
        static let spazioTessereStrette: CGFloat = 6
        static let margineTessereStrette = EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        static let filoGruppoStretto: CGFloat = 24
        /// Tessera del tipo nell'elenco e, più grande, nella barra del dettaglio.
        static let tessera: CGFloat = 30
        static let tesseraGrande: CGFloat = 38
        /// Segno «da leggere»: un cerchio vuoto (non un pallino blu, che si confonderebbe con Alleanza).
        static let puntoNuovo: CGFloat = 8
        static let bordoNuovo: CGFloat = 1.5
        /// Righe dell'elenco.
        static let rigaElenco = EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 10)
        static let spazioRiga: CGFloat = 10
        static let spazioTestiRiga: CGFloat = 2
        static let spazioStatoRiga: CGFloat = 5
        static let testataGruppo = EdgeInsets(top: 12, leading: 14, bottom: 4, trailing: 12)
        /// Barra del dettaglio: margini, spazio tra le righe e tra gli elementi di una riga.
        static let barraDettaglio = EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 12)
        static let spazioRigheBarra: CGFloat = 2
        /// Il titolo nella barra non si stringe sotto questa larghezza: prima le azioni perdono la scritta.
        static let titoloMinimo: CGFloat = 180
        static let spazioBarra: CGFloat = 8
        static let pulsante = EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        static let pulsanteIcona = EdgeInsets(top: 4, leading: 7, bottom: 4, trailing: 7)
        static let menuCategoria: CGFloat = 170
        /// Colonna dei dati: margini, spazio tra le sezioni, righe.
        static let margineScheda = EdgeInsets(top: 12, leading: 14, bottom: 18, trailing: 14)
        static let spazioSezioni: CGFloat = 12
        static let occhielloSezione = EdgeInsets(top: 10, leading: 12, bottom: 4, trailing: 12)
        static let noteSezione = EdgeInsets(top: 4, leading: 12, bottom: 10, trailing: 12)
        static let spazioNote: CGFloat = 4
        static let rigaDato = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 10)
        static let spazioRigaDato: CGFloat = 8
        /// Nel pannello snello il nome del dato sta sopra il valore: tra i due questo spazio.
        static let spazioEtichettaValore: CGFloat = 1
        static let etichettaDato: CGFloat = 132
        /// Spunta del dato (cerchio vuoto o pieno) e matita della correzione.
        static let spuntaDato: CGFloat = 18
        /// Fonte «p. 2»: margini della capsula.
        static let fonte = EdgeInsets(top: 2, leading: 7, bottom: 2, trailing: 7)
        /// Banner in cima alla scheda.
        static let banner = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        static let spazioBanner: CGFloat = 10
        /// Dati non trovati: larghezza minima di un gettone e campo del popover «Aggiungi».
        static let chipMancante: CGFloat = 150
        static let spazioChip: CGFloat = 6
        static let campoAggiungi: CGFloat = 220
        static let popover = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        /// Il foglio dell'anteprima: proporzione A4, margini del foglio e del tavolo, larghezza massima.
        static let rapportoA4: CGFloat = 210.0 / 297.0
        static let margineFoglio = EdgeInsets(top: 22, leading: 26, bottom: 22, trailing: 26)
        static let margineTavolo: CGFloat = 20
        static let foglioMassimo: CGFloat = 1000
        /// Il foglio ricostruito è disegnato per questa larghezza: più largo, testo e margini crescono con lui
        /// (adatto alla larghezza: il testo si legge come su carta vista da vicino), fino a `scalaFoglioMassima`.
        static let foglioRiferimento: CGFloat = 380
        static let scalaFoglioMassima: CGFloat = 1.8
        /// Su un'anteprima stretta il testo non scende sotto questa scala: va a capo, resta leggibile.
        static let scalaFoglioMinima: CGFloat = 1
        /// Zoom dell'anteprima rispetto alla larghezza: passo dei pulsanti − e +, minimo e massimo.
        static let passoZoom: CGFloat = 0.25
        static let zoomMinimo: CGFloat = 0.5
        static let zoomMassimo: CGFloat = 2.5
        /// Spazio sotto il foglio perché la barra delle pagine, che galleggia, non copra l'ultima riga.
        static let spazioSottoFoglio: CGFloat = 64
        static let spazioRigheFoglio: CGFloat = 1
        static let margineRigaFoglio: CGFloat = 3
        static let spazioNotaFoglio: CGFloat = 10
        /// Scheda «Testo»: il testo letto nel riquadro.
        static let riquadroTesto = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        /// Barra delle pagine che galleggia in basso sul foglio.
        static let barraPagine: CGFloat = 36
        static let marginePagine: CGFloat = 8
        static let spazioPagine: CGFloat = 6
        static let margineBarraPagine: CGFloat = 12
        static let filoBarraPagine: CGFloat = 16
        /// Il conteggio «da confermare» sul pulsante del pannello dei dati.
        static let contatore = EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6)
        // Tabella dei documenti del cliente (§6.7): quella di KID e polizze usa i gettoni della specifica 9
        static let spuntaConfronto: CGFloat = 26
        static let colonnaDatoConfronto: CGFloat = 132
        static let colonnaEsito: CGFloat = 104
        static let spazioConfronto: CGFloat = 12
        /// Modulo «Crea da un documento».
        static let modulo: CGFloat = 340
        static let margineModulo = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        static let spazioModulo: CGFloat = 12
        static let menuArea: CGFloat = 240
        /// Vuoto iniziale e rilascio.
        static let vuotoLarghezza: CGFloat = 600
        static let passoVuoto: CGFloat = 180
        static let spazioVuoto: CGFloat = 14
        static let cerchioPasso: CGFloat = 22
        static let marginePasso = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        static let capsulaRilascio = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 18)
        /// «Nessun documento con questi filtri».
        static let spazioNessuno: CGFloat = 10
    }
}

extension Tema.Raggio {
    /// Raggi dell'app Documenti.
    enum Documenti {
        static let tessera: CGFloat = Tema.Raggio.miniatura
        static let foglio: CGFloat = 3
        static let banner: CGFloat = Tema.Apple.Raggio.tile
        /// La riga del dato evidenziato (scheda, testo e foglio).
        static let evidenza: CGFloat = Tema.Raggio.tasto
        /// La cornice della tessera scelta nell'elenco stretto.
        static let tesseraStretta: CGFloat = Tema.Apple.Raggio.giorno
    }
}

extension Tema.Colore {
    /// Colori dell'app Documenti.
    enum Documenti {
        /// Il cerchio vuoto «da leggere»: inchiostro, fuori dalla coppia blu Alleanza / cuoio indipendente.
        static let nuovo = Tema.Apple.Colore.inchiostro2
        static let tessera = Tema.Apple.Colore.chip
        static let simbolo = Tema.Apple.Colore.inchiostro2
        static let daControllare = Tema.Apple.Colore.accento
        static let confermato = Tema.Apple.Colore.inchiostro3
        /// Valore che non torna (arancio del tema).
        static let diverso = Tema.Apple.Colore.arancio
        static let daAggiungere = Tema.Apple.Colore.accento
        /// Riga della fonte (scheda, testo, foglio ricostruito).
        static let evidenzia: Color = Tema.Apple.Colore.selezioneGiorno
        /// Fisso: sta sul foglio bianco del PDF.
        static let evidenziaPDF = Color(r: 0, g: 122, b: 255, a: 0.28)
        /// Banner: informazione, attenzione (cose che non tornano), errore.
        static let fondoBanner: Color = Tema.Apple.Colore.selezioneVoce.opacity(0.6)
        static let fondoBannerAttenzione: Color = Tema.Apple.Colore.avvisoFondo
        static let fondoBannerErrore: Color = Tema.Apple.Colore.rosso.opacity(Tema.Apple.AltreApp.alfaFondoVerde)
        static let simboloBanner = Tema.Apple.Colore.accento
        static let simboloBannerAttenzione = Tema.Apple.Colore.arancio
        static let simboloBannerErrore = Tema.Apple.Colore.rosso
        /// Numero dei passi del vuoto iniziale.
        static let passo = Tema.Apple.Colore.accento
        static let testoPasso = Tema.Apple.Controlli.Pulsante.testoPrincipale
        // Il foglio dell'anteprima è carta: colori fissi, uguali in chiaro e in scuro
        static let foglio = Color.white
        static let testoFoglio = Color(hex: "#1D1D1F")
        static let notaFoglio = Color(hex: "#86868B")
        static let evidenziaFoglio = Color(r: 0, g: 122, b: 255, a: 0.16)
        /// Il conteggio «da confermare» sul pulsante del pannello dei dati.
        static let contatore = Tema.Apple.Colore.accento
        static let testoContatore = Tema.Apple.Controlli.Pulsante.testoPrincipale
        /// La tessera del documento aperto nell'elenco stretto.
        static let tesseraScelta: Color = Tema.Apple.Colore.selezioneVoce
        static let bordoTesseraScelta = Tema.Apple.Colore.accento
    }
}

extension Tema.Testo {
    /// Caratteri dell'app Documenti.
    enum Documenti {
        static let titolo = Tema.Apple.AltreApp.titoloScheda.fontLeggibile
        static let valore = Tema.Apple.Carattere(dimensione: 13, peso: .regular, tabellare: true).fontLeggibile
        static let simboloTessera = Tema.Testo.sf(14)
        static let simboloTesseraGrande = Tema.Testo.sf(18)
        static let testoFoglio = Font.system(size: 10.5 * Tipo.fattore, design: .default)
        static let notaFoglio = Font.system(size: 9.5 * Tipo.fattore, design: .default)
        /// Testo e nota del foglio ricostruito con lo zoom adatto alla larghezza.
        static func testoFoglioScala(_ scala: CGFloat) -> Font { Font.system(size: 10.5 * Tipo.fattore * scala, design: .default) }
        static func notaFoglioScala(_ scala: CGFloat) -> Font { Font.system(size: 9.5 * Tipo.fattore * scala, design: .default) }
        /// Nome del dato sopra il valore nel pannello snello; conteggio sul pulsante del pannello.
        static let etichettaDato = Tema.Apple.AltreApp.nota.fontLeggibile
        static let contatore = Tema.Apple.Carattere(dimensione: 11, peso: .semibold, tabellare: true).fontLeggibile
        static let numeroPasso = Tema.Apple.Carattere(dimensione: 12, peso: .bold, tabellare: true).fontLeggibile
        static let simboloBanner = Tema.Testo.sf(15)
        static let spunta = Tema.Testo.sf(14)
    }
}
