import SwiftUI

// La Sala della versione «Luce» (Design/template-luce-specifica.md §1.3): la cornice comune delle 11 esperienze.
//
//   La sala.  LE ESPERIENZE DA VIVERE CON IL CLIENTE                 (Giulia)(Marco)(Laura)(Andrea)(Sofia)
//   ┌────────────────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐
//   │ ▣              ││ luce ││letter││ film ││disegn││rischi│
//   │ Ciao Giulia.   │└──────┘└──────┘└──────┘└──────┘└──────┘
//   │ ◯ ◯ ◯          │┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐
//   │ Il Prisma del… ││giorna││ dadi ││valore││capsul││  AR  │
//   └────────────────┘└──────┘└──────┘└──────┘└──────┘└──────┘
//
// - Griglia `1.35fr repeat(5,1fr)` su due righe: la scheda grande del Prisma del cliente (saluto e anelli dei primi tre
//   obiettivi del cliente attivo) e le dieci schede piccole. Le schede si inclinano verso il puntatore (4° e 7°) ed
//   entrano a cascata; gli anelli si riempiono.
// - Un clic su una scheda apre il palco: la card nasce dalla scheda (`matchedGeometryEffect`, decisione 124) e ci torna
//   con «‹ Sala» o con Esc (decisione 125: Esc dal palco torna alla griglia, dalla griglia chiude la finestra).
// - Nel palco: «‹ Sala», il tassello, il nome dell'esperienza e il cliente; a destra «Mostra sul tavolo», «Aggiungi al
//   Prisma di …» (dove servono) e «Presenta» (la sala opaca in modalità cliente, decisione 123). Nel giro 1 nessuna
//   esperienza è ancora fatta: il palco dice «Arriva con un prossimo aggiornamento» e i due pulsanti dell'esperienza
//   sono spenti.
// - Stati: nessun cliente («Ciao.» e «Scegli un cliente per iniziare», schede spente, un clic porta a Clienti); cliente
//   senza obiettivi (una frase, mai anelli inventati); meno di tre obiettivi (tanti anelli quanti sono).
// - «Riduci movimento»: niente inclinazione né crescita dalla scheda, la dissolvenza di 0,15 s. Istantanee: anelli
//   pieni, palco già entrato.

/// Il contenuto della finestra della Sala.
struct AppSala: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        CorpoSala(sala: stato.sala)
    }
}

/// Le pillole dei clienti nella testata della Sala: in modalità cliente (e nella presentazione) solo il cliente presente
/// (decisione 2 del §1.3.8); fuori, come in Analisi 360.
struct AzioniSala: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        let t = Tema.Apple.Aree360.Testata.self
        if stato.clienti.count > 0 {
            let varianti = PilloleClienti.varianti(stato.clienti, attivo: stato.clienteAttivo,
                                                   numeri: [t.pilloleMassime, t.pilloleMassime - 1, t.pilloleMinime])
            PilloleClienti(lunga: varianti[0], media: varianti[1], corta: varianti[2],
                           scelto: stato.clienteAttivoId, scegli: { stato.clienteAttivoId = $0 })
                .equatable()
        }
    }
}

private struct CorpoSala: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var sala: StatoSala
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Namespace private var spazio

    var body: some View {
        let cliente = stato.clienteAttivo
        ZStack(alignment: .topLeading) {
            if let e = sala.esperienza, let cliente {
                PalcoSala(esperienza: e, cliente: cliente, spazio: spazio, torna: torna)
                    .transition(.opacity)
            } else {
                GrigliaSala(cliente: cliente, spazio: spazio, apri: apri)
                    .transition(.opacity)
            }
            EscSala(sistema: stato.sistema, palco: sala.esperienza != nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Dalla scheda al palco: la card cresce dalla scheda toccata (senza movimento con «Riduci movimento»).
    private func apri(_ e: EsperienzaSala) {
        guard stato.clienteAttivo != nil else {
            stato.apri(.clienti)
            return
        }
        let m = Tema.Apple.Moto.SalaEsperienze.self
        if istantanea {
            sala.esperienza = e
        } else {
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : m.passaggio) { sala.esperienza = e }
        }
    }

    /// Dal palco alla griglia: la card torna nella sua scheda.
    private func torna() {
        let m = Tema.Apple.Moto.SalaEsperienze.self
        if istantanea {
            stato.tornaAllaSala()
        } else {
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : m.ritorno) { stato.tornaAllaSala() }
        }
    }
}

