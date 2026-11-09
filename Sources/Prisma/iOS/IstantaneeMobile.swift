#if os(iOS)
import SwiftUI
import UIKit

/// Istantanee di iPhone e iPad (`--istantanee-ios [scene]`), scattate dal workflow con `simctl io screenshot`
/// (fedele: vetro, ombre, barre di sistema). Sincronizzazione a file con Supporto/iOS/istantanee.sh:
/// 1. l'app mostra la scena e aspetta che il disegno si fermi;
/// 2. scrive in modo atomico Documents/scena-pronta.txt con il nome della scena (lo script lo cancella e scatta);
/// 3. aspetta Documents/scatto-fatto.txt, lo cancella e passa alla scena successiva;
/// 4. alla fine scrive Documents/esito-istantanee-ios.txt (EsitoProva) ed esce.
/// Chiaro e scuro li sceglie lo script (`simctl ui appearance`): Prisma resta sull'aspetto «automatico».
/// Ogni scena ha uno stato nuovo con i dati di prova (StatoShell non persistente: niente disco).
@MainActor
enum IstantaneeMobile {
    struct Scena {
        let nome: String
        /// Solo iPad: la scena si scatta in orizzontale (le altre in verticale, come parte il simulatore). Il
        /// simulatore resta in verticale: è l'app a disegnare la radice girata (`RadiceRuotataIstantanea`).
        var orizzontale = false
        /// Attesa in più prima dello scatto, per la scrivania dell'iPad: con `istantaneaSchermo` i riquadri sono già
        /// nello stato finale (niente cascata, numeri completi, anelli pieni); il margine copre vetro e materiali.
        var attesaInPiu: UInt64 = 0
        /// Sul thread principale, come lo stato che prepara.
        let prepara: @MainActor (StatoMobile) -> Void
        /// Facoltativo: si ripete dopo che la scena è comparsa (per lo stato che una vista può azzerare al primo
        /// disegno, come il dettaglio di Posizioni quando cambia il cliente attivo).
        var ritocco: (@MainActor (StatoMobile) -> Void)? = nil
    }

