import SwiftUI

// Incontri › Il copilota dell'incontro (Orizzonte, giro 5; Design/template-novita-specifica.md §8.2 e §8.3): la colonna
// «Oggi» con il consenso, la testata con l'onda della voce e il pulsante, la trascrizione con le parole illuminate, le
// schede che nascono mentre Prisma capisce, il verbale finale (dettaglio 940×520). Le viste stanno in
// Shell/CopilotaIncontro.swift e Shell/VerbaleCopilota.swift, l'onda in DesignSystem/Apple/OndaNastroApple.swift, lo
// stato dell'ascolto in Shell/StatoCopilotaIncontro.swift. Qui solo i valori, tutti ricavati dal tema Apple.

// MARK: - Colori dei tipi di scheda (§8.2.3)

extension Tema.Apple.Colore {
    enum Copilota {
        /// Obiettivo: lo stesso blu degli investimenti (`--r2`).
        static let obiettivo = Tema.Apple.Colore.Area.investimenti
        /// Polizza di un'altra compagnia: il cuoio del template (#B06E12), fisso. Dubbio §15.9 punto 4: è il colore del
        /// canale indipendente; la posizione si salva comunque con quel canale e l'emittente «Altra compagnia».
        static let polizza = Color(hex: "#B06E12")
        /// Timore → profilo per l'obiettivo (`--r3`).
        static let profilo = Tema.Apple.Colore.stima
        /// Evento della vita: il chiaro dell'avatar di Giulia.
        static let evento = Color(hex: "#E58BA0")
        /// Da fare (`--r1`).
        static let attivita = Tema.Apple.Colore.Area.liquidita

        static func tipo(_ t: SchedaCopilota.Tipo) -> Color {
            switch t {
            case .obiettivo: return obiettivo
            case .polizzaEsterna: return polizza
            case .profilo: return profilo
            case .evento: return evento
            case .attivita: return attivita
            }
        }
    }
}

extension Tema.Apple {
    enum Copilota {
        // MARK: Disposizione (§8.2, #wc)

        enum Disposizione {
            /// La colonna `.side` larga 300 e 16 di gioco prima dell'area principale (da x 316).
            static let larghezzaColonna: CGFloat = 300
            static let gioco: CGFloat = 16
            /// Sotto questa larghezza (iPad in verticale) la colonna «Oggi» lascia il posto a una riga in testa e le
            /// due colonne vanno una sotto l'altra.
            static let sogliaStretta: CGFloat = 900
            /// Testata e colonne: 14 fra l'una e l'altra; trascrizione e schede in proporzione 1,3 : 1.
            static let spazio: CGFloat = 14
            static let quotaTrascrizione: CGFloat = 1.3
            static let quotaSchede: CGFloat = 1
            /// Nella disposizione stretta la trascrizione prende questa quota dell'altezza che resta.
            static let quotaTrascrizioneStretta: CGFloat = 0.48
        }

        // MARK: La colonna «Oggi» (§8.2.1)

        enum Colonna {
            static let superficie = Superficie.pannello
            static let raggio = Raggio.pannello
            static let padding = Misura.Padding.barraLaterale
            /// Occhiello `.lbl` «Oggi», 8 sotto.
            static let occhiello = Carattere.etichetta
            static let coloreOcchiello = Colore.inchiostro2
            static let sottoOcchiello: CGFloat = 8
            /// Riga `.rub`: padding 10, raggio 14, 2 fra le righe; avatar 38 a 10 dal testo.
            static let paddingVoce = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            static let raggioVoce = Raggio.voce
            static let fraVoci: CGFloat = 2
            static let avatar = Misura.Avatar.medio
            static let spazioAvatar: CGFloat = 10
            /// Nome 14 bold, sotto «ora · titolo» 12 `inchiostro2` su una riga (al massimo 200).
            static let nome = Carattere(dimensione: 14, peso: .bold)
            static let coloreNome = Colore.inchiostro
            static let sottotitolo = Carattere(dimensione: 12, peso: .regular)
            static let coloreSottotitolo = Colore.inchiostro2
            static let larghezzaSottotitolo: CGFloat = 200
            static let spazioTitoli: CGFloat = 1
            /// Sotto il puntatore `chip`, scelta `selezioneVoce`, in 0,25 s; durante l'ascolto le altre righe spente.
            static let fondoSopra = Colore.chip
            static let fondoScelta = Colore.selezioneVoce
            static let opacitaSpenta: Double = 0.45
            static let durataFondo = 0.25
            static var animazioneFondo: Animation { .easeInOut(duration: durataFondo * Tema.Apple.Moto.ritmo) }
            /// «Nessun incontro in agenda oggi.» (`.k`) e il pulsante sotto.
            static let vuoto = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
            static let coloreVuoto = Colore.inchiostro2
            static let spazioVuoto: CGFloat = 10
            /// In fondo, i collegamenti al resto dell'incontro.
            static let sopraCollegamenti: CGFloat = 12
            static let spazioCollegamenti: CGFloat = 6
        }

