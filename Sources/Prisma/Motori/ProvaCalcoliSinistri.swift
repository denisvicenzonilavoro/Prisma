import Foundation

// Prova dei sinistri («Luce» giro 15, §7.4): giorni dalla denuncia; indennizzo nelle sue forme; sinistro fermo con la
// soglia; barra con gli aperti e i chiusi degli ultimi 90 giorni; passaggio di fase con il fatto e, a «Pagato», l'importo;
// la vista del cliente senza importo se non acceso e senza descrizione né numeri; l'occasione di Messaggi non commerciale
// senza numero di polizza; il sollecito con solo polizza, sinistro e assicurato; il sinistro ridotto per «Prisma
// ovunque»; i sinistri di prova e le impostazioni lette con tolleranza. Clienti, polizze, numeri e importi inventati per
// la prova (cifre non tonde, date fisse).
enum ProvaCalcoliSinistri {
    static func esegui(_ verifica: VerificaCalcoli) {
        let cal = Calendar(identifier: .gregorian)
        func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }
        let oggi = d(2026, 3, 27)

        // Giorni dalla denuncia (non dai fatti); un chiuso conta fino alla chiusura
        var s = Sinistro(id: "sinistro-calcoli-1", clienteId: "cliente-calcoli", titolo: "Sinistro di prova", apertoIl: d(2026, 3, 9))
        s.eventi = [EventoSinistro(id: "e1", data: d(2026, 3, 9), testo: "Denuncia", fase: .denuncia),
                    EventoSinistro(id: "e2", data: d(2026, 3, 11), testo: "Documenti", fase: .documenti)]
        verifica("Sinistri: aperto da 18 giorni dalla denuncia", Double(MotoreSinistri.giorniAperto(s, oggi: oggi, cal: cal)), 18)
        var chiuso = s
        chiuso.fase = .pagato
        chiuso.chiusoIl = d(2026, 3, 20)
        verifica("Sinistri: un chiuso conta fino alla chiusura", Double(MotoreSinistri.giorniAperto(chiuso, oggi: oggi, cal: cal)), 11)
        verifica.vero("Sinistri: la fase dopo «Documenti» è «Perizia», dopo «Pagato» e «Respinto» niente",
                      MotoreSinistri.prossimaFase(Sinistro(id: "x", clienteId: "c", titolo: "t", apertoIl: oggi, fase: .documenti)) == .perizia
                      && MotoreSinistri.prossimaFase(chiuso) == nil
                      && MotoreSinistri.prossimaFase(Sinistro(id: "y", clienteId: "c", titolo: "t", apertoIl: oggi, fase: .respinto)) == nil)

        // L'indennizzo nelle quattro forme del template (più le due senza intervallo)
        var stima = s
        stima.stimaMinima = 1_137
        stima.stimaMassima = 1_793
        verifica.vero("Sinistri: «tra 1.137 e 1.793 €»", MotoreSinistri.indennizzo(stima) == "tra 1.137 e " + Formati.euro(1_793))
        stima.stimaMinima = nil
        stima.stimaMassima = 1_483
        verifica.vero("Sinistri: «fino a 1.483 €»", MotoreSinistri.indennizzo(stima) == "fino a " + Formati.euro(1_483))
        var pagato = s
        pagato.fase = .pagato
        pagato.pagato = 3_417
        verifica.vero("Sinistri: «pagati 3.417 €»", MotoreSinistri.indennizzo(pagato) == "pagati " + Formati.euro(3_417))
        verifica.vero("Sinistri: senza stime «da stimare»", MotoreSinistri.indennizzo(s) == "da stimare")
        var respinto = s
        respinto.fase = .respinto
        respinto.stimaMassima = 1_483
        verifica.vero("Sinistri: respinto «nessun indennizzo», anche con una stima", MotoreSinistri.indennizzo(respinto) == "nessun indennizzo")

