#if os(macOS)
import SwiftUI

/// Le istantanee della parte comune di «Luce», giro 1 (Design/template-luce-specifica.md §0.6, §1.1.7, §1.2.7, §1.3.7,
/// §1.4.7), tutte nello stato finale (`\.modoIstantanea`):
/// - 614: il pannello «✦ Novità» a due gruppi (29 voci ferme, tre colonne), chiaro e scuro; 615: lo stesso con la
///   finestra di Prisma alla larghezza minima (1100);
/// - 616: la scrivania con il dock a 16 voci e i pulsanti «La tua settimana» e «Cerca ovunque», chiara e scura;
/// - 617: la tavola delle icone nell'ordine del dock su fondo chiaro e scuro (Pratiche e Incontri, Biblioteca e Clienti,
///   Sala e Vera a confronto, decisione 122); 619: la tavola dei 29 glifi nei tasselli;
/// - 618: le quattro finestre nuove con la testata e lo stato «in arrivo»;
/// - 690-694: la Sala (griglia, palco, senza cliente, in modalità cliente, presentazione sulla sala opaca).
/// I clienti sono quelli di prova del template (dati di prova): nessun dato nuovo nell'archivio.
extension Istantanee {
    /// La finestra di Prisma alla larghezza minima (`ShellView`: 1100 × 720).
    static let dimensioneStretta = CGSize(width: 1100, height: 720)

    nonisolated static var sceneLuce: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        // §1.1: il pannello delle novità
        coppia("614-novita-luce") { s in s.apriNovita() }
        una("615-novita-luce-stretta") { s in s.apriNovita() }
        // §1.2: la scrivania, le icone, le app nuove, i glifi
        coppia("616-scrivania-luce") { _ in }
        una("617-icone-luce") { _ in }
        una("618-app-nuove-territorio") { s in s.apriTerritorio(.oggi) }
        una("618-app-nuove-pratiche-scuro") { s in s.apriPratiche(.dopoLaFirma) }
        una("618-app-nuove-sala") { s in
            s.clienteAttivoId = "giulia"
            s.apri(.sala)
        }
        una("618-app-nuove-biblioteca-scuro") { s in s.apri(.biblioteca) }
        una("619-glifi-luce") { _ in }
        // §1.3: la Sala
        coppia("690-sala-griglia") { s in
            s.clienteAttivoId = "giulia"
            s.apri(.sala)
        }
        coppia("691-sala-palco") { s in
            s.apriEsperienza(.lettera, cliente: "giulia")
        }
        una("692-sala-senza-cliente") { s in
            s.dati.clienti.removeAll()
            s.apri(.sala)
        }
        una("693-sala-modo-cliente") { s in
            s.clienteAttivoId = "giulia"
            s.entraModoCliente(avviso: false)
            s.apri(.sala)
        }
        coppia("694-sala-presenta") { s in
            s.apriEsperienza(.prismaLuce, cliente: "giulia")
            s.presentaEsperienza(.prismaLuce)
        }
        return scene
    }

    /// Le scene che non sono la shell: le due tavole di controllo (icone e glifi).
    static func tavolaLuce(_ nome: String) -> AnyView? {
        switch nome {
        case "617-icone-luce": return AnyView(TavolaIconeLuce())
        case "619-glifi-luce": return AnyView(TavolaGlifiIstantanea())
        // «Luce» giro 5: il biglietto del traguardo da solo (IstantaneeTraguardi.swift)
        case "735-biglietto-traguardo": return tavolaBiglietto()
        default: return nil
        }
    }

    /// La misura della scena: alcune vogliono la finestra minima.
    static func misuraLuce(_ nome: String) -> CGSize? {
        // «Stanotte» (giro 14): la finestra stretta ma alta, perché il registro sotto i comandi stia nell'istantanea
        if nome == "766-notte-stretta" { return dimensioneStrettaAlta }
        return nome.hasSuffix("-stretta") ? dimensioneStretta : nil
    }

    /// La finestra alla larghezza minima ma alta (766: le carte della notte con il registro sotto i comandi).
    static let dimensioneStrettaAlta = CGSize(width: 1100, height: 1000)
}

/// Le icone nell'ordine del dock (Scrivania e le quindici app) su fondo chiaro e su fondo scuro.
private struct TavolaIconeLuce: View {
    private typealias T = Tema.Apple.TavoleLuce

    var body: some View {
        HStack(spacing: 0) {
            meta(scuro: false)
            meta(scuro: true)
        }
    }

    private func meta(scuro: Bool) -> some View {
        let app = AppPrisma.delDock
        let righe = stride(from: 0, to: app.count, by: T.colonneIcone).map { Array(app[$0..<min($0 + T.colonneIcone, app.count)]) }
        return VStack(alignment: .leading, spacing: T.spazio) {
            Text(scuro ? "Fondo scuro" : "Fondo chiaro")
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(scuro ? T.testoScuro : T.testoChiaro)
            ForEach(Array(righe.enumerated()), id: \.offset) { _, riga in
                HStack(alignment: .top, spacing: T.spazio) {
                    ForEach(riga) { a in
                        VStack(spacing: T.sottoIcona) {
                            IconaApp(app: a, lato: T.icona)
                            Text(a.nomeDock)
                                .carattereApple(Tema.Apple.Carattere.dock)
                                .foregroundColor(scuro ? T.testoScuro : T.testoChiaro)
                                .lineLimit(1)
                        }
                        .frame(width: T.cella)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(T.margine)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(scuro ? T.fondoScuro : T.fondoChiaro)
        .environment(\.colorScheme, scuro ? .dark : .light)
    }
}

/// La tavola dei glifi su fondo chiaro.
private struct TavolaGlifiIstantanea: View {
    private typealias T = Tema.Apple.TavoleLuce

    var body: some View {
        VStack(alignment: .leading, spacing: T.spazio) {
            Text("I 29 glifi di Luce")
                .carattereApple(Tema.Apple.Carattere.h2)
                .foregroundColor(T.testoChiaro)
            TavolaGlifiLuce(lato: Tema.Apple.Tassello.latoSalaGrande, colonne: T.colonneGlifi)
            Spacer(minLength: 0)
        }
        .padding(T.margine)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(T.fondoChiaro)
        .environment(\.colorScheme, .light)
    }
}
#endif