        // MARK: Il consenso e «Come funziona» (§8.2.1, §8.1.5)

        enum Consenso {
            /// Card senza ombra, padding 14×16, raggio 22, 16 sotto le righe di «Oggi».
            static let padding = Misura.padding(14, 16)
            static let raggio = Raggio.card
            static let sopra: CGFloat = 16
            /// Dato: verde al 8% con il bordo al 22%. Mancante: i colori degli avvisi (arancio).
            static let superficieData = Superficie(riempimento: Color(r: 47, g: 163, b: 90, a: 0.08), sfocatura: 0, saturazione: 1,
                                                   bordo: Color(r: 47, g: 163, b: 90, a: 0.22), spessoreBordo: Misura.bordo,
                                                   ombra: nil, raggio: Raggio.card, filoInterno: false)
            static let superficieMancante = Superficie(riempimento: Colore.avvisoFondo, sfocatura: 0, saturazione: 1,
                                                       bordo: Colore.avvisoBordo, spessoreBordo: Misura.bordo,
                                                       ombra: nil, raggio: Raggio.card, filoInterno: false)
            /// Titolo 13,5 bold (✓ in verde, ! in arancio); testo `.k` interlinea 1,45, 4 sotto il titolo.
            static let titolo = Carattere(dimensione: 13.5, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let coloreSegnoDato = Colore.verde
            static let coloreSegnoMancante = Colore.arancio
            static let testo = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
            static let coloreTesto = Colore.inchiostro2
            static let sottoTitolo: CGFloat = 4
            /// Il modulo per registrarlo: modo a pillola, nota, data; 10 fra i campi.
            static let sopraModulo: CGFloat = 10
            static let spazioModulo: CGFloat = 8
            static let nota = Carattere(dimensione: 12.5, peso: .regular)
            static let paddingNota = Misura.padding(6, 10)
            static let raggioNota = Raggio.giorno
            static let fondoNota = Colore.chip
            /// «Verifica le regole di Alleanza sull'ascolto» sui clienti di Alleanza (finché manca il dato, §8.6).
            static let coloreAlleanza = Colore.canaleAlleanza
            static let alleanza = Carattere(dimensione: 12, peso: .semibold)
            /// «Come funziona»: card piatta, 10 sotto il consenso, testo interlinea 1,5 a 6 dall'occhiello.
            static let superficieComeFunziona = Superficie.cardPiatta
            static let sopraComeFunziona: CGFloat = 10
            static let testoComeFunziona = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.5)
            static let sottoOcchielloComeFunziona: CGFloat = 6
        }

        // MARK: La testata dell'incontro (§8.2.2)

        enum Testata {
            /// Card piatta, padding 16×20, 16 fra gli elementi.
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.padding(16, 20)
            static let spazio: CGFloat = 16
            static let avatar: CGFloat = 44
            /// Larghezza sotto cui titolo e stato non scendono: se non resta posto, l'onda della voce si toglie (iPad).
            static let larghezzaMinimaTitoli: CGFloat = 260
            /// Sotto questa larghezza dell'area principale l'onda (360) lascia il posto a titoli e pulsante.
            static let larghezzaMinimaConOnda: CGFloat = 900
            /// Titolo 16 bold; stato `.k` (in rosso un problema del microfono o del riconoscimento).
            static let titolo = Carattere(dimensione: 16, peso: .bold)
            static let coloreTitolo = Colore.inchiostro
            static let stato = Carattere(dimensione: 12.5, peso: .regular, tabellare: true)
            static let coloreStato = Colore.inchiostro2
            static let coloreProblema = Colore.rosso
            static let spazioTitoli: CGFloat = 2
            /// Il pulsante grande: «● Avvia il copilota» rosso, «■ Termina» quasi nero (nello scuro un bianco al 20%,
            /// perché `#14202B` sparirebbe sulla card scura: dubbio §15.9 punto 7), testo bianco.
            static let pulsante = Carattere.pulsanteGrande
            static let paddingPulsante = Misura.Padding.pulsanteGrande
            static let fondoAvvia = Colore.rosso
            static let fondoTermina = Color.dinamico(chiaro: Color(hex: "#14202B"), scuro: Color(r: 255, g: 255, b: 255, a: 0.20))
            static let testoPulsante = Color.white
            static let opacitaSpento: Double = 0.45
            /// «sul dispositivo · l'audio non lascia il Mac»: 11,5 semibold verde con il lucchetto.
            static let indicatore = Carattere(dimensione: 11.5, peso: .semibold)
            static let coloreIndicatore = Colore.verde
            static let spazioIndicatore: CGFloat = 4
        }

