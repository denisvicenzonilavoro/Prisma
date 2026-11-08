#if os(macOS)
import Foundation

/// Le istantanee del giro 8 di «Luce», «Sala: racconti senza uscita» (Design/template-luce-specifica.md §3.1.7, §4.3.7,
/// §4.4.7), tutte nello stato finale (`\.modoIstantanea`: numeri completi, linee tracciate), mai Qwen:
/// - 640: la lettera dal futuro di Giulia, «Con il piano», lettera fissa intera, tile contate (chiaro e scuro);
///   641: «Senza il piano» (chiaro e scuro); 642: l'avviso arancio «Vera non è pronta»; 643: Andrea senza data di
///   nascita (lo stato con «Completa l'anagrafica ›», chiaro e scuro);
/// - 670: Lancia l'anno all'inizio (solo pallini e la frase); 671: dieci anni a seme fisso, l'ultima carta un evento
///   coperto con l'indennizzo stimato e quella di prima a 0,4 (chiaro e scuro); 672: la fine della partita;
///   673: Giulia senza proposte né versamenti («le due vite sarebbero uguali»);
/// - 675: Quanto vale avermi accanto, Giulia con tutte le voci (chiaro e scuro); 676: solo deduzioni e protezione
///   («vale almeno …»); 677: Andrea, «presto per misurare»; 678: il dettaglio di «Costi tagliati».
/// DATI DI PROVA DICHIARATI (solo dentro queste scene, lo stato non si salva): le ipotesi di previdenza di Giulia
/// confermate (1.400 € / 2.200 €), 550 € al mese per l'anticipo della casa, una polizza infortuni in proposta con
/// 9.000 € di indennizzo stimato, l'inizio del rapporto, le raccomandazioni accettate, le posizioni «pos-prova-valore-…»,
/// una parcella pagata e le raccomandazioni del track record di prova (`Istantanee.trackRecordDiProva`). Cifre
/// dimostrative per vedere le schermate, non dati veri; a schermo «dati di prova».
extension Istantanee {
    nonisolated static var sceneSalaRacconti: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        // §3.1: la lettera dal futuro
        coppia("640-sala-lettera") { s in
            preparaLettera(s)
            s.sala.versioneLettera = .conPiano
            s.apriEsperienza(.lettera, cliente: "giulia")
        }
        coppia("641-sala-lettera-senza-piano") { s in
            preparaLettera(s)
            s.sala.versioneLettera = .senzaPiano
            s.apriEsperienza(.lettera, cliente: "giulia")
        }
        una("642-sala-lettera-vera-non-pronta") { s in
            preparaLettera(s)
            s.sala.versioneLettera = .conPiano
            s.sala.letteraNonProntaIstantanea = true
            s.apriEsperienza(.lettera, cliente: "giulia")
        }
        coppia("643-sala-lettera-dati-mancanti") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "andrea" }) { s.dati.clienti[i].dataNascita = nil }
            s.apriEsperienza(.lettera, cliente: "andrea")
        }
        // §4.3: Lancia l'anno
        una("670-sala-lancia-inizio") { s in
            preparaLancia(s)
            s.apriEsperienza(.lanciaAnno, cliente: "giulia")
        }
        coppia("671-sala-lancia-partita") { s in
            preparaLancia(s)
            s.sala.lanciaIstantanea = ProvaLanciaAnno(seme: semeLancia, anni: 10, carte: [4: "caldaia", 10: "infortunio"])
            s.apriEsperienza(.lanciaAnno, cliente: "giulia")
        }
        una("672-sala-lancia-fine") { s in
            preparaLancia(s)
            s.sala.lanciaIstantanea = ProvaLanciaAnno(seme: semeLancia, anni: 12, carte: [4: "caldaia", 10: "infortunio"])
            s.apriEsperienza(.lanciaAnno, cliente: "giulia")
        }
        una("673-sala-lancia-senza-proposte") { s in
            s.dati.posizioni.removeAll { $0.clienteId == "giulia" && $0.stato == .proposta }
            for i in s.dati.obiettivi.indices where s.dati.obiettivi[i].clienteId == "giulia" { s.dati.obiettivi[i].versamentoMensile = 0 }
            s.apriEsperienza(.lanciaAnno, cliente: "giulia")
        }
        // §4.4: Quanto vale avermi accanto
        coppia("675-sala-valore") { s in
            preparaValore(s, completo: true)
            s.apriEsperienza(.valoreConsulente, cliente: "giulia")
        }
        una("676-sala-valore-parziale") { s in
            preparaValore(s, completo: false)
            s.apriEsperienza(.valoreConsulente, cliente: "giulia")
        }
        una("677-sala-valore-presto") { s in
            s.apriEsperienza(.valoreConsulente, cliente: "andrea")
        }
        una("678-sala-valore-dettaglio") { s in
            preparaValore(s, completo: true)
            s.sala.valoreDettaglioIstantanea = .costi
            s.apriEsperienza(.valoreConsulente, cliente: "giulia")
        }
        return scene
    }

    /// Il seme della partita delle istantanee (fisso: la partita è sempre la stessa).
    nonisolated static let semeLancia: UInt64 = 2026_11_08

    /// DATI DI PROVA: le ipotesi di previdenza di Giulia confermate e 550 € al mese per l'anticipo della casa.
    nonisolated static func preparaLettera(_ s: StatoShell) {
        preparaGiornata(s, giornata: nil)
        for i in s.dati.obiettivi.indices where s.dati.obiettivi[i].id == "obiettivo-giulia-casa" {
            s.dati.obiettivi[i].versamentoMensile = 550
        }
    }

    /// DATI DI PROVA: la polizza infortuni in proposta di Giulia con 9.000 € di indennizzo stimato (l'evento coperto).
    nonisolated static func preparaLancia(_ s: StatoShell) {
        preparaLettera(s)
        var p = Posizione(clienteId: "giulia", canale: .alleanza, stato: .proposta, area: .protezione, nome: "Polizza infortuni")
        p.id = "pos-prova-lancia-infortuni"
        p.rischio = .infortuni
        p.premio = 18
        p.frequenza = .mensile
        p.indennizzoStimato = 9_000
        s.dati.posizioni.removeAll { $0.id == p.id }
        s.dati.posizioni.append(p)
    }

    /// DATI DI PROVA di «Quanto vale avermi accanto»: inizio del rapporto 26 mesi fa; un fondo pensione accettato
    /// (2.000 € l'anno), la temporanea caso morte accettata; con `completo` anche una sostituzione (dall'1,9% allo 0,4%)
    /// e il track record di prova (il piano di risparmio di Giulia contro il conto deposito), e una parcella pagata.
    nonisolated static func preparaValore(_ s: StatoShell, completo: Bool) {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        func mesi(_ n: Int) -> Date { ValoriDaDocumento.mezzogiorno(cal.date(byAdding: .month, value: -n, to: oggi) ?? oggi) }
        if completo { trackRecordDiProva(s, .completo) }
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "giulia" }) {
            s.dati.clienti[i].clienteDal = mesi(26)
            s.dati.clienti[i].profilo.redditoLordoAnnuo = 32_000
        }
        var fondo = Posizione(clienteId: "giulia", canale: .indipendente, stato: .inEssere, area: .previdenza, nome: "Fondo pensione aperto")
        fondo.id = "pos-prova-valore-fondo"
        fondo.decorrenza = mesi(23)
        fondo.premio = 2_000
        fondo.frequenza = .annuale
        fondo.controvalore = 4_200
        var vecchio = Posizione(clienteId: "giulia", canale: .indipendente, stato: .chiusa, area: .investimento, nome: "Fondo bilanciato")
        vecchio.id = "pos-prova-valore-vecchio"
        vecchio.costoAnnuo = 1.9
        vecchio.controvalore = 0
        var nuovo = Posizione(clienteId: "giulia", canale: .indipendente, stato: .inEssere, area: .investimento, nome: "Portafoglio ETF")
        nuovo.id = "pos-prova-valore-etf"
        nuovo.decorrenza = mesi(22)
        nuovo.versamentoIniziale = 30_000
        nuovo.controvalore = 31_800
        nuovo.costoAnnuo = 0.4
        let nuove = completo ? [fondo, vecchio, nuovo] : [fondo]
        let ids = Set(nuove.map(\.id))
        s.dati.posizioni.removeAll { ids.contains($0.id) }
        s.dati.posizioni += nuove

        func accettata(_ id: String, posizione: Posizione, mesiFa: Int, sostituita: String? = nil) -> Raccomandazione {
            var r = Raccomandazione(id: id, data: mesi(mesiFa + 1), clienteId: "giulia", posizioneId: posizione.id,
                                    canale: posizione.canale, area: posizione.area, proposta: MotoreTrackRecord.titolo(posizione),
                                    motivazione: "Motivazione di prova", cifre: CifreRaccomandazione(),
                                    alternativa: AlternativaRaccomandazione(tipo: sostituita == nil ? .altro : .lasciareComE,
                                                                            descrizione: sostituita == nil ? "Nessuna" : "Lasciare il fondo com’era",
                                                                            posizioneSostituitaId: sostituita, ricavata: false))
            r.registraScelta(.accettata, il: mesi(mesiFa))
            return r
        }
        var raccomandazioni = [accettata("racc-prova-valore-fondo", posizione: fondo, mesiFa: 23)]
        if let temporanea = s.dati.posizioni.first(where: { $0.id == "pos-giulia-temporanea-caso-morte" }) {
            raccomandazioni.append(accettata("racc-prova-valore-temporanea", posizione: temporanea, mesiFa: 24))
        }
        if completo {
            raccomandazioni.append(accettata("racc-prova-valore-etf", posizione: nuovo, mesiFa: 22, sostituita: vecchio.id))
            var parcella = Parcella(id: "parcella-prova-valore", clienteId: "giulia", data: mesi(12), descrizione: "Consulenza di prova",
                                    righe: [RigaParcella(id: "rv1", descrizione: "Consulenza annuale di prova", importo: 1_200)])
            parcella.stato = .pagata
            parcella.incassataIl = mesi(11)
            s.dati.parcelle.removeAll { $0.id == parcella.id }
            s.dati.parcelle.append(parcella)
        }
        let idsRacc = Set(raccomandazioni.map(\.id))
        s.dati.raccomandazioni.removeAll { idsRacc.contains($0.id) }
        s.dati.raccomandazioni += raccomandazioni
    }
}
#endif
