import Foundation
import simd

/// Prove della realtà aumentata (Design/template-luce-specifica.md §2.3, «Luce» giro 16): per i clienti del template
/// le quote sommano a 1, nessuno strato a zero, strati nell'ordine delle classi, totale uguale alla composizione di
/// Analisi 360, primo anno = oggi, ultimo anno all'età di pensione, altezza fra 0,85 e 2,2 unità; senza posizioni il
/// cristallo è spento, senza data di nascita niente anni; la maglia è chiusa e ben orientata; la crescita rimbalza; il
/// passaggio dal tavolo torna uguale; i testi non portano cifre inventate. Chiamata da `ProvaCalcoli.esegui()` (gira
/// anche nel simulatore iOS: non usa RealityKit).
enum ProvaCalcoliRealta {
    static func esegui(_ verifica: VerificaCalcoli) {
        demo(verifica)
        casi(verifica)
        maglia(verifica)
        movimento(verifica)
        tavolo(verifica)
        testi(verifica)
    }

    /// I clienti del template.
    private static func demo(_ verifica: VerificaCalcoli) {
        let d = DatiPrisma.demo()
        for c in d.clienti {
            let e = MotoreRealtaAumentata.calcola(cliente: c, posizioni: d.posizioni, obiettivi: d.obiettivi, eventi: d.eventiVita,
                                                  analisi: d.analisi[c.id], oggi: AiutiProva.oggi)
            let comp = MotoreAree360.composizione(d.posizioni.filter { $0.clienteId == c.id }, cliente: c)
            verifica("Realtà: \(c.id), totale = composizione di Analisi 360", e.totaleOggi, comp.totale)
            guard !e.vuota else { continue }
            verifica("Realtà: \(c.id), quote che sommano a 1", e.strati.reduce(0) { $0 + $1.quota }, 1, tolleranza: 1e-9)
            verifica.vero("Realtà: \(c.id), nessuno strato a zero", e.strati.allSatisfy { $0.quota > 0 && $0.valoreOggi > 0 })
            let ordine = ComposizioneInvestimenti360.Classe.allCases
            let posti = e.strati.compactMap { s in ordine.firstIndex(of: s.classe) }
            verifica.vero("Realtà: \(c.id), strati nell'ordine delle classi", posti == posti.sorted() && Set(posti).count == posti.count)
            let b = e.bordi
            verifica.vero("Realtà: \(c.id), bordi da 0 a 1 crescenti",
                          b.count == e.strati.count + 1 && b.first == 0 && b.last == 1 && zip(b, b.dropFirst()).allSatisfy { $0 < $1 })
            if let primo = e.anni.first {
                verifica("Realtà: \(c.id), il primo anno è il totale di oggi", primo.totale, e.totaleOggi)
                let prep = MotoreLineaVita.prepara(cliente: c, posizioni: d.posizioni.filter { $0.clienteId == c.id },
                                                   obiettivi: d.obiettivi, eventi: d.eventiVita, analisi: d.analisi[c.id],
                                                   oggi: AiutiProva.oggi)
                if let i = prep.ingresso, let ultimo = e.anni.last {
                    verifica("Realtà: \(c.id), l'ultimo anno è all'età di pensione", Double(ultimo.eta), Double(max(i.etaOggi, i.etaPensione)))
                }
            }
            for anno in [e.annoOggi, e.annoFine] {
                let h = e.altezza(anno: anno)
                verifica.vero("Realtà: \(c.id), altezza fra 0,85 e 2,2 unità", h >= 0.85 - 1e-9 && h <= 2.2 + 1e-9)
            }
            if let fine = e.annoFine, let s = e.strati.first {
                verifica("Realtà: \(c.id), valore dello strato con la quota di oggi", e.valore(s, anno: fine), e.totale(anno: fine) * s.quota)
            }
        }
    }

