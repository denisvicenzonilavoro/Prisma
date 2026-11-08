import Foundation

/// Le frasi di Clienti › Potenziali e Passaparola («Luce» giro 12, §9.2), tutte in un punto. Solo fatti: mai uno stato
/// d'animo del cliente, mai cifre inventate.
enum TestiPassaparola {
    // MARK: - Potenziali

    static let notaPercorso = "Tocca una scheda per farla avanzare. Prisma ricorda chi l'ha presentata: quando diventa cliente, compare nell'albero del passaparola."
    static let notaPercorsoSolaLettura = "Su iPad il percorso si guarda soltanto: le schede si spostano dal Mac."
    static let aggiungi = "Aggiungi un potenziale cliente"
    static let aggiungiBreve = "+ Potenziale"
    static let vuoto = "Nessun potenziale cliente per ora. Quando qualcuno ti viene presentato, o ti contatta, aggiungilo qui: Prisma ricorda chi te l'ha presentato."
    static let stimaDaInserire = "stima da inserire"
    static let informativaDaDare = "informativa da dare"
    static let datiDiProva = "dati di prova"
    static let nonInteressati = "Non interessati"
    static let tilePotenziali = "Potenziali clienti"
    static let tilePatrimonio = "Patrimonio stimato"
    static let tilePassaparola = "Dal passaparola"
    static let tileProbabile = "Probabile entro fine anno"

    /// «presentato da Marco» (il primo nome del cliente) o la fonte libera («dal sito dello studio»).
    static func fonte(_ p: PotenzialeCliente, clienti: [Cliente]) -> String? {
        if let da = p.presentatoDa, let c = clienti.first(where: { $0.id == da }) {
            return "presentato da " + TestiTraguardi.primoNome(c.nome)
        }
        return p.fonte
    }

    /// «2 senza stima».
    static func senzaStima(_ n: Int) -> String { "\(n) senza stima" }

    /// «3 senza data» (fuori dal probabile).
    static func esclusi(_ n: Int) -> String { n == 1 ? "1 senza tutti i dati" : "\(n) senza tutti i dati" }

    /// «45%» o «—».
    static func probabilita(_ p: Int?) -> String { p.map { "\($0)%" } ?? "—" }

    static func stima(_ s: Double?) -> String { s.map { Formati.euro($0) } ?? stimaDaInserire }

    /// Il toast all'arrivo di un nuovo cliente dal percorso.
    static func benvenuto(_ nome: String) -> String {
        "Nuovo cliente: \(TestiTraguardi.primoNome(nome)) entra nel passaparola"
    }

    static func avanzato(_ nome: String, _ fase: FasePotenziale) -> String {
        "\(TestiTraguardi.primoNome(nome)): \(fase.titolo.lowercased())"
    }

    static let scrivigliNonPronto = "Per scrivergli servono l'informativa data e il consenso a essere contattato."
    static let primoIncontroFissato = "Primo incontro fissato in Agenda"
    static let agendaPiena = "Nessuno spazio libero nelle prossime settimane: fissalo a mano in Agenda."

    // MARK: - Albero

    /// «CHI TI HA PRESENTATO CHI · DAL 2016» (senza date solo «Chi ti ha presentato chi»).
    static func etichettaAlbero(anno: Int?) -> String {
        anno.map { "CHI TI HA PRESENTATO CHI · DAL \($0)" } ?? "CHI TI HA PRESENTATO CHI"
    }

    static let notaAlbero = "La grandezza di ogni cerchio è il patrimonio. Le persone in grigio sono ancora potenziali clienti."
    static let vuotoAlbero = "Nessuna presentazione registrata per ora. Quando un cliente te ne presenta un altro, scrivilo nel suo dossier («Presentato da»): qui nasce l'albero."
    static let tu = "Tu"

    /// «+ 34 clienti senza presentazioni».
    static func senzaPresentazioni(_ n: Int) -> String {
        n == 1 ? "+ 1 cliente senza presentazioni" : "+ \(n) clienti senza presentazioni"
    }

