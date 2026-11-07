import SwiftUI

/// I dati di prova delle istantanee di Mercato (Mac, iPhone e iPad), tutti relativi a oggi così le scene sono uguali
/// in ogni giorno. DATI DI PROVA DICHIARATI, solo dentro le scene (lo stato dell'istantanea non si salva): ogni serie
/// porta la fonte «Dati di prova» e l'occhiello dice «· valori di prova». Nessun valore viene da BCE o Eurostat.
/// - Le serie della configurazione con le cifre dimostrative del template (§12.1.4): Euro Stoxx 50 da 3.780 a 3.712
///   (−1,8%), rendimento italiano da 3,27% a 3,42% (+0,15), tedesco per lo spread, Euribor 3 mesi da 2,10% a 2,08%,
///   inflazione da 1,8% a 1,6%, tasso BCE fermo al 2,00% da 120 giorni.
/// - Il «Fondo di prova azionario globale» con un ISIN DI PROVA (ZZPRISMA0016: supera la cifra di controllo, il
///   prefisso ZZ non è di nessun paese): 17,36 € a fine anno, massimo 19,60 €, oggi 18,42 € (+6,1% da inizio anno,
///   −6% dal massimo), negli ETF di Giulia e Laura e nel portafoglio di fondi di Sofia.
/// - «BTP di prova 2031» di Sofia (ISIN di prova ZZPRISMA0024) con la cedola fra 12 giorni.
/// - Le soglie: calo dal massimo 5%, cedola 15 giorni, indici 1%, tassi 0,10 punti.
enum MercatoDiProva {
    /// La fonte di ogni serie di prova: l'occhiello la riconosce (`StatoShell.mercatoDiProva`).
    static let fonte = "Dati di prova"
    static let isinFondo = "ZZPRISMA0016"
    static let isinBTP = "ZZPRISMA0024"
    /// Valido ma senza quote né posizioni (543).
    static let isinSconosciuto = "ZZPRISMA0032"
    /// Non supera la cifra di controllo (543, come il template con il campo vuoto).
    static let isinSbagliato = "LU0000000000"
    static let posizioniFondo: [(id: String, quote: Double)] = [("pos-giulia-etf-azionario-globale", 1_976),
                                                                 ("pos-laura-etf-azionario-globale", 1_466),
                                                                 ("pos-sofia-portafoglio-di-fondi", 1_737)]
    static let btpSofia = "pos-sofia-btp-di-prova-2031"

