import CryptoKit
import Foundation

/// Prova della fase 2 di Vera (Vera/BRIEF.md) dentro `Prisma --prova-vera`: la finestra unica del filo lungo, la ricerca
/// (BM25 e vettori finti da /api/embed), la memoria cifrata (cosa non si ricorda mai, «ricorda che…», i ricordi proposti
/// e confermati, la modalità cliente), le lezioni che arrivano a Qwen dalla risposta dopo, il riassunto progressivo
/// (un fatto detto all'inizio resta nel messaggio a Qwen), «Il cliente in 30 secondi», la biblioteca delle norme (articoli,
/// citazioni, «la norma non risponde») e «Lascia cadere qui» (cliente riconosciuto, scheda, archivio, annulla).
enum ProvaFaseDueVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let lezioniPrima = LezioniVera.attive
        let finestraPrima = FinestraVera.attuale
        defer {
            LezioniVera.attive = lezioniPrima
            FinestraVera.attuale = finestraPrima
        }
        pacchetto(controlla)
        finestra(controlla)
        ricerca(controlla)
        memoria(controlla)
        lezioni(controlla)
        filo(controlla)
        trenta(controlla)
        norme(controlla)
        lasciaCadere(controlla)
        archivio(controlla)
    }

    // MARK: - Aiuti

    private final class Scatola<T>: @unchecked Sendable { var valore: T?; init() {} }

    private static func aspetta<T>(_ f: @escaping () async -> T?) -> T? {
        let s = Scatola<T>()
        let semaforo = DispatchSemaphore(value: 0)
        Task.detached {
            s.valore = await f()
            semaforo.signal()
        }
        _ = semaforo.wait(timeout: .now() + 20)
        return s.valore
    }

    private static var sessioneFinta: URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.protocolClasses = [ServerFintoScenari.self]
        return URLSession(configuration: c)
    }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        for (nome, parola) in [("filo", "riassunto"), ("trenta", "JSON"), ("norme", "articoli")] {
            let t = IstruzioniVera.testo(nome) ?? ""
            controlla(t.contains(parola), "Fase 2: istruzioni «\(nome)» nel pacchetto (Vera/Istruzioni/\(nome).md)")
        }
    }

    // MARK: - Il filo lungo: una finestra sola

    private static func finestra(_ controlla: (Bool, String) -> Void) {
        let dec = JSONDecoder()
        let vecchie = try? dec.decode(ImpostazioniVera.self, from: Data(#"{"leggiTutto":true}"#.utf8))
        controlla(vecchie?.finestra == FinestraVera.predefinita && vecchie?.memoriaAttiva == true && vecchie?.modelloRicerca == RicercaVera.modelloPredefinito,
                  "Filo lungo: le impostazioni di prima si aprono con la finestra lunga, la memoria accesa e il modello di ricerca")
        let strane = try? dec.decode(ImpostazioniVera.self, from: Data(#"{"finestra":1234}"#.utf8))
        controlla(strane?.finestra == FinestraVera.predefinita, "Filo lungo: una finestra non prevista torna quella predefinita")
        let s = StatoShell(persistente: false)
        s.dati.impostazioni.vera.finestra = 16_384
        controlla(FinestraVera.attuale == 16_384 && NucleoVera.finestra == 16_384 && FalloTuVera.opzioni(s.dati.impostazioni.vera, inModoCliente: false).contesto == 16_384,
                  "Filo lungo: la finestra scelta vale per tutte le chiamate (chat, strumenti, JSON)")
        s.dati.impostazioni.vera.finestra = 32_768
        controlla(NucleoVera.massimoBattute > 40, "Filo lungo: con 32.000 token la storia porta più battute")
    }

    // MARK: - Ricerca

    private static func ricerca(_ controlla: (Bool, String) -> Void) {
        let pezzi = [PezzoRicerca(id: "a", tipo: .nota, clienteId: "x", fonte: "Nota A", testo: "Il cliente vuole riscattare il piano della casa senza penali"),
                     PezzoRicerca(id: "b", tipo: .nota, clienteId: "x", fonte: "Nota B", testo: "Le vacanze in montagna sono andate bene"),
                     PezzoRicerca(id: "c", tipo: .nota, clienteId: "x", fonte: "Nota C", testo: "Il riscatto parziale costa cinquanta euro")]
        let r = RicercaVera.cerca("quanto costa il riscatto?", in: pezzi)
        controlla(r.first?.pezzo.id == "c" && !r.contains { $0.pezzo.id == "b" }, "Ricerca: BM25 trova il passaggio giusto e lascia fuori quelli senza parole in comune")
        controlla(RicercaVera.cerca("tempo", in: pezzi).isEmpty, "Ricerca: senza niente di pertinente non torna nulla (meglio «non trovato»)")

        // Vettori finti da /api/embed, cache e ricerca per significato
        let f = FornitoreOllama(indirizzo: FornitoreOllama.indirizzoPredefinito, modello: "qwen3.5:4b", sessione: sessioneFinta)
        let indice = IndiceVera(persistente: false) { nil }
        let prima = ServerFintoScenari.chiamateEmbed
        let v = aspetta { await indice.vettori(per: pezzi, domanda: "riscatto del piano", fornitore: f, modello: RicercaVera.modelloPredefinito) }
        controlla(v?.pezzi.count == 3 && v?.domanda.count == 64 && indice.quanti == 3, "Ricerca: i vettori dei pezzi e della domanda da /api/embed")
        let dopo = ServerFintoScenari.chiamateEmbed
        _ = aspetta { await indice.vettori(per: pezzi, domanda: "riscatto", fornitore: f, modello: RicercaVera.modelloPredefinito) }
        controlla(ServerFintoScenari.chiamateEmbed == dopo + 1 && dopo > prima, "Ricerca: i vettori già calcolati non si chiedono di nuovo (solo la domanda)")
        if let v {
            let s = RicercaVera.cerca("riscattare il piano", in: pezzi, vettori: v.pezzi, domandaVettore: v.domanda)
            controlla(s.first?.pezzo.id == "a", "Ricerca: con i vettori vince il passaggio più vicino per significato")
        }
        let senza = IndiceVera(persistente: false) { nil }
        let rotto = FornitoreOllama(indirizzo: "http://127.0.0.1:1", modello: "x", sessione: URLSession(configuration: .ephemeral))
        controlla(aspetta { await senza.vettori(per: pezzi, domanda: "x", fornitore: rotto, modello: "x") } == nil,
                  "Ricerca: senza il modello di ricerca resta BM25 (nessun errore)")
    }

    // MARK: - Memoria

    private static func memoria(_ controlla: (Bool, String) -> Void) {
        let vietati = ["la password di Marco è gatto123", "IBAN IT60X0542811101000000123456", "codice fiscale RSSGLI85M41H501Z",
                       "il numero della carta è 4111 1111 1111 1111", "il PIN del bancomat"]
        controlla(vietati.allSatisfy { MemoriaVera.vietato($0) != nil } && MemoriaVera.vietato("Marco preferisce le videochiamate al mattino") == nil,
                  "Memoria: mai numeri di documenti, conti, carte, codici fiscali o password; le preferenze sì")
        controlla(MemoriaVera.richiestaEsplicita("Ricorda che Sofia decide sempre insieme a Paolo.") == "Sofia decide sempre insieme a Paolo"
                  && MemoriaVera.richiestaEsplicita("Ricordami di chiamare Laura") == nil
                  && MemoriaVera.richiestaEsplicita("Ricorda di chiamare Laura domani") == nil,
                  "Memoria: «ricorda che…» è un ricordo, «ricordami di…» resta un promemoria")
        let proposte = MemoriaVera.proposte(da: "Marco preferisce le videochiamate al mattino. Quanto ha nel fondo?")
        controlla(proposte == ["Marco preferisce le videochiamate al mattino"], "Memoria: dalla domanda Vera propone il ricordo giusto")

        // Cifratura
        if let k = MemoriaVera.nuovaChiave(), let altra = MemoriaVera.nuovaChiave() {
            var c = ContenutoMemoriaVera()
            c.ricordi = [RicordoVera(testo: "Laura non vuole rischi sulla casa", clienteId: "laura", fonte: "in chat")]
            let d = try? MemoriaVera.scrivi(c, chiave: k)
            controlla(d != nil && d?.range(of: Data("rischi".utf8)) == nil && (try? MemoriaVera.leggi(d!, chiave: k))?.ricordi.first?.testo == c.ricordi.first?.testo
                      && (try? MemoriaVera.leggi(d!, chiave: altra)) == nil,
                      "Memoria: cifrata, si apre solo con la sua chiave")
        }

        // Nella conversazione
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "giulia"
        controlla(s.ricordaVera("Ricorda che Sofia decide sempre insieme a Paolo", chiave: "giulia")
                  && s.memoriaVera.ricordi.contains { $0.clienteId == "sofia" && $0.testo.contains("Paolo") },
                  "Memoria: «ricorda che…» si salva subito, sul cliente nominato")
        if let m = s.conversazione("giulia").last, m.conferma?.stato == .eseguita {
            s.annullaSchedaVera(messaggio: m.id)
            controlla(!s.memoriaVera.ricordi.contains { $0.testo.contains("Paolo") }, "Memoria: «Annulla» lo dimentica")
        } else {
            controlla(false, "Memoria: il ricordo si può annullare")
        }
        _ = s.ricordaVera("Ricorda che l'IBAN di Marco è IT60X0542811101000000123456", chiave: "giulia")
        controlla(s.memoriaVera.ricordi.isEmpty && s.conversazione("giulia").last?.testo.contains("IBAN") == true,
                  "Memoria: un IBAN non si ricorda e Vera lo dice")
        if let scheda = s.schedaRicordi(da: "Marco preferisce le videochiamate al mattino", chiave: "marco") {
            controlla(scheda.origine == .memoria && scheda.azioni.first?.argomenti["cliente"] == "marco" && s.memoriaVera.ricordi.isEmpty,
                      "Memoria: Vera propone il ricordo e non lo salva prima del sì")
            var m = MessaggioVera(autore: .vera, testo: "Risposta")
            m.conferma = scheda
            s.aggiungiMessaggio(m, cliente: "marco")
            s.confermaSchedaVera(messaggio: m.id)
            controlla(s.memoriaVera.ricordi.contains { $0.clienteId == "marco" }, "Memoria: con «Ricorda» il ricordo è salvato")
        } else {
            controlla(false, "Memoria: Vera propone il ricordo dalla domanda")
        }
        _ = s.memoriaVera.ricorda("Preferisco i report in una pagina", cliente: nil, fonte: "in chat")
        controlla(s.ricordiPerVera(cliente: "marco").count == 2, "Memoria: a Vera vanno i ricordi del cliente e quelli su di te")
        s.entraModoCliente()
        controlla(s.ricordiPerVera(cliente: s.clienteAttivoId).allSatisfy { r in s.memoriaVera.ricordi.contains { $0.testo == r && $0.clienteId == s.clienteAttivoId } },
                  "Memoria: in modalità cliente solo i ricordi del cliente davanti a te")
        s.dati.impostazioni.vera.memoriaAttiva = false
        controlla(s.ricordiPerVera(cliente: "marco").isEmpty, "Memoria: spenta, Vera non usa i ricordi")
    }

    // MARK: - Lezioni

    private static func lezioni(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "giulia"
        var m = MessaggioVera(autore: .vera, testo: "Ciao Sofia, il prodotto…", motore: "Qwen sul Mac")
        m.modalita = .lavoro
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Spiega a Sofia"), cliente: "giulia")
        s.aggiungiMessaggio(m, cliente: "giulia")
        controlla(s.correggiRispostaVera(m.id, correzione: "") == nil && s.memoriaVera.lezioni.isEmpty, "Lezioni: un 👎 senza testo non crea una lezione")
        let l = s.correggiRispostaVera(m.id, correzione: "Con i clienti Alleanza parla di «piano», non di «prodotto»")
        controlla(l != nil && LezioniVera.attive.contains(l!.testo) && s.messaggioVera(m.id)?.voto == false,
                  "Lezioni: la correzione diventa una lezione attiva subito")
        s.approvaRispostaVera(m.id)
        controlla(s.messaggioVera(m.id)?.voto == true, "Lezioni: 👍 segna la risposta come buona")
        // La lezione arriva a Qwen dalla risposta dopo (solo per il testo libero, non per i JSON)
        let motore = MotoreLocale(ImpostazioniVera(), disponibilita: .pronto, sessione: sessioneFinta)
        ServerFintoScenari.prepara(["Gentile Sofia, il piano…", #"{"capito":false,"filtri":[]}"#])
        _ = aspetta { try? await motore.scrivi([MessaggioModello(ruolo: .sistema, testo: "Istruzioni"), MessaggioModello(ruolo: .utente, testo: "Scrivi")],
                                               opzioni: OpzioniModello()).testo }
        let sistema = ((ServerFintoScenari.ultimo["messages"] as? [[String: Any]])?.first?["content"] as? String) ?? ""
        controlla(sistema.contains("LEZIONI DEL CONSULENTE") && sistema.contains("«piano»"), "Lezioni: Qwen le rilegge prima di rispondere")
        _ = aspetta { try? await motore.scrivi(ClientelaVera.messaggi("Chi?", oggi: Date()), opzioni: ClientelaVera.opzioni(ImpostazioniVera())).testo }
        let json = ((ServerFintoScenari.ultimo["messages"] as? [[String: Any]])?.first?["content"] as? String) ?? ""
        controlla(!json.contains("LEZIONI DEL CONSULENTE"), "Lezioni: non entrano nelle risposte in JSON")
        s.dati.impostazioni.vera.imparaDalleCorrezioni = false
        let quante = s.memoriaVera.lezioni.count
        controlla(LezioniVera.attive.isEmpty && s.correggiRispostaVera(m.id, correzione: "Un'altra lezione") == nil && s.memoriaVera.lezioni.count == quante,
                  "Lezioni: con «Impara dalle correzioni» spento non si usano e non se ne salvano")
    }

    // MARK: - Il filo lungo

    private static func filo(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.dati.impostazioni.vera.finestra = 8_192
        s.clienteAttivoId = "laura"
        var storia = [MessaggioVera(autore: .utente, testo: "Parliamo di Laura: vuole smettere di lavorare a 60 anni e non vuole rischi sulla casa."),
                      MessaggioVera(autore: .vera, testo: "Va bene, la casa resta fuori dai calcoli.")]
        for i in 0..<30 {
            storia.append(MessaggioVera(autore: .utente, testo: "Domanda \(i) " + String(repeating: "lunga ", count: 260)))
            storia.append(MessaggioVera(autore: .vera, testo: "Risposta \(i) " + String(repeating: "lunga ", count: 260)))
        }
        guard let fonte = s.fonteVera("laura") else { return controlla(false, "Filo lungo: il dossier di Laura") }
        let r = RichiestaVera(domanda: "Torniamo a prima: quale ipotesi le conviene?", spunto: nil, fonte: fonte, storia: storia)
        var ambiente = AmbienteVera(cliente: "Laura Moretti")
        let piano = NucleoVera.piano(r, impostazioni: s.dati.impostazioni.vera, ambiente: ambiente)
        let uscite = NucleoVera.uscite(storia, piano: piano)
        controlla(uscite.first?.testo.contains("60 anni") == true, "Filo lungo: le prime battute escono dalla finestra (\(uscite.count) uscite)")
        let riassunto = s.riassuntoVera(chiave: "laura", uscite: uscite) ?? ""
        ambiente.riassunto = riassunto
        let conFilo = NucleoVera.piano(r, impostazioni: s.dati.impostazioni.vera, ambiente: ambiente)
        let ultimo = conFilo.messaggi.last?.testo ?? ""
        controlla(ultimo.contains("IL FILO DELLA CONVERSAZIONE") && ultimo.contains("60 anni") && ultimo.contains("casa"),
                  "Filo lungo: un fatto detto all'inizio arriva a Qwen nel riassunto")
        let totale = conFilo.messaggi.reduce(0) { $0 + NucleoVera.token($1.testo) + 4 }
        controlla(totale <= NucleoVera.finestra, "Filo lungo: con il riassunto si resta nella finestra (\(totale) su \(NucleoVera.finestra))")
        if let ultima = uscite.last {
            s.memoriaVera.aggiornaFilo("laura", FiloVera(riassunto: "Laura: pensione a 60 anni, niente rischi sulla casa.", finoA: ultima.id))
            controlla(s.riassuntoVera(chiave: "laura", uscite: uscite) == "Laura: pensione a 60 anni, niente rischi sulla casa.",
                      "Filo lungo: il riassunto di Qwen copre le battute uscite")
        }
        s.memoriaVera.aggiornaFilo("altro", FiloVera(riassunto: "L'IBAN è IT60X0542811101000000123456", finoA: "x"))
        controlla(s.memoriaVera.filo("altro") == nil, "Filo lungo: un riassunto con un IBAN non entra nella memoria")
        s.nuovaConversazione()
        controlla(s.memoriaVera.filo("laura") == nil, "Filo lungo: «Nuova conversazione» toglie anche il riassunto")
        let m = FiloLungoVera.messaggi(precedente: "Prima", nuove: Array(storia.prefix(2)))
        controlla(m.count == 2 && m[1].testo.contains("RIASSUNTO FIN QUI") && m[1].testo.contains("60 anni"), "Filo lungo: a Qwen il riassunto di prima e le battute nuove")
    }

    // MARK: - Il cliente in 30 secondi

    private static func trenta(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        s.clienteAttivoId = "giulia"
        let noti = s.dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        controlla(TrentaSecondiVera.cliente("Raccontami Marco", clienti: noti, attivo: "giulia") == "marco"
                  && TrentaSecondiVera.cliente("Laura in 30 secondi", clienti: noti, attivo: nil) == "laura"
                  && TrentaSecondiVera.cliente("Parlami di previdenza", clienti: noti, attivo: "giulia") == nil
                  && TrentaSecondiVera.cliente("Chi è il beneficiario della polizza di Marco?", clienti: noti, attivo: "giulia") == nil,
                  "Trenta secondi: «raccontami Marco» e «Laura in 30 secondi» sì, «parlami di previdenza» no")
        _ = s.memoriaVera.ricorda("Marco preferisce le videochiamate al mattino", cliente: "marco", fonte: "in chat")
        guard let fonte = s.fonteVera("marco") else { return controlla(false, "Trenta secondi: il dossier di Marco") }
        let scheda = TrentaSecondiVera.scheda(fonte, messaggi: s.dati.messaggi, ricordi: s.memoriaVera.ricordi)
        controlla(scheda.sezioni.map(\.titolo) == TrentaSecondiVera.titoli && scheda.sezioni.allSatisfy { !$0.fonte.isEmpty && !$0.testo.isEmpty },
                  "Trenta secondi: cinque sezioni fisse, ognuna con la sua fonte")
        controlla(scheda.sezioni[1].testo.contains("Elena") && scheda.sezioni[3].testo.contains("videochiamate"),
                  "Trenta secondi: la famiglia dalla scheda, le preferenze dai ricordi")
        let inventata = TrentaSecondiVera.applica(#"{"chi":"Ha 99 anni e un patrimonio enorme.","famiglia":"Una famiglia unita, con Elena.","deciso":"x","preferisce":"y","sospeso":"z"}"#, a: scheda)
        controlla(inventata.sezioni[0].testo == scheda.sezioni[0].testo && inventata.sezioni[1].testo == "Una famiglia unita, con Elena.",
                  "Trenta secondi: una cifra inventata da Qwen non passa, il resto sì")
        controlla(s.chiediTrentaSecondi("Raccontami Marco", chiave: "giulia") && s.conversazione("giulia").last?.trenta?.clienteId == "marco",
                  "Trenta secondi: nella conversazione arriva la scheda")
    }

    // MARK: - Il codice in tasca

    private static func norme(_ controlla: (Bool, String) -> Void) {
        let pagine = ["CODICE DELLE ASSICURAZIONI PRIVATE\nArt. 176 – Revoca della proposta\nLa proposta può essere revocata fino alla conclusione del contratto.\n",
                      "Art. 177 – Diritto di recesso\n1. Il contraente può recedere dal contratto entro trenta giorni dal momento in cui è informato che il contratto è concluso.\nArt. 177-bis. Ulteriori obblighi\nL'impresa rimborsa il premio entro trenta giorni."]
        let articoli = NormeVera.articoli(pagine, testoId: "t")
        controlla(articoli.map(\.numero) == ["176", "177", "177-bis"] && articoli[1].rubrica == "Diritto di recesso" && articoli[1].pagina == 2,
                  "Norme: il testo diviso per articolo, con rubrica e pagina (\(articoli.map(\.numero).joined(separator: ", ")))")
        let noti = StatoShell(persistente: false).dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        controlla(NormeVera.eUnaDomanda("Entro quanto un cliente può ripensarci dopo aver firmato una polizza vita?", clienti: noti)
                  && !NormeVera.eUnaDomanda("Quanto ha Marco?", clienti: noti)
                  && !NormeVera.eUnaDomanda("Quanto rendono le obbligazioni di Marco?", clienti: noti)
                  && !NormeVera.eUnaDomanda("Come ho impostato il piano di Laura?", clienti: noti),
                  "Norme: riconosce le domande sulle norme, non quelle sui clienti")
        let s = StatoShell(persistente: false)
        let t = s.biblioteca.aggiungi(titolo: "Codice delle assicurazioni private", sigla: "D.Lgs. 209/2005", edizione: "prova", file: "x.pdf", pagine: pagine)
        let pezzi = NormeVera.pezzi([t])
        let trovati = RicercaVera.cerca("entro quanto si può recedere dal contratto?", in: pezzi, quanti: 3)
            .compactMap { x in NormeVera.citazione(x.pezzo.id, in: [t]).map { (x.pezzo, $0) } }
        controlla(trovati.first?.1.numero == "177", "Norme: la ricerca trova l'articolo del recesso")
        controlla(RicercaVera.cerca("Cosa dice l'articolo 176?", in: pezzi, quanti: 1).first?.pezzo.id == t.articoli.first?.id,
                  "Norme: «l'articolo 176» trova l'articolo dal suo numero")
        let senzaArticoli = NormeVera.articoli(["Circolare di prova\nIl questionario si aggiorna ogni tre anni."], testoId: "c")
        controlla(senzaArticoli.first?.numero == "pag. 1", "Norme: un testo senza articoli si cerca pagina per pagina")
        let id = trovati.first?.1.articoloId ?? ""
        let buona = NormeVera.leggi(#"{"risponde":true,"risposta":"Entro trenta giorni dalla conclusione del contratto (art. 177).","articoli":["\#(id)"]}"#, trovati: trovati)
        controlla(buona?.risponde == true && buona?.citazioni.first?.etichetta == "Codice delle assicurazioni private · art. 177", "Norme: la risposta cita l'articolo")
        controlla(NormeVera.leggi(#"{"risponde":true,"risposta":"Entro 45 giorni.","articoli":["\#(id)"]}"#, trovati: trovati) == nil,
                  "Norme: una cifra che non è nell'articolo si scarta")
        controlla(NormeVera.leggi(#"{"risponde":true,"risposta":"Entro trenta giorni.","articoli":["inventato"]}"#, trovati: trovati) == nil,
                  "Norme: senza un articolo vero la risposta non vale")
        let no = s.rispondiNorme(#"{"risponde":false,"risposta":"","articoli":[]}"#, domanda: "Ogni quanto aggiorno il questionario?", trovati: trovati, chiave: "giulia", motore: "Qwen")
        controlla(no.norme?.nonRisponde == true && no.testo.contains("La norma non risponde") && no.testo.contains("3 articoli"),
                  "Norme: se la norma non risponde Vera lo dice, con quanti articoli ha cercato")
        let si = s.rispondiNorme(#"{"risponde":true,"risposta":"Entro trenta giorni.","articoli":["\#(id)"]}"#, domanda: "Entro quanto?", trovati: trovati, chiave: "giulia", motore: "Qwen")
        controlla(si.norme?.citazioni.count == 1, "Norme: nella conversazione la citazione con «Apri l'articolo»")
        if let c = si.norme?.citazioni.first {
            s.apriArticolo(c)
            controlla(s.biblioteca.articoloScelto == c.articoloId && s.aperta(.biblioteca), "Norme: «Apri l'articolo» apre la Biblioteca sull'articolo")
        }
    }

    // MARK: - Lascia cadere qui

    private static func lasciaCadere(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "marco"
        guard let i = s.dati.clienti.firstIndex(where: { $0.id == "giulia" }) else { return controlla(false, "Lascia cadere: Giulia nei dati di prova") }
        s.dati.clienti[i].codiceFiscale = "RSSGLI85M41H501Z"
        let pagine = ["POLIZZA CASA E FAMIGLIA\nContraente: Mario Verdi\nCodice fiscale: RSSGLI85M41H501Z\nData di scadenza: 30/06/2099\nPremio annuo: 480,00 €"]
        let l = LasciaCadereVera.leggi(nomeFile: "polizza.pdf", pagine: pagine, pagineOCR: 0, clienti: s.dati.clienti)
        controlla(l.clienteId == "giulia" && l.come == "dal codice fiscale", "Lascia cadere: il cliente riconosciuto dal codice fiscale")
        let perNome = LasciaCadereVera.cliente(campi: [], pagine: ["Spett.le Laura Moretti, le inviamo l'estratto conto."], clienti: s.dati.clienti)
        controlla(perNome.id == "laura", "Lascia cadere: il cliente riconosciuto dal nome nel documento")

        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("ProvaLasciaCadere-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: cartella) }
        let file = cartella.appendingPathComponent("polizza.pdf")
        try? Data("finto".utf8).write(to: file)
        let documenti = s.dati.documenti.count
        let attivita = s.dati.attivita.count
        let m = s.rispondiDocumentoCaduto(file, pagine: pagine, pagineOCR: 0, chiave: "marco")
        controlla(m.conferma?.origine == .documento && m.conferma?.azioni.map(\.strumento) == [RegistroStrumenti.documentiArchivia, RegistroStrumenti.attivitaNuova]
                  && m.testo.contains("Giulia Rossi") && s.dati.documenti.count == documenti,
                  "Lascia cadere: la scheda con l'archiviazione e il promemoria, niente salvato prima di «Conferma»")
        s.confermaSchedaVera(messaggio: m.id)
        let d = s.dati.documenti.last
        controlla(s.dati.documenti.count == documenti + 1 && d?.clienteId == "giulia" && d?.campi.isEmpty == false && d?.campi.allSatisfy(\.confermato) == true
                  && s.dati.attivita.count == attivita + 1,
                  "Lascia cadere: dopo «Conferma» il documento è nel dossier di Giulia con i dati confermati, e il promemoria in agenda")
        s.annullaSchedaVera(messaggio: m.id)
        controlla(s.dati.documenti.count == documenti && s.dati.attivita.count == attivita, "Lascia cadere: «Annulla» toglie documento e promemoria")
        s.veraPortafoglio = true
        let ignoto = s.rispondiDocumentoCaduto(file, pagine: ["Un documento senza nomi"], pagineOCR: 0, chiave: VeraPortafoglio.chiave)
        controlla(ignoto.conferma == nil && ignoto.testo.contains("non trovo il cliente"), "Lascia cadere: senza cliente riconoscibile Vera lo dice e non archivia")
    }

    // MARK: - Archivio

    private static func archivio(_ controlla: (Bool, String) -> Void) {
        var m = MessaggioVera(autore: .vera, testo: "Marco in 30 secondi.")
        m.voto = true
        m.trenta = SchedaTrentaSecondi(clienteId: "marco", nome: "Marco Bianchi", tema: "", canali: [.alleanza],
                                       sezioni: [SezioneTrenta(titolo: "Chi è", testo: "45 anni.", fonte: "La scheda")], incontri: 2, messaggi: 1, ricordi: 0, documenti: 1)
        m.norme = RispostaNorme(citazioni: [CitazioneNorma(testoId: "t", articoloId: "t-art-177", titolo: "Codice", sigla: "", edizione: "prova",
                                                           numero: "177", rubrica: "", pagina: 2)], nonRisponde: false, articoliCercati: 3, testiCercati: 1)
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let letto = (try? e.encode(m)).flatMap { try? d.decode(MessaggioVera.self, from: $0) }
        controlla(letto?.voto == true && letto?.trenta == m.trenta && letto?.norme == m.norme, "Archivio: voto, 30 secondi e citazioni tornano uguali")
    }
}
