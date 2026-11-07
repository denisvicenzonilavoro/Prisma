import Foundation
import PDFKit

/// Prova del report «Un anno insieme», dentro `Prisma --prova-prospetti`: il motore su un caso costruito a mano
/// (valore al 1° gennaio dallo storico, versamenti dell'anno, andamento, calo, traguardo), poi il PDF dei 5 clienti
/// di prova: si crea, è A4 orizzontale, ha le avvertenze in ogni pagina, il canale riconoscibile, le cifre del
/// motore e nessuna parola di promessa («garantito», «sicuro», «certo»). Entra nel fascicolo della revisione.
/// La chiama `ProvaProspetti.esegui` prima del riepilogo, con la sua funzione di verifica.
@MainActor
enum ProvaAnnoInsieme {
    static func esegui(_ verifica: (String, Bool, String) -> Void, cartella: URL?) {
        provaMotore(verifica)

        let stato = StatoShell(persistente: false)
        let avvertenza = "I rendimenti passati non sono indicativi di quelli futuri"
        for c in stato.clienti.prefix(5) {
            let nome = "anno-insieme-\(c.id)"
            stato.clienteAttivoId = c.id
            guard let t = stato.testiAnnoInsieme(c.id), let d = stato.documentoProspetto(.annoInsieme) else {
                verifica("\(nome): report composto", false, "")
                continue
            }
            let a = t.a
            verifica("\(nome): almeno 4 pagine (prima, l'anno, la protezione, cosa ci aspetta)", d.pagine.count >= 4, "\(d.pagine.count) pagine")
            guard let pdf = StampaCarta.pdf(d), let documento = PDFDocument(data: pdf) else {
                verifica("\(nome): PDF creato", false, "")
                continue
            }
            verifica("\(nome): PDF di \(d.pagine.count) pagine", documento.pageCount == d.pagine.count,
                     "\(documento.pageCount) pagine, \(pdf.count / 1024) KB")
            let box = documento.page(at: 0)?.bounds(for: .mediaBox) ?? .zero
            verifica("\(nome): A4 orizzontale", box.width > box.height, "\(Int(box.width))×\(Int(box.height))")

            let pagine = StampaCarta.testo(pdf).map { ProvaProspetti.spazi($0) }
            let testo = pagine.joined(separator: " ")
            let minuscolo = testo.lowercased()
            verifica("\(nome): il cliente e il titolo", testo.contains(c.nome) && minuscolo.contains("un anno insieme"), "")
            let senzaAvvertenze = pagine.enumerated().filter { !$0.element.contains(avvertenza) }.map { "\($0.offset + 1)" }
            verifica("\(nome): avvertenze a piè di ogni pagina", senzaAvvertenze.isEmpty,
                     senzaAvvertenze.isEmpty ? "" : "mancano a pagina \(senzaAvvertenze.joined(separator: ", "))")
            let prima = (pagine.first ?? "").lowercased()
            let canaliMancanti = a.canali.filter { !prima.contains($0.nome.lowercased()) }.map(\.nomeBreve)
            verifica("\(nome): il canale in testa alla prima pagina", canaliMancanti.isEmpty,
                     a.canali.map(\.nomeBreve).joined(separator: " e "))

            // «Cosa ci aspetta» si chiama col periodo vero (da oggi a 12 mesi), non «Nel» anno successivo:
            // a fine anno le scadenze cadono anche nell'anno in corso
            verifica("\(nome): «\(TestiAnnoInsieme.titoloPeriodoAvanti)» nel PDF, mai «Nel \(a.anno + 1)»",
                     minuscolo.contains(TestiAnnoInsieme.periodoAvanti) && !testo.contains("Nel \(a.anno + 1)"), "")
            let orizzonte = Calendar.current.date(byAdding: .month, value: MotoreAnnoInsieme.mesiAvanti, to: a.oggi) ?? a.oggi
            verifica("\(nome): le scadenze di «cosa ci aspetta» fra oggi e 12 mesi",
                     a.scadenze.allSatisfy { $0.data >= Calendar.current.startOfDay(for: a.oggi) && $0.data <= orizzonte }, "")

            // Le cifre sono quelle del motore, e il patrimonio di oggi è quello del riepilogo delle posizioni
            let mie = stato.posizioniCliente(c.id)
            let riepilogo = RiepilogoPosizioni(mie)
            let protezione = mie.filter { $0.stato == .inEssere && $0.area == .protezione }.reduce(0) { $0 + $1.valore }
            verifica("\(nome): patrimonio di oggi come il riepilogo", abs(a.patrimonioFine - (riepilogo.patrimonioNetto - protezione)) < 0.5,
                     "\(Int(a.patrimonioFine)) contro \(Int(riepilogo.patrimonioNetto - protezione))")
            for cifra in [CifreDoc.euro(a.patrimonioFine), CifreDoc.euro(a.patrimonioInizio), CifreDoc.euro(a.versamenti)] {
                verifica("\(nome): \(cifra) nel PDF", testo.contains(ProvaProspetti.spazi(cifra)), "")
            }
            if a.esposte {
                verifica("\(nome): andamento \(CifreDoc.euroSegno(a.andamento)) nel PDF", testo.contains(ProvaProspetti.spazi(CifreDoc.euroSegno(a.andamento))), "")
            }
            for o in a.obiettivi.prefix(Tema.Apple.CartaAnno.Righe.obiettivi) {
                verifica("\(nome): obiettivo «\(o.obiettivo.titolo)» da \(TestiAnnoInsieme.quota(o.quotaInizio)) a \(TestiAnnoInsieme.quota(o.quotaFine))",
                         testo.contains(ProvaProspetti.spazi(t.confrontoObiettivo(o))) && o.quotaInizio >= 0 && o.quotaFine <= 1, "")
            }

            // Niente parole di promessa (tolti i nomi propri: posizioni, prodotti, obiettivi, cliente)
            let vietate = paroleVietate(testo, togliendo: mie.flatMap { [$0.nome, $0.emittente, $0.tipologia] }
                                        + stato.dati.prodotti.map(\.nome) + a.obiettivi.map(\.obiettivo.titolo) + [c.nome])
            verifica("\(nome): nessuna parola di promessa", vietate.isEmpty, vietate.joined(separator: ", "))

            if let cartella { try? pdf.write(to: cartella.appendingPathComponent("\(nome).pdf")) }
        }

        // Nel fascicolo della revisione periodica: «Un anno insieme» apre i report
        var revisione = Appuntamento.nuovo(clienteId: "giulia", giorno: Date())
        revisione.tipo = .revisione
        let scelti = TipoProspetto.perIncontro(revisione, posizione: nil)
        verifica("Un anno insieme: nel fascicolo della revisione", scelti.contains(.annoInsieme) && TipoProspetto.annoInsieme.report == .annoInsieme, "")
        stato.clienteAttivoId = "giulia"
        stato.sceltaFascicolo = [.annoInsieme, .resoconto]
        if let f = stato.documentoFascicolo(), let d = stato.documentoProspetto(.annoInsieme),
           let r = stato.documentoProspetto(.resoconto(report: true)) {
            verifica("Un anno insieme: nel fascicolo con il resoconto", f.pagine.count == 2 + d.pagine.count + r.pagine.count,
                     "\(f.pagine.count) pagine")
        } else {
            verifica("Un anno insieme: fascicolo composto", false, "")
        }
    }

