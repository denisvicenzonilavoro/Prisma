#if os(macOS)
import Foundation

/// Le istantanee di «Orizzonte», giro 1 (Design/template-novita-specifica.md §0.5, §1.7 e §2.7), tutte nello stato
/// finale (`\.modoIstantanea`):
/// - parte comune (500-506): la scrivania con il riquadro «Il tuo studio» (con valori di prova, poi vuoto, cioè lo
///   stato vero di un archivio senza aliquote né obiettivi) e la finestra di Studio su una scheda che arriverà (il
///   pannello «Le novità» e Messaggi e Mercato sono fra le scene di Istantanee.swift);
/// - Studio › Cruscotto (570-577): con le aliquote e gli obiettivi di prova, senza aliquote (lo stato vero), senza
///   obiettivi, l'archivio vuoto, e Impostazioni › Studio con i campi vuoti.
/// Le aliquote e gli obiettivi di prova esistono SOLO dentro queste scene (lo stato dell'istantanea non si salva):
/// sono valori dimostrativi, non dati veri, e a schermo ogni card porta «dati di prova» (i clienti sono quelli di prova).
extension Istantanee {
    nonisolated static var sceneStudio: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            // Parte comune
            ("500-scrivania-orizzonte", { s in studioDiProva(s) }),
            ("500-scrivania-orizzonte-scuro", { s in studioDiProva(s) }),
            ("503-scrivania-studio-vuoto", { _ in }),
            ("503-scrivania-studio-vuoto-scuro", { _ in }),
            // Era la scheda «che arriva»: dal giro 6 Esame OCF c'è, qui senza domande (IstantaneeEsameOCF.swift, 530-537)
            ("505-app-nuove-studio", { s in s.apriStudio(.ocf) }),
            ("505-app-nuove-studio-scuro", { s in s.apriStudio(.ocf) }),
            // Studio › Cruscotto
            ("570-studio-cruscotto", { s in
                studioDiProva(s)
                s.apriStudio(.cruscotto)
            }),
            ("570-studio-cruscotto-scuro", { s in
                studioDiProva(s)
                s.apriStudio(.cruscotto)
            }),
            ("571-studio-cruscotto-vuoto", { s in
                archivioVuoto(s)
                s.apriStudio(.cruscotto)
            }),
            ("571-studio-cruscotto-vuoto-scuro", { s in
                archivioVuoto(s)
                s.apriStudio(.cruscotto)
            }),
            // Lo stato vero dei dati di prova: nessuna aliquota e nessun obiettivo inseriti
            ("572-studio-cruscotto-senza-aliquote", { s in s.apriStudio(.cruscotto) }),
            ("572-studio-cruscotto-senza-aliquote-scuro", { s in s.apriStudio(.cruscotto) }),
            ("574-studio-cruscotto-senza-obiettivi", { s in
                aliquoteDiProva(s)
                s.apriStudio(.cruscotto)
            }),
            ("574-studio-cruscotto-senza-obiettivi-scuro", { s in
                aliquoteDiProva(s)
                s.apriStudio(.cruscotto)
            }),
            ("576-impostazioni-studio", { s in preparaImpostazioniApple(s, sezione: .studio) }),
            ("576-impostazioni-studio-scuro", { s in preparaImpostazioniApple(s, sezione: .studio) }),
        ]
    }

    /// Aliquote e obiettivi di prova (scene 500, 570): valori dimostrativi del template, mai dati veri.
    nonisolated static func studioDiProva(_ s: StatoShell) {
        aliquoteDiProva(s)
        let anno = Calendar.current.component(.year, from: Date())
        // Obiettivi di prova (quelli del template: 500.000 € di produzione, 10 nuovi clienti, 35.000 € di consulenza)
        s.dati.impostazioni.studio.obiettivi[anno] = ObiettiviStudio(produzioneAlleanza: 500_000, nuoviClienti: 10,
                                                                     ricaviConsulenza: 35_000)
    }

    /// Aliquote di prova, dichiarate tali (scene 500, 570, 574): percentuali tonde, dimostrative, non di Alleanza.
    nonisolated static func aliquoteDiProva(_ s: StatoShell) {
        let prova = AliquoteProvvigione(nuovaProduzione: 3, ricorrenti: 1, rinnovi: nil)
        s.dati.impostazioni.studio.aliquote[.investimento] = prova
        s.dati.impostazioni.studio.aliquote[.risparmio] = prova
        s.dati.impostazioni.studio.aliquote[.previdenza] = prova
        s.dati.impostazioni.studio.aliquote[.protezione] = AliquoteProvvigione(nuovaProduzione: 10, ricorrenti: nil, rinnovi: 5)
    }

    /// Un archivio senza clienti (scena 571): ogni card dice che cosa manca.
    nonisolated static func archivioVuoto(_ s: StatoShell) {
        s.dati.clienti.removeAll()
        s.dati.posizioni.removeAll()
        s.dati.appuntamenti.removeAll()
        s.dati.incontri.removeAll()
        s.dati.simulazioni.removeAll()
        s.dati.obiettivi.removeAll()
    }
}
#endif
