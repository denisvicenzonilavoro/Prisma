import SwiftUI

/// App Clienti nel tema Apple (Design/template-apple-specifica.md §4.2.1): la rubrica a sinistra (barra laterale
/// 250) e il dossier del cliente in una card senza ombra, con le tessere che contano e le schede (DossierApple.swift).
struct AppClienti: View {
    @Environment(StatoShell.self) var stato
    @State var ricerca = ""
    @State var soloPreferiti = false
    @State var modulo: Cliente?
    @State var familiare: ModificaFamiliare?
    /// Il campo su cui si apre il modulo del cliente o del familiare (completezza dei dati).
    @State var fuoco: FuocoModulo?
    /// Il potenziale da cui nasce il cliente del modulo («Luce» giro 12: arrivo in «Cliente»); nil = modulo normale.
    @State private var potenzialeDelModulo: String?

    var body: some View {
        let _ = ContaCorpi.segna()
        // Rubrica, Potenziali o Passaparola: i fogli e le richieste valgono per tutte e tre le viste
        contenuto
        // Il modulo del familiare per la scheda Famiglia (anche quella del template)
        .environment(\.azioneFamiliareDossier, AzioneFamiliareDossier(apri: { familiare = $0 }))
        .sheet(item: $modulo, onDismiss: {
            fuoco = nil
            // Annullato senza salvare: il potenziale resta (o torna) in «Proposta»
            if let p = potenzialeDelModulo {
                stato.annullaClienteDaPotenziale(p)
                potenzialeDelModulo = nil
            }
        }) { c in
            ModuloCliente(
                bozza: c,
                nuovo: !stato.clienti.contains { $0.id == c.id },
                salva: { cliente in
                    if let p = potenzialeDelModulo {
                        stato.confermaClienteDaPotenziale(potenziale: p, cliente: cliente)
                        potenzialeDelModulo = nil
                    } else {
                        stato.salvaCliente(cliente)
                    }
                },
                elimina: { stato.eliminaCliente(c.id) },
                conservaIban: stato.dati.impostazioni.pratiche.ibanConservato,
                rubrica: stato.clienti
            )
            .environment(\.fuocoModulo, fuoco)
        }
        .sheet(item: Bindable(stato).importazione) { i in
            ModuloImportaClienti(importazione: i)
                .environment(stato)
        }
        .sheet(item: $familiare, onDismiss: { fuoco = nil }) { m in
            ModuloFamiliare(modifica: m, salva: salvaFamiliare, elimina: eliminaFamiliare)
                .environment(\.fuocoModulo, fuoco)
        }
        .onAppear {
            controllaRichiesta(stato.richiestaNuovoCliente)
            controllaCompletamento(stato.richiestaCompletamento)
            controllaPotenziale(stato.richiestaClienteDaPotenziale)
            controllaBozza(stato.bozzaNuovoCliente)
        }
        .onChange(of: stato.richiestaNuovoCliente) { controllaRichiesta($0) }
        .onChange(of: stato.richiestaClienteDaPotenziale) { controllaPotenziale($0) }
        // «Luce» giro 13: «Scrivi a mano» dalla scena del nuovo cliente apre il modulo con i dati letti
        .onChange(of: stato.bozzaNuovoCliente) { controllaBozza($0) }
        #if os(iOS)
        // iPad: «Nuovo cliente» della testata apre la fotocamera per la carta d'identità («Luce» giro 13)
        .cartaIdentitaTelefono(stato)
        #endif
        .onChange(of: stato.richiestaCompletamento) { controllaCompletamento($0) }
    }

    /// La vista scelta nella testata (in modalità cliente sempre la Rubrica).
    @ViewBuilder private var contenuto: some View {
        switch stato.inModoCliente ? .rubrica : stato.vistaClienti {
        case .potenziali: VistaPotenziali()
        case .passaparola: VistaPassaparola()
        case .rubrica: conDettaglio
        }
    }

    /// Il modulo del nuovo cliente già compilato dal potenziale arrivato in «Cliente».
    private func controllaPotenziale(_ id: String?) {
        guard let id, modulo == nil, let c = stato.clienteDaPotenziale(id) else { return }
        potenzialeDelModulo = id
        modulo = c
    }

