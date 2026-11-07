import SwiftUI

// Il pannello di ricerca ⌘K come Spotlight, nel tema Apple (Design/template-apple-specifica.md §4.8): pannello di
// vetro con raggio 22 in alto al centro, campo grande con la lente, risultati sotto raggruppati per app con la
// selezione blu al 13%, colonna di anteprima a destra, piede con i tasti. Struttura di sempre (.spot, .spot-in,
// .spot-res, .sr-g, .sr-i, .spot-foot); colori, caratteri e movimento dal tema Apple.

extension Misure {
    enum Spotlight {
        /// Distanza dal bordo alto della shell (tema: top 15vh), mai sopra la barra superiore.
        static let distanzaAltoQuota: CGFloat = 0.15
        static let distanzaAltoMinima: CGFloat = Tema.Misura.barra + 16
        /// Larghezza: il campo del tema (660) più lo spazio per la colonna di anteprima.
        static let larghezza: CGFloat = 760
        /// Margine minimo dai lati della shell (tema: 100vw − 32px).
        static let margineLato: CGFloat = 16
        static let raggio: CGFloat = Tema.Apple.AltreApp.Ricerca.raggio
        /// Margine interno del vetro (tema: padding 8px).
        static let cornice: CGFloat = 8
        // Campo (.spot-in)
        static let campoAltezza: CGFloat = 52
        static let campoMargine: CGFloat = 14
        static let campoSpazio: CGFloat = 12
        /// Altezza massima del pannello rispetto alla shell (tema: max-height 70vh).
        static let altezzaQuota: CGFloat = 0.7
        /// Altezza dell'area dei risultati: cresce con i risultati, tra questi due valori.
        static let risultatiMinima: CGFloat = 360
        static let risultatiMassima: CGFloat = 470
        /// Altezza dell'area quando non c'è niente da mostrare (nessun risultato).
        static let nessunRisultato: CGFloat = 64
        /// Spazio tenuto per la striscia dei filtri e per il piede quando si calcola quanto crescono i risultati.
        static let riservaStrisciaPie: CGFloat = 72
        // Elenco (.spot-res, .sr-g, .sr-i)
        static let colonnaElenco: CGFloat = 330
        /// Sotto questa larghezza del pannello (iPhone) niente colonna di anteprima né tasti nel piede.
        static let sogliaAnteprima: CGFloat = 600
        static let margineElenco: CGFloat = 4
        static let gruppoMargine = EdgeInsets(top: 10, leading: 10, bottom: 4, trailing: 10)
        static let rigaMargine = EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10)
        static let rigaSpazio: CGFloat = 10
        static let rigaTestoSpazio: CGFloat = 1
        static let icona: CGFloat = Tema.Apple.Misura.Avatar.piccolo
        /// Stime per far crescere il pannello con i risultati (non servono al disegno).
        static let stimaRiga: CGFloat = 46
        static let stimaEstratto: CGFloat = 15
        static let stimaGruppo: CGFloat = 30
        // Anteprima
        static let anteprimaMargine: CGFloat = 18
        static let anteprimaSpazio: CGFloat = 14
        static let iconaAnteprima: CGFloat = 52
        static let intestazioneSpazio: CGFloat = 12
        static let cifraMargineVerticale: CGFloat = 6
        static let azioniSpazio: CGFloat = 8
        /// Le azioni dell'anteprima stanno in un piede fisso sotto la parte che scorre: margini del piede.
        static let azioniMargine = EdgeInsets(top: 10, leading: 18, bottom: 12, trailing: 18)
        /// La parte che scorre sfuma sopra il piede delle azioni.
        static let sfumaturaAnteprima: CGFloat = 16
        static let testoAnteprimaRighe = 6
        // Striscia dei filtri e dei totali
        static let strisciaMargine = EdgeInsets(top: 0, leading: 12, bottom: 8, trailing: 12)
        static let pillolaSpazio: CGFloat = 6
        static let pillolaMargine = EdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9)
        static let pillolaAltezza: CGFloat = 22
        static let totaleSpazio: CGFloat = 6
        // Pannello vuoto (ricerche salvate e filtri)
        static let vuotoMargine = EdgeInsets(top: 4, leading: 4, bottom: 8, trailing: 4)
        /// Oltre queste ricerche salvate l'elenco scorre, alto così.
        static let salvateSenzaScorrere = 5
        static let salvateAltezza: CGFloat = 236
        static let messaggioMargine = EdgeInsets(top: 22, leading: 12, bottom: 22, trailing: 12)
        // Piede (.spot-foot)
        static let pieMargine = EdgeInsets(top: 8, leading: 14, bottom: 4, trailing: 8)
        static let pieSpazio: CGFloat = 14
        static let nomeRicercaLarghezza: CGFloat = 260
    }
}

