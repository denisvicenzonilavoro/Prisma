import Foundation

/// Prove dei simulatori dal vivo di Previdenza e Protezione (Analisi 360, §4.3.2-4.3.3): con il versamento delle
/// ipotesi il passo leggero dà gli stessi numeri di `MotoreAnalisi.previdenza`; deduzione entro il limite e IRPEF
/// per scaglioni; tariffa caso morte dal cliente o, se manca, dall'archivio; premio, scoperto e copertura.
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliSimulatoriAnalisi {
    static func esegui(_ verifica: VerificaCalcoli) {
        previdenza(verifica)
        protezione(verifica)
    }

    private static func previdenza(_ verifica: VerificaCalcoli) {
        var i = IpotesiPrevidenza()
        i.eta = 40; i.etaPensione = 67; i.redditoDesiderato = 2_200; i.pensionePubblica = 1_400
        i.capitale = 12_000; i.versamentoMensile = 150; i.rendimentoReale = 1.5; i.anniIntegrazione = 25
        let pieno = MotoreAnalisi.previdenza(i)
        let passo = MotoreSimulatoriAnalisi.previdenza(i, versamento: i.versamentoMensile, reddito: nil)
        verifica("Simulatore previdenza: montante come l'area", passo.montante, pieno.montante)
        verifica("Simulatore previdenza: rendita come l'area", passo.integrazione, pieno.integrazione)
        verifica("Simulatore previdenza: divario residuo come l'area", passo.divarioResiduo, pieno.divarioResiduo)
        verifica("Simulatore previdenza: copertura = rendita / divario", passo.copertura, pieno.integrazione / 800, tolleranza: 1e-9)
        verifica.vero("Simulatore previdenza: senza reddito niente risparmio fiscale", passo.risparmioFiscale == nil)
        // 500 € al mese = 6.000 € l'anno: si deducono 5.300 €; reddito 32.000 € → IRPEF(32.000) − IRPEF(26.700)
        let alto = MotoreSimulatoriAnalisi.previdenza(i, versamento: 500, reddito: 32_000)
        verifica("Simulatore previdenza: deduzione entro il limite", alto.deducibili, RegoleFiscali.limiteDeducibilita)
        verifica("Simulatore previdenza: IRPEF risparmiata per scaglioni", alto.risparmioFiscale ?? -1, 1_619)
        // Con il datore a 1.300 € l'anno restano 4.000 € deducibili per il cliente
        let datore = MotoreSimulatoriAnalisi.previdenza(i, versamento: 500, datore: 1_300, reddito: 32_000)
        verifica("Simulatore previdenza: il datore riduce il limite", datore.deducibili, 4_000)
        verifica.vero("Simulatore previdenza: più versamento, più rendita", alto.integrazione > passo.integrazione)
        // Senza divario la copertura è piena
        var senza = i
        senza.pensionePubblica = 2_500
        verifica("Simulatore previdenza: senza divario copertura piena",
                 MotoreSimulatoriAnalisi.previdenza(senza, versamento: 0, reddito: nil).copertura, 1)
    }

    private static func protezione(_ verifica: VerificaCalcoli) {
        let tcm1 = AiutiProva.posizione("TCM 1", .protezione, 0) {
            $0.rischio = .vita; $0.capitaleAssicurato = 150_000; $0.premio = 22; $0.frequenza = .mensile
        }
        let tcm2 = AiutiProva.posizione("TCM 2", .protezione, 0) {
            $0.rischio = .vita; $0.capitaleAssicurato = 300_000; $0.premio = 45; $0.frequenza = .mensile
        }
        let decrescente = AiutiProva.posizione("TCM mutuo", .protezione, 0) {
            $0.rischio = .vita; $0.capitaleAssicurato = 200_000; $0.premio = 300; $0.frequenza = .annuale
            $0.capitaleDecrescente = true
        }
        // Il cliente non ha coperture con premio: vale la media dell'archivio (la decrescente non conta)
        let t = MotoreSimulatoriAnalisi.tariffaCasoMorte(cliente: [], archivio: [tcm1, tcm2, decrescente])
        verifica("Simulatore protezione: tariffa dall'archivio", t?.perMille ?? -1, (264.0 + 540) / 450_000 * 1_000, tolleranza: 1e-9)
        verifica.vero("Simulatore protezione: fonte archivio", t?.fonte == .archivio && t?.coperture == 2)
        let propria = MotoreSimulatoriAnalisi.tariffaCasoMorte(cliente: [tcm1], archivio: [tcm1, tcm2])
        verifica.vero("Simulatore protezione: prima le coperture del cliente", propria?.fonte == .cliente && propria?.coperture == 1)
        verifica.vero("Simulatore protezione: senza coperture nessuna tariffa",
                      MotoreSimulatoriAnalisi.tariffaCasoMorte(cliente: [], archivio: [decrescente]) == nil)

        var i = IpotesiProtezione()
        i.fabbisognoMensile = 1_800; i.anniSostegno = 10; i.debiti = 0; i.speseImmediate = 15_000; i.capitaleDisponibile = 10_000
        let e = MotoreAnalisi.protezione(i, posizioni: [tcm1])
        // Fabbisogno 15.000 + 216.000 − 10.000 = 221.000; assicurati 150.000 + 50.000
        let p = MotoreSimulatoriAnalisi.protezione(e, aggiunta: 50_000, tariffa: t)
        verifica("Simulatore protezione: fabbisogno dal motore", p.fabbisogno, 221_000)
        verifica("Simulatore protezione: scoperto che resta", p.scoperto, 21_000)
        verifica("Simulatore protezione: copertura", p.copertura, 200_000.0 / 221_000, tolleranza: 1e-9)
        verifica("Simulatore protezione: premio stimato l'anno", p.premioAnnuo ?? -1, 50_000 * (804.0 / 450_000), tolleranza: 1e-6)
        verifica("Simulatore protezione: premio al mese", p.premioMensile ?? -1, 50_000 * (804.0 / 450_000) / 12, tolleranza: 1e-6)
        let oltre = MotoreSimulatoriAnalisi.protezione(e, aggiunta: 200_000, tariffa: nil)
        verifica.vero("Simulatore protezione: oltre il fabbisogno copertura piena e niente scoperto",
                      oltre.copertura == 1 && oltre.scoperto == 0 && oltre.premioAnnuo == nil)
    }
}
