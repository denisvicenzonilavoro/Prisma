import SwiftUI

// Impostazioni del tema Apple (Design/template-apple-specifica.md §4.6, riferimenti PIE i01-i09).
// Le viste stanno in Shell/AppImpostazioni.swift (barra laterale e pagina), Shell/ImpostazioniPagine.swift,
// Shell/ImpostazioniArchivio.swift e DesignSystem/Apple/ImpostazioniApple.swift (righe a card, voci della barra,
// anello del backup); le righe di sempre (ComponentiImpostazioni.swift) si disegnano così con `.impostazioniApple()`.
// Qui solo i valori.

extension Tema.Apple {
    enum Impostazioni {
        // MARK: Disposizione

        enum Disposizione {
            /// Barra laterale 260 (`.side`), la pagina comincia a 276 da sinistra.
            static let larghezzaLaterale: CGFloat = Misura.Laterale.impostazioni
            static let spazioLaterale: CGFloat = 16
        }

        // MARK: Barra laterale

        enum Laterale {
            static let superficie = Superficie.pannello
            static let raggio = Raggio.pannello
            static let padding = Misura.Padding.barraLaterale
            /// Voce `.rub` con padding 11×12, raggio 14, 2 fra le voci, titolo 14 bold.
            static let paddingVoce = Misura.padding(11, 12)
            static let raggioVoce: CGFloat = Raggio.voce
            static let fraVoci: CGFloat = 2
            static let titoloVoce = Carattere(dimensione: 14, peso: .bold)
            static let coloreVoce = Colore.inchiostro
            /// Sotto il puntatore `chip`, scelta `rgba(0,122,255,.13)`, il fondo cambia in 0,25 s.
            static let fondoSopra = Colore.chip
            static let fondoScelta = Colore.selezioneVoce
            static let durataFondo = 0.25
            static var animazioneFondo: Animation { .easeInOut(duration: durataFondo * Tema.Apple.Moto.ritmo) }
            /// Prisma ha più sezioni del template: sono raccolte sotto etichette `.lbl` (la prima senza).
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let sottoEtichetta: CGFloat = 8
            static let sopraGruppo: CGFloat = 16
            static let rientroEtichetta: CGFloat = 12
            /// Piede: archivio locale e versione, `.k` piccolo, 12 sopra.
            static let piede = Carattere(dimensione: 11.5, peso: .regular)
            static let colorePiede = Colore.inchiostro3
            static let sopraPiede: CGFloat = 12
            static let spazioPiede: CGFloat = 2
            /// Pallino verde dell'archivio locale nel piede.
            static let pallinoPiede: CGFloat = 6
            static let colorePallinoPiede = Colore.verde
        }

        // MARK: Pagina

        enum Pagina {
            /// Titolo della sezione `.h2` (21 bold), 4 sopra e 14 sotto.
            static let titolo = Carattere.h2
            static let coloreTitolo = Colore.inchiostro
            static let sopraTitolo: CGFloat = 4
            static let sottoTitolo: CGFloat = 14
            /// Fra i gruppi di righe (il template ha un solo gruppo per sezione).
            static let spazioGruppi: CGFloat = 22
            /// Colonna leggibile (i rendimenti di confronto prendono tutta la larghezza).
            static let larghezzaMassima: CGFloat = 760
            /// La pagina scorre: un filo d'aria a destra per non toccare il bordo e in fondo sopra il dock.
            static let margine = EdgeInsets(top: 0, leading: 0, bottom: 24, trailing: 6)
        }

        // MARK: Righe

        enum Riga {
            /// Card senza ombra, padding 16×20, 10 fra una riga e l'altra; titolo 15 bold e `.k`; il controllo a destra.
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.Padding.rigaImpostazione
            static let fraRighe: CGFloat = 10
            static let spazioControllo: CGFloat = 16
            static let titolo = Carattere.titoloRiga
            static let coloreTitolo = Colore.inchiostro
            static let spiegazione = Carattere.secondario
            static let coloreSpiegazione = Colore.inchiostro2
            static let sottoTitolo: CGFloat = 2
            /// Avvertenza sotto la spiegazione (backup non riusciti, permessi negati).
            static let avvertenza = Carattere.secondario
            static let coloreAvvertenza = Colore.scadenza
            /// Icona di vetro accanto al titolo (Scorciatoie, Strumenti).
            static let spazioIcona: CGFloat = 12
            /// Un controllo che non c'è più posto per affiancare va sotto il testo.
            static let spazioControlliAffiancati: CGFloat = 8
        }

        // MARK: Gruppi e note

        enum Gruppo {
            /// Titolo di un gruppo di righe: `.lbl` 12 semibold maiuscolo, 8 sotto.
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let sottoEtichetta: CGFloat = 8
            static let rientroEtichetta: CGFloat = 4
        }

        enum Nota {
            static let carattere = Carattere.secondario
            static let colore = Colore.inchiostro2
            static let rientro: CGFloat = 4
            /// Una riga di avviso dell'archivio (sola lettura, copie non leggibili).
            static let coloreErrore = Colore.rosso
        }