    /// Il ciclo interrotto («A presenta B e B presenta A»).
    static func ciclo(_ nomi: [String]) -> String {
        "Presentazioni in cerchio interrotte: " + nomi.joined(separator: ", ") + ". Controlla «Presentato da» nei loro dossier."
    }

    /// «320.000 € · potenziale», «180.000 €», «—».
    static func cifraNodo(_ n: NodoPassaparola) -> String {
        let cifra = n.patrimonio.map { Formati.euro($0) } ?? "—"
        if case .potenziale = n.tipo { return cifra + " · potenziale" }
        return cifra
    }

    /// Il suggerimento al passaggio: nome, fase, patrimonio o stima, data della presentazione.
    static func suggerimento(_ n: NodoPassaparola) -> String {
        var parti = [n.nome]
        switch n.tipo {
        case .cliente: parti.append("cliente")
        case .potenziale: parti.append(n.fase.map { "potenziale · " + $0.titolo.lowercased() } ?? "potenziale")
        case .tu, .altri: break
        }
        if let p = n.patrimonio { parti.append(Formati.euro(p)) }
        if let d = n.presentatoIl { parti.append("presentato il " + Formati.dataEstesa.string(from: d)) }
        return parti.joined(separator: " · ")
    }

    // MARK: - Ambasciatori e quota

    static let ambasciatori = "I tuoi ambasciatori"
    static let nessunAmbasciatore = "Nessuno ancora"
    static let portato = "portato"
    static let inArrivo = "in arrivo"

    /// «3 persone presentate».
    static func presentati(_ n: Int) -> String { n == 1 ? "1 persona presentata" : "\(n) persone presentate" }

    /// «Il 38% del patrimonio nuovo degli ultimi tre anni è nato dal passaparola».
    static func quota(_ q: QuotaPassaparola) -> String {
        "Il \(Int((q.quota * 100).rounded()))% del patrimonio nuovo degli ultimi tre anni è nato dal passaparola"
    }

    /// La nota quando alcuni clienti non hanno «Cliente dal».
    static func notaQuota(_ q: QuotaPassaparola) -> String? {
        q.senzaDataVera > 0 ? "calcolato sui clienti con la data d'inizio (per \(q.senzaDataVera) vale la data della scheda)" : nil
    }

    // MARK: - Momento giusto

    static let momentoTitolo = "Il momento giusto per chiedere"
    static let preparaRichiesta = "Prepara la richiesta"
    static let messaggioPronto = "✓ Messaggio pronto"

    static func richiestaPronta(_ nome: String) -> String {
        "Richiesta per \(TestiTraguardi.primoNome(nome)) pronta in Messaggi: la spedisci tu"
    }

    /// Il fatto di un traguardo: «ha raggiunto «Rendita integrativa» ieri».
    static func fatto(_ t: Traguardo, oggi: Date, cal: Calendar) -> String {
        minuscola(t.titolo) + " " + TestiTraguardi.quando(t.data, oggi: oggi, cal: cal)
    }

    /// Il fatto di una firma: «ha firmato «Piano Futuro» ieri».
    static func firma(_ nome: String, il data: Date, oggi: Date, cal: Calendar) -> String {
        "ha firmato «\(nome)» " + TestiTraguardi.quando(data, oggi: oggi, cal: cal)
    }

    static func titoloRichiesta(_ nome: String) -> String { "Chiedere una presentazione a \(TestiTraguardi.primoNome(nome))" }
    static let oggettoRichiesta = "Un grazie"

    // MARK: - Colonne degli anni

    static let nuoviTitolo = "Nuovi clienti dal passaparola"

    /// «2026: 6 clienti nuovi dal passaparola su 11».
    static func colonnaAnno(anno: Int, dal: Int, totali: Int) -> String {
        "\(anno): \(dal) \(dal == 1 ? "cliente nuovo" : "clienti nuovi") dal passaparola su \(totali)"
    }

    // MARK: - Aiuti

    static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    static func minuscola(_ s: String) -> String { s.prefix(1).lowercased() + s.dropFirst() }
}
