#if os(macOS)
import Foundation

/// Le istantanee di Pratiche › Moduli, «Compila da solo» (Design/template-luce-specifica.md §7.2.7, «Luce» giro 10),
/// tutte nello stato finale (`\.modoIstantanea`: caselle già piene, valori scritti per intero, firme gialle ferme, tile
/// finali presenti):
/// - 810: il modulo fac-simile di prova non compilato, chiaro e scuro;
/// - 811: compilato con i dati di Giulia, IBAN rosso (interruttore spento), firme gialle, tile di Vera e delle firme,
///   chiaro e scuro;
/// - 812: nessun modulo caricato, la zona di rilascio e «Moduli da preparare»;
/// - 813: la revisione della mappa di un fac-simile piatto (caselle proposte dalle regole, da confermare), chiaro e scuro;
/// - 814: compilato con Qwen non pronto (la tile senza la sfera di Vera);
/// - 815: Impostazioni › Moduli con i due fac-simile e l'interruttore dell'IBAN.
/// DATI DI PROVA DICHIARATI: i moduli sono i fac-simile disegnati da Prisma (FacSimileModulo, con la scritta «FAC-SIMILE»);
/// per Giulia si aggiungono nel solo stato dell'istantanea (che non si salva) la scheda fiscale con la sede, una proposta
/// del canale indipendente (premio, decorrenza e beneficiari di prova) e il documento d'identità di prova.
extension Istantanee {
    nonisolated static var scenePraticheModuli: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("810-pratiche-moduli") { s in preparaModuli(s) }
        coppia("811-pratiche-moduli-compilato") { s in
            preparaModuli(s)
            s.moduli.veraProntaIstantanea = true
            s.compilaModulo()
        }
        una("812-pratiche-moduli-vuoto") { s in
            s.apriPratiche(.moduli)
        }
        coppia("813-pratiche-moduli-revisione") { s in
            s.apriPratiche(.moduli)
            guard let pdf = FacSimileModulo.pdf(FacSimileModulo.proposta, compilabile: false) else { return }
            if let m = s.importaModulo(pdf, nome: "Proposta di polizza (fac-simile piatto)") {
                s.moduli.campoRevisione = m.campi.first { $0.dato == .codiceFiscale }?.id
            }
        }
        una("814-pratiche-moduli-senza-ruby") { s in
            preparaModuli(s)
            s.moduli.veraProntaIstantanea = false
            s.compilaModulo()
        }
        una("815-impostazioni-moduli") { s in
            s.caricaEsempiModuli()
            s.schedaImpostazioni = .moduli
            s.apri(.impostazioni)
        }
        return scene
    }

    /// I fac-simile di prova, Giulia con i dati di prova che servono al modulo, Pratiche › Moduli sulla proposta.
    nonisolated static func preparaModuli(_ s: StatoShell) {
        s.caricaEsempiModuli()
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "giulia" }) {
            var c = s.dati.clienti[i]
            var f = c.fiscale ?? DatiFiscaliCliente()
            f.nome = "Giulia"
            f.cognome = "Rossi"
            f.sede.indirizzo = "Via dei Mille"
            f.sede.numeroCivico = "12"
            f.sede.cap = "40121"
            f.sede.comune = "Bologna"
            f.sede.provincia = "BO"
            c.fiscale = f
            if c.codiceFiscale.isEmpty { c.codiceFiscale = "RSSGLI89C54A944X" }
            s.dati.clienti[i] = c
            var p = Posizione(clienteId: c.id, canale: .indipendente, stato: .proposta, area: .risparmio, nome: "Piano di accumulo (dati di prova)")
            p.esito = .presentata
            p.premio = 550
            p.frequenza = .mensile
            p.beneficiari = "Gli eredi legittimi"
            p.decorrenza = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 12, day: 1))
            s.dati.posizioni.append(p)
        }
        s.clienteAttivoId = "giulia"
        s.moduli.clienteId = "giulia"
        s.moduli.scelto = "modulo-prova-\(TipoModulo.propostaPolizza.rawValue)"
        s.apriPratiche(.moduli)
    }
}
#endif
