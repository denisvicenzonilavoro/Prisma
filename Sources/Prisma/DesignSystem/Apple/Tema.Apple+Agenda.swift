import SwiftUI

// Agenda nel tema Apple (Design/template-apple-specifica.md §4.4, riferimenti analisi-agenda/G01-G14): la barra
// in testa, il mese con i puntini, la barra laterale della settimana («Questa settimana», «Da non dimenticare»),
// la settimana a pillola, la giornata con le ore, gli impegni e la linea rossa dell'ora, la fascia «Da fare» e la
// traccia dell'impegno (860×500). Le viste stanno in Shell/AgendaApple.swift, Shell/TracciaImpegnoApple.swift e
// Shell/AppAgenda.swift; qui solo i valori.

extension Tema.Apple {
    enum Agenda {
        // MARK: Disposizione

        enum Disposizione {
            /// Spazio fra la barra laterale (o la colonna del giorno) e la colonna principale: 346 − 330.
            static let spazio: CGFloat = 16
            /// Spazio fra la barra in testa, la striscia dei riesami e il contenuto.
            static let spazioRighe: CGFloat = 12
            /// Le card del contenuto (mese, giornata, colonna del giorno, occasioni): piatte come nelle app.
            static let superficie = Superficie.cardPiatta
            static let raggio: CGFloat = Raggio.card
        }

        // MARK: Barra in testa

        enum Barra {
            /// Il periodo mostrato («Novembre 2026», «2 — 8 novembre 2026»): `.h2`.
            static let periodo = Carattere.h2
            static let colorePeriodo = Colore.inchiostro
            static let spazio: CGFloat = 8
            /// Fra le frecce e «Oggi».
            static let spazioFrecce: CGFloat = 4
            /// Fra il periodo e il riepilogo delle attività.
            static let spazioPeriodo: CGFloat = 14
            static let menuClienti: CGFloat = 190
            static let menuClientiCompatto: CGFloat = 150
            static let altezza: CGFloat = 34
        }

        // MARK: Barra laterale (330, padding 18×18)

        enum Laterale {
            static let larghezza: CGFloat = Misura.Laterale.agenda
            static let padding = Misura.padding(18, 18)
            static let superficie = Superficie.pannello
            static let raggio: CGFloat = Raggio.pannello
            /// «Novembre» 20 bold e «2026» `.k`.
            static let mese = Carattere.meseAgenda
            static let coloreMese = Colore.inchiostro
            static let anno = Carattere.secondario
            static let coloreAnno = Colore.inchiostro2
            /// Il calendario 14 sotto il mese; le card 18 e 12 sotto.
            static let calendarioSopra: CGFloat = 14
            static let primaCardSopra: CGFloat = 18
            static let cardSopra: CGFloat = 12
            /// Card «Questa settimana» e «Da non dimenticare»: padding 16×18, senza ombra.
            static let paddingCard = Misura.padding(16, 18)
            static let superficieCard = Superficie.cardPiatta
            static let raggioCard: CGFloat = Raggio.card
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            /// Le tre cifre che si contano: `.v` 26 bold, `.k` sotto; 24 fra l'una e l'altra, 8 sotto l'etichetta.
            static let cifra = Carattere.valore
            static let coloreCifra = Colore.inchiostro
            static let nomeCifra = Carattere.secondario
            static let coloreNomeCifra = Colore.inchiostro2
            static let spazioCifre: CGFloat = 24
            static let cifreSopra: CGFloat = 8
            /// «Da non dimenticare»: fondo arancio al 10% con il bordo al 25%; testo 14 con interlinea 1,45.
            static let fondoAvviso = Colore.avvisoFondo
            static let bordoAvviso = Colore.avvisoBordo
            static let coloreEtichettaAvviso = Colore.arancio
            static let avviso = Carattere(dimensione: 14, peso: .regular, interlinea: 1.45)
            static let coloreAvviso = Colore.inchiostro
            static let avvisoSopra: CGFloat = 6
            /// Al massimo tante righe di «Da non dimenticare».
            static let righeAvviso = 4
        }

        // MARK: Calendario del mese (barra laterale)