    /// Rubrica e dossier con sopra il dettaglio delle card. Su iPad il vetro della finestra resta fuori dal
    /// presentatore: la sfocatura del dettaglio aperto non si somma a quella del vetro (sfocature non annidate).
    @ViewBuilder private var conDettaglio: some View {
        #if os(iOS)
        PresentatoreDettaglioDossier(stato: stato) {
            dossierERubrica
        }
        .clipShape(FormaVetro.arrotondata(Tema.Raggio.scheda))
        .vetro(.sottile, forma: .arrotondata(Tema.Raggio.scheda))
        #else
        PresentatoreDettaglioDossier(stato: stato) {
            dossierERubrica
        }
        #endif
    }

    /// Rubrica e dossier: sul Mac il pannello e la card, su iPad sul vetro della finestra (in `conDettaglio`).
    @ViewBuilder private var dossierERubrica: some View {
        #if os(iOS)
        // iPad stretto: la rubrica si chiude in una striscia e si apre sopra il dossier (il cliente si sceglie
        // anche dalla barra degli strumenti). Rubrica e dossier stanno sul vetro della finestra.
        ColonnaLateraleAdattiva(larghezzaLaterale: Tema.Misura.Mobile.rubrica, titolo: "la rubrica",
                                chiudiAlCambio: AnyHashable(stato.clienteAttivoId)) {
            rubrica
                .frame(width: Tema.Misura.Mobile.rubrica)
        } contenuto: {
            dossierConFilo
        }
        #elseif os(macOS)
        // Sul Mac come nel template: la rubrica nel pannello, il dossier nella card a 16 di distanza
        // Finestra stretta (mezza finestra di uno spazio): resta solo il dossier, a tutta larghezza. La larghezza
        // ideale fissata dice a ViewThatFits quanto chiede il dossier (senza, i testi lunghi la farebbero enorme)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Tema.Apple.Clienti.spazioRubrica) {
                rubrica
                    .frame(width: Tema.Apple.Clienti.larghezzaRubrica)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .superficieApple(Tema.Apple.Superficie.pannello)
                    .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.Superficie.pannello.raggio, style: .continuous))
                dossier(superficie: Tema.Apple.Superficie.cardPiatta)
                    .frame(minWidth: Tema.Apple.Clienti.larghezzaMinimaDossier, idealWidth: Tema.Apple.Clienti.larghezzaMinimaDossier,
                           maxWidth: .infinity)
            }
            dossier(superficie: Tema.Apple.Superficie.cardPiatta)
        }
        #endif
    }

    /// Completezza dei dati: apre il modulo del cliente o del familiare sul campo da completare. Legge solo le
    /// richieste per il cliente attivo che riguardano Clienti (le altre sono di Posizioni) e le consuma.
    private func controllaCompletamento(_ richiesta: RichiestaCompletamento?) {
        guard let r = richiesta, r.clienteId == stato.clienteAttivoId else { return }
        switch r.destinazione {
        case .cliente(let campo):
            // La nota «Da ricordare» in attesa entra prima nella scheda: il modulo la salverebbe com'era
            TestiRinviati.scriviOra()
            if let c = stato.cliente(r.clienteId) {
                fuoco = FuocoModulo(campo: campo.etichetta, sezione: campo.sezione)
                modulo = c
            }
        case .familiare(let id):
            TestiRinviati.scriviOra()
            if let c = stato.cliente(r.clienteId), let f = c.famiglia.first(where: { $0.id == id }) {
                fuoco = FuocoModulo(campo: CampoCliente.dataNascita.etichetta)
                familiare = ModificaFamiliare(clienteId: c.id, familiare: f, nuovo: false)
            }
        case .analisi360, .posizione, .dettaglioPosizione:
            return
        }
        stato.richiestaCompletamento = nil
    }

    /// «Nuovo cliente» da un altro punto (Prova del fuoco…): sul Mac apre la scena della carta d'identità («Luce» giro 13),
    /// su iPhone e iPad il modulo vuoto.
    private func controllaRichiesta(_ richiesta: Bool) {
        guard richiesta else { return }
        stato.richiestaNuovoCliente = false
        #if os(macOS)
        stato.apriNuovoCliente()
        #else
        modulo = Cliente.nuovo(tinta: stato.prossimaTinta)
        #endif
    }

    /// La bozza del nuovo cliente con i dati letti dalla carta: il modulo si apre già compilato (si consuma subito).
    private func controllaBozza(_ bozza: Cliente?) {
        guard let bozza else { return }
        stato.bozzaNuovoCliente = nil
        modulo = bozza
    }

    #if os(iOS)
    /// Il dossier con il filo d'ombra verso la rubrica (iPad: tutto sul vetro della finestra).
    private var dossierConFilo: some View {
        dossier(superficie: nil)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .leading) {
                Rectangle().fill(Colori.Rubrica.divisoreOmbra)
                    .frame(width: Tema.Misura.filo)
                    .allowsHitTesting(false)
            }
    }
    #endif

    // MARK: - Rubrica

    private var rubrica: some View {
        RubricaApple(ricerca: $ricerca, soloPreferiti: $soloPreferiti)
    }

    // MARK: - Dossier

    @ViewBuilder private func dossier(superficie: Tema.Apple.Superficie?) -> some View {
        if stato.clienteAttivo != nil {
            DossierApple(superficie: superficie, modifica: { c in modulo = c }) { scheda, c in
                schedaDossier(scheda, c)
            }
        } else if stato.dati.clienti.isEmpty {
            // Rubrica vuota: il vuoto che spiega da dove si parte e che cosa fare
            VuotoGuidato(
                icona: "person.crop.circle.badge.plus",
                titolo: "La rubrica è vuota",
                perche: "Ogni analisi parte da una persona: chi è, la sua famiglia, il suo lavoro, che cosa le preme.",
                passi: [
                    ("Aggiungi", "Con «Nuovo cliente» in alto o dall'app Contatti."),
                    ("Completa", "Prisma ti dice quali dati mancano."),
                    ("Analizza", "Poi passa a Posizioni."),
                ],
                pulsante: "Importa i clienti…",
                azione: { stato.importaClientiDaFile() },
                secondario: ("Carica i clienti di prova", {
                    stato.schedaImpostazioni = .strumenti
                    stato.apri(.impostazioni)
                })
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fondoSuperficie(superficie)
        } else {
            VStack(spacing: 10) {
                IconaApp(app: .clienti, lato: Misure.Scrivania.icona)
                Text("Nessun cliente scelto.").font(Tipo.pannelloTitolo).foregroundColor(Colori.Rubrica.testo)
                Text("Scegli un cliente nella rubrica a sinistra.").font(Tipo.pannelloTesto).foregroundColor(Colori.Rubrica.secondario)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fondoSuperficie(superficie)
        }
    }

    /// Il contenuto di una scheda del dossier. Le quattro del template (Panoramica, Obiettivi, Nel tempo, Famiglia)
    /// hanno la loro vista in Shell/Dossier<Nome>.swift; le altre restano quelle di Prisma, nella cornice del tema
    /// che mette DossierApple.
    @ViewBuilder private func schedaDossier(_ scheda: SchedaCliente, _ c: Cliente) -> some View {
        switch scheda {
        case .panoramica: PanoramicaDossierApple(cliente: c)
        case .obiettivi: ObiettiviDossierApple(cliente: c)
        case .lineaVita: LineaVitaDossier(cliente: c)
        case .nelTempo: NelTempoDossier(cliente: c)
        case .famiglia: FamigliaDossier(cliente: c)
        case .bisogni: BisogniCliente(cliente: c)
        case .documenti:
            // Elenco e dettaglio scorrono da soli: la scheda prende tutta l'altezza, senza lo scorrimento del dossier
            DocumentiCliente(cliente: c)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Un altro cliente riparte con la ricerca vuota
                .id(c.id)
        case .anagrafica: anagrafica(c)
        case .profilo: profilo(c)
        case .inRegola: InRegolaCliente(cliente: c)
        case .note: note(c)
        case .riesami: CronologiaRiesami(cliente: c)
        case .azienda: AziendaDossier(cliente: c)
        }
    }

    private func anagrafica(_ c: Cliente) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                OcchielloSezione(titolo: "Dati personali")
                RigaCampo(etichetta: "Nome e cognome", valore: c.nome)
                RigaCampo(etichetta: "Data di nascita",
                          valore: c.dataNascita.map { "\(Formati.dataEstesa.string(from: $0))\(c.eta.map { " · \($0) anni" } ?? "")" } ?? "")
                RigaCampo(etichetta: "Codice fiscale", valore: c.codiceFiscale)
                RigaCampo(etichetta: "Professione", valore: c.professione)
                RigaCampo(etichetta: "Stato civile", valore: c.statoCivile?.nome ?? "")
            }
            VStack(alignment: .leading, spacing: 4) {
                OcchielloSezione(titolo: "Contatti")
                RigaCampo(etichetta: "Email", valore: c.email)
                RigaCampo(etichetta: "Telefono", valore: c.telefono)
                RigaCampo(etichetta: "Indirizzo", valore: c.indirizzo)
                // «Luce» giro 11: da dove viene la posizione sulla mappa del Territorio, con «Mettila a mano»
                RigaPosizioneMappa(cliente: c)
                RigaCampo(etichetta: "In rubrica dal", valore: Formati.dataEstesa.string(from: c.creatoIl))
            }
            // I dati per la fattura (Studio › Parcelle e fatture, giro 2): dal modulo «Modifica la scheda»
            VStack(alignment: .leading, spacing: 4) {
                let f = c.fiscale ?? DatiFiscaliCliente()
                OcchielloSezione(titolo: "Per le fatture",
                                 nota: MotoreFattura.mancantiCliente(c).isEmpty ? nil : "Per il file XML manca qualcosa")
                RigaCampo(etichetta: "Intestata a", valore: f.vuoti ? "" : TestiFattura.nomeFattura(c))
                RigaCampo(etichetta: "Partita IVA", valore: f.partitaIVA)
                RigaCampo(etichetta: "Sede", valore: TestiFattura.sede(f.sede))
                RigaCampo(etichetta: "Codice destinatario", valore: f.codiceDestinatario)
                RigaCampo(etichetta: "PEC", valore: f.pec)
                RigaCampo(etichetta: "Sostituto d'imposta",
                          valore: f.sostitutoImposta.map { $0 ? "Sì" : "No" } ?? "")
            }
            Button {
                // La nota «Da ricordare» in attesa entra prima nella scheda: il modulo la salverebbe com'era
                TestiRinviati.scriviOra()
                modulo = stato.cliente(c.id) ?? c
            } label: {
                Label("Modifica la scheda", systemImage: "pencil")
            }
                .buttonStyle(StileCuoioChiaro())
        }
    }

    private func portafoglioModello(_ c: Cliente) -> some View {
        let modelli = stato.dati.portafogliModello
        return VStack(alignment: .leading, spacing: 4) {
            OcchielloSezione(titolo: "Portafoglio modello")
            HStack(spacing: 10) {
                Picker("Portafoglio modello", selection: Binding(
                    get: { c.modelloId ?? "" },
                    set: { assegnaModello(c.id, $0.isEmpty ? nil : $0) })) {
                    Text("Nessun modello").tag("")
                    ForEach(modelli) { m in Text(m.nome.isEmpty ? "Senza nome" : m.nome).tag(m.id) }
                }
                .labelsHidden()
                .frame(width: Tema.Apple.Posizioni.Radar.Impostazioni.sceltaModello)
                .disabled(stato.solaLettura || modelli.isEmpty)
                Button(modelli.isEmpty ? "Imposta i modelli" : "I modelli") { stato.apriImpostazioniModelli() }
                    .buttonStyle(.appleSobrio)
            }
            .padding(.vertical, 6)
            Text("Il modello è una scelta tua, separata dal profilo MiFID: il radar segnala se chiede più rischio del profilo.")
                .font(Tipo.rubricaTema)
                .foregroundColor(Colori.Rubrica.secondario)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func assegnaModello(_ clienteId: String, _ modelloId: String?) {
        guard !stato.solaLettura, let i = stato.dati.clienti.firstIndex(where: { $0.id == clienteId }) else { return }
        stato.dati.clienti[i].modelloId = modelloId
    }

    private func profilo(_ c: Cliente) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                OcchielloSezione(titolo: "Profilo dell'investitore",
                                 nota: c.profilo.aggiornatoIl.map { "Aggiornato il \(Formati.dataEstesa.string(from: $0))" })
                RigaCampo(etichetta: "Propensione al rischio", valore: c.profilo.propensione?.nome ?? "")
                // Il gioco del rischio della Sala («Luce» giro 4): la partita salvata accanto al dichiarato, mai al suo posto
                if let p = MotoreGiocoRischio.ultima(stato.dati.partiteRischio, cliente: c.id), let s = MotoreGiocoRischio.caricati,
                   let emerso = MotoreGiocoRischio.profilo(p, scenari: s) {
                    RigaCampo(etichetta: "Gioco del rischio",
                              valore: "\(emerso.nome) (\(Formati.dataEstesa.string(from: p.data))) · non cambia la propensione")
                }
                RigaCampo(etichetta: "Orizzonte temporale", valore: c.profilo.orizzonteAnni.map { "\($0) anni" } ?? "")
                RigaCampo(etichetta: "Esperienza finanziaria", valore: c.profilo.esperienza?.nome ?? "")
                RigaCampo(etichetta: "Reddito lordo annuo", valore: c.profilo.redditoLordoAnnuo.map { Formati.euro($0) } ?? "")
                RigaCampo(etichetta: "Obiettivi principali", valore: c.profilo.obiettivi)
            }
            EsperienzaCliente(cliente: c)
            VStack(alignment: .leading, spacing: 4) {
                OcchielloSezione(titolo: "Canali")
                HStack(spacing: 8) {
                    if c.canali.isEmpty {
                        Text("Nessun canale indicato").font(Tipo.campoValore).foregroundColor(Colori.Rubrica.secondario)
                    }
                    ForEach(c.canali) { EtichettaCanale(canale: $0) }
                }
                .padding(.vertical, 8)
            }
            // Il portafoglio modello del radar («Luce» §8.3.5): scelta del consulente, separata dal profilo MiFID. In
            // modalità cliente non si vede (il radar e i modelli sono riservati, decisione 50)
            if !stato.inModoCliente {
                portafoglioModello(c)
            }
            VStack(alignment: .leading, spacing: 4) {
                OcchielloSezione(titolo: "Consensi")
                RigaCampo(etichetta: "Privacy", valore: c.consensi.privacy
                          ? "Sì" + (c.consensi.dataPrivacy.map { ", dal \(Formati.dataEstesa.string(from: $0))" } ?? "")
                          : "Non raccolto")
                RigaCampo(etichetta: "Comunicazioni commerciali", valore: c.consensi.marketing
                          ? "Sì" + (c.consensi.dataMarketing.map { ", dal \(Formati.dataEstesa.string(from: $0))" } ?? "")
                          : "No")
            }
            Text("Il profilo orienta le analisi di Posizioni. Non sostituisce i questionari di adeguatezza ufficiali.")
                .font(Tipo.rubricaTema)
                .foregroundColor(Colori.Rubrica.secondario)
            Button {
                // La nota «Da ricordare» in attesa entra prima nella scheda: il modulo la salverebbe com'era
                TestiRinviati.scriviOra()
                modulo = stato.cliente(c.id) ?? c
            } label: {
                Label("Modifica il profilo", systemImage: "pencil")
            }
                .buttonStyle(StileCuoioChiaro())
        }
    }

    private func note(_ c: Cliente) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            OcchielloSezione(titolo: "Da ricordare", nota: "Si salva da sola")
            // Si scrive nel campo e passa all'archivio poco dopo l'ultimo tasto: una lettera non rifà tutta Prisma
            TestoRinviato(testo: Binding(get: { c.nota }, set: { stato.aggiornaNota(c.id, $0) }),
                          salvaOra: { stato.salvaOra() }) { bozza in
                TextEditor(text: bozza)
                    .font(Tipo.campoValore)
                    .foregroundColor(Colori.Rubrica.testo)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .padding(10)
                    .frame(minHeight: 260)
                    .background { FormaVetro.arrotondata(Tema.Raggio.Dossier.campoLungo).fill(Tema.Colore.pozzetto) }
                    .overlay {
                        FormaVetro.arrotondata(Tema.Raggio.Dossier.campoLungo)
                            .strokeBorder(Tema.Colore.separatore, lineWidth: Tema.Misura.filo)
                            .allowsHitTesting(false)
                    }
            }
            // Cambiando cliente la bozza riparte dalla sua nota (e quella in attesa va al cliente di prima)
            .id(c.id)
            OcchielloSezione(titolo: "Nel taccuino", nota: "Le note dell'app Note")
                .padding(.top, 8)
            let note = stato.noteCliente(c.id).filter { !$0.vuota }
            if note.isEmpty {
                Text("Nessuna nota per \(c.nome). Gli appunti degli incontri trovano posto nel taccuino.")
                    .font(Tipo.rubricaTema)
                    .foregroundColor(Colori.Rubrica.secondario)
            } else {
                ForEach(note) { n in
                    Button { stato.vai(a: .nota(n.id)) } label: {
                        HStack(spacing: 8) {
                            if n.fissata { Text("◆").font(Tipo.noteVoceData).foregroundColor(Colori.Note.fissata) }
                            Text(n.titoloMostrato).font(Tipo.campoValore).foregroundColor(Colori.Rubrica.testo).lineLimit(1)
                            Spacer()
                            Text(Formati.giornoMeseBreve.string(from: n.aggiornataIl)).font(Tipo.rubricaTema).foregroundColor(Colori.Rubrica.secondario)
                            Image(systemName: "chevron.right").font(Tipo.rubricaFreccia).foregroundColor(Colori.Rubrica.rigaFreccia)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StileSemplice())
                    .bordoBasso(Colori.Rubrica.rigaBordo)
                }
            }
            Button {
                stato.filtroClienteNote = c.id
                stato.nuovaNota(clienteId: c.id)
                stato.apri(.note)
            } label: {
                Label("Nuova nota per \(c.nome)", systemImage: "plus")
            }
            .buttonStyle(StileCuoioChiaro())
            // I messaggi preparati in Messaggi (giro 3 di Orizzonte): restano nel dossier con la data e lo stato
            OcchielloSezione(titolo: "Messaggi", nota: "Preparati in Messaggi, spediti da te")
                .padding(.top, 8)
            let messaggi = stato.messaggiCliente(c.id)
            if messaggi.isEmpty {
                Text("Nessun messaggio per \(c.nome). Quelli che prepari in Messaggi restano qui, con la data.")
                    .font(Tipo.rubricaTema)
                    .foregroundColor(Colori.Rubrica.secondario)
            } else {
                ForEach(messaggi) { m in
                    // Un clic lo riapre in Messaggi, sul cliente e sul suo motivo (CollegamentiMessaggi.swift)
                    Button { stato.preparaMessaggio(clienteId: c.id, occasioneId: m.occasioneId, messaggioId: m.id) } label: {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(m.oggetto ?? m.origine.tipo.nome)
                                    .font(Tipo.campoValore).foregroundColor(Colori.Rubrica.testo).lineLimit(1)
                                Text("\(m.canale.nome) · \(m.tono.nome) · \(m.stato.nome) · \(m.autore.nome)")
                                    .font(Tipo.rubricaTema).foregroundColor(Colori.Rubrica.secondario).lineLimit(1)
                            }
                            Spacer()
                            Text(Formati.giornoMeseBreve.string(from: m.dataMostrata))
                                .font(Tipo.rubricaTema).foregroundColor(Colori.Rubrica.secondario)
                            Image(systemName: "chevron.right").font(Tipo.rubricaFreccia).foregroundColor(Colori.Rubrica.rigaFreccia)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(StileSemplice())
                    .help(m.testo)
                    .bordoBasso(Colori.Rubrica.rigaBordo)
                }
            }
            // «Scrivi a …» solo quando Messaggi ha un motivo per scrivergli oggi o in settimana: apre la sua prima occasione
            if let prima = stato.occasioniMessaggi().tutte.first(where: { o in o.clienteId == c.id }) {
                Button { stato.preparaMessaggio(clienteId: c.id, occasioneId: prima.id) } label: {
                    Label("Scrivi a \(c.nome)", systemImage: "envelope")
                }
                .buttonStyle(StileCuoioChiaro())
                .help("Apre Messaggi su «\(prima.titolo)»: Prisma prepara il testo, lo spedisci tu")
            }
        }
    }

    // MARK: - Familiari

    private func salvaFamiliare(_ m: ModificaFamiliare) {
        guard var c = stato.cliente(m.clienteId) else { return }
        if let i = c.famiglia.firstIndex(where: { $0.id == m.familiare.id }) {
            c.famiglia[i] = m.familiare
        } else {
            c.famiglia.append(m.familiare)
        }
        stato.salvaCliente(c)
    }

    private func eliminaFamiliare(_ m: ModificaFamiliare) {
        guard var c = stato.cliente(m.clienteId) else { return }
        c.famiglia.removeAll { $0.id == m.familiare.id }
        stato.salvaCliente(c)
    }
}

