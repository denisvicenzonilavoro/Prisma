#if os(iOS)
import SwiftUI

/// La scrivania dell'iPhone nel tema Apple (Design/iphone.html, schermata 1): sotto la barra, sull'acqua, la data e
/// il saluto; poi i riquadri di vetro uno per riga, in ordine di importanza: la mossa del giorno in grande (con il
/// prossimo incontro sotto), «Richiede attenzione», la riga di Vera con la sfera e il portafoglio con i tre anelli;
/// in fondo il piede. Comincia sotto la barra e scorre sotto il dock. I riquadri entrano a cascata (base 0,12 della
/// scrivania), scendono a 0,98 alla pressione e aprono le app con `mobile.apri` dal punto toccato (`misuraOrigine`):
/// StatoMobile porta l'app nella finestra di vetro. Con «Riduci movimento» e nelle istantanee tutto è già fermo.
struct ScrivaniaTelefono: View {
    /// Dove comincia la scrivania (sotto la barra) e quanto lasciare in basso (il dock).
    let alto: CGFloat
    let basso: CGFloat
    /// Solo istantanee: la scrivania parte già scorsa fino al piede.
    var inFondo = false

    @EnvironmentObject var stato: StatoShell
    @EnvironmentObject var mobile: StatoMobile

    private typealias S = Tema.Apple.Telefono.Scrivania

    /// L'ancora del piede (istantanee in fondo alla scrivania).
    static let ancoraPiede = "piede"
    static let attesaInFondo: Double = 0.3

    var body: some View {
        ScrollViewReader { lettore in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    introduzione
                        .entrataCascata(0, base: S.baseCascata)
                    bacheca
                    piede
                    // Lo spazio del dock, in fondo: la scrivania scorre fino a mostrare il piede sopra il dock
                    Color.clear
                        .frame(height: basso)
                        .id(Self.ancoraPiede)
                }
                .padding(.horizontal, S.margine)
                .padding(.top, S.salutoSopra)
                // Un tocco sul fondo libero fa cadere una goccia (dentro lo scorrimento: la ScrollView prende tutto il riquadro)
                .gocciaAlTocco()
            }
            // Come .desk del tema: comincia sotto la barra (lì si taglia) e scorre sotto il dock
            .onAppear {
                guard inFondo else { return }
                // A impaginazione fatta: prima la ScrollView non sa ancora dov'è il piede
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.attesaInFondo) {
                    lettore.scrollTo(Self.ancoraPiede, anchor: .bottom)
                }
            }
        }
        .padding(.top, alto)
        // Le etichette del canale nello stile del tema Apple
        .superficiApple()
    }

    /// In alto, sull'acqua: la data e il saluto (Design/iphone.html). Cerca e le app aperte stanno nella barra e nel dock.
    private var introduzione: some View {
        TimelineView(.everyMinute) { contesto in
            VStack(alignment: .leading, spacing: S.spazioSaluto) {
                Text(Self.data(contesto.date))
                    .carattereApple(S.data)
                    .foregroundColor(S.coloreData)
                    .lineLimit(1)
                Text(SalutoScrivaniaMobile.saluto(contesto.date, nome: stato.nomeUtente))
                    .carattereApple(S.saluto)
                    .foregroundColor(S.coloreSaluto)
                    .lineLimit(1)
                    .minimumScaleFactor(S.riduzioneSaluto)
            }
        }
        .aloneSfondo()
        .padding(.horizontal, S.salutoLato)
        .padding(.bottom, S.salutoSotto)
    }

    /// «Martedì 3 novembre»: la data lunga con l'iniziale maiuscola.
    private static func data(_ d: Date) -> String {
        let testo = Formati.dataLunga.string(from: d)
        return testo.prefix(1).uppercased() + testo.dropFirst()
    }

    /// I riquadri a una colonna, in ordine di importanza; i vetri campionati insieme. Entrano senza sfocatura: il
    /// vetro è dentro il riquadro (come i widget del Mac allo sblocco).
    private var bacheca: some View {
        VStack(spacing: S.spazio) {
            RiquadroMossaTelefono()
                .entrataCascata(1, base: S.baseCascata, sfocatura: false)
            RiquadroAttenzioneTelefono()
                .entrataCascata(2, base: S.baseCascata, sfocatura: false)
            RiquadroVeraTelefono()
                .entrataCascata(3, base: S.baseCascata, sfocatura: false)
            RiquadroPortafoglioTelefono()
                .entrataCascata(4, base: S.baseCascata, sfocatura: false)
        }
        .gruppoVetro()
    }

    /// Il piede: le due frasi una sotto l'altra, sull'acqua.
    private var piede: some View {
        VStack(alignment: .leading, spacing: S.spazioPiede) {
            Text("Un tocco per entrare. Il dock per cambiare app.")
            Text(PiedeScrivaniaMobile.backup(stato))
        }
        .carattereApple(S.piede)
        .foregroundColor(S.colorePiede)
        .fixedSize(horizontal: false, vertical: true)
        .aloneSfondo()
        .padding(.horizontal, S.salutoLato)
        .padding(.top, S.piedeSopra)
    }
}

/// Il saluto della scrivania (.hero h1 e p): «Buongiorno, Denis.» sull'acqua, aggiornato ogni minuto (solo lui).
struct SalutoScrivaniaMobile: View {
    @EnvironmentObject var stato: StatoShell
    let carattere: Font
    let spaziatura: CGFloat
    /// «Tutto il tuo lavoro, a portata di mano.» sotto il saluto (sull'iPhone c'è la data sopra, al suo posto).
    var sottotitolo = true

    var body: some View {
        VStack(alignment: .leading, spacing: Tema.Misura.Shell.salutoSpazio) {
            TimelineView(.everyMinute) { contesto in
                Text(Self.saluto(contesto.date, nome: stato.nomeUtente))
                    .font(carattere)
                    .tracking(spaziatura)
                    .foregroundColor(Tema.Colore.inchiostroSfondo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            if sottotitolo {
                Text("Tutto il tuo lavoro, a portata di mano.")
                    .font(Tema.Testo.sottotitoloSaluto)
                    .foregroundColor(Tema.Colore.inchiostroSfondoSecondario)
            }
        }
        .aloneSfondo()
    }

    /// Lo stesso saluto della scrivania del Mac: prima delle 13 buongiorno, prima delle 18 buon pomeriggio.
    static func saluto(_ ora: Date, nome: String) -> String {
        let h = Calendar.current.component(.hour, from: ora)
        let s = h < 13 ? "Buongiorno" : h < 18 ? "Buon pomeriggio" : "Buonasera"
        return "\(s), \(nome)."
    }
}

/// Quante app sono aperte: osserva solo le finestre, così la scrivania non si ricalcola quando si apre un'app.
struct TestoAppAperteMobile: View {
    @EnvironmentObject var sistema: StatoFinestre

    var body: some View {
        Text(testo)
    }

    private var testo: String {
        switch sistema.elenco.count {
        case 0: return "Nessuna app aperta"
        case 1: return "1 app aperta"
        default: return "\(sistema.elenco.count) app aperte"
        }
    }
}

/// Il testo del piede della scrivania (.foot): l'ultimo backup, come sul Mac.
enum PiedeScrivaniaMobile {
    static func backup(_ stato: StatoShell) -> String {
        stato.dati.impostazioni.backup.ultimo.map { "Ultimo backup: \(Formati.dataOra.string(from: $0)) · archivio locale" }
            ?? "Nessun backup ancora · archivio locale"
    }
}
#endif
