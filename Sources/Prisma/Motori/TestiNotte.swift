import Foundation

// I testi di «Stanotte Prisma ha lavorato» («Luce» giro 14, §6.1): la sovrapposizione delle carte, le carte di ogni tipo
// (con le cifre vere dei motori), gli stati, il registro e la notifica. Parla Prisma in prima persona. La notifica non dice
// mai nomi né cifre dei clienti (decisione 29).

enum TestiNotte {
    // MARK: - La sovrapposizione

    static let titoloSovrapposizione = "Stanotte ho lavorato per te."
    static let istruzioni = "Approvale con un gesto: a destra sì, a sinistra più tardi."
    static let chiudi = "Chiudi"
    static let apri = "Apri ›"
    static let approva = "Approva"
    static let piuTardi = "Più tardi"
    static let timbroApprova = "APPROVA"
    static let timbroPiuTardi = "PIÙ TARDI"
    static let registro = "FATTO ADESSO"
    static let daIeri = "DA IERI"
    static let preparaAdesso = "Prepara adesso"
    static let vaiAllaScrivania = "Vai alla scrivania"
    static let pulsanteScrivania = "Stanotte"
    static let aiutoPulsante = "Le cose che Prisma ha preparato per oggi"
    static let ancoraImpostazioni = "impostazioni-notte"
    static let avvisoModoCliente = "In modalità cliente le carte della notte non si aprono: parlano di tutti i clienti."
    static let avvisoPresentazione = "Con la presentazione aperta le carte della notte non si aprono."
    static let avvisoLavoroInCorso = "Sto già preparando le cose di oggi."
    static let avvisoSolaLettura = "L'archivio è in sola lettura: il lavoro della notte non può scrivere."

    /// «1 cosa», «8 cose».
    static func cose(_ n: Int) -> String { n == 1 ? "1 cosa" : "\(n) cose" }

    /// L'ora senza lo zero davanti («2:10», «23:05»), come nel template.
    static func ora(_ d: Date) -> String {
        let s = Formati.ora.string(from: d)
        return s.hasPrefix("0") && s.count == 5 ? String(s.dropFirst()) : s
    }

    /// La prima parte del sottotitolo, fino al numero in grassetto compreso.
    static func sottotitoloInizio(inizio: Date?, fine: Date?) -> String {
        guard let i = inizio else { return "Ho preparato " }
        let f = fine ?? i
        return "Tra le \(ora(i)) e le \(ora(f)) ho preparato "
    }

    /// «Tra le 2:10 e le 2:14 ho preparato 8 cose. Approvale con un gesto: a destra sì, a sinistra più tardi.»
    static func sottotitolo(inizio: Date?, fine: Date?, carte: Int) -> String {
        sottotitoloInizio(inizio: inizio, fine: fine) + cose(carte) + ". " + istruzioni
    }

    /// «Sto preparando… 3 di 8»
    static func inCorso(fatte: Int, totale: Int) -> String {
        totale > 0 ? "Sto preparando… \(min(fatte, totale)) di \(totale)" : "Sto preparando…"
    }

    /// «1 di 8»
    static func contatore(_ i: Int, di n: Int) -> String { "\(i) di \(n)" }

    /// «7 approvate, 1 per più tardi. Buona giornata, Denis.»
    static func fine(approvate: Int, rimandate: Int, nome: String?) -> String {
        let a = approvate == 1 ? "1 approvata" : "\(approvate) approvate"
        let saluto = nome.flatMap { n -> String? in
            let t = n.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : "Buona giornata, \(t)."
        } ?? "Buona giornata."
        return "\(a), \(rimandate) per più tardi. \(saluto)"
    }

    static let tuttoFatto = "Tutto fatto."

    /// L'occhiello del tipo.
    static func occhiello(_ t: TipoCartaNotte) -> String {
        switch t {
        case .fascicolo: return "FASCICOLO"
        case .messaggio: return "MESSAGGIO"
        case .ricalcolo: return "RICALCOLO"
        case .documento: return "DOCUMENTO"
        case .moduli: return "MODULI"
        case .riesame: return "RIESAME"
        case .campagna: return "CAMPAGNA"
        case .domani: return "DOMANI"
        case .daFinire: return "DA FINIRE"
        }
    }

    /// «Preparato alle 2:10 · in locale sul Mac»
    static func piede(_ preparataIl: Date) -> String { "Preparato alle \(ora(preparataIl)) · in locale sul Mac" }

    /// La riga del registro di una carta rimandata.
    static func rigaRimandata(_ titolo: String) -> String { "\(titolo) · più tardi" }

    // MARK: - Gli stati