    /// Le scene dell'iPad e dell'iPhone (le dimensioni vengono dal dispositivo: ognuno scatta le sue). Dal giro 3 le
    /// app stanno nella finestra di vetro sopra la scrivania (`m.apri`), e ci sono le scene della scrivania, del
    /// dock e dei pannelli. Prima `m.apri`, poi i percorsi dell'iPhone: le icone li azzerano.
    static func scene(iPad: Bool) -> [Scena] {
        var elenco: [Scena] = [
            Scena(nome: "1-apertura-backup") { m in m.apriBackup() },
            Scena(nome: "2-apertura-password") { m in
                m.simulaScelta(nome: "Prisma 2026-10-29 09.12.04.zip.cifrato", protetto: true,
                               fase: .errore("La password non è corretta: riprova."))
            },
            Scena(nome: "3-clienti") { m in m.apri(.clienti) },
            Scena(nome: "4-clienti-scheda") { m in
                m.stato.clienteAttivoId = "marco"
                m.apri(.clienti)
                m.percorsoClienti = [.cliente("marco")]
            },
            Scena(nome: "5-posizioni", attesaInPiu: IstantaneeMobile.attesaScrivania) { m in m.apri(.posizioni) },
            Scena(nome: "6-posizioni-dettaglio", prepara: { m in
                m.stato.clienteAttivoId = "giulia"
                m.stato.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
                m.apri(.posizioni)
                m.percorsoPosizioni = [.posizione("pos-giulia-etf-azionario-globale")]
            }, ritocco: { m in
                // AppPosizioni chiude il dettaglio a ogni cambio del cliente attivo: si riapre a scena comparsa
                m.stato.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
            }),
            Scena(nome: "7-agenda") { m in
                m.stato.appuntamentoSelezionato = "event-marco"
                m.apri(.agenda)
            },
        ]
        if iPad {
            elenco += [
                // «Luce» giro 3: la proposta che si costruisce da sola sull'iPad come sul Mac (§7.1.4), costruita fino in
                // fondo sul primo bisogno dei clienti di prova che arriva a «Proposta pronta»
                Scena(nome: "808-pratiche-proposta-ipad", orizzontale: true) { m in
                    m.stato.schedaPratiche = .proposta
                    m.apri(.pratiche)
                    m.stato.moduli.carica()
                    guard let b = m.stato.bisogniProposta().first(where: { m.stato.propostaCostruita($0)?.pronta == true }) else { return }
                    m.stato.scegliBisognoProposta(b.id)
                    m.stato.costruisciProposta(b, animato: false)
                },
                Scena(nome: "8-simulazioni") { m in m.apri(.simulazioni) },
                Scena(nome: "9-vera", attesaInPiu: IstantaneeMobile.attesaScrivania) { m in m.apri(.vera) },
                Scena(nome: "10-impostazioni-archivio") { m in
                    m.stato.schedaImpostazioni = .archivio
                    m.apri(.impostazioni)
                },
                Scena(nome: "11-ricerca") { m in
                    m.stato.testoRicerca = "Marco"
                    m.apri(.clienti)
                    m.stato.cercaOvunque()
                },
                // Tutte le app dell'iPad, in verticale (la finestra più stretta del 13")
                Scena(nome: "12-analisi360") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.apri(.analisi360)
                },
                Scena(nome: "13-incontri") { m in
                    m.stato.clienteAttivoId = "marco"
                    m.apri(.incontri)
                },
                Scena(nome: "14-obiettivi") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.obiettivoSelezionato = "obiettivo-giulia-casa"
                    m.apri(.obiettivi)
                },
                Scena(nome: "15-confronti") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.apri(.confronti)
                },
                Scena(nome: "16-prodotti") { m in m.apri(.prodotti) },
                Scena(nome: "17-attivita") { m in m.apri(.attivita) },
                Scena(nome: "18-note") { m in m.apri(.note) },
                // Documenti: il KID di Giulia (nelle istantanee senza il file PDF: c'è la scheda dei dati)
                Scena(nome: "19-documenti") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.documentoSelezionato = "doc-giulia-kid"
                    m.apri(.documenti)
                },
                // Prospetti: le pagine del PDF in anteprima, come a schermo sul Mac
                Scena(nome: "20-prospetti-resoconto") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.apriProspetto(.resoconto(report: false))
                    m.apri(.presentazioni)
                },
                Scena(nome: "21-prospetto-proposta") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.apriProspetto(.posizione("pos-giulia-piano-previdenziale-integrativo"))
                    m.apri(.presentazioni)
                },
                Scena(nome: "22-impostazioni") { m in
                    m.stato.schedaImpostazioni = .panoramica
                    m.apri(.impostazioni)
                },
                // Impostazioni nel tema Apple anche sull'iPad: il segmentato a pillola e l'interruttore, poi il profilo
                Scena(nome: "23-impostazioni-aspetto") { m in
                    m.stato.schedaImpostazioni = .aspetto
                    m.apri(.impostazioni)
                },
                Scena(nome: "24-impostazioni-profilo") { m in
                    m.stato.schedaImpostazioni = .profilo
                    m.apri(.impostazioni)
                },
                // La scrivania del Mac sull'iPad in verticale (tema Apple): saluto e guida compatta, la mossa del
                // giorno, poi i riquadri del Mac su tre righe a due colonne
                Scena(nome: "41-scrivania-verticale", attesaInPiu: IstantaneeMobile.attesaScrivania) { m in m.mostraHome() },
                // La stessa senza la guida (finita o nascosta): sotto il saluto c'è subito la mossa del giorno
                Scena(nome: "45-scrivania-senza-guida", attesaInPiu: IstantaneeMobile.attesaScrivania) { m in
                    m.stato.dati.impostazioni.guidaNascosta = true
                    m.mostraHome()
                },
                // Le stesse app con l'iPad in orizzontale: le colonne del Mac tornano affiancate. Il simulatore non si
                // gira (in iPadOS 26 la rotazione chiesta dall'app ridisegna la finestra, non lo schermo): la radice si
                // disegna in un riquadro orizzontale girato di 90° e lo script raddrizza la PNG (RadiceRuotataIstantanea)
                Scena(nome: "30-clienti-orizzontale", orizzontale: true, attesaInPiu: IstantaneeMobile.attesaScrivania) { m in
                    m.stato.clienteAttivoId = "marco"
                    m.apri(.clienti)
                },
                Scena(nome: "31-posizioni-orizzontale", orizzontale: true, attesaInPiu: IstantaneeMobile.attesaScrivania) { m in m.apri(.posizioni) },
                Scena(nome: "32-posizioni-dettaglio-orizzontale", orizzontale: true, attesaInPiu: IstantaneeMobile.attesaScrivania, prepara: { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
                    m.apri(.posizioni)
                }, ritocco: { m in
                    m.stato.posizioneInDettaglio = "pos-giulia-etf-azionario-globale"
                }),
                Scena(nome: "33-documenti-orizzontale", orizzontale: true, attesaInPiu: IstantaneeMobile.attesaScrivania) { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.documentoSelezionato = "doc-giulia-kid"
                    m.apri(.documenti)
                },
                Scena(nome: "34-prospetti-orizzontale", orizzontale: true) { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.apriProspetto(.resoconto(report: false))
                    m.apri(.presentazioni)
                },
                Scena(nome: "35-impostazioni-orizzontale", orizzontale: true) { m in
                    m.stato.schedaImpostazioni = .archivio
                    m.apri(.impostazioni)
                },
                // La scrivania in orizzontale: i riquadri del Mac come sul Mac, il dock con i nomi; poi i pannelli
                Scena(nome: "40-scrivania-orizzontale", orizzontale: true, attesaInPiu: IstantaneeMobile.attesaScrivania) { m in
                    m.mostraHome()
                },
                Scena(nome: "42-scrivania-notifiche", orizzontale: true, attesaInPiu: IstantaneeMobile.attesaScrivania) { m in
                    m.mostraHome()
                    m.stato.alternaNotifiche()
                },
                Scena(nome: "43-scrivania-controllo", orizzontale: true, attesaInPiu: IstantaneeMobile.attesaScrivania) { m in
                    m.mostraHome()
                    m.pannello = .controllo
                },
                Scena(nome: "44-app-aperte", orizzontale: true) { m in
                    m.apri(.clienti)
                    m.apri(.posizioni)
                    m.apri(.agenda)
                    m.pannello = .appAperte
                },
                // Il tavolo con il Mac (TavoloiPad.swift), con un tavolo finto senza rete: la pagina mandata dal Mac,
                // il cursore lasciato al cliente, la presa visione con un tratto di prova e la schermata neutra
                Scena(nome: "50-tavolo-pagina", attesaInPiu: IstantaneeMobile.attesaScrivania) { m in IstantaneeTavoloiPad.pagina(m) },
                Scena(nome: "51-tavolo-cursore", attesaInPiu: IstantaneeMobile.attesaScrivania) { m in IstantaneeTavoloiPad.cursore(m) },
                Scena(nome: "52-tavolo-presa-visione") { m in IstantaneeTavoloiPad.presaVisione(m) },
                Scena(nome: "53-tavolo-neutro") { m in IstantaneeTavoloiPad.neutra(m) },
                // «Luce» giro 16: il tavolo a doppio senso (rischio, Lancia l'anno, disegno, capsula, realtà aumentata)
                Scena(nome: "56-tavolo-rischio") { m in IstantaneeTavoloiPad.rischio(m) },
                Scena(nome: "57-tavolo-lancia-anno") { m in IstantaneeTavoloiPad.lancia(m) },
                Scena(nome: "58-tavolo-disegno") { m in IstantaneeTavoloiPad.disegno(m) },
                Scena(nome: "59-tavolo-capsula") { m in IstantaneeTavoloiPad.capsula(m) },
                Scena(nome: "74-ar-tavolo") { m in IstantaneeTavoloiPad.realta(m) },
                // «Luce» giro 16: Sala › La realtà aumentata a tutto schermo, con il ripiego disegnato (nel simulatore
                // non c'è la fotocamera): il cristallo sul tavolo virtuale, l'esploso, la fotocamera negata
                Scena(nome: "70-ar-ipad", orizzontale: true) { m in IstantaneeMobile.realta(m, ScenaRealtaDiProva()) },
                Scena(nome: "71-ar-ipad-esploso", orizzontale: true) { m in
                    IstantaneeMobile.realta(m, ScenaRealtaDiProva(allaPensione: true, esploso: true))
                },
                Scena(nome: "73-ar-non-disponibile", orizzontale: true) { m in
                    IstantaneeMobile.realta(m, ScenaRealtaDiProva(fotocameraNegata: true))
                },
                // «Luce», giro 1: il dock dell'iPad in verticale con le app del Mac fino a Prospetti, più Sala e Vera
                // (13 elementi, decisione 121); Biblioteca, Mercato, Studio e Impostazioni in «Tutte le app»
                Scena(nome: "55-dock-ipad-luce", attesaInPiu: IstantaneeMobile.attesaScrivania) { m in m.mostraHome() },
                // Messaggi (giro 3 di «Orizzonte»): la colonna delle occasioni e il riepilogo di Giulia scritto da Vera,
                // con i dati di prova di MessaggiDiProva (Shell/IstantaneeMessaggi.swift)
                Scena(nome: "498-messaggi") { m in IstantaneeMobile.messaggi(m) },
                // Mercato (giro 7 di «Orizzonte»): la stessa finestra del Mac con i dati di prova di MercatoDiProva
                // (Shell/IstantaneeMercato.swift), in sola lettura
                Scena(nome: "540-mercato") { m in IstantaneeMobile.mercato(m) },
                // Il copilota dell'incontro (giro 5 di «Orizzonte»): il riconoscimento sull'iPad con il dialogo di prova
                // (Shell/DialogoProvaCopilota.swift), in verticale (colonne una sotto l'altra) e in orizzontale; poi le
                // schede rimaste sull'iPad perché il Mac non risponde
                Scena(nome: "580-copilota-ascolto") { m in IstantaneeMobile.copilota(m) },
                Scena(nome: "581-copilota-orizzontale", orizzontale: true) { m in IstantaneeMobile.copilota(m) },
                Scena(nome: "582-copilota-attesa-mac", orizzontale: true) { m in
                    IstantaneeMobile.copilota(m, attesa: true)
                },
                // Prisma ovunque (giro 8): l'iPad sulla copia cifrata con il Mac che non risponde, la pillola nella barra e
                // Impostazioni › iPhone e iPad del dispositivo (dati di prova di Shell/IstantaneeOvunque.swift)
                Scena(nome: "613-ovunque-ipad") { m in
                    DatiProvaOvunque.dispositivoAcceso(m.stato, iPad: true)
                    m.stato.schedaImpostazioni = .ovunque
                    m.apri(.impostazioni)
                },
            ]
        } else {
            elenco += [
                Scena(nome: "8-agenda-dettaglio") { m in
                    m.apri(.agenda)
                    m.percorsoAgenda = [.appuntamento("event-marco")]
                },
                // Il centro notifiche del Mac sotto la barra, sopra la scrivania
                Scena(nome: "9-notifiche") { m in
                    m.mostraHome()
                    m.stato.alternaNotifiche()
                },
                Scena(nome: "10-impostazioni") { m in m.apri(.impostazioni) },
                // La scrivania del tema Apple a una colonna: in cima (saluto, la mossa del giorno con il prossimo incontro,
                // «Richiede attenzione») e in fondo (la riga di Vera, il portafoglio con i tre anelli, il piede, il dock)
                Scena(nome: "40-scrivania") { m in m.mostraHome() },
                Scena(nome: "41-scrivania-giu") { m in
                    m.mostraHome()
                    m.scrivaniaInFondo = true
                },
                Scena(nome: "43-ricerca") { m in
                    m.mostraHome()
                    m.stato.testoRicerca = "Marco"
                    m.stato.cercaOvunque()
                },
                Scena(nome: "44-controllo") { m in
                    m.mostraHome()
                    m.pannello = .controllo
                },
                Scena(nome: "45-tutte-le-app") { m in
                    m.mostraHome()
                    m.pannello = .tutteLeApp
                },
                // «Luce», giro 1: «Tutte le app» con le quattro app nuove (Territorio, Pratiche, Sala, Biblioteca)
                Scena(nome: "54-tutte-le-app-luce") { m in
                    m.mostraHome()
                    m.pannello = .tutteLeApp
                },
                Scena(nome: "46-attivita") { m in m.apri(.attivita) },
                Scena(nome: "47-note") { m in m.apri(.note) },
                Scena(nome: "48-documenti") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.apri(.documenti)
                },
                Scena(nome: "49-in-arrivo") { m in m.apri(.analisi360) },
                // Vera sull'iPhone: Qwen del Mac in Wi‑Fi. Prima il Mac non collegato, poi una conversazione
                Scena(nome: "50-vera-mac-assente") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.disponibilitaLocale = .nonDisponibile(PonteVera.macNonTrovato)
                    m.apri(.vera)
                },
                // Messaggi (giro 3 di «Orizzonte»): il messaggio dell'occasione in alto, tono, canale e testo, le altre
                // occasioni a un tocco nel menu «Occasioni»
                Scena(nome: "497-messaggi") { m in IstantaneeMobile.messaggi(m) },
                // «Luce» giro 16: la realtà aumentata sull'iPhone, in verticale: «Fine» e lo scatto spento con l'aiuto
                Scena(nome: "72-ar-iphone") { m in IstantaneeMobile.realta(m, ScenaRealtaDiProva()) },
                // «Luce» giro 12: i potenziali clienti in sola lettura (una cosa grande in alto, poi l'elenco per fase)
                Scena(nome: "76-potenziali-iphone") { m in
                    m.apri(.clienti)
                    m.percorsoClienti = [.potenziali]
                },
                // «Luce» giro 15: i sinistri in sola lettura (i tre sinistri di prova, ridotti come nell'istantanea di
                // «Prisma ovunque»: niente descrizione, numeri, stime né importi)
                // «Luce» §7.3.4: «Dopo la firma» sull'iPhone con le quattro pratiche di prova (una ferma in alto, poi le
                // aperte), in sola lettura: senza «Prisma ovunque» acceso i passi si segnano dal Mac
                Scena(nome: "824-pratiche-iphone") { m in m.apri(.pratiche) },
                Scena(nome: "836-sinistri-iphone") { m in
                    m.stato.dati.sinistri = m.stato.dati.sinistri.map(SpazioOvunque.sinistroPerOvunque)
                    m.apri(.clienti)
                    m.percorsoClienti = [.sinistri]
                },
                // Mercato (giro 7): la prima tessera grande, le altre su due colonne, chi è toccato e gli avvisi
                Scena(nome: "540-mercato") { m in IstantaneeMobile.mercato(m) },
                // Inquadra e capisci (giro 5): la schermata della fotocamera a lettura finita, con il foglio di prova
                // disegnato al posto della foto (nessuna foto vera, nessuna fotocamera nel simulatore)
                Scena(nome: "609-inquadra-iphone", prepara: { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.apri(.posizioni)
                }, ritocco: { m in IstantaneeMobile.inquadra(m) }),
                // «Luce» giro 13: la carta d'identità fac-simile (dati di prova dichiarati) letta sull'iPhone, con «Manda al Mac»
                Scena(nome: "75-nuovo-cliente-iphone", prepara: { m in
                    m.apri(.clienti)
                }, ritocco: { m in IstantaneeMobile.cartaIdentita(m) }),
                // «Luce» giro 13: la nota vocale (il testo del template, dati di prova): in ascolto, pronta, in coda
                Scena(nome: "775-nota-iphone-ascolto", prepara: { m in
                    m.apri(.incontri)
                }, ritocco: { m in IstantaneeMobile.notaVocale(m, fase: .ascolto) }),
                Scena(nome: "776-nota-iphone-pronta", prepara: { m in
                    m.apri(.incontri)
                }, ritocco: { m in IstantaneeMobile.notaVocale(m, fase: .fermata) }),
                Scena(nome: "777-nota-iphone-in-coda", prepara: { m in
                    m.apri(.incontri)
                }, ritocco: { m in IstantaneeMobile.notaVocale(m, fase: .inCoda) }),
                // Prisma ovunque (giro 8, dati di prova di Shell/IstantaneeOvunque.swift): il dossier di Giulia sulla copia
                // cifrata con la pillola «Senza Mac» nella barra; Impostazioni › iPhone e iPad con l'ultima copia letta e
                // le 3 modifiche da unire; la prima volta, con la scelta della cartella e la passphrase
                Scena(nome: "610-ovunque-senza-mac") { m in
                    DatiProvaOvunque.dispositivoAcceso(m.stato, iPad: false)
                    m.stato.clienteAttivoId = "giulia"
                    m.apri(.clienti)
                    m.percorsoClienti = [.cliente("giulia")]
                },
                Scena(nome: "611-ovunque-impostazioni") { m in
                    DatiProvaOvunque.dispositivoAcceso(m.stato, iPad: false)
                    m.apri(.impostazioni)
                },
                Scena(nome: "612-ovunque-scegli-cartella") { m in
                    m.stato.ovunque.cartellaScelta = URL(fileURLWithPath: DatiProvaOvunque.percorso, isDirectory: true)
                    m.stato.ovunque.modulo = .accendi
                    m.apri(.impostazioni)
                },
                Scena(nome: "51-vera-conversazione") { m in
                    m.stato.clienteAttivoId = "giulia"
                    m.stato.disponibilitaLocale = .pronto
                    m.stato.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Cosa ha Giulia in scadenza nei prossimi mesi?"),
                                              cliente: "giulia", parla: false)
                    m.stato.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "Nei prossimi 12 mesi Giulia ha 2 posizioni in scadenza: il conto deposito a gennaio (indipendente) e il piano di risparmio a marzo (Alleanza). È liquidità che può andare verso l'anticipo della casa: ne parlerei con lei prima di gennaio.",
                                                           motore: "Qwen sul Mac"), cliente: "giulia", parla: false)
                    m.apri(.vera)
                },
            ]
        }
        return elenco
    }

    /// Il copilota dell'incontro sull'iPad: le prime quattro righe del dialogo di prova e le loro schede, in ascolto;
    /// con `attesa` le schede non ancora arrivate al Mac (che non risponde). Dati di prova dichiarati.
    static func copilota(_ m: StatoMobile, attesa: Bool = false) {
        let sid = DialogoProvaCopilota.prepara(m.stato, righe: 4)
        let schede = sid.flatMap { m.stato.sessioneCopilota($0)?.schede.count } ?? 0
        m.stato.copilota.mostraPerIstantanea(fase: .ascolto, sessione: sid, secondi: 9, qwenPronto: true,
                                             attesaPonte: attesa ? schede : 0,
                                             motivoPonte: attesa ? PonteVera.macNonTrovato : nil)
        m.apri(.incontri)
    }

    /// Messaggi con i dati di prova: il riepilogo dell'incontro di Giulia, Cordiale, Mail, nello stato finale di Vera.
    static func messaggi(_ m: StatoMobile) {
        MessaggiDiProva.prepara(m.stato)
        RichiestaIstantaneaMessaggi.chiedi(m.stato, tipo: .riepilogoIncontro, cliente: "giulia")
        m.apri(.messaggi)
    }

    /// Mercato con i dati di prova dichiarati (MercatoDiProva): serie, fondo e BTP di prova, soglie e avvisi.
    static func mercato(_ m: StatoMobile) {
        MercatoDiProva.prepara(m.stato)
        m.apri(.mercato)
    }

    /// Sala › La realtà aumentata a tutto schermo («Luce» giro 16): il ripiego disegnato con lo stato di prova.
    static func realta(_ m: StatoMobile, _ prova: ScenaRealtaDiProva) {
        m.stato.clienteAttivoId = "giulia"
        m.stato.sala.realtaIstantanea = prova
        m.stato.sala.esperienza = .realtaAumentata
        m.apri(.sala)
        m.stato.sala.realtaAperta = true
    }

    /// Inquadra e capisci sull'iPhone: il foglio di prova (FoglioInquadraDiProva, dati dichiarati di prova) letto e
    /// tutto acceso, i dati riconosciuti e «Manda al Mac».
    static func inquadra(_ m: StatoMobile) {
        guard !m.stato.inquadra.telefonoAperto else { return }
        m.stato.inquadra.apriTelefono()
        m.stato.inquadra.mostra(righe: FoglioInquadraDiProva.righe(), origine: "", subito: true)
    }

    /// Nuovo cliente sull'iPhone («Luce» giro 13): la carta fac-simile (CartaIdentitaFacSimile, dati di prova dichiarati)
    /// letta e tutta accesa, con «Manda al Mac». Nessuna foto, nessuna fotocamera nel simulatore.
    static func cartaIdentita(_ m: StatoMobile) {
        guard !m.stato.nuovoCliente.telefonoAperto else { return }
        m.stato.nuovoCliente.apriTelefono()
        m.stato.nuovoCliente.mostra(righe: CartaIdentitaFacSimile.righe(), origine: "", subito: true)
    }

    /// La nota vocale sull'iPhone («Luce» giro 13): la schermata «Una nota veloce» con il testo del template
    /// (NotaVocaleDiProva, dati di prova dichiarati), l'onda ferma nella forma del template e, in coda, due note.
    static func notaVocale(_ m: StatoMobile, fase: FaseNotaTelefono) {
        guard !m.stato.notaVeloceAperta else { return }
        let n = m.stato.notaTelefono
        let livelli: [Float] = (0..<StatoNotaVocaleTelefono.livelliTenuti).map { i in Float(0.2 + 0.6 * abs(sin(Double(i) * 0.5))) }
        var coda: [CodaNoteVocali.VoceCoda] = []
        if fase == .inCoda {
            let quando = Date(timeIntervalSinceReferenceDate: 815_000_000)
            coda = [
                CodaNoteVocali.VoceCoda(nota: NotaVocaleDiProva.ponte(quando: quando, id: NotaVocaleDiProva.prefisso + "coda-1")),
                CodaNoteVocali.VoceCoda(nota: NotaVocalePonte(id: NotaVocaleDiProva.prefisso + "coda-2",
                                                              testo: "Laura ha chiesto il riepilogo delle polizze: mandarlo entro venerdì.",
                                                              quando: quando.addingTimeInterval(3_600), durata: 6,
                                                              dispositivo: NotaVocaleDiProva.dispositivo), tentativi: 1,
                                        ultimoMotivo: PonteVera.macNonTrovato),
            ]
        }
        let riga: String
        switch fase {
        case .ascolto: riga = "Ascolto · sull’iPhone"
        case .fermata: riga = "Pronta. Tocca ✓ per mandarla al Mac"
        case .inCoda: riga = "Il Mac non è raggiungibile: la nota parte quando sarai in rete con il Mac"
        case .mandata: riga = "✓ Nota mandata al Mac"
        case .pronta: riga = ""
        }
        n.clienteSuggerito = "giulia"
        n.preparaIstantanea(fase: fase, testo: NotaVocaleDiProva.testo, livelli: fase == .ascolto ? livelli : [], riga: riga, coda: coda)
        m.stato.notaVeloceAperta = true
    }

    /// Attese: la prima scena (primo avvio, caratteri e icone da preparare) e le altre; lo scatto dello script.
    static let attesaPrima: UInt64 = 3_000_000_000
    static let attesaScena: UInt64 = 1_500_000_000
    /// In più per la scrivania dell'iPad (riquadri già fermi con `istantaneaSchermo`: è solo un margine).
    static let attesaScrivania: UInt64 = 2_000_000_000
    static let limiteScatto: TimeInterval = 120
    static let intervalloControllo: UInt64 = 200_000_000

    /// Il disegno fermo prima dello scatto: l'impronta della finestra (ridotta) deve restare uguale fra due controlli
    /// di fila, entro un tempo massimo; se è uguale a quella della scena precedente si aspetta ancora un po' (il
    /// contenuto nuovo può non essere ancora disegnato). Poi un margine perché il fotogramma arrivi allo schermo.
    static let limiteStabile: TimeInterval = 15
    static let limiteUgualeAllaPrecedente: TimeInterval = 8
    static let intervalloStabile: UInt64 = 400_000_000
    static let margineSchermo: UInt64 = 500_000_000
    /// La scala dell'impronta: pochi pixel bastano a distinguere due scene (memoria minima).
    static let scalaImpronta: CGFloat = 0.1

    static var scenaFinestra: UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }

    static var finestra: UIWindow? {
        guard let scena = scenaFinestra else { return nil }
        return scena.windows.first(where: \.isKeyWindow) ?? scena.windows.first
    }

    /// La rotazione della radice nelle scene orizzontali, in gradi: antioraria, così il lato alto della scena va a
    /// sinistra dello schermo verticale e lo script la raddrizza girando la PNG di 90° in senso orario (`sips -r 90`).
    /// È una misura della ripresa, non della grafica: l'app vera non si disegna mai girata.
    static let rotazioneOrizzontale: Double = -90

    /// La finestra è verticale (più alta che larga): le scene orizzontali si disegnano girate.
    @MainActor
    static var finestraVerticale: Bool {
        guard let f = finestra else { return true }
        return f.bounds.width <= f.bounds.height
    }

    /// L'impronta del disegno attuale della finestra: un'immagine ridotta (prima si chiudono gli aggiornamenti in
    /// sospeso, `afterScreenUpdates`) riassunta in un numero. Nil se non c'è finestra.
    @MainActor
    static func impronta() -> Int? {
        guard let f = finestra, f.bounds.width > 0, f.bounds.height > 0 else { return nil }
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = scalaImpronta
        formato.opaque = true
        let immagine = UIGraphicsImageRenderer(bounds: f.bounds, format: formato).image { _ in
            _ = f.drawHierarchy(in: f.bounds, afterScreenUpdates: true)
        }
        guard let dati = immagine.pngData() else { return nil }
        var h = Hasher()
        h.combine(dati)
        h.combine(Int(f.bounds.width))
        h.combine(Int(f.bounds.height))
        return h.finalize()
    }

    static var documenti: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static var scenaPronta: URL { documenti.appendingPathComponent("scena-pronta.txt") }
    static var scattoFatto: URL { documenti.appendingPathComponent("scatto-fatto.txt") }
}

