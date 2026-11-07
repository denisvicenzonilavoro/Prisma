#if os(macOS)
import Foundation
import CoreGraphics

/// Le istantanee della Sala, giro 4 di «Luce» (Design/template-luce-specifica.md §2.2.7 e §3.3.7), tutte nello stato
/// finale (`\.modoIstantanea`): il prisma di luce con `PrismaDiLuceFermo` (niente Metal), «Disegna il tuo futuro» con
/// il tratto di prova già trasformato.
/// - 624: Giulia, per investimento, oggi (chiaro e scuro: il palco è notte in tutti e due);
/// - 625: per obiettivo; 626: per canale, con le etichette del canale (Giulia ha tutti e due i canali);
/// - 627: Azionario scelto (pannello con la cifra, altre etichette attenuate); 628: fra vent'anni;
/// - 629: cliente senza posizioni in essere (cristallo spento);
/// - 649: la tela vuota con l'invito (chiaro e scuro); 650: il tratto di prova sopra il piano (chiaro e scuro);
/// - 651: il tratto di prova sotto il piano, «già alla portata»; 652: Andrea senza data di nascita.
/// DATI DI PROVA DICHIARATI: i tratti di `DisegnoDiProva`; le cifre le calcolano MotoreLuce e MotoreDisegno.
extension Istantanee {
    nonisolated static var sceneSalaGiro4: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        func luce(_ s: StatoShell, cliente: String = "giulia", _ prova: ProvaLuce = ProvaLuce()) {
            s.sala.provaLuce = prova
            s.apriEsperienza(.prismaLuce, cliente: cliente)
        }
        func disegna(_ s: StatoShell, cliente: String = "giulia", _ tratto: [CGPoint]?) {
            s.sala.provaDisegno = tratto
            s.apriEsperienza(.disegna, cliente: cliente)
        }
        // §2.2.7: il prisma di luce
        coppia("624-sala-luce") { s in luce(s) }
        una("625-sala-luce-obiettivi") { s in luce(s, ProvaLuce(vista: .obiettivo)) }
        una("626-sala-luce-canale") { s in luce(s, ProvaLuce(vista: .canale)) }
        una("627-sala-luce-raggio-scelto") { s in luce(s, ProvaLuce(scelta: "Azionario")) }
        una("628-sala-luce-fra-vent-anni") { s in luce(s, ProvaLuce(fraVentAnni: true)) }
        una("629-sala-luce-vuota") { s in
            s.dati.posizioni.removeAll { $0.clienteId == "giulia" && $0.stato == .inEssere }
            luce(s)
        }
        // §3.3.7: disegna il tuo futuro
        coppia("649-sala-disegna-vuota") { s in disegna(s, nil) }
        coppia("650-sala-disegna-risultato") { s in disegna(s, DisegnoDiProva.sopraIlPiano) }
        una("651-sala-disegna-alla-portata") { s in disegna(s, DisegnoDiProva.sottoIlPiano) }
        una("652-sala-disegna-dati-mancanti") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "andrea" }) { s.dati.clienti[i].dataNascita = nil }
            disegna(s, cliente: "andrea", nil)
        }
        return scene
    }
}
#endif
