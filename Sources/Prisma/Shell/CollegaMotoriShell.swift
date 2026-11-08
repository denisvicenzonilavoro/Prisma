import Foundation

// «I motori di Vera» nell'app (Vera/BRIEF.md, fase 5, funzioni 23 «Due velocità» e 25 «Il cervello grande»): la pagina
// sopra la chat con le due schede (le corsie dello smistamento con le richieste di oggi; i motori con le regole bloccate),
// la registrazione dei tempi di ogni richiesta, la corsia veloce del modello Apple (spento: con `ammesso = false` la
// condizione è sempre falsa e la domanda va a Qwen come prima) e le frasi in chat. Mai in modalità cliente: le righe
// delle corsie contengono le domande su altri clienti.

/// La scheda aperta della pagina dei motori.
enum SchedaMotoriVera: String, CaseIterable, Identifiable {
    case dueVelocita
    case cervello

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .dueVelocita: return "Due velocità"
        case .cervello: return "Il cervello grande"
        }
    }
}

extension StatoShell {
    static let titoloMotori = "I motori di Vera"
    /// Oltre questo tempo la risposta non è più quella della domanda (il ragionamento può durare fino a 3 minuti).
    static let attesaMassimaRichiesta: TimeInterval = 600

    // MARK: - La pagina

    func apriPaginaMotori(_ scheda: SchedaMotoriVera = .dueVelocita) {
        guard !inModoCliente else {
            return mostraAvviso("I motori di Vera mostrano le domande su tutti i clienti: fuori dalla modalità cliente.")
        }
        paginaTagliandoAperta = false
        paginaSuMisuraAperta = false
        schedaMotori = scheda
        if !aperta(.vera) { apri(.vera) }
        paginaMotoriAperta = true
    }

    func chiudiPaginaMotori() {
        paginaMotoriAperta = false
    }

    // MARK: - I tempi di ogni richiesta

    /// Una domanda a Vera comincia: il tempo parte da qui (chiediVera, chiediVeraPortafoglio).
    func iniziaRichiestaVera(_ testo: String) {
        inizioRichiestaVera = (testo, Date())
    }

    /// La prima risposta di Vera dopo una domanda: la corsia (dal motore scritto sotto la risposta) e i secondi. Gli avvisi
    /// («Qwen non è pronto», «non ha potuto rispondere», l'esame in corso) non sono risposte: non contano.
    func registraRichiestaVera(_ m: MessaggioVera) {
        guard m.autore == .vera, let inizio = inizioRichiestaVera else { return }
        inizioRichiestaVera = nil
        // Una domanda rimasta senza risposta (conversazione nuova, risposta fermata) non si attacca a un messaggio di dopo
        guard Date().timeIntervalSince(inizio.quando) < Self.attesaMassimaRichiesta else { return }
        let avviso = m.titolo == "Qwen non è pronto" || m.titolo == "Vera non ha potuto rispondere"
            || (m.motore == "Prisma" && m.titolo == Self.titoloSuMisura)
        guard !avviso else { return }
        dueVelocita.registra(inizio.testo, corsia: CorsiaVera.da(motore: m.motore), secondi: Date().timeIntervalSince(inizio.quando))
    }

    // MARK: - La corsia veloce (modello Apple, spento)

    /// La risposta della corsia veloce, con Qwen come ripiego (SmistamentoVera.rispondi). Si arriva qui solo se il modello
    /// Apple è ammesso e disponibile: oggi mai.
    func rispostaVeloce(_ piano: PianoVera, domanda: String, cliente id: String, veloce: MotoreVeloce) {
        let qwen = self.qwen
        veraInCorso = true
        compitoVera = Task { @MainActor in
            do {
                let r = try await SmistamentoVera.rispondi(piano, domanda: domanda, veloce: veloce, qwen: qwen)
                var m = MessaggioVera(autore: .vera, testo: r.testo, motore: r.corsia == .apple ? veloce.nome : qwen.nome)
                m.modalita = piano.scelta.modalita
                self.aggiungiMessaggio(m, cliente: id)
            } catch is CancellationError {
            } catch {
                self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: error.localizedDescription,
                                                    titolo: "Vera non ha potuto rispondere", motore: qwen.nome), cliente: id)
            }
            self.veraInCorso = false
            self.compitoVera = nil
        }
    }

    // MARK: - Le frasi in chat

    static let frasiDueVelocita = #"\bcome smisti\b|\bdue velocita\b|^(?:apri |mostra(?:mi)? )?i (?:tuoi )?motori(?: di vera)?$|\bquali motori (?:usi|hai)\b"#
    static let frasiCervello = #"\bmotore esterno\b|\bcervello grande\b"#

    /// «Come smisti le domande?», «due velocità», «motore esterno», «cervello grande»: apre la pagina dei motori (sul Mac)
    /// e risponde in una riga. Nessuna azione.
    func chiediMotori(_ testo: String, chiave: String) -> Bool {
        let t = NucleoVera.semplice(InterpreteComandi.pulisci(testo))
        let cervello = DateItaliane.cerca(Self.frasiCervello, t) != nil
        guard cervello || DateItaliane.cerca(Self.frasiDueVelocita, t) != nil else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        let risposta: String
        if inModoCliente {
            risposta = "In modalità cliente la pagina dei motori non si apre."
        } else {
            #if os(macOS)
            apriPaginaMotori(cervello ? .cervello : .dueVelocita)
            #endif
            risposta = cervello
                ? "Il motore esterno non è collegato: oggi Vera lavora tutta sul Mac. Quando lo collegherai riceverà solo le domande generali, mai i dati dei clienti."
                : "Prima le regole di Prisma (comandi, agenda, routine, tagliando: senza modello), poi Qwen sul Mac. Il modello Apple è spento."
        }
        aggiungiMessaggio(MessaggioVera(autore: .vera, testo: risposta, titolo: Self.titoloMotori, motore: MotoriVera.sintesi.nome), cliente: chiave)
        return true
    }
}