        // MARK: L'onda della voce (§8.2.2)

        enum Onda {
            /// Tela 360×44: 48 barre a passo 7,5, larghe 4,5, raggio 2,2, centrate a metà altezza.
            static let larghezza: CGFloat = 360
            static let altezza: CGFloat = 44
            static let barre = 48
            static let passo: CGFloat = 7.5
            static let larghezzaBarra: CGFloat = 4.5
            static let raggioBarra: CGFloat = 2.2
            /// Altezza = max(3, a·40).
            static let minima: CGFloat = 3
            static let scala: CGFloat = 40
            /// Ascolto: rosso all'85%; ferma: grigio al 35% (tutte alte 3).
            static let coloreAscolto = Color(r: 229, g: 72, b: 77, a: 0.85)
            static let coloreFermo = Color(r: 120, g: 130, b: 140, a: 0.35)
            /// Le istantanee disegnano la forma del template al secondo 2 (sempre la stessa).
            static let tempoIstantanea: Double = 2
            /// Il microfono dà un picco ogni ~0,1 s: fra un valore e l'altro le barre scorrono in 0,1 s.
            static let durataPasso = 0.10
            static var passoAnimato: Animation { .linear(duration: durataPasso * Tema.Apple.Moto.ritmo) }
        }

        // MARK: La trascrizione (§8.2.3)

        enum Trascrizione {
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.padding(18, 22)
            static let occhiello = Carattere.etichetta
            static let coloreOcchiello = Colore.inchiostro2
            static let sopraRighe: CGFloat = 10
            /// Riga: chi parla largo 56 (13 bold, 2 più in basso) e il testo 15 con interlinea 1,5, a 12; filo sotto.
            static let paddingRiga: CGFloat = 9
            static let spazio: CGFloat = 12
            static let chi = Carattere(dimensione: 13, peso: .bold)
            static let larghezzaChi: CGFloat = 56
            /// Un nome lungo si stringe appena per stare nei 56.
            static let scalaMinimaChi: CGFloat = 0.8
            static let sopraChi: CGFloat = 2
            static let testo = Carattere(dimensione: 15, peso: .regular)
            /// Spazio fra le righe di una stessa frase (interlinea 1,5 su 15) e fra le parole.
            static let interlinea: CGFloat = 4.5
            static let spazioParole: CGFloat = 4
            static let coloreTesto = Colore.inchiostro
            static let coloreConsulente = Colore.accento
            static let coloreSconosciuto = Colore.inchiostro3
            /// La riga che si sta ancora riconoscendo.
            static let coloreInCorso = Colore.inchiostro2
            /// Le parole riconosciute: pastiglia blu chiara, testo blu semibold, raggio 6, padding 0×4.
            static let evidenza = Carattere(dimensione: 15, peso: .semibold)
            static let fondoEvidenza = Colore.selezioneVoce
            static let testoEvidenza = Colore.accento
            static let raggioEvidenza = Raggio.bollaPiccola
            static let paddingEvidenza = EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
            /// La riga da cui nasce la scheda toccata: fondo `selezioneVoce` al passaggio.
            static let fondoRigaIndicata = Colore.selezioneVoce
            static let raggioRigaIndicata = Raggio.bollaPiccola
            /// Restano visibili al massimo 7 righe: l'ottava fa sparire la più vecchia in alto.
            static let righeVisibili = 7
            /// «Parla pure: le parole compaiono qui.»
            static let vuoto = Carattere(dimensione: 14, peso: .regular)
            static let coloreVuoto = Colore.inchiostro2
            /// «Conserva la trascrizione» spento: la nota sotto l'occhiello.
            static let nota = Carattere(dimensione: 11.5, peso: .regular)
            static let coloreNota = Colore.inchiostro3
        }

