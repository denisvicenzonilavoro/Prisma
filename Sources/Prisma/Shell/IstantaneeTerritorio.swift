#if os(macOS)
import Foundation

/// Le istantanee di Territorio, «Il tuo territorio» (Design/template-luce-specifica.md §5.1.7, serie 700-709, «Luce»
/// giro 11), tutte nello stato finale (`\.modoIstantanea`):
/// - 700: Oggi con i 35 clienti di prova (5 + 30 fittizi), chiaro e scuro; 701: La crescita all'ultimo anno, chiaro e
///   scuro; 702: La crescita a metà degli anni;
/// - 703: Il giro con 2 visite, il suggerimento «Lungo la strada» e l'auto all'arrivo, chiaro e scuro; 704: dopo
///   «＋ Aggiungi Sofia al giro» (3 visite, la riga nuova evidenziata);
/// - 705: nessun cliente con un luogo, chiaro e scuro; 706: tre clienti non sulla mappa con l'elenco aperto;
/// - 707: il giorno senza visite fuori studio («Il prossimo giro: …»); 708: il fumetto di Giulia (solo chiaro);
/// - 709: Impostazioni › Territorio, chiaro e scuro.
///
/// DATI DI PROVA DICHIARATI: la tabella dei comuni è quella ridotta di prova (32 comuni, confini a ottagono); il giro di
/// Bologna (posizioni a mano di Laura, Andrea e Sofia, partenza, l'attività di Sofia) è `TerritorioDiProva`. Il giorno
/// del giro è il primo giorno di lavoro da domani, così l'istantanea non cambia con il giorno in cui gira il workflow.
extension Istantanee {
    nonisolated static var sceneTerritorio: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("700-territorio-oggi") { s in
            conFittizi(s)
            s.apriTerritorioIstantanea(.oggi)
        }
        coppia("701-territorio-crescita") { s in
            conFittizi(s)
            s.territorio.avvioCrescitaFatto = true
            s.territorio.annoCrescita = nil
            s.apriTerritorioIstantanea(.crescita)
        }
        una("702-territorio-crescita-anno") { s in
            conFittizi(s)
            s.territorio.avvioCrescitaFatto = true
            s.apriTerritorioIstantanea(.crescita)
            let anni = s.crescitaTerritorio().anni
            if let primo = anni.first?.anno, let ultimo = anni.last?.anno { s.territorio.annoCrescita = (primo + ultimo) / 2 }
        }
        coppia("703-territorio-giro") { s in
            giroDiProva(s, spostaVisite: 0)
            s.apriTerritorioIstantanea(.giro)
        }
        una("704-territorio-giro-aggiunto") { s in
            let g = giroDiProva(s, spostaVisite: 0)
            s.apriTabellaTerritorio()
            if let primo = s.giroTerritorio(g).suggerimenti.first { s.aggiungiAlGiro(primo) }
            s.apriTerritorioIstantanea(.giro)
        }
        coppia("705-territorio-vuoto") { s in
            for i in s.dati.clienti.indices {
                s.dati.clienti[i].indirizzo = ""
                s.dati.clienti[i].fiscale = nil
                s.dati.clienti[i].luogo = nil
            }
            s.apriTerritorioIstantanea(.oggi)
        }
        una("706-territorio-senza-luogo") { s in
            let indirizzi = ["giulia": "Via Che Non Esiste 3, Paperopoli", "marco": "Piazza 1, Samone", "laura": ""]
            for i in s.dati.clienti.indices {
                if let nuovo = indirizzi[s.dati.clienti[i].id] {
                    s.dati.clienti[i].indirizzo = nuovo
                    s.dati.clienti[i].fiscale = nil
                    s.dati.clienti[i].luogo = nil
                }
            }
            s.apriTerritorioIstantanea(.oggi)
            s.territorio.elencoSenzaLuogo = true
        }
        una("707-territorio-giro-vuoto") { s in
            giroDiProva(s, spostaVisite: 3)
            s.apriTerritorioIstantanea(.giro)
        }
        una("708-territorio-fumetto") { s in
            conFittizi(s)
            s.apriTerritorioIstantanea(.oggi)
            s.territorio.lucePuntata = "giulia"
        }
        coppia("709-impostazioni-territorio") { s in
            s.territorio.caricaSeServe()
            s.schedaImpostazioni = .territorio
            s.apri(.impostazioni)
        }
        return scene
    }

    /// I 5 clienti di prova più i 30 fittizi (dati di prova).
    nonisolated static func conFittizi(_ s: StatoShell) {
        var d = s.dati.istantanea
        ClientiFittizi.aggiungi(a: &d)
        s.dati.carica(d)
    }

    /// Il giro di prova di Bologna sul primo giorno di lavoro da domani; con `spostaVisite` le visite vanno a quel giorno
    /// più tanti giorni (707: il giorno resta senza visite fuori studio). Restituisce il giorno mostrato.
    @discardableResult
    nonisolated static func giroDiProva(_ s: StatoShell, spostaVisite: Int) -> Date {
        let g = TerritorioDiProva.giorno(da: Date(), orari: s.dati.impostazioni.orari)
        let giornoVisite = Calendar.current.date(byAdding: .day, value: spostaVisite, to: g) ?? g
        var d = s.dati.istantanea
        TerritorioDiProva.applica(&d, giorno: giornoVisite, conPartenza: true)
        s.dati.carica(d)
        s.territorio.giornoGiro = g
        return g
    }
}

extension StatoShell {
    /// Nelle istantanee `onAppear` può arrivare tardi: tabella e confini si caricano prima di aprire Territorio.
    func apriTerritorioIstantanea(_ vista: VistaTerritorio) {
        apriTabellaTerritorio()
        apriTerritorio(vista)
    }
}
#endif