        enum Calendario {
            /// 7 colonne con lo spazio 4; intestazioni 11 semibold `inchiostro3`.
            static let spazio: CGFloat = 4
            static let intestazione = Carattere(dimensione: 11, peso: .semibold)
            static let coloreIntestazione = Colore.inchiostro3
            static let sottoIntestazione: CGFloat = 4
            /// Caselle alte 36 con raggio 12, numeri 13 tabellari; il passaggio in `chip` in 0,25 s.
            static let altezza: CGFloat = 36
            static let raggio: CGFloat = Raggio.giorno
            static let numero = Carattere(dimensione: 13, peso: .regular, tabellare: true)
            static let numeroForte = Carattere(dimensione: 13, peso: .bold, tabellare: true)
            static let coloreNumero = Colore.inchiostro
            static let coloreFuori = Colore.inchiostro3
            /// Oggi su rosso con il testo bianco; il giorno scelto sull'accento al 14%.
            static let fondoOggi = Colore.rosso
            static let testoOggi = Color.white
            static let fondoScelto = Colore.selezioneGiorno
            static let fondoPassaggio = Colore.chip
            static var animazionePassaggio: Animation { .easeInOut(duration: 0.25) }
            /// I puntini del giorno: 4, a 4 dal fondo, 2 fra l'uno e l'altro (al massimo quattro tipi).
            static let puntino: CGFloat = 4
            static let puntinoDalFondo: CGFloat = 4
            static let spazioPuntini: CGFloat = 2
            /// L'occasione è un anellino (come gli anelli delle occasioni del mese), spesso 1.
            static let spessoreOccasione: CGFloat = 1
            /// Su oggi i puntini sono bianchi.
            static let puntinoSuOggi = Color.white
        }

        // MARK: I segni del giorno (calendario, mese e settimana)

        enum Segno {
            /// Appuntamenti: l'accento.
            static let appuntamento = Colore.accento
            /// Riesami (appuntamenti di revisione): il tono del riesame.
            static let riesame = Colore.Impegno.riesame
            /// Attività da fare: arancio; rimaste indietro: rosso.
            static let attivita = Colore.arancio
            static let attivitaScaduta = Colore.rosso
            /// Scadenze delle posizioni.
            static let scadenza = Colore.scadenza
            /// Occasioni: il colore del canale, neutro se non c'è.
            static let occasioneNeutra = Colore.inchiostro3

            static func occasione(_ c: Canale?) -> Color {
                guard let c else { return occasioneNeutra }
                return c == .alleanza ? Colore.canaleAlleanza : Colore.canaleIndipendente
            }
        }

        // MARK: Mese grande (la vista «Mese», approvata: solo il nuovo stile)

        enum Mese {
            static let numero = Carattere(dimensione: 12.5, peso: .semibold, tabellare: true)
            static let numeroOggi = Carattere(dimensione: 12.5, peso: .bold, tabellare: true)
            static let coloreNumero = Colore.inchiostro
            static let testoOggi = Color.white
            static let fondoOggi = Colore.rosso
            static let nomeGiorno = Carattere(dimensione: 11, peso: .semibold, tracking: 0.4)
            static let coloreNomeGiorno = Colore.inchiostro3
            /// La cella: bordo `separatore`; scelta sull'accento al 14%; passaggio `chip`.
            static let bordo = Colore.separatore
            static let fondoScelto = Colore.selezioneGiorno
            static let bordoScelto = Colore.accento.opacity(0.45)
            static let fondoPassaggio = Colore.chip
            static let raggio: CGFloat = Raggio.giorno
        }

        // MARK: Settimana a pillola

        enum Settimana {
            /// Alta 34, 7 voci di uguale larghezza; 16 sotto e la data `.h2` con «N impegni» `.k` a 8.
            static let altezza: CGFloat = 34
            static let titolo = Carattere.h2
            static let coloreTitolo = Colore.inchiostro
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
            static let spazioTitolo: CGFloat = 8
            static let titoloSopra: CGFloat = 16
            static let titoloSotto: CGFloat = 8
            static let rientroTitolo: CGFloat = 4
        }

        // MARK: Giornata