    /// Senza posizioni e senza data di nascita.
    private static func casi(_ verifica: VerificaCalcoli) {
        var c = Cliente.nuovo(tinta: .blu)
        c.nome = "Cliente di prova"
        let vuota = MotoreRealtaAumentata.calcola(cliente: c, posizioni: [], obiettivi: [], eventi: [], analisi: nil, oggi: AiutiProva.oggi)
        verifica.vero("Realtà: senza posizioni il cristallo è spento", vuota.vuota && vuota.strati.isEmpty)
        let azioni = AiutiProva.posizione("Fondo azionario", .investimento, 61_300) {
            $0.clienteId = c.id
            $0.quotaAzionaria = 100
            $0.quotaTitoliStato = 0
        }
        let conto = AiutiProva.posizione("Conto", .liquidita, 17_450, canale: .alleanza) { $0.clienteId = c.id }
        let e = MotoreRealtaAumentata.calcola(cliente: c, posizioni: [azioni, conto], obiettivi: [], eventi: [], analisi: nil,
                                              oggi: AiutiProva.oggi)
        verifica.vero("Realtà: senza data di nascita niente anni", e.anni.isEmpty && e.annoOggi == nil)
        verifica.vero("Realtà: senza data di nascita la frase lo dice", e.motivoSenzaAnni == TestiRealta.senzaAnni("Cliente"))
        verifica.vero("Realtà: classi a zero escluse", !e.strati.contains { $0.classe == .obbligazionario || $0.classe == .gestioneSeparata })
        verifica.vero("Realtà: la liquidità è l'ultimo strato", e.strati.last?.classe == .liquidita)
        verifica("Realtà: senza anni l'altezza è piena", e.altezza(anno: nil), MotoreRealtaAumentata.altezzaBase + MotoreRealtaAumentata.altezzaVariabile,
                 tolleranza: 1e-9)
    }

    /// La maglia di uno strato: vertici e normali in coppia, indici validi, triangoli non vuoti e orientati, normali
    /// di lunghezza 1, laterali orizzontali, coperchio alto verso l'alto, chiusa (ogni spigolo in due triangoli).
    private static func maglia(_ verifica: VerificaCalcoli) {
        let m = MotoreRealtaAumentata.maglia(basso: 0.1, alto: 0.6)
        verifica.vero("Realtà: tante normali quanti vertici", m.posizioni.count == m.normali.count && !m.posizioni.isEmpty)
        verifica.vero("Realtà: indici a gruppi di tre e dentro i vertici",
                      m.indici.count % 3 == 0 && m.indici.allSatisfy { Int($0) < m.posizioni.count })
        verifica.vero("Realtà: normali di lunghezza 1", m.normali.allSatisfy { abs(simd_length($0) - 1) < 1e-4 })
        var areePositive = true
        var orientati = true
        var chiave: [String: Int] = [:]
        func punto(_ p: SIMD3<Float>) -> String {
            String(format: "%.4f,%.4f,%.4f", Double(p.x), Double(p.y), Double(p.z))
        }
        for t in stride(from: 0, to: m.indici.count, by: 3) {
            let a = Int(m.indici[t]), b = Int(m.indici[t + 1]), c = Int(m.indici[t + 2])
            let n = simd_cross(m.posizioni[b] - m.posizioni[a], m.posizioni[c] - m.posizioni[a])
            if simd_length(n) <= 1e-9 { areePositive = false }
            let media = m.normali[a] + m.normali[b] + m.normali[c]
            if simd_dot(n, media) <= 0 { orientati = false }
            // Gli spigoli per posizione (i coperchi hanno vertici propri): ognuno deve stare in due triangoli
            for (x, y) in [(a, b), (b, c), (c, a)] {
                let k = [punto(m.posizioni[x]), punto(m.posizioni[y])].sorted().joined(separator: "|")
                chiave[k, default: 0] += 1
            }
        }
        verifica.vero("Realtà: triangoli con area > 0", areePositive)
        verifica.vero("Realtà: triangoli in senso antiorario visti da fuori", orientati)
        // Le diagonali dei lati sono spigoli interni (due triangoli), i bordi fra lato e coperchio anche: tutti 2
        verifica.vero("Realtà: maglia chiusa (ogni spigolo in due triangoli)", chiave.values.allSatisfy { $0 == 2 })
        let laterali = m.normali.filter { abs($0.y) < 1e-6 }
        verifica.vero("Realtà: normali laterali orizzontali", !laterali.isEmpty)
        verifica.vero("Realtà: coperchio alto con normale (0, 1, 0)",
                      zip(m.posizioni, m.normali).contains { abs($0.0.y - 0.6) < 1e-6 && $0.1 == SIMD3<Float>(0, 1, 0) })
        let pianta = MotoreRealtaAumentata.pianta()
        verifica("Realtà: punti della pianta", Double(pianta.count), Double(3 * (MotoreRealtaAumentata.segmentiAngolo + 1)))
        verifica.vero("Realtà: la pianta sta nel raggio",
                      pianta.allSatisfy { simd_length($0) <= MotoreRealtaAumentata.raggio + 1e-4 })
        verifica.vero("Realtà: il vertice della pianta va verso −z", (pianta.map(\.y).min() ?? 0) < -0.3)
        // Gli estremi: fessura fra gli strati, esploso che alza di 0,2 × indice, crescita intorno alla base
        let bordi = [0, 0.5, 1.0]
        let primo = MotoreRealtaAumentata.estremi(strato: 0, bordi: bordi, altezza: 2, esploso: 0, crescita: 1)
        let secondo = MotoreRealtaAumentata.estremi(strato: 1, bordi: bordi, altezza: 2, esploso: 0, crescita: 1)
        verifica("Realtà: la base dello strato più basso è a 0", Double(primo.basso), 0, tolleranza: 1e-6)
        verifica("Realtà: la fessura fra gli strati", Double(secondo.basso - primo.alto), Double(MotoreRealtaAumentata.fessura), tolleranza: 1e-6)
        let esploso = MotoreRealtaAumentata.estremi(strato: 1, bordi: bordi, altezza: 2, esploso: 1, crescita: 1)
        verifica("Realtà: l'esploso alza lo strato di 0,2", Double(esploso.basso - secondo.basso), 0.2, tolleranza: 1e-6)
        let mezzo = MotoreRealtaAumentata.estremi(strato: 1, bordi: bordi, altezza: 2, esploso: 0, crescita: 0.5)
        verifica.vero("Realtà: la crescita schiaccia verso la base", mezzo.alto < secondo.alto)
    }

