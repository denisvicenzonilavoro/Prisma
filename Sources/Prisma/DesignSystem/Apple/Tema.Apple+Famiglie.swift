import SwiftUI

// Analisi 360 › «Rispetto alle famiglie come la sua» (Orizzonte, giro 6; Design/template-novita-specifica.md §10.2,
// §10.3): il segmentato sotto la testata, la card della frase grande, le voci con la barra della distribuzione (griglia
// 2 × 2 per la cella età × reddito, una card per voce con i gruppi affiancati per le tavole a una dimensione) e la
// nota. La vista sta in Shell/FamiglieComeLaSua.swift, la barra in DesignSystem/Apple/DistribuzioneApple.swift, le
// cifre in Motori/MotoreFamiglie.swift. Qui solo i valori.

extension Tema.Apple {
    enum Famiglie {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        // MARK: Riga del segmentato

        /// Fra il segmentato e l'etichetta «Dati di prova…».
        static let spazioRigaVista: CGFloat = 12
        /// Sotto la riga del segmentato (12 nel template, `.row.st` margin-bottom).
        static let sottoSegmentato: CGFloat = 12
        /// Quanto la riga del segmentato toglie all'altezza delle card delle aree (riga 34 più lo spazio sotto).
        static let riservatoRigaVista: CGFloat = 46

        /// L'etichetta «Dati di prova: carica le tabelle…»: arancio sul fondo degli avvisi, pillola.
        static let etichettaProva = Carattere.pulsante
        static let coloreEtichettaProva = Colore.scadenza
        static let fondoEtichettaProva = Colore.avvisoFondo
        static let bordoEtichettaProva = Colore.avvisoBordo
        static let paddingEtichettaProva = Tema.Apple.Misura.padding(6, 12)
        static let spazioSimboloProva: CGFloat = 6
        static let simboloProva = "exclamationmark.triangle.fill"

        // MARK: Card principale

        static let superficie = Tema.Apple.Superficie.card
        static let raggio = Tema.Apple.Raggio.card
        /// Padding 22 × 26.
        static let paddingPrincipale = Tema.Apple.Misura.padding(22, 26)
        /// Frase: display 28/700, tracking −0,6, al massimo 980 di larghezza.
        static let frase = Carattere(dimensione: 28, peso: .bold, tracking: -0.6, interlinea: 1.15)
        static let coloreFrase = Colore.inchiostro
        static let larghezzaFraseMax: CGFloat = 980
        /// La percentuale della frase: blu dei grafici (#0A84FF).
        static let cifraPrincipale = Colore.anello2
        /// Sottotitolo `.k` a 13,5, 4 sotto la frase.
        static let sottotitolo = Carattere(dimensione: 13.5, peso: .regular)
        static let coloreSottotitolo = Colore.inchiostro2
        static let sopraSottotitolo: CGFloat = 4
        /// Fra la frase dello stato «servono età e reddito» e il pulsante.
        static let sopraPulsante: CGFloat = 12

        // MARK: Griglia delle voci

        static let spazioGriglia: CGFloat = 14
        static let sopraGriglia: CGFloat = 14
        /// Padding 20 × 24 (card `.st`, senza inclinazione).
        static let paddingVoce = Tema.Apple.Misura.padding(20, 24)
        static let spazioRigaVoce: CGFloat = 8
        static let etichetta = Carattere.etichetta
        static let coloreEtichetta = Colore.inchiostro2
        /// Percentuale della voce: display 24/700, cifre tabellari.
        static let percentuale = Carattere(dimensione: 24, peso: .bold, tabellare: true)
        /// «circa» davanti alla percentuale del campione piccolo, e «sì» / «no» / «sopra» / «sotto».
        static let circa = Carattere.secondario
        static let coloreCirca = Colore.inchiostro2
        static let spazioCirca: CGFloat = 5
        static let parolaVoce = Carattere(dimensione: 17, peso: .bold)
        /// La cifra che manca: «—» in `ink3`.
        static let coloreMancante = Colore.inchiostro3
        /// Frase 14, 30 sotto la barra (lascia posto alla scritta della tacca).
        static let fraseVoce = Carattere(dimensione: 14, peso: .regular, interlinea: 1.4)
        static let coloreFraseVoce = Colore.inchiostro
        static let sopraFrase: CGFloat = 30
        /// Le cautele della voce: `.k`, 6 sotto la frase, 3 fra l'una e l'altra.
        static let cautela = Carattere.secondario
        static let coloreCautela = Colore.inchiostro2
        static let sopraCautele: CGFloat = 6
        static let spazioCautele: CGFloat = 3
        /// «Completa nella scheda del cliente ›» sotto la frase della cifra mancante.
        static let sopraCompleta: CGFloat = 8

        // MARK: Righe dei gruppi (tavole a una dimensione)

        /// Le voci in colonna, una card per riga a tutta larghezza: dentro, i gruppi (età, quinto di reddito, tutte le
        /// famiglie) uno accanto all'altro.
        static let colonneUnaDimensione = 1
        /// Le voci della cella età × reddito (versione 1): griglia 2 × 2 come nel template.
        static let colonneCella = 2
        /// Fra i gruppi di una card.
        static let spazioGruppi: CGFloat = 22
        /// Sotto la testa della card, prima dei gruppi.
        static let sopraGruppi: CGFloat = 14
        /// L'etichetta del gruppo («Capofamiglia tra i 35 e i 44 anni») e il valore del gruppo: `.k` 12,5.
        static let etichettaGruppo = Carattere(dimensione: 12.5, peso: .semibold)
        static let coloreEtichettaGruppo = Colore.inchiostro2
        static let valoreGruppo = Carattere(dimensione: 15, peso: .bold, tabellare: true)
        static let coloreValoreGruppo = Colore.inchiostro
        static let spazioValoreGruppo: CGFloat = 6
        /// La cifra del cliente in testa alla card (con il nome davanti, in `ink2`).
        static let nomeCliente = Carattere.secondario
        static let coloreNomeCliente = Colore.inchiostro2
        /// Con la tacca vicina al bordo la scritta si allinea alla tacca invece di centrarsi (sotto 15, sopra 85).
        static let bordoScrittaTacca: Double = 15