        enum Giornata {
            /// Card senza ombra; righe di 46 per ora dalle 8 alle 19 (di più se un impegno esce dall'orario).
            static let superficie = Superficie.cardPiatta
            static let raggio: CGFloat = Raggio.card
            static let altezzaOra: CGFloat = 46
            static let primaOra = 8
            static let ultimaOra = 19
            /// La linea della prima ora a 14 dall'alto; lo spazio sotto l'ultima.
            static let lineaSopra: CGFloat = 14
            static let sottoUltima: CGFloat = 18
            static let linea = Colore.separatore
            /// Ore 11,5 tabellari `inchiostro3` a 16 dal bordo, 8 sopra la loro linea; la linea parte dopo l'ora
            /// (così l'ora sta sullo stesso fondo della giornata, §4.9 n. 13).
            static let ora = Carattere(dimensione: 11.5, peso: .regular, tabellare: true)
            static let coloreOra = Colore.inchiostro3
            static let oraDalBordo: CGFloat = 16
            static let oraSopraLinea: CGFloat = 8
            static let lineaDalBordo: CGFloat = 58
            /// Impegni a 72 dal bordo sinistro e 16 dal destro, a (inizio − 8)·46 + 16, alti max(40, durata·46 − 4).
            static let impegnoSinistra: CGFloat = 72
            static let impegnoDestra: CGFloat = 16
            static let impegnoSopra: CGFloat = 16
            static let impegnoMinimo: CGFloat = 40
            static let impegnoStacco: CGFloat = 4
            /// Due impegni nello stesso tempo stanno affiancati, a 6 l'uno dall'altro (Prisma).
            static let spazioCorsie: CGFloat = 6
            /// Raggio 14, padding 8×12, bordo sinistro 4 nel colore e fondo nel colore al 13%.
            static let raggioImpegno: CGFloat = Raggio.voce
            static let paddingImpegno = Misura.padding(8, 12)
            static let bordoImpegno: CGFloat = 4
            static let opacitaFondo: Double = 0.13
            static let opacitaConcluso: Double = 0.55
            /// Nome 13,5 bold, ora e luogo `.k`, titolo 12 `inchiostro2` se l'impegno è più alto di 50.
            static let nome = Carattere(dimensione: 13.5, peso: .bold)
            static let coloreNome = Colore.inchiostro
            static let quando = Carattere.secondario
            static let coloreQuando = Colore.inchiostro2
            static let titolo = Carattere(dimensione: 12, peso: .regular)
            static let coloreTitolo = Colore.inchiostro2
            static let altezzaConTitolo: CGFloat = 50
            static let spazioRiga: CGFloat = 8
            /// Sopra questa larghezza l'etichetta del canale sta nell'impegno.
            static let larghezzaConCanale: CGFloat = 330
            /// Inclinazione 3 (§0 n. 4).
            static let inclinazione = Moto.Inclinazione.massimoImpegni
            /// La linea rossa dell'ora: alta 2, da 62 al bordo destro, con il pallino 10.
            static let coloreLinea = Colore.rosso
            static let spessoreLinea: CGFloat = 2
            static let lineaOraDalBordo: CGFloat = 62
            static let pallinoOra: CGFloat = 10
            /// Nelle istantanee la linea dell'ora sta alle 10:24 (il template: 10,4 fuori orario).
            static let oraIstantanea: Double = 10.4
            /// Giornata vuota: «☀︎» 40 e la frase 15 `inchiostro2`.
            static let simboloVuoto = "sun.max"
            static let carattereSimboloVuoto = Carattere(dimensione: 40, peso: .regular)
            static let vuoto = Carattere(dimensione: 15, peso: .regular)
            static let coloreVuoto = Colore.inchiostro2
            static let spazioVuoto: CGFloat = 8
        }

        // MARK: Fascia «Da fare» sopra le ore (Prisma: le attività stanno nella giornata)

