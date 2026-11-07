import Foundation

// MARK: - La famiglia del dossier (Clienti › Famiglia, tema Apple §4.2.5)
// Le schede delle persone del nucleo, con le scoperture accese. Nessun calcolo nuovo: si leggono
// - la protezione persona per persona (`MotoreProtezioneFamiglia.perPersona`, dentro `EsitoProtezioneFamiglia`):
//   chi porta reddito e non è protetto, chi dipende da qualcuno che non è protetto;
// - il passaggio generazionale (`MotoreSuccessione`): beneficiari da indicare o da aggiornare, il convivente che senza
//   testamento non eredita, la successione da sistemare.
// Ogni scopertura dice dove si risolve: Analisi 360 › Protezione, Posizioni › Passaggio generazionale o la posizione.

/// Una scopertura (o una conferma) di una persona della famiglia, con la scheda in cui si risolve.
struct ScoperturaFamiglia: Identifiable, Equatable {
    enum Tono: Equatable {
        case rosso, arancio, verde
    }

    enum Destinazione: Equatable {
        /// Analisi 360 › Protezione.
        case protezione
        /// Posizioni › Passaggio generazionale del cliente.
        case successione
        /// La posizione (per i beneficiari).
        case posizione(String)
    }

    let testo: String
    let tono: Tono
    let destinazione: Destinazione
    /// Che cosa si apre (aiuto al passaggio del puntatore e VoiceOver).
    let aiuto: String
    var id: String { testo }
}

/// Una persona della famiglia: il titolare del dossier o un familiare.
struct PersonaFamiglia: Identifiable {
    let id: String
    let nome: String
    let iniziali: String
    let titolare: Bool
    /// «45 anni · titolare del dossier», «Coniuge · 43 anni».
    let descrizione: String
    /// nil per il titolare.
    let familiare: Familiare?
    let scoperture: [ScoperturaFamiglia]
}

enum MotoreFamigliaDossier {
    static let aiutoProtezione = "Apre Analisi 360 › Protezione"
    static let aiutoSuccessione = "Apre Posizioni › Passaggio generazionale"

    /// Il titolare e i familiari, nell'ordine del dossier, con le loro scoperture.
    static func persone(cliente c: Cliente, protezione: EsitoProtezioneFamiglia, successione: Successione?) -> [PersonaFamiglia] {
        let persone = protezione.persone
        var elenco: [PersonaFamiglia] = []

        // Il titolare
        var delTitolare: [ScoperturaFamiglia] = []
        if let p = persone.first(where: { $0.relazione == nil }), let s = statoProtezione(p) { delTitolare.append(s) }
        if let s = successione {
            if let senza = s.voci.first(where: { $0.destino == .beneficiari && $0.posizione.senzaBeneficiari }) {
                delTitolare.append(ScoperturaFamiglia(testo: "Beneficiari da indicare", tono: .arancio,
                                                      destinazione: .posizione(senza.posizione.id),
                                                      aiuto: "Apre \(senza.posizione.nome) in Posizioni"))
            } else if let altro = s.daSistemare.first(where: { !$0.posizione.senzaBeneficiari }) {
                delTitolare.append(ScoperturaFamiglia(testo: "Beneficiari da aggiornare", tono: .arancio,
                                                      destinazione: .posizione(altro.posizione.id),
                                                      aiuto: "Apre \(altro.posizione.nome) in Posizioni"))
            }
            if successioneDaSistemare(s) {
                delTitolare.append(ScoperturaFamiglia(testo: "Successione da sistemare", tono: .arancio,
                                                      destinazione: .successione, aiuto: aiutoSuccessione))
            }
        }
        let parti = [c.eta.map { "\($0) anni" }, "titolare del dossier"].compactMap { $0 }
        elenco.append(PersonaFamiglia(id: c.id, nome: primoNome(c.nome), iniziali: c.iniziali, titolare: true,
                                      descrizione: maiuscola(parti.joined(separator: " · ")), familiare: nil,
                                      scoperture: delTitolare))

        // I familiari
        let fuoriAsse = successione?.voci.filter { $0.destino == .beneficiari } ?? []
        let legittimi = Set(MotoreSuccessione.legittimi(c).map { $0.nome.lowercased() })
        for f in c.famiglia {
            var sue: [ScoperturaFamiglia] = []
            if let p = persone.first(where: { $0.id == f.id }) {
                // Porta reddito: la sua protezione
                if let s = statoProtezione(p) { sue.append(s) }
            } else if let s = statoDipendente(f, persone: persone) {
                // Dipende da chi porta reddito: è protetto se lo è chi lo mantiene
                sue.append(s)
            }
            // Beneficiari: il partner e i figli dovrebbero esserlo di almeno una polizza o di un fondo
            let vicini: Set<Familiare.Relazione> = [.coniuge, .convivente, .figlio, .figlia]
            if vicini.contains(f.relazione), !fuoriAsse.isEmpty {
                let nominate = fuoriAsse.filter { !$0.posizione.senzaBeneficiari }
                if !nominate.isEmpty, !nominate.contains(where: { beneficiario(f, testo: $0.posizione.beneficiari, legittimi: legittimi) }),
                   let prima = nominate.max(by: { $0.importo < $1.importo }) {
                    sue.append(ScoperturaFamiglia(testo: "Non è beneficiario", tono: .arancio,
                                                  destinazione: .posizione(prima.posizione.id),
                                                  aiuto: "Apre \(prima.posizione.nome) in Posizioni: beneficiari «\(prima.posizione.beneficiari)»"))
                }
            }
            // Il convivente senza testamento non eredita
            if let escluso = successione?.conviventeEscluso, escluso == f.nome {
                sue.append(ScoperturaFamiglia(testo: "Non eredita senza testamento", tono: .arancio,
                                              destinazione: .successione, aiuto: aiutoSuccessione))
            }
            let descrizione = [f.relazione.nome, f.eta.map { "\($0) anni" }].compactMap { $0 }.joined(separator: " · ")
            elenco.append(PersonaFamiglia(id: f.id, nome: f.nome, iniziali: Cliente.iniziali(di: f.nome), titolare: false,
                                          descrizione: descrizione, familiare: f, scoperture: sue))
        }
        return elenco
    }

