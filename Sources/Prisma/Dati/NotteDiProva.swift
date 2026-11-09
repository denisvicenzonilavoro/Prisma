import Foundation

// Le carte della notte DI PROVA («Luce» giro 14): le otto carte del template sui clienti di prova (Giulia fascicolo
// delle 9:30, Marco messaggio, ricalcolo «5 portafogli», Sofia documento e moduli della sua proposta indipendente, Andrea
// riesame al posto di «Federico Galli», che non è nei dati di prova, la campagna del gruppo più grande, la borsa), lavoro
// fra le 2:10 e le 2:14. Le cifre che non vengono dai dati (5 portafogli, 34 km, partenza alle 9:15, 48 campi, la scadenza
// del 17 dicembre) sono dati di prova dichiarati. Solo per le istantanee e le prove: mai nell'archivio di prova; id con il
// prefisso «notte-prova-» (`rimuoviDatiDiProva` le toglie).
enum NotteDiProva {
    static let prefisso = "notte-prova-"

    /// La notte di prova del giorno di `oggi` con le otto carte.
    static func notte(_ d: DatiPrisma, oggi: Date, cal: Calendar = Calendar(identifier: .gregorian)) -> NotteDiLavoro {
        let giorno = cal.startOfDay(for: oggi)
        let inizio = alle(giorno, 2, 10, cal: cal)
        var n = NotteDiLavoro(giorno: giorno, inizio: inizio, cal: cal)
        n.fine = alle(giorno, 2, 14, cal: cal)
        n.esito = .fatta
        n.carte = carte(d, giorno: giorno, cal: cal)
        return n
    }

    /// La notte di prova con Vera non pronta: due carte e «Da finire» terza nella pila.
    static func conDaFinire(_ d: DatiPrisma, oggi: Date, cal: Calendar = Calendar(identifier: .gregorian)) -> NotteDiLavoro {
        var n = notte(d, oggi: oggi, cal: cal)
        let giorno = n.giorno
        var c = CartaNotte(id: prefisso + "daFinire", tipo: .daFinire, clienteId: nil, riferimento: "bozze",
                           titolo: TestiNotte.daFinireQwen(2), descrizione: TestiNotte.daFinireTesto,
                           conferma: TestiNotte.daFinireConferma, preparataIl: alle(giorno, 2, 14, cal: cal), perIl: giorno)
        c.daFinire = 2
        n.carte = Array(n.carte.prefix(2)) + [c]
        n.motivoStop = .qwenNonPronto
        return n
    }

    private static func alle(_ giorno: Date, _ h: Int, _ m: Int, cal: Calendar) -> Date {
        NotaInArrivo.alSecondo(cal.date(bySettingHour: h, minute: m, second: 0, of: giorno) ?? giorno)
    }

    private static func nome(_ d: DatiPrisma, _ id: String) -> String {
        d.clienti.first { $0.id == id }?.nome ?? id.capitalized
    }