/// La vista delle istantanee: mostra una scena alla volta e parla con lo script attraverso i file.
struct VistaIstantaneeMobile: View {
    let solo: Set<String>?

    @State private var mobile: StatoMobile?
    @State private var indice = 0
    /// La scena attuale è orizzontale (solo iPad): la radice si disegna girata in un riquadro orizzontale.
    @State private var orizzontale = false
    /// I margini di sistema dell'iPad letti all'avvio, in verticale: in alto la barra di stato, in basso l'indicatore
    /// Home. In orizzontale sono gli stessi (l'iPad non ha tacca), quindi valgono anche per la scena girata.
    @State private var margini = EdgeInsets()

    var body: some View {
        Group {
            if let mobile {
                if orizzontale {
                    RadiceRuotataIstantanea(margini: margini, contenuto: RadiceMobile(mobile: mobile))
                        .id(indice)
                } else {
                    RadiceMobile(mobile: mobile)
                        .id(indice)
                }
            } else {
                Color.clear
            }
        }
        // Niente `modoIstantanea`: lo scatto è dello schermo vero, con il vetro e i materiali di iOS come li vede
        // l'utente (sul Mac serve solo perché le PNG si disegnano fuori schermo). I componenti del tema Apple però
        // sono già nello stato finale (numeri completi, anelli pieni, cascate concluse): `istantaneaSchermo`
        .environment(\.istantaneaSchermo, true)
        .task { await esegui() }
    }