        // MARK: Barra della distribuzione

        static let sopraBarra: CGFloat = 20
        static let altezzaBarra: CGFloat = 26
        /// La fascia: rosso, arancio al 45%, verde (uguale in chiaro e in scuro).
        static let fasciaRosso = Color(r: 229, g: 72, b: 77, a: 0.22)
        static let fasciaArancio = Color(r: 224, g: 138, b: 0, a: 0.22)
        static let fasciaVerde = Color(r: 47, g: 163, b: 90, a: 0.28)
        static let posizioneArancio: CGFloat = 0.45
        static var fascia: LinearGradient {
            LinearGradient(stops: [Gradient.Stop(color: fasciaRosso, location: 0),
                                   Gradient.Stop(color: fasciaArancio, location: posizioneArancio),
                                   Gradient.Stop(color: fasciaVerde, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        }
        /// La tacca della metà (o del confine fra chi ha e chi non ha): larga 2, sporge 5 sopra e sotto, `ink3`.
        static let larghezzaTacca: CGFloat = 2
        static let sporgenzaTacca: CGFloat = 5
        static let coloreTacca = Colore.inchiostro3
        /// Le tacche dei quartili della fonte (p25, p75): sottili, dentro la barra.
        static let larghezzaTaccaQuantile: CGFloat = 1
        static let coloreTaccaQuantile = Colore.inchiostro3
        static let opacitaTaccaQuantile: Double = 0.45
        static let rientroTaccaQuantile: CGFloat = 6
        /// Fuori da p10-p90 (una famiglia su dieci per parte) la fascia si vela verso il fondo della card: la parte
        /// piena è dove stanno otto famiglie su dieci.
        static let veloCode = Colore.cardPiena
        static let opacitaVeloCode: Double = 0.55
        /// «metà delle famiglie»: `.k` a 11, 34 sotto l'inizio della barra, centrata sulla tacca.
        static let scrittaTacca = Carattere(dimensione: 11, peso: .regular)
        static let coloreScrittaTacca = Colore.inchiostro2
        static let scrittaTaccaY: CGFloat = 34
        /// Metà dell'altezza della riga a 11 punti: la scritta si centra a `scrittaTaccaY` più questa.
        static let mezzaScrittaTacca: CGFloat = 6.5
        /// Il segnaposto: avatar 30 con bordo 3 `cardE` e ombra 0 4 10 nero al 25%.
        static let latoAvatar: CGFloat = 30
        static let bordoAvatar: CGFloat = 3
        static let coloreBordoAvatar = Colore.cardPiena
        static let ombraAvatar = Color(r: 0, g: 0, b: 0, a: 0.25)
        static let raggioOmbraAvatar: CGFloat = 5
        static let yOmbraAvatar: CGFloat = 4

        // MARK: Nota

        static let nota = Carattere.secondario
        static let coloreNota = Colore.inchiostro2
        static let sopraNota: CGFloat = 12
        static let spazioNote: CGFloat = 4

        // MARK: Soglie dei colori (fisse nel tema)

        /// Verde da 60, arancio da 35, rosso sotto (§10.2.3).
        static let sogliaVerde = 60
        static let sogliaArancio = 35
        static func soglia(_ p: Int) -> Color {
            if p >= sogliaVerde { return Colore.verde }
            if p >= sogliaArancio { return Colore.arancio }
            return Colore.rosso
        }
        /// «sì» / «sopra» in verde, «no» / «sotto» in arancio (non è un errore: è un margine).
        static func tono(_ sopra: Bool) -> Color { sopra ? Colore.verde : Colore.arancio }

        // MARK: Tempi (§10.3)

        enum Tempi {
            /// Cascata dentro l'app: base 0. Indici: card principale 0, voci 1-5, nota 6.
            static let baseCascata = Tema.Apple.Moto.Cascata.baseDentroApp
            static let indicePrincipale = 0
            static let indicePrimaVoce = 1
            /// L'ultima voce della cascata (0-4: risparmio, patrimonio finanziario, ricchezza netta, protezione,
            /// previdenza complementare).
            static let ultimaVoce = 4
            static let indiceNota = 6
            /// Le percentuali si contano: frase principale indice 0 (1,1 s), voci 1-4 (1,16-1,34 s).
            static let indiceCifraPrincipale = 0
            /// I segnaposti scorrono dall'estremità rossa al percentile: 1,3 s con `--spring`, dopo 0,25 + i·0,12.
            static let ritardoSegnaposto = 0.25
            static let passoSegnaposto = 0.12
            static let corsaSegnaposto = 1.3
            static var animazioneSegnaposto: Animation { Tema.Apple.Moto.Curva.molla.animazione(corsaSegnaposto) }
            static func ritardo(segnaposto i: Int) -> Double { ritardoSegnaposto + Double(i) * passoSegnaposto }
            /// Cambio di vista dal segmentato (`rimonta`, come le schede di Studio): uscita 0,13 s, scala 0,99.
            static let durataRimonta = Tema.Apple.Studio.Moto.durataRimonta
            static let scalaRimonta = Tema.Apple.Studio.Moto.scalaRimonta
            static var uscitaRimonta: Animation { Tema.Apple.Studio.Moto.uscitaRimonta }
        }
    }
}