    static let saltataTitolo = "Stanotte il Mac dormiva."
    static let saltataTesto = "Preparo adesso le cose di oggi? Ci vogliono pochi minuti."
    static let saltataSpentoTitolo = "Il lavoro della notte è spento."
    static let saltataSpentoTesto = "Preparo adesso le cose di oggi? Puoi accenderlo in Impostazioni › Vera."
    static let nienteTitolo = "Oggi non c'era niente da preparare."
    static let nienteTesto = "Nessun incontro, nessuna scadenza nei prossimi 30 giorni, nessun riesame dovuto."
    static let inCorsoTitolo = "Sto preparando le cose di oggi."
    static let inCorsoTesto = "Le carte arrivano qui una alla volta, appena sono pronte."

    static func daFinireQwen(_ n: Int) -> String {
        "Vera non era pronta: \(n == 1 ? "1 bozza" : "\(n) bozze") da scrivere quando vuoi."
    }

    static func daFinireMemoria(_ n: Int) -> String {
        "Mi sono fermata per lasciare memoria al Mac: \(n == 1 ? "1 bozza" : "\(n) bozze") da scrivere quando vuoi."
    }

    static func daFinireTempo(_ n: Int) -> String {
        "Il tempo della notte è finito: \(n == 1 ? "1 bozza" : "\(n) bozze") da scrivere quando vuoi."
    }

    static let daFinireTesto = "Le cifre e i documenti di Prisma ci sono comunque. «Apri ›» ti porta in Messaggi."
    static let daFinireConferma = "Le scrivo io più tardi"
    static let senzaFirma = "Manca la tua firma: la bozza è senza saluto."

    // MARK: - Notifiche

    /// La voce del pannello Notifiche di Prisma e la notifica di macOS: mai nomi né cifre dei clienti.
    static func notifica(_ n: Int) -> String { "Stanotte ho preparato \(cose(n))" }
    static func voceNotifica(_ n: Int) -> String { notifica(n) }
    static let dettaglioNotifica = "Approvale con un gesto"

    // MARK: - Le carte

    /// «Giulia Rossi» → «Giulia».
    static func primoNome(_ nome: String) -> String { ModelliMessaggi.primoNome(nome) }

    static func titoloFascicolo(nome: String) -> String { "Il fascicolo di \(primoNome(nome)) è pronto" }

    /// «Per l'incontro delle 09:30: 3 report (…). Lo metto nei Documenti quando approvi.»
    static func descrizioneFascicolo(ora o: Date, prospetti: [String]) -> String {
        let nomi = prospetti.compactMap { TipoProspetto(rawValue: $0)?.nome }
        let quanti = nomi.count == 1 ? "1 report" : "\(nomi.count) report"
        let elenco = nomi.isEmpty ? "" : " (" + nomi.joined(separator: ", ") + ")"
        return "Per l'incontro delle \(Formati.ora.string(from: o)): \(quanti)\(elenco). Lo metto nei Documenti quando approvi."
    }

    static let confermaFascicolo = "Fascicolo approvato"
    static let confermaFascicoloGiaPronto = "Fascicolo già nei Documenti"

    static func titoloMessaggio(nome: String, occasione: String) -> String { "Bozza per \(primoNome(nome)): \(occasione)" }

    static func descrizioneMessaggio(perche: String, firma: Bool) -> String {
        "\(perche). Tono cordiale, scritta da Vera: da rivedere in Messaggi prima di mandarla." + (firma ? "" : " " + senzaFirma)
    }

    static let confermaMessaggio = "Bozza pronta in Messaggi"

    static func titoloRicalcolo(portafogli: Int) -> String {
        portafogli == 1 ? "1 portafoglio ricalcolato" : "\(portafogli) portafogli ricalcolati"
    }

    static func descrizioneRicalcolo(nuovi: Int) -> String {
        let chi = nuovi == 1 ? "Un cliente ha" : "\(nuovi) clienti hanno"
        return "Con i dati di stanotte. \(chi) un'attenzione nuova da guardare."
    }

    static let confermaRicalcolo = "Ricalcolo visto"

    /// «La carta d'identità di Sofia scade il 30 novembre» / «… è scaduta il 2 novembre».
    static func titoloDocumento(nome: String, documento: String, scadenza: Date, scaduto: Bool) -> String {
        let quando = Formati.giornoMese.string(from: scadenza)
        if scaduto { return "Il documento d'identità di \(primoNome(nome)) è scaduto il \(quando)" }
        return "\(documento) di \(primoNome(nome)) scade il \(quando)"
    }

    static let descrizioneDocumento = "Ho preparato la richiesta del documento nuovo, da mandare quando vuoi."
    static let confermaDocumento = "Richiesta pronta"

    /// L'attività che nasce con «Approva» del documento.
    static func attivitaDocumento(nome: String) -> String { "Chiedere a \(primoNome(nome)) il documento d'identità nuovo" }

