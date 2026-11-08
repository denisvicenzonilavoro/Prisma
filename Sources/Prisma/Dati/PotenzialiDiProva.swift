import Foundation

/// DATI DI PROVA DICHIARATI (§9.2.5 punto 8): gli otto potenziali delle prime quattro colonne del template
/// (Design/template-luce.html, riga 2015), presentati dai clienti di prova (marco, sofia, giulia, andrea) o con una fonte
/// libera, con le date relative a oggi. Stima e probabilità sono quelle dimostrative del template, mai una regola di
/// Prisma (decisione 94). La vista dice «dati di prova» quando ce n'è almeno uno. Si tolgono con i clienti di prova
/// (`diProva`, `StatoShell.rimuoviDatiDiProva`).
enum PotenzialiDiProva {
    static let prefisso = "pot-prova-"

    /// (chiave, nome, presentatore o nil, fonte libera, stima, probabilità, fase, informativa data, chiusura entro l'anno)
    private static let elenco: [(String, String, String?, String?, Double, Int, FasePotenziale, Bool, Bool)] = [
        ("ferretti", "Paolo Ferretti", "marco", nil, 180_000, 20, .daContattare, false, false),
        ("galli", "Anna Galli", nil, "dal sito dello studio", 60_000, 15, .daContattare, false, false),
        ("neri", "Roberto Neri", "sofia", nil, 240_000, 25, .daContattare, true, false),
        ("fontana", "Chiara Fontana", "giulia", nil, 90_000, 40, .primoIncontro, true, true),
        ("sala", "Davide Sala", "marco", nil, 320_000, 45, .primoIncontro, true, true),
        ("conti", "Marta Conti", "andrea", nil, 75_000, 60, .analisi, true, true),
        ("ricci", "Luca Ricci", nil, "evento in Comune", 110_000, 55, .analisi, true, true),
        ("villa", "Sara Villa", "marco", nil, 150_000, 75, .proposta, true, true),
    ]