struct ModificaFamiliare: Identifiable {
    let id = UUID()
    let clienteId: String
    var familiare: Familiare
    let nuovo: Bool
}

// MARK: - Campo di ricerca

struct CampoRicerca: View {
    @Binding var testo: String
    let segnaposto: String

    var body: some View {
        // Il campo di ricerca del tema: pozzetto in capsula con un filo sottile
        let forma = FormaVetro.capsula
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(Tema.Testo.secondario)
                .foregroundColor(Colori.Rubrica.cerca)
            TextField(segnaposto, text: $testo)
                .textFieldStyle(.plain)
                .font(Tema.Testo.corpo)
                .foregroundColor(Tema.Colore.inchiostro)
            if !testo.isEmpty {
                Button { testo = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Colori.Rubrica.cerca)
                        .contentShape(Rectangle().inset(by: -Tema.Misura.Componenti.allargamentoClic))
                }
                .buttonStyle(StileSemplice())
                .help("Cancella la ricerca")
                .accessibilityLabel("Cancella la ricerca")
            }
        }
        .padding(.horizontal, Tema.Misura.Componenti.margineCampo)
        .frame(height: Tema.Misura.Componenti.campoPiccolo)
        .background { forma.fill(Tema.Colore.pozzetto) }
        .overlay { forma.strokeBorder(Tema.Colore.separatore, lineWidth: Tema.Misura.filo).allowsHitTesting(false) }
    }
}