        // MARK: Le schede (§8.2.3)

        enum Scheda {
            /// Card con l'ombra (`--shadow`), padding 12×16, 10 sotto, filo colorato a sinistra di 4.
            static let superficie = Superficie.card
            static let raggio = Raggio.card
            static let padding = Misura.padding(12, 16)
            static let fraSchede: CGFloat = 10
            static let filo: CGFloat = 4
            /// Occhiello `.lbl` 11 nel colore del tipo; frase 15 semibold a 2; pulsanti a 8.
            static let occhiello = Carattere(dimensione: 11, peso: .semibold, tracking: 0.6, maiuscolo: true)
            static let frase = Carattere(dimensione: 15, peso: .semibold)
            static let coloreFrase = Colore.inchiostro
            static let sopraFrase: CGFloat = 2
            static let sopraPulsanti: CGFloat = 8
            static let spazioPulsanti: CGFloat = 6
            /// «✓ Fatto» in verde; «Scartata» in `inchiostro3`; la provenienza (iPad, Qwen) in `inchiostro3`.
            static let fatto = Carattere(dimensione: 12.5, peso: .semibold)
            static let coloreFatto = Colore.verde
            static let coloreScartata = Colore.inchiostro3
            static let opacitaScartata: Double = 0.55
            static let provenienza = Carattere(dimensione: 11, peso: .regular)
            static let coloreProvenienza = Colore.inchiostro3
            /// Il vuoto: `.k` 14 centrato, padding 30.
            static let vuoto = Carattere(dimensione: 14, peso: .regular, interlinea: 1.45)
            static let coloreVuoto = Colore.inchiostro2
            static let paddingVuoto: CGFloat = 30
            /// «Vera non è pronta: Prisma riconosce con le sue regole.» sotto l'occhiello; l'iPad in attesa del Mac in arancio.
            static let nota = Carattere(dimensione: 12, peso: .regular, interlinea: 1.4)
            static let coloreNota = Colore.inchiostro2
            static let coloreAttesa = Colore.arancio
            static let sottoNota: CGFloat = 8
        }

        // MARK: Il verbale (§8.2.4)

        enum Verbale {
            /// Dettaglio 940×520, contenuto con il padding del dettaglio (26×30).
            static let misura = CGSize(width: 940, height: 520)
            /// Occhiello verde, titolo display 27 bold (−0,5).
            static let occhiello = Carattere.etichetta
            static let coloreOcchiello = Colore.verde
            static let titolo = Carattere.titoloDettaglio(27)
            static let coloreTitolo = Colore.inchiostro
            /// Colonne a 20 sotto il titolo, 26 fra loro; la destra larga 380.
            static let sopraColonne: CGFloat = 20
            static let spazioColonne: CGFloat = 26
            static let larghezzaDestra: CGFloat = 380
            /// «Il verbale»: occhiello a 6 dal testo 14,5 con interlinea 1,65.
            static let sottoOcchiello: CGFloat = 6
            static let testo = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.65)
            static let coloreTesto = Colore.inchiostro
            /// «Le attività» a 16 dal verbale; «Cosa entra nel dossier» a 4 dalle righe.
            static let sopraAttivita: CGFloat = 16
            static let sottoOcchielloDossier: CGFloat = 4
            /// Chi ha scritto il verbale: 11,5 `inchiostro3`.
            static let firma = Carattere(dimensione: 11.5, peso: .regular)
            static let coloreFirma = Colore.inchiostro3
            /// Le righe con il pallino: quelle di «Ti preparo» (TiPreparo).
            static let voce = Carattere.voceLista
            static let coloreVoce = Colore.inchiostro
            static let coloreVoceFatta = Colore.inchiostro2
            /// «Niente da aggiungere.» e i vuoti.
            static let vuoto = Carattere.secondario
            static let coloreVuoto = Colore.inchiostro2
            /// Pulsanti grandi a 8 l'uno dall'altro, in fondo; «Conserva la trascrizione» a destra.
            static let spazioPulsanti: CGFloat = 8
            static let sopraPulsanti: CGFloat = 14
            static let interruttore = Carattere.secondario
            static let coloreInterruttore = Colore.inchiostro2
        }
    }
}

