import Foundation

/// Prova del copilota dell'incontro dentro `Prisma --prova-vera` (Orizzonte, giro 5): istruzioni e schema nel
/// pacchetto, le regole locali sulle conversazioni di Vera/Esempi/copilota.json (schede, cifre, parole da illuminare),
/// le risposte di un Qwen finto con il JSON dello schema (cifre inventate scartate), il consenso (senza, il copilota
/// non parte), niente nel dossier senza conferma (poi una scheda, tutte, e la seconda volta niente), l'archivio senza
/// trascrizione e i messaggi nuovi del ponte cifrato (schede dall'iPad, testo inquadrato dall'iPhone).
enum ProvaCopilota {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        let esempi = leggiEsempi()
        controlla(esempi != nil, "Copilota: esempi nel pacchetto (Vera/Esempi/copilota.json)")
        if let esempi {
            regole(esempi, controlla)
            qwenEsempi(esempi, controlla)
        }
        riconoscitore(controlla)
        consenso(controlla)
        conferma(controlla)
        archivio(controlla)
        modelloFinto(controlla)
        ponte(controlla)
        // La schermata del copilota (Shell/ProvaVistaCopilota.swift): testi, evidenze, dialogo di prova, verbale
        ProvaVistaCopilota.esegui(controlla)
    }

    // MARK: - Istruzioni, schema, esempi

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let istruzioni = IstruzioniVera.testo("copilota") ?? ""
        controlla(istruzioni.contains("JSON") && istruzioni.contains("schede") && istruzioni.contains("niente cifre inventate"),
                  "Copilota: istruzioni di Qwen nel pacchetto (Vera/Istruzioni/copilota.md), solo JSON e niente cifre inventate")
        let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/copilota.json")
        let file = url.flatMap { try? Data(contentsOf: $0) }.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
        controlla(file != nil, "Copilota: schema JSON nel pacchetto (Vera/Schemi/copilota.json)")
        guard let file else { return }
        func voce(_ s: [String: Any]) -> [String: Any] {
            (((s["properties"] as? [String: Any])?["schede"] as? [String: Any])?["items"] as? [String: Any]) ?? [:]
        }
        func chiavi(_ s: [String: Any]) -> Set<String> { Set(((s["properties"] as? [String: Any]) ?? [:]).keys) }
        func richiesti(_ s: [String: Any]) -> Set<String> { Set((s["required"] as? [String]) ?? []) }
        func elenco(_ s: [String: Any], _ k: String) -> [String] {
            (((s["properties"] as? [String: Any])?[k] as? [String: Any])?["enum"] as? [String]) ?? []
        }
        let interno = RiconoscitoreCopilota.schemaInterno
        let uguali = richiesti(file) == richiesti(interno) && chiavi(voce(file)) == chiavi(voce(interno))
            && richiesti(voce(file)) == richiesti(voce(interno))
            && ["tipo", "area", "frequenza", "propensione", "evento"].allSatisfy { elenco(voce(file), $0) == elenco(voce(interno), $0) }
        controlla(uguali && richiesti(voce(file)) == ["tipo", "frase"],
                  "Copilota: lo schema della cartella coincide con quello nel codice (campi \(chiavi(voce(file)).sorted().joined(separator: ", ")))")
        // Le aree, i tipi di evento e le frequenze dello schema sono quelli di Prisma
        controlla(elenco(voce(interno), "area").filter { $0 != "nessuna" }.allSatisfy { AreaBisogno(rawValue: $0) != nil }
                  && elenco(voce(interno), "evento").filter { $0 != "nessuno" }.allSatisfy { EventoLineaVita.Tipo(rawValue: $0) != nil }
                  && elenco(voce(interno), "frequenza").filter { $0 != "nessuna" }.allSatisfy { Frequenza(rawValue: $0) != nil },
                  "Copilota: aree, eventi e frequenze dello schema sono quelli dell'archivio")
    }

    private static var oggi: Date { AiutiProva.data(2026, 11, 4) }

    private static func leggiEsempi() -> [String: Any]? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Esempi/copilota.json"),
              let d = try? Data(contentsOf: url), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              j["conversazioni"] is [[String: Any]] else { return nil }
        return j
    }

    /// nil se la scheda è come attesa; altrimenti cosa non torna.
    static func confronta(_ s: SchedaCopilota?, _ atteso: [String: Any]) -> String? {
        guard let s else { return "manca" }
        var diversi: [String] = []
        if let t = atteso["tipo"] as? String, s.tipo.rawValue != t { diversi.append("tipo \(s.tipo.rawValue)") }
        if let a = atteso["azione"] as? String, s.azione.rawValue != a { diversi.append("azione \(s.azione.rawValue)") }
        if let t = atteso["titolo"] as? String, s.titolo != t { diversi.append("titolo «\(s.titolo)»") }
        let c = s.cifre
        let giorno = DateFormatter()
        giorno.calendar = Calendar(identifier: .gregorian)
        giorno.dateFormat = "yyyy-MM-dd"
        for (k, v) in (atteso["cifre"] as? [String: Any]) ?? [:] {
            let n = (v as? NSNumber)?.doubleValue
            let testo = v as? String
            let ok: Bool
            switch k {
            case "importo": ok = n == c.importo
            case "importi": ok = (v as? [NSNumber])?.map(\.doubleValue) == c.importi
            case "frequenza": ok = testo == c.frequenza?.rawValue
            case "anniDaOggi": ok = n.map { Int($0) } == c.anniDaOggi
            case "anno": ok = n.map { Int($0) } == c.anno
            case "mese": ok = n.map { Int($0) } == c.mese
            case "area": ok = testo == c.area?.rawValue
            case "propensione": ok = testo == c.propensione?.rawValue
            case "tipoPolizza": ok = testo == c.tipoPolizza
            case "compagnia": ok = testo == c.compagnia
            case "evento": ok = testo == c.evento?.rawValue
            case "scadenza": ok = testo == c.scadenza.map { giorno.string(from: $0) }
            default: ok = false
            }
            if !ok { diversi.append("\(k) diverso") }
        }
        return diversi.isEmpty ? nil : diversi.joined(separator: ", ")
    }

    private static func regole(_ e: [String: Any], _ controlla: (Bool, String) -> Void) {
        for conv in (e["conversazioni"] as? [[String: Any]]) ?? [] {
            let titolo = conv["titolo"] as? String ?? "conversazione"
            let aree = ((conv["obiettiviNelDossier"] as? [String]) ?? []).compactMap(AreaBisogno.init(rawValue:))
            let obiettivi = aree.map { Obiettivo(clienteId: "prova", titolo: "Obiettivo di prova", area: $0, importo: 1_000, scadenza: oggi) }
            var contesto = ContestoCopilota(obiettivi: obiettivi, oggi: oggi)
            var sessione: [SchedaCopilota] = []
            for (n, p) in ((conv["pezzi"] as? [[String: Any]]) ?? []).enumerated() {
                let testo = p["testo"] as? String ?? ""
                let esito = RiconoscitoreCopilota.leggi(testo, pezzoId: "pezzo-\(n)", contesto: &contesto)
                let attese = (p["attese"] as? [[String: Any]]) ?? []
                let idAttesi = Set(attese.compactMap { $0["id"] as? String })
                let trovati = Set(esito.schede.map(\.id))
                let difetti = attese.compactMap { a -> String? in
                    let id = a["id"] as? String ?? ""
                    return confronta(esito.schede.first { $0.id == id }, a).map { "\(id): \($0)" }
                }
                controlla(trovati == idAttesi && difetti.isEmpty && esito.schede.allSatisfy { $0.stato == .proposta && $0.origine == .regole },
                          "Copilota, regole (\(titolo)): «\(testo.prefix(60))» → " + (trovati.isEmpty ? "nessuna scheda" : trovati.sorted().joined(separator: ", "))
                            + (difetti.isEmpty ? "" : " [\(difetti.joined(separator: "; "))]"))
                if let evidenze = p["evidenze"] as? [String] {
                    let lette = esito.evidenze.compactMap { $0.testo(in: testo) }
                    controlla(lette == evidenze, "Copilota, parole da illuminare: «\(lette.joined(separator: "», «"))»")
                }
                sessione = RiconoscitoreCopilota.unisci(sessione, esito.schede)
            }
            let finali = (conv["finali"] as? [[String: Any]]) ?? []
            let difetti = finali.compactMap { a -> String? in
                let id = a["id"] as? String ?? ""
                return confronta(sessione.first { $0.id == id }, a).map { "\(id): \($0)" }
            }
            controlla(Set(sessione.map(\.id)) == Set(finali.compactMap { $0["id"] as? String }) && difetti.isEmpty,
                      "Copilota (\(titolo)): \(sessione.count) schede alla fine, la stessa cosa detta due volte è una scheda sola"
                        + (difetti.isEmpty ? "" : " [\(difetti.joined(separator: "; "))]"))
        }
    }

    private static func qwenEsempi(_ e: [String: Any], _ controlla: (Bool, String) -> Void) {
        for q in (e["qwen"] as? [[String: Any]]) ?? [] {
            let pezzo = q["pezzo"] as? String ?? ""
            let risposta = q["risposta"] as? [String: Any] ?? [:]
            let voci = (risposta["schede"] as? [Any])?.count ?? 0
            let json = String(data: (try? JSONSerialization.data(withJSONObject: risposta)) ?? Data(), encoding: .utf8) ?? ""
            let contesto = ContestoCopilota(oggi: oggi)
            let letto = RiconoscitoreCopilota.leggiJSON("Ecco le schede:\n```json\n" + json + "\n```", pezzo: pezzo, pezzoId: "p", contesto: contesto)
            let attese = Set((q["attese"] as? [String]) ?? [])
            let scartate = (q["scartate"] as? Int) ?? 0
            controlla(letto != nil && Set(letto?.map(\.id) ?? []) == attese && voci - (letto?.count ?? 0) == scartate
                      && (letto ?? []).allSatisfy { $0.origine == .qwen && $0.stato == .proposta },
                      "Copilota, JSON di Qwen: «\(pezzo.prefix(50))» → \((letto ?? []).map(\.id).joined(separator: ", "))"
                        + (scartate > 0 ? " (\(scartate) scartata: cifra o frase che non è nel pezzo)" : ""))
            if let conRegole = q["conRegole"] as? [String] {
                var c = contesto
                let r = RiconoscitoreCopilota.leggi(pezzo, pezzoId: "p", contesto: &c).schede
                let unite = RiconoscitoreCopilota.conQwen(regole: r, modello: letto ?? [])
                controlla(Set(unite.map(\.id)) == Set(conRegole),
                          "Copilota, Qwen e regole insieme: le regole vincono, Qwen aggiunge quello che manca (\(unite.map(\.id).joined(separator: ", ")))")
            }
        }
        controlla(RiconoscitoreCopilota.leggiJSON("Non saprei.", pezzo: "x", contesto: ContestoCopilota()) == nil,
                  "Copilota: una risposta senza JSON non si legge")
        // Sulle stesse cose vincono le cifre delle regole; Qwen riempie solo i campi che le regole lasciano vuoti
        // (le cifre di Qwen che la frase non dice sono già scartate da leggiJSON, provato sopra)
        let pezzo = "Vorremmo comprare casa tra tre anni, ci servono circa 40.000 euro di anticipo."
        var c = ContestoCopilota(oggi: oggi)
        let r = RiconoscitoreCopilota.leggi(pezzo, contesto: &c).schede
        var qwen = r
        if !qwen.isEmpty { qwen[0].cifre.importo = 45_000; qwen[0].cifre.mese = 6 }
        let unite = RiconoscitoreCopilota.conQwen(regole: r, modello: qwen)
        let meseVuotoPerLeRegole = r.first?.cifre.mese == nil
        controlla(unite.first?.cifre.importo == 40_000 && unite.count == 1
                  && unite.first?.cifre.mese == (meseVuotoPerLeRegole ? 6 : r.first?.cifre.mese),
                  "Copilota: sulla stessa scheda vincono le regole, Qwen completa solo i campi vuoti")
    }

    // MARK: - Il riconoscitore

    private static func riconoscitore(_ controlla: (Bool, String) -> Void) {
        let f = RiconoscitoreCopilota.frasi("Costa 40.000 euro. Va bene? Sì certo… anzi no")
        controlla(f.count == 4 && f[0].testo == "Costa 40.000 euro" && f[1].domanda && !f[0].domanda && f[3].inizio == 38,
                  "Copilota: le frasi si spezzano a fine frase, mai dentro «40.000», con la domanda riconosciuta")
        let originale = "Perché è così l’anticipo"
        controlla(RiconoscitoreCopilota.semplice(originale).count == originale.count && RiconoscitoreCopilota.semplice(originale) == "perche e cosi l'anticipo",
                  "Copilota: il testo semplice ha gli stessi caratteri dell'originale (gli intervalli valgono su tutti e due)")
        let i = RiconoscitoreCopilota.importi("40 mila euro e poi € 90 al mese")
        controlla(i.count == 2 && i[0].valori == [40_000] && i[1].valori == [90] && i[1].frequenza == .mensile,
                  "Copilota: importi all'italiana («40 mila euro», «€ 90 al mese»)")
        controlla(RiconoscitoreCopilota.importi("ho 45 anni e nel 2030 vado in pensione").isEmpty,
                  "Copilota: un'età o un anno senza euro non sono importi")
        let t = RiconoscitoreCopilota.tempi("tra tre anni, anzi tra quattro anni, poi a giugno del 2027", annoOggi: 2026)
        controlla(t.count == 3 && t[0].anniDaOggi == 3 && t[1].anniDaOggi == 4 && t[2].anno == 2027 && t[2].mese == 6,
                  "Copilota: tempi in lettere, la correzione e il mese con l'anno")
        controlla(IntervalloTesto.unisci([IntervalloTesto(5, 9), IntervalloTesto(0, 3), IntervalloTesto(2, 4)]) == [IntervalloTesto(0, 4), IntervalloTesto(5, 9)],
                  "Copilota: le parole da illuminare in ordine, quelle che si toccano fuse")
        // L'avviso dopo la conferma
        controlla(ApplicaCopilota.avviso(EsitoCopilota(modifiche: 4, attivita: 2)) == "4 modifiche e 2 attività"
                  && ApplicaCopilota.avviso(EsitoCopilota(modifiche: 1, attivita: 1)) == "1 modifica e 1 attività"
                  && ApplicaCopilota.avviso(EsitoCopilota(modifiche: 4, attivita: 0)) == "4 modifiche",
                  "Copilota: l'avviso dice quante modifiche e attività sono entrate nel dossier")
    }

    // MARK: - Consenso

    private static func consenso(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        controlla(s.cliente("giulia")?.consensoCopilota == nil && GuardiaCopilota.motivoBlocco(s.cliente("giulia")) != nil
                  && GuardiaCopilota.motivoBlocco(nil) == GuardiaCopilota.senzaCliente,
                  "Copilota: senza consenso registrato la guardia dice di no («\(GuardiaCopilota.motivoBlocco(s.cliente("giulia")) ?? "")»)")
        let prima = s.dati.sessioniCopilota.count
        controlla(s.avviaSessioneCopilota(clienteId: "giulia") == nil && s.dati.sessioniCopilota.count == prima
                  && SessioneCopilota.nuova(cliente: s.cliente("giulia")) == nil,
                  "Copilota: senza consenso non parte (nessuna sessione)")
        s.registraConsensoCopilota(clienteId: "giulia", modo: .scritto, nota: "Nota di prova", data: Date().addingTimeInterval(3_600))
        controlla(s.avviaSessioneCopilota(clienteId: "giulia") == nil, "Copilota: un consenso con la data nel futuro non vale")
        s.registraConsensoCopilota(clienteId: "giulia", modo: .aVoce, nota: "Nota di prova", data: Date().addingTimeInterval(-60))
        let id = s.avviaSessioneCopilota(clienteId: "giulia")
        controlla(id != nil && s.sessioneCopilota(id ?? "")?.consenso.modo == .aVoce && s.sessioneCopilota(id ?? "")?.consenso.nota == "Nota di prova"
                  && s.avviaSessioneCopilota(clienteId: "giulia") == id,
                  "Copilota: con il consenso parte, e la sessione ricorda il consenso di quel giorno; riavviando continua la stessa")
        s.revocaConsensoCopilota(clienteId: "giulia")
        controlla(s.ascoltaPezzoCopilota("Vorremmo comprare casa tra tre anni.", sessione: id ?? "").isEmpty
                  && s.sessioneCopilota(id ?? "")?.aperta == false && s.sessioneCopilota(id ?? "")?.trascrizione.isEmpty == true,
                  "Copilota: tolto il consenso la sessione si chiude e non ascolta più")
    }

    // MARK: - Niente nel dossier senza conferma

    static let dialogo = [
        "Buongiorno Giulia, avete pensato a quali progetti avete?",
        "Vorremmo comprare casa tra tre anni, ci servono circa 40.000 euro di anticipo.",
        "Ha già qualche polizza vita?",
        "Sì, una vita intera con un'altra compagnia, pago circa 90 euro al mese.",
        "Però i soldi della casa non voglio rischiarli…",
        "E a giugno del 2027 ci sposiamo.",
        "Perfetto, ti preparo un confronto con 450, 550 e 650 euro al mese.",
    ]

    private static func conferma(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.registraConsensoCopilota(clienteId: "giulia", modo: .aVoce, data: Date().addingTimeInterval(-60))
        guard let sid = s.avviaSessioneCopilota(clienteId: "giulia") else { return controlla(false, "Copilota: sessione di prova") }
        let obiettivi = s.dati.obiettivi, posizioni = s.dati.posizioni, attivita = s.dati.attivita
        let eventi = s.dati.eventiVita, note = s.dati.note, profilo = s.cliente("giulia")?.profilo
        for frase in dialogo { s.ascoltaPezzoCopilota(frase, sessione: sid) }
        let sessione = s.sessioneCopilota(sid)
        controlla(sessione?.schede.count == 6 && sessione?.schede.allSatisfy { $0.stato == .proposta } == true
                  && sessione?.trascrizione.count == dialogo.count,
                  "Copilota: il dialogo di prova dà 6 schede proposte (\(sessione?.schede.map(\.id).joined(separator: ", ") ?? ""))")
        controlla(s.dati.obiettivi == obiettivi && s.dati.posizioni == posizioni && s.dati.attivita == attivita
                  && s.dati.eventiVita == eventi && s.dati.note == note,
                  "Copilota: niente entra nel dossier senza conferma")
        controlla(sessione?.scheda("obiettivo-casa")?.azione == .aggiornaObiettivo
                  && sessione?.scheda("obiettivo-casa")?.obiettivoId == "obiettivo-giulia-casa",
                  "Copilota: Giulia ha già l'obiettivo casa, la scheda propone «Aggiorna l’obiettivo»")

        // Una scheda sola
        let uno = s.confermaSchedeCopilota(["evento-matrimonio"], sessione: sid)
        let evento = s.dati.eventiVita.first { $0.clienteId == "giulia" && $0.origine == .copilota }
        controlla(uno == EsitoCopilota(modifiche: 1, attivita: 0) && evento?.tipo == .matrimonio && evento?.anno == 2027
                  && (evento?.nota ?? "").contains("giugno 2027") && s.dati.obiettivi == obiettivi,
                  "Copilota: confermata una scheda, entra solo quella (il matrimonio nella linea della vita, origine copilota)")
        // Tutte le altre
        let resto = s.confermaSchedeCopilota(nil, sessione: sid)
        controlla(resto == EsitoCopilota(modifiche: 3, attivita: 2), "Copilota: «Conferma tutto» porta le altre: \(ApplicaCopilota.avviso(resto))")
        let casa = s.dati.obiettivi.first { $0.id == "obiettivo-giulia-casa" }
        controlla(casa?.importo == 40_000 && s.dati.obiettivi.count == obiettivi.count,
                  "Copilota: l'obiettivo casa aggiornato a 40.000 € (nessun doppione)")
        let nuova = s.dati.posizioni.first { $0.clienteId == "giulia" && !posizioni.contains($0) }
        controlla(nuova?.frequenza == .mensile && nuova?.premio == 90 && nuova?.premioAnnuo == 1_080 && nuova?.emittente == "Altra compagnia"
                  && nuova?.canale == .indipendente && nuova?.stato == .inEssere && nuova?.area == .protezione,
                  "Copilota: la vita intera dell'altra compagnia in Posizioni, 90 € al mese (1.080 € l'anno)")
        let annotazione = s.dati.note.first { $0.clienteId == "giulia" && !note.contains($0) }
        controlla((annotazione?.testo ?? "").contains("non profilo MiFID") && s.cliente("giulia")?.profilo == profilo,
                  "Copilota: il timore è un'annotazione nel taccuino, il profilo del questionario non cambia")
        controlla(s.dati.attivita.count == attivita.count + 2 && s.sessioneCopilota(sid)?.attivitaCreate.count == 2
                  && s.dati.attivita.contains { $0.titolo == "Chiedere la polizza vita intera per il confronto" },
                  "Copilota: due attività create (la polizza da chiedere e il confronto), senza scadenze inventate")
        // La seconda volta niente
        let ancora = s.confermaSchedeCopilota(nil, sessione: sid)
        controlla(ancora.vuoto && s.dati.attivita.count == attivita.count + 2 && s.dati.posizioni.count == posizioni.count + 1,
                  "Copilota: una seconda conferma non duplica niente")
        // Una scheda scartata non entra
        s.ascoltaPezzoCopilota("Mia figlia andrà all'università nel 2031.", sessione: sid)
        s.scartaSchedaCopilota("evento-studi", sessione: sid)
        controlla(s.confermaSchedeCopilota(nil, sessione: sid).vuoto && !s.dati.eventiVita.contains { $0.tipo == .studi && $0.clienteId == "giulia" && $0.origine == .copilota },
                  "Copilota: una scheda scartata non entra nel dossier")
        // Il verbale e la trascrizione che non si conserva
        s.chiudiSessioneCopilota(sid, conservaTrascrizione: false)
        let chiusa = s.sessioneCopilota(sid)
        controlla(chiusa?.verbale?.punti.count == 4 && chiusa?.verbale?.attivita.count == 2 && chiusa?.verbale?.dossier.count == 4
                  && chiusa?.trascrizione.isEmpty == true && chiusa?.schede.allSatisfy { $0.frase.isEmpty && $0.evidenze.isEmpty } == true
                  && chiusa?.aperta == false,
                  "Copilota: verbale con 4 punti, 2 attività e 4 voci del dossier; senza «Conserva la trascrizione» resta solo il verbale")
        controlla(s.ascoltaPezzoCopilota("Vorremmo comprare casa tra due anni.", sessione: sid).isEmpty,
                  "Copilota: una sessione chiusa non ascolta più")
    }

    // MARK: - L'archivio: la trascrizione solo se si conserva

    private static func archivio(_ controlla: (Bool, String) -> Void) {
        let consenso = ConsensoCopilota(data: Date(timeIntervalSinceReferenceDate: 815_000_000), modo: .scritto, nota: "Firmato")
        var s = SessioneCopilota(clienteId: "giulia", data: Date(timeIntervalSinceReferenceDate: 815_000_100), consenso: consenso)
        var c = ContestoCopilota(oggi: oggi)
        let frase = "Vorremmo comprare casa tra tre anni, ci servono circa 40.000 euro di anticipo."
        let esito = RiconoscitoreCopilota.leggi(frase, contesto: &c)
        s.trascrizione = [PezzoTrascrizione(testo: frase, quando: Date(timeIntervalSinceReferenceDate: 815_000_200), evidenze: esito.evidenze)]
        s.schede = esito.schede
        let senza = (try? Archivio.codificatore.encode(s)).map { String(decoding: $0, as: UTF8.self) } ?? ""
        let letta = (try? Archivio.decodificatore.decode(SessioneCopilota.self, from: Data(senza.utf8)))
        controlla(!senza.isEmpty && !senza.contains("anticipo") && !senza.contains("\"trascrizione\"") && letta?.trascrizione.isEmpty == true
                  && letta?.schede.count == 1 && letta?.schede.first?.frase.isEmpty == true && letta?.schede.first?.cifre.importo == 40_000,
                  "Copilota: senza «Conserva la trascrizione» il testo del cliente non si scrive nell'archivio (restano schede e cifre)")
        s.conservaTrascrizione = true
        let con = (try? Archivio.codificatore.encode(s)) ?? Data()
        let riletta = try? Archivio.decodificatore.decode(SessioneCopilota.self, from: con)
        controlla(riletta == s && riletta?.trascrizione.first?.evidenze.count == 2,
                  "Copilota: con «Conserva la trascrizione» la sessione torna uguale (testo, schede, parole da illuminare)")
        controlla(!String(decoding: con, as: UTF8.self).lowercased().contains("audio"), "Copilota: nell'archivio solo testo, niente audio")
    }

    // MARK: - Qwen finto

    private static func modelloFinto(_ controlla: (Bool, String) -> Void) {
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.protocolClasses = [ServerFintoScenari.self]
        let sessione = URLSession(configuration: configurazione)
        let vera = ImpostazioniVera()
        let motore = MotoreLocale(vera, disponibilita: .pronto, sessione: sessione)
        let pezzo = "Sì, una vita intera con un'altra compagnia, pago circa 90 euro al mese."
        let json = #"{"schede":[{"tipo":"polizza","frase":"Sì, una vita intera con un'altra compagnia, pago circa 90 euro al mese","tipoPolizza":"vita intera","compagnia":"","importo":90,"frequenza":"mensile"},{"tipo":"attivita","frase":"pago circa 90 euro al mese","attivita":"Chiedere il contratto della polizza da 95 euro"}]}"#
        ServerFintoScenari.prepara([json])
        let contesto = ContestoCopilota(oggi: oggi)
        let messaggi = RiconoscitoreCopilota.messaggi(pezzo: pezzo, contesto: contesto, cliente: "Cliente di prova")
        let r = aspetta { try? await motore.scrivi(messaggi, opzioni: RiconoscitoreCopilota.opzioni(vera)).testo }
        let ricevuto = ServerFintoScenari.ultimo
        let sistema = ((ricevuto["messages"] as? [[String: Any]])?.first?["content"] as? String) ?? ""
        let utente = ((ricevuto["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        let formato = ricevuto["format"] as? [String: Any]
        controlla(sistema.contains("schede") && utente.contains(pezzo) && utente.contains("anno in corso 2026")
                  && (formato?["required"] as? [String]) == ["schede"] && (ricevuto["think"] as? Bool) == false,
                  "Copilota, Qwen finto: la richiesta porta istruzioni, contesto, pezzo e lo schema in «format»")
        let letto = r.flatMap { RiconoscitoreCopilota.leggiJSON($0, pezzo: pezzo, pezzoId: "p", contesto: contesto) }
        controlla(letto?.count == 1 && letto?.first?.id == "polizzaEsterna-vita-intera" && letto?.first?.cifre.importo == 90
                  && letto?.first?.cifre.frequenza == .mensile && letto?.first?.origine == .qwen && letto?.first?.cifre.compagnia == nil,
                  "Copilota, Qwen finto: il JSON in streaming ricomposto; l'attività con un numero che non è nella frase scartata")
        // Qwen non pronto: restano le regole, nessuna richiesta
        let s = StatoShell(persistente: false)
        s.disponibilitaLocale = .nonDisponibile("Ollama non risponde sul Mac.")
        s.registraConsensoCopilota(clienteId: "giulia", modo: .aVoce, data: Date().addingTimeInterval(-60))
        if let sid = s.avviaSessioneCopilota(clienteId: "giulia") {
            let schede = s.ascoltaPezzoCopilota(pezzo, sessione: sid)
            let pid = s.sessioneCopilota(sid)?.trascrizione.last?.id ?? ""
            s.riconosciConQwenCopilota(pezzo: pid, sessione: sid)
            controlla(schede.count == 2 && s.sessioneCopilota(sid)?.schede.count == 2 && !s.veraInCorso,
                      "Copilota: Vera non è pronta, Prisma riconosce con le sue regole")
        } else {
            controlla(false, "Copilota: sessione senza Qwen")
        }
    }

    // MARK: - Il ponte

    private static func ponte(_ controlla: (Bool, String) -> Void) {
        let codice = PonteVera.nuovoCodice()
        guard let k = PonteVera.chiave(codice), let altra = PonteVera.chiave(PonteVera.nuovoCodice()) else {
            return controlla(false, "Ponte, copilota: chiave dal codice")
        }
        let adesso = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
        var scheda = SchedaCopilota(id: "evento-matrimonio", tipo: .evento, titolo: "Matrimonio · a giugno 2027", azione: .aggiungiLineaVita,
                                    frase: "E a giugno del 2027 ci sposiamo")
        scheda.cifre.evento = .matrimonio
        scheda.cifre.anno = 2027
        scheda.cifre.mese = 6
        // Dall'iPad arriva «confermata»: il Mac la deve rimettere tra le proposte
        scheda.stato = .confermata
        let pacchetto = SchedeCopilotaPonte(clienteId: "giulia", dispositivo: "iPad di prova", quando: adesso,
                                            pezzi: [PezzoTrascrizione(testo: "E a giugno del 2027 ci sposiamo.", quando: adesso, chi: .cliente)],
                                            schede: [scheda])
        let arrivo = ArrivoPonte.schedeCopilota(pacchetto)
        let sigillata = (try? arrivo.busta(k)) ?? Data()
        let busta = BustaPonte.apri(sigillata, k)
        controlla(busta?.versione == PonteVera.versioneProtocollo && busta?.percorso == BustaPonte.copilota && busta.flatMap(ArrivoPonte.leggi) == arrivo,
                  "Ponte, copilota: le schede dell'iPad si sigillano e si riaprono uguali (protocollo \(PonteVera.versioneProtocollo))")
        controlla(BustaPonte.apri(sigillata, altra) == nil && !String(decoding: sigillata, as: UTF8.self).contains("sposiamo"),
                  "Ponte, copilota: con un altro codice non si apre, e il testo non si legge in chiaro")
        // Compatibilità: le buste di prima (senza versione) si leggono ancora
        let vecchia = try? JSONDecoder().decode(BustaPonte.self, from: Data(#"{"quando":1000,"percorso":"api/chat"}"#.utf8))
        controlla(vecchia?.versione == nil && vecchia?.percorso == "api/chat" && vecchia.flatMap(ArrivoPonte.leggi) == nil,
                  "Ponte: una busta di un telefono di prima (senza versione) resta valida per Qwen")
        // Limiti e corpi sbagliati
        let righe = [RigaLetta(testo: "Contraente: Anna Verdi", riquadro: RiquadroPagina(x: 0.1, y: 0.2, larghezza: 0.5, altezza: 0.03)),
                     RigaLetta(testo: "Premio: 90,00 € al mese", riquadro: RiquadroPagina(x: 0.1, y: 0.26, larghezza: 0.4, altezza: 0.03))]
        let inquadratura = InquadraturaPonte(dispositivo: "iPhone di prova", quando: adesso, righe: righe, campi: MotoreInquadra.leggi(righe).campi)
        let enorme = InquadraturaPonte(dispositivo: "iPhone di prova", quando: adesso,
                                       righe: Array(repeating: RigaLetta(testo: "riga"), count: PonteVera.massimoRighe + 1))
        let troppe = BustaPonte(quando: adesso.timeIntervalSince1970, percorso: BustaPonte.inquadra, corpo: try? JSONEncoder().encode(enorme))
        let scambiata = BustaPonte(quando: adesso.timeIntervalSince1970, percorso: BustaPonte.copilota, corpo: try? JSONEncoder().encode(inquadratura))
        controlla(ArrivoPonte.leggi(troppe) == nil && ArrivoPonte.leggi(scambiata) == nil && inquadratura.campi.count == 2,
                  "Ponte: oltre i limiti, o con il corpo di un altro messaggio, il Mac non legge niente")
        #if os(macOS)
        server(codice: codice, arrivo: arrivo, inquadratura: inquadratura, controlla)
        #endif
        // Sul Mac: senza consenso le schede dell'iPad non entrano; con il consenso entrano come proposte
        let s = StatoShell(persistente: false)
        let posizioni = s.dati.posizioni, eventi = s.dati.eventiVita
        controlla(!s.riceviDalPonte(arrivo).accettato && s.dati.sessioniCopilota.isEmpty,
                  "Ponte, copilota: senza il consenso del cliente le schede dell'iPad non entrano")
        s.registraConsensoCopilota(clienteId: "giulia", modo: .scritto, data: Date().addingTimeInterval(-60))
        let ricevuta = s.riceviDalPonte(arrivo)
        let aperta = s.sessioneCopilotaAperta(clienteId: "giulia")
        controlla(ricevuta.accettato && aperta?.schede.count == 1 && aperta?.schede.first?.stato == .proposta
                  && aperta?.schede.first?.dispositivo == "iPad di prova" && aperta?.trascrizione.first?.dispositivo == "iPad di prova"
                  && aperta?.trascrizione.first?.chi == .cliente && s.dati.eventiVita == eventi,
                  "Ponte, copilota: con il consenso le schede dell'iPad entrano nella sessione come proposte, non nel dossier")
        let ripetuta = s.riceviDalPonte(arrivo)
        controlla(ripetuta.accettato && s.sessioneCopilotaAperta(clienteId: "giulia")?.trascrizione.count == 1
                  && s.sessioneCopilotaAperta(clienteId: "giulia")?.schede.count == 1,
                  "Ponte, copilota: lo stesso messaggio due volte non raddoppia niente")
        // Il testo inquadrato: aspetta in arrivo, poi diventa un documento da confermare
        controlla(s.riceviDalPonte(.inquadratura(inquadratura)).accettato && s.inquadratureInArrivo.count == 1,
                  "Ponte, inquadra: il testo dell'iPhone arriva sul Mac e aspetta il consulente")
        let documento = s.documentoDaInquadratura(inquadratura.id, clienteId: "giulia")
        controlla(documento?.campi.contains { $0.chiave == .premio && !$0.confermato } == true && s.inquadratureInArrivo.isEmpty
                  && s.dati.posizioni == posizioni,
                  "Ponte, inquadra: il documento nasce con i dati da confermare, Posizioni non cambia")
    }

    #if os(macOS)
    /// Il server vero del Mac su 127.0.0.1, con il telefono che manda le schede e il testo inquadrato.
    private static func server(codice: String, arrivo: ArrivoPonte, inquadratura: InquadraturaPonte, _ controlla: (Bool, String) -> Void) {
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.protocolClasses = [ServerFinto.self]
        let finta = URLSession(configuration: configurazione)
        var vera = ImpostazioniVera()
        vera.ponte.condividi = true
        vera.ponte.codice = codice
        let server = ServerPonteVera()
        let raccolta = RaccoltaArrivi()
        server.consegnaArrivi { (a: ArrivoPonte) async -> RicevutaPonte in
            raccolta.aggiungi(a)
            return .accettata()
        }
        server.aggiorna(vera, sessione: finta, porta: 0, annuncia: false)
        let scadenza = Date().addingTimeInterval(5)
        while server.porta == nil && Date() < scadenza { Thread.sleep(forTimeInterval: 0.05) }
        guard let porta = server.porta else { return controlla(false, "Ponte, copilota: il server del Mac ascolta") }
        defer { server.ferma() }
        let rete = URLSession(configuration: .ephemeral)
        let ipad = FornitorePonte(indirizzo: "http://127.0.0.1:\(porta)", codice: codice, tipo: .ollama, modello: "qwen3.5:4b", sessione: rete)
        let estraneo = FornitorePonte(indirizzo: "http://127.0.0.1:\(porta)", codice: PonteVera.nuovoCodice(), tipo: .ollama, modello: "qwen3.5:4b", sessione: rete)
        let (stato, buona, rifiutata) = aspetta { (await ipad.stato(), await ipad.manda(arrivo), await estraneo.manda(arrivo)) }
        controlla(stato?.versione == PonteVera.versioneProtocollo && stato?.riceveMessaggiNuovi == true,
                  "Ponte: il Mac dice la sua versione del protocollo (\(stato?.versione ?? 0))")
        controlla(buona.accettato && raccolta.elenco == [arrivo], "Ponte, copilota: l'iPad manda le schede al Mac, cifrate, e il Mac le riceve")
        controlla(!rifiutata.accettato && raccolta.elenco.count == 1, "Ponte, copilota: con il codice sbagliato il Mac non riceve niente")
        let foto = aspetta { await ipad.manda(.inquadratura(inquadratura)) }
        controlla(foto.accettato && raccolta.elenco.last == .inquadratura(inquadratura),
                  "Ponte, inquadra: l'iPhone manda al Mac il testo letto con le posizioni dei campi")
        // Un corpo non valido sul percorso nuovo: 400, niente consegnato
        let codiceRisposta: Int = aspetta { () async -> Int in
            guard let r = try? ipad.busta(BustaPonte.copilota, corpo: Data("{}".utf8), attesa: 5),
                  case let (_, risposta)? = try? await rete.data(for: r) else { return 0 }
            return (risposta as? HTTPURLResponse)?.statusCode ?? 0
        }
        controlla(codiceRisposta == 400 && raccolta.elenco.count == 2, "Ponte: un messaggio nuovo malformato è rifiutato (400)")
        // Il Mac senza destinatario (Prisma non pronto): ricevuta rifiutata
        server.consegnaArrivi(nil)
        let senza = aspetta { await ipad.manda(arrivo) }
        controlla(!senza.accettato && raccolta.elenco.count == 2, "Ponte: se Prisma sul Mac non è pronto la ricevuta lo dice")
    }
    #endif

    /// Aspetta un lavoro asincrono dal thread delle prove.
    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaCopilota<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

private final class ScatolaCopilota<T>: @unchecked Sendable {
    var valore: T?
}

/// I messaggi consegnati dal server del ponte nelle prove.
private final class RaccoltaArrivi: @unchecked Sendable {
    private let blocco = NSLock()
    private var _elenco: [ArrivoPonte] = []

    func aggiungi(_ a: ArrivoPonte) {
        blocco.lock(); defer { blocco.unlock() }
        _elenco.append(a)
    }

    var elenco: [ArrivoPonte] {
        blocco.lock(); defer { blocco.unlock() }
        return _elenco
    }
}