// MARK: - Panoramica

struct PanoramicaCliente: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    /// false sotto la Panoramica del tema Apple (DossierPanoramica.swift), che ha già la sua griglia con i dati per
    /// l'analisi, «Da ricordare» e il prossimo incontro: qui restano riesame, In regola e il dossier collegato.
    var conQuadro = true

    var body: some View {
        let _ = ContaCorpi.segna()
        let prossimo = stato.prossimiAppuntamenti.first { $0.clienteId == cliente.id }
        let aperte = stato.attivitaCliente(cliente.id).filter { !$0.completata }
        let aCarico = cliente.famiglia.filter(\.aCarico).count
        VStack(alignment: .leading, spacing: 14) {
            if conQuadro {
                quadro(prossimo: prossimo, aperte: aperte, aCarico: aCarico)
            }
            riesame
            RiquadroInRegola(clienteId: cliente.id)
            OcchielloSezione(titolo: "Il dossier collegato")
            collegati(aperte: aperte)
        }
    }

    /// Il quadro di sempre: età, nucleo e da seguire, i dati per l'analisi e «Da ricordare».
    @ViewBuilder private func quadro(prossimo: Appuntamento?, aperte: [Attivita], aCarico: Int) -> some View {
            OcchielloSezione(titolo: "Il quadro d'insieme", nota: "Una scheda, tutte le app.")
            FasciaMetriche(metriche: [
                .init(etichetta: "Età", valore: cliente.eta.map { "\($0) anni" } ?? "—",
                      nota: cliente.professione.isEmpty ? "Professione non indicata" : cliente.professione),
                .init(etichetta: "Nucleo familiare", valore: "\(cliente.famiglia.count + 1) \(cliente.famiglia.isEmpty ? "persona" : "persone")",
                      nota: aCarico == 0 ? "Nessuno a carico" : "\(aCarico) a carico"),
                .init(etichetta: "Da seguire", valore: "\(aperte.count) \(aperte.count == 1 ? "attività" : "attività")",
                      nota: prossimo.map { "Prossimo incontro \(Formati.giorno.string(from: $0.inizio)) \(Formati.meseBreve.string(from: $0.inizio)), \(Formati.ora.string(from: $0.inizio))" }
                          ?? "Nessun incontro in programma"),
            ])
            completezza
            if !cliente.nota.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    OcchielloSezione(titolo: "Da ricordare")
                    Text(cliente.nota)
                        .font(Tipo.campoValore)
                        .foregroundColor(Colori.Rubrica.testo)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
    }

    /// Le app e le schede collegate al dossier.
    private func collegati(aperte: [Attivita]) -> some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Misure.Rubrica.schedaAppMinima), spacing: 8)], spacing: 8) {
                collegamento(.posizioni, "In essere e in proposta")
                collegamento(.analisi360, "Previdenza, protezione, investimenti")
                collegamento(.incontri, "Appunti, decisioni e seguiti")
                // Obiettivi e documenti sono schede di questo dossier: il clic cambia scheda, non apre un'altra app
                scheda(.obiettivi, .obiettivi, sottotitoloObiettivi, conteggio: stato.obiettiviCliente(cliente.id).count)
                collegamento(.agenda, "Appuntamenti", conteggio: stato.appuntamentiCliente(cliente.id).count)
                collegamento(.attivita, "Azioni ancora aperte", conteggio: aperte.count)
                scheda(.documenti, .documenti, sottotitoloDocumenti, conteggio: stato.documentiCliente(cliente.id).count)
                collegamento(.note, "Appunti e idee")
                collegamento(.presentazioni, "Prospetti in PDF")
                collegamento(.vera, "Ragiona su questo cliente")
            }
    }

    /// I dati per l'analisi: cosa manca, cosa è stimato o vecchio, e un clic per completarlo. Strumento del
    /// consulente: in modalità cliente non compare.
    @ViewBuilder private var completezza: some View {
        if !stato.inModoCliente, let k = stato.completezzaCliente(cliente.id) {
            let id = cliente.id
            let nome = cliente.nome
            RiquadroCompletezza(
                completezza: k,
                completa: { stato.apriCompletamento($0, cliente: id) },
                escludi: { v in
                    stato.segnaDatoNonPertinente(v.id, cliente: id)
                    stato.mostraAvviso(TestiCompletezza.avvisoEsclusa(v.titolo, nome: nome))
                },
                ripristina: { stato.ripristinaDatiNonPertinenti(id) }
            )
            // Un altro cliente riparte con le voci raccolte
            .id(id)
        }
    }

    /// Il riesame annuale, quando è dovuto: quanti punti ci sono da trattare e il prospetto per prepararlo.
    @ViewBuilder private var riesame: some View {
        // Calcolato una volta per dati e ora (DerivatiDati): passa da tutta la fonte di Vera
        if let r = stato.riesameCliente(cliente.id) {
            if r.dovuto, r.prossimo == nil, !r.punti.isEmpty {
                let alta = r.punti.filter { $0.priorita == .alta }.count
                VStack(alignment: .leading, spacing: 6) {
                    OcchielloSezione(titolo: "Riesame annuale", nota: r.ultimoContatto.map { "Ultimo incontro il \(Formati.dataEstesa.string(from: $0))" } ?? "Nessun incontro registrato")
                    HStack(alignment: .center, spacing: 12) {
                        Text("\(r.punti.count) punti da trattare" + (alta > 0 ? ", \(alta) con priorità alta" : "") + ": " + r.punti.prefix(2).map(\.titolo).joined(separator: "; ") + (r.punti.count > 2 ? "…" : "."))
                            .font(Tipo.campoValore)
                            .foregroundColor(Colori.Rubrica.testo)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Button("Prepara il riesame") {
                            stato.clienteAttivoId = cliente.id
                            stato.apriProspetto(.riesame)
                        }
                        .buttonStyle(StileCuoioChiaro())
                    }
                    RigaMemoriaPanoramica(clienteId: cliente.id)
                }
            }
        }
    }

    /// Una scheda del dossier presentata come le app collegate (icona dell'app accorpata): il clic la apre qui.
    private func scheda(_ app: AppPrisma, _ destinazione: SchedaCliente, _ sottotitolo: String, conteggio: Int) -> some View {
        SchedaAppCollegata(app: app, sottotitolo: sottotitolo, conteggio: conteggio) {
            stato.schedaCliente = destinazione
        }
    }

    /// «38% coperto» se ci sono obiettivi, altrimenti che cosa sono.
    private var sottotitoloObiettivi: String {
        let elenco = stato.obiettiviCliente(cliente.id)
        guard !elenco.isEmpty else { return "I progetti da realizzare" }
        let avanzamenti = stato.avanzamentiObiettivi(cliente.id)
        let totale = elenco.reduce(0.0) { $0 + max($1.importo, 0) }
        let coperto = elenco.reduce(0.0) { $0 + min(avanzamenti[$1.id]?.accantonato ?? 0, max($1.importo, 0)) }
        let quota = totale > 0 ? coperto / totale : 1
        return "\(Int((quota * 100).rounded()))% coperto"
    }

    /// «2 da leggere» se ce ne sono, altrimenti personali e dei prodotti.
    private var sottotitoloDocumenti: String {
        let voci = stato.vociDocumenti(cliente.id)
        let daLeggere = voci.filter { MotoreDocumenti.appartiene($0, a: .daLeggere) }.count
        if daLeggere > 0 { return "\(daLeggere) da leggere" }
        return "Personali e dei prodotti"
    }

    private func collegamento(_ app: AppPrisma, _ sottotitolo: String, conteggio: Int? = nil) -> some View {
        SchedaAppCollegata(app: app, sottotitolo: sottotitolo, conteggio: conteggio) {
            stato.clienteAttivoId = cliente.id
            stato.apri(app)
        }
    }
}
