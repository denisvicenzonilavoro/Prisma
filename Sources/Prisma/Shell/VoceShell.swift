#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import Foundation

/// Parlare con Ruby: il microfono, la risposta a voce e la conversazione che continua finché non le dici «basta».
/// L'ascolto e la voce lavorano sul Mac; il testo segue la stessa strada delle domande scritte.
extension StatoShell {
    /// Il pulsante del microfono (e ⌥⌘E): se Ruby ascolta, chiude la frase e la manda; se parla, la ferma e
    /// ascolta; altrimenti inizia ad ascoltare. Dal menu, a conversazione a voce aperta, la chiude.
    func alternaAscolto(daMenu: Bool = false) {
        guard persistente, !bloccato, presentazione == nil else { return }
        if dettaturaAttiva {
            // Con la dettatura di macOS: il pulsante manda subito quello che è scritto
            mandaDettatura()
            return
        }
        if ascoltoRuby.ascolta {
            ascoltoRuby.ferma(invia: true)
            return
        }
        if daMenu, conversazioneAVoce {
            fermaVoce()
            return
        }
        if !aperta(.ruby) || appAttiva != .ruby { apri(.ruby) }
        ascolta()
    }

    /// Ruby si mette in ascolto (smettendo di parlare).
    func ascolta() {
        guard persistente, !rubyInCorso else { return }
        voceRuby.zitta()
        let ruby = dati.impostazioni.ruby
        let automatico = ruby.riconoscimento == .automatico
        if ruby.riconoscimento == .dettatura || (automatico && usaDettatura) {
            avviaDettatura()
            return
        }
        let scelta = automatico ? (ripiegoAscolto ?? SceltaRiconoscimento.catenaAutomatica.first ?? .classico) : ruby.riconoscimento
        ascoltoRuby.azzera()
        ascoltoRuby.concluso = { [weak self] frase in self?.fraseDetta(frase) }
        ascoltoRuby.problema = { [weak self] motivo in self?.problemaAscolto(motivo) }
        ascoltoRuby.avvia(scelta)
    }

    /// Ruby non ha potuto ascoltare o capire. In automatico prova il riconoscimento successivo
    /// (nuovo → dettatura di sistema → classica → dettatura di macOS); altrimenti lo scrive e lo dice.
    func problemaAscolto(_ motivo: String) {
        conversazioneAVoce = false
        rispostaAVoce = false
        let ruby = dati.impostazioni.ruby
        DiagnosticaVoce.annota("Problema d'ascolto: \(motivo)")
        let ripiegabile: Bool = {
            switch ascoltoRuby.fallimento {
            case .nonPartito, .nonPronto, .senzaParole, .errore: return true
            default: return false   // microfono muto o non acceso: un altro riconoscimento non aiuta
            }
        }()
        if persistente, ruby.riconoscimento == .automatico, ripiegabile, !usaDettatura {
            if ripieghiRimasti == nil { ripieghiRimasti = Array(SceltaRiconoscimento.catenaAutomatica.dropFirst()) }
            let perche = ascoltoRuby.fallimento == .nonPronto ? "Il riconoscimento non è stato pronto in tempo" : "Il riconoscimento non mi ha dato parole"
            if let prossimo = ripieghiRimasti?.first {
                ripieghiRimasti?.removeFirst()
                ripiegoAscolto = prossimo
                DiagnosticaVoce.annota("Automatico: riprovo con \(prossimo.rawValue)")
                avvisoVoce("\(perche) (\(motivo)). Riprovo con «\(prossimo.nome)»: parla pure quando mi vedi in ascolto.",
                           titolo: "Riprovo con \(prossimo.nome)", breve: "Riprovo con un altro riconoscimento. Parla pure.") { [weak self] in self?.ascolta() }
                return
            }
            usaDettatura = true
            DiagnosticaVoce.annota("Automatico: passo alla dettatura di macOS")
            avvisoVoce("\(perche), quindi uso la dettatura del Mac. Parla pure adesso: quando fai una pausa, mando io la frase.",
                       titolo: "Ti ascolto con la dettatura del Mac", breve: "Uso la dettatura del Mac. Parla pure.") { [weak self] in self?.avviaDettatura() }
            return
        }
        // Lo stesso avviso due volte di fila non serve
        guard conversazione(chiaveConversazione).last?.testo != motivo else { return }
        avvisoVoce(motivo, titolo: "Non riesco ad ascoltarti", breve: "Scusa, non sono riuscita a capirti. Ti ho scritto il motivo.", poi: nil)
    }

    /// Un avviso della voce, scritto e detto in breve; `poi` parte quando Ruby ha finito di dirlo (subito, se non parla).
    func avvisoVoce(_ testo: String, titolo: String, breve: String, poi: (() -> Void)?) {
        let ruby = dati.impostazioni.ruby
        aggiungiMessaggio(MessaggioRuby(autore: .ruby, testo: testo, titolo: titolo, motore: "Voce"), cliente: chiaveConversazione, parla: false)
        if persistente, ruby.risposteAVoce != .mai {
            voceRuby.finito = poi
            voceRuby.di(breve, voce: ruby.voce, velocita: ruby.velocitaVoce)
        } else {
            poi?()
        }
    }