/// Esc nella Sala: dal palco torna alla griglia, dalla griglia chiude la finestra. Solo con la Sala davanti e nessun
/// pannello o sovrapposizione sopra (che hanno il loro Esc). Osserva le finestre a parte: la Sala non si ridisegna.
private struct EscSala: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var sistema: StatoFinestre
    let palco: Bool

    var body: some View {
        let libera = sistema.appAttiva == .sala && !sistema.pannelloNovita && sistema.sovrapposizione == nil
            && !sistema.pannelloNotifiche && !sistema.pannelloRicerca && sistema.guida == nil && !sistema.bloccato
            && stato.presentazione == nil
        if libera {
            Button(palco ? "Torna alla Sala" : "Chiudi la Sala") {
                if palco {
                    withAnimation(Tema.Apple.Moto.SalaEsperienze.ritorno) { stato.tornaAllaSala() }
                } else {
                    stato.chiudi(.sala)
                }
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(StileSemplice())
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - La griglia

private struct GrigliaSala: View {
    let cliente: Cliente?
    let spazio: Namespace.ID
    let apri: (EsperienzaSala) -> Void

    private typealias G = Tema.Apple.SalaEsperienze.Griglia

    var body: some View {
        GeometryReader { geo in
            let colonne = CGFloat(G.colonne)
            let unita = max(0, (geo.size.width - colonne * G.spazio) / (G.quotaPrima + colonne))
            let piccole = EsperienzaSala.piccole
            let righe = stride(from: 0, to: piccole.count, by: G.colonne).map { Array(piccole[$0..<min($0 + G.colonne, piccole.count)]) }
            HStack(alignment: .top, spacing: G.spazio) {
                SchedaGrandeSala(cliente: cliente, spazio: spazio, apri: apri)
                    .frame(width: unita * G.quotaPrima)
                    .entrataCascata(0)
                VStack(spacing: G.spazio) {
                    ForEach(Array(righe.enumerated()), id: \.offset) { r, riga in
                        HStack(spacing: G.spazio) {
                            ForEach(Array(riga.enumerated()), id: \.element) { c, e in
                                SchedaPiccolaSala(esperienza: e, spenta: cliente == nil, spazio: spazio, apri: apri)
                                    .frame(width: unita)
                                    .entrataCascata(1 + r * G.colonne + c)
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }
}

/// La scheda grande «Il Prisma del cliente»: il saluto e gli anelli dei primi tre obiettivi del cliente attivo.
private struct SchedaGrandeSala: View {
    @EnvironmentObject var stato: StatoShell
    let cliente: Cliente?
    let spazio: Namespace.ID
    let apri: (EsperienzaSala) -> Void

    private typealias S = Tema.Apple.SalaEsperienze.Scheda

    var body: some View {
        let e = EsperienzaSala.prismaCliente
        Button { apri(e) } label: {
            VStack(alignment: .leading, spacing: 0) {
                TasselloGlifo(glifo: e.glifo, lato: S.tasselloGrande, raggio: S.raggioTassello)
                Text(cliente.map { "Ciao \(StatoShell.nomeBreve($0))." } ?? "Ciao.")
                    .carattereApple(S.saluto)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, S.sottoTassello)
                Text(cliente == nil ? "Scegli un cliente per iniziare" : "Il tuo piano, sempre con te.")
                    .carattereApple(S.sottotitolo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(2)
                if let cliente {
                    anelli(cliente)
                        .padding(.top, S.sopraAnelli)
                }
                Spacer(minLength: S.sopraAnelli)
                Text(e.titolo)
                    .carattereApple(S.titoloGrande)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(2)
                Text(e.frase)
                    .carattereApple(S.fraseGrande)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(S.righeFrase)
                    .padding(.top, S.sopraFrase)
            }
            .multilineTextAlignment(.leading)
            .padding(S.paddingGrande)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .matchedGeometryEffect(id: e.id, in: spazio, isSource: true)
            .superficieApple(S.superficie, raggio: S.raggio)
            .clipShape(RoundedRectangle(cornerRadius: S.raggio, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: S.raggio, style: .continuous))
        }
        .buttonStyle(StileSemplice())
        .inclinazione(massimo: Tema.Apple.Moto.Inclinazione.massimoSalaGrande, raggio: S.raggio)
        .help(cliente == nil ? "Scegli prima un cliente in Clienti" : "Apri «\(e.titolo)»")
        .accessibilityLabel(Text("\(e.titolo): \(e.frase)"))
    }

    /// I primi tre obiettivi: quanto è già da parte rispetto al traguardo (decisione 81), mai anelli inventati.
    @ViewBuilder private func anelli(_ c: Cliente) -> some View {
        let obiettivi = Array(stato.obiettiviCliente(c.id).prefix(S.massimoAnelli))
        if obiettivi.isEmpty {
            Text("Nessun obiettivo ancora: aggiungilo nel dossier")
                .carattereApple(S.etichettaAnello)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .lineLimit(2)
        } else {
            let posizioni = stato.posizioniCliente(c.id)
            HStack(alignment: .top, spacing: S.spazioAnelli) {
                ForEach(Array(obiettivi.enumerated()), id: \.element.id) { i, o in
                    let esito = MotoreObiettivo.calcola(o, posizioni: posizioni)
                    let frazione = o.importo > 0 ? min(1, max(0, esito.disponibileOggi / o.importo)) : 0
                    VStack(spacing: S.sopraEtichetta) {
                        Anello(frazione: frazione, colore: S.coloriAnelli[i % S.coloriAnelli.count], misura: S.anello,
                               spessore: S.trattoAnello, ritardo: Tema.Apple.Moto.Anello.ritardo(indice: i, base: Tema.Apple.Moto.Anello.ritardoFinestra)) {
                            Text("\(Int((frazione * 100).rounded()))%")
                                .carattereApple(S.centroAnello)
                                .foregroundColor(Tema.Apple.Colore.inchiostro)
                        }
                        Text(o.titolo)
                            .carattereApple(S.etichettaAnello)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                            .lineLimit(1)
                            .frame(maxWidth: S.larghezzaEtichetta)
                    }
                }
            }
        }
    }
}

/// Una delle dieci schede piccole: il tassello in alto, in fondo il titolo e la frase.
private struct SchedaPiccolaSala: View {
    let esperienza: EsperienzaSala
    let spenta: Bool
    let spazio: Namespace.ID
    let apri: (EsperienzaSala) -> Void

    private typealias S = Tema.Apple.SalaEsperienze.Scheda

    var body: some View {
        Button { apri(esperienza) } label: {
            VStack(alignment: .leading, spacing: 0) {
                TasselloGlifo(glifo: esperienza.glifo, lato: S.tassello, raggio: S.raggioTassello)
                Spacer(minLength: S.sopraFrase)
                Text(esperienza.titolo)
                    .carattereApple(S.titolo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(2)
                Text(esperienza.frase)
                    .carattereApple(S.frase)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(S.righeFrase)
                    .padding(.top, S.sopraFrase)
            }
            .multilineTextAlignment(.leading)
            .padding(S.paddingPiccola)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .matchedGeometryEffect(id: esperienza.id, in: spazio, isSource: true)
            .superficieApple(S.superficie, raggio: S.raggio)
            .clipShape(RoundedRectangle(cornerRadius: S.raggio, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: S.raggio, style: .continuous))
            .opacity(spenta ? S.opacitaSpenta : 1)
        }
        .buttonStyle(StileSemplice())
        .inclinazione(massimo: Tema.Apple.Moto.Inclinazione.massimoSala, raggio: S.raggio, attiva: !spenta)
        .help(spenta ? "Scegli prima un cliente in Clienti" : "Apri «\(esperienza.titolo)»")
        .accessibilityLabel(Text("\(esperienza.titolo): \(esperienza.frase)"))
    }
}

// MARK: - Il palco

private struct PalcoSala: View {
    @EnvironmentObject var stato: StatoShell
    let esperienza: EsperienzaSala
    let cliente: Cliente
    let spazio: Namespace.ID
    let torna: () -> Void

    private typealias P = Tema.Apple.SalaEsperienze.Palco

    var body: some View {
        VStack(alignment: .leading, spacing: P.dallAlto - P.altezzaTestata) {
            testata
                .frame(height: P.altezzaTestata)
                .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            ContenutoPalco(esperienza: esperienza, cliente: cliente)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .matchedGeometryEffect(id: esperienza.id, in: spazio, isSource: false)
                .superficieApple(Tema.Apple.SalaEsperienze.Scheda.superficie, raggio: Tema.Apple.SalaEsperienze.Scheda.raggio)
                .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.SalaEsperienze.Scheda.raggio, style: .continuous))
        }
    }

    private var testata: some View {
        let nome = StatoShell.nomeBreve(cliente)
        return HStack(spacing: P.spazioTestata) {
            Button { torna() } label: { Text("‹ Sala") }
                .buttonStyle(.apple)
                .help("Torna alla griglia delle esperienze (esc)")
            TasselloGlifo(glifo: esperienza.glifo, lato: P.tassello, raggio: P.raggioTassello)
            HStack(alignment: .firstTextBaseline, spacing: P.spazioPulsanti) {
                Text(esperienza.titolo)
                    .carattereApple(P.nome)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text("· \(cliente.nome)")
                    .carattereApple(P.cliente)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            .lineLimit(1)
            Spacer(minLength: P.spazioTestata)
            HStack(spacing: P.spazioPulsanti) {
                // Il tavolo e il Prisma del cliente non sono ancora pronti per nessuna esperienza (decisioni 7 e 111):
                // i pulsanti restano spenti anche dove l'esperienza c'è già
                if esperienza.mostraSulTavolo {
                    Button { } label: { Text("▣ Mostra sul tavolo") }
                        .buttonStyle(.apple)
                        .disabled(true)
                        .help(esperienza.disponibile ? "Sull'iPad del tavolo: arriva con un prossimo aggiornamento"
                              : "Sull'iPad del tavolo: arriva insieme all'esperienza")
                }
                if esperienza.aggiungeAlPrisma {
                    Button { } label: { Text("✦ Aggiungi al Prisma di \(nome)") }
                        .buttonStyle(.apple)
                        .disabled(true)
                        .help(esperienza.disponibile ? "Nel file personale del cliente: arriva con il Prisma del cliente. Prisma non manda nulla da solo"
                              : "Nel file personale del cliente: arriva insieme all'esperienza. Prisma non manda nulla da solo")
                }
                Button { stato.presentaEsperienza(esperienza) } label: { Text("▶︎ Presenta") }
                    .buttonStyle(.applePrimario)
                    .help("Mostra l'esperienza a tutto schermo, in modalità cliente")
            }
            .fixedSize()
        }
    }
}

/// Dentro la card del palco: la vista dell'esperienza. Finché un'esperienza non c'è, lo stato «in arrivo».
struct ContenutoPalco: View {
    let esperienza: EsperienzaSala
    let cliente: Cliente

    var body: some View {
        // Ogni giro aggiunge qui la sua esperienza
        switch esperienza {
        case .prismaLuce: PalcoLuce(cliente: cliente)               // giro 4, Shell/SalaLuce.swift
        case .disegna: DisegnaIlFuturo(cliente: cliente)            // giro 4, Shell/SalaDisegna.swift
        default: InArrivoEsperienza(esperienza: esperienza)
        }
    }
}

/// «Arriva con un prossimo aggiornamento»: il tassello grande, il nome, la frase e la nota.
struct InArrivoEsperienza: View {
    let esperienza: EsperienzaSala
    /// Sulla sala opaca della presentazione (testi bianchi, misure grandi).
    var inSala = false

    var body: some View {
        let p = Tema.Apple.SalaEsperienze.Palco.self
        let s = Tema.Apple.SalaEsperienze.Presenta.self
        VStack(spacing: inSala ? s.spazio : p.spazioInArrivo) {
            TasselloGlifo(glifo: esperienza.glifo, lato: inSala ? s.tassello : p.tasselloInArrivo,
                          raggio: inSala ? s.raggioTassello : Tema.Apple.SalaEsperienze.Scheda.raggioTassello)
            Text(esperienza.titolo)
                .carattereApple(inSala ? s.titolo : p.titoloInArrivo)
                .foregroundColor(inSala ? s.coloreTitolo : Tema.Apple.Colore.inchiostro)
            Text(esperienza.frase)
                .carattereApple(inSala ? s.testo : p.testoInArrivo)
                .foregroundColor(inSala ? s.coloreTesto : Tema.Apple.Colore.inchiostro2)
            Text("Arriva con un prossimo aggiornamento.")
                .carattereApple(inSala ? s.testo : p.testoInArrivo)
                .foregroundColor(inSala ? s.coloreTesto : Tema.Apple.Colore.inchiostro2)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: inSala ? s.larghezzaTesto : p.larghezzaInArrivo)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - La presentazione

/// «▶︎ Presenta»: l'esperienza a tutta finestra sopra la sala opaca dei Prospetti (sempre scura), con il nome del
/// cliente in alto e «Chiudi» bianco in basso. Esc la chiude. Sotto il velo l'acqua si ferma (`scrivaniaCoperta`).
struct VistaPresentazioneEsperienza: View {
    @EnvironmentObject var stato: StatoShell
    let esperienza: EsperienzaSala

    var body: some View {
        let s = Tema.Apple.SalaEsperienze.Presenta.self
        ZStack {
            s.velo
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
            VStack(spacing: 0) {
                Text((stato.clienteAttivo?.nome ?? "").uppercased())
                    .carattereApple(s.cliente)
                    .foregroundColor(s.coloreCliente)
                    .lineLimit(1)
                    .frame(height: s.margine)
                if esperienza.disponibile, let cliente = stato.clienteAttivo {
                    // L'esperienza vera, nella sua card scura
                    ContenutoPalco(esperienza: esperienza, cliente: cliente)
                        .superficieApple(Tema.Apple.SalaEsperienze.Scheda.superficie, raggio: Tema.Apple.SalaEsperienze.Scheda.raggio)
                        .clipShape(RoundedRectangle(cornerRadius: Tema.Apple.SalaEsperienze.Scheda.raggio, style: .continuous))
                        .environment(\.colorScheme, .dark)
                } else {
                    InArrivoEsperienza(esperienza: esperienza, inSala: true)
                        .environment(\.colorScheme, .dark)
                }
                HStack {
                    Spacer()
                    Button("Chiudi") { stato.chiudiSovrapposizione() }
                        .buttonStyle(StileCapsulaSalaApple(chiara: true))
                        .keyboardShortcut(.cancelAction)
                        .help("Chiudi la presentazione (esc)")
                    Spacer()
                }
                .frame(height: s.altezzaComandi)
                .padding(.top, s.sopraComandi)
                .padding(.bottom, s.comandiFondo)
            }
            .padding(.horizontal, s.margine)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Presentazione: \(esperienza.titolo)"))
    }
}
