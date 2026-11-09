#if os(macOS)
import Foundation

/// Le istantanee di Sala › Il Prisma del cliente (giro 15 di «Luce», §2.1.3 e §6 del piano), tutte nello stato finale
/// (`\.modoIstantanea`: nome intero, onde ferme a metà, anelli pieni, linea tracciata):
/// - 620: Giulia, voci del template (posizioni spente), stato iniziale, password nascosta (chiaro e scuro);
/// - 621: la tile verde «✓ Il-Prisma-di-Giulia.pdf · … · protetto con la password» (chiaro e scuro);
/// - 622: Andrea senza data di nascita, senza obiettivi, senza lettera né film: voci spente con i motivi (chiaro e scuro);
/// - 623: la password mostrata.
/// DATI DI PROVA DICHIARATI (solo dentro queste scene, lo stato non si salva): un film del piano esportato di Giulia (un
/// Documento senza file), la password di prova «Lago-Vela-Pino-27» (mai una password vera) e la dimensione della tile
/// pronta (`TileFilePronto.dimensioneDiProva`). Andrea nei dati di prova ha la data di nascita: la scena la toglie.
extension Istantanee {
    nonisolated static var sceneSalaPrismaCliente: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("620-sala-prisma-cliente") { s in
            preparaScenaPrismaCliente(s)
            s.apriEsperienza(.prismaCliente, cliente: "giulia")
        }
        coppia("621-sala-prisma-cliente-file-pronto") { s in
            preparaScenaPrismaCliente(s)
            s.sala.provaUscite.prismaFilePronto = true
            s.apriEsperienza(.prismaCliente, cliente: "giulia")
        }
        coppia("622-sala-prisma-cliente-dati-mancanti") { s in
            s.sala.provaUscite.passwordDiProva = passwordDiProvaPrisma
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "andrea" }) { s.dati.clienti[i].dataNascita = nil }
            s.dati.obiettivi.removeAll { $0.clienteId == "andrea" }
            s.apriEsperienza(.prismaCliente, cliente: "andrea")
        }
        una("623-sala-prisma-cliente-password") { s in
            preparaScenaPrismaCliente(s)
            s.sala.provaUscite.prismaPasswordMostrata = true
            s.apriEsperienza(.prismaCliente, cliente: "giulia")
        }
        return scene
    }

    /// La password di prova delle istantanee (dichiarata, mai una password vera).
    nonisolated static let passwordDiProvaPrisma = "Lago-Vela-Pino-27"

    /// Dati di prova comuni: la password di prova e un film del piano esportato di Giulia (un Documento senza file).
    nonisolated static func preparaScenaPrismaCliente(_ s: StatoShell) {
        s.sala.provaUscite.passwordDiProva = passwordDiProvaPrisma
        if s.ultimoFilm(clienteId: "giulia") == nil {
            var film = Documento(clienteId: "giulia", titolo: "\(TestiUscite.titoloFilm) · dati di prova", tipo: .altro)
            film.lettura = .letto
            s.dati.documenti.append(film)
        }
    }
}
#endif