    static func titoloModuli(proposta: String, quanti: Int) -> String {
        quanti == 1 ? "Il modulo della proposta «\(proposta)» è compilato" : "I moduli della proposta «\(proposta)» sono compilati"
    }

    static func descrizioneModuli(quanti: Int, campi: Int, mancanti: [String]) -> String {
        let m = quanti == 1 ? "Un modulo" : "\(quanti) moduli"
        let c = campi == 1 ? "1 campo" : "\(campi) campi"
        let manca = mancanti.isEmpty ? "Non manca nessun dato." : "Manca solo: \(mancanti.joined(separator: ", "))."
        return "\(m), \(c). \(manca)"
    }

    static let confermaModuli = "Moduli approvati"

    static func titoloRiesame(nome: String) -> String { "Il riesame di \(primoNome(nome)) è pronto" }

    static func descrizioneRiesame(dovutoDal: Date?, oggi: Date, fuoriModello: Double?) -> String {
        var parti: [String] = []
        if let d = dovutoDal {
            parti.append((d <= oggi ? "Dovuto dal " : "Dovuto entro il ") + Formati.giornoMese.string(from: d) + ".")
        } else {
            parti.append("Non ci siamo ancora incontrati per un riesame.")
        }
        if let f = fuoriModello, f.isFinite {
            parti.append("Fuori dal portafoglio modello di \(Formati.numeroFormatter.string(from: NSNumber(value: (f * 10).rounded() / 10)) ?? "\(f)") punti.")
        }
        parti.append("Prospetto del riesame pronto; la scheda di adeguatezza resta da firmare.")
        return parti.joined(separator: " ")
    }

    static let confermaRiesame = "Riesame approvato"

    static func titoloCampagna(titolo: String, inclusi: Int) -> String { "\(titolo): \(inclusi) clienti" }

    static func descrizioneCampagna(inclusi: Int) -> String {
        "\(inclusi) messaggi personalizzati con il modello di Prisma, da rivedere uno per uno prima di mandarli."
    }

    static let confermaCampagna = "Campagna pronta"

    static let titoloDomani = "La borsa di oggi"

    /// «2 incontri, 4 cose da portare, 34 km. Partenza consigliata alle 09:15 (stima).»
    static func descrizioneDomani(incontri: Int, daPortare: Int, km: Double?, partenza: Date?) -> String {
        var s = incontri == 1 ? "1 incontro" : "\(incontri) incontri"
        s += daPortare == 1 ? ", 1 cosa da portare" : ", \(daPortare) cose da portare"
        if let km, km.isFinite, km > 0 { s += ", \(Int(km.rounded())) km" }
        s += "."
        if let p = partenza { s += " Partenza consigliata alle \(Formati.ora.string(from: p)) (stima)." }
        return s
    }

    static let confermaDomani = "Lista della borsa pronta"
    static let notaBorsa = "Da portare: "

    /// «09:30 Giulia: fascicolo, moduli da firmare (3), documento d'identità da rinnovare»
    static func rigaBorsa(ora o: Date, nome: String?, cose: [String]) -> String {
        let chi = nome.map { " " + primoNome($0) } ?? ""
        let cosa = cose.isEmpty ? "niente di particolare" : cose.joined(separator: ", ")
        return "\(Formati.ora.string(from: o))\(chi): \(cosa)"
    }

    static let borsaFascicolo = "fascicolo"
    static func borsaModuli(_ n: Int) -> String { n == 1 ? "un modulo da firmare" : "moduli da firmare (\(n))" }
    static let borsaDocumento = "documento d'identità da rinnovare"

    static func titoloDaFinire(_ n: Int, motivo: MotivoStopNotte?) -> String {
        switch motivo {
        case .memoria?: return daFinireMemoria(n)
        case .tempo?, .riposo?, .chiusura?: return daFinireTempo(n)
        case .qwenNonPronto?, nil: return daFinireQwen(n)
        }
    }

    // MARK: - Impostazioni

    static let gruppoImpostazioni = "Stanotte"
    static let rigaAttivo = "Lavora di notte"
    static let rigaInizio = "Dalle"
    static let fineFinestra = "alle 6:00"
    static let rigaBozze = "Bozze con Vera"
    static let notaBozze = "al massimo 10, una alla volta"
    static let rigaApri = "Apri le carte al mattino"
    static let rigaNotifica = "Notifica sul Mac"
    static let aiutoNotifica = "Solo «Stanotte ho preparato N cose», senza nomi"
    static let notaImpostazioni = "Solo con il Mac acceso, alla corrente e Prisma aperto: un MacBook chiuso dorme. Mai internet; «Approva» non manda nulla."
    static func oraInizio(_ h: Int) -> String { "\(h):00" }
}
