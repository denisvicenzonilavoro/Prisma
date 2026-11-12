import Foundation

/// Prove di «Il prodotto sul cliente» (MotoreProdottoCliente): i campi del cliente dipendono dal tipo di prodotto e
/// dallo stato; la posizione prende dalla scheda costi, rendimento, rischio e canale e dal consulente solo importi, date
/// e durata; senza importo non si aggiunge; la frequenza «unica» con un premio periodico diventa annuale; in essere
/// porta il valore di oggi e il numero di contratto, la proposta resta in bozza. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliProdottoCliente {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 11, 12)
        var risparmio = Prodotto(nome: "Piano di risparmio di prova", canale: .alleanza, area: .risparmio)
        risparmio.tipologia = "Polizza rivalutabile a premi ricorrenti (Ramo I)"
        risparmio.costoIngresso = 3; risparmio.costoAnnuo = 1.2; risparmio.rendimentoAtteso = 2.5; risparmio.sri = 2
        risparmio.periodoRaccomandato = 10
        var fondo = Prodotto(nome: "Fondo azionario di prova", canale: .indipendente, area: .investimento)
        fondo.emittente = "Casa di prova"; fondo.costoAnnuo = 1.6; fondo.sri = 4
        var tcm = Prodotto(nome: "Temporanea caso morte di prova", canale: .alleanza, area: .protezione)
        tcm.periodoRaccomandato = nil
        var pip = Prodotto(nome: "PIP di prova", canale: .alleanza, area: .previdenza)
        pip.periodoRaccomandato = 25

        // I campi
        let c = MotoreProdottoCliente.campi
        verifica.vero("Prodotto sul cliente: risparmio, prima il premio unico e il periodico",
                      Array(c(risparmio, .proposta).prefix(2)) == [.versamentoIniziale, .premio])
        verifica.vero("Prodotto sul cliente: protezione, prima il capitale assicurato",
                      c(tcm, .proposta).first == .capitaleAssicurato)
        verifica.vero("Prodotto sul cliente: previdenza con TFR e contributo del datore",
                      c(pip, .proposta).contains(.tfr) && c(pip, .proposta).contains(.contributoDatore))
        verifica.vero("Prodotto sul cliente: in essere chiede valore di oggi e numero di contratto",
                      c(fondo, .inEssere).contains(.controvalore) && c(fondo, .inEssere).contains(.numeroContratto))
        verifica.vero("Prodotto sul cliente: la proposta non chiede il valore di oggi",
                      !c(fondo, .proposta).contains(.controvalore))

        // I valori proposti: frequenza e durata, mai importi
        let vr = MotoreProdottoCliente.valoriIniziali(per: risparmio, cliente: nil, oggi: oggi)
        verifica.vero("Prodotto sul cliente: risparmio mensile, durata dal KID",
                      vr.frequenza == .mensile && vr.anni == 10 && vr.premio == 0 && vr.versamentoIniziale == 0)
        verifica.vero("Prodotto sul cliente: fondo a premio unico",
                      MotoreProdottoCliente.valoriIniziali(per: fondo, cliente: nil, oggi: oggi).frequenza == .unica)
        verifica.vero("Prodotto sul cliente: protezione annuale, 10 anni senza periodo nel KID",
                      MotoreProdottoCliente.valoriIniziali(per: tcm, cliente: nil, oggi: oggi).anni == 10)
        verifica.vero("Prodotto sul cliente: previdenza senza età del cliente, durata dalla scheda",
                      MotoreProdottoCliente.valoriIniziali(per: pip, cliente: nil, oggi: oggi).anni == 25)

        // Che cosa manca
        verifica.vero("Prodotto sul cliente: senza importo non si aggiunge",
                      MotoreProdottoCliente.mancante(vr, per: risparmio) != nil)
        var v = vr
        v.premio = 150
        verifica.vero("Prodotto sul cliente: con il periodico si aggiunge", MotoreProdottoCliente.mancante(v, per: risparmio) == nil)
        var zero = v
        zero.anni = 0
        verifica.vero("Prodotto sul cliente: durata zero non va", MotoreProdottoCliente.mancante(zero, per: risparmio) != nil)
        var protezione = MotoreProdottoCliente.valoriIniziali(per: tcm, cliente: nil, oggi: oggi)
        verifica.vero("Prodotto sul cliente: protezione senza capitale né premio non va",
                      MotoreProdottoCliente.mancante(protezione, per: tcm) != nil)
        protezione.capitaleAssicurato = 200_000
        verifica.vero("Prodotto sul cliente: protezione con il capitale va", MotoreProdottoCliente.mancante(protezione, per: tcm) == nil)

        // La posizione: la scheda più i dati del cliente
        let p = MotoreProdottoCliente.posizione(da: risparmio, clienteId: "giulia", valori: v)
        verifica.vero("Prodotto sul cliente: legata alla scheda, canale e area della scheda",
                      p.prodottoId == risparmio.id && p.canale == .alleanza && p.area == .risparmio && p.clienteId == "giulia")
        verifica("Prodotto sul cliente: costo d'ingresso dalla scheda", p.costoIngresso ?? -1, 3)
        verifica("Prodotto sul cliente: costo annuo dalla scheda", p.costoAnnuo ?? -1, 1.2)
        verifica("Prodotto sul cliente: rendimento dalla scheda", p.rendimentoAtteso ?? -1, 2.5)
        verifica("Prodotto sul cliente: premio mensile scritto", p.premio, 150)
        verifica.vero("Prodotto sul cliente: proposta in bozza, mensile", p.stato == .proposta && p.esito == .bozza && p.frequenza == .mensile)
        let anni = p.scadenza.flatMap { Calendar.current.dateComponents([.year], from: oggi, to: $0).year }
        verifica("Prodotto sul cliente: scadenza a 10 anni dalla decorrenza", Double(anni ?? -1), 10)

        var unica = v
        unica.frequenza = .unica
        verifica.vero("Prodotto sul cliente: premio periodico con frequenza unica diventa annuale",
                      MotoreProdottoCliente.posizione(da: risparmio, clienteId: "giulia", valori: unica).frequenza == .annuale)

        var inEssere = MotoreProdottoCliente.valoriIniziali(per: fondo, cliente: nil, stato: .inEssere, oggi: oggi)
        inEssere.versamentoIniziale = 20_000
        inEssere.controvalore = 21_500
        inEssere.numeroContratto = "  AB-123 "
        let q = MotoreProdottoCliente.posizione(da: fondo, clienteId: "marco", valori: inEssere)
        verifica.vero("Prodotto sul cliente: in essere senza esito, con il numero ripulito",
                      q.stato == .inEssere && q.esito == nil && q.numeroContratto == "AB-123")
        verifica("Prodotto sul cliente: valore di oggi", q.controvalore ?? -1, 21_500)
        verifica.vero("Prodotto sul cliente: indipendente con la compagnia della scheda", q.canale == .indipendente && q.emittente == "Casa di prova")

        var piano = MotoreProdottoCliente.valoriIniziali(per: pip, cliente: nil, oggi: oggi)
        piano.premio = 100; piano.tfr = 1_800; piano.contributoDatore = 0
        let r = MotoreProdottoCliente.posizione(da: pip, clienteId: "giulia", valori: piano)
        verifica("Prodotto sul cliente: TFR conferito", r.tfrConferito ?? -1, 1_800)
        verifica.vero("Prodotto sul cliente: contributo del datore zero resta vuoto", r.contributoDatore == nil)
    }
}
