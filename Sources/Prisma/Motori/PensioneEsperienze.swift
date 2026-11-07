import Foundation

// Il calcolo comune della pensione per le esperienze della Sala (Design/template-luce-specifica.md §1.4.1 punto 4.8,
// §1.4.5, decisioni 75, 76 e 77): la lettera dal futuro, il film del piano, una giornata della pensione e Lancia l'anno
// chiedono qui le stesse cifre, così raccontano tutte la stessa pensione. Il template usa un 3% fisso (`fattore`,
// `pensCon`, `versPens`): qui no. Le cifre vengono da `MotorePrevidenza` con le ipotesi del cliente, e solo se l'area
// Previdenza è confermata con lui in Analisi 360 (`Analisi360.confermate`): le ipotesi hanno valori predefiniti (1.400 /
// 2.200 / 67 anni / 1,5%) che nessuno ha dato, e Prisma non racconta cifre inventate.

/// Le cifre della pensione di un cliente per le esperienze (importi mensili netti in euro di oggi).
struct CifrePensioneEsperienze: Equatable {
    let etaPensione: Int
    let anniAllaPensione: Int
    /// Il reddito che il cliente vorrebbe in pensione.
    let redditoDesiderato: Double
    /// La pensione pubblica stimata.
    let pensionePubblica: Double
    /// Pubblica più la rendita delle posizioni previdenziali in essere («senza il piano»).
    let senzaPiano: Double
    /// Con le proposte vere in Posizioni (`renditaProposte`); nil se non ci sono proposte previdenziali.
    let conPiano: Double?
    /// Il divario fra desiderato e pubblica, e quello che resta con le posizioni in essere e con le proposte.
    let divario: Double
    let divarioSenzaPiano: Double
    let divarioConPiano: Double?
    /// Quanto servirebbe versare in più al mese per chiudere il divario (nil se non serve o non si sa): un'ipotesi,
    /// da mostrare sempre come tale (decisione 77).
    let versamentoPerDivario: Double?
}

enum PensioneEsperienze {
    /// Il risultato per un cliente: le cifre, oppure perché non ci sono.
    enum Esito: Equatable {
        case pronto(CifrePensioneEsperienze)
        /// L'area Previdenza non è confermata con il cliente: «ipotesi da confermare in Analisi 360 › Previdenza».
        case ipotesiDaConfermare
        /// Manca la pensione stimata o quella desiderata.
        case datiMancanti
    }

    /// La frase dello stato senza cifre, con il nome di battesimo del cliente.
    static func frase(_ e: Esito, nome: String) -> String? {
        switch e {
        case .pronto: return nil
        case .ipotesiDaConfermare:
            return "Le ipotesi sulla pensione di \(nome) sono da confermare in Analisi 360 › Previdenza."
        case .datiMancanti:
            return "Per questa esperienza servono la pensione stimata e quella desiderata di \(nome)."
        }
    }

    /// Le cifre del cliente dalle sue posizioni (tutte, in essere e in proposta) e dalla sua analisi.
    static func calcola(cliente: Cliente, posizioni: [Posizione], analisi: Analisi360?, data: Date = Date()) -> Esito {
        guard let analisi, analisi.confermate.contains(.previdenza) else { return .ipotesiDaConfermare }
        let ipotesi = analisi.previdenza
        guard ipotesi.pensionePubblica > 0, ipotesi.redditoDesiderato > 0 else { return .datiMancanti }
        let delCliente = posizioni.filter { $0.clienteId == cliente.id }
        let e = MotorePrevidenza.calcola(delCliente, cliente: cliente, analisi: ipotesi, data: data)
        let senza = e.pensionePubblica + e.renditaInEssere
        let conProposte = e.proposte.isEmpty ? nil : senza + e.renditaProposte
        let mancante = e.versamentoMancante.flatMap { $0 > 0 ? $0 : nil }
        return .pronto(CifrePensioneEsperienze(
            etaPensione: e.etaPensione,
            anniAllaPensione: e.anniAccumulo,
            redditoDesiderato: e.redditoDesiderato,
            pensionePubblica: e.pensionePubblica,
            senzaPiano: senza,
            conPiano: conProposte,
            divario: e.divario,
            divarioSenzaPiano: e.divarioResiduo,
            divarioConPiano: e.proposte.isEmpty ? nil : e.divarioConProposte,
            versamentoPerDivario: mancante))
    }
}

/// Prove dell'adattatore (chiamate da `ProvaCalcoli.esegui()`, cioè da `Prisma --prova-calcoli`): casi costruiti a mano.
enum ProvaCalcoliPensioneEsperienze {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 11, 3)
        let cliente = Cliente(id: "prova", nome: "Prova Pensione", iniziali: "PP", tinta: .blu, tema: "", email: "",
                              telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2020, 1, 1))
        var analisi = Analisi360(cliente: cliente, posizioni: [])
        analisi.previdenza.pensionePubblica = 1_400
        analisi.previdenza.redditoDesiderato = 2_200

        // Senza conferma dell'area: nessuna cifra (mai i valori predefiniti)
        verifica.vero("Pensione per le esperienze: senza conferma della Previdenza nessuna cifra",
                      PensioneEsperienze.calcola(cliente: cliente, posizioni: [], analisi: analisi, data: oggi) == .ipotesiDaConfermare)
        verifica.vero("Pensione per le esperienze: senza analisi nessuna cifra",
                      PensioneEsperienze.calcola(cliente: cliente, posizioni: [], analisi: nil, data: oggi) == .ipotesiDaConfermare)

        // Confermata, senza posizioni previdenziali: senza piano = la pubblica, nessun «con il piano»
        analisi.confermate = [.previdenza]
        if case .pronto(let c) = PensioneEsperienze.calcola(cliente: cliente, posizioni: [], analisi: analisi, data: oggi) {
            verifica("Pensione per le esperienze: senza posizioni, senza piano = pubblica", c.senzaPiano, 1_400)
            verifica("Pensione per le esperienze: divario 2.200 − 1.400", c.divario, 800)
            verifica.vero("Pensione per le esperienze: senza proposte nessuna cifra «con il piano»", c.conPiano == nil && c.divarioConPiano == nil)
            // Le stesse cifre del motore della previdenza
            let e = MotorePrevidenza.calcola([], cliente: cliente, analisi: analisi.previdenza, data: oggi)
            verifica("Pensione per le esperienze: stesso divario di MotorePrevidenza", c.divarioSenzaPiano, e.divarioResiduo)
        } else {
            verifica.vero("Pensione per le esperienze: con la Previdenza confermata le cifre ci sono", false)
        }

        // Pensione stimata a zero: dati mancanti
        analisi.previdenza.pensionePubblica = 0
        verifica.vero("Pensione per le esperienze: senza pensione stimata, dati mancanti",
                      PensioneEsperienze.calcola(cliente: cliente, posizioni: [], analisi: analisi, data: oggi) == .datiMancanti)
    }
}
