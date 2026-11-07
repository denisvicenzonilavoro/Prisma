#if os(iOS)
import Foundation

/// La prova del dock di iPhone e iPad (`--prova-dock`, esito in Documents/esito-prova-dock.txt come le altre prove):
/// - il lato delle icone di `fitDock` resta fra il minimo e il massimo e il dock sta nello schermo meno 12 punti,
///   alle larghezze vere di iPhone (6 elementi) e iPad (13 elementi: Scrivania, le 11 app del dock dell'iPad e
///   «Tutte le app», verticale e orizzontale);
/// - i nomi sotto le icone ci sono solo sull'iPad dove ci stanno (orizzontale e verticale da 834): non sull'iPhone
///   (dock compatto, Design/iphone.html) né sull'iPad mini in verticale;
/// - il dock dell'iPhone e «Tutte le app» insieme hanno tutte le app, ognuna una volta; il dock dell'iPad ha le app
///   del dock del Mac fino a Prospetti più Sala e Vera (versione «Luce», decisione 121), nello stesso ordine; in modo
///   cliente solo quelle consentite.
@MainActor
enum ProvaDockMobile {
    private typealias D = Tema.Misura.Mobile.Dock

    static func esegui() -> Int32 {
        var errori: [String] = []
        func verifica(_ nome: String, _ ok: Bool) {
            print("\(ok ? "OK    " : "ERRORE") \(nome)")
            if !ok { errori.append(nome) }
        }

        // 6 elementi: Scrivania, Clienti, Posizioni, Agenda, Attività, Tutte le app
        let telefono = DisposizioneDockMobile.appTelefono.count + 2
        // 13 elementi: Scrivania, le 11 app del dock dell'iPad e «Tutte le app»
        let iPad = DisposizioneDockMobile.appiPad.count + 2
        verifica("il dock dell'iPad ha 11 app (\(DisposizioneDockMobile.appiPad.count))", DisposizioneDockMobile.appiPad.count == 11)
        let casi: [(CGFloat, Int, CGFloat)] = [
            (375, telefono, D.massimoTelefono), (393, telefono, D.massimoTelefono),
            (402, telefono, D.massimoTelefono), (440, telefono, D.massimoTelefono),
            (744, iPad, D.massimoiPad), (834, iPad, D.massimoiPad), (1032, iPad, D.massimoiPad),
            (1210, iPad, D.massimoiPad), (1376, iPad, D.massimoiPad),
        ]
        for (w, n, massimo) in casi {
            let lato = DisposizioneDockMobile.lato(elementi: n, larghezza: w, massimo: massimo)
            let larghezza = DisposizioneDockMobile.larghezza(elementi: n, lato: lato)
            verifica("lato fra \(D.minimo) e \(massimo) a \(Int(w)) pt (\(n) elementi): \(lato)", lato >= D.minimo && lato <= massimo)
            verifica("dock largo \(Int(larghezza.rounded())) ≤ \(Int(w - D.bordo)) a \(Int(w)) pt", larghezza <= w - D.bordo)
        }
        func nomi(_ w: CGFloat, _ n: Int, _ massimo: CGFloat, _ stile: StileDockMobile = .iPad) -> Bool {
            DisposizioneDockMobile.conNomi(lato: DisposizioneDockMobile.lato(elementi: n, larghezza: w, massimo: massimo), stile: stile)
        }
        verifica("niente nomi sotto le icone sull'iPhone (393): dock compatto", !nomi(393, telefono, D.massimoTelefono, .telefono))
        verifica("nomi sotto le icone sull'iPad in orizzontale (1376)", nomi(1376, iPad, D.massimoiPad))
        // Con 13 elementi (versione «Orizzonte») sull'iPad in verticale le icone restano a 50 e i nomi ci stanno
        verifica("nomi sotto le icone sull'iPad in verticale (834)", nomi(834, iPad, D.massimoiPad))
        verifica("niente nomi sull'iPad mini in verticale (744)", !nomi(744, iPad, D.massimoiPad))

        // Dock dell'iPhone + «Tutte le app» = tutte le app, ognuna una volta (in «Tutte le app» ci sono tutte)
        let tutte = Set(AppPrisma.allCases)
        let nelDock = DisposizioneDockMobile.app(.telefono, consentita: { _ in true })
        verifica("il dock dell'iPhone non ripete le app", Set(nelDock).count == nelDock.count)
        verifica("il dock dell'iPhone ha solo app di Prisma", Set(nelDock).isSubset(of: tutte))
        let dockiPad = DisposizioneDockMobile.app(.iPad, consentita: { _ in true })
        verifica("il dock dell'iPad ha le app del dock del Mac fino a Prospetti, più Sala e Vera, nello stesso ordine",
                 dockiPad == [.clienti, .posizioni, .analisi360, .incontri, .agenda, .territorio, .messaggi, .pratiche,
                              .presentazioni, .sala, .vera])
        verifica("il dock dell'iPad ha solo app del dock del Mac, senza ripetizioni",
                 Set(dockiPad).isSubset(of: Set(AppPrisma.delDock)) && Set(dockiPad).count == dockiPad.count)
        verifica("le app del Mac che non stanno nel dock dell'iPad sono in «Tutte le app»",
                 Set(AppPrisma.delDock).subtracting(dockiPad) == Set<AppPrisma>([.biblioteca, .mercato, .studio, .impostazioni]))

        // In modo cliente solo le app consentite (Note, Ricerca, Impostazioni, Territorio e Pratiche no)
        let consentita: (AppPrisma) -> Bool = { !StatoShell.appRiservate.contains($0) }
        let telefonoCliente = DisposizioneDockMobile.app(.telefono, consentita: consentita)
        let iPadCliente = DisposizioneDockMobile.app(.iPad, consentita: consentita)
        verifica("modo cliente: niente app riservate nel dock dell'iPhone",
                 telefonoCliente.allSatisfy(consentita))
        verifica("modo cliente: niente app riservate nel dock dell'iPad",
                 Set(iPadCliente) == Set(dockiPad).subtracting(StatoShell.appRiservate)
                 && !iPadCliente.contains(.territorio) && !iPadCliente.contains(.pratiche) && iPadCliente.contains(.sala))

        if errori.isEmpty {
            print("Prova del dock: tutto a posto")
            return 0
        }
        print("Prova del dock: \(errori.count) errori: \(errori.joined(separator: "; "))")
        return 1
    }
}
#endif
