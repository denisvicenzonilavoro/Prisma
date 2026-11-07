import SwiftUI

/// Impostazioni: le pagine Agenda e lavoro, Promemoria e occasioni, Conformità, PDF (in Proposte e PDF), Ruby e
/// la voce di Ruby (in Strumenti, chiusa). Sottotitoli di poche parole; il testo lungo in `aiuto` (.help).
extension AppImpostazioni {

    // MARK: Agenda e lavoro

    /// Gli orari di lavoro (dove «Pianifica» di Agenda, Portafoglio e Prospetti cerca lo spazio libero), le
    /// festività e il seguito delle proposte.
    var lavoro: some View {
        let orari = stato.dati.impostazioni.orari
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            GruppoImpostazioni(titolo: "Orari di lavoro") {
                RigaImpostazione(titolo: "Giorni di lavoro", sottotitolo: "«Pianifica» cerca solo qui") {
                    SceltaGiorniLavoro(giorni: $stato.dati.impostazioni.orari.giorni)
                }
                RigaImpostazione(titolo: "Mattina", sottotitolo: "Anche orario continuato") {
                    sceltaFascia($stato.dati.impostazioni.orari.mattina)
                }
                RigaImpostazione(titolo: "Pomeriggio",
                                 sottotitolo: orari.pomeriggioAttivo ? "Dopo la pausa pranzo" : "Spento: solo il mattino") {
                    interruttore($stato.dati.impostazioni.orari.pomeriggioAttivo)
                }
                // La fascia sotto il suo interruttore: una cosa per riga
                if orari.pomeriggioAttivo {
                    RigaImpostazione(titolo: "Fascia del pomeriggio") {
                        sceltaFascia($stato.dati.impostazioni.orari.pomeriggio)
                    }
                }
                RigaImpostazione(titolo: "Margine tra gli appuntamenti", sottotitolo: "Prima e dopo ogni appuntamento") {
                    segmenti(AppImpostazioni.opzioniMargini, $stato.dati.impostazioni.orari.margineMinuti)
                }
                RigaImpostazione(titolo: "Riesami al giorno", sottotitolo: "Oltre, il riesame va al giorno dopo",
                                 aiuto: "Ognuno chiede la sua preparazione", ultima: true) {
                    segmenti(AppImpostazioni.opzioniRiesami, $stato.dati.impostazioni.orari.riesamiAlGiorno)
                }
            }
            GruppoImpostazioni(titolo: "Calendario") {
                RigaImpostazione(titolo: "Festività", sottotitolo: "Nazionali italiane",
                                 aiuto: "Capodanno, Epifania, Pasqua e Pasquetta, 25 aprile, 1° maggio, 2 giugno, Ferragosto, 4 ottobre, Ognissanti, Immacolata, Natale e Santo Stefano",
                                 ultima: true) {
                    interruttore($stato.dati.impostazioni.orari.festivi)
                }
            }
            GruppoImpostazioni(titolo: "Seguito delle proposte") {
                RigaImpostazione(titolo: "Recupera dopo", sottotitolo: "Proposte senza risposta né appuntamento",
                                 aiuto: "Dopo quanti giorni una proposta presentata, senza appuntamento in agenda, torna tra le cose da recuperare (notifiche, scrivania, Portafoglio). Non è una regola di legge: è il tuo ritmo",
                                 ultima: true) {
                    MenuTendina(selezione: $stato.dati.impostazioni.giorniSeguitoProposte,
                                opzioni: AppImpostazioni.opzioniGiorniSeguito)
                }
            }
            NotaImpostazioni("Il seguito non è una regola di legge: è il tuo ritmo.")
        }
    }

    /// Inizio e fine di una fascia oraria (ogni mezz'ora dalle 7:00 alle 21:00). Se l'inizio va oltre la fine,
    /// la fine diventa inizio + 60 minuti, tagliata alle 21:00; la fine propone solo le ore dopo l'inizio.
    func sceltaFascia(_ fascia: Binding<FasciaOraria>) -> some View {
        let ore = OrariLavoro.orariScelta
        let ultima = ore.last ?? 21 * 60
        let inizio = Binding<Int>(
            get: { fascia.wrappedValue.inizio },
            set: { nuovo in
                var f = fascia.wrappedValue
                f.inizio = nuovo
                if f.fine <= nuovo { f.fine = min(nuovo + 60, ultima) }
                fascia.wrappedValue = f
            }
        )
        // L'ultima ora resta solo come fine: una fascia ha sempre almeno mezz'ora
        let inizi = AppImpostazioni.opzioniOre(Array(ore.dropLast()), con: fascia.wrappedValue.inizio)
        let fini = AppImpostazioni.opzioniOre(ore.filter { $0 > fascia.wrappedValue.inizio }, con: fascia.wrappedValue.fine)
        return HStack(spacing: Misure.RiesamiAgenda.spazioOre) {
            MenuTendina(selezione: inizio, opzioni: inizi, larghezza: Misure.RiesamiAgenda.menuOra)
            Text("–")
                .font(Tema.Testo.corpo)
                .foregroundColor(Tema.Colore.inchiostroSecondario)
            MenuTendina(selezione: fascia.fine, opzioni: fini, larghezza: Misure.RiesamiAgenda.menuOra)
        }
    }

    /// Le scelte del margine tra gli appuntamenti: «Nessuno», «10 min»…
    static var opzioniMargini: [(Int, String)] {
        OrariLavoro.margini.map { m -> (Int, String) in
            let testo: String = m == 0 ? "Nessuno" : "\(m) min"
            return (m, testo)
        }
    }

    /// Le scelte dei riesami al giorno: «1», «2», «3», «Senza limite».
    static var opzioniRiesami: [(Int, String)] {
        OrariLavoro.limitiRiesami.map { n -> (Int, String) in
            let testo: String = n == 0 ? "Senza limite" : String(n)
            return (n, testo)
        }
    }

    /// Le scelte dei giorni del seguito: «14 giorni», «21 giorni»…
    static var opzioniGiorniSeguito: [(Int, String)] {
        Impostazioni.sceltaGiorniSeguito.map { g -> (Int, String) in (g, "\(g) giorni") }
    }

    /// Le ore del menu, con quella salvata anche se non è tra le scelte (un archivio scritto a mano): il menu
    /// mostra sempre il valore vero.
    static func opzioniOre(_ ore: [Int], con attuale: Int) -> [(Int, String)] {
        let tutte = ore.contains(attuale) ? ore : (ore + [attuale]).sorted()
        return tutte.map { o -> (Int, String) in (o, OrariLavoro.testoOra(o)) }
    }

    // MARK: Promemoria e occasioni

    var promemoriaEOccasioni: some View {
        VStack(alignment: .leading, spacing: M.spazioGruppi) {
            gruppoPromemoria
            GruppoOccasioniImpostazioni()
                .id("impostazioni-occasioni")
        }
    }

    /// Promemoria nel Centro notifiche del Mac: spenti di partenza, il permesso di macOS si chiede
    /// solo accendendoli. Nei testi niente cifre: il nome del cliente (se scelto) e cosa fare.
    /// La prova sta in Strumenti.
    private var gruppoPromemoria: some View {
        let scelte = stato.dati.impostazioni.promemoria
        let negati = stato.permessoPromemoria == .negati
        let ora = "alle \(MotoreNotifiche.oraPromemoria):00"
        let pillola: Pillola = negati ? Pillola(testo: "Non consentiti", tono: .errore)
            : scelte.attivi ? Pillola(testo: "Attivi", tono: .ok) : Pillola(testo: "Spenti", tono: .neutro)
        return GruppoImpostazioni(titolo: "Promemoria del Mac") {
            RigaImpostazione(titolo: "Promemoria nel Centro notifiche", sottotitolo: "Anche a Prisma chiusa",
                             stato: pillola,
                             aiuto: "Appuntamenti, attività, scadenze delle polizze, occasioni e compleanni, anche a Prisma chiusa. Nei testi niente cifre dei clienti",
                             avvertenza: negati ? "Non consentiti da macOS: Impostazioni di Sistema › Notifiche › Prisma" : nil) {
                HStack(spacing: 8) {
                    if negati {
                        Button { PromemoriaMac.apriImpostazioniDiSistema() } label: { Label("Apri Impostazioni di Sistema", systemImage: "gearshape") }
                            .buttonStyle(StilePulsanteRigaImpostazioni())
                    }
                    interruttore(Binding(get: { stato.dati.impostazioni.promemoria.attivi },
                                         set: { stato.attivaPromemoria($0) }))
                }
            }
            Group {
                RigaImpostazione(titolo: "Appuntamenti", sottotitolo: "Prima dell'inizio, con il luogo") {
                    HStack(spacing: 8) {
                        MenuTendina(selezione: $stato.dati.impostazioni.promemoria.anticipoMinuti,
                                    opzioni: ImpostazioniPromemoria.anticipi.map { ($0, ImpostazioniPromemoria.nomeAnticipo($0) + " prima") },
                                    larghezza: M.menuStretto)
                        interruttore($stato.dati.impostazioni.promemoria.appuntamenti)
                    }
                }
                RigaImpostazione(titolo: "Attività", sottotitolo: "Il giorno di scadenza, \(ora)") {
                    interruttore($stato.dati.impostazioni.promemoria.attivita)
                }
                RigaImpostazione(titolo: "Scadenze delle polizze", sottotitolo: "30 e 7 giorni prima e il giorno stesso",
                                 aiuto: "Posizioni in essere: 30 e 7 giorni prima e il giorno stesso, \(ora)") {
                    interruttore($stato.dati.impostazioni.promemoria.scadenze)
                }
                RigaImpostazione(titolo: "Compleanni dei clienti", sottotitolo: "Il giorno stesso, \(ora)") {
                    interruttore($stato.dati.impostazioni.promemoria.compleanni)
                }
                RigaImpostazione(titolo: "Occasioni",
                                 sottotitolo: "\(stato.dati.impostazioni.occasioni.anticipoGiorni) giorni prima e il giorno stesso",
                                 aiuto: "\(ora): penali finite, previdenza, famiglia, coperture. L'anticipo si sceglie qui sotto, in Occasioni") {
                    interruttore($stato.dati.impostazioni.promemoria.occasioni)
                }
                RigaImpostazione(titolo: "Nomi dei clienti", sottotitolo: "Spento: solo l'ora e cosa fare",
                                 aiuto: "In modalità cliente i banner non compaiono", ultima: true) {
                    interruttore($stato.dati.impostazioni.promemoria.nomiClienti)
                }
            }
            .disabled(!scelte.attivi)
            .opacity(scelte.attivi ? 1 : Tema.Misura.Shell.opacitaDisabilitato)
            // Con i promemoria spenti anche gli interruttori accesi diventano grigi: non sembrano più attivi
            .saturation(scelte.attivi ? 1 : Tema.Misura.RifinitureScrivania.saturazioneSpento)
        }
    }

    // MARK: Conformità

    /// Le scadenze di conformità («In regola»): validità dei questionari di adeguatezza per canale, rinnovo
    /// dell'adeguata verifica per rischio, consenso commerciale, data dell'ultima informativa privacy.
    /// Sono valori di buona prassi: il consulente li allinea alle regole della compagnia e alle sue.
    var conformita: some View {
        let regole = stato.dati.impostazioni.conformita
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            GruppoImpostazioni(titolo: "Questionari di adeguatezza") {
                RigaImpostazione(titolo: "Validità", sottotitolo: "Poi il profilo va aggiornato") {
                    HStack(spacing: M.spazioGriglia) {
                        EtichettaCanale(canale: .alleanza, compatta: true)
                        MenuTendina(selezione: $stato.dati.impostazioni.conformita.mesiQuestionarioAlleanza,
                                    opzioni: AppImpostazioni.opzioniMesi(AppImpostazioni.mesiQuestionario, con: regole.mesiQuestionarioAlleanza),
                                    larghezza: M.menuGriglia)
                    }
                }
                RigaImpostazione(titolo: "Validità", sottotitolo: "Ogni quanto si aggiorna il profilo", ultima: true) {
                    HStack(spacing: M.spazioGriglia) {
                        EtichettaCanale(canale: .indipendente, compatta: true)
                        MenuTendina(selezione: $stato.dati.impostazioni.conformita.mesiQuestionarioIndipendente,
                                    opzioni: AppImpostazioni.opzioniMesi(AppImpostazioni.mesiQuestionario, con: regole.mesiQuestionarioIndipendente),
                                    larghezza: M.menuGriglia)
                    }
                }
            }
            .id("impostazioni-conformita")
            GruppoImpostazioni(titolo: "Adeguata verifica") {
                RigaImpostazione(titolo: "Rinnovo per rischio", sottotitolo: "Antiriciclaggio") {
                    HStack(alignment: .bottom, spacing: M.spazioGriglia) {
                        rischio(.alto, $stato.dati.impostazioni.conformita.mesiVerificaAlto,
                                AppImpostazioni.opzioniMesi(AppImpostazioni.mesiVerificaAlto, con: regole.mesiVerificaAlto))
                        rischio(.medio, $stato.dati.impostazioni.conformita.mesiVerificaMedio,
                                AppImpostazioni.opzioniMesi(AppImpostazioni.mesiVerificaMedio, con: regole.mesiVerificaMedio))
                        rischio(.basso, $stato.dati.impostazioni.conformita.mesiVerificaBasso,
                                AppImpostazioni.opzioniMesi(AppImpostazioni.mesiVerificaBasso, con: regole.mesiVerificaBasso))
                    }
                }
                RigaImpostazione(titolo: "Anche sul canale indipendente", sottotitolo: "Se sei tenuto all'antiriciclaggio",
                                 ultima: true) {
                    interruttore($stato.dati.impostazioni.conformita.verificaIndipendente)
                }
            }
            GruppoImpostazioni(titolo: "Consensi e privacy") {
                RigaImpostazione(titolo: "Consenso commerciale", sottotitolo: "Ogni quanto riconfermarlo") {
                    MenuTendina(selezione: $stato.dati.impostazioni.conformita.mesiCommerciale,
                                opzioni: AppImpostazioni.opzioniMesi(AppImpostazioni.mesiCommerciale, con: regole.mesiCommerciale),
                                larghezza: M.menuGriglia)
                }
                RigaImpostazione(titolo: "Informativa privacy aggiornata il", sottotitolo: "Chi l'ha firmata prima la riceve di nuovo",
                                 ultima: true) {
                    CampoDataFacoltativa(data: $stato.dati.impostazioni.conformita.informativaAggiornataIl,
                                         predefinita: Calendar.current.startOfDay(for: Date()))
                }
            }
            NotaImpostazioni("Valori di buona prassi: allineali alla compagnia e alle tue regole.")
                .help("Le scadenze compaiono in Clienti › «In regola», nelle notifiche, nel riesame e nella ricerca (conformita:scaduta).")
        }
    }

    /// Una colonna della griglia dell'adeguata verifica: «Alto», «Medio», «Basso» sopra il suo menu.
    private func rischio(_ r: RischioRiciclaggio, _ mesi: Binding<Int>, _ opzioni: [(Int, String)]) -> some View {
        VStack(alignment: .leading, spacing: M.spazioEtichettaGriglia) {
            Text(r.nome)
                .font(Tema.Testo.secondario)
                .foregroundColor(Tema.Colore.inchiostroSecondario)
            MenuTendina(selezione: mesi, opzioni: opzioni, larghezza: M.menuGriglia)
        }
    }

    /// Le validità proposte, in mesi (0 = «Non scade», solo per il consenso commerciale).
    static let mesiQuestionario = [12, 24, 36, 48, 60]
    static let mesiVerificaAlto = [6, 12, 18]
    static let mesiVerificaMedio = [12, 18, 24, 36]
    static let mesiVerificaBasso = [24, 36, 48, 60]
    static let mesiCommerciale = [0, 12, 24, 36]

    /// Le scelte di una validità («6 mesi», «1 anno», «Non scade»), con quella salvata anche se non è tra le
    /// scelte (un archivio scritto a mano): il menu mostra sempre il valore vero.
    static func opzioniMesi(_ scelte: [Int], con attuale: Int) -> [(Int, String)] {
        let tutte = scelte.contains(attuale) ? scelte : (scelte + [attuale]).sorted()
        return tutte.map { m -> (Int, String) in
            let testo: String = m == 0 ? "Non scade" : TestiConformita.durata(m)
            return (m, testo)
        }
    }

    // MARK: PDF

    var gruppoPDF: some View {
        GruppoImpostazioni(titolo: "PDF per i clienti") {
            RigaImpostazione(titolo: "Proponi la password", sottotitolo: "Protezione già attiva al salvataggio",
                             aiuto: "Salvando un prospetto o un report, la protezione è già attiva") {
                interruttore($stato.dati.impostazioni.pdf.proteggi)
            }
            RigaImpostazione(titolo: "Password proposta", sottotitolo: "Dai dati del cliente",
                             aiuto: "Prisma non conserva nessuna password", ultima: true) {
                MenuTendina(selezione: $stato.dati.impostazioni.pdf.regola,
                            opzioni: ImpostazioniPDF.Regola.allCases.map { ($0, $0.nome) }, larghezza: M.menuLargo)
            }
        }
    }

    // MARK: Ruby

    #if os(iOS)
    /// Su iPhone e iPad Ruby usa Qwen del Mac abbinato, in Wi‑Fi (PonteRuby): lo stato del collegamento e il codice.
    var paginaRuby: some View {
        let ponte = stato.dati.impostazioni.ruby.ponte
        let pronta = stato.disponibilitaLocale.pronto
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            GruppoImpostazioni {
                RigaImpostazione(titolo: "Qwen sul Mac",
                                 sottotitolo: pronta ? stato.qwen.descrizione : (stato.disponibilitaLocale.motivo ?? "Non collegata"),
                                 stato: Pillola(testo: pronta ? "Collegata" : "Non collegata", tono: pronta ? .ok : .attenzione),
                                 aiuto: "Ruby usa Qwen del tuo Mac: Prisma aperto sul Mac, «iPhone e iPad» attivo in Impostazioni › Ruby, stessa rete Wi‑Fi") {
                    Button { stato.verificaMotoreLocale() } label: { Label("Verifica", systemImage: "arrow.clockwise") }
                        .buttonStyle(StilePulsanteRigaImpostazioni())
                }
                RigaImpostazione(titolo: "Codice del Mac",
                                 sottotitolo: ponte.abbinato ? "Abbinato" : "Da Impostazioni › Ruby sul Mac",
                                 aiuto: ponte.abbinato ? "Lo trovi sul Mac in Impostazioni › Ruby (arriva anche con il backup)"
                                                       : "Scrivi il codice che compare sul Mac in Impostazioni › Ruby › iPhone e iPad") {
                    TextField("ABCD-EFGH-JKLM", text: $stato.dati.impostazioni.ruby.ponte.codice)
                        .campoTesto()
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .frame(width: M.menuMedio)
                        .onSubmit { stato.verificaMotoreLocale() }
                }
                RigaImpostazione(titolo: "Ragionamento", sottotitolo: "Sulle domande difficili",
                                 aiuto: "Automatico: Ruby ragiona sulle domande difficili o quando le dici «pensaci bene». Risponde più piano") {
                    MenuTendina(selezione: $stato.dati.impostazioni.ruby.ragionamento,
                                opzioni: SceltaRagionamento.allCases.map { ($0, $0.nome) }, larghezza: M.menuMedio)
                }
                RigaImpostazione(titolo: "Conserva le conversazioni", sottotitolo: "Nel dossier, su questo dispositivo", ultima: true) {
                    interruttore($stato.dati.impostazioni.ruby.conservaConversazioni)
                }
            }
            // Solo iPad: il tavolo con il Mac, con lo stesso codice (TavoloiPad.swift)
            GruppoTavoloiPad()
            NotaImpostazioni("Ruby spiega e racconta; le cifre le calcola Prisma. Mai internet.")
        }
    }
    #else
    /// Come nel template (§4.6, PIE i07): «Motore» con lo stato reale di Qwen sul Mac (Ollama o un server compatibile
    /// OpenAI, solo indirizzi locali), «iPhone e iPad» (il ponte cifrato) e la scorciatoia della mini Ruby; poi come
    /// lavora Ruby (modello, ragionamento, avvio, conversazioni) e, chiuse, fornitore e indirizzo in «Avanzate».
    var paginaRuby: some View {
        let ruby = stato.dati.impostazioni.ruby
        let pronta = stato.disponibilitaLocale.pronto
        let modello: String = ruby.modello.isEmpty ? MotoreLocale.modelloPredefinito : ruby.modello
        let motore: String = "\(stato.qwen.nome) · \(modello) con \(ruby.fornitore.nome), solo indirizzi locali."
        return VStack(alignment: .leading, spacing: M.spazioGruppi) {
            GruppoImpostazioni {
                RigaImpostazione(titolo: "Motore",
                                 sottotitolo: motore,
                                 stato: Pillola(testo: pronta ? "Pronto" : "Non pronto", tono: pronta ? .ok : .attenzione),
                                 aiuto: pronta ? nil : stato.disponibilitaLocale.motivo,
                                 avvertenza: pronta ? nil : "Serve l'app gratuita Ollama con \(MotoreLocale.modelloPredefinito) (circa 3,5 GB mentre risponde). Senza Qwen Ruby non risponde.") {
                    Button { stato.verificaMotoreLocale() } label: { Label("Verifica", systemImage: "arrow.clockwise") }
                        .buttonStyle(StilePulsanteRigaImpostazioni())
                        .fixedSize()
                }
                .cascataImpostazioni(1)
                RigaImpostazione(titolo: "iPhone e iPad", sottotitolo: "Usano Ruby del Mac attraverso la rete di casa, cifrata. Mai internet.",
                                 aiuto: "iPhone e iPad usano Qwen di questo Mac attraverso la rete di casa o dello studio, cifrato con un codice") {
                    interruttore(Binding(get: { ruby.ponte.condividi }, set: { attivo in
                        if attivo, !stato.dati.impostazioni.ruby.ponte.abbinato {
                            stato.dati.impostazioni.ruby.ponte.codice = PonteRuby.nuovoCodice()
                        }
                        stato.dati.impostazioni.ruby.ponte.condividi = attivo
                    }))
                }
                .cascataImpostazioni(2)
                if ruby.ponte.condividi {
                    RigaImpostazione(titolo: "Codice \(ruby.ponte.codice)", sottotitolo: "Da scrivere su iPhone e iPad.",
                                     aiuto: "Scrivilo in Prisma su iPhone e iPad (Impostazioni › Ruby), oppure apri lì un backup di questo Mac. Stessa rete Wi‑Fi, tutto cifrato") {
                        Button { stato.dati.impostazioni.ruby.ponte.codice = PonteRuby.nuovoCodice() } label: {
                            Label("Nuovo codice", systemImage: "key")
                        }
                        .buttonStyle(StilePulsanteRigaImpostazioni())
                        .fixedSize()
                        .help("Il codice vecchio smette di valere: va riscritto su iPhone e iPad")
                    }
                    .cascataImpostazioni(3)
                }
                RigaImpostazione(titolo: "Scorciatoia", sottotitolo: "Apri la mini Ruby; tienila premuta per parlare.", ultima: true) {
                    TastiScorciatoia(tasti: ["⌥", "Spazio"])
                }
                .cascataImpostazioni(4)
            }
            GruppoImpostazioni(titolo: "Come lavora") {
                RigaImpostazione(titolo: "Modello", sottotitolo: "Il nome in Ollama.") {
                    TextField(ruby.fornitore == .ollama ? MotoreLocale.modelloPredefinito : "nome del modello", text: $stato.dati.impostazioni.ruby.modello)
                        .campoTesto()
                        .frame(width: M.campoModello)
                        .onSubmit { stato.verificaMotoreLocale() }
                }
                RigaImpostazione(titolo: "Ragionamento", sottotitolo: "Sulle domande difficili.",
                                 aiuto: "Automatico: Ruby ragiona sulle domande difficili o quando le dici «pensaci bene». Risponde più piano") {
                    MenuTendina(selezione: $stato.dati.impostazioni.ruby.ragionamento,
                                opzioni: SceltaRagionamento.allCases.map { ($0, $0.nome) }, larghezza: M.menuMedio)
                }
                RigaImpostazione(titolo: "Pronta all'avvio", sottotitolo: "La prima risposta non aspetta.",
                                 aiuto: "All'apertura di Prisma Ruby avvia Ollama e carica il modello: la prima risposta non aspetta") {
                    interruttore($stato.dati.impostazioni.ruby.prontaAllAvvio)
                }
                RigaImpostazione(titolo: "Conserva le conversazioni", sottotitolo: "Nel dossier, sul Mac e nei backup.", ultima: true) {
                    interruttore($stato.dati.impostazioni.ruby.conservaConversazioni)
                }
            }
            .cascataImpostazioni(5)
            GruppoImpostazioni(titolo: "Avanzate") {
                rigaApri("Fornitore e indirizzo", "\(ruby.fornitore.nome) · solo indirizzi del Mac",
                         aperta: $mostraAvanzateRuby, ultima: !mostraAvanzateRuby)
                if mostraAvanzateRuby {
                    RigaImpostazione(titolo: "Fornitore del modello", sottotitolo: "Ollama o compatibile OpenAI",
                                     aiuto: "Ollama, oppure un server compatibile OpenAI (MLX, llama.cpp, LM Studio). Solo indirizzi del Mac (127.0.0.1)") {
                        MenuTendina(selezione: $stato.dati.impostazioni.ruby.fornitore,
                                    opzioni: TipoFornitore.allCases.map { ($0, $0.nome) }, larghezza: M.menuMedio)
                            .onChange(of: stato.dati.impostazioni.ruby.fornitore) { _ in stato.verificaMotoreLocale() }
                    }
                    RigaImpostazione(titolo: "Indirizzo", sottotitolo: "Solo 127.0.0.1", ultima: true) {
                        TextField(ruby.fornitore == .ollama ? FornitoreOllama.indirizzoPredefinito : FornitoreCompatibileOpenAI.indirizzoPredefinito,
                                  text: $stato.dati.impostazioni.ruby.indirizzo)
                            .campoTesto()
                            .frame(width: M.campoIndirizzo)
                            .onSubmit { stato.verificaMotoreLocale() }
                    }
                }
            }
            .cascataImpostazioni(6)
            NotaImpostazioni("Ruby spiega e racconta; le cifre le calcola Prisma. I dati non lasciano il Mac.")
                .cascataImpostazioni(7)
        }
    }

    /// Strumenti › Ruby: le stesse domande di prova a ogni modello, risposte e tempi affiancati.
    var rigaConfrontaModelli: some View {
        RigaImpostazione(titolo: "Confronta i modelli",
                         sottotitolo: stato.avanzamentoConfronto ?? "Le stesse domande a ogni modello",
                         icona: IconaVetroImpostazioni(.app(.ruby)),
                         aiuto: "Le stesse domande di prova (sui clienti fittizi) a ogni modello, uno alla volta: risposte e tempi affiancati in una pagina",
                         ultima: true) {
            HStack(spacing: 8) {
                TextField(ConfrontoModelli.predefiniti, text: $stato.dati.impostazioni.ruby.modelliConfronto)
                    .campoTesto()
                    .frame(width: M.campoConfronto)
                Button { stato.confrontaModelli() } label: { Label("Confronta", systemImage: "square.split.2x1") }
                    .buttonStyle(StilePulsanteRigaImpostazioni())
                    .disabled(stato.avanzamentoConfronto != nil)
            }
        }
    }
    #endif

    // MARK: Voce di Ruby (in Strumenti, chiusa: per ora Ruby non parla)

    /// La voce di Ruby e la conversazione a voce: tutto sul Mac (sintesi e dettatura di macOS). Il codice resta
    /// pronto per quando Ruby avrà la voce.
    @ViewBuilder var righeVoce: some View {
        let voci = VoceRuby.vociItaliane()
        let scelta: String = VoceRuby.voce(stato.dati.impostazioni.ruby.voce).map { "Ora " + VoceRuby.nome($0) } ?? "La migliore voce italiana installata"
        RigaImpostazione(titolo: "Voce di Ruby", sottotitolo: scelta,
                         aiuto: VoceRuby.soloVociStandard
                            ? "Per una voce più naturale scarica «Federica (Premium)» in Impostazioni di Sistema › Accessibilità › Contenuti letti ad alta voce › Voce di sistema › Gestisci voci › Italiano"
                            : nil) {
            HStack(spacing: 8) {
                MenuTendina(selezione: $stato.dati.impostazioni.ruby.voce,
                            opzioni: [(String?.none, "Automatica")] + voci.map { (String?.some($0.identifier), VoceRuby.nome($0)) },
                            larghezza: M.menuLargo)
                Button { stato.provaVoce() } label: { Label("Ascolta", systemImage: "speaker.wave.2") }
                    .buttonStyle(StilePulsanteRigaImpostazioni())
            }
        }
        RigaImpostazione(titolo: "Velocità della voce", sottotitolo: "Al centro il ritmo naturale") {
            Slider(value: $stato.dati.impostazioni.ruby.velocitaVoce, in: 0.7...1.4)
                .frame(width: M.menuMedio)
        }
        RigaImpostazione(titolo: "Risposte a voce", sottotitolo: "Il testo resta scritto") {
            MenuTendina(selezione: $stato.dati.impostazioni.ruby.risposteAVoce,
                        opzioni: ImpostazioniRuby.RisposteAVoce.allCases.map { ($0, $0.nome) }, larghezza: M.menuMedio)
        }
        RigaImpostazione(titolo: "Leggi tutta la risposta", sottotitolo: "Altrimenti solo l'inizio") {
            interruttore($stato.dati.impostazioni.ruby.leggiTutto)
        }
        RigaImpostazione(titolo: "Riconoscimento della voce", sottotitolo: "Sempre sul Mac",
                         aiuto: "Automatico: quello nuovo di Apple su macOS 26 e successivi, altrimenti la dettatura classica") {
            MenuTendina(selezione: $stato.dati.impostazioni.ruby.riconoscimento,
                        opzioni: SceltaRiconoscimento.allCases.map { ($0, $0.nome) }, larghezza: M.menuLargo)
            .onChange(of: stato.dati.impostazioni.ruby.riconoscimento) { _ in stato.azzeraRipieghiAscolto() }
        }
        RigaImpostazione(titolo: "Prova il microfono",
                         sottotitolo: stato.esitoProvaMicrofono ?? "Tre secondi di ascolto",
                         aiuto: "Tre secondi di ascolto senza riconoscimento: dice se il microfono sente") {
            Button { stato.provaMicrofono() } label: { Label("Prova", systemImage: "mic") }
                .buttonStyle(StilePulsanteRigaImpostazioni())
                .disabled(stato.esitoProvaMicrofono == "In prova… parla per tre secondi")
        }
        RigaImpostazione(titolo: "Prova il riconoscimento",
                         sottotitolo: stato.esitoProvaRiconoscimento ?? "Senza microfono, con ogni riconoscimento",
                         aiuto: "Ruby dice una frase e la fa capire a ogni riconoscimento (nuovo, dettatura di sistema, classico). Poi «Copia» per mandare il risultato") {
            HStack(spacing: 8) {
                Button { stato.provaRiconoscimento() } label: { Label("Prova", systemImage: "waveform") }
                    .buttonStyle(StilePulsanteRigaImpostazioni())
                    .disabled(stato.esitoProvaRiconoscimento == "In prova…")
                Button { stato.copiaDiagnosticaVoce() } label: { Label("Copia", systemImage: "doc.on.doc") }
                    .buttonStyle(StilePulsanteRigaImpostazioni())
            }
        }
        RigaImpostazione(titolo: "Mostra i passaggi dell'ascolto", sottotitolo: "Sotto il campo di Ruby",
                         aiuto: "Sotto il campo di Ruby compare l'ultimo passaggio (preparazione, microfono, risultati, voce, dettatura): si vede dove si ferma") {
            interruttore($stato.dati.impostazioni.ruby.mostraPassaggiVoce)
        }
        RigaImpostazione(titolo: "Conversazione continua", sottotitolo: "Ruby torna ad ascoltarti",
                         aiuto: "Dopo aver risposto Ruby torna ad ascoltarti, finché non le dici «basta così» · ⌥⌘E per parlarle",
                         ultima: true) {
            interruttore($stato.dati.impostazioni.ruby.conversazioneContinua)
        }
    }
}
