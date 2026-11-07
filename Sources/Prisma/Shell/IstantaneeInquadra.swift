#if os(macOS)
import Foundation

/// Le istantanee di Inquadra e capisci sul Mac (Design/template-novita-specifica.md §9.7), 600-609, tutte nello stato
/// finale (`\.modoIstantanea`: righe tutte presenti e accese, linea ferma in alto, sfera ferma):
/// - 600: testata di Posizioni › Portafoglio con «◎ Inquadra con l’iPhone»;
/// - 601: in attesa del testo dall'iPhone (ponte acceso); 602: ponte spento, la zona dove trascinare;
/// - 603: a metà lettura (due righe); 604: lettura finita con i due pulsanti; 605: dopo «Confronta»;
/// - 606: pochi dati; 607: illeggibile; 608: la conferma prima di aggiungere; 609: con «Riduci movimento».
/// L'iPhone (la schermata della fotocamera, con il foglio disegnato al posto della foto) sta nelle istantanee di iOS.
///
/// DATI DI PROVA DICHIARATI: il foglio è quello di `FoglioInquadraDiProva` (una vita intera di «Compagnia Esempio
/// Vita», contraente Giulia Rossi dei clienti di prova): esiste solo dentro queste scene, che non si salvano.
extension Istantanee {
    nonisolated static var sceneInquadra: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        una("600-posizioni-testata-inquadra") { s in
            s.posizioneInDettaglio = nil
            s.portafoglio = true
            s.provaFuoco.vista = .portafoglio
            s.apriApp(.posizioni)
        }
        coppia("601-posizioni-inquadra-attesa") { s in preparaInquadra(s, ponte: true) }
        una("602-posizioni-inquadra-trascina") { s in preparaInquadra(s, ponte: false) }
        coppia("603-posizioni-inquadra-lettura") { s in
            preparaInquadra(s, righe: FoglioInquadraDiProva.righe())
            s.inquadra.fermaCascata(a: 2)
        }
        coppia("604-posizioni-inquadra-fatto") { s in preparaInquadra(s, righe: FoglioInquadraDiProva.righe()) }
        coppia("605-posizioni-inquadra-confronta") { s in
            preparaInquadra(s, righe: FoglioInquadraDiProva.righe())
            s.confrontaInquadrata()
        }
        una("606-posizioni-inquadra-pochi-dati") { s in preparaInquadra(s, righe: FoglioInquadraDiProva.parziale()) }
        una("607-posizioni-inquadra-illeggibile") { s in
            preparaInquadra(s, ponte: false)
            s.inquadra.illeggibile(origine: "foto-polizza.jpg")
        }
        coppia("608-posizioni-inquadra-conferma") { s in
            preparaInquadra(s, righe: FoglioInquadraDiProva.righe())
            s.inquadra.conferma = true
        }
        una("609-posizioni-inquadra-calma") { s in
            s.dati.impostazioni.riduciMovimento = true
            preparaInquadra(s, righe: FoglioInquadraDiProva.righe())
        }
        return scene
    }

    /// Posizioni › Portafoglio con la scena aperta: il ponte acceso o spento e, se ci sono, le righe del foglio
    /// arrivate dall'iPhone di prova (subito nello stato finale).
    nonisolated static func preparaInquadra(_ s: StatoShell, ponte: Bool = true, righe: [RigaLetta]? = nil) {
        s.dati.impostazioni.vera.ponte.condividi = ponte
        if ponte, !s.dati.impostazioni.vera.ponte.abbinato { s.dati.impostazioni.vera.ponte.codice = PonteVera.nuovoCodice() }
        s.posizioneInDettaglio = nil
        s.portafoglio = true
        s.provaFuoco.vista = .portafoglio
        s.apriApp(.posizioni)
        s.apriInquadra()
        if let righe {
            s.inquadra.mostra(righe: righe, origine: "iPhone di prova", subito: true)
        }
    }
}
#endif
