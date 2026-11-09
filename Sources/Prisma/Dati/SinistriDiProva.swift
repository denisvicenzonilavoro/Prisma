import Foundation

/// I sinistri dei clienti di prova («Luce» giro 15, §7.4 e §8 del piano). DATI DI PROVA DICHIARATI: solo con i clienti di
/// prova, id con il prefisso `sinistro-prova-` (`rimuoviDatiDiProva` li toglie da qui), fatti, documenti, numeri e
/// importi fittizi, date relative a oggi. I tre del template adattati ai dati di prova:
/// - Marco: «Infortunio di Pietro» (Pietro è il figlio di prova) sulla polizza di prova «Infortuni famiglia», in perizia,
///   denuncia di 18 giorni fa, stima fra 1.200 e 1.800 €, una visita fissata fra qualche giorno, aggiornamenti accesi;
/// - Sofia: «Danni da acqua in cucina», pagato 3.400 €, senza polizza collegata (nei dati di prova non ha una polizza
///   casa: «polizza da collegare»), aggiornamenti e importo accesi;
/// - Giulia: «Furto della bicicletta», in raccolta documenti, senza polizza collegata né stima, aggiornamenti spenti.
/// Nessuna polizza di prova nuova (cambierebbe conti e istantanee esistenti).
enum SinistriDiProva {
    /// Il prefisso degli id dei sinistri di prova.
    static let prefisso = "sinistro-prova-"
    static let idMarco = "sinistro-prova-marco"
    static let idSofia = "sinistro-prova-sofia"
    static let idGiulia = "sinistro-prova-giulia"
    /// La polizza di prova di Marco (DatiDemo.posizioni).
    static let polizzaMarco = "pos-marco-infortuni-famiglia"

    static func applica(_ d: inout DatiPrisma, oggi: Date = Date()) {
        for s in sinistri(oggi: oggi) where d.clienti.contains(where: { $0.id == s.clienteId })
            && !d.sinistri.contains(where: { $0.id == s.id }) {
            var x = s
            if let p = x.posizioneId, !d.posizioni.contains(where: { $0.id == p }) { x.posizioneId = nil }
            d.sinistri.append(x)
        }
    }

    /// I tre sinistri di prova, con le date relative a `oggi` (a mezzogiorno, al secondo: come le scrive l'archivio).
    static func sinistri(oggi: Date) -> [Sinistro] {
        let cal = Calendar(identifier: .gregorian)
        let inizio = cal.startOfDay(for: oggi)
        func giorno(_ n: Int) -> Date {
            let g = cal.date(byAdding: .day, value: n, to: inizio) ?? inizio
            return cal.date(bySettingHour: 12, minute: 0, second: 0, of: g) ?? g
        }

        var marco = Sinistro(id: idMarco, clienteId: "marco", posizioneId: polizzaMarco, titolo: "Infortunio di Pietro",
                             descrizione: "Caduta giocando a calcio (dati di prova)", accadutoIl: giorno(-20), apertoIl: giorno(-18))
        marco.numeroSinistro = "SIN-PROVA-2741"
        marco.fase = .perizia
        marco.eventi = [
            EventoSinistro(id: "evento-prova-marco-1", data: giorno(-18), testo: "Denuncia inviata alla compagnia", fase: .denuncia),
            EventoSinistro(id: "evento-prova-marco-2", data: giorno(-12), testo: "Ricevuti i documenti del pronto soccorso", fase: .documenti),
            EventoSinistro(id: "evento-prova-marco-3", data: giorno(-4), testo: "Perito incaricato dalla compagnia", fase: .perizia),
            EventoSinistro(id: "evento-prova-marco-4", data: giorno(5), testo: "Visita del medico fiduciario fissata", fase: .perizia),
        ]
        marco.documenti = [
            DocumentoSinistro(id: "documento-prova-marco-1", titolo: "Denuncia firmata", ricevutoIl: giorno(-18), documentoId: nil),
            DocumentoSinistro(id: "documento-prova-marco-2", titolo: "Referto del pronto soccorso", ricevutoIl: giorno(-12), documentoId: nil),
            DocumentoSinistro(id: "documento-prova-marco-3", titolo: "Certificato di guarigione", ricevutoIl: nil, documentoId: nil),
        ]
        marco.stimaMinima = 1_200
        marco.stimaMassima = 1_800
        marco.mostraAlCliente = true
        marco.ultimoAggiornamentoCliente = giorno(-4)

        var sofia = Sinistro(id: idSofia, clienteId: "sofia", titolo: "Danni da acqua in cucina",
                             descrizione: "Perdita dal tubo della lavastoviglie (dati di prova)", accadutoIl: giorno(-62), apertoIl: giorno(-60))
        sofia.numeroSinistro = "SIN-PROVA-1958"
        sofia.fase = .pagato
        sofia.eventi = [
            EventoSinistro(id: "evento-prova-sofia-1", data: giorno(-60), testo: "Denuncia inviata alla compagnia", fase: .denuncia),
            EventoSinistro(id: "evento-prova-sofia-2", data: giorno(-52), testo: "Inviati foto e preventivo", fase: .documenti),
            EventoSinistro(id: "evento-prova-sofia-3", data: giorno(-41), testo: "Sopralluogo del perito", fase: .perizia),
            EventoSinistro(id: "evento-prova-sofia-4", data: giorno(-20), testo: "Liquidazione approvata", fase: .liquidazione),
            EventoSinistro(id: "evento-prova-sofia-5", data: giorno(-9), testo: "Pagati 3.400 €", fase: .pagato),
        ]
        sofia.documenti = [
            DocumentoSinistro(id: "documento-prova-sofia-1", titolo: "Denuncia firmata", ricevutoIl: giorno(-60), documentoId: nil),
            DocumentoSinistro(id: "documento-prova-sofia-2", titolo: "Foto dei danni", ricevutoIl: giorno(-58), documentoId: nil),
            DocumentoSinistro(id: "documento-prova-sofia-3", titolo: "Preventivo di riparazione", ricevutoIl: giorno(-52), documentoId: nil),
        ]
        sofia.stimaMinima = 3_000
        sofia.stimaMassima = 3_600
        sofia.pagato = 3_400
        sofia.chiusoIl = giorno(-9)
        sofia.mostraAlCliente = true
        sofia.importoAlCliente = true
        sofia.ultimoAggiornamentoCliente = giorno(-9)

        var giulia = Sinistro(id: idGiulia, clienteId: "giulia", titolo: "Furto della bicicletta",
                              descrizione: "Rubata davanti a casa (dati di prova)", accadutoIl: giorno(-7), apertoIl: giorno(-6))
        giulia.fase = .documenti
        giulia.eventi = [
            EventoSinistro(id: "evento-prova-giulia-1", data: giorno(-6), testo: "Denuncia ai Carabinieri e alla compagnia", fase: .denuncia),
            EventoSinistro(id: "evento-prova-giulia-2", data: giorno(-3), testo: "La compagnia chiede la fattura d'acquisto", fase: .documenti),
        ]
        giulia.documenti = [
            DocumentoSinistro(id: "documento-prova-giulia-1", titolo: "Copia della denuncia", ricevutoIl: giorno(-6), documentoId: nil),
            DocumentoSinistro(id: "documento-prova-giulia-2", titolo: "Fattura d'acquisto della bicicletta", ricevutoIl: nil, documentoId: nil),
        ]
        return [marco, sofia, giulia]
    }
}
