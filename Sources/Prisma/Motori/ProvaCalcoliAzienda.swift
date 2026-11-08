import Foundation

/// Prove della scheda «L'azienda» dei clienti imprenditori (Design/template-luce-specifica.md §9.3, «Luce» giro 7): il
/// fabbisogno della persona chiave è fatturato × mesi ÷ 12 e la copertura conta solo le posizioni in essere collegate
/// dall'utente; senza fatturato o mesi nessun anello e la frase dice cosa manca; il TFM è sì/no senza calcoli; welfare e
/// continuità sono voci fatte ÷ voci scelte; le cifre del template (35%, 10%) non si riproducono; un'area non pertinente
/// non ha anello; le frasi usano i dati veri (figli dalla famiglia); il primo cliente con un'azienda è il primo per nome.
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliAzienda {
    static func esegui(_ verifica: VerificaCalcoli) {
        personaChiave(verifica)
        aree(verifica)
        mancanti(verifica)
        testi(verifica)
        clienti(verifica)
    }

    private static func cliente(_ aziende: [AziendaCliente]) -> Cliente {
        var c = Cliente.nuovo(tinta: .blu)
        c.nome = "Marco Bianchi"
        c.aziende = aziende
        return c
    }

    private static func personaChiave(_ verifica: VerificaCalcoli) {
        verifica("Azienda: fabbisogno della persona chiave = fatturato × mesi ÷ 12",
                 MotoreAzienda.fabbisognoPersonaChiave(fatturato: 2_100_000, mesi: 6) ?? -1, 1_050_000)
        verifica.vero("Azienda: senza mesi a rischio nessun fabbisogno",
                      MotoreAzienda.fabbisognoPersonaChiave(fatturato: 2_100_000, mesi: nil) == nil)
        verifica.vero("Azienda: senza fatturato nessun fabbisogno",
                      MotoreAzienda.fabbisognoPersonaChiave(fatturato: nil, mesi: 6) == nil)

        var a = AziendeDiProva.bianchiSerramenti()
        let c = cliente([a])
        var keyMan = AiutiProva.posizione("Key man", .protezione, 0) { $0.clienteId = c.id; $0.capitaleAssicurato = 420_000 }
        keyMan.id = "pos-keyman"
        var proposta = AiutiProva.posizione("Key man proposta", .protezione, 0) {
            $0.clienteId = c.id; $0.capitaleAssicurato = 1_000_000; $0.stato = .proposta
        }
        proposta.id = "pos-keyman-proposta"
        var altra = AiutiProva.posizione("Altra TCM", .protezione, 0) { $0.clienteId = c.id; $0.capitaleAssicurato = 300_000 }
        altra.id = "pos-tcm"
        let posizioni = [keyMan, proposta, altra]
        // Nessuna copertura collegata: 0%
        let senza = MotoreAzienda.valuta(a, cliente: c, posizioni: posizioni)[0]
        verifica("Azienda: persona chiave senza coperture collegate", senza.percentuale ?? -1, 0)
        verifica.vero("Azienda: «Oggi nessuna copertura»", senza.frase.hasSuffix("Oggi nessuna copertura."))
        // Collegate la key man in essere e la proposta: conta solo quella in essere (420.000 / 1.050.000 = 40%)
        a.personaChiave?.posizioniCollegate = ["pos-keyman", "pos-keyman-proposta"]
        let con = MotoreAzienda.valuta(a, cliente: cliente([a]), posizioni: posizioni)[0]
        verifica("Azienda: copertura della persona chiave dalle posizioni in essere collegate", con.percentuale ?? -1, 40,
                 tolleranza: 1e-9)
        verifica("Azienda: capitale delle coperture collegate", MotoreAzienda.capitalePersonaChiave(a, posizioni: posizioni), 420_000)
        // Più capitale del fabbisogno: al massimo 100
        a.personaChiave?.posizioniCollegate = ["pos-keyman", "pos-tcm", "pos-keyman"]
        a.personaChiave?.mesiARischio = 3
        let piena = MotoreAzienda.valuta(a, cliente: cliente([a]), posizioni: posizioni)[0]
        verifica("Azienda: copertura oltre il fabbisogno ferma a 100", piena.percentuale ?? -1, 100)
    }

    private static func aree(_ verifica: VerificaCalcoli) {
        let a = AziendeDiProva.bianchiSerramenti()
        let v = MotoreAzienda.valuta(a, cliente: cliente([a]), posizioni: [])
        verifica.vero("Azienda: quattro aree nell'ordine del template", v.map(\.area) == AreaAzienda.allCases)
        verifica("Azienda: TFM non accantonato = 0%", v[1].percentuale ?? -1, 0)
        verifica.vero("Azienda: TFM non accantonato rimanda al commercialista", v[1].frase.contains("commercialista"))
        // Welfare di prova: 1 voce attiva su 3 = 33,3% (non il 35% dimostrativo del template)
        verifica("Azienda: welfare = voci attive ÷ voci scelte", v[2].percentuale ?? -1, 100.0 / 3, tolleranza: 1e-9)
        // Continuità di prova: 1 passo su 5 = 20% (il 10% del template con cinque passi non si ottiene)
        verifica("Azienda: passaggio = passi fatti ÷ passi scelti", v[3].percentuale ?? -1, 20, tolleranza: 1e-9)
        var accantonato = a
        accantonato.tfm = StatoTFM(accantonato: true, importo: 80_000)
        let t = MotoreAzienda.valuta(accantonato, cliente: cliente([accantonato]), posizioni: [])[1]
        verifica("Azienda: TFM accantonato = 100%", t.percentuale ?? -1, 100)
        verifica.vero("Azienda: TFM accantonato con l'importo e senza calcoli fiscali",
                      t.frase.contains("80.000") && t.frase.contains("commercialista"))
        // Non pertinente: nessun anello, nessun dato che manca
        var c = cliente([a])
        c.datiNonPertinenti = [MotoreAzienda.chiaveNonPertinente(azienda: a.id, area: .welfare): Date()]
        let np = MotoreAzienda.valuta(a, cliente: c, posizioni: [])[2]
        verifica.vero("Azienda: area non pertinente senza anello", np.nonPertinente && np.percentuale == nil && np.mancano.isEmpty)
        verifica.vero("Azienda: chiave non pertinente per azienda e area",
                      MotoreAzienda.chiaveNonPertinente(azienda: "x", area: .welfare) == "azienda:x:welfare")
        verifica.vero("Azienda: le altre aree restano valutate", MotoreAzienda.valuta(a, cliente: c, posizioni: [])[1].percentuale == 0)
    }

    private static func mancanti(_ verifica: VerificaCalcoli) {
        let a = AziendeDiProva.morettiCostruzioni()
        let v = MotoreAzienda.valuta(a, cliente: cliente([a]), posizioni: [])
        verifica.vero("Azienda con il solo nome: nessun anello", v.allSatisfy { $0.percentuale == nil && $0.daCompletare })
        verifica.vero("Azienda con il solo nome: la persona chiave chiede fatturato e mesi",
                      v[0].mancano.count == 2 && v[0].frase.hasPrefix("Per valutarla servono il fatturato e i mesi"))
        verifica.vero("Azienda con il solo nome: il TFM chiede se è accantonato", v[1].frase.hasPrefix("Per valutarla serve sapere se"))
        verifica.vero("Azienda con il solo nome: le voci di welfare al plurale",
                      v[2].frase == "Per valutarla servono le voci di welfare da considerare.")
        verifica.vero("Azienda con il solo nome: «dipendenti da inserire»",
                      TestiAzienda.sottotitolo(a, cliente: cliente([a])).contains("dipendenti da inserire"))
        // Una lista con voci illeggibili o vuote: il modulo le ripulisce
        var sporca = a
        sporca.welfare = ListaAzienda(voci: [VoceAzienda(titolo: "  ")])
        sporca.personaChiave = PersonaChiave()
        sporca.ripulisci()
        verifica.vero("Azienda: voci vuote e aree vuote tornano nil", sporca.welfare == nil && sporca.personaChiave == nil)
    }

    private static func testi(_ verifica: VerificaCalcoli) {
        let a = AziendeDiProva.bianchiSerramenti()
        let c = cliente([a])
        verifica.vero("Azienda: sottotitolo del template",
                      TestiAzienda.sottotitolo(a, cliente: c)
                        == "Azienda di prova · Serramenti · 14 dipendenti · Marco Bianchi socio al 70% e amministratore")
        verifica.vero("Azienda: fatturato in milioni «2,1 mln €»", TestiAzienda.fatturatoBreve(2_100_000) == "2,1 mln\u{00A0}€")
        verifica.vero("Azienda: fatturato sotto il milione in euro", TestiAzienda.fatturatoBreve(850_000) == "850.000\u{00A0}€")
        verifica.vero("Azienda: tre milioni senza decimali", TestiAzienda.fatturatoBreve(3_000_000) == "3 mln\u{00A0}€")
        verifica.vero("Azienda: frase della persona chiave del template",
                      TestiAzienda.frasePersonaChiave(nome: "Marco", mesi: 6, capitale: 0, fabbisogno: 1_050_000)
                        == "Se Marco si ferma, l'azienda perde circa 6 mesi di fatturato. Oggi nessuna copertura.")
        verifica.vero("Azienda: frase del welfare dalle voci",
                      TestiAzienda.fraseWelfare(a.welfare?.voci ?? [])
                        == "Attive: buoni pasto. Da valutare: premi di risultato e previdenza complementare per i dipendenti.")
        verifica.vero("Azienda: i figli dalla famiglia nella frase del passaggio",
                      TestiAzienda.frasePassaggio(a.continuita?.voci ?? [], figli: [9, 1])
                        == "Figli di 9 e 1 anno: fatto 1 passo su 5 (statuto e clausole valutati).")
        verifica.vero("Azienda: senza figli la frase comincia maiuscola",
                      TestiAzienda.frasePassaggio([VoceAzienda(titolo: "Piano")], figli: []) == "Il passo della continuità scelto non è ancora fatto.")
        verifica.vero("Azienda: piede di prova e nota fiscale",
                      TestiAzienda.piede(a) == "Dati aziendali di prova. Le valutazioni fiscali vanno sempre verificate con il commercialista dell'azienda.")
        var vera = a
        vera.diProva = nil
        verifica.vero("Azienda: piede di un'azienda vera senza «di prova»", TestiAzienda.piede(vera) == TestiAzienda.piedeFiscale)
        verifica.vero("Azienda: sigle lasciate maiuscole nella frase", TestiAzienda.inFrase("TFR in azienda") == "TFR in azienda")
    }

    private static func clienti(_ verifica: VerificaCalcoli) {
        var b = cliente([AziendeDiProva.morettiCostruzioni()])
        b.nome = "Zeno Bassi"
        let a = cliente([AziendeDiProva.bianchiSerramenti()])
        var senza = Cliente.nuovo(tinta: .rosa)
        senza.nome = "Anna Alberti"
        verifica.vero("Azienda: il primo per nome con un'azienda", MotoreAzienda.primoConAzienda([b, senza, a])?.id == a.id)
        verifica.vero("Azienda: nessuno con un'azienda", MotoreAzienda.primoConAzienda([senza]) == nil)
        // Dati di prova: Marco Bianchi ha l'azienda del template, dichiarata di prova
        let demo = DatiDemo.clienti().first { $0.id == "marco" }
        verifica.vero("Azienda: Marco Bianchi nei dati di prova con Bianchi Serramenti, di prova",
                      demo?.elencoAziende.first?.ragioneSociale == "Bianchi Serramenti S.r.l." && demo?.elencoAziende.first?.diProva == true)
        verifica.vero("Azienda: la professione di Marco resta quella di prima", demo?.professione == "Ingegnere")
    }
}