    private func esegui() async {
        let fm = FileManager.default
        let iPad = UIDevice.current.userInterfaceIdiom == .pad
        let scene = IstantaneeMobile.scene(iPad: iPad).filter { solo?.contains($0.nome) ?? true }
        guard !scene.isEmpty else {
            EsitoProva.scrivi("istantanee-ios", ok: false, dettaglio: "nessuna scena con questi nomi: \(solo?.sorted().joined(separator: ",") ?? "")")
            exit(1)
        }
        try? fm.createDirectory(at: IstantaneeMobile.documenti, withIntermediateDirectories: true)
        try? fm.removeItem(at: IstantaneeMobile.scattoFatto)
        // I margini di sistema, prima di qualsiasi scena girata
        if let f = IstantaneeMobile.finestra {
            margini = EdgeInsets(top: f.safeAreaInsets.top, leading: 0, bottom: f.safeAreaInsets.bottom, trailing: 0)
        }
        let scala = IstantaneeMobile.finestra?.traitCollection.displayScale ?? 2
        var improntaPrecedente: Int?
        for (i, scena) in scene.enumerated() {
            // Stato nuovo per ogni scena, con i dati di prova e senza disco
            let stato = StatoShell(persistente: false)
            let nuovo = StatoMobile(stato: stato, persistente: false)
            scena.prepara(nuovo)
            // Girata solo se la finestra è verticale (lo è sempre, nel simulatore: non si ruota)
            let girata = iPad && scena.orizzontale && IstantaneeMobile.finestraVerticale
            orizzontale = girata
            indice = i
            mobile = nuovo
            // Il disegno si ferma (vetro, elenchi pigri, notifiche ricalcolate)
            try? await Task.sleep(nanoseconds: (i == 0 ? IstantaneeMobile.attesaPrima : IstantaneeMobile.attesaScena) + scena.attesaInPiu)
            if let ritocco = scena.ritocco {
                ritocco(nuovo)
                try? await Task.sleep(nanoseconds: IstantaneeMobile.attesaScena)
            }
            // Il fotogramma nuovo è davvero disegnato e fermo (non quello della scena precedente)
            let (attuale, ferma) = await aspettaDisegnoFermo(diversoDa: improntaPrecedente)
            let uguale = attuale != nil && attuale == improntaPrecedente
            if !ferma { print("Istantanee: \(scena.nome): il disegno non si è fermato entro \(Int(IstantaneeMobile.limiteStabile)) s") }
            if uguale { print("Istantanee: \(scena.nome): il disegno è uguale a quello della scena precedente") }
            improntaPrecedente = attuale
            try? await Task.sleep(nanoseconds: IstantaneeMobile.margineSchermo)
            // Riga 1 il nome; poi l'orientamento chiesto, se la scena è disegnata girata e quanti pixel in alto
            // dello scatto verticale occupa la barra di stato (fuori dal disegno girato), per lo script
            let righe = [scena.nome,
                         "richiesto=\(iPad && scena.orizzontale ? "orizzontale" : "verticale")",
                         "disegno=\(girata ? "girato" : "diritto")",
                         "fascia-alta=\(girata ? Int((margini.top * scala).rounded()) : 0)",
                         "uguale-alla-precedente=\(uguale ? "si" : "no")"]
            do {
                try Data((righe.joined(separator: "\n") + "\n").utf8).write(to: IstantaneeMobile.scenaPronta, options: .atomic)
            } catch {
                EsitoProva.scrivi("istantanee-ios", ok: false, dettaglio: "\(scena.nome): scena-pronta.txt non scritto (\(error.localizedDescription))")
                exit(1)
            }
            print("Istantanea pronta: \(scena.nome)")
            guard await aspettaScatto() else {
                EsitoProva.scrivi("istantanee-ios", ok: false, dettaglio: "\(scena.nome): lo scatto non è arrivato entro \(Int(IstantaneeMobile.limiteScatto)) s")
                exit(1)
            }
            try? fm.removeItem(at: IstantaneeMobile.scattoFatto)
        }
        EsitoProva.scrivi("istantanee-ios", ok: true, dettaglio: "\(scene.count) scene")
        exit(0)
    }