    private static func carte(_ d: DatiPrisma, giorno: Date, cal: Calendar) -> [CartaNotte] {
        func carta(_ k: Int, _ tipo: TipoCartaNotte, cliente: String?, riferimento: String, titolo: String, descrizione: String,
                   conferma: String) -> CartaNotte {
            CartaNotte(id: prefisso + tipo.rawValue, tipo: tipo, clienteId: cliente, riferimento: riferimento, titolo: titolo,
                       descrizione: descrizione, conferma: conferma, preparataIl: alle(giorno, 2, 10 + min(k, 4), cal: cal), perIl: giorno)
        }
        let domani = cal.date(byAdding: .day, value: 1, to: giorno) ?? giorno
        let ids = Set(d.clienti.map(\.id))
        let delGiorno = d.appuntamenti.filter { $0.inizio >= giorno && $0.inizio < domani && ids.contains($0.clienteId) }
            .sorted { $0.inizio < $1.inizio }

        // 1 · Fascicolo di Giulia per l'incontro delle 9:30
        let incontro = delGiorno.first { $0.clienteId == "giulia" } ?? d.appuntamenti.first { $0.clienteId == "giulia" }
        let ora = incontro?.inizio ?? alle(giorno, 9, 30, cal: cal)
        let prospetti = [TipoProspetto.resoconto, .patrimonio, .costi].map(\.rawValue)
        var fascicolo = carta(0, .fascicolo, cliente: "giulia", riferimento: incontro?.id ?? prefisso + "appuntamento",
                              titolo: TestiNotte.titoloFascicolo(nome: nome(d, "giulia")),
                              descrizione: TestiNotte.descrizioneFascicolo(ora: ora, prospetti: prospetti), conferma: TestiNotte.confermaFascicolo)
        fascicolo.prospetti = prospetti

        // 2 · La bozza per Marco (scadenza del 17 dicembre: dato di prova)
        let occasione = prefisso + "infortuni"
        var bozza = MessaggioCliente(clienteId: "marco", occasioneId: occasione,
                                     origine: OrigineMessaggio(tipo: .scadenzaPosizione, riferimento: occasione), canaleLavoro: nil,
                                     tono: .cordiale, canale: .mail, oggetto: "Il rinnovo dell'Infortuni",
                                     testo: "Ciao Marco,\n\nl'Infortuni scade il 17 dicembre: ti va di vederci per il rinnovo, con la proposta per Elena?\n\nUn saluto.",
                                     cifre: [CifraMessaggio(.scadenza, "17 dicembre")], autore: .vera, modello: MotoreLocale.modelloPredefinito,
                                     creatoIl: alle(giorno, 2, 12, cal: cal))
        bozza.id = "messaggio-" + prefisso + "marco"
        var messaggio = carta(1, .messaggio, cliente: "marco", riferimento: occasione,
                              titolo: TestiNotte.titoloMessaggio(nome: nome(d, "marco"), occasione: "il rinnovo dell'Infortuni"),
                              descrizione: TestiNotte.descrizioneMessaggio(perche: "Scade il 17 dicembre", firma: true),
                              conferma: TestiNotte.confermaMessaggio)
        messaggio.bozze = [bozza]

        // 3 · Il ricalcolo («5 portafogli»: dato di prova)
        var ricalcolo = carta(2, .ricalcolo, cliente: nil, riferimento: "attenzioni", titolo: TestiNotte.titoloRicalcolo(portafogli: 5),
                              descrizione: TestiNotte.descrizioneRicalcolo(nuovi: 2), conferma: TestiNotte.confermaRicalcolo)
        ricalcolo.clienti = ["giulia", "marco"]

        // 4 · Il documento di Sofia (scade fra 21 giorni)
        let scadenza = cal.date(byAdding: .day, value: 21, to: giorno) ?? giorno
        let sofia = d.clienti.first { $0.id == "sofia" }
        let rifDoc = "sofia·\(NotteDiLavoro.chiave(scadenza, cal: cal))"
        var documento = carta(3, .documento, cliente: "sofia", riferimento: rifDoc,
                              titolo: TestiNotte.titoloDocumento(nome: nome(d, "sofia"), documento: "La carta d'identità", scadenza: scadenza, scaduto: false),
                              descrizione: TestiNotte.descrizioneDocumento, conferma: TestiNotte.confermaDocumento)
        if let sofia {
            var b = MotoreNotte.bozzaDocumento(sofia, scadenza: scadenza, scaduto: false, documento: "Carta d'identità", riferimento: rifDoc,
                                               giorno: giorno, impostazioni: d.impostazioni, cal: cal)
            b.id = "messaggio-" + prefisso + "documento"
            documento.bozze = [b]
        }

        // 5 · I moduli della proposta indipendente di Sofia (3 moduli, 48 campi: dati di prova)
        let proposta = d.posizioni.first { $0.clienteId == "sofia" && $0.stato == .proposta && $0.canale == .indipendente }
        var moduli = carta(4, .moduli, cliente: "sofia", riferimento: proposta?.id ?? prefisso + "proposta",
                           titolo: TestiNotte.titoloModuli(proposta: proposta?.nome ?? "Proposta di prova", quanti: 3),
                           descrizione: TestiNotte.descrizioneModuli(quanti: 3, campi: 48, mancanti: ["IBAN per l'addebito"]),
                           conferma: TestiNotte.confermaModuli)
        moduli.modelli = ["modulo-prova-\(TipoModulo.propostaPolizza.rawValue)", "modulo-prova-\(TipoModulo.adeguataVerifica.rawValue)"]

        // 6 · Il riesame di Andrea
        let riesame = carta(5, .riesame, cliente: "andrea", riferimento: "andrea", titolo: TestiNotte.titoloRiesame(nome: nome(d, "andrea")),
                            descrizione: TestiNotte.descrizioneRiesame(dovutoDal: nil, oggi: giorno, fuoriModello: nil),
                            conferma: TestiNotte.confermaRiesame)

        // 7 · La campagna del gruppo più grande dei dati di prova
        let gruppo = MotoreCampagne.gruppi(dati: d, oggi: giorno, cal: cal)
            .max { $0.membri.filter(\.inclusoDiBase).count < $1.membri.filter(\.inclusoDiBase).count }
        let inclusi = gruppo?.membri.filter(\.inclusoDiBase).map(\.clienteId) ?? ["giulia", "marco"]
        var campagna = carta(6, .campagna, cliente: nil, riferimento: gruppo?.id ?? prefisso + "campagna",
                             titolo: TestiNotte.titoloCampagna(titolo: gruppo?.titolo ?? "Famiglia senza protezione", inclusi: inclusi.count),
                             descrizione: TestiNotte.descrizioneCampagna(inclusi: inclusi.count), conferma: TestiNotte.confermaCampagna)
        campagna.clienti = inclusi

        // 8 · La borsa (34 km e partenza alle 9:15: dati di prova)
        let righe = delGiorno.map { a in
            TestiNotte.rigaBorsa(ora: a.inizio, nome: nome(d, a.clienteId),
                                 cose: a.clienteId == "giulia" ? [TestiNotte.borsaFascicolo] : (a.clienteId == "sofia" ? [TestiNotte.borsaModuli(3), TestiNotte.borsaDocumento] : []))
        }
        var borsa = carta(7, .domani, cliente: nil, riferimento: "borsa", titolo: TestiNotte.titoloDomani,
                          descrizione: TestiNotte.descrizioneDomani(incontri: max(delGiorno.count, 1), daPortare: 4, km: 34,
                                                                    partenza: alle(giorno, 9, 15, cal: cal)),
                          conferma: TestiNotte.confermaDomani)
        borsa.appuntamenti = delGiorno.map(\.id)
        borsa.righe = righe

        return [fascicolo, messaggio, ricalcolo, documento, moduli, riesame, campagna, borsa]
    }
}