    /// Al secondo, come le date dell'archivio.
    private static func alSecondo(_ d: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: d.timeIntervalSinceReferenceDate.rounded(.down))
    }

    static func potenziali(oggi: Date = Date(), calendario: Calendar = Calendar(identifier: .gregorian)) -> [PotenzialeCliente] {
        let inizio = calendario.startOfDay(for: oggi)
        func giorno(_ n: Int) -> Date {
            let g = calendario.date(byAdding: .day, value: n, to: inizio) ?? inizio
            return alSecondo(calendario.date(bySettingHour: 10, minute: 0, second: 0, of: g) ?? g)
        }
        let anno = calendario.component(.year, from: oggi)
        let fineAnno = calendario.date(from: DateComponents(year: anno, month: 12, day: 31, hour: 12)) ?? oggi
        return elenco.enumerated().map { n, e -> PotenzialeCliente in
            let (chiave, nome, da, fonte, stima, prob, fase, informativa, entroAnno) = e
            var p = PotenzialeCliente(id: prefisso + chiave, nome: nome, creatoIl: giorno(-60 + n * 5))
            p.presentatoDa = da
            p.fonte = fonte
            p.patrimonioStimato = stima
            p.probabilita = prob
            p.fase = fase
            // Cinque entro il 31 dicembre, tre nell'anno dopo: la tile «Probabile entro fine anno» mostra la regola
            if entroAnno {
                p.chiusuraPrevista = alSecondo(min(giorno(20 + n * 4), fineAnno))
            } else {
                p.chiusuraPrevista = alSecondo(calendario.date(byAdding: .month, value: 3, to: fineAnno) ?? fineAnno)
            }
            // La storia: dalla prima fase a quella di oggi
            var storia = [CambioFase(fase: .daContattare, il: p.creatoIl)]
            var f = FasePotenziale.daContattare
            var passo = 1
            while f != fase, let s = f.successiva {
                f = s
                storia.append(CambioFase(fase: s, il: giorno(-60 + n * 5 + passo * 6)))
                passo += 1
            }
            p.storia = storia
            if informativa {
                p.informativaIl = p.creatoIl
                p.consensoContatto = true
            }
            p.diProva = true
            return p
        }
    }

    /// Solo se i clienti di prova ci sono (e i potenziali di prova non ci sono già).
    static func applica(_ d: inout DatiPrisma, oggi: Date = Date()) {
        let ids = Set(d.clienti.map(\.id))
        guard ["marco", "sofia", "giulia", "andrea"].allSatisfy({ ids.contains($0) }),
              !d.potenziali.contains(where: { $0.id.hasPrefix(prefisso) }) else { return }
        d.potenziali += potenziali(oggi: oggi)
    }

    /// Il passaparola dei clienti fittizi (`ClientiFittizi.completi()`): qualche presentatore fra i fittizi e verso marco,
    /// sofia e giulia, con una terza e una quarta generazione (per il «+ N»). Date relative a oggi.
    static func applicaFittizi(_ d: inout DatiPrisma, oggi: Date = Date(), calendario: Calendar = Calendar(identifier: .gregorian)) {
        let p = ClientiFittizi.prefisso
        // (presentato, presentatore, anni fa)
        let legami: [(String, String, Int)] = [
            ("ferraro", "marco", 9), ("galli", "marco", 6), ("marchetti", "sofia", 8), ("russo", "sofia", 4),
            ("colombo", "giulia", 3), ("esposito", "ferraro", 5), ("ricci", "ferraro", 2), ("fontana", "esposito", 1),
            ("conti-l", "fontana", 0), ("greco", "marchetti", 2),
        ]
        for (chi, da, anni) in legami {
            let idChi = p + chi
            let idDa = ["marco", "sofia", "giulia", "andrea", "laura"].contains(da) ? da : p + da
            guard let i = d.clienti.firstIndex(where: { $0.id == idChi }), d.clienti.contains(where: { $0.id == idDa }),
                  d.clienti[i].presentatoDa == nil else { continue }
            d.clienti[i].presentatoDa = idDa
            let quando = calendario.date(byAdding: .year, value: -anni, to: calendario.startOfDay(for: oggi)) ?? oggi
            d.clienti[i].presentatoIl = alSecondo(calendario.date(byAdding: .day, value: -30, to: quando) ?? quando)
        }
    }

    /// Per le istantanee 850-857: i tre clienti «già presentati» del template (Chiara Marino da Marco, Elena Marchi e Paola
    /// Leone da Sofia), solo nello stato della scena, mai nell'archivio di prova (così i 5 clienti di prova restano 5). Con
    /// una posizione di liquidità ciascuno (65.000, 140.000 e 188.000 €, riga 2020 del template) perché i nodi mostrino il
    /// patrimonio netto.
    static func clientiDelTemplate(oggi: Date = Date()) -> (clienti: [Cliente], posizioni: [Posizione]) {
        let cal = Calendar(identifier: .gregorian)
        let dati: [(String, String, String, TintaAvatar, String, Double, Int)] = [
            ("scena-chiara-marino", "Chiara Marino", "CM", .viola, "marco", 65_000, 4),
            ("scena-elena-marchi", "Elena Marchi", "EM", .rosa, "sofia", 140_000, 0),
            ("scena-paola-leone", "Paola Leone", "PL", .verde, "sofia", 188_000, 2),
        ]
        var clienti: [Cliente] = []
        var posizioni: [Posizione] = []
        for (id, nome, iniziali, tinta, da, valore, anni) in dati {
            let quando = alSecondo(cal.date(byAdding: .year, value: -anni, to: cal.date(byAdding: .month, value: -2, to: oggi) ?? oggi) ?? oggi)
            var c = Cliente(id: id, nome: nome, iniziali: iniziali, tinta: tinta, tema: "", email: "", telefono: "",
                            preferito: false, nota: "Dati di prova.", creatoIl: quando)
            c.presentatoDa = da
            c.presentatoIl = quando
            c.clienteDal = quando
            clienti.append(c)
            var pos = Posizione(clienteId: id, canale: .indipendente, stato: .inEssere, area: .liquidita, nome: "Conto (prova)")
            pos.id = "pos-\(id)"
            pos.controvalore = valore
            posizioni.append(pos)
        }
        return (clienti, posizioni)
    }

    /// Il potenziale del template già diventato cliente (Elena Marchi, colonna «Cliente»), collegato al cliente della scena.
    static func elenaInCliente(oggi: Date = Date()) -> PotenzialeCliente {
        var p = PotenzialeCliente(id: prefisso + "marchi", nome: "Elena Marchi", creatoIl: alSecondo(oggi.addingTimeInterval(-86_400 * 90)))
        p.presentatoDa = "sofia"
        p.patrimonioStimato = 140_000
        p.probabilita = 100
        p.fase = .cliente
        p.storia = [CambioFase(fase: .daContattare, il: p.creatoIl), CambioFase(fase: .cliente, il: alSecondo(oggi.addingTimeInterval(-86_400 * 10)))]
        p.informativaIl = p.creatoIl
        p.consensoContatto = true
        p.clienteId = "scena-elena-marchi"
        p.diProva = true
        return p
    }

    /// Via i potenziali di prova (chiamata da `rimuoviDatiDiProva`).
    static func togli(_ p: inout [PotenzialeCliente]) {
        p.removeAll { $0.diProva }
    }
}
