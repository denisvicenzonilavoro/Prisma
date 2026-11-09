import Foundation
import SwiftUI

// Il compositore del Prisma del cliente («Luce» giro 15, §2.1.5 punto 3): dai dati del cliente e dalle voci scelte
// costruisce `ContenutoPrismaCliente`, con le cifre già calcolate dai motori di Prisma (`MotoreObiettivo` per la quota già
// da parte, decisione 81; `MotoreLineaVita.calcola` una volta per età del cursore). Puro: niente stato, niente viste
// (SwiftUI solo per leggere i colori fissi delle aree in esadecimale). Le voci spente o non disponibili non entrano nel
// contenuto: nel JSON non c'è nulla di ciò che il consulente non ha scelto.

enum CompositorePrismaCliente {
    /// Il cursore del file (dentro `MotoreLineaVita.etaPensioneMinima…Massima`, 55-72).
    static let etaCursore = 58...70
    /// Le righe della tabella del PDF al posto del cursore.
    static let etaTabella = [60, 62, 64, 67, 70]
    static let massimoObiettivi = 3

    // MARK: Disponibilità delle voci

    /// Le voci che non si possono accendere, con il motivo (assente = disponibile).
    static func disponibilita(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], preparazione: PreparazioneLineaVita,
                              lettera: String?, film: Documento?, luce: Bool, giornata: Bool,
                              sinistri: [Sinistro]) -> [VoceFilePrisma: String] {
        let nome = TestiPrismaCliente.nomeBattesimo(cliente)
        var motivi: [VoceFilePrisma: String] = [:]
        if obiettiviScelti(obiettivi).isEmpty { motivi[.obiettivi] = TestiPrismaCliente.senzaObiettivi(nome) }
        if let i = preparazione.ingresso {
            if !etaCursore.contains(where: { $0 > i.etaOggi }) { motivi[.lineaVita] = TestiPrismaCliente.troppoAvanti(nome) }
        } else {
            motivi[.lineaVita] = preparazione.motivoAssente ?? "Per disegnare la linea della vita serve la data di nascita di \(nome)."
        }
        if lettera == nil { motivi[.lettera] = TestiPrismaCliente.senzaLettera }
        if film == nil { motivi[.film] = TestiPrismaCliente.senzaFilm }
        if !luce { motivi[.luce] = TestiPrismaCliente.senzaLuce }
        if !giornata { motivi[.giornata] = TestiPrismaCliente.senzaGiornata }
        if !sinistri.contains(where: { $0.clienteId == cliente.id && $0.mostraAlCliente == true }) {
            motivi[.sinistro] = TestiPrismaCliente.senzaSinistro
        }
        if !posizioni.contains(where: { $0.clienteId == cliente.id && $0.stato == .inEssere }) {
            motivi[.posizioni] = TestiPrismaCliente.senzaPosizioni
        }
        return motivi
    }

    /// Gli obiettivi che vanno nel file: solo con un importo, per priorità e poi per scadenza, al più tre.
    static func obiettiviScelti(_ obiettivi: [Obiettivo]) -> [Obiettivo] {
        let validi = obiettivi.filter { $0.importo > 0 && $0.importo.isFinite }
        let ordinati = validi.sorted { a, b in
            if a.priorita != b.priorita { return a.priorita > b.priorita }
            return a.scadenza < b.scadenza
        }
        return Array(ordinati.prefix(massimoObiettivi))
    }

    // MARK: Il contenuto

    static func componi(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], preparazione: PreparazioneLineaVita,
                        voci: Set<VoceFilePrisma>, lettera: String?, film: Data?, luce: Data?, giornata: Data?,
                        sinistri: [SinistroMini], consulente: String, avvertenze: [String], validoFinoAl: Date, oggi: Date,
                        diProva: Bool, conFilm: Bool = false) -> ContenutoPrismaCliente {
        let mie = posizioni.filter { $0.clienteId == cliente.id }
        let creato = Date(timeIntervalSinceReferenceDate: oggi.timeIntervalSinceReferenceDate.rounded(.down))
        let fino = Date(timeIntervalSinceReferenceDate: validoFinoAl.timeIntervalSinceReferenceDate.rounded(.down))

        var miniObiettivi: [ObiettivoMini]?
        if voci.contains(.obiettivi) {
            let scelti = obiettiviScelti(obiettivi.filter { $0.clienteId == cliente.id })
            let elenco = scelti.map { o -> ObiettivoMini in
                ObiettivoMini(titolo: o.titolo, quota: quota(o, posizioni: mie, oggi: oggi),
                              coloreHex: coloreHex(Tema.Apple.Clienti.Obiettivi.colore(o.area)))
            }
            miniObiettivi = elenco.isEmpty ? nil : elenco
        }

        let linea = voci.contains(.lineaVita) ? lineaVita(preparazione) : nil

        var miniPosizioni: [PosizioneMini]?
        if voci.contains(.posizioni) {
            let elenco = mie.filter { $0.stato == .inEssere }
                .sorted { $0.valore > $1.valore }
                .map { p in
                    PosizioneMini(nome: p.nome, canale: p.canale.nomeBreve,
                                  coloreCanaleHex: p.canale == .alleanza ? Tema.Apple.PrismaCliente.canaleAlleanzaHex
                                      : Tema.Apple.PrismaCliente.canaleIndipendenteHex,
                                  valore: p.valore, data: secondi(p.dataValore ?? creato))
                }
            miniPosizioni = elenco.isEmpty ? nil : elenco
        }

        let testoLettera: String? = voci.contains(.lettera) ? lettera.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 } : nil
        let miniSinistri: [SinistroMini]? = voci.contains(.sinistro) && !sinistri.isEmpty
            ? sinistri.map { s -> SinistroMini in var m = s; m.aggiornatoIl = secondi(s.aggiornatoIl); return m } : nil
        return ContenutoPrismaCliente(nomeBattesimo: TestiPrismaCliente.nomeBattesimo(cliente), consulente: consulente,
                                      creatoIl: creato, validoFinoAl: fino, obiettivi: miniObiettivi, lineaVita: linea,
                                      lettera: testoLettera, film: voci.contains(.film) ? film : nil,
                                      luce: voci.contains(.luce) ? luce : nil,
                                      giornata: voci.contains(.giornata) ? giornata : nil,
                                      sinistri: miniSinistri, posizioni: miniPosizioni, avvertenze: avvertenze, diProva: diProva,
                                      conFilm: voci.contains(.film) && (conFilm || film != nil))
    }

    /// Una data al secondo intero (il JSON del file porta le date ISO 8601 senza frazioni).
    static func secondi(_ d: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: d.timeIntervalSinceReferenceDate.rounded(.down))
    }

    /// La quota già da parte (decisione 81): `disponibileOggi / importo`, fra 0 e 1.
    static func quota(_ o: Obiettivo, posizioni: [Posizione], oggi: Date) -> Double {
        guard o.importo > 0 else { return 0 }
        let q = MotoreObiettivo.calcola(o, posizioni: posizioni, data: oggi).disponibileOggi / o.importo
        guard q.isFinite else { return 0 }
        return min(1, max(0, q))
    }

    /// Le serie della linea della vita per ogni età del cursore dopo quella di oggi (nil senza ingresso o senza età).
    static func lineaVita(_ p: PreparazioneLineaVita) -> LineaVitaMini? {
        guard let i0 = p.ingresso else { return nil }
        let eta = etaCursore.filter { $0 > i0.etaOggi }
        guard let prima = eta.first else { return nil }
        let serie = eta.map { e -> SerieLineaVita in
            var i = i0
            i.etaPensione = e
            let r = MotoreLineaVita.calcola(i)
            return SerieLineaVita(etaPensione: e, valori: r.punti.map(\.valore), etaEsaurimento: r.etaEsaurimento)
        }
        let proposta = min(max(i0.etaPensione, prima), etaCursore.upperBound)
        var ip = i0
        ip.etaPensione = proposta
        let indicativa = MotoreLineaVita.calcola(ip).dopoPensioneIndicativa
        return LineaVitaMini(etaOggi: i0.etaOggi, etaProposta: proposta, etaFine: max(i0.etaFine, i0.etaOggi), serie: serie,
                             indicativa: indicativa)
    }

    /// Le righe della tabella del PDF: «Se vai in pensione a 60 anni · I risparmi bastano …» (solo le età calcolate).
    static func righeTabella(_ l: LineaVitaMini) -> [(eta: Int, frase: String)] {
        etaTabella.compactMap { e in
            guard let s = l.serie.first(where: { $0.etaPensione == e }) else { return nil }
            return (e, TestiPrismaCliente.frasePensione(esaurimento: s.etaEsaurimento, etaFine: l.etaFine))
        }
    }

    /// Un colore fisso in esadecimale «#RRGGBB», risolto nell'aspetto chiaro (la mini-app e il file sono sempre chiari).
    static func coloreHex(_ c: Color) -> String {
        var env = EnvironmentValues()
        env.colorScheme = .light
        let r = c.resolve(in: env)
        func h(_ v: Float) -> String { String(format: "%02X", Int((min(max(Double(v), 0), 1) * 255).rounded())) }
        return "#" + h(r.red) + h(r.green) + h(r.blue)
    }
}