        // Fermo: nessun fatto già accaduto da più dei giorni della soglia; un fatto futuro non conta; un chiuso mai
        var fermo = s
        fermo.eventi = [EventoSinistro(id: "f1", data: d(2026, 3, 12), testo: "Denuncia", fase: .denuncia),
                        EventoSinistro(id: "f2", data: d(2026, 4, 6), testo: "Visita fissata", fase: .perizia)]
        verifica.vero("Sinistri: 15 giorni senza fatti con la soglia 14 è fermo (il fatto futuro non conta)",
                      MotoreSinistri.fermo(fermo, oggi: oggi, soglia: 14, cal: cal) && MotoreSinistri.giorniFermo(fermo, oggi: oggi, cal: cal) == 15)
        verifica.vero("Sinistri: 15 giorni con la soglia 15 non è fermo", !MotoreSinistri.fermo(fermo, oggi: oggi, soglia: 15, cal: cal))
        var fermoChiuso = fermo
        fermoChiuso.fase = .respinto
        verifica.vero("Sinistri: un sinistro chiuso non è mai fermo", !MotoreSinistri.fermo(fermoChiuso, oggi: oggi, soglia: 3, cal: cal))
        let senzaFatti = Sinistro(id: "z", clienteId: "c", titolo: "t", apertoIl: d(2026, 3, 1))
        verifica.vero("Sinistri: senza fatti conta dalla denuncia", MotoreSinistri.giorniFermo(senzaFatti, oggi: oggi, cal: cal) == 26)

        // La barra: aperti (denuncia più recente prima), poi i chiusi degli ultimi 90 giorni
        let a1 = Sinistro(id: "a1", clienteId: "c", titolo: "Aperto vecchio", apertoIl: d(2026, 1, 13))
        let a2 = Sinistro(id: "a2", clienteId: "c", titolo: "Aperto nuovo", apertoIl: d(2026, 3, 17))
        var c1 = Sinistro(id: "c1", clienteId: "c", titolo: "Chiuso da poco", apertoIl: d(2025, 11, 4), fase: .pagato)
        c1.chiusoIl = d(2026, 3, 2)
        var c2 = Sinistro(id: "c2", clienteId: "c", titolo: "Chiuso da tanto", apertoIl: d(2025, 6, 4), fase: .respinto)
        c2.chiusoIl = d(2025, 11, 19)
        var c3 = Sinistro(id: "c3", clienteId: "c", titolo: "Chiuso a gennaio", apertoIl: d(2025, 10, 4), fase: .respinto)
        c3.chiusoIl = d(2026, 1, 23)
        let barra = MotoreSinistri.elenco([c2, a1, c1, c3, a2], oggi: oggi, cal: cal).map(\.id)
        verifica.vero("Sinistri: barra con gli aperti prima e i chiusi degli ultimi 90 giorni (\(barra))", barra == ["a2", "a1", "c1", "c3"])

        // Avanzare di fase: il fatto entra, «Pagato» chiede l'importo e chiude, una fase prima riapre e toglie l'importo
        var av = s
        av.fase = .liquidazione
        MotoreSinistri.avanza(&av, a: .pagato, il: d(2026, 3, 25), pagato: 3_417, id: "evento-calcoli-pagato")
        verifica.vero("Sinistri: «Pagato» segna l'importo, la chiusura e il fatto «Pagati 3.417 €»",
                      av.fase == .pagato && av.pagato == 3_417 && av.chiusoIl == d(2026, 3, 25)
                      && av.eventi.last?.fase == .pagato && av.eventi.last?.testo == "Pagati " + Formati.euro(3_417)
                      && av.eventi.last?.id == "evento-calcoli-pagato" && av.eventi.count == s.eventi.count + 1)
        MotoreSinistri.avanza(&av, a: .perizia, il: d(2026, 3, 26), pagato: nil)
        verifica.vero("Sinistri: tornare a «Perizia» riapre e toglie l'importo pagato",
                      av.fase == .perizia && av.pagato == nil && av.chiusoIl == nil && av.eventi.count == s.eventi.count + 2)
        var senzaImporto = s
        MotoreSinistri.avanza(&senzaImporto, a: .pagato, il: oggi, pagato: 0)
        verifica.vero("Sinistri: un importo zero non si segna", senzaImporto.pagato == nil && senzaImporto.eventi.last?.testo == "Indennizzo pagato")

