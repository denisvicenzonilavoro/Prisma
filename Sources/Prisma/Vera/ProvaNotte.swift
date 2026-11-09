import Foundation

/// Prove di «Stanotte Prisma ha lavorato» («Luce» giro 14, Design/template-luce-specifica.md §6.1), dentro
/// `Prisma --prova-vera`, solo con dati di prova dichiarati (`NotteDiProva`, id «notte-prova-»): la voce di Novità apre
/// le otto carte; in modalità cliente niente carte né pallino; per ogni tipo «Approva» fa il suo effetto senza mandare nulla
/// (bozze mai aperte) e «Annulla» rimette tutto com'era; «Più tardi» manda la carta in fondo; il fascicolo approvato non
/// cambia il cliente attivo; la fase 1 sui dati di prova fa fascicolo e borsa con id stabili; il blocco chiude le carte e
/// lascia le decisioni; le carte restano fuori da «Prisma ovunque»; lo stop per memoria ferma le bozze.
/// Chiamata da `ProvaVera.esegui()` (sul thread principale, tutto sincrono). Solo sul Mac.
enum ProvaNotte {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        #if os(macOS)
        novitaEModoCliente(controlla)
        approvaEAnnulla(controlla)
        rimandaEFascicolo(controlla)
        faseUno(controlla)
        bloccoOvunqueMemoria(controlla)
        #endif
    }

    #if os(macOS)
    /// Uno stato con la notte di prova di oggi.
    private static func statoConNotte(_ notte: ((DatiPrisma) -> NotteDiLavoro)? = nil) -> StatoShell {
        let s = StatoShell(persistente: false)
        let d = s.dati.istantanea
        s.dati.notti = [notte?(d) ?? NotteDiProva.notte(d, oggi: Date(), cal: Calendar.current)]
        return s
    }

    // MARK: - 1. Novità e modalità cliente

    private static func novitaEModoCliente(_ controlla: (Bool, String) -> Void) {
        let s = statoConNotte()
        s.apriVoceNovita(.stanotte)
        controlla(NovitaLuce.stanotte.disponibile && s.sovrapposizione == .notte && s.notte.pila.count == 8,
                  "Notte: la voce di Novità apre le otto carte di prova")
        controlla(s.carteDaDecidere == 8 && s.carteRimanentiNotte.count == 8, "Notte: il pallino conta otto carte da decidere")
        s.chiudiSovrapposizione(animato: false)

        let m = statoConNotte()
        m.clienteAttivoId = "giulia"
        m.entraModoCliente(avviso: false)
        m.apriNotte()
        controlla(m.sovrapposizione == nil && m.avviso == TestiNotte.avvisoModoCliente && m.carteDaDecidere == 0,
                  "Notte: in modalità cliente le carte non si aprono, lo dice, e il pallino non c'è")
        m.proponiNotteDopoSblocco()
        controlla(m.sovrapposizione == nil, "Notte: in modalità cliente le carte non si aprono da sole")
    }

    // MARK: - 2. Approva e Annulla, per tipo

    private static func approvaEAnnulla(_ controlla: (Bool, String) -> Void) {
        let s = statoConNotte()
        s.caricaEsempiModuli()
        s.apriNotte()
        guard let notte = s.notteDiOggi, notte.carte.count == 8 else { return controlla(false, "Notte: la notte di prova non ha otto carte") }
        for c in notte.carte {
            var prima = s.dati.istantanea
            s.approvaCartaNotte(c.id)
            let dopo = s.dati.istantanea
            let carta = s.cartaNotte(c.id)
            let nome = TestiNotte.occhiello(c.tipo).lowercased()
            controlla(carta?.stato == .approvata || carta?.stato == .scaduta, "Notte, \(nome): «Approva» decide la carta")
            controlla(!dopo.messaggi.contains { $0.stato == .apertoInMail || $0.stato == .apertoInMessaggi },
                      "Notte, \(nome): «Approva» non apre né manda nessun messaggio")
            switch c.tipo {
            case .messaggio:
                controlla(dopo.messaggi.contains { m in c.bozze.contains { $0.id == m.id } && m.stato == .bozza && m.apertoIl == nil },
                          "Notte, messaggio: la bozza entra in Messaggi come bozza, mai aperta")
            case .documento:
                controlla(dopo.messaggi.contains { m in c.bozze.contains { $0.id == m.id } && m.stato == .bozza }
                            && dopo.attivita.contains { $0.id == "notte-\(c.id)" && !$0.completata },
                          "Notte, documento: la bozza della richiesta e l'attività «Chiedere il documento nuovo»")
            case .domani:
                controlla(c.appuntamenti.isEmpty || dopo.appuntamenti.contains { c.appuntamenti.contains($0.id) && $0.note.contains(TestiNotte.notaBorsa) },
                          "Notte, borsa: «Da portare:» nella nota degli appuntamenti del giorno")
            case .campagna:
                if carta?.stato == .approvata {
                    controlla(dopo.campagne.count == prima.campagne.count + 1 && carta?.creati.count == 1,
                              "Notte, campagna: la campagna nasce con le sue bozze")
                }
            case .fascicolo:
                if let a = dopo.appuntamenti.first(where: { $0.id == c.riferimento }) {
                    let titolo = "Report · " + StatoShell.titoloFascicolo(a.inizio)
                    controlla(dopo.documenti.contains { $0.clienteId == a.clienteId && $0.titolo == titolo },
                              "Notte, fascicolo: il report nei Documenti con il titolo del fascicolo dell'incontro")
                }
            case .moduli:
                controlla(carta?.creati.isEmpty == false && dopo.documenti.contains { d in carta?.creati.contains(d.id) == true && d.tipo == .modulo },
                          "Notte, moduli: i fac-simile compilati nei Documenti di Sofia")
            case .riesame:
                controlla(carta?.creati.count == 1, "Notte, riesame: il prospetto del riesame nei Documenti")
            case .ricalcolo, .daFinire:
                controlla(dopo.messaggi == prima.messaggi && dopo.documenti == prima.documenti, "Notte, \(nome): nessun effetto oltre la decisione")
            }
            s.annullaCartaNotte(c.id)
            var tornati = s.dati.istantanea
            tornati.notti = []
            prima.notti = []
            controlla(tornati == prima, "Notte, \(nome): «Annulla» rimette tutto com'era")
            controlla(s.cartaNotte(c.id)?.stato == .daDecidere && s.carteRimanentiNotte.first?.id == c.id && s.notte.registro.isEmpty,
                      "Notte, \(nome): annullata, la carta torna in cima alla pila")
        }
    }

    // MARK: - 3. Più tardi e il fascicolo che non cambia il cliente attivo

    private static func rimandaEFascicolo(_ controlla: (Bool, String) -> Void) {
        let s = statoConNotte()
        s.apriNotte()
        guard let prima = s.carteRimanentiNotte.first else { return controlla(false, "Notte: nessuna carta da rimandare") }
        s.rimandaCartaNotte(prima.id)
        controlla(s.cartaNotte(prima.id)?.stato == .rimandata && s.notte.registro.first?.testo == TestiNotte.rigaRimandata(prima.titolo),
                  "Notte: «Più tardi» lascia la carta e scrive «· più tardi» nel registro")
        s.fissaPilaNotte()
        controlla(s.notte.pila.last == prima.id, "Notte: riaprendo, la carta rimandata è in fondo alla pila")

        let f = statoConNotte()
        f.clienteAttivoId = "marco"
        f.sceltaFascicolo = [.costi]
        f.fascicoloAppuntamento = nil
        f.apriNotte()
        if let c = f.notteDiOggi?.carte.first(where: { $0.tipo == .fascicolo }) {
            f.approvaCartaNotte(c.id)
            controlla(f.clienteAttivoId == "marco" && f.sceltaFascicolo == [.costi] && f.fascicoloAppuntamento == nil,
                      "Notte: approvare il fascicolo lascia cliente attivo, scelta e appuntamento come prima")
        } else {
            controlla(false, "Notte: la notte di prova ha il fascicolo")
        }
    }

    // MARK: - 4. La fase 1 sui dati di prova

    private static func faseUno(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        let cal = Calendar.current
        // Alle 23:07 si serve domani: un incontro di prova con Giulia domani alle 10:07
        let adesso = cal.date(bySettingHour: 23, minute: 7, second: 0, of: Date()) ?? Date()
        let domani = MotoreNotte.giornoServito(adesso, inizio: s.dati.impostazioni.notte.inizio, cal: cal)
        let ora = cal.date(bySettingHour: 10, minute: 7, second: 0, of: domani) ?? domani
        s.dati.appuntamenti.append(Appuntamento(id: NotteDiProva.prefisso + "incontro", clienteId: "giulia", titolo: "Incontro di prova",
                                                inizio: ora, durataMinuti: 45, luogo: "", note: "", stato: .pianificato, tipo: .analisi))
        let carte = s.preparaNotteSenzaQwen(adesso: adesso)
        controlla(carte.contains { $0.tipo == .fascicolo && $0.riferimento == NotteDiProva.prefisso + "incontro" }
                    && carte.contains { $0.tipo == .domani },
                  "Notte: la fase 1 prepara il fascicolo e la borsa per l'incontro di domani")
        controlla(!carte.contains { $0.tipo.conQwen }, "Notte: la fase 1 non scrive bozze di Vera")
        let ids = s.dati.notti.flatMap { $0.carte.map(\.id) }
        let ancora = s.preparaNotteSenzaQwen(adesso: adesso)
        controlla(ancora.isEmpty && s.dati.notti.flatMap { $0.carte.map(\.id) } == ids, "Notte: rifare il lavoro non duplica le carte (id stabili)")
    }

    // MARK: - 5. Blocco, Prisma ovunque, memoria

    private static func bloccoOvunqueMemoria(_ controlla: (Bool, String) -> Void) {
        let s = statoConNotte()
        s.apriNotte()
        if let c = s.carteRimanentiNotte.first(where: { $0.tipo == .ricalcolo }) { s.approvaCartaNotte(c.id) }
        s.blocca(animato: false)
        controlla(s.sovrapposizione == nil && s.notteDiOggi?.carte.contains { $0.tipo == .ricalcolo && $0.stato == .approvata } == true,
                  "Notte: il blocco chiude le carte e le decisioni restano")

        var d = DatiPrisma.demo()
        d.notti = [NotteDiProva.notte(d, oggi: Date(), cal: Calendar.current)]
        d.impostazioni.notte.attivo = true
        let ist = SpazioOvunque.datiIstantanea(d)
        controlla(ist.notti.isEmpty && ist.impostazioni.notte == ImpostazioniNotte(), "Notte: le carte e le impostazioni restano fuori da Prisma ovunque")

        let m = StatoShell(persistente: false)
        let e = EsecutoreBozzeNotte()
        // Una notte che sta lavorando (giorno di oggi), con l'esecutore delle bozze attivo (Revisione R11)
        let giorno = Calendar.current.startOfDay(for: Date())
        var inLavoro = NotteDiLavoro(giorno: giorno, inizio: Date())
        inLavoro.esito = .inCorso
        m.dati.notti = [inLavoro]
        m.notte.inCorso = true
        m.notte.lavoro.esecutore = e
        m.fermaLavoroNotte(.memoria)
        controlla(e.motivo == .memoria && m.notte.lavoro.fermatoPer == .memoria, "Notte: l'avviso di memoria ferma le bozze di Vera")
        let c = MotoreNotte.carta(PreparativoNotte(tipo: .daFinire, clienteId: nil, riferimento: "bozze", dettagli: .daFinire(bozze: 3, motivo: .memoria)),
                                  giorno: Date(), adesso: Date(), nomi: [:])
        controlla(c.titolo == TestiNotte.daFinireMemoria(3) && c.daFinire == 3, "Notte: dopo l'avviso di memoria resta una carta «Da finire»")
        // Le bozze rimaste diventano una sola carta «Da finire» (anche se arrivano due volte) e la notte è «interrotta»
        m.aggiungiDaFinire(3, motivo: .memoria, giorno: giorno)
        m.aggiungiDaFinire(3, motivo: .memoria, giorno: giorno)
        m.finisciNotte(giorno: giorno)
        let finita = m.dati.notti.first { $0.giornoChiave == NotteDiLavoro.chiave(giorno) }
        controlla(finita?.esito == .interrotta && finita?.motivoStop == .memoria && finita?.fine != nil,
                  "Notte: dopo l'avviso di memoria la notte è «interrotta» con il motivo")
        controlla(finita?.carte.filter { $0.tipo == .daFinire }.count == 1 && finita?.carte.first { $0.tipo == .daFinire }?.daFinire == 3,
                  "Notte: dopo l'avviso di memoria resta una sola carta «Da finire» con le bozze mancanti")
        controlla(!m.notte.inCorso && m.notte.lavoro.esecutore == nil && m.notte.lavoro.fermatoPer == .memoria,
                  "Notte: alla fine il lavoro è chiuso")
        m.notte.lavoro.chiudi()
    }
    #endif
}