    /// L'utente ha cambiato riconoscimento nelle impostazioni: si riparte da capo, senza i ripieghi della sessione.
    func azzeraRipieghiAscolto() {
        usaDettatura = false
        ripiegoAscolto = nil
        ripieghiRimasti = nil
        ascoltoRuby.azzera()
    }

    // MARK: - Dettatura di macOS

    /// Avvia la dettatura di macOS nel campo di Ruby (la vista mette il campo in primo piano e la accende).
    func avviaDettatura() {
        guard persistente, !rubyInCorso else { return }
        ascoltoRuby.azzera()   // via l'errore rosso del riconoscimento di Prisma
        if !aperta(.ruby) || appAttiva != .ruby { apri(.ruby) }
        lavoroDettatura?.cancel()
        dettaturaAttiva = true
        dettaturaHaScritto = false
        domandaRuby = ""
        richiestaDettatura += 1
        DiagnosticaVoce.annota("Dettatura di macOS: avvio (richiesta \(richiestaDettatura))")
        attendiParole()
    }

    /// Se in 15 secondi la dettatura non scrive niente, si chiude spiegando il perché.
    func attendiParole() {
        lavoroDettatura?.cancel()
        let attesa = DispatchWorkItem { [weak self] in
            guard let self, self.dettaturaAttiva, self.domandaRuby.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            DiagnosticaVoce.annota("Dettatura di macOS: nessuna parola in 15 s")
            self.chiudiDettatura()
            self.avvisoVoce("In 15 secondi la dettatura del Mac non ha scritto niente nel mio campo. Se accanto al cursore non è comparso il microfono di macOS, la dettatura non è partita: controlla Impostazioni di Sistema › Tastiera › Dettatura, oppure premi il tasto microfono (fn) con il cursore nel campo. Altrimenti premi di nuovo il microfono e parla.",
                           titolo: "Non ho sentito niente", breve: "Non ho sentito niente. Ti ho scritto cosa fare.", poi: nil)
        }
        lavoroDettatura = attesa
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: attesa)
    }

    /// Il campo cambia mentre detti: alla pausa la frase parte da sola; se torna vuoto, riparte l'attesa.
    func dettaturaCambiata() {
        lavoroDettatura?.cancel()
        guard !domandaRuby.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { attendiParole(); return }
        if !dettaturaHaScritto {
            dettaturaHaScritto = true
            DiagnosticaVoce.annota("Dettatura di macOS: prime parole nel campo")
        }
        let pausa = DispatchWorkItem { [weak self] in self?.mandaDettatura() }
        lavoroDettatura = pausa
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: pausa)
    }

    /// Manda come frase detta quello che la dettatura ha scritto.
    func mandaDettatura() {
        let frase = domandaRuby.trimmingCharacters(in: .whitespacesAndNewlines)
        DiagnosticaVoce.annota("Dettatura di macOS: mando \(frase.count) caratteri")
        chiudiDettatura()
        guard !frase.isEmpty else { return }
        fraseDetta(frase)
    }

    /// Spegne la dettatura: il campo perde il fuoco e macOS smette di scrivere (così non trascrive la voce di Ruby).
    func chiudiDettatura() {
        lavoroDettatura?.cancel()
        lavoroDettatura = nil
        guard dettaturaAttiva else { return }
        dettaturaAttiva = false
        DiagnosticaVoce.annota("Dettatura di macOS: chiusa")
        #if os(macOS)
        NSApp?.keyWindow?.makeFirstResponder(nil)
        #elseif os(iOS)
        _ = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    /// «Avvia dettatura» non ha trovato un campo di testo: si spegne subito e lo si dice.
    func dettaturaNonPartita() {
        guard dettaturaAttiva else { return }
        DiagnosticaVoce.annota("Dettatura di macOS: nessun campo di testo pronto")
        chiudiDettatura()
        usaDettatura = false
        avvisoVoce("La dettatura del Mac non è partita: il mio campo non ha preso il cursore. Clicca nel campo e premi il tasto microfono (fn) della tastiera, oppure scegli un altro riconoscimento in Impostazioni › Parlare con Ruby.",
                   titolo: "La dettatura del Mac non è partita", breve: "La dettatura del Mac non è partita. Ti ho scritto cosa fare.", poi: nil)
    }

    /// Ruby chiusa o ridotta: dettatura e ascolto non restano accesi nel vuoto.
    /// L'orecchio si tocca solo se è già nato (niente microfono creato per spegnerlo).
    func spegniVoceSeRubySparisce() {
        guard persistente else { return }
        if dettaturaAttiva { chiudiDettatura() }
        if let ascolto = ascoltoRubySeNato, ascolto.ascolta { ascolto.ferma(invia: false) }
    }

    // MARK: - Prove e diagnostica

    /// Prova il riconoscimento senza microfono, una scelta dopo l'altra: nuovo, dettatura di sistema, classica.
    func provaRiconoscimento() {
        guard persistente, esitoProvaRiconoscimento != "In prova…" else { return }
        esitoProvaRiconoscimento = "In prova…"
        provaUnoDopoLAltro([.nuovo, .dettaturaSistema, .classico], esiti: [])
    }

    private func provaUnoDopoLAltro(_ restanti: [SceltaRiconoscimento], esiti: [String]) {
        guard let scelta = restanti.first else {
            esitoProvaRiconoscimento = esiti.joined(separator: "\n")
            provaInCorso = nil
            return
        }
        let p = ProvaRiconoscimento()
        provaInCorso = p
        p.esegui(scelta) { [weak self] esito in
            self?.provaUnoDopoLAltro(Array(restanti.dropFirst()), esiti: esiti + [esito])
        }
    }

    /// Prova del microfono: tre secondi di ascolto senza riconoscimento.
    func provaMicrofono() {
        guard persistente, esitoProvaMicrofono != "In prova… parla per tre secondi" else { return }
        esitoProvaMicrofono = "In prova… parla per tre secondi"
        ascoltoRuby.provaMicrofono { [weak self] in self?.esitoProvaMicrofono = $0 }
    }

    /// Copia la diagnostica: ambiente, impostazioni, passaggi e prove (niente audio né frasi dette).
    func copiaDiagnosticaVoce() {
        var testo = DiagnosticaVoce.riepilogo(dati.impostazioni.ruby) + "\n\n" + DiagnosticaVoce.testo
        if let m = esitoProvaMicrofono { testo += "\n\nProva del microfono: " + m }
        if let r = esitoProvaRiconoscimento { testo += "\n\nProva del riconoscimento:\n" + r }
        Appunti.copia(testo)
        mostraAvviso("Diagnostica copiata: incollala nel messaggio")
    }

    // MARK: - Frasi e risposte

    /// Chiude la conversazione a voce: Ruby smette di ascoltare e di parlare.
    /// Tocca voce e orecchio solo se sono già nati, e lo stato solo se cambia: bloccare la scrivania
    /// non crea il microfono né ridisegna le app aperte.
    func fermaVoce() {
        if conversazioneAVoce { conversazioneAVoce = false }
        rispostaAVoce = false
        guard persistente else { return }
        if dettaturaAttiva { chiudiDettatura() }
        ascoltoRubySeNato?.ferma(invia: false)
        voceRubySeNata?.zitta()
    }

    /// Una frase detta a Ruby: diventa una domanda come quelle scritte, con la risposta anche a voce.
    func fraseDetta(_ frase: String) {
        let ruby = dati.impostazioni.ruby
        DiagnosticaVoce.annota("Frase detta: \(frase.count) caratteri")
        if CongedoRuby.e(frase) {
            conversazioneAVoce = false
            rispostaAVoce = false
            if persistente, ruby.risposteAVoce != .mai {
                voceRuby.finito = nil
                voceRuby.di("Va bene. Sono qui quando ti servo.", voce: ruby.voce, velocita: ruby.velocitaVoce)
            }
            return
        }
        rispostaAVoce = ruby.risposteAVoce != .mai
        conversazioneAVoce = ruby.conversazioneContinua && ruby.risposteAVoce != .mai
        let partita = rubyPortafoglio ? chiediRubyPortafoglio(frase) : chiediRuby(frase)
        // Se la domanda non è partita (Ruby era già al lavoro, nessun cliente), niente attesa a vuoto
        if !partita {
            rispostaAVoce = false
            conversazioneAVoce = false
        }
    }

    /// Dice a voce una risposta di Ruby, se la domanda è arrivata a voce o se le risposte a voce sono sempre attive.
    /// A conversazione aperta, finita la risposta Ruby torna ad ascoltare.
    func parlaRisposta(_ m: MessaggioRuby) {
        // La dettatura del Mac non deve trascrivere la voce di Ruby
        if dettaturaAttiva { chiudiDettatura() }
        let ruby = dati.impostazioni.ruby
        let aVoce = ruby.risposteAVoce == .sempre || (rispostaAVoce && ruby.risposteAVoce != .mai)
        rispostaAVoce = false
        guard persistente, aVoce else {
            conversazioneAVoce = false
            return
        }
        voceRuby.finito = { [weak self] in
            guard let self, self.conversazioneAVoce, !self.bloccato, self.presentazione == nil else { return }
            self.ascolta()
        }
        voceRuby.di(TestoParlato.da(titolo: m.titolo, testo: m.testo, completo: ruby.leggiTutto), voce: ruby.voce, velocita: ruby.velocitaVoce)
    }

    /// Fa ascoltare la voce scelta (dalle impostazioni).
    func provaVoce() {
        guard persistente else { return }
        if dettaturaAttiva { chiudiDettatura() }
        let ruby = dati.impostazioni.ruby
        voceRuby.finito = nil
        voceRuby.di("Ciao \(nomeUtente), sono Ruby. Dimmi pure: ti preparo quello che serve.", voce: ruby.voce, velocita: ruby.velocitaVoce)
    }
}