        // La vista del cliente: niente descrizione, numero né stime; l'importo solo se acceso
        var completo = s
        completo.descrizione = "Descrizione riservata di prova"
        completo.numeroSinistro = "NUM-PROVA-7731"
        completo.stimaMinima = 1_137
        completo.stimaMassima = 1_793
        completo.fase = .pagato
        completo.pagato = 3_417
        completo.documenti = [DocumentoSinistro(id: "dc1", titolo: "Documento riservato di prova", ricevutoIl: oggi, documentoId: "doc-x")]
        let senza = completo.perIlCliente(consulente: "Consulente di prova", oggi: oggi)
        let jsonSenza = String(decoding: (try? JSONEncoder().encode(senza)) ?? Data(), as: UTF8.self)
        verifica.vero("Sinistri: per il cliente senza importo se non acceso", senza.pagato == nil)
        verifica.vero("Sinistri: per il cliente niente descrizione, numero, stime o documenti",
                      !jsonSenza.contains("riservat") && !jsonSenza.contains("7731") && !jsonSenza.contains("1137")
                      && !jsonSenza.contains("1.137") && !jsonSenza.contains("doc-x"))
        completo.importoAlCliente = true
        let con = completo.perIlCliente(consulente: "Consulente di prova", oggi: oggi)
        verifica.vero("Sinistri: per il cliente l'importo pagato se acceso, cinque fasi fatte",
                      con.pagato == Formati.euro(3_417) && con.fasi.count == 5 && con.fasi.allSatisfy { $0.stato == .fatta })
        var rifiutato = s
        rifiutato.fase = .respinto
        let mini = rifiutato.perIlCliente(consulente: "Consulente di prova", oggi: oggi)
        verifica.vero("Sinistri: respinto chiude la linea con il nodo rosso dopo le fasi raggiunte",
                      mini.fasi.last?.stato == .respinta && mini.fasi.dropLast().allSatisfy { $0.stato == .fatta } && mini.fasi.count == 3)

