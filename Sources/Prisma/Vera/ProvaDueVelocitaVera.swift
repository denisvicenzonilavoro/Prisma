import Foundation

/// Prova di «Due velocità» (Vera/BRIEF.md, fase 5, funzione 23) dentro `Prisma --prova-vera`: il modello Apple spento,
/// lo smistamento a tre corsie (sotto macOS 26 o con il modello spento tutto a Qwen, senza errori), il ripiego su Qwen
/// quando la risposta veloce non va (con un motore veloce finto e il server Ollama finto), la corsia dal motore scritto
/// sotto la risposta e la registrazione delle richieste nell'app. Niente rete, niente modello.
enum ProvaDueVelocitaVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        regole(controlla)
        ripiego(controlla)
        nellApp(controlla)
    }

    /// Un motore veloce finto: risponde quello che gli si dice, o lancia un errore.
    struct MotoreVeloceFinto: MotoreVeloce {
        var risposta: String?
        var nome: String { ModelloAppleVera.nome }
        func rispondi(istruzioni: String, domanda: String) async throws -> String {
            guard let risposta else { throw ErroreVera(messaggio: "Il modello veloce non ha risposto.") }
            return risposta
        }
    }

    private static let conversazione = SceltaVera(modalita: .conversazione, pensa: false)
    private static let lavoro = SceltaVera(modalita: .lavoro, pensa: false)

    // MARK: - Le corsie

    private static func regole(_ controlla: (Bool, String) -> Void) {
        controlla(ModelloAppleVera.ammesso == false, "Due velocità: il modello Apple è spento («Niente modello Apple», CLAUDE.md)")
        controlla(ModelloAppleVera.motore() == nil, "Due velocità: senza il sì dell'utente nessun motore Apple")
        let breve = "Come si dice grazie in inglese?"
        controlla(SmistamentoVera.corsiaModello(conversazione, domanda: breve, ammesso: false, disponibile: true) == .qwen,
                  "Due velocità: con il modello Apple spento la domanda va a Qwen")
        controlla(SmistamentoVera.corsiaModello(conversazione, domanda: breve, ammesso: true, disponibile: false) == .qwen,
                  "Due velocità: sotto macOS 26 (non disponibile) tutto a Qwen, senza errori")
        controlla(SmistamentoVera.corsiaModello(conversazione, domanda: breve, ammesso: true, disponibile: true) == .apple,
                  "Due velocità: acceso e disponibile, una domanda breve di conversazione va al veloce")
        controlla(SmistamentoVera.corsiaModello(lavoro, domanda: breve, ammesso: true, disponibile: true) == .qwen
                  && SmistamentoVera.corsiaModello(SceltaVera(modalita: .conversazione, pensa: true), domanda: breve, ammesso: true, disponibile: true) == .qwen,
                  "Due velocità: lavoro (la scheda del cliente) e ragionamento vanno sempre a Qwen")
        let lunga = Array(repeating: "parola", count: 30).joined(separator: " ")
        controlla(!SmistamentoVera.adattaAlVeloce(conversazione, domanda: lunga), "Due velocità: una domanda lunga va a Qwen")
        controlla(SmistamentoVera.valida("Thank you.", domanda: breve) && !SmistamentoVera.valida("   ", domanda: breve)
                  && !SmistamentoVera.valida(String(repeating: "a", count: 700), domanda: breve)
                  && !SmistamentoVera.valida("Costa 1.250 €.", domanda: breve),
                  "Due velocità: una risposta veloce vuota, troppo lunga o con cifre inventate non è valida")
        controlla(CorsiaVera.da(motore: StatoShell.motoreAzioni) == .regole && CorsiaVera.da(motore: "Prisma") == .regole
                  && CorsiaVera.da(motore: MotoriVera.sintesi.nome) == .regole && CorsiaVera.da(motore: "Qwen sul Mac") == .qwen
                  && CorsiaVera.da(motore: "Vera su misura sul Mac") == .qwen && CorsiaVera.da(motore: CervelloGrandeVera.nome) == .esterno,
                  "Due velocità: la corsia si legge dal motore sotto la risposta")
        controlla(!ModelloAppleVera.descrizioneDisponibilita.isEmpty, "Due velocità: la disponibilità del modello Apple è descritta (\(ModelloAppleVera.descrizioneDisponibilita))")
    }

    // MARK: - Il ripiego su Qwen

    private static func ripiego(_ controlla: (Bool, String) -> Void) {
        let qwenRisponde = "Si dice «thank you»."
        let sessione = ProvaSuMisuraVera.sessioneFinta()
        let qwen = MotoreLocale(ImpostazioniVera(), disponibilita: .pronto, sessione: sessione)
        let domanda = "Come si dice grazie in inglese?"
        let piano = PianoVera(scelta: conversazione, messaggi: [MessaggioModello(ruolo: .sistema, testo: IstruzioniVera.conversazione),
                                                              MessaggioModello(ruolo: .utente, testo: domanda)], opzioni: OpzioniModello())
        let casi: [(String, String?)] = [("vuota", ""), ("troppo lunga", String(repeating: "bla ", count: 200)),
                                         ("con una cifra inventata", "Costa 12 €."), ("con un errore", nil)]
        for (nome, risposta) in casi {
            ServerFintoSuMisura.prepara(installati: [MotoreLocale.modelloPredefinito], risposte: [MotoreLocale.modelloPredefinito: [qwenRisponde]])
            let r = ProvaSuMisuraVera.aspetta { () async -> (String, CorsiaVera)? in
                guard let x = try? await SmistamentoVera.rispondi(piano, domanda: domanda, veloce: MotoreVeloceFinto(risposta: risposta), qwen: qwen) else { return nil }
                return (x.testo, x.corsia)
            }
            controlla(r?.0 == qwenRisponde && r?.1 == .qwen, "Due velocità: risposta veloce \(nome) → risponde Qwen")
        }
        ServerFintoSuMisura.prepara(installati: [MotoreLocale.modelloPredefinito], risposte: [MotoreLocale.modelloPredefinito: [qwenRisponde]])
        let buona = ProvaSuMisuraVera.aspetta { () async -> (String, CorsiaVera)? in
            guard let x = try? await SmistamentoVera.rispondi(piano, domanda: domanda, veloce: MotoreVeloceFinto(risposta: "Thank you."), qwen: qwen) else { return nil }
            return (x.testo, x.corsia)
        }
        controlla(buona?.0 == "Thank you." && buona?.1 == .apple && ServerFintoSuMisura.registro.isEmpty,
                  "Due velocità: una risposta veloce valida resta, Qwen non viene chiamato")
        let senza = ProvaSuMisuraVera.aspetta { () async -> CorsiaVera? in
            try? await SmistamentoVera.rispondi(piano, domanda: domanda, veloce: nil, qwen: qwen).corsia
        }
        controlla(senza == .qwen, "Due velocità: senza motore veloce (macOS 14-25, iOS) risponde Qwen")
    }

    // MARK: - Nell'app

    private static func nellApp(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        _ = s.chiediVera("Apri l'agenda")
        let regole = s.dueVelocita.richieste(.regole)
        controlla(regole.contains { $0.testo == "Apri l'agenda" && $0.secondi >= 0 }, "Due velocità nell'app: «Apri l'agenda» va nella corsia delle regole, con il tempo")
        let prima = s.dueVelocita.voci.count
        s.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "Buongiorno: tre cose per oggi.", titolo: "Routine", motore: MotoriVera.sintesi.nome),
                            cliente: s.chiaveConversazione, parla: false)
        controlla(s.dueVelocita.voci.count == prima, "Due velocità nell'app: un messaggio di Vera senza domanda non registra niente")
        // La domanda libera, con le risposte preparate: nessun errore, il percorso passa dallo smistamento
        let conversazioneSenzaErrori = s.chiediVera("Come si dice grazie in inglese?")
        let ultima = s.conversazione(s.chiaveConversazione).last
        controlla(conversazioneSenzaErrori && ultima?.autore == .vera && ultima?.titolo != "Vera non ha potuto rispondere",
                  "Due velocità nell'app: con il modello Apple spento la domanda segue il percorso di sempre, senza errori")
        let ieri = Date().addingTimeInterval(-86_400 * 1.5)
        let d = StatoDueVelocita()
        d.registra("Chi devo chiamare?", corsia: .regole, secondi: 0.3, quando: ieri)
        d.registra("Che documento è questo?", corsia: .qwen, secondi: 4, quando: Date())
        d.registra("Confronta i due KID", corsia: .qwen, secondi: 6, quando: Date())
        controlla(d.richieste(.regole).isEmpty && d.richieste(.qwen).count == 2 && d.media(.qwen) == 5 && d.media(.regole) == nil,
                  "Due velocità: contano solo le richieste di oggi, con la media dei secondi")
        for i in 0..<50 { d.registra("Domanda \(i)", corsia: .qwen, secondi: 1) }
        controlla(d.voci.count == StatoDueVelocita.massimo, "Due velocità: al massimo \(StatoDueVelocita.massimo) richieste in memoria")
        s.modoCliente = "giulia"
        s.apriPaginaMotori()
        controlla(!s.paginaMotoriAperta, "Due velocità: in modalità cliente la pagina dei motori non si apre")
        s.modoCliente = nil
        let gestita = s.chiediVera("Come smisti le domande?")
        #if os(macOS)
        controlla(gestita && s.paginaMotoriAperta && s.schedaMotori == .dueVelocita, "Due velocità: «come smisti le domande?» apre la pagina dei motori")
        #else
        controlla(gestita, "Due velocità: «come smisti le domande?» risponde")
        #endif
    }
}