    private static func movimento(_ verifica: VerificaCalcoli) {
        verifica("Realtà: crescita a 0", MotoreRealtaAumentata.crescita(0), 0, tolleranza: 1e-9)
        verifica("Realtà: crescita a 1,5 s", MotoreRealtaAumentata.crescita(1.5), 1, tolleranza: 0.01)
        let massimo = stride(from: 0.0, through: 1.5, by: 0.01).map(MotoreRealtaAumentata.crescita).max() ?? 0
        verifica.vero("Realtà: la crescita ha il rimbalzo", massimo > 1)
        let x = MotoreRealtaAumentata.insegui(0, verso: 1, velocita: 5, dt: 0.2)
        verifica("Realtà: inseguimento esponenziale", x, 1 - exp(-1), tolleranza: 1e-9)
        verifica("Realtà: inseguimento fermo senza tempo", MotoreRealtaAumentata.insegui(0.3, verso: 1, velocita: 5, dt: 0), 0.3, tolleranza: 1e-12)
    }

    /// Il passaggio dal tavolo: uguale all'andata e al ritorno, classi sconosciute scartate.
    private static func tavolo(_ verifica: VerificaCalcoli) {
        let d = DatiPrisma.demo()
        guard let c = d.clienti.first(where: { cl in
            !MotoreRealtaAumentata.calcola(cliente: cl, posizioni: d.posizioni, obiettivi: d.obiettivi, eventi: d.eventiVita,
                                           analisi: d.analisi[cl.id], oggi: AiutiProva.oggi).vuota
        }) else { return verifica.vero("Realtà: un cliente del template ha il cristallo", false) }
        let e = MotoreRealtaAumentata.calcola(cliente: c, posizioni: d.posizioni, obiettivi: d.obiettivi, eventi: d.eventiVita,
                                              analisi: d.analisi[c.id], oggi: AiutiProva.oggi)
        let t = MotoreRealtaAumentata.tavolo(e, nome: TestiRealta.primoNome(c.nome), scattoConStanza: false)
        let r = MotoreRealtaAumentata.daTavolo(t)
        verifica.vero("Realtà: dal tavolo tornano gli stessi strati", r.strati == e.strati)
        verifica.vero("Realtà: dal tavolo tornano gli stessi anni e la stima", r.anni == e.anni && r.stimata == e.stimata)
        verifica.vero("Realtà: al tavolo solo il nome di battesimo", t.nome == TestiRealta.primoNome(c.nome) && !t.nome.contains(" "))
        var guasto = t
        guasto.strati.append(StratoRealtaTavolo(classe: "ologramma", nome: "Ologramma", quota: 0.1, valoreOggi: 1_234))
        verifica.vero("Realtà: una classe sconosciuta si scarta", MotoreRealtaAumentata.daTavolo(guasto).strati.count == e.strati.count)
    }

    /// Nessuna frase fissa con cifre inventate o nomi di clienti.
    private static func testi(_ verifica: VerificaCalcoli) {
        let tutte = TestiRealta.tutte
        verifica.vero("Realtà: i testi non portano la cifra del template", !tutte.contains { $0.contains("204.050") || $0.contains("204050") })
        verifica.vero("Realtà: i testi non portano nomi di clienti", !tutte.contains { $0.contains("Giulia") || $0.contains("Rossi") })
        verifica.vero("Realtà: i testi non portano cifre", !tutte.contains { $0.rangeOfCharacter(from: .decimalDigits) != nil })
        verifica.vero("Realtà: il nome arriva da fuori", TestiRealta.fotoSalvata("Anna Bianchi") == "Foto salvata nel dossier di Anna Bianchi")
    }
}