// MARK: - Tempi e curve (§8.3)

extension Tema.Apple.Moto {
    enum Copilota {
        /// Riga nuova: da y +10 e trasparente in 0,35 s con `uscita`.
        static let durataRiga = 0.35
        static let spostamentoRiga: CGFloat = 10
        /// Parola nuova della riga in corso: dissolvenza di 0,11 s.
        static let durataParola = 0.11
        static var parola: Animation { .easeOut(duration: durataParola * Tema.Apple.Moto.ritmo) }
        /// Scheda nuova: da x +40, scala 0,92, trasparente, 0,62 s con la molla.
        static let durataScheda = 0.62
        static let spostamentoScheda: CGFloat = 40
        static let scalaScheda: CGFloat = 0.92
        /// «Conferma tutto»: le spunte una dopo l'altra (0,15 + k·0,26 s), molla di 0,35 s; l'avviso a 1,8 s.
        static let ritardoSpunte = 0.15
        static let passoSpunte = 0.26
        static let durataSpunta = 0.35
        static var spunta: Animation { Tema.Apple.Moto.molla(durataSpunta) }
        static func ritardoSpunta(_ k: Int) -> Double { ritardoSpunte + Double(k) * passoSpunte }
        static let avvisoDopo = 1.8
        /// Lo stesso ascolto riparte dopo ogni frase: un attimo per lasciare chiudere il riconoscimento di prima.
        static let ripresaAscolto = 0.05
    }
}

extension Tema.Apple.Moto.StileEntrata {
    /// Riga della trascrizione: da y +10, in 0,35 s con `uscita`, senza sfocatura.
    static let rigaCopilota = Tema.Apple.Moto.StileEntrata(durata: Tema.Apple.Moto.Copilota.durataRiga,
                                                           curva: Tema.Apple.Moto.Curva.uscita,
                                                           spostamentoX: 0,
                                                           spostamentoY: Tema.Apple.Moto.Copilota.spostamentoRiga,
                                                           scala: 1, sfocatura: 0)
    /// Scheda del copilota: da x +40, scala 0,92, in 0,62 s con la molla.
    static let schedaCopilota = Tema.Apple.Moto.StileEntrata(durata: Tema.Apple.Moto.Copilota.durataScheda,
                                                             curva: Tema.Apple.Moto.Curva.molla,
                                                             spostamentoX: Tema.Apple.Moto.Copilota.spostamentoScheda,
                                                             spostamentoY: 0,
                                                             scala: Tema.Apple.Moto.Copilota.scalaScheda, sfocatura: 0)
}

/// I valori di un'onda «nastro» (`OndaNastroApple`): quella del copilota (`.copilota`, i valori di
/// `Tema.Apple.Copilota.Onda`) e quella del telefono della nota vocale (`Tema.Apple.NotaVocale.onda`, «Luce» giro 13).
struct ParametriOnda {
    let larghezza: CGFloat
    let altezza: CGFloat
    let barre: Int
    let passo: CGFloat
    let larghezzaBarra: CGFloat
    let raggioBarra: CGFloat
    let minima: CGFloat
    let scala: CGFloat
    let coloreAscolto: Color
    let coloreFermo: Color
    let tempoIstantanea: Double

    static let copilota = ParametriOnda(larghezza: Tema.Apple.Copilota.Onda.larghezza, altezza: Tema.Apple.Copilota.Onda.altezza,
                                        barre: Tema.Apple.Copilota.Onda.barre, passo: Tema.Apple.Copilota.Onda.passo,
                                        larghezzaBarra: Tema.Apple.Copilota.Onda.larghezzaBarra,
                                        raggioBarra: Tema.Apple.Copilota.Onda.raggioBarra, minima: Tema.Apple.Copilota.Onda.minima,
                                        scala: Tema.Apple.Copilota.Onda.scala, coloreAscolto: Tema.Apple.Copilota.Onda.coloreAscolto,
                                        coloreFermo: Tema.Apple.Copilota.Onda.coloreFermo,
                                        tempoIstantanea: Tema.Apple.Copilota.Onda.tempoIstantanea)
}
