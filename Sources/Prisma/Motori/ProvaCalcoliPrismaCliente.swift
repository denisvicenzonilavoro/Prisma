import Foundation

// Prova del Prisma del cliente («Luce» giro 15, §2.1 e §5 del piano): le voci spente non entrano nel JSON (nomi dei
// prodotti, importi delle posizioni, codice fiscale, email, telefono); gli obiettivi senza importo restano fuori; la quota
// è il già da parte (decisione 81); le serie della linea della vita sono una per età del cursore dopo quella di oggi; la
// frase «indicativa»; la tabella 60/62/64/67/70; la lettera solo con la sua voce; cifra e decifra uguali; password
// sbagliata e dati associati alterati rifiutati; fuori dal blocco niente nome né cifre; il testo di Messaggi senza
// password; il nome del file solo con il nome di battesimo. Cliente, posizioni e cifre inventati per la prova (cifre non
// tonde, date fisse).
enum ProvaCalcoliPrismaCliente {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 6, 15)
        var c = Cliente(id: "prova-prisma-cliente", nome: "Ottavia Brunelleschi", iniziali: "OB", tinta: .viola, tema: "",
                        email: "ottavia.prova@esempio.invalid", telefono: "+39 333 765 4219", preferito: false, nota: "",
                        creatoIl: AiutiProva.data(2023, 2, 7))
        c.dataNascita = AiutiProva.data(1991, 3, 10)
        c.codiceFiscale = "BRNTTV91C50A944K"
        var pos = Posizione(clienteId: c.id, canale: .alleanza, stato: .inEssere, area: .investimento,
                            nome: "Piano Lampone Prova")
        pos.controvalore = 23_417.83
        pos.numeroContratto = "CONTR-778213"

        var casa = Obiettivo(clienteId: c.id, titolo: "Anticipo casa", area: .casa, importo: 10_325,
                             scadenza: AiutiProva.data(2031, 9, 1))
        casa.accantonato = 4_130
        casa.priorita = .alta
        let senzaImporto = Obiettivo(clienteId: c.id, titolo: "Sogno senza cifra", area: .famiglia, importo: 0,
                                     scadenza: AiutiProva.data(2030, 1, 1))
        var studi = Obiettivo(clienteId: c.id, titolo: "Studi di Leo", area: .famiglia, importo: 18_740,
                              scadenza: AiutiProva.data(2036, 9, 1))
        studi.priorita = .media

        let pensioni = Dictionary(uniqueKeysWithValues: (55...72).map { ($0, 1_187.0) })
        let ingresso = IngressoLineaVita(etaOggi: 35, etaPensione: 67, patrimonioIniziale: 21_806, risparmioAnnuo: 3_260,
                                         rendimentoReale: 1.7, redditoDesiderato: 1_930, pensionePerEta: pensioni)
        let preparazione = PreparazioneLineaVita(ingresso: ingresso, motivoAssente: nil, avvisi: [], ipotesi: [],
                                                 etaPensioneIpotizzata: false, eventiSenzaCifra: 0)
        let senzaNascita = PreparazioneLineaVita(ingresso: nil, motivoAssente: "Per disegnare la linea della vita serve la data di nascita di Ottavia.",
                                                 avvisi: [], ipotesi: [], etaPensioneIpotizzata: false, eventiSenzaCifra: 0)
        let fino = AiutiProva.data(2027, 6, 15)
        let consulente = TestiPrismaCliente.consulente("Nome Prova")

        let letteraDiProva = "Cara Ottavia, ti scrivo dai tuoi 67 anni."
        func componi(_ voci: Set<VoceFilePrisma>, lettera: String? = nil, senzaLettera: Bool = false,
                     preparazione altra: PreparazioneLineaVita? = nil) -> ContenutoPrismaCliente {
            CompositorePrismaCliente.componi(cliente: c, posizioni: [pos], obiettivi: [casa, senzaImporto, studi],
                                             preparazione: altra ?? preparazione,
                                             voci: voci, lettera: senzaLettera ? nil : (lettera ?? letteraDiProva), film: nil, luce: nil, giornata: nil, sinistri: [],
                                             consulente: consulente, avvertenze: [ImpostazioniSala.segnapostoAvvertenza],
                                             validoFinoAl: fino, oggi: oggi, diProva: true)
        }

        // Disponibilità
        let d = CompositorePrismaCliente.disponibilita(cliente: c, posizioni: [pos], obiettivi: [senzaImporto], preparazione: senzaNascita,
                                                       lettera: nil, film: nil, luce: false, giornata: false, sinistri: [])
        verifica.vero("Prisma del cliente: senza obiettivi con importo la voce è spenta con il motivo", d[.obiettivi] != nil)
        verifica.vero("Prisma del cliente: senza data di nascita niente linea della vita", d[.lineaVita] != nil)
        verifica.vero("Prisma del cliente: lettera e film non pronti hanno il motivo", d[.lettera] != nil && d[.film] != nil)
        verifica.vero("Prisma del cliente: con una posizione in essere le posizioni si possono accendere", d[.posizioni] == nil)
        let tutte = CompositorePrismaCliente.disponibilita(cliente: c, posizioni: [pos], obiettivi: [casa], preparazione: preparazione,
                                                           lettera: "x", film: nil, luce: true, giornata: true, sinistri: [])
        verifica.vero("Prisma del cliente: obiettivi e linea della vita disponibili con i dati", tutte[.obiettivi] == nil && tutte[.lineaVita] == nil)

        // Voci spente fuori dal JSON
        let base = componi(VoceFilePrisma.accesePredefinite)
        let json = (try? base.json()).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        verifica.vero("Prisma del cliente: JSON del contenuto prodotto", !json.isEmpty)
        for vietato in ["Piano Lampone Prova", "23417.83", "BRNTTV91C50A944K", "esempio.invalid", "765 4219", "CONTR-778213", "Brunelleschi"] {
            verifica.vero("Prisma del cliente: «\(vietato)» non è nel JSON con le posizioni spente", !json.contains(vietato))
        }
        verifica.vero("Prisma del cliente: posizioni spente = nessuna posizione", base.posizioni == nil)
        let conPosizioni = componi([.posizioni])
        verifica.vero("Prisma del cliente: posizioni accese con nome e canale, senza contratto",
                      conPosizioni.posizioni?.first?.nome == "Piano Lampone Prova"
                          && !((try? conPosizioni.json()).flatMap { String(data: $0, encoding: .utf8) } ?? "").contains("CONTR-778213"))

        // Obiettivi
        let titoli = base.obiettivi?.map(\.titolo) ?? []
        verifica.vero("Prisma del cliente: obiettivo senza importo escluso", !titoli.contains("Sogno senza cifra"))
        verifica.vero("Prisma del cliente: obiettivi per priorità (prima il più importante)", titoli.first == "Anticipo casa")
        verifica(  "Prisma del cliente: quota = già da parte / importo", base.obiettivi?.first?.quota ?? -1, 4_130.0 / 10_325.0,
                 tolleranza: 0.0001)
        verifica.vero("Prisma del cliente: colore dell'area in esadecimale", base.obiettivi?.first?.coloreHex.hasPrefix("#") == true
                          && base.obiettivi?.first?.coloreHex.count == 7)
        verifica.vero("Prisma del cliente: frase del già da parte", TestiPrismaCliente.fraseObiettivo(0.4) == "Hai già messo da parte il 40%")

        // Linea della vita
        let linea = base.lineaVita
        verifica(  "Prisma del cliente: 13 serie a 35 anni (58-70)", Double(linea?.serie.count ?? 0), 13)
        let vecchio = PreparazioneLineaVita(ingresso: IngressoLineaVita(etaOggi: 61, etaPensione: 67, patrimonioIniziale: 52_310,
                                                                       risparmioAnnuo: 2_140, rendimentoReale: 1.3, redditoDesiderato: nil),
                                            motivoAssente: nil, avvisi: [], ipotesi: [], etaPensioneIpotizzata: false, eventiSenzaCifra: 0)
        let lineaVecchio = CompositorePrismaCliente.lineaVita(vecchio)
        verifica.vero("Prisma del cliente: le età fino a quella di oggi sono escluse",
                      lineaVecchio?.serie.allSatisfy { $0.etaPensione > 61 } == true && lineaVecchio?.serie.count == 9)
        verifica.vero("Prisma del cliente: senza reddito desiderato la linea è indicativa", lineaVecchio?.indicativa == true)
        verifica.vero("Prisma del cliente: con reddito e pensione la linea non è indicativa", linea?.indicativa == false)
        verifica.vero("Prisma del cliente: ogni serie va da oggi a 90 anni",
                      linea?.serie.allSatisfy { $0.valori.count == (linea?.etaFine ?? 0) - 35 + 1 } == true)
        if let l = linea, let s67 = l.serie(67) {
            var i = ingresso
            i.etaPensione = 67
            let r = MotoreLineaVita.calcola(i)
            verifica.vero("Prisma del cliente: la serie a 67 è quella del motore", s67.valori == r.punti.map(\.valore)
                              && s67.etaEsaurimento == r.etaEsaurimento)
            let righe = CompositorePrismaCliente.righeTabella(l)
            verifica.vero("Prisma del cliente: tabella 60/62/64/67/70", righe.map(\.eta) == [60, 62, 64, 67, 70])
            verifica.vero("Prisma del cliente: frasi della tabella", righe.allSatisfy { $0.frase.hasPrefix("I risparmi bastano") })
        } else {
            verifica.vero("Prisma del cliente: serie a 67 presente", false)
        }
        verifica.vero("Prisma del cliente: frase oltre i 90", TestiPrismaCliente.frasePensione(esaurimento: nil, etaFine: 90) == "I risparmi bastano oltre i 90 anni")
        verifica.vero("Prisma del cliente: frase fino a N", TestiPrismaCliente.frasePensione(esaurimento: 83, etaFine: 90) == "I risparmi bastano fino a 83 anni")
        verifica.vero("Prisma del cliente: senza data di nascita nessuna linea", componi([.lineaVita], preparazione: senzaNascita).lineaVita == nil)

        // Lettera solo con la sua voce
        verifica.vero("Prisma del cliente: lettera con la voce accesa", base.lettera != nil)
        verifica.vero("Prisma del cliente: lettera spenta fuori dal file", componi([.obiettivi]).lettera == nil)
        verifica.vero("Prisma del cliente: lettera vuota fuori dal file", componi([.lettera], lettera: "  \n").lettera == nil)

        // Cifratura (poche iterazioni: la prova è sul formato, non sulla lentezza)
        let password = "Prova-Calcoli-Lampo-73"
        if let cifrato = try? FilePrismaCliente.cifra(base, password: password, iterazioni: 1_000) {
            let (i, blocco) = cifrato
            let aperto = try? FilePrismaCliente.decifra(blocco, i, password: password)
            verifica.vero("Prisma del cliente: cifra e decifra uguali", aperto == base)
            var sbagliata = false
            do { _ = try FilePrismaCliente.decifra(blocco, i, password: "Prova-Calcoli-Lampo-74") } catch { sbagliata = true }
            verifica.vero("Prisma del cliente: password sbagliata rifiutata", sbagliata)
            var alterata = i
            alterata.scadenza = "2099-12-31"
            var rifiutata = false
            do { _ = try FilePrismaCliente.decifra(blocco, alterata, password: password) } catch { rifiutata = true }
            verifica.vero("Prisma del cliente: dati associati alterati rifiutati", rifiutata)
            verifica.vero("Prisma del cliente: sale di 16 byte e nonce di 12", i.sale.count == 16 && i.nonce.count == 12)
            verifica.vero("Prisma del cliente: scadenza in chiaro nel formato aaaa-mm-gg", i.scadenza == FilePrismaCliente.giorno(fino))
            verifica.vero("Prisma del cliente: intestazione riletta dal suo JSON", FilePrismaCliente.Intestazione.daJSON(i.json) == i)
        } else {
            verifica.vero("Prisma del cliente: cifratura riuscita", false)
        }
        verifica.vero("Prisma del cliente: 600.000 iterazioni nel file", FilePrismaCliente.iterazioni == 600_000)

        // L'HTML: fuori dal blocco niente nome né cifre
        if let dati = try? FilePrismaCliente.html(base, password: password, iterazioni: 1_000),
           let html = String(data: dati, encoding: .utf8) {
            let fuori = FilePrismaCliente.fuoriDalBlocco(html)
            verifica.vero("Prisma del cliente: fuori dal blocco niente nome", !fuori.contains("Ottavia") && !fuori.contains("Brunelleschi"))
            verifica.vero("Prisma del cliente: fuori dal blocco niente obiettivi né lettera",
                          !fuori.contains("Anticipo casa") && !fuori.contains("Cara Ottavia"))
            verifica.vero("Prisma del cliente: fuori dal blocco niente password", !html.contains(password))
            verifica.vero("Prisma del cliente: nessun indirizzo web nell'HTML", !html.contains("http://") && !html.contains("https://"))
            if let parti = FilePrismaCliente.parti(html) {
                let (i, blocco) = parti
                verifica.vero("Prisma del cliente: l'HTML si riapre con la password", (try? FilePrismaCliente.decifra(blocco, i, password: password)) == base)
            } else {
                verifica.vero("Prisma del cliente: parti dell'HTML leggibili", false)
            }
        } else {
            verifica.vero("Prisma del cliente: HTML prodotto (risorse del lettore nel pacchetto)", false)
        }

        // Messaggio e nome del file
        let proposta = GeneratorePassword.nuova(cliente: c)
        let testo = TestiPrismaCliente.messaggio(c)
        verifica.vero("Prisma del cliente: il testo di Messaggi non contiene la password", !testo.contains(proposta) && !testo.contains(password))
        verifica.vero("Prisma del cliente: il testo di Messaggi dice che la password arriva a voce", testo.contains("a voce"))
        let nomePDF = FilePrismaCliente.nomeFile(base, estensione: "pdf")
        verifica.vero("Prisma del cliente: nome del file con il solo nome di battesimo",
                      nomePDF == "Il-Prisma-di-Ottavia.pdf" && !nomePDF.contains("Brunelleschi"))
        verifica.vero("Prisma del cliente: nome del file senza accenti né spazi", TestiPrismaCliente.baseNomeFile("Niccolò Maria") == "Il-Prisma-di-NiccoloMaria")
        verifica.vero("Prisma del cliente: traccia senza password", !TestiPrismaCliente.descrizioneUscita(base.voci, html: false).contains(password))
        verifica.vero("Prisma del cliente: voci per l'esperienza della Sala",
                      VoceFilePrisma.perEsperienza(.film) == .film && VoceFilePrisma.perEsperienza(.disegna) == nil)
    }
}