    /// Aspetta che due impronte di fila coincidano (disegno fermo). Se l'impronta ferma è quella della scena
    /// precedente continua a controllare per `limiteUgualeAllaPrecedente`: il contenuto nuovo può arrivare dopo.
    /// Restituisce l'ultima impronta e se il disegno si è fermato.
    private func aspettaDisegnoFermo(diversoDa precedente: Int?) async -> (Int?, Bool) {
        let inizio = Date()
        var ultima = IstantaneeMobile.impronta()
        var fermaDa: Date?
        while Date().timeIntervalSince(inizio) < IstantaneeMobile.limiteStabile {
            try? await Task.sleep(nanoseconds: IstantaneeMobile.intervalloStabile)
            let nuova = IstantaneeMobile.impronta()
            guard nuova != nil, nuova == ultima else {
                ultima = nuova
                fermaDa = nil
                continue
            }
            if nuova != precedente { return (nuova, true) }
            // Fermo ma uguale alla scena prima: si concede ancora un po' di tempo, poi si scatta comunque
            let da = fermaDa ?? Date()
            fermaDa = da
            if Date().timeIntervalSince(da) >= IstantaneeMobile.limiteUgualeAllaPrecedente { return (nuova, true) }
        }
        return (ultima, false)
    }

    /// Aspetta il file dello script (controllato cinque volte al secondo), entro il tempo massimo.
    private func aspettaScatto() async -> Bool {
        let inizio = Date()
        while Date().timeIntervalSince(inizio) < IstantaneeMobile.limiteScatto {
            if FileManager.default.fileExists(atPath: IstantaneeMobile.scattoFatto.path) { return true }
            try? await Task.sleep(nanoseconds: IstantaneeMobile.intervalloControllo)
        }
        return false
    }
}