    /// Prepara Mercato con i dati di prova. `vecchi`: l'ultimo aggiornamento di cinque giorni fa e i dati mensili di
    /// tre mesi fa, una serie configurata ancora senza valori (545).
    static func prepara(_ s: StatoShell, vecchi: Bool = false, cal: Calendar = .current) {
        let oggi = Date()
        let inizio = cal.startOfDay(for: oggi)
        let ore18 = cal.date(bySettingHour: 18, minute: 0, second: 0, of: inizio) ?? inizio
        let aggiornato = vecchi ? (cal.date(byAdding: .day, value: -5, to: ore18) ?? ore18) : ore18
        let spostamento = vecchi ? -3 : 0
        func mese(_ indietro: Int) -> Date {
            let primo = cal.date(from: cal.dateComponents([.year, .month], from: inizio)) ?? inizio
            let d = cal.date(byAdding: .month, value: -indietro + spostamento, to: primo) ?? primo
            return cal.date(bySettingHour: 12, minute: 0, second: 0, of: d) ?? d
        }
        func giorni(_ n: Int) -> Date {
            let d = cal.date(byAdding: .day, value: n, to: inizio) ?? inizio
            return cal.date(bySettingHour: 12, minute: 0, second: 0, of: d) ?? d
        }
        func mensile(_ id: String, _ nome: String, _ unita: UnitaMercato, _ tipo: TipoSerieMercato, _ valori: [Double]) -> SerieMercato {
            let punti = valori.enumerated().map { PuntoMercato(data: mese(valori.count - $0.offset), valore: $0.element) }
            return SerieMercato(id: id, nome: nome, origine: .aMano, fonte: fonte, unita: unita, tipo: tipo, frequenza: .mensile,
                                punti: punti, aggiornataIl: aggiornato)
        }
        let stoxx = mensile("euro-stoxx-50", "Euro Stoxx 50", .punti, .indiceAzionario,
                            [3_500, 3_560, 3_610, 3_580, 3_690, 3_760, 3_790, 3_780, 3_712])
        let italia = mensile("rendimento-it-lungo", "Rendimento dei titoli di Stato italiani a lungo termine", .percentuale, .rendimentoStato,
                             [3.1, 3.2, 3.15, 3.3, 3.25, 3.2, 3.3, 3.27, 3.42])
        let germania = mensile("rendimento-de-lungo", "Rendimento dei titoli di Stato tedeschi a lungo termine", .percentuale, .rendimentoStato,
                               [2.5, 2.55, 2.5, 2.6, 2.6, 2.58, 2.62, 2.6, 2.68])
        let euribor = mensile("euribor-3m", "Euribor 3 mesi", .percentuale, .tassoInterbancario,
                              [2.4, 2.35, 2.3, 2.25, 2.2, 2.18, 2.12, 2.1, 2.08])
        let inflazione = mensile("inflazione-it", "Inflazione IPCA Italia", .percentuale, .inflazione,
                                 [2.1, 2, 1.9, 1.9, 1.8, 1.8, 1.7, 1.8, 1.6])
        let bce = SerieMercato(id: "bce-depositi", nome: "Tasso BCE sui depositi", origine: .aMano, fonte: fonte, unita: .percentuale,
                               tipo: .tassoUfficiale, frequenza: .giornaliera,
                               punti: [PuntoMercato(data: giorni(-300), valore: 2.5), PuntoMercato(data: giorni(-200), valore: 2.25),
                                       PuntoMercato(data: giorni(-120), valore: 2)],
                               aggiornataIl: vecchi ? (cal.date(byAdding: .day, value: -20, to: ore18) ?? ore18) : aggiornato)
        var m = ArchivioMercato()
        m.serie = [stoxx, italia, germania, inflazione, bce] + (vecchi ? [] : [euribor])
        if let spread = MotoreMercato.differenza(italia, germania, id: "spread-it-de", nome: "Spread Italia–Germania", unita: .percentuale,
                                                 tipo: .spread, il: aggiornato, cal: cal) {
            m.serie.append(spread)
        }
        // Il fondo di prova: fine anno, poi su fino al massimo e giù fino a oggi
        let anno = cal.component(.year, from: oggi)
        let fineAnno = cal.date(from: DateComponents(year: anno - 1, month: 12, day: 31, hour: 12)) ?? inizio
        let quote = [PuntoMercato(data: fineAnno, valore: 17.36), PuntoMercato(data: giorni(-150), valore: 18.1),
                     PuntoMercato(data: giorni(-110), valore: 18.9), PuntoMercato(data: giorni(-70), valore: 19.6),
                     PuntoMercato(data: giorni(-40), valore: 19.0), PuntoMercato(data: giorni(-3), valore: 18.42)]
        m.quote = [QuotaISIN(isin: isinFondo, nome: "Fondo di prova azionario globale",
                             punti: quote.filter { $0.data <= oggi }.sorted { $0.data < $1.data }, fonte: fonte, origine: .aMano,
                             importataIl: aggiornato)]
        m.ultimoAggiornamento = aggiornato
        // Le posizioni con l'ISIN di prova e il BTP di prova di Sofia
        for (id, n) in posizioniFondo {
            if let i = s.dati.posizioni.firstIndex(where: { $0.id == id }) {
                s.dati.posizioni[i].isin = isinFondo
                s.dati.posizioni[i].numeroQuote = n
            }
        }
        if s.dati.clienti.contains(where: { $0.id == "sofia" }), !s.dati.posizioni.contains(where: { $0.id == btpSofia }) {
            var btp = Posizione(clienteId: "sofia", canale: .indipendente, stato: .inEssere, area: .investimento, nome: "BTP di prova 2031")
            btp.id = btpSofia
            btp.controvalore = 20_000
            btp.quotaAzionaria = 0
            btp.quotaTitoliStato = 100
            btp.isin = isinBTP
            btp.cedola = CedolaTitolo(tassoAnnuo: 3.5, volteAllAnno: 2, prossima: giorni(12))
            s.dati.posizioni.append(btp)
        }
        var i = ImpostazioniMercato()
        i.attivo = true
        i.caloDalMassimo = 5
        i.giorniCedola = 15
        i.variazioneIndici = 1
        i.variazioneTassi = 0.1
        s.dati.impostazioni.mercato = i
        let eventi = MotoreMercato.toccati(archivio: m, impostazioni: i, posizioni: s.dati.posizioni, clienti: s.dati.clienti,
                                           obiettivi: s.dati.obiettivi, oggi: oggi, cal: cal)
        m.avvisi = MotoreMercato.avvisi(eventi: eventi, esistenti: [], oggi: oggi, cal: cal)
        s.dati.mercato = m
    }

    /// Prepara e apre Mercato.
    static func apri(_ s: StatoShell, vecchi: Bool = false) {
        prepara(s, vecchi: vecchi)
        s.apri(.mercato)
    }