        // L'occasione di Messaggi: non commerciale, senza numero di polizza o di sinistro, descrizione, stime o importo
        var cliente = Cliente(id: "cliente-calcoli", nome: "Ottavio Prova", iniziali: "OP", tinta: .blu, tema: "", email: "",
                              telefono: "", preferito: false, nota: "", creatoIl: d(2024, 3, 9))
        cliente.dataNascita = d(1979, 5, 21)
        var polizza = Posizione(clienteId: cliente.id, canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Polizza di prova")
        polizza.numeroContratto = "POL-PROVA-5521"
        polizza.emittente = "Compagnia di Prova"
        polizza.assicurato = "Ottavio Prova"
        var perMessaggio = completo
        perMessaggio.fase = .perizia
        perMessaggio.pagato = nil
        perMessaggio.importoAlCliente = true
        perMessaggio.eventi.append(EventoSinistro(id: "e3", data: d(2026, 3, 24), testo: "Perito incaricato il 24 marzo", fase: .perizia))
        let o = MotoreSinistri.occasione(perMessaggio, cliente: cliente, consulente: "Consulente di prova", oggi: oggi, polizza: polizza)
        let tutto = ([o.titolo, o.perche, o.oggetto] + o.cifre.map(\.valore)).joined(separator: " ")
        verifica.vero("Sinistri: occasione `.sinistro` non commerciale, riferimento «id-fase», canale della polizza",
                      o.tipo == .sinistro && !o.commerciale && !TipoOccasioneMessaggio.sinistro.commerciale
                      && o.origine.riferimento == "sinistro-calcoli-1-perizia" && o.canale == .alleanza && o.gruppo == .oggi)
        verifica.vero("Sinistri: l'occasione non porta numero di polizza o di sinistro, descrizione, stime né importo",
                      !tutto.contains("5521") && !tutto.contains("7731") && !tutto.contains("riservat") && !tutto.contains("1.137")
                      && o.valore(.importoPagato) == nil && o.valore(.ultimoFatto) == "Perito incaricato il 24 marzo")
        verifica.vero("Sinistri: l'id del sinistro torna dal riferimento",
                      MotoreSinistri.idDaRiferimento(o.origine.riferimento) == "sinistro-calcoli-1"
                      && MotoreSinistri.idDaRiferimento("sinistro-prova-marco-perizia") == "sinistro-prova-marco"
                      && MotoreSinistri.idDaRiferimento("senzafase") == nil)
        for tono in TonoMessaggio.allCases {
            let t = ModelliMessaggi.testo(o, tono: tono, canale: .mail, cliente: cliente, firma: "Firma di prova")
            verifica.vero("Sinistri: il messaggio \(tono.rawValue) dice la fase, senza polizza né importi",
                          t.completo.contains("Perizia") && !t.completo.contains("5521") && !t.completo.contains("7731")
                          && !t.completo.contains("€") && (t.oggetto ?? "").contains("Sinistro di prova"))
        }
        var pagatoAcceso = perMessaggio
        pagatoAcceso.fase = .pagato
        pagatoAcceso.pagato = 3_417
        let op = MotoreSinistri.occasione(pagatoAcceso, cliente: cliente, consulente: "Consulente di prova", oggi: oggi)
        verifica.vero("Sinistri: l'importo pagato nell'occasione solo se acceso nel sinistro, senza polizza nessun canale",
                      op.valore(.importoPagato) == Formati.euro(3_417) && op.canale == nil)
        pagatoAcceso.importoAlCliente = nil
        verifica.vero("Sinistri: spento, nessun importo nell'occasione",
                      MotoreSinistri.occasione(pagatoAcceso, cliente: cliente, consulente: "Consulente di prova", oggi: oggi).valore(.importoPagato) == nil)

        // Il sollecito: solo numero di polizza, numero di sinistro e assicurato
        var perSollecito = completo
        perSollecito.titolo = "Titolo riservato di prova"
        let soll = MotoreSinistri.sollecito(perSollecito, polizza: polizza, assicurato: polizza.assicurato, firma: "Firma di prova")
        verifica.vero("Sinistri: il sollecito ha numero di polizza, di sinistro e assicurato",
                      soll.corpo.contains("POL-PROVA-5521") && soll.corpo.contains("NUM-PROVA-7731") && soll.corpo.contains("Ottavio Prova")
                      && soll.oggetto.contains("NUM-PROVA-7731") && soll.corpo.hasSuffix("Firma di prova"))
        verifica.vero("Sinistri: il sollecito non porta titolo, descrizione, fatti, documenti né importi",
                      !(soll.oggetto + soll.corpo).contains("riservat") && !soll.corpo.contains("Perito")
                      && !soll.corpo.contains("€") && !soll.corpo.contains("Documento"))
        let indirizzi = [IndirizzoCompagnia(id: "i1", compagnia: "Compagnia di Prova", email: "sinistri@prova.invalid", soloPortale: false),
                         IndirizzoCompagnia(id: "i2", compagnia: "Altra Compagnia", email: "", soloPortale: true)]
        verifica.vero("Sinistri: l'indirizzo della compagnia si trova senza maiuscole e spazi",
                      MotoreSinistri.indirizzo(compagnia: " compagnia di prova ", in: indirizzi)?.id == "i1"
                      && MotoreSinistri.indirizzo(compagnia: "", in: indirizzi) == nil
                      && MotoreSinistri.indirizzo(compagnia: "Nessuna", in: indirizzi) == nil)
        verifica.vero("Sinistri: le polizze adatte sono le protezioni in essere del cliente",
                      MotoreSinistri.polizzeAdatte([polizza, AiutiProva.posizione("Fondo di prova", .investimento, 7_311)], clienteId: cliente.id).map(\.id)
                      == [polizza.id])

        // «Prisma ovunque»: titolo, fase, fatti e documenti senza file; via descrizione, numero, stime, importo
        let ridotto = SpazioOvunque.sinistroPerOvunque(completo)
        verifica.vero("Sinistri: per «Prisma ovunque» senza descrizione, numero, stime, importo e file dei documenti",
                      ridotto.descrizione.isEmpty && ridotto.numeroSinistro == nil && ridotto.stimaMinima == nil && ridotto.stimaMassima == nil
                      && ridotto.pagato == nil && ridotto.documenti.allSatisfy { $0.documentoId == nil }
                      && ridotto.titolo == completo.titolo && ridotto.fase == completo.fase && ridotto.eventi == completo.eventi)

        // I testi brevi (decisione 36)
        let lungo = String(repeating: "parola ", count: 40) + "\nfine"
        verifica.vero("Sinistri: i testi brevi restano su una riga entro il limite",
                      MotoreSinistri.breve(lungo, limite: MotoreSinistri.lunghezzaTesto).count == MotoreSinistri.lunghezzaTesto
                      && !MotoreSinistri.breve("  uno\ndue  ", limite: 60).contains("\n"))

        // I sinistri di prova: tre, con il prefisso, sempre uguali per lo stesso giorno, solo con i clienti di prova
        let prova = SinistriDiProva.sinistri(oggi: oggi)
        verifica.vero("Sinistri: tre sinistri di prova con il prefisso, uguali fra due letture",
                      prova.count == 3 && prova.allSatisfy { $0.id.hasPrefix(SinistriDiProva.prefisso) } && prova == SinistriDiProva.sinistri(oggi: oggi))
        var vuoto = DatiPrisma(clienti: [], appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: "", impostazioni: Impostazioni())
        SinistriDiProva.applica(&vuoto, oggi: oggi)
        verifica.vero("Sinistri: senza clienti di prova nessun sinistro di prova", vuoto.sinistri.isEmpty)
        var demo = DatiPrisma.demo()
        let primaDemo = demo.sinistri.count
        SinistriDiProva.applica(&demo, oggi: oggi)
        verifica.vero("Sinistri: i sinistri di prova non si aggiungono due volte", demo.sinistri.count == primaDemo && primaDemo == 3)
        verifica.vero("Sinistri: Marco sulla polizza di prova, Sofia e Giulia «polizza da collegare»",
                      demo.sinistri.first(where: { $0.id == SinistriDiProva.idMarco })?.posizioneId == SinistriDiProva.polizzaMarco
                      && demo.posizioni.contains { $0.id == SinistriDiProva.polizzaMarco }
                      && demo.sinistri.filter { $0.posizioneId == nil }.count == 2)

        // Le impostazioni dei sinistri: soglia di base 14, fuori misura torna di base, elenchi letti con tolleranza
        let json = #"{"giorniFerma": 9, "giorniSinistroFermo": 999, "indirizziSinistri": [{"id": "a", "compagnia": "X", "email": "x@prova.invalid", "soloPortale": true}, {"id": 3}], "documentiPerSinistro": [{"id": "t", "tipo": "Furto", "documenti": ["Denuncia"]}]}"#
        let lette = try? JSONDecoder().decode(ImpostazioniPratiche.self, from: Data(json.utf8))
        verifica.vero("Sinistri: impostazioni lette con tolleranza (soglia fuori misura → 14, voce rovinata scartata)",
                      lette?.giorniSinistroFermo == nil && lette?.sogliaSinistroFermo == 14 && lette?.indirizziSinistri?.count == 1
                      && lette?.indirizziSinistri?.first?.soloPortale == true && lette?.documentiPerSinistro?.first?.documenti == ["Denuncia"]
                      && lette?.giorniFerma == 9)
        verifica.vero("Sinistri: senza scelta la soglia del sinistro fermo è 14", ImpostazioniPratiche().sogliaSinistroFermo == 14)
    }
}