    /// La protezione caso morte di chi porta reddito: nil se non c'è niente da proteggere.
    static func statoProtezione(_ p: FabbisognoPersona) -> ScoperturaFamiglia? {
        guard p.fabbisognoMorte > 0.5 else { return nil }
        if p.divarioMorte < 0.5 {
            return ScoperturaFamiglia(testo: "Protezione completa", tono: .verde, destinazione: .protezione, aiuto: aiutoProtezione)
        }
        if !p.proposte.isEmpty, p.divarioMorteConProposte < 0.5 {
            return ScoperturaFamiglia(testo: "Protezione in proposta", tono: .arancio, destinazione: .protezione, aiuto: aiutoProtezione)
        }
        if p.capitaleMorte < 0.5 {
            return ScoperturaFamiglia(testo: "Nessuna protezione", tono: .rosso, destinazione: .protezione, aiuto: aiutoProtezione)
        }
        return ScoperturaFamiglia(testo: "Mancano \(Formati.euroBreve(p.divarioMorte)) di protezione", tono: .rosso,
                                  destinazione: .protezione, aiuto: aiutoProtezione)
    }

    /// Chi non porta reddito ed è mantenuto: «Coperto…» se chi lo mantiene è protetto, altrimenti scoperto.
    static func statoDipendente(_ f: Familiare, persone: [FabbisognoPersona]) -> ScoperturaFamiglia? {
        let chiLoMantiene = persone.filter { p in p.dipendenti.contains { $0.id == f.id } }
        guard !chiLoMantiene.isEmpty else { return nil }
        if let scoperto = chiLoMantiene.first(where: { $0.fabbisognoMorte > 0.5 && $0.divarioMorte >= 0.5 }) {
            return ScoperturaFamiglia(testo: "Scoperto se manca \(primoNome(scoperto.nome))", tono: .rosso,
                                      destinazione: .protezione, aiuto: aiutoProtezione)
        }
        let testo = chiLoMantiene.count == 1 ? "Coperto se manca \(primoNome(chiLoMantiene[0].nome))" : "Coperto se manca chi porta reddito"
        return ScoperturaFamiglia(testo: testo, tono: .verde, destinazione: .protezione, aiuto: aiutoProtezione)
    }

    /// La successione ha qualcosa da sistemare: voci con un avviso, il convivente escluso, nessun erede.
    static func successioneDaSistemare(_ s: Successione) -> Bool {
        !s.daSistemare.isEmpty || s.conviventeEscluso != nil || (s.eredi.isEmpty && s.asseNetto > 0)
    }

    /// Il familiare è tra i beneficiari scritti: per nome, oppure con un'indicazione generica che lo comprende
    /// («eredi» per gli eredi legittimi, «figli» per i figli, «coniuge» per il coniuge).
    static func beneficiario(_ f: Familiare, testo: String, legittimi: Set<String>) -> Bool {
        let b = testo.lowercased()
        let nome = f.nome.lowercased().trimmingCharacters(in: .whitespaces)
        if !nome.isEmpty, b.contains(nome) { return true }
        let primo = primoNome(f.nome).lowercased()
        if primo.count >= 3, b.contains(primo) { return true }
        if b.contains("eredi"), legittimi.contains(f.nome.lowercased()) { return true }
        switch f.relazione {
        case .figlio, .figlia: return b.contains("figli")
        case .coniuge: return b.contains("coniuge")
        default: return false
        }
    }

    static func primoNome(_ nome: String) -> String {
        nome.split(separator: " ").first.map(String.init) ?? nome
    }

    private static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }
}