    /// Mai aggiornato: nessuna serie, nessuna quota, «Dati di mercato» spento (lo stato vero appena installato).
    static func vuoto(_ s: StatoShell) {
        s.dati.mercato = ArchivioMercato()
        s.dati.impostazioni.mercato = ImpostazioniMercato()
        s.apri(.mercato)
    }

    /// La ricerca di un ISIN, come se il consulente l'avesse scritto e premuto Invio.
    static func cerca(_ s: StatoShell, _ isin: String) {
        prepara(s)
        s.sessioneMercato.testoISIN = isin
        s.cercaISINMercato()
        s.apri(.mercato)
    }

    /// Il primo avviso del calo dal massimo visto: l'interruttore spento e il pallino grigio (546).
    static func avvisoSpento(_ s: StatoShell) {
        prepara(s)
        if let a = s.dati.mercato.avvisi.first(where: { $0.tipo == .caloDalMassimo }) {
            MotoreMercato.segnaVisto(a.id, in: &s.dati.mercato.avvisi, il: Date())
        }
        s.apri(.mercato)
    }
}

#if os(macOS)
/// Le istantanee di Mercato (Design/template-novita-specifica.md §12.7), 540-549 in chiaro e in scuro, tutte nello
/// stato finale (`\.modoIstantanea`): linee tracciate, numeri completi, pallino rosso senza alone. iPhone e iPad (540)
/// sono in iOS/IstantaneeMobile.swift. Dati di prova in `MercatoDiProva`.
/// - 540: la finestra con i dati di prova: striscia, «Chi è toccato oggi» con gli avatar sovrapposti, gli avvisi;
/// - 541: mai aggiornato, «Dati di mercato» spento: l'invito a importare un file o a scrivere a mano;
/// - 542: la ricerca di un ISIN trovato (quota, da inizio anno, nei portafogli di 3 clienti);
/// - 543: un ISIN valido senza quote e, a parte, un codice che non supera la cifra di controllo;
/// - 544: il foglio delle soglie degli avvisi (al posto del «＋ Nuovo avviso» del template);
/// - 545: dati vecchi (ultimo aggiornamento di cinque giorni fa, dati mensili di tre mesi fa, una serie senza valori);
/// - 546: un avviso visto, con l'interruttore spento e il pallino grigio;
/// - 547: il dettaglio della tessera Euro Stoxx 50 con la serie dei 12 mesi e la fonte;
/// - 548: Impostazioni › Mercato con l'interruttore, le serie e le soglie;
/// - 549: il centro notifiche con gli avvisi di Mercato.
extension Istantanee {
    nonisolated static var sceneMercato: [(nome: String, prepara: (StatoShell) -> Void)] {
        var elenco: [(nome: String, prepara: (StatoShell) -> Void)] = []
        let scene: [(String, (StatoShell) -> Void)] = [
            ("540-mercato", { s in MercatoDiProva.apri(s) }),
            ("541-mercato-vuoto", { s in MercatoDiProva.vuoto(s) }),
            ("542-mercato-isin", { s in MercatoDiProva.cerca(s, MercatoDiProva.isinFondo) }),
            ("543-mercato-isin-sconosciuto", { s in MercatoDiProva.cerca(s, MercatoDiProva.isinSconosciuto) }),
            ("543-mercato-isin-non-valido", { s in MercatoDiProva.cerca(s, MercatoDiProva.isinSbagliato) }),
            ("544-mercato-soglie", { s in
                MercatoDiProva.prepara(s)
                s.sessioneMercato.foglio = .soglie
                s.apri(.mercato)
            }),
            ("545-mercato-dati-vecchi", { s in MercatoDiProva.apri(s, vecchi: true) }),
            ("546-mercato-avviso-spento", { s in MercatoDiProva.avvisoSpento(s) }),
            ("547-mercato-tessera-dettaglio", { s in
                MercatoDiProva.prepara(s)
                s.sessioneMercato.dettaglioIstantanea = "euro-stoxx-50"
                s.apri(.mercato)
            }),
            ("548-impostazioni-mercato", { s in
                MercatoDiProva.prepara(s)
                s.schedaImpostazioni = .mercato
                s.apri(.impostazioni)
            }),
            ("549-notifica-avviso-mercato", { s in
                MercatoDiProva.prepara(s)
                s.alternaNotifiche()
            }),
        ]
        for (nome, prepara) in scene {
            elenco.append((nome: nome, prepara: prepara))
            elenco.append((nome: nome + "-scuro", prepara: prepara))
        }
        return elenco
    }
}
#endif
