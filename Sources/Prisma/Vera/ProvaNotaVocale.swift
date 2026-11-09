import Foundation

/// Prove della nota vocale («Luce» giro 13, Design/template-luce-specifica.md §6.2), dentro `Prisma --prova-vera`, solo
/// con dati di prova dichiarati (la nota del template su Giulia, `NotaVocaleDiProva`): la busta «prisma/nota» e i suoi
/// limiti; la nota ricevuta due volte non si raddoppia, con Prisma bloccato è accettata ma la scheda non si mostra; il
/// cliente riconosciuto (sicuro, dubbio fra omonimi, nessuno, l'appuntamento appena concluso come indizio); le proposte
/// delle regole (nota, attività con la data da confermare, messaggio, obiettivo solo se esiste); Qwen assente = solo
/// regole; la conferma con id stabili, senza doppioni e senza toccare il profilo MiFID; la coda cifrata dell'iPhone;
/// le note fuori da «Prisma ovunque»; le voci del pannello Novità.
/// Chiamata da `ProvaVera.esegui()`.
enum ProvaNotaVocale {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        busta(controlla)
        arrivo(controlla)
        cliente(controlla)
        proposte(controlla)
        conferma(controlla)
        coda(controlla)
        ovunqueENovita(controlla)
    }

    /// L'8 novembre 2026, a mezzogiorno (al secondo).
    static let oggi = NotaInArrivo.alSecondo(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 12)) ?? Date())

    // MARK: - 1. La busta

    private static func busta(_ controlla: (Bool, String) -> Void) {
        let n = NotaVocaleDiProva.ponte(quando: oggi)
        guard let k = PonteVera.chiave(PonteVera.nuovoCodice()) else { return controlla(false, "Nota: chiave dal codice") }
        let aperta = BustaPonte.apri((try? ArrivoPonte.notaVocale(n).busta(k)) ?? Data(), k)
        controlla(aperta?.percorso == BustaPonte.nota && aperta.flatMap(ArrivoPonte.leggi) == .notaVocale(n),
                  "Nota: la busta «prisma/nota» si sigilla e si riapre uguale")
        var lunga = n
        lunga.testo = String(repeating: "a", count: PonteVera.massimoTestoNota + 1)
        let bustaLunga = BustaPonte(quando: oggi.timeIntervalSince1970, percorso: BustaPonte.nota, corpo: try? JSONEncoder().encode(lunga))
        controlla(!lunga.valido && ArrivoPonte.leggi(bustaLunga) == nil, "Nota: un testo di 4.001 caratteri è rifiutato")
        var vuota = n
        vuota.testo = "   "
        controlla(!vuota.valido, "Nota: una nota senza testo è rifiutata")
    }

    // MARK: - 2. L'arrivo sul Mac

    private static func arrivo(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        var n = NotaVocaleDiProva.ponte(quando: oggi.addingTimeInterval(0.6))
        n.id = NotaVocaleDiProva.prefisso + "arrivo"
        let prima = s.riceviDalPonte(.notaVocale(n))
        let seconda = s.riceviDalPonte(.notaVocale(n))
        let arrivate = s.dati.noteInArrivo.filter { $0.id == n.id }
        controlla(prima.accettato && seconda.accettato && arrivate.count == 1, "Nota: la stessa nota ricevuta due volte resta una")
        let q = arrivate.first?.quando.timeIntervalSinceReferenceDate ?? 0.5
        controlla(q.rounded(.down) == q, "Nota: le date della nota arrivata sono al secondo (come le scrive l'archivio)")
        controlla(arrivate.first?.clienteId == "giulia" && arrivate.first?.conQwen == false && s.notaVocale.mostrata == n.id,
                  "Nota: Prisma capisce che si parla di Giulia (solo regole, Qwen assente) e mostra la scheda «Arriva sul Mac»")
        // Con Prisma bloccato: accettata, da guardare, ma la scheda non si mostra
        let b = StatoShell(persistente: false)
        b.blocca(animato: false)
        var bloccata = n
        bloccata.id = NotaVocaleDiProva.prefisso + "bloccato"
        let r = b.riceviDalPonte(.notaVocale(bloccata))
        controlla(r.accettato && b.dati.noteInArrivo.first { $0.id == bloccata.id }?.stato == .daGuardare && b.notaVocale.mostrata == nil,
                  "Nota: con Prisma bloccato la nota è accettata e aspetta, senza mostrare la scheda")
        // In modalità cliente: accettata, mai mostrata (porta il testo dettato e il nome di un altro cliente)
        let m = StatoShell(persistente: false)
        m.clienteAttivoId = "marco"
        m.entraModoCliente(avviso: false)
        var privata = n
        privata.id = NotaVocaleDiProva.prefisso + "modo-cliente"
        controlla(m.riceviDalPonte(.notaVocale(privata)).accettato && m.notaVocale.mostrata == nil,
                  "Nota: in modalità cliente la nota è accettata ma la scheda non si mostra")
    }

    // MARK: - 4. Il cliente

    private static func cliente(_ controlla: (Bool, String) -> Void) {
        let d = DatiPrisma.demo()
        controlla(MotoreNotaVocale.cliente(in: NotaVocaleDiProva.testo, clienti: d.clienti, appuntamenti: [], quando: oggi) == .sicuro("giulia"),
                  "Nota: nel testo del template si parla di Giulia")
        var altro = Cliente.nuovo(tinta: .blu)
        altro.nome = "Marco Verdi"
        let conDue = d.clienti + [altro]
        let dubbio = MotoreNotaVocale.cliente(in: "Ho sentito Marco per la polizza.", clienti: conDue, appuntamenti: [], quando: oggi)
        if case .dubbio(let c) = dubbio {
            controlla(c.count == 2 && c.count <= MotoreNotaVocale.maxCandidati && c.contains("marco") && c.contains(altro.id),
                      "Nota: con due «Marco» Prisma chiede di chi si parla (mai una scelta silenziosa)")
        } else {
            controlla(false, "Nota: con due «Marco» Prisma chiede di chi si parla (mai una scelta silenziosa)")
        }
        controlla(MotoreNotaVocale.cliente(in: "Ho sentito Marco Verdi per la polizza.", clienti: conDue, appuntamenti: [], quando: oggi) == .sicuro(altro.id),
                  "Nota: nome e cognome tolgono il dubbio")
        controlla(MotoreNotaVocale.cliente(in: "Da richiamare per la polizza.", clienti: d.clienti, appuntamenti: [], quando: oggi) == .nessuno,
                  "Nota: nessun nome e nessun appuntamento → «Non ho capito di chi si parla»")
        let visita = Appuntamento(id: "app-prova-nota", clienteId: "laura", titolo: "Visita di prova", inizio: oggi.addingTimeInterval(-2 * 3600),
                                  durataMinuti: 60, luogo: "", note: "", stato: .concluso)
        controlla(MotoreNotaVocale.cliente(in: "Da richiamare per la polizza.", clienti: d.clienti, appuntamenti: [visita], quando: oggi) == .sicuro("laura"),
                  "Nota: senza nomi l'appuntamento concluso da un'ora vale come indizio (Laura)")
        let vecchia = Appuntamento(id: "app-prova-vecchia", clienteId: "laura", titolo: "Visita di prova", inizio: oggi.addingTimeInterval(-6 * 3600),
                                   durataMinuti: 60, luogo: "", note: "", stato: .concluso)
        controlla(MotoreNotaVocale.cliente(in: "Da richiamare.", clienti: d.clienti, appuntamenti: [vecchia], quando: oggi) == .nessuno,
                  "Nota: un appuntamento finito da più di 3 ore non conta")
    }

    // MARK: - 3. Le proposte

    private static func proposte(_ controlla: (Bool, String) -> Void) {
        let d = DatiPrisma.demo()
        let n = NotaVocaleDiProva.inArrivo(d, oggi: oggi)
        let p = n.proposte
        controlla(p.first?.tipo == .nota && p.first?.titolo == "Giulia vuole anticipare la casa di un anno.",
                  "Nota: la prima voce è sempre la nota, con la prima frase («\(p.first?.titolo ?? "")»)")
        let gennaio = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2027, month: 1, day: 1))
        let attivita = p.first { $0.tipo == .attivita }
        controlla(attivita?.titolo == "Risentire Giulia per il mutuo · gennaio" && attivita?.scadenza == gennaio && attivita?.scadenzaDaConfermare == true,
                  "Nota: «Risentire Giulia per il mutuo · gennaio» il 1° gennaio 2027, da confermare («\(attivita?.titolo ?? "")»)")
        let messaggio = p.first { $0.tipo == .messaggio }
        controlla(messaggio?.titolo == "Il confronto con 650 € al mese" && messaggio?.importi == [650] && messaggio?.frequenza == .mensile,
                  "Nota: «Il confronto con 650 € al mese» da preparare («\(messaggio?.titolo ?? "")»)")
        let casa = d.obiettivi.first { $0.clienteId == "giulia" && $0.area == .casa }
        let obiettivo = p.first { $0.tipo == .obiettivo }
        controlla(casa != nil && obiettivo?.obiettivoId == casa?.id && obiettivo?.anniSpostamento == -1
                  && obiettivo?.titolo == "Casa: un anno prima · da confermare",
                  "Nota: l'obiettivo casa di Giulia, un anno prima, da confermare")
        var senzaCasa = d
        senzaCasa.obiettivi.removeAll { $0.clienteId == "giulia" && $0.area == .casa }
        controlla(!NotaVocaleDiProva.inArrivo(senzaCasa, oggi: oggi).proposte.contains { $0.tipo == .obiettivo },
                  "Nota: senza l'obiettivo casa nessuna proposta d'obiettivo (mai creato da qui)")
        let sola = MotoreNotaVocale.proposte(testo: "Visita andata bene, cliente contento.", cliente: nil, obiettivi: d.obiettivi, oggi: oggi)
        controlla(sola.map(\.tipo) == [.nota], "Nota: senza nulla da proporre resta solo «Nota per il dossier»")
    }

    // MARK: - 6. La conferma

    private static func conferma(_ controlla: (Bool, String) -> Void) {
        var d = DatiPrisma.demo()
        var n = NotaVocaleDiProva.inArrivo(d, oggi: oggi)
        let profilo = d.clienti.first { $0.id == "giulia" }?.profilo
        let scadenzaCasa = d.obiettivi.first { $0.clienteId == "giulia" && $0.area == .casa }?.scadenza
        let note = d.note.count, attivita = d.attivita.count
        let esito = ApplicaNotaVocale.applica(nil, nota: &n, a: &d, oggi: oggi)
        let casa = d.obiettivi.first { $0.clienteId == "giulia" && $0.area == .casa }
        let attesa = scadenzaCasa.flatMap { Calendar(identifier: .gregorian).date(byAdding: .year, value: -1, to: $0) }
        controlla(esito.note == 1 && esito.attivita == 1 && esito.obiettivi == 1 && esito.messaggi.count == 1
                  && d.note.count == note + 1 && d.attivita.count == attivita + 1 && casa?.scadenza == attesa,
                  "Nota: «Conferma tutto» crea una nota e un'attività e anticipa l'obiettivo casa di un anno")
        controlla(n.stato == .confermata && n.decisaIl != nil && n.proposte.allSatisfy { $0.stato == .confermata }
                  && n.proposte.first { $0.tipo == .nota }?.titoloVoce == "Nota salvata nel dossier",
                  "Nota: dopo la conferma la nota è decisa e i titoli vanno al passato")
        let seconda = ApplicaNotaVocale.applica(nil, nota: &n, a: &d, oggi: oggi)
        controlla(seconda == EsitoNotaVocale() && d.note.count == note + 1 && d.attivita.count == attivita + 1
                  && d.obiettivi.first { $0.id == casa?.id }?.scadenza == attesa,
                  "Nota: confermare di nuovo non crea niente (id stabili)")
        controlla(d.clienti.first { $0.id == "giulia" }?.profilo == profilo, "Nota: il profilo MiFID non si tocca mai")
        var d2 = DatiPrisma.demo()
        var n2 = NotaVocaleDiProva.inArrivo(d2, oggi: oggi, id: NotaVocaleDiProva.prefisso + "scarta")
        if let a = n2.proposte.first(where: { $0.tipo == .attivita }) { ApplicaNotaVocale.scarta(a.id, nota: &n2, oggi: oggi) }
        let prima = d2.attivita.count
        let e2 = ApplicaNotaVocale.applica(nil, nota: &n2, a: &d2, oggi: oggi)
        controlla(e2.attivita == 0 && d2.attivita.count == prima && n2.stato == .confermata, "Nota: una proposta scartata non entra")
        // Senza gli appuntamenti dei dati di prova (nascono attorno al giorno della prova): nessun indizio del cliente
        var senzaAppuntamenti = d2
        senzaAppuntamenti.appuntamenti = []
        var senzaCliente = NotaVocaleDiProva.inArrivo(senzaAppuntamenti, oggi: oggi, testo: "Da richiamare per la polizza.",
                                                      id: NotaVocaleDiProva.prefisso + "nessuno")
        let e3 = ApplicaNotaVocale.applica(nil, nota: &senzaCliente, a: &d2, oggi: oggi)
        controlla(senzaCliente.clienteId == nil && e3 == EsitoNotaVocale() && senzaCliente.stato == .daGuardare,
                  "Nota: senza il cliente scelto non entra niente")
    }

    // MARK: - 7. La coda cifrata dell'iPhone

    private static func coda(_ controlla: (Bool, String) -> Void) {
        ProvaCodaNoteVocali.esegui(controlla)
    }

    // MARK: - 8-9. Prisma ovunque e Novità

    private static func ovunqueENovita(_ controlla: (Bool, String) -> Void) {
        var d = DatiPrisma.demo()
        d.noteInArrivo = [NotaVocaleDiProva.inArrivo(d, oggi: oggi)]
        controlla(SpazioOvunque.datiIstantanea(d).noteInArrivo.isEmpty, "Nota: le note dall'iPhone non entrano in Prisma ovunque")
        let s = StatoShell(persistente: false)
        s.apriVoceNovita(NovitaLuce.notaVocale)
        controlla(NovitaLuce.nuovoCliente.disponibile && NovitaLuce.notaVocale.disponibile && s.appAttiva == .incontri,
                  "Novità: «Nuovo cliente in 10 secondi» e «La nota vocale» sono accese; la nota apre Incontri")
    }
}
