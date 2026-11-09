import Foundation

// Prova della condivisione del biglietto dei traguardi («Luce» giro 15, §5.4, decisioni 9 e 115): la copia da spedire
// nasce nella cartella temporanea delle uscite (`CartellaUscite`, sotto `temporaryDirectory`, mai in Download) con il nome
// «Biglietto per Sofia.png»; `togli` e `svuota` la cancellano e `togli` non tocca un file fuori dalla cartella; con
// «Mostra la cifra» spento il biglietto non riceve né la cifra né la didascalia (funzione pura che sceglie i testi);
// la frase scritta a mano prende il posto di quella di Prisma; la traccia nel dossier dice se c'era la cifra.
// Traguardo e cifre inventati per la prova (nessuna dipendenza dalla data di oggi). Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliBiglietto {
    static func esegui(_ verifica: VerificaCalcoli) {
        testi(verifica)
        cartella(verifica)
    }

    /// Un traguardo di prova con una cifra non tonda.
    private static func traguardo(cifra: Double? = 87_341, didascalia: String? = "messi al sicuro in 4 anni e 7 mesi") -> Traguardo {
        let giorno = AiutiProva.data(2026, 3, 17)
        return Traguardo(id: "obiettivoRaggiunto-prova-biglietto-ob", tipo: .obiettivoRaggiunto, clienteId: "prova-biglietto",
                         data: giorno, titolo: "Ha raggiunto «Casa al lago»",
                         fraseBreve: "Sofia ha raggiunto «Casa al lago».", perche: "Obiettivo raggiunto ieri",
                         saluto: "Ce l’hai fatta, Sofia.", cifra: cifra, didascaliaCifra: didascalia,
                         frase: TestiTraguardi.fraseObiettivo, ideaRegalo: nil, capsulaId: nil, festeggiatoIl: nil,
                         fraseMomento: "Il 17 marzo Sofia ha raggiunto «Casa al lago».", peso: 87_341)
    }

    // MARK: Testi (funzione pura)

    private static func testi(_ verifica: VerificaCalcoli) {
        let t = traguardo()
        let spenta = TestiBiglietto.contenuto(t, mostraCifra: false, frase: nil)
        verifica.vero("Biglietto: con «Mostra la cifra» spento niente cifra", spenta.cifra == nil)
        verifica.vero("Biglietto: con «Mostra la cifra» spento niente didascalia della cifra", spenta.didascalia == nil)
        verifica.vero("Biglietto: con la cifra spenta restano saluto e frase di Prisma",
                      spenta.saluto == t.saluto && spenta.frase == t.frase)
        let accesa = TestiBiglietto.contenuto(t, mostraCifra: true, frase: nil)
        verifica("Biglietto: con «Mostra la cifra» acceso la cifra del traguardo", accesa.cifra ?? -1, 87_341)
        verifica.vero("Biglietto: con la cifra accesa anche la didascalia", accesa.didascalia == t.didascaliaCifra)
        let senzaCifra = TestiBiglietto.contenuto(traguardo(cifra: nil, didascalia: nil), mostraCifra: true, frase: nil)
        verifica.vero("Biglietto: un traguardo senza cifra non ne inventa una", senzaCifra.cifra == nil && senzaCifra.didascalia == nil)
        // Una didascalia senza cifra non compare da sola
        let soloDidascalia = TestiBiglietto.contenuto(traguardo(cifra: nil), mostraCifra: true, frase: nil)
        verifica.vero("Biglietto: niente didascalia senza la cifra", soloDidascalia.didascalia == nil)

        // La frase scritta a mano
        let scritta = TestiBiglietto.contenuto(t, mostraCifra: false, frase: "  Un abbraccio per la casa nuova, Sofia.\n")
        verifica.vero("Biglietto: la frase scritta a mano (ripulita) al posto di quella di Prisma",
                      scritta.frase == "Un abbraccio per la casa nuova, Sofia.")
        verifica.vero("Biglietto: una frase vuota torna a quella di Prisma",
                      TestiBiglietto.contenuto(t, mostraCifra: false, frase: "  \n ").frase == t.frase)
        verifica.vero("Biglietto: la frase uguale a quella di Prisma non conta come cambiata",
                      TestiBiglietto.fraseScritta(t.frase, traguardo: t) == nil)
        let lunga = String(repeating: "parola ", count: 80)
        verifica.vero("Biglietto: la frase scritta a mano si taglia alla misura del biglietto",
                      (TestiBiglietto.fraseScritta(lunga, traguardo: t)?.count ?? 0) <= Tema.Apple.Messaggi.Traguardo.Esporta.massimoFrase)

        // Nome del file e traccia
        verifica.vero("Biglietto: nome del file «Biglietto per Sofia.png» (solo il nome di battesimo)",
                      TestiBiglietto.nomeFile(t, nome: "Sofia Romano") == "Biglietto per Sofia.png")
        verifica.vero("Biglietto: senza nome «Biglietto.png»", TestiBiglietto.nomeFile(t, nome: "  ") == "Biglietto.png")
        verifica.vero("Biglietto: la traccia dice «con la cifra» solo se c'era",
                      TestiBiglietto.descrizioneUscita(t, conCifra: true).hasSuffix(" · con la cifra")
                        && !TestiBiglietto.descrizioneUscita(t, conCifra: false).contains("cifra"))
        verifica.vero("Biglietto: la traccia non contiene la cifra",
                      !TestiBiglietto.descrizioneUscita(t, conCifra: true).contains("87"))
        verifica.vero("Biglietto: l'avviso senza cifra non parla di cifre",
                      !TestiBiglietto.avvisoPrimaVolta(nome: "Sofia", conCifra: false).contains("cifre"))
        verifica.vero("Biglietto: la riga del pannello non promette più l'animazione",
                      !TestiTraguardi.biglietto.contains("animato") && !TestiTraguardi.bigliettoNota.contains("prossimo aggiornamento"))
    }

    // MARK: Cartella delle uscite

    private static func cartella(_ verifica: VerificaCalcoli) {
        let fm = FileManager.default
        let t = traguardo()
        let nome = TestiBiglietto.nomeFile(t, nome: "Sofia Romano")
        // Un PNG finto di pochi byte: qui conta dove nasce e quando si cancella (il PNG vero lo disegnano le istantanee)
        let dati = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x31, 0x37])
        guard let url = try? CartellaUscite.scrivi(dati, nome: nome) else {
            verifica.vero("Biglietto: la copia si scrive nella cartella delle uscite", false)
            return
        }
        let temporanea = fm.temporaryDirectory.standardizedFileURL.path
        verifica.vero("Biglietto: la copia nasce sotto la cartella temporanea", url.standardizedFileURL.path.hasPrefix(temporanea + "/"))
        verifica.vero("Biglietto: la copia è dentro la cartella delle uscite", CartellaUscite.dentro(url))
        let download = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first?.standardizedFileURL.path
        verifica.vero("Biglietto: mai nella cartella Download",
                      download.map { !url.standardizedFileURL.path.hasPrefix($0 + "/") } ?? true)
        verifica.vero("Biglietto: il file si chiama «Biglietto per Sofia.png»", url.lastPathComponent == "Biglietto per Sofia.png")
        verifica.vero("Biglietto: il file c'è con i suoi byte", (try? Data(contentsOf: url)) == dati)
        CartellaUscite.togli(url)
        verifica.vero("Biglietto: dopo la condivisione la copia si cancella", !fm.fileExists(atPath: url.path))

        // `togli` non tocca un file fuori dalla cartella delle uscite
        let fuori = fm.temporaryDirectory.appendingPathComponent("prova-biglietto-fuori-\(UUID().uuidString).png")
        if (try? dati.write(to: fuori)) != nil {
            CartellaUscite.togli(fuori)
            verifica.vero("Biglietto: un file fuori dalla cartella delle uscite resta", fm.fileExists(atPath: fuori.path))
            try? fm.removeItem(at: fuori)
        } else {
            verifica.vero("Biglietto: file di controllo fuori dalla cartella scritto", false)
        }

        // Al blocco e alla chiusura: `svuota` cancella tutto
        let secondo = try? CartellaUscite.scrivi(dati, nome: nome)
        CartellaUscite.svuota()
        verifica.vero("Biglietto: al blocco e alla chiusura le copie si cancellano",
                      (secondo.map { !fm.fileExists(atPath: $0.path) } ?? false) && !fm.fileExists(atPath: CartellaUscite.cartella.path))
    }
}