extension Tipo {
    // La Ricerca nel tema Apple (§4.8): la scala del template, con la «Dimensione del testo» dei caratteri di sempre
    private typealias R = Tema.Apple.AltreApp.Ricerca
    /// Il campo grande.
    static let spotlightCampo = R.carattereCampo.fontLeggibile
    static let spotlightLente = Tema.Apple.Carattere(dimensione: 19, peso: .medium).fontLeggibile
    static let spotlightGruppo = Tema.Apple.AltreApp.etichettaPiccola.fontLeggibile
    static let spotlightTitolo = R.carattereVoce.fontLeggibile
    static let spotlightDettaglio = R.carattereSotto.fontLeggibile
    static let spotlightEstratto = R.carattereSotto.fontLeggibile.italic()
    static let spotlightPie = Tema.Apple.AltreApp.nota.fontLeggibile
    static let spotlightPillola = Tema.Apple.Carattere(dimensione: 11.5, peso: .semibold).fontLeggibile
    static let spotlightPillolaNota = Tema.Apple.Carattere(dimensione: 11, peso: .regular).fontLeggibile
    static let spotlightAnteprimaTitolo = Tema.Apple.Carattere.h2.fontLeggibile
    static let spotlightAnteprimaSottotitolo = Tema.Apple.Carattere.secondario.fontLeggibile
    static let spotlightCifraEtichetta = Tema.Apple.Carattere.secondario.fontLeggibile
    static let spotlightCifraValore = Tema.Apple.Carattere(dimensione: 14, peso: .semibold, tabellare: true).fontLeggibile
    static let spotlightTesto = Tema.Apple.AltreApp.corpoPiccolo.fontLeggibile
    static let spotlightMessaggio = Tema.Apple.AltreApp.corpoPiccolo.fontLeggibile
    static let spotlightSimboloAzione = Tema.Apple.Carattere(dimensione: 14, peso: .semibold).fontLeggibile
    static let spotlightSimboloAnteprima = Tema.Apple.Carattere(dimensione: 24, peso: .semibold).fontLeggibile
}

extension Colori {
    /// La Ricerca nel tema Apple: il vetro del template, inchiostri, selezione blu al 13% come la rubrica.
    enum Spotlight {
        private typealias A = Tema.Apple.Colore
        /// Velo sotto il pannello (--scrim).
        static let velo = A.velo
        /// Riempimento del vetro del pannello (`.glass`).
        static let fondo = A.vetro
        static let lente = A.inchiostro2
        static let testo = A.inchiostro
        static let cancella = A.inchiostro3
        static let separatore = A.separatore
        static let gruppo = A.inchiostro2
        static let titolo = A.inchiostro
        static let dettaglio = A.inchiostro2
        static let estratto = A.inchiostro2
        /// Voce scelta: blu al 13% (`rgba(0,122,255,.13)`); al passaggio il `chip`.
        static let selezione = Tema.Apple.AltreApp.Ricerca.selezione
        static let sopra = A.chip
        static let pie = A.inchiostro3
        static let collegamento = A.accento
        static let messaggio = A.inchiostro2
        // Azioni: tessera neutra con il simbolo
        static let tesseraAzione = A.chip
        static let simboloAzione = A.accento
        // Anteprima
        static let etichettaCifra = A.inchiostro2
        static let valoreCifra = A.inchiostro
        static let testoAnteprima = A.inchiostro2
        // Pillole: suggerimenti (chip), filtri riconosciuti (blu), filtri a metà (arancio)
        static let pillola = A.chip
        static let pillolaSopra = A.binario
        static let pillolaTesto = A.inchiostro
        static let pillolaNota = A.inchiostro3
        static let filtro = A.selezioneVoce
        static let filtroTesto = A.accento
        static let incompleto = A.avvisoFondo
        static let incompletoTesto = A.arancio
    }
}

extension Tema.Moto {
    /// Entrata e uscita del pannello: come il pannello delle notifiche del tema Apple (§4.8: 0,38 s con la molla,
    /// da y −10 e scala 0,97); l'uscita resta la dissolvenza breve di sempre.
    enum Spotlight {
        static var entrata: Animation { Tema.Apple.Moto.PannelloNotifiche.animazione }
        static let uscita = Animation.easeIn(duration: 0.12)
        static let scala: CGFloat = Tema.Apple.Moto.PannelloNotifiche.scala
        static let spostamento: CGFloat = Tema.Apple.Moto.PannelloNotifiche.spostamento
    }
}