    /// Le parole di promessa trovate nel testo (parole intere, senza distinguere maiuscole), dopo aver tolto i nomi propri.
    static func paroleVietate(_ testo: String, togliendo nomi: [String]) -> [String] {
        var pulito = testo.lowercased()
        for n in nomi.map({ ProvaProspetti.spazi($0).lowercased() }).filter({ !$0.isEmpty }).sorted(by: { $0.count > $1.count }) {
            pulito = pulito.replacingOccurrences(of: n, with: " ")
        }
        let schema = "\\b(" + TestiAnnoInsieme.paroleVietate.joined(separator: "|") + ")\\b"
        guard let re = try? NSRegularExpression(pattern: schema, options: [.caseInsensitive]) else { return ["schema non valido"] }
        let intervallo = NSRange(pulito.startIndex..., in: pulito)
        let trovate = re.matches(in: pulito, range: intervallo).compactMap { m in Range(m.range, in: pulito).map { String(pulito[$0]) } }
        return Array(Set(trovate)).sorted()
    }

    /// Il motore su un caso costruito a mano, a una data fissa (3 novembre 2026).
    private static func provaMotore(_ verifica: (String, Bool, String) -> Void) {
        let cal = Calendar.current
        func giorno(_ a: Int, _ m: Int, _ g: Int, _ ora: Int = 0) -> Date {
            cal.date(from: DateComponents(year: a, month: m, day: g, hour: ora)) ?? Date()
        }
        let oggi = giorno(2026, 11, 3, 12)
        guard let c = DatiPrisma.demo().clienti.first else {
            verifica("Un anno insieme: cliente di prova", false, "")
            return
        }
        var p = Posizione(clienteId: c.id, canale: .indipendente, stato: .inEssere, area: .risparmio, nome: "Piano di prova")
        p.decorrenza = giorno(2024, 11, 3, 12)
        p.versamentoIniziale = 7_600
        p.premio = 100
        p.frequenza = .mensile
        p.rilevazioni = [Rilevazione(data: giorno(2026, 1, 1), controvalore: 10_000, versato: 10_000)]
        p.controvalore = 11_000
        p.totaleVersato = 10_600
        p.dataValore = oggi
        var nuova = Posizione(clienteId: c.id, canale: .alleanza, stato: .inEssere, area: .investimento, nome: "Nuova di prova")
        nuova.decorrenza = giorno(2026, 3, 15, 12)
        nuova.versamentoIniziale = 5_000
        nuova.controvalore = 5_000
        nuova.dataValore = oggi
        var o = Obiettivo(clienteId: c.id, titolo: "Obiettivo di prova", area: .casa, importo: 20_000, scadenza: giorno(2029, 10, 1))
        o.posizioniCollegate = [p.id]
        let protezione = MotoreProtezioneFamiglia.calcola([], cliente: c, analisi: IpotesiProtezione(), data: oggi)
        let a = MotoreAnnoInsieme.calcola(cliente: c, posizioni: [p, nuova], appuntamenti: [], incontri: [], obiettivi: [o],
                                          protezione: protezione, oggi: oggi)
        let piano = a.voci.first { $0.posizione.id == p.id }
        verifica("Un anno insieme: valore al 1° gennaio dallo storico", abs((piano?.inizio ?? 0) - 10_000) < 0.5, "\(Int(piano?.inizio ?? 0))")
        verifica("Un anno insieme: versamenti dell'anno ricostruiti", abs((piano?.versato ?? 0) - 600) < 0.5, "\(Int(piano?.versato ?? 0))")
        verifica("Un anno insieme: la posizione nuova parte da zero con il suo versamento",
                 a.voci.first { $0.posizione.id == nuova.id }.map { $0.inizio < 0.5 && abs($0.versato - 5_000) < 0.5 && $0.nuova } ?? false, "")
        verifica("Un anno insieme: andamento al netto dei versamenti", abs(a.andamento - 400) < 0.5, "\(Int(a.andamento))")
        verifica("Un anno insieme: patrimonio da 10.000 a 16.000 €", abs(a.patrimonioInizio - 10_000) < 0.5 && abs(a.patrimonioFine - 16_000) < 0.5,
                 "\(Int(a.patrimonioInizio)) → \(Int(a.patrimonioFine))")
        verifica("Un anno insieme: obiettivo dal 50% al 55%",
                 a.obiettivi.first.map { abs($0.quotaInizio - 0.5) < 0.001 && abs($0.quotaFine - 0.55) < 0.001 } ?? false, "")
        verifica("Un anno insieme: la posizione nuova è un momento dell'anno", a.momenti.contains { $0.titolo == nuova.nome && $0.tono == .novita }, "")
        verifica("Un anno insieme: i canali delle posizioni", Set(a.canali) == Set(Canale.allCases), "")

        // Il calo più forte da un mese all'altro, e il traguardo superato
        let giorni = [giorno(2026, 1, 1), giorno(2026, 2, 1), giorno(2026, 3, 1)]
        let calo = MotoreAnnoInsieme.caloMaggiore(giorni: giorni, valori: [100, 90, 95])
        verifica("Un anno insieme: calo del 10% a febbraio, non ancora ripreso",
                 calo.map { abs($0.quota - 0.1) < 0.0001 && $0.data == giorni[1] && !$0.ripreso } ?? false, "")
        verifica("Un anno insieme: niente calo sotto la soglia", MotoreAnnoInsieme.caloMaggiore(giorni: giorni, valori: [100, 99, 101]) == nil, "")
        let t = TestiAnnoInsieme(a)
        let vietate = paroleVietate(([t.comeEAndata, t.fraseAndamento, t.fraseProtezione] + t.testoMercati + t.prossimiPassi).joined(separator: " "),
                                    togliendo: [])
        verifica("Un anno insieme: i testi del caso di prova senza parole di promessa", vietate.isEmpty, vietate.joined(separator: ", "))
    }
}