        enum Fascia {
            static let padding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let spazio: CGFloat = 8
            /// Le voci: capsula `chip`, padding 6×12, testo 12,5 con il pallino 7 nel colore del segno.
            static let voce = Carattere(dimensione: 12.5, peso: .medium)
            static let coloreVoce = Colore.inchiostro
            static let cliente = Carattere.secondario
            static let coloreCliente = Colore.inchiostro2
            static let paddingVoce = Misura.padding(6, 12)
            static let fondoVoce = Colore.chip
            static let pallino: CGFloat = 7
            static let spazioVoce: CGFloat = 6
            static let filo = Colore.separatore
            /// Al massimo tante voci, poi «+N».
            static let massimo = 8
            /// Se le voci non stanno nella larghezza la striscia scorre e sfuma per 28 sul bordo destro.
            static let sfumatura: CGFloat = 28
        }

        // MARK: Colonna del giorno (viste Mese e Giorno)

        enum Colonna {
            /// L'occhiello delle sezioni («APPUNTAMENTI», «DA FARE»…): `.lbl`.
            static let occhiello = Carattere.etichetta
            /// La testa: giorno della settimana `.lbl` rosso se è oggi, data 17 bold, conteggi `.k`.
            static let giorno = Carattere.etichetta
            static let coloreOggi = Colore.rosso
            static let coloreGiorno = Colore.inchiostro2
            static let data = Carattere.titoloFinestra
            static let coloreData = Colore.inchiostro
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
        }

        // MARK: Traccia dell'impegno (860×500)

        enum Traccia {
            static let misura = Misura.DettaglioAperto.impegno
            /// Avatar 54, oppure il cerchio nel colore con «✓»; 14 fra l'avatar e i testi.
            static let avatar: CGFloat = Misura.Avatar.grande
            static let spuntaSenzaCliente = Carattere(dimensione: 22, peso: .bold)
            static let coloreSpunta = Color.white
            /// Fra etichetta, titolo e riga sotto della testata; fra il nome del riquadro e la sua cifra.
            static let spazioTesti: CGFloat = 2
            /// La cifra del patrimonio si stringe fino a questa scala prima di andare a capo.
            static let scalaMinimaCifra: CGFloat = 0.7
            static let spazioTestata: CGFloat = 14
            /// «{TIPO} · {giorno}» `.lbl` nel colore dell'impegno, titolo 26 bold, sotto `.k` 14.
            static let etichetta = Carattere.etichetta
            static let titolo = Carattere.titoloDettaglio(26)
            static let coloreTitolo = Colore.inchiostro
            static let sotto = Carattere(dimensione: 14, peso: .regular)
            static let coloreSotto = Colore.inchiostro2
            /// Lo spazio a destra della testata lasciato al ✕.
            static let margineChiudi: CGFloat = 56
            static let spazioCanale: CGFloat = 6
            /// Corpo 24 sotto la testata; 28 fra i punti e le tile; tile larghe 300, 10 fra l'una e l'altra.
            static let corpoSopra: CGFloat = 24
            static let spazioColonne: CGFloat = 28
            static let larghezzaTile: CGFloat = 300
            static let spazioTile: CGFloat = 10
            static let superficieTile = Superficie.tile
            static let raggioTile: CGFloat = Raggio.tile
            static let paddingTile = Misura.Padding.tile
            static let nomeTile = Carattere.secondario
            static let coloreNomeTile = Colore.inchiostro2
            static let cifraTile = Carattere.valore
            static let coloreCifraTile = Colore.inchiostro
            static let barraSopra: CGFloat = 6
            /// «Dati per l'analisi»: verde da 85 in su, arancio sotto.
            static let sogliaVerde = 85
            static let barraCompleta = Colore.verde
            static let barraParziale = Colore.arancio
            /// Al massimo tanti punti da toccare (gli altri restano nel riesame).
            static let massimoPunti = 6
            /// Piede: pulsanti grandi a 8, la nota `.k` a destra.
            static let spazioPulsanti: CGFloat = 8
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
        }

        // MARK: Il colore di un impegno

        /// Il colore dell'impegno: quello del cliente (la tinta dell'avatar), l'attività senza cliente in grigio.
        static func colore(_ cliente: Cliente?) -> Color {
            guard let cliente else { return Colore.Impegno.attivita }
            return Posizioni.coloreCliente(cliente.tinta)
        }
    }
}
