#if os(macOS)
import Foundation
import CoreGraphics

/// Le istantanee di Posizioni › Radar (Design/template-luce-specifica.md §8.3.7, «Luce» giro 2), tutte nello stato
/// finale (`\.modoIstantanea`: fascio fermo a −30°, anelli fermi, numeri completi):
/// - 890: il radar con i dati di prova (tre modelli, i 35 clienti di prova, la tolleranza di prova), chiaro e scuro;
/// - 891: il dettaglio del cliente più lontano (barre di oggi, linee del modello, riequilibrio), chiaro e scuro;
/// - 892: il dettaglio di un cliente entro la tolleranza (cifra verde);
/// - 893: nessun modello: radar vuoto e invito, chiaro e scuro;
/// - 894: dopo «Riequilibra»: bozze pronte, punti al loro posto con il segno della proposta;
/// - 895: 200 clienti (come `--prova-carico`); 896: Impostazioni › Portafogli modello, chiaro e scuro;
/// - 897: la finestra stretta.
/// DATI DI PROVA DICHIARATI: modelli e tolleranza sono quelli del template (`PortafogliModelloDiProva`, nota «Dati di
/// prova»); le cifre le calcola MotoreRadar.
extension Istantanee {
    nonisolated static var sceneRadar: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("890-posizioni-radar") { s in preparaRadar(s) }
        coppia("891-posizioni-radar-dettaglio") { s in
            preparaRadar(s)
            s.radarDettaglioIstantanea = MotoreRadar.calcola(s.dati.istantanea).fuori.first?.id
        }
        una("892-posizioni-radar-dentro") { s in
            preparaRadar(s)
            s.radarDettaglioIstantanea = MotoreRadar.calcola(s.dati.istantanea).voci.filter { !$0.fuori }.max { $0.distanza < $1.distanza }?.id
        }
        coppia("893-posizioni-radar-senza-modelli") { s in
            preparaRadar(s)
            s.dati.portafogliModello = []
            s.dati.impostazioni.tolleranzaRadar = nil
            for i in s.dati.clienti.indices { s.dati.clienti[i].modelloId = nil }
        }
        una("894-posizioni-radar-bozze") { s in
            preparaRadar(s)
            s.preparaBozzeRiequilibrio(MotoreRadar.calcola(s.dati.istantanea).daRiequilibrare)
        }
        una("895-posizioni-radar-carico") { s in
            if let d = try? ProvaCarico.moltiplica(DatiPrisma.demo(), copie: ProvaCarico.copie) {
                s.dati.clienti = d.clienti
                s.dati.posizioni = d.posizioni
                s.dati.portafogliModello = d.portafogliModello
            }
            s.dati.impostazioni.tolleranzaRadar = PortafogliModelloDiProva.tolleranza
            s.apriRadar()
        }
        coppia("896-impostazioni-modelli") { s in
            preparaRadar(s, apri: false)
            s.apriImpostazioniModelli()
        }
        una("897-posizioni-radar-stretta") { s in
            preparaRadar(s)
            s.alternaIngrandimento(.posizioni)
            s.ridimensiona(.posizioni, dimensione: CGSize(width: 760, height: 640))
        }
        return scene
    }

    /// I 35 clienti di prova con i tre modelli di prova e la tolleranza di prova; poi Posizioni › Radar.
    nonisolated static func preparaRadar(_ s: StatoShell, apri: Bool = true) {
        let d = ClientiFittizi.completi()
        s.dati.clienti = d.clienti
        s.dati.posizioni = d.posizioni
        s.dati.portafogliModello = d.portafogliModello
        s.dati.impostazioni.tolleranzaRadar = d.impostazioni.tolleranzaRadar
        if apri { s.apriRadar() }
    }
}
#endif
