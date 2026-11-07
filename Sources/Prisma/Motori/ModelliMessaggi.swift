import Foundation

// I modelli fissi dei messaggi: per ogni tipo d'occasione e ogni tono un testo già compilato con i dati del cliente e
// le cifre dei motori (solo quelle dell'occasione: nessun altro numero). Si usano quando Qwen non è pronto (Vera lo dice)
// o quando il testo di Qwen non passa la verifica delle cifre (MessaggiVera), e sono la bozza che Qwen riscrive.
// La chiusura e la firma le mette sempre Prisma: la firma viene dalle impostazioni o dai dati del consulente, e se
// mancano il messaggio resta senza firma (mai una firma inventata).

/// Il testo di un messaggio diviso in parti: l'oggetto (solo Mail), il saluto con il corpo, la chiusura con la firma.
struct TestoMessaggio: Hashable {
    var oggetto: String?
    /// Dal saluto all'invito finale, senza chiusura e firma.
    var corpo: String
    /// «\n\nUn saluto,\nDenis», «\n\nCordiali saluti.» o, per il tono breve, «\nDenis» (vuota senza firma).
    var chiusura: String

    var completo: String { corpo + chiusura }
}

enum ModelliMessaggi {
    // MARK: - Firma, saluto, chiusura

    /// La firma per il canale e il tono, presa dai dati: la firma del canale scritta in Impostazioni › Messaggi;
    /// altrimenti, per il tono formale, nome e cognome dei dati di fatturazione del consulente; altrimenti il nome
    /// dell'utente di Prisma; altrimenti nome e cognome di fatturazione. nil se Prisma non ha nessuno di questi dati.
    static func firma(_ canale: Canale?, tono: TonoMessaggio, impostazioni: Impostazioni) -> String? {
        if let c = canale {
            let f = impostazioni.messaggi.firma(c)
            if !f.isEmpty { return f }
        }
        let fatt = impostazioni.studio.fatturazione
        let completo = [fatt.nome, fatt.cognome].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }.joined(separator: " ")
        let nomeCompleto = completo.isEmpty ? fatt.denominazione.trimmingCharacters(in: .whitespacesAndNewlines) : completo
        if tono == .formale, !nomeCompleto.isEmpty { return nomeCompleto }
        let nome = impostazioni.nomeUtente.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nome.isEmpty { return nome }
        return nomeCompleto.isEmpty ? nil : nomeCompleto
    }

    /// «Ciao Giulia,» (cordiale e breve) o «Gentile Giulia Rossi,» (formale).
    static func saluto(_ cliente: Cliente, tono: TonoMessaggio) -> String {
        let nome = cliente.nome.trimmingCharacters(in: .whitespacesAndNewlines)
        switch tono {
        case .formale: return "Gentile \(nome),"
        case .cordiale, .breve: return "Ciao \(primoNome(nome)),"
        }
    }

    /// La chiusura con la firma. Senza firma: solo il saluto finale (o niente, per il tono breve).
    static func chiusura(tono: TonoMessaggio, firma: String?) -> String {
        let f = firma?.trimmingCharacters(in: .whitespacesAndNewlines).nonVuota
        switch tono {
        case .cordiale: return f.map { "\n\nUn saluto,\n\($0)" } ?? "\n\nUn saluto."
        case .formale: return f.map { "\n\nCordiali saluti,\n\($0)" } ?? "\n\nCordiali saluti."
        case .breve: return f.map { "\n\($0)" } ?? ""
        }
    }

    /// L'oggetto della mail (al massimo 60 caratteri); nil per Messaggi.
    static func oggetto(_ o: OccasioneMessaggio, canale: CanaleMessaggio) -> String? {
        canale == .messaggi ? nil : String(o.oggetto.prefix(RegoleMessaggi.caratteriOggetto))
    }

    /// «Marco ed Elena Bianchi» → «Marco ed Elena»; «Giulia Rossi» → «Giulia».
    static func primoNome(_ nome: String) -> String {
        let parole = nome.split(separator: " ").map(String.init)
        if let i = parole.firstIndex(where: { $0 == "e" || $0 == "ed" }), i > 0, i + 1 < parole.count {
            return parole[0...(i + 1)].joined(separator: " ")
        }
        return parole.first ?? nome
    }

    // MARK: - Il testo

    /// Il messaggio fisso già compilato: saluto, corpo con le sole cifre dell'occasione, chiusura e firma.
    /// Il tono breve resta entro `RegoleMessaggi.caratteriBreve` caratteri con la firma.
    static func testo(_ o: OccasioneMessaggio, tono: TonoMessaggio, canale: CanaleMessaggio, cliente: Cliente,
                      firma: String?) -> TestoMessaggio {
        let fine = chiusura(tono: tono, firma: firma)
        let s = saluto(cliente, tono: tono)
        let corpo: String
        if tono == .breve {
            let (necessarie, facoltative) = frasiBrevi(o)
            corpo = breve(s, necessarie: necessarie, facoltative: facoltative,
                          limite: RegoleMessaggi.caratteriBreve - fine.count)
        } else {
            corpo = s + "\n\n" + paragrafi(o, lei: tono.lei).joined(separator: "\n\n")
        }
        return TestoMessaggio(oggetto: oggetto(o, canale: canale), corpo: corpo, chiusura: fine)
    }

    /// I paragrafi di cordiale (tu) e formale (lei), dopo il saluto.
    static func paragrafi(_ o: OccasioneMessaggio, lei: Bool) -> [String] {
        func v(_ x: VoceCifraMessaggio) -> String? { o.valore(x)?.trimmingCharacters(in: .whitespacesAndNewlines).nonVuota }
        switch o.tipo {
        case .riepilogoIncontro:
            let data = v(.dataIncontro).map { " " + del($0) } ?? ""
            var punti: [String] = []
            if let d = v(.decisioni) { punti.append((lei ? "Quanto deciso: " : "Cosa abbiamo deciso: ") + frase(d)) }
            if let p = v(.prossimoPasso) { punti.append("Il prossimo passo: " + frase(p)) }
            if let i = v(.prossimoIncontro) { punti.append(lei ? "Il prossimo incontro è fissato per \(il(i))." : "Ci rivediamo \(il(i)).") }
            var parti = [lei ? "la ringrazio per l'incontro\(data). Le riassumo quanto abbiamo concordato."
                             : "grazie per l'incontro\(data). Ti scrivo in breve quello che ci siamo detti."]
            if !punti.isEmpty { parti.append(punti.joined(separator: "\n")) }
            parti.append(lei ? "Resto a disposizione per qualsiasi chiarimento." : "Se qualcosa non ti torna, scrivimi pure.")
            return parti
        case .scadenzaPosizione:
            let nome = v(.posizione).map { "«\($0)»" } ?? (lei ? "la sua posizione" : "la tua posizione")
            let quando = v(.scadenza).map { " \(il($0))" } ?? " a breve"
            return lei
                ? ["le scrivo per ricordarle che \(nome) giunge a scadenza\(quando). Le propongo di incontrarci per valutare insieme come proseguire.",
                   "Mi faccia sapere quando le è più comodo."]
                : ["ti scrivo perché \(nome) scade\(quando). È un buon momento per guardarla insieme e capire se risponde ancora a quello che ti serve.",
                   "Ti va di fissare un appuntamento nei prossimi giorni?"]
        case .compleanno:
            return lei
                ? ["le porgo i miei più sinceri auguri di buon compleanno, con l'augurio di una giornata serena."]
                : ["tanti auguri di buon compleanno! Ti auguro una giornata serena, con le persone a cui vuoi bene."]
        case .consenso:
            if v(.consenso) == "Informativa privacy" {
                let quando = v(.informativaAggiornata).map { " \(il($0))" } ?? ""
                return lei
                    ? ["l'informativa sulla privacy è stata aggiornata\(quando): le chiedo di prenderne visione e di firmarla nuovamente, anche al nostro prossimo incontro.",
                       "Resto a disposizione per qualsiasi chiarimento."]
                    : ["ho aggiornato l'informativa sulla privacy\(quando) e ti chiedo di leggerla e firmarla di nuovo: possiamo farlo al prossimo incontro, ci vuole un minuto.",
                       "Se hai domande, scrivimi pure."]
            }
            let quando = v(.scadenza).map { (o.inRitardo ? " è scaduto " : (lei ? " scadrà " : " scade ")) + il($0) }
                ?? (o.inRitardo ? " è scaduto" : " è in scadenza")
            return lei
                ? ["le ricordo che il consenso a ricevere proposte e aggiornamenti\(quando). Se desidera continuare a riceverli, potremo rinnovarlo con una firma al prossimo incontro.",
                   "Resto a disposizione per qualsiasi chiarimento."]
                : ["il consenso che mi avevi dato per ricevere proposte e aggiornamenti\(quando). Se ti fa piacere continuare a riceverli, basta rinnovarlo: ci vuole un minuto, anche al prossimo incontro.",
                   "Fammi sapere tu, senza nessun impegno."]
        case .riesame:
            let ultimo = v(.ultimoContatto)
            if lei {
                let inizio = ultimo.map { "è trascorso un po' di tempo dal nostro ultimo incontro, \(il($0)), e le propongo" } ?? "le propongo"
                return ["\(inizio) di fare il punto insieme sulla sua situazione e sui suoi obiettivi.",
                        "Mi faccia sapere quando le è più comodo."]
            }
            let inizio = ultimo.map { "è passato un po' di tempo dal nostro ultimo incontro, \(il($0)), e mi farebbe piacere" } ?? "mi farebbe piacere"
            return ["\(inizio) fare il punto insieme: come stanno andando le cose e se i tuoi obiettivi sono cambiati.",
                    "Ti va di fissare un appuntamento nelle prossime settimane?"]
        case .occasioneAgenda:
            let quando = v(.dataOccasione).map { "\(il($0)) " } ?? "a breve "
            let cosa = v(.occasione).map { ": «\($0)»" } ?? ""
            return lei
                ? ["\(quando)si presenta un passaggio che la riguarda\(cosa). Le propongo di parlarne con calma per valutare insieme se conviene intervenire.",
                   "Mi faccia sapere quando le è più comodo."]
                : ["\(quando)c'è una novità che ti riguarda\(cosa). Mi piacerebbe parlartene con calma per capire insieme se conviene fare qualcosa.",
                   "Quando ti farebbe comodo sentirci?"]
        case .parcella:
            let numero = v(.parcella).map { " \($0)" } ?? ""
            let importo = v(.importo).map { " di \($0)" } ?? ""
            if o.inRitardo {
                let scaduta = v(.scadenza).map { ", scaduta \(il($0))" } ?? ""
                return lei
                    ? ["le ricordo, qualora le fosse sfuggita, la parcella\(numero)\(importo)\(scaduta). Se ha già provveduto al pagamento, non tenga conto di questo messaggio.",
                       "Resto a disposizione per qualsiasi chiarimento."]
                    : ["ti ricordo, nel caso ti fosse sfuggita, la parcella\(numero)\(importo)\(scaduta). Se l'hai già saldata, non tenere conto di questo messaggio.",
                       "Grazie, e scrivimi pure per qualsiasi cosa."]
            }
            let scadenza = v(.scadenza).map { ", con scadenza \(il($0))" } ?? ""
            return lei
                ? ["le invio la parcella\(numero)\(importo) relativa alla consulenza\(scadenza). Trova tutti i dettagli nel documento.",
                   "Resto a disposizione per qualsiasi chiarimento."]
                : ["ti invio la parcella\(numero)\(importo) per la consulenza\(scadenza). Trovi tutti i dettagli nel documento.",
                   "Per qualsiasi domanda scrivimi pure."]
        case .avvisoMercato:
            let avviso = v(.avviso).map { ": \(minuscolaIniziale(frase($0)))" } ?? "."
            return lei
                ? ["in questi giorni i mercati hanno registrato dei movimenti e ho verificato le sue posizioni\(avviso) Se lo desidera, possiamo parlarne con calma.",
                   "Resto a disposizione per qualsiasi chiarimento."]
                : ["in questi giorni i mercati si sono mossi e ho dato un'occhiata alle tue posizioni\(avviso) Se ti va, ne parliamo con calma.",
                   "Scrivimi pure quando vuoi."]
        case .provaFuoco:
            // Uno scenario ipotetico, non un fatto: il testo lo dice sempre («non è una previsione»)
            let scenario = v(.scenario).map { " («\($0)»)" } ?? ""
            let suo = lei ? "il suo" : "il tuo"
            var effetto = ""
            if let ob = v(.obiettivo), let oggi = v(.coperturaOggi), let dopo = v(.coperturaDopo) {
                effetto = ": \(suo) obiettivo «\(ob)» passerebbe da una copertura del \(oggi) al \(dopo)"
            } else if let p = v(.perditaScenario) {
                effetto = ": \(suo) patrimonio scenderebbe di \(p)"
            }
            return lei
                ? ["ho svolto una verifica sul suo portafoglio con uno scenario difficile\(scenario)\(effetto). Non è una previsione: serve a capire se i suoi obiettivi reggerebbero anche in un momento sfavorevole.",
                   "Se lo desidera, possiamo esaminarla insieme con calma."]
                : ["ho messo alla prova il tuo portafoglio con uno scenario difficile\(scenario)\(effetto). Non è una previsione: serve a capire se i tuoi obiettivi reggono anche in un momento sfavorevole.",
                   "Ti va di guardarla insieme con calma?"]
        }
    }

    /// Le frasi del tono breve (dai del tu): quelle necessarie e quelle che entrano solo se c'è spazio.
    static func frasiBrevi(_ o: OccasioneMessaggio) -> (necessarie: [String], facoltative: [String]) {
        func v(_ x: VoceCifraMessaggio) -> String? { o.valore(x)?.trimmingCharacters(in: .whitespacesAndNewlines).nonVuota }
        switch o.tipo {
        case .riepilogoIncontro:
            let data = v(.dataIncontro).map { " " + del($0) } ?? ""
            var facoltative: [String] = []
            if let p = v(.prossimoPasso) { facoltative.append("Il prossimo passo: " + frase(p)) }
            if let i = v(.prossimoIncontro) { facoltative.append("Ci rivediamo \(il(i)).") }
            return (["grazie per l'incontro\(data)."], facoltative + ["Scrivimi pure per ogni dubbio."])
        case .scadenzaPosizione:
            let nome = v(.posizione).map { "«\($0)»" } ?? "la tua posizione"
            let quando = v(.scadenza).map { " \(il($0))" } ?? " a breve"
            return (["\(nome) scade\(quando): ci vediamo per guardarla insieme?"], [])
        case .compleanno:
            return (["tanti auguri di buon compleanno!"], ["Ti auguro una bellissima giornata."])
        case .consenso:
            if v(.consenso) == "Informativa privacy" {
                let quando = v(.informativaAggiornata).map { " \(il($0))" } ?? ""
                return (["l'informativa privacy è stata aggiornata\(quando): al prossimo incontro la firmiamo di nuovo."], ["Ci vuole un minuto."])
            }
            let quando = v(.scadenza).map { (o.inRitardo ? " è scaduto " : " scade ") + il($0) } ?? (o.inRitardo ? " è scaduto" : " è in scadenza")
            return (["il consenso per ricevere le mie proposte\(quando): se vuoi lo rinnoviamo con una firma."], ["Fammi sapere!"])
        case .riesame:
            return (["è un po' che non ci vediamo: ti va di fare il punto insieme nelle prossime settimane?"], [])
        case .occasioneAgenda:
            let quando = v(.dataOccasione).map { "\(il($0)) " } ?? "a breve "
            let necessarie = ["\(quando)c'è una novità che ti riguarda: ne parliamo?"]
            // Con il nome dell'occasione se lascia spazio a saluto e firma, altrimenti senza
            if let cosa = v(.occasione) {
                let conNome = "\(quando)c'è una novità che ti riguarda («\(cosa)»): ne parliamo?"
                if conNome.count <= RegoleMessaggi.caratteriBreve - RegoleMessaggi.riservaBreve { return ([conNome], []) }
            }
            return (necessarie, [])
        case .parcella:
            let numero = v(.parcella).map { " \($0)" } ?? ""
            let importo = v(.importo).map { " di \($0)" } ?? ""
            if o.inRitardo {
                let scaduta = v(.scadenza).map { ", scaduta \(il($0))" } ?? ""
                return (["ti ricordo la parcella\(numero)\(importo)\(scaduta)."], ["Se l'hai già saldata, non farci caso!"])
            }
            return (["ti mando la parcella\(numero)\(importo)."], ["Per ogni domanda scrivimi pure."])
        case .avvisoMercato:
            return (["i mercati si sono mossi e ho guardato le tue posizioni: se vuoi ne parliamo."], [])
        case .provaFuoco:
            let scenario = v(.scenario).map { " («\($0)»)" } ?? ""
            return (["ho messo alla prova il tuo portafoglio con uno scenario difficile\(scenario): ti va di guardarlo insieme?"],
                    ["Non è una previsione."])
        }
    }

    /// Il tono breve su una riga: il saluto, le frasi necessarie e, finché c'è spazio, quelle facoltative.
    /// Se anche le necessarie non stanno nel limite si taglia all'ultima parola intera.
    static func breve(_ saluto: String, necessarie: [String], facoltative: [String], limite: Int) -> String {
        var testo = ([saluto] + necessarie).joined(separator: " ")
        for f in facoltative where testo.count + 1 + f.count <= limite {
            testo += " " + f
        }
        guard testo.count > limite, limite > 1 else { return testo }
        let inizio = testo.prefix(limite - 1)
        let taglio = inizio.lastIndex(of: " ").map { String(inizio[..<$0]) } ?? String(inizio)
        return taglio + "…"
    }

    // MARK: - Aiuti

    /// Con il punto finale se manca.
    static func frase(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ultimo = t.last else { return t }
        return ".!?…".contains(ultimo) ? t : t + "."
    }

    /// «il 17 dicembre 2026», «l'8 novembre 2026», «l'1 dicembre 2026» (la data è già scritta per esteso).
    static func il(_ data: String) -> String {
        ["1 ", "8 ", "11 "].contains { data.hasPrefix($0) } ? "l'\(data)" : "il \(data)"
    }

    /// «del 17 dicembre 2026», «dell'8 novembre 2026».
    static func del(_ data: String) -> String {
        ["1 ", "8 ", "11 "].contains { data.hasPrefix($0) } ? "dell'\(data)" : "del \(data)"
    }

    private static func minuscolaIniziale(_ s: String) -> String {
        guard let primo = s.first else { return s }
        if s.dropFirst().first.map({ $0.isUppercase }) == true { return s }
        return primo.lowercased() + s.dropFirst()
    }
}

private extension String {
    /// nil se vuota.
    var nonVuota: String? { isEmpty ? nil : self }
}
