import Foundation

/// Prove del radar del portafoglio (Design/template-luce-specifica.md §8.3.5, punto 6): la distanza di Laura del
/// template (50/33/12/5 contro 40/40/12/8) è 9,5; un cliente uguale al modello è a 0; le classi a zero contano giuste;
/// gli spostamenti sommano a `daSpostare` (un canale) e restano dentro i canali; nessun cliente senza modello va sul
/// radar; la previdenza non entra; la composizione stimata è segnata; la tolleranza non si inventa; le bozze sono
/// proposte e il radar le riconosce. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliRadar {
    static func esegui(_ verifica: VerificaCalcoli) {
        distanze(verifica)
        voci(verifica)
        radar(verifica)
        bozze(verifica)
        testi(verifica)
    }

    private typealias P = PortafogliModelloDiProva

    private static func distanze(_ verifica: VerificaCalcoli) {
        // Le quote del template (1954-1959): azioni +d, obbligazioni −0,7·d, liquidità −0,3·d con d = 9,5 (la
        // specifica le arrotonda a 50/33/12/5, che darebbero 10)
        let laura = PesiModello(azionario: 49.5, obbligazionario: 33.35, gestioneSeparata: 12, liquidita: 5.15)
        verifica("Radar: distanza di Laura dal modello Equilibrato", MotoreRadar.distanza(quote: laura, pesi: P.equilibrato.pesi), 9.5)
        verifica("Radar: uguale al modello, distanza 0", MotoreRadar.distanza(quote: P.equilibrato.pesi, pesi: P.equilibrato.pesi), 0)
        // Dinamico non ha gestione separata: 30 punti di gestione separata contano tutti
        let conGestione = PesiModello(azionario: 50, obbligazionario: 15, gestioneSeparata: 30, liquidita: 5)
        verifica("Radar: classe a zero nel modello contata giusta", MotoreRadar.distanza(quote: conGestione, pesi: P.dinamico.pesi), 30)
        verifica.vero("Radar: pesi dei modelli di prova a 100", P.tutti.allSatisfy { $0.pesi.completi })
        verifica.vero("Radar: pesi che non fanno 100 segnalati", !PesiModello(azionario: 50, obbligazionario: 45).completi)
    }

    /// Un cliente con un fondo (60% azioni dichiarate) e un conto, tutto indipendente.
    private static func clienteDiProva(modello: String? = P.equilibrato.id) -> (Cliente, [Posizione]) {
        var c = Cliente.nuovo(tinta: .blu)
        c.nome = "Cliente di prova"
        c.modelloId = modello
        let fondo = AiutiProva.posizione("Fondo", .investimento, 80_000) {
            $0.clienteId = c.id
            $0.quotaAzionaria = 60
            $0.quotaTitoliStato = 0
            $0.totaleVersato = 70_000
        }
        let conto = AiutiProva.posizione("Conto", .liquidita, 20_000) { $0.clienteId = c.id }
        return (c, [fondo, conto])
    }

    private static func voci(_ verifica: VerificaCalcoli) {
        let (c, pos) = clienteDiProva()
        guard let v = MotoreRadar.voce(cliente: c, modello: P.equilibrato, posizioni: pos, tolleranzaGenerale: 5) else {
            verifica.vero("Radar: voce del cliente di prova", false)
            return
        }
        // Oggi: azioni 48, obbligazioni 32, gestione separata 0, liquidità 20 → |8|+|8|+|12|+|12| = 40 / 2 = 20
        verifica("Radar: quota azionaria di oggi", v.quote.azionario, 48, tolleranza: 1e-6)
        verifica("Radar: distanza del cliente di prova", v.distanza, 20, tolleranza: 1e-6)
        verifica.vero("Radar: oltre 5 punti è fuori tolleranza", v.fuori)
        verifica("Radar: da spostare = distanza × patrimonio", v.daSpostare, 20_000, tolleranza: 0.01)
        verifica("Radar: gli spostamenti di un canale sommano a da spostare", v.spostato, v.daSpostare, tolleranza: 0.05)
        verifica.vero("Radar: spostamenti solo dentro il canale indipendente", v.spostamenti.allSatisfy { $0.canale == .indipendente })
        verifica.vero("Radar: si sposta dalle classi in eccesso a quelle in difetto",
                      v.spostamenti.allSatisfy { [.azionario, .liquidita].contains($0.da) && [.obbligazionario, .gestioneSeparata].contains($0.a) })
        // Imposta sulla parte venduta del fondo: 8.000 € di azioni vendute, cioè 8.000 / 80.000 = 1/10 del fondo;
        // plusvalenza 10.000 × 1/10 al 26% = 260 € (dal conto si sposta liquidità: nessuna tassa)
        verifica("Radar: tasse sulla plusvalenza quota per quota", v.costo.imposte, 260, tolleranza: 0.05)
        verifica.vero("Radar: con il versato le tasse si calcolano", v.costo.senzaVersato.isEmpty)
        let stima = MotoreRadar.voce(cliente: c, modello: P.equilibrato,
                                     posizioni: pos.map { var p = $0; p.quotaAzionaria = nil; p.sri = 4; return p },
                                     tolleranzaGenerale: 5)
        verifica.vero("Radar: composizione stimata dall'SRI segnata", stima?.stimata == true)
        verifica.vero("Radar: senza versato le tasse restano da calcolare",
                      MotoreRadar.voce(cliente: c, modello: P.equilibrato,
                                       posizioni: pos.map { var p = $0; p.totaleVersato = nil; return p },
                                       tolleranzaGenerale: 5)?.costo.senzaVersato == ["Fondo"])
        verifica.vero("Radar: senza tolleranza nessuno è fuori",
                      MotoreRadar.voce(cliente: c, modello: P.equilibrato, posizioni: pos, tolleranzaGenerale: nil)?.fuori == false)
        var stretto = P.equilibrato
        stretto.tolleranza = 25
        verifica.vero("Radar: la tolleranza del modello vale sulla generale",
                      MotoreRadar.voce(cliente: c, modello: stretto, posizioni: pos, tolleranzaGenerale: 5)?.fuori == false)
        let previdenza = AiutiProva.posizione("Fondo pensione", .previdenza, 500_000) { $0.clienteId = c.id; $0.quotaAzionaria = 100 }
        verifica("Radar: la previdenza non entra nel radar",
                 MotoreRadar.voce(cliente: c, modello: P.equilibrato, posizioni: pos + [previdenza], tolleranzaGenerale: 5)?.distanza ?? -1, 20,
                 tolleranza: 1e-6)
        // Due canali: azioni in Alleanza, liquidità indipendente → ogni canale si riequilibra da sé
        let alleanza = AiutiProva.posizione("Fondo Alleanza", .investimento, 50_000, canale: .alleanza) {
            $0.clienteId = c.id; $0.quotaAzionaria = 100
        }
        let due = MotoreRadar.voce(cliente: c, modello: P.equilibrato, posizioni: [alleanza, pos[1]], tolleranzaGenerale: 5)
        verifica.vero("Radar: con due canali ogni spostamento resta nel suo",
                      Set(due?.spostamenti.map(\.canale) ?? []) == [.alleanza, .indipendente])
        verifica.vero("Radar: angolo nel settore fisso per cliente",
                      MotoreRadar.angolo("laura") == MotoreRadar.angolo("laura") && (0..<1).contains(MotoreRadar.angolo("laura")))
        var prudente = c
        prudente.profilo.propensione = .prudente
        verifica.vero("Radar: un modello Dinamico supera il profilo prudente", MotoreRadar.oltreProfilo(P.dinamico, cliente: prudente))
        var moderato = c
        moderato.profilo.propensione = .moderata
        verifica.vero("Radar: il modello Prudente sta nel profilo moderato", !MotoreRadar.oltreProfilo(P.prudente, cliente: moderato))
    }

    private static func radar(_ verifica: VerificaCalcoli) {
        var d = DatiPrisma(clienti: [], appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: "", impostazioni: Impostazioni())
        let (c, pos) = clienteDiProva()
        let (senza, pos2) = clienteDiProva(modello: nil)
        d.clienti = [c, senza]
        d.posizioni = pos + pos2
        verifica.vero("Radar: senza modelli il radar è vuoto", MotoreRadar.calcola(d).vuoto)
        d.portafogliModello = P.tutti
        let r = MotoreRadar.calcola(d)
        verifica("Radar: sul radar solo i clienti con un modello", Double(r.voci.count), 1)
        verifica.vero("Radar: il cliente senza modello è fra quelli da assegnare", r.senzaModello == [senza.id])
        verifica("Radar: senza tolleranza scritta nessuno fuori", Double(r.fuori.count), 0)
        d.impostazioni.tolleranzaRadar = 5
        verifica("Radar: con la tolleranza il cliente è fuori", Double(MotoreRadar.calcola(d).fuori.count), 1)
        // I dati di prova: tre modelli, tolleranza 5, un modello per ogni cliente con investimenti
        var prova = ClientiFittizi.completi()
        P.applica(&prova)
        let rp = MotoreRadar.calcola(prova)
        verifica.vero("Radar: dati di prova con tre modelli e clienti sul radar", rp.modelli.count == 3 && rp.voci.count >= 10)
        verifica.vero("Radar: chi ha solo liquidità resta senza modello", !rp.senzaModello.isEmpty)
        verifica.vero("Radar: distanze dei dati di prova fra 0 e 100", rp.voci.allSatisfy { (0...100).contains($0.distanza) })
        verifica.vero("Radar: i più lontani sono al massimo tre, in ordine",
                      rp.piuLontani.count == 3 && zip(rp.piuLontani, rp.piuLontani.dropFirst()).allSatisfy { $0.distanza >= $1.distanza })
    }

    private static func bozze(_ verifica: VerificaCalcoli) {
        let (c, pos) = clienteDiProva()
        guard let v = MotoreRadar.voce(cliente: c, modello: P.equilibrato, posizioni: pos, tolleranzaGenerale: 5) else { return }
        let b = MotoreRadar.bozze(v)
        verifica.vero("Radar: una bozza per canale, proposta in bozza",
                      b.count == 1 && b.allSatisfy { $0.stato == .proposta && $0.esito == .bozza && $0.riequilibrio?.modelloId == P.equilibrato.id })
        verifica("Radar: la bozza porta l'importo da spostare", b.first?.versamentoIniziale ?? 0, v.spostato, tolleranza: 0.01)
        var d = DatiPrisma(clienti: [c], appuntamenti: [], attivita: [], posizioni: pos + b, clienteAttivoId: "", impostazioni: Impostazioni())
        d.portafogliModello = P.tutti
        d.impostazioni.tolleranzaRadar = 5
        let r = MotoreRadar.calcola(d)
        verifica.vero("Radar: con la bozza il punto resta dove è, segnato «proposta pronta»",
                      r.voci.first?.bozzaPronta == true && abs((r.voci.first?.distanza ?? 0) - v.distanza) < 1e-9)
        verifica("Radar: chi ha la bozza non si riequilibra due volte", Double(r.daRiequilibrare.count), 0)
        d.posizioni = d.posizioni.map { var p = $0; if p.riequilibrio != nil { p.esito = .presentata }; return p }
        verifica.vero("Radar: una bozza presentata non è più «proposta pronta»", MotoreRadar.calcola(d).voci.first?.bozzaPronta == false)
    }

    private static func testi(_ verifica: VerificaCalcoli) {
        verifica.vero("Radar: punti con la virgola", TestiRadar.puntiConNome(9.5) == "9,5 punti" && TestiRadar.puntiConNome(1) == "1 punto")
        verifica.vero("Radar: pesi in fila come nel template", TestiRadar.pesi(P.prudente.pesi) == "20 · 55 · 20 · 5")
        verifica.vero("Radar: importi della frase alle migliaia", TestiRadar.circa(19_620) == Formati.euro(20_000))
        let (c, pos) = clienteDiProva()
        if let v = MotoreRadar.voce(cliente: c, modello: P.equilibrato, posizioni: pos, tolleranzaGenerale: 5) {
            let f = TestiRadar.riequilibrio(v)
            verifica.vero("Radar: la frase non inventa percentuali di costo e dice l'ingresso",
                          !f.contains("0,4%") && f.contains("dipende dal prodotto"))
            verifica.vero("Radar: VoiceOver dice nome, modello, distanza e stato",
                          TestiRadar.accessibilita(v) == "Cliente di prova, modello Equilibrato, 20 punti, fuori tolleranza")
        }
    }
}
