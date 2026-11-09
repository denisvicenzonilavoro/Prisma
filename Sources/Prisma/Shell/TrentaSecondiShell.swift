import Foundation

// «Il cliente in 30 secondi» nell'app (Vera/BRIEF.md, funzione 6; template «Il cliente in 30 secondi»): si chiede a voce,
// per scritto («Raccontami Marco») o con un tocco dalla scheda del cliente (la card nella Panoramica del dossier), e Vera
// la racconta a voce in 30 secondi: una sezione alla volta (la sezione che sta dicendo si accende, le altre aspettano),
// con l'anello del conto alla rovescia e «Ascolta di nuovo». Il testo detto è quello sullo schermo (stesse cifre).
// A voce parte da sola quando la domanda è arrivata a voce o con il tocco dalla scheda, come le altre risposte (mai con
// «Risposte a voce: mai»); altrimenti c'è il pulsante «Ascolta». Nelle prove e nelle istantanee non parla: lo stato si
// comporta uguale e `avanzaLetturaTrenta` fa le veci della fine di una frase.

/// La lettura a voce in corso (o appena finita) di una scheda «in 30 secondi».
struct LetturaTrentaSecondi: Equatable {
    var messaggioId: String
    /// La sezione che Vera sta dicendo; uguale a `sezioni` quando ha finito (o è stata fermata).
    var sezione: Int
    var sezioni: Int
    /// Cresce a ogni partenza: l'anello riparte da 30.
    var avvio: Int

    var finita: Bool { sezione >= sezioni }
}

extension StatoShell {
    /// Dalla scheda del cliente: apre Vera sulla conversazione del cliente e racconta, a voce (come una domanda detta).
    func trentaSecondiDallaScheda(_ clienteId: String) {
        guard !inModoCliente || clienteId == clienteAttivoId, let c = cliente(clienteId) else { return }
        if clienteAttivoId != clienteId { clienteAttivoId = clienteId }
        if veraPortafoglio { veraPortafoglio = false }
        if !aperta(.vera) { apri(.vera) }
        rispostaAVoce = true
        let primo = c.nome.split(separator: " ").first.map(String.init) ?? c.nome
        raccontaTrentaSecondi(clienteId, domanda: "Raccontami \(primo) in 30 secondi", chiave: clienteId)
    }

    /// Fa partire (o ripartire, «Ascolta di nuovo») la lettura a voce delle cinque sezioni di un messaggio.
    func ascoltaTrentaSecondi(messaggio id: String) {
        guard let t = messaggioVera(id)?.trenta, !t.sezioni.isEmpty else { return }
        if dettaturaAttiva { chiudiDettatura() }
        letturaTrenta = LetturaTrentaSecondi(messaggioId: id, sezione: 0, sezioni: t.sezioni.count, avvio: (letturaTrenta?.avvio ?? 0) + 1)
        diciSezioneTrenta()
    }

    /// Dice la sezione corrente; quando la voce finisce, passa alla successiva.
    private func diciSezioneTrenta() {
        guard let l = letturaTrenta, !l.finita, let t = messaggioVera(l.messaggioId)?.trenta else { return }
        guard persistente else { return }
        let vera = dati.impostazioni.vera
        let id = l.messaggioId
        voceVera.finito = { [weak self] in self?.avanzaLetturaTrenta(id) }
        voceVera.di(TrentaSecondiVera.parlato(t, sezione: l.sezione), voce: vera.voce,
                    velocita: TrentaSecondiVera.velocita(t, preferita: vera.velocitaVoce))
    }

    /// Una sezione è finita: la prossima, oppure la fine (e, a conversazione aperta, Vera torna ad ascoltare).
    func avanzaLetturaTrenta(_ id: String) {
        guard var l = letturaTrenta, l.messaggioId == id, !l.finita else { return }
        l.sezione += 1
        letturaTrenta = l
        if l.finita {
            voceVera.finito = nil
            if persistente, conversazioneAVoce, !bloccato, presentazione == nil { ascolta() }
        } else {
            diciSezioneTrenta()
        }
    }

    /// «Ferma»: Vera smette di parlare e tutte le sezioni restano accese.
    func fermaLetturaTrenta() {
        guard var l = letturaTrenta, !l.finita else { return }
        voceVeraSeNata?.finito = nil
        voceVeraSeNata?.zitta()
        l.sezione = l.sezioni
        letturaTrenta = l
    }
}
