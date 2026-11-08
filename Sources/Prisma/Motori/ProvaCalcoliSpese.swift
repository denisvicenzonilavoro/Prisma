import Foundation

/// Prove di Studio › Spese, «Chilometri, spese e scadenze» (Design/template-luce-specifica.md §6.3.5.4, «Luce» giro 9):
/// - giri: due visite con la tabella andata e ritorno 28 e 36 → 64; la correzione a mano vince; telefonate, incontri in
///   studio e appuntamenti pianificati esclusi; visite senza luogo o senza distanza contate a parte («almeno»);
/// - spese: la somma vera (358,80 sui dati del template, non 386); il mese mostrato il 2 novembre è ottobre, l'11 novembre;
/// - scadenze: mensile al 16 → la prossima dopo «fatta», le prossime entro 90 giorni; ore 22/30 → 73%;
/// - lettore dello scontrino su tre testi finti (totale «TOTALE EURO», data gg/mm/aa, importo con la virgola);
/// - pacchetto: CSV con le righe giuste e senza nomi dei clienti con `nomiNelPacchetto` spento; lo zip si rilegge.
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliSpese {
    static func esegui(_ verifica: VerificaCalcoli) {
        giri(verifica)
        mese(verifica)
        spese(verifica)
        scadenze(verifica)
        scontrini(verifica)
        pacchetto(verifica)
    }

    private static let cal = Calendar(identifier: .gregorian)

    private static func visita(_ id: String, cliente: String, _ giorno: Int, ora: Int, mese: Int = 10,
                               stato: Appuntamento.Stato = .concluso, tipo: TipoAppuntamento = .analisi,
                               presso: LuogoIncontro? = .cliente) -> Appuntamento {
        let inizio = cal.date(from: DateComponents(year: 2026, month: mese, day: giorno, hour: ora)) ?? Date()
        return Appuntamento(id: id, clienteId: cliente, titolo: "Prova", inizio: inizio, durataMinuti: 60, luogo: "",
                            note: "", stato: stato, tipo: tipo, presso: presso)
    }

    private static func impostazioni() -> ImpostazioniSpese { ImpostazioniSpese() }

    /// I km di andata e ritorno per cliente di prova (nel file di ogni cliente, `DatiPrisma.kmClienti`).
    private static let km: [String: Double] = ["a": 28, "b": 36, "c": 41]

    private static func giri(_ verifica: VerificaCalcoli) {
        let ottobre = AiutiProva.data(2026, 10, 1)
        var imp = impostazioni()
        let appuntamenti = [
            visita("v1", cliente: "a", 3, ora: 10),
            visita("v2", cliente: "b", 3, ora: 15),
            visita("v3", cliente: "c", 8, ora: 11),
            // Esclusi: una telefonata, un incontro in studio, uno pianificato, uno di novembre
            visita("t1", cliente: "a", 8, ora: 17, tipo: .telefonata),
            visita("s1", cliente: "b", 9, ora: 9, presso: .studio),
            visita("p1", cliente: "c", 20, ora: 9, stato: .pianificato),
            visita("n1", cliente: "a", 2, ora: 9, mese: 11),
        ]
        let g = MotoreChilometri.giri(mese: ottobre, appuntamenti: appuntamenti, impostazioni: imp, kmClienti: km, calendario: cal)
        verifica("Spese: giri di ottobre (telefonate, studio, pianificati e novembre esclusi)", Double(g.count), 2)
        verifica("Spese: giro di due visite = 28 + 36 dalla tabella andata e ritorno", g.first?.km ?? -1, 64)
        verifica.vero("Spese: visite del giro in ordine d'orario", g.first?.visite.map(\.appuntamentoId) == ["v1", "v2"])
        verifica.vero("Spese: chiave del giorno del giro", g.first?.chiave == "2026-10-03")
        // La correzione a mano vince
        imp.kmCorretti["2026-10-03"] = 47
        let corretto = MotoreChilometri.giri(mese: ottobre, appuntamenti: appuntamenti, impostazioni: imp, kmClienti: km, calendario: cal)
        verifica("Spese: la correzione a mano vince sulla tabella", corretto.first?.km ?? -1, 47)
        verifica.vero("Spese: giro corretto segnato «a mano»", corretto.first?.corretto == true)
        let r = MotoreChilometri.riepilogo(mese: ottobre, appuntamenti: appuntamenti, impostazioni: imp, kmClienti: km, calendario: cal)
        verifica("Spese: totale del mese con la correzione", r.totale, 47 + 41)
        verifica("Spese: visite del mese", Double(r.visite), 3)
        verifica("Spese: clienti del mese", Double(r.clienti), 3)
        verifica("Spese: serie di 10 mesi", Double(r.serie.count), 10)
        verifica("Spese: ultima colonna = il mese mostrato", r.serie.last?.km ?? -1, 88)
        verifica.vero("Spese: completo senza visite senza km", r.completo)
        // Visite senza km: luogo non indicato e cliente senza distanza
        let senza = appuntamenti + [visita("x1", cliente: "d", 14, ora: 10), visita("x2", cliente: "a", 21, ora: 10, presso: nil)]
        let r2 = MotoreChilometri.riepilogo(mese: ottobre, appuntamenti: senza, impostazioni: imp, kmClienti: km, calendario: cal)
        verifica("Spese: visite senza km contate a parte", Double(r2.senzaKm), 2)
        verifica("Spese: visite senza luogo («Dove eri?»)", Double(r2.senzaLuogo), 1)
        verifica("Spese: il totale conta solo i km noti («almeno»)", r2.totale, 88)
        verifica.vero("Spese: «almeno» quando mancano dei km", !r2.completo)
        verifica.vero("Spese: giro senza distanza da completare", r2.giri.first { $0.chiave == "2026-10-14" }?.km == nil)
        // Una visita altrove non prende i km della tabella
        let altrove = MotoreChilometri.visita(visita("y1", cliente: "a", 22, ora: 10, presso: .altro), kmClienti: km)
        verifica.vero("Spese: visita altrove senza km dalla tabella", altrove.km == nil && altrove.motivo == .altrove)
        // Senza cliente: solo se l'utente lo chiede
        let libero = visita("z1", cliente: "", 23, ora: 10)
        verifica.vero("Spese: appuntamento senza cliente escluso di base", !MotoreChilometri.eVisita(libero, contaSenzaCliente: false))
        verifica.vero("Spese: appuntamento senza cliente contato se richiesto", MotoreChilometri.eVisita(libero, contaSenzaCliente: true))
        // Nessuna stima inventata: senza tabella nessun km
        let vuoto = MotoreChilometri.riepilogo(mese: ottobre, appuntamenti: appuntamenti, impostazioni: ImpostazioniSpese(), kmClienti: [:], calendario: cal)
        verifica("Spese: senza km scritti dall'utente il totale è 0", vuoto.totale, 0)
        verifica("Spese: senza km scritti tutte le visite sono senza km", Double(vuoto.senzaKm), 3)
    }

    private static func mese(_ verifica: VerificaCalcoli) {
        let ottobre = AiutiProva.data(2026, 10, 1)
        let novembre = AiutiProva.data(2026, 11, 1)
        verifica.vero("Spese: il 2 novembre si mostra ottobre",
                      MotoreChilometri.meseMostrato(oggi: AiutiProva.data(2026, 11, 2), calendario: cal) == cal.startOfDay(for: ottobre))
        verifica.vero("Spese: il 10 novembre ancora ottobre",
                      MotoreChilometri.meseMostrato(oggi: AiutiProva.data(2026, 11, 10), calendario: cal) == cal.startOfDay(for: ottobre))
        verifica.vero("Spese: l'11 novembre si mostra novembre",
                      MotoreChilometri.meseMostrato(oggi: AiutiProva.data(2026, 11, 11), calendario: cal) == cal.startOfDay(for: novembre))
        verifica.vero("Spese: il 5 gennaio si mostra dicembre dell'anno prima",
                      MotoreChilometri.meseMostrato(oggi: AiutiProva.data(2027, 1, 5), calendario: cal)
                          == cal.startOfDay(for: AiutiProva.data(2026, 12, 1)))
    }

    private static func spese(_ verifica: VerificaCalcoli) {
        let d = { (g: Int) in AiutiProva.data(2026, 10, g) }
        let template = [
            SpesaStudio(data: d(2), descrizione: "Carburante", importo: 92.40, categoria: .carburante),
            SpesaStudio(data: d(8), descrizione: "Pranzo con cliente", importo: 48.00, categoria: .pasti),
            SpesaStudio(data: d(14), descrizione: "Parcheggio", importo: 6.50, categoria: .parcheggio),
            SpesaStudio(data: d(17), descrizione: "Cancelleria", importo: 31.90, categoria: .cancelleria),
            SpesaStudio(data: d(24), descrizione: "Corso di aggiornamento", importo: 180.00, categoria: .formazione),
            SpesaStudio(data: AiutiProva.data(2026, 11, 3), descrizione: "Di novembre", importo: 10, categoria: .altro),
        ]
        let ottobre = MotoreSpese.delMese(template, mese: d(1), calendario: cal)
        verifica("Spese: spese di ottobre", Double(ottobre.count), 5)
        verifica("Spese: totale vero delle spese (358,80, non 386)", MotoreSpese.totale(ottobre), 358.80, tolleranza: 0.001)
        verifica.vero("Spese: in ordine di data", ottobre.first?.descrizione == "Carburante")
        let nuovo = ottobre + [SpesaStudio(data: d(30), descrizione: "Pranzo con cliente", importo: 36, categoria: .pasti)]
        verifica("Spese: il totale si aggiorna con lo scontrino nuovo", MotoreSpese.totale(nuovo), 394.80, tolleranza: 0.001)
        let categorie = MotoreSpese.perCategoria(nuovo)
        verifica("Spese: pasti per categoria", categorie.first { $0.categoria == .pasti }?.totale ?? -1, 84)
        verifica.vero("Spese: nessuna percentuale di deducibilità nelle categorie",
                      CategoriaSpesa.allCases.allSatisfy { !$0.nome.contains("%") })
    }

    private static func scadenze(_ verifica: VerificaCalcoli) {
        let f24 = ScadenzaStudio(id: "s-f24", titolo: "Prova mensile", data: AiutiProva.data(2026, 11, 16), ricorrenza: .mensile, tipo: .fiscale)
        let dopo = MotoreSpese.segnaFatta("s-f24", in: [f24], il: AiutiProva.data(2026, 11, 15), calendario: cal)
        verifica("Spese: dopo «fatta» nasce la prossima", Double(dopo.count), 2)
        verifica.vero("Spese: la fatta resta con la data", dopo.first?.fattaIl != nil)
        verifica.vero("Spese: ricorrenza mensile al 16 → 16 dicembre",
                      dopo.last.map { cal.dateComponents([.month, .day], from: $0.data) == DateComponents(month: 12, day: 16) } ?? false)
        verifica.vero("Spese: la nuova non ha l'importo di prima", dopo.last?.importo == nil && dopo.last?.fattaIl == nil)
        let fine = MotoreSpese.prossimaData(AiutiProva.data(2026, 1, 31), ricorrenza: .mensile, calendario: cal)
        verifica.vero("Spese: il 31 gennaio → 28 febbraio", cal.dateComponents([.month, .day], from: fine) == DateComponents(month: 2, day: 28))
        let annuale = MotoreSpese.prossimaData(AiutiProva.data(2026, 12, 31), ricorrenza: .annuale, calendario: cal)
        verifica.vero("Spese: annuale → l'anno dopo", cal.component(.year, from: annuale) == 2027)
        let oggi = AiutiProva.data(2026, 11, 2)
        let elenco = [
            ScadenzaStudio(titolo: "Fra 100 giorni", data: AiutiProva.data(2027, 2, 15)),
            ScadenzaStudio(titolo: "Fatta", data: AiutiProva.data(2026, 11, 10), fattaIl: oggi),
            ScadenzaStudio(titolo: "B", data: AiutiProva.data(2026, 12, 31)),
            ScadenzaStudio(titolo: "A", data: AiutiProva.data(2026, 11, 30)),
            ScadenzaStudio(titolo: "Passata", data: AiutiProva.data(2026, 10, 30)),
        ]
        let prossime = MotoreSpese.prossime(elenco, oggi: oggi, calendario: cal)
        verifica.vero("Spese: prossime entro 90 giorni, fatte escluse, in ordine (la passata prima)",
                      prossime.map(\.titolo) == ["Passata", "A", "B"])
        verifica.vero("Spese: scadenza passata riconosciuta", MotoreSpese.passata(elenco[4], oggi: oggi, calendario: cal))
        // Ore di aggiornamento
        let corsi = [CorsoAggiornamento(titolo: "Uno", data: AiutiProva.data(2026, 3, 1), ore: 14),
                     CorsoAggiornamento(titolo: "Due", data: AiutiProva.data(2026, 6, 1), ore: 8),
                     CorsoAggiornamento(titolo: "Anno prima", data: AiutiProva.data(2025, 6, 1), ore: 20)]
        let ore = MotoreSpese.ore(corsi, anno: 2026, calendario: cal)
        verifica("Spese: ore dei corsi dell'anno", ore, 22)
        verifica("Spese: 22 ore su 30 → 73%", MotoreSpese.percentualeOre(fatte: ore, obiettivo: 30) ?? -1, 73.33, tolleranza: 0.01)
        verifica.vero("Spese: senza obiettivo nessun anello", MotoreSpese.percentualeOre(fatte: ore, obiettivo: nil) == nil)
        verifica("Spese: oltre l'obiettivo ferma a 100", MotoreSpese.percentualeOre(fatte: 40, obiettivo: 30) ?? -1, 100)
        // La prossima di una scadenza di prova resta di prova: «Togli i clienti di prova» la toglie
        let rc = ScadenzaStudio(id: SpeseDiProva.prefisso + "scadenza-rc", titolo: "Polizza di prova", data: AiutiProva.data(2026, 12, 1),
                                ricorrenza: .annuale, tipo: .polizza, nota: SpeseDiProva.nota)
        var archivioRC = ArchivioSpese(scadenze: MotoreSpese.segnaFatta(rc.id, in: [rc], il: AiutiProva.data(2026, 11, 20), calendario: cal))
        verifica.vero("Spese: la prossima di una scadenza di prova resta di prova",
                      archivioRC.scadenze.count == 2 && archivioRC.scadenze.allSatisfy { $0.id.hasPrefix(SpeseDiProva.prefisso) })
        SpeseDiProva.togli(&archivioRC)
        verifica.vero("Spese: «Togli i clienti di prova» toglie anche la prossima", archivioRC.scadenze.isEmpty)
        verifica.vero("Spese: la prossima di una scadenza dell'utente non diventa di prova",
                      dopo.last.map { !$0.id.hasPrefix(SpeseDiProva.prefisso) } ?? false)
        verifica.vero("Spese: titoli suggeriti senza date né importi (decisione 66)",
                      ScadenzaStudio.titoliSuggeriti.allSatisfy { $0.titolo.range(of: #"(?<![A-Za-z0-9])\d"#, options: .regularExpression) == nil })
    }

    private static func scontrini(_ verifica: VerificaCalcoli) {
        let uno = """
        TRATTORIA DA PROVA
        Via di prova 1
        P.IVA 01234567890
        DOCUMENTO COMMERCIALE
        Coperto 2,00
        Primo 12,00
        TOTALE EURO 36,00
        DI CUI IVA 3,27
        CONTANTI 50,00
        RESTO 14,00
        28/10/26 13:42
        """
        let a = LettoreScontrino.leggi(uno, calendario: cal)
        verifica("Scontrino: totale da «TOTALE EURO»", a.totale ?? -1, 36)
        verifica.vero("Scontrino: data gg/mm/aa", a.data.map { cal.dateComponents([.year, .month, .day], from: $0) == DateComponents(year: 2026, month: 10, day: 28) } ?? false)
        verifica.vero("Scontrino: esercente dalla prima riga", a.esercente == "TRATTORIA DA PROVA")
        verifica.vero("Scontrino: partita IVA dell'esercente", a.partitaIVA == "01234567890")
        verifica("Scontrino: IVA stampata", a.iva ?? -1, 3.27)
        verifica.vero("Scontrino: categoria proposta (pasti)", a.categoria == .pasti)
        verifica.vero("Scontrino: completo non da controllare", !a.incerto)

        let due = """
        STAZIONE DI SERVIZIO PROVA
        Self service gasolio
        SUBTOTALE 60,00
        TOTALE
        1.092,40
        Data 02-10-2026
        """
        let b = LettoreScontrino.leggi(due, calendario: cal)
        verifica("Scontrino: totale sulla riga dopo, migliaia con il punto", b.totale ?? -1, 1092.40)
        verifica.vero("Scontrino: «SUBTOTALE» non è il totale", b.totale != 60)
        verifica.vero("Scontrino: data gg-mm-aaaa", b.data.map { cal.component(.day, from: $0) == 2 && cal.component(.month, from: $0) == 10 } ?? false)
        verifica.vero("Scontrino: categoria proposta (carburante)", b.categoria == .carburante)

        let tre = """
        PARCHEGGIO CENTRO PROVA
        Sosta 2 ore
        Importo 6,50
        """
        let c = LettoreScontrino.leggi(tre, calendario: cal)
        verifica.vero("Scontrino: senza totale né data è da controllare", c.incerto && c.totale == nil && c.data == nil)
        verifica.vero("Scontrino: categoria proposta (parcheggio)", c.categoria == .parcheggio)
        verifica.vero("Scontrino: importi con la virgola", LettoreScontrino.importi("Importo 6,50") == [6.5])

        // Il totale con l'IVA dentro è il totale, non l'IVA; l'aliquota con i decimali non è l'IVA
        let quattro = """
        BAR DI PROVA
        TOTALE COMPLESSIVO IVA INCLUSA 36,00
        DI CUI IVA 3,27
        05/10/2026
        """
        let d = LettoreScontrino.leggi(quattro, calendario: cal)
        verifica("Scontrino: «TOTALE … IVA INCLUSA» è il totale", d.totale ?? -1, 36)
        verifica("Scontrino: l'IVA dalla riga «DI CUI IVA», non dal totale", d.iva ?? -1, 3.27)
        let cinque = """
        CARTOLERIA DI PROVA
        IVA 22,00% 5,41
        TOTALE 30,00
        """
        let e = LettoreScontrino.leggi(cinque, calendario: cal)
        verifica("Scontrino: l'aliquota «22,00%» non è l'IVA", e.iva ?? -1, 5.41)
        verifica("Scontrino: totale con l'aliquota sopra", e.totale ?? -1, 30)
        let sei = LettoreScontrino.leggi("NEGOZIO DI PROVA\nIVA 22,00%\nTOTALE IVA INCLUSA 12,20", calendario: cal)
        verifica.vero("Scontrino: solo l'aliquota, nessuna IVA inventata", sei.iva == nil && sei.totale == 12.20)
        let sette = LettoreScontrino.leggi("NEGOZIO DI PROVA\nTOTALE IVA 2,20\nTOTALE 12,20", calendario: cal)
        verifica.vero("Scontrino: «TOTALE IVA 2,20» è l'IVA, non il totale", sette.iva == 2.20 && sette.totale == 12.20)
    }

    private static func pacchetto(_ verifica: VerificaCalcoli) {
        let ottobre = AiutiProva.data(2026, 10, 1)
        let appuntamenti = [visita("v1", cliente: "a", 3, ora: 10), visita("v2", cliente: "b", 3, ora: 15),
                            visita("v3", cliente: "c", 8, ora: 11)]
        let giri = MotoreChilometri.giri(mese: ottobre, appuntamenti: appuntamenti, impostazioni: impostazioni(), kmClienti: km, calendario: cal)
        let nomi = ["a": "Cliente Prova Uno", "b": "Cliente Prova Due", "c": "Cliente Prova Tre"]
        let senza = PacchettoCommercialista.csvChilometri(giri, nomi: nil, euroPerKm: nil)
        verifica.vero("Pacchetto: CSV con il BOM per Excel", senza.hasPrefix(PacchettoCommercialista.bom))
        let righe = senza.dropFirst().components(separatedBy: "\r\n").filter { !$0.isEmpty }
        verifica("Pacchetto: una riga per giro più l'intestazione", Double(righe.count), 3)
        verifica.vero("Pacchetto: separatore «;» e km con la virgola", righe.dropFirst().first == "03/10/2026;2;64,0;km andata e ritorno per cliente")
        verifica.vero("Pacchetto: nessun nome di cliente con i nomi spenti", !nomi.values.contains { senza.contains($0) })
        let con = PacchettoCommercialista.csvChilometri(giri, nomi: nomi, euroPerKm: nil)
        verifica.vero("Pacchetto: i nomi solo se l'utente li accende", con.contains("Cliente Prova Uno · Cliente Prova Due"))
        let spesa = SpesaStudio(data: AiutiProva.data(2026, 10, 8), descrizione: "Pranzo; con \"virgolette\"", importo: 48,
                                categoria: .pasti, clienteId: "a")
        let csv = PacchettoCommercialista.csvSpese([spesa], scontrini: [:], nomi: nil)
        verifica.vero("Pacchetto: campo con «;» tra virgolette", csv.contains("\"Pranzo; con \"\"virgolette\"\"\""))
        verifica.vero("Pacchetto: importo con la virgola", csv.contains(";48,00;"))
        verifica.vero("Pacchetto: la spesa legata al cliente non porta il nome", !csv.contains("Cliente Prova Uno"))
        // Un testo che Excel leggerebbe come formula prende l'apostrofo davanti; i numeri restano come sono
        verifica.vero("Pacchetto: «=HYPERLINK(…)» non è una formula", PacchettoCommercialista.campo("=HYPERLINK(\"x\")").hasPrefix("\"'="))
        verifica.vero("Pacchetto: «+39 …», «-x», «@x» neutralizzati",
                      ["+39 000", "-somma", "@prova"].allSatisfy { PacchettoCommercialista.campo($0).hasPrefix("'") })
        verifica.vero("Pacchetto: i numeri restano numeri", PacchettoCommercialista.campo("48,00") == "48,00"
                          && PacchettoCommercialista.campo("-5") == "-5" && PacchettoCommercialista.campo("Pranzo") == "Pranzo")
        // I km del PDF e del CSV tornano fra loro: un giro da completare porta i km noti in tutti e due
        var kmMezzi = km
        kmMezzi["a"] = 20.5
        kmMezzi["b"] = 41.5
        let incompleti = [visita("m1", cliente: "a", 3, ora: 10), visita("m2", cliente: "a", 5, ora: 10),
                          visita("m3", cliente: "b", 9, ora: 10), visita("m4", cliente: "c", 9, ora: 15, presso: nil)]
        let rm = MotoreChilometri.riepilogo(mese: ottobre, appuntamenti: incompleti, impostazioni: ImpostazioniSpese(),
                                            kmClienti: kmMezzi, calendario: cal)
        let csvKm = PacchettoCommercialista.csvChilometri(rm.giri, nomi: nil, euroPerKm: 0.3)
        let righeKm = csvKm.dropFirst().components(separatedBy: "\r\n").dropFirst().filter { !$0.isEmpty }
            .map { $0.components(separatedBy: ";") }
        let sommaKm = righeKm.compactMap { Double($0[2].replacingOccurrences(of: ",", with: ".")) }.reduce(0, +)
        let sommaEuro = righeKm.compactMap { Double($0[4].replacingOccurrences(of: ",", with: ".")) }.reduce(0, +)
        verifica.vero("Pacchetto: il giro da completare porta i km noti nel CSV",
                      righeKm.last.map { $0[2] == "41,5" && $0[3] == "da completare: solo i km noti" } ?? false)
        verifica("Pacchetto: la somma dei km del CSV = il totale del riepilogo", sommaKm, rm.totale, tolleranza: 0.001)
        let testiKm = TestiRiepilogoSpese(mese: ottobre, riepilogo: rm, spese: [], nomi: nil, consulente: "Consulente di prova",
                                          euroPerKm: 0.3)
        verifica.vero("Pacchetto: il PDF scrive il totale al decimo («almeno 82,5 km»)",
                      testiKm.totali.first { $0.etichetta == "Chilometri" }?.valore == "almeno 82,5 km")
        verifica.vero("Pacchetto: i giri del PDF al decimo («20,5 km»)", testiKm.righe.first?.riga.numero == "20,5 km")
        verifica.vero("Pacchetto: il giro da completare nel PDF con «almeno»", testiKm.righe.last?.riga.numero == "almeno 41,5 km")
        verifica.vero("Pacchetto: «Km × valore» del PDF = la somma degli euro del CSV",
                      testiKm.totali.first { $0.etichetta == "Km × valore scritto da te" }?.valore == Formati.euroDecimali(sommaEuro))
        verifica.vero("Pacchetto: nome dello zip «Ottobre-2026»", PacchettoCommercialista.nome(mese: ottobre, calendario: cal) == "Ottobre-2026")
        verifica.vero("Pacchetto: suffisso «2026-10»", PacchettoCommercialista.suffisso(mese: ottobre, calendario: cal) == "2026-10")
        // Lo zip scritto si rilegge con LettoreZip: i due CSV, il PDF e lo scontrino
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("Prisma-prova-pacchetto-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        do {
            try fm.createDirectory(at: base, withIntermediateDirectories: true)
            let scontrino = base.appendingPathComponent("abcd-scontrino.jpg")
            try Data("scontrino finto".utf8).write(to: scontrino)
            var conFile = spesa
            conFile.scontrino = scontrino.lastPathComponent
            let file = PacchettoCommercialista.scontrini([conFile], cartella: base)
            let contenuto = PacchettoCommercialista.Contenuto(
                nome: "Ottobre-2026", suffisso: "2026-10", csvChilometri: senza,
                csvSpese: PacchettoCommercialista.csvSpese([conFile], scontrini: file.perSpesa, nomi: nil),
                pdf: Data("%PDF-finto".utf8), scontrini: file.file)
            let zip = base.appendingPathComponent("Ottobre-2026.zip")
            var passi: [Int] = []
            try PacchettoCommercialista.scrivi(contenuto, in: zip) { fatti, _ in passi.append(fatti) }
            let voci = try LettoreZip.nomi(zip)
            verifica.vero("Pacchetto: lo zip contiene CSV, PDF e scontrini",
                          voci.contains("Ottobre-2026/chilometri-2026-10.csv") && voci.contains("Ottobre-2026/spese-2026-10.csv")
                              && voci.contains("Ottobre-2026/riepilogo-2026-10.pdf")
                              && voci.contains("Ottobre-2026/scontrini/2026-10-08 Pasti.jpg"))
            let letto = try LettoreZip.dati(zip, voce: "Ottobre-2026/chilometri-2026-10.csv")
            verifica.vero("Pacchetto: il CSV dei km torna uguale dallo zip (BOM compreso)", letto == Data(senza.utf8))
            verifica.vero("Pacchetto: la barra segue i file scritti", passi == Array(1...5))
            let csvLetto = try LettoreZip.dati(zip, voce: "Ottobre-2026/spese-2026-10.csv").flatMap { String(data: $0, encoding: .utf8) } ?? ""
            verifica.vero("Pacchetto: la spesa indica il file dello scontrino", csvLetto.contains("2026-10-08 Pasti.jpg"))
        } catch {
            verifica.vero("Pacchetto: zip scritto e riletto (\(error.localizedDescription))", false)
        }
    }
}