        // MARK: Stato a destra della riga

        enum Stato {
            /// Pallino 8 e testo 13 semibold («● Pronto»).
            static let pallino: CGFloat = 8
            static let spazio: CGFloat = 6
            static let carattere = Carattere(dimensione: 13, peso: .semibold)
            static let coloreTesto = Colore.inchiostro
            static let ok = Colore.verde
            static let attenzione = Colore.arancio
            static let errore = Colore.rosso
            static let neutro = Colore.inchiostro3
        }

        // MARK: Panoramica

        enum Tessera {
            static let superficie = Superficie.tile
            static let raggio = Raggio.tile
            static let padding = Misura.Padding.tile
            static let etichetta = Carattere.secondario
            static let coloreEtichetta = Colore.inchiostro2
            static let valore = Carattere(dimensione: 22, peso: .bold, tracking: -0.4, tabellare: true)
            static let coloreValore = Colore.inchiostro
            static let nota = Carattere(dimensione: 12, peso: .regular)
            static let coloreNota = Colore.inchiostro2
            static let spazio: CGFloat = 4
            static let sottoTesta: CGFloat = 6
            static let larghezzaMinima: CGFloat = 200
            static let fraTessere: CGFloat = 12
            static let fondoSopra = Colore.chip
        }

        // MARK: Archivio e backup

        enum Backup {
            /// Card del backup: padding 22×24, senza ombra, 24 fra l'anello e il testo, 12 sotto.
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.padding(22, 24)
            static let spazio: CGFloat = 24
            static let sottoCard: CGFloat = 12
            /// Anello 110/12 verde (`anello1`).
            static let anello: CGFloat = 110
            static let spessore: CGFloat = 12
            static let colore = Colore.anello1
            static let opacitaBinario = Grafico.Anello.opacitaBinario
            /// Il backup non dice quanto manca: l'anello sale fino a qui in 1,6 s e aspetta la fine.
            static let frazioneAttesa: Double = 0.92
            /// Dall'attesa al pieno, a backup finito.
            static let durataChiusura = 0.35
            static var animazioneChiusura: Animation { Moto.Curva.backup.animazione(durataChiusura) }
            /// ✓ al centro (26) nel verde dell'anello; a riposo senza backup il simbolo del giro in `inchiostro2`.
            static let spunta = Carattere(dimensione: 26, peso: .bold)
            static let coloreSpunta = Colore.anello1
            static let attesa = Carattere(dimensione: 24, peso: .regular)
            static let coloreAttesa = Colore.inchiostro2
            /// Errore: il punto esclamativo arancio.
            static let coloreErrore = Colore.arancio
            /// Titolo 17 bold e `.k` 4 sotto.
            static let titolo = Carattere(dimensione: 17, peso: .bold, tracking: -0.2)
            static let coloreTitolo = Colore.inchiostro
            static let spiegazione = Carattere.secondario
            static let coloreSpiegazione = Colore.inchiostro2
            static let sottoTitolo: CGFloat = 4
            /// I numeri dell'archivio (clienti, appuntamenti, attività) sotto la card dell'archivio.
            static let numero = Carattere(dimensione: 22, peso: .bold, tracking: -0.4, tabellare: true)
            static let coloreNumero = Colore.inchiostro
            static let etichettaNumero = Carattere.secondario
            static let coloreEtichettaNumero = Colore.inchiostro2
            static let fraNumeri: CGFloat = 28
        }

        // MARK: Profilo

        enum Profilo {
            /// Card padding 22×24, avatar 64 «DV» 22 semibold bianco sul gradiente, 18 fra avatar e nome.
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.padding(22, 24)
            static let spazio: CGFloat = 18
            static let sottoCard: CGFloat = 12
            static let avatar: CGFloat = Misura.Avatar.molto
            static let iniziali = Carattere(dimensione: 22, peso: .semibold)
            static let coloreIniziali = Color.white
            static let avatarAlto = Colore.avatarDVAlto
            static let avatarBasso = Colore.avatarDVBasso
            /// Nome 19 bold, sotto `.k`.
            static let nome = Carattere(dimensione: 19, peso: .bold, tracking: -0.3)
            static let coloreNome = Colore.inchiostro
            static let ruolo = Carattere.secondario
            static let coloreRuolo = Colore.inchiostro2
            /// Il campo del nome nel popover.
            static let larghezzaCampo: CGFloat = 220
            static let paddingPopover = Misura.padding(14, 16)
        }

        // MARK: Sala («Luce» giro 8)

        /// Impostazioni › Sala: i campi degli imprevisti in riga (mesi o importo, probabilità, fonte) e i testi.
        enum Sala {
            static let spazioCampi: CGFloat = 6
            static let campoMesi: CGFloat = 56
            static let campoImporto: CGFloat = 90
            static let campoProbabilita: CGFloat = 56
            static let campoFonte: CGFloat = 160
            static let campoTesto: CGFloat = 380
            static let carattereCampi = Carattere.secondario
        }
    }
}
