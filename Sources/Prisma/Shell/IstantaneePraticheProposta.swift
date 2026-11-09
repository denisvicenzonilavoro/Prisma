#if os(macOS)
import Foundation

/// Le istantanee di Pratiche › Proposta (Design/template-luce-specifica.md §7.0.7 e §7.1.7, «Luce» giro 3), tutte
/// nello stato finale (`\.modoIstantanea`: numeri completi, anelli pieni, linee tracciate, nessuna sequenza avviata):
/// - 800: l'archivio senza clienti, la scheda Proposta con lo stato vuoto comune, chiaro e scuro;
/// - 801: la scheda appena aperta sui clienti di prova, cinque passi spenti tratteggiati, chiaro e scuro;
/// - 802: una proposta costruita fino in fondo, cinque riquadri e «Proposta pronta», chiaro e scuro (con i due fac-simile
///   dei moduli caricati in memoria: per un prodotto indipendente la tappa 5 li elenca con le caselle compilate);
/// - 803: la protezione caso morte ferma sulla scelta fra due prodotti, uno per canale;
/// - 804: catalogo senza coperture caso morte, passo 1 arancio con «Rimedia»;
/// - 805: adeguatezza rossa, niente moduli né riquadro finale;
/// - 806: la sostituzione «costi più bassi» costruita, con il prospetto di sostituzione e i costi da … a …, chiaro e scuro;
/// - 807: nessun bisogno scoperto;
/// - 809: «Proponi una key man ›» dal dossier di Marco: il bisogno della persona chiave di Bianchi Serramenti (azienda di
///   prova) con il capitale che manca, costruito, chiaro e scuro.
/// La 806 usa il bisogno di sostituzione dei motori dei costi se i dati di prova ne hanno uno; altrimenti la prima
/// posizione in essere di investimento o risparmio con un prodotto del catalogo di prova della stessa area, come se la
/// sostituzione arrivasse dallo Smontaggio (dichiarato: è la strada di «Crea la proposta di sostituzione»).
/// DATI DI PROVA DICHIARATI: i clienti, le analisi e il catalogo sono quelli di prova (`DatiDemo`, con la copertura caso
/// morte indipendente segnata «dati di prova»); le cifre le calcolano i motori. Per la 805 il profilo di prova di un
/// cliente viene scartato nel solo stato dell'istantanea (che non si salva), per la 807 si aprono proposte presentate.
extension Istantanee {
    nonisolated static var scenePraticheProposta: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("800-pratiche-vuota") { s in
            s.dati.clienti = []
            s.dati.posizioni = []
            s.apriPratiche(.proposta)
        }
        coppia("801-pratiche-proposta") { s in
            s.apriPratiche(.proposta)
        }
        coppia("802-pratiche-proposta-pronta") { s in
            // I due fac-simile di Prisma (dati di prova, in memoria): la tappa 5 elenca i moduli del canale indipendente
            s.caricaEsempiModuli()
            s.apriPratiche(.proposta)
            costruisciFinoInFondo(s)
        }
        una("803-pratiche-proposta-scegli-prodotto") { s in
            s.apriPratiche(.proposta)
            guard let b = s.bisogniProposta().first(where: { b in
                b.origine == "protezione-vita" && Set(s.cliente(b.clienteId)?.canali ?? []).count == 2
            }) ?? s.bisogniProposta().first(where: { $0.origine == "protezione-vita" }) else { return }
            s.scegliBisognoProposta(b.id)
            s.costruisciProposta(b, animato: false)
        }
        una("804-pratiche-proposta-bloccata") { s in
            s.dati.prodotti.removeAll { $0.area == .protezione && MotoreProposta.rischioNominato($0) == .vita }
            s.apriPratiche(.proposta)
            guard let b = s.bisogniProposta().first(where: { $0.origine == "protezione-vita" }) else { return }
            s.scegliBisognoProposta(b.id)
            s.costruisciProposta(b, animato: false)
        }
        una("805-pratiche-proposta-non-adeguata") { s in
            s.apriPratiche(.proposta)
            costruisciNonAdeguata(s)
        }
        coppia("806-pratiche-proposta-sostituzione") { s in
            s.apriPratiche(.proposta)
            costruisciSostituzione(s)
        }
        coppia("809-pratiche-proposta-azienda") { s in
            s.proponiDaAzienda(clienteId: "marco", aziendaId: AziendeDiProva.idBianchi, area: .personaChiave)
            guard let b = s.bisogniProposta().first(where: { $0.areaAzienda == .personaChiave }) else { return }
            if case .daScegliere(let prodotti)? = s.propostaCostruita(b)?.prodotto, let primo = prodotti.first {
                s.praticheProposta.sceltaProdotto[b.id] = primo.id
            }
            s.costruisciProposta(b, animato: false)
        }
        una("807-pratiche-proposta-vuota") { s in
            s.dati.obiettivi = []
            // Senza catalogo nessuna sostituzione «costi più bassi»: il vuoto è quello dei bisogni delle analisi
            s.dati.prodotti = []
            for c in s.dati.clienti {
                for (area, rischio) in [(AreaPosizione.protezione, RischioCoperto.vita), (.protezione, .invalidita),
                                        (.liquidita, nil), (.previdenza, nil), (.investimento, nil)] {
                    var p = Posizione(clienteId: c.id, canale: c.canali.first ?? .alleanza, stato: .proposta, area: area,
                                      nome: "Proposta di prova presentata")
                    p.rischio = rischio
                    p.esito = .presentata
                    s.dati.posizioni.append(p)
                }
            }
            s.apriPratiche(.proposta)
        }
        return scene
    }

    /// Il primo bisogno (dei clienti di prova) la cui proposta arriva fino a «Proposta pronta», con il primo prodotto
    /// adatto se ce n'è più d'uno; costruito senza sequenza (la bozza si salva nello stato dell'istantanea).
    nonisolated static func costruisciFinoInFondo(_ s: StatoShell) {
        for b in s.bisogniProposta() {
            guard var r = s.propostaCostruita(b) else { continue }
            if case .daScegliere(let prodotti) = r.prodotto, let primo = prodotti.first {
                s.praticheProposta.sceltaProdotto[b.id] = primo.id
                guard let conScelta = s.propostaCostruita(b) else { continue }
                r = conScelta
            }
            guard r.pronta else {
                s.praticheProposta.sceltaProdotto[b.id] = nil
                continue
            }
            s.scegliBisognoProposta(b.id)
            s.costruisciProposta(b, animato: false)
            return
        }
    }

    /// La sostituzione «costi più bassi» dei dati di prova (vedi sopra), costruita senza sequenza.
    nonisolated static func costruisciSostituzione(_ s: StatoShell) {
        if let b = s.bisogniProposta().first(where: \.sostituzione) {
            s.scegliBisognoProposta(b.id)
            s.costruisciProposta(b, animato: false)
            return
        }
        for c in s.dati.clienti {
            for p in s.posizioniCliente(c.id) where p.stato == .inEssere && (p.area == .investimento || p.area == .risparmio) && p.valore > 0 {
                guard let prodotto = s.dati.prodotti.first(where: { x in
                    x.area == p.area && x.id != p.prodottoId && x.nome != p.nome && (c.canali.isEmpty || c.canali.contains(x.canale))
                }) else { continue }
                let da = p.costoComplessivo.map { CifreDoc.percento($0) } ?? "non indicati"
                let a = (prodotto.incidenzaCostiKID ?? prodotto.costoAnnuo).map { CifreDoc.percento($0) } ?? "non indicati"
                let b = MotoreProposta.bisognoSostituzione(attuale: p, cliente: c,
                                                           motivo: "Costi oggi \(da) l'anno, con «\(prodotto.nome)» \(a).",
                                                           prodotto: prodotto.id)
                s.richiediBisognoProposta(b)
                s.costruisciProposta(b, animato: false)
                return
            }
        }
    }

    /// Una proposta che il motore dell'adeguatezza giudica rossa: il consulente ha scartato, nel profilo, il bisogno a
    /// cui risponde (solo nello stato dell'istantanea). Il bisogno resta in elenco perché la bozza è già costruita.
    nonisolated static func costruisciNonAdeguata(_ s: StatoShell) {
        for b in s.bisogniProposta() {
            guard let rilevato = b.bisognoRilevatoId,
                  let i = s.dati.clienti.firstIndex(where: { $0.id == b.clienteId }) else { continue }
            var r = s.propostaCostruita(b)
            if case .daScegliere(let prodotti)? = r?.prodotto, let primo = prodotti.first {
                s.praticheProposta.sceltaProdotto[b.id] = primo.id
                r = s.propostaCostruita(b)
            }
            guard r?.bozza != nil else { continue }
            s.scegliBisognoProposta(b.id)
            s.costruisciProposta(b, animato: false)
            s.dati.clienti[i].bisogni.esiti[rilevato] = false
            s.praticheProposta.azzera()
            return
        }
    }
}
#endif