/// La radice di una scena orizzontale dell'iPad nel simulatore verticale. In iPadOS 26 l'app non può girare lo
/// schermo (`requestGeometryUpdate` rimpicciolisce la finestra e UIRequiresFullScreen è ignorato) e la barra di
/// stato resta visibile; si fa allora così:
/// - sotto la barra di stato (fascia alta dello schermo verticale, `margini.top`) c'è un riquadro largo quanto lo
///   schermo è alto meno la barra e alto quanto lo schermo è largo: sul 13" 1352 × 1032 punti, cioè l'iPad in
///   orizzontale meno la sola barra di stato (24 punti di larghezza in meno);
/// - lì dentro Prisma si dispone davvero in orizzontale (la stessa RadiceMobile, che legge solo la misura offerta),
///   con in alto e in basso i margini dell'orizzontale (barra di stato e indicatore Home, uguali al verticale);
/// - il riquadro si disegna girato di 90° in senso antiorario (`rotazioneOrizzontale`): solo il disegno gira, la
///   disposizione resta quella orizzontale;
/// - lo script (Supporto/iOS/istantanee.sh) toglie la fascia della barra di stato e raddrizza la PNG.
/// Se la finestra è già orizzontale non serve: la radice si disegna diritta.
private struct RadiceRuotataIstantanea<Contenuto: View>: View {
    let margini: EdgeInsets
    let contenuto: Contenuto

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            if w <= h {
                let lungo = max(h - margini.top, 0)
                conMargini
                    .frame(width: lungo, height: w)
                    .rotationEffect(.degrees(IstantaneeMobile.rotazioneOrizzontale))
                    .frame(width: w, height: lungo)
                    .padding(.top, margini.top)
            } else {
                conMargini
                    .frame(width: w, height: h)
            }
        }
        // I margini veri del verticale non entrano: quelli dell'orizzontale li mette `conMargini`
        .ignoresSafeArea()
    }

    /// La safe area dell'orizzontale: dentro una vista che la ignora i margini valgono zero, si rimettono qui
    private var conMargini: some View {
        contenuto
            .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: margini.top) }
            .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: margini.bottom) }
    }
}
#endif
