import SwiftUI

// La pagina «I motori di Vera» (Vera/BRIEF.md, fase 5; Design/template-vera.html, «Due velocità» e «Il cervello grande»):
// sopra la chat di Vera, due schede in un segmentato. «Due velocità»: le due corsie (a sinistra le regole di Prisma, perché
// il modello Apple è spento; a destra Qwen), la sfera al centro che smista, le richieste di oggi con il loro tempo e in
// fondo a ogni corsia quante e in quanto. «Il cervello grande»: i motori (Qwen dallo stato vero, il modello Apple spento,
// il motore esterno non collegato con la scelta del tipo), le tre regole con l'interruttore bloccato (un clic lo scuote) e
// due bolle d'esempio con le etichette. Mai in modalità cliente.

private typealias D = Tema.Apple.DueVelocita
private typealias K = Tema.Apple.CervelloGrande
private typealias S = Tema.Apple.SuMisura
private typealias C = Tema.Apple.Colore

extension View {
    /// La pagina dei motori sopra la finestra di Vera (velo e pagina), quando `paginaMotoriAperta`.
    func paginaMotoriVera() -> some View { modifier(ModificatorePaginaMotori()) }
}

private struct ModificatorePaginaMotori: ViewModifier {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        let aperta = stato.paginaMotoriAperta && !stato.inModoCliente
        content
            .overlay {
                if aperta {
                    ZStack {
                        S.velo
                            .contentShape(Rectangle())
                            .onTapGesture { stato.chiudiPaginaMotori() }
                        PaginaMotoriVista()
                            .padding(S.marginePagina)
                    }
                    .transition(.opacity)
                }
            }
            .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.uscita(S.durataCambio), calmo: calmo, istantanea: istantanea), value: aperta)
    }
}

struct PaginaMotoriVista: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        VStack(alignment: .leading, spacing: S.spazio) {
            HStack(spacing: S.spazio) {
                IconaApp(app: .vera, lato: S.iconaIntestazione)
                Text(StatoShell.titoloMotori).carattereApple(S.titoloPagina).foregroundColor(C.inchiostro)
                Spacer(minLength: 0)
                SegmentatoPillola(selezione: Bindable(stato).schedaMotori, voci: SchedaMotoriVera.allCases.map { ($0, $0.nome) })
                    .fixedSize()
                Spacer(minLength: 0)
                Button("Fine") { stato.chiudiPaginaMotori() }
                    .buttonStyle(.applePrimario).fixedSize()
                    .keyboardShortcut(.cancelAction)
            }
            switch stato.schedaMotori {
            case .dueVelocita: DueVelocitaVista()
            case .cervello: CervelloGrandeVista()
            }
        }
        .padding(S.paddingPagina)
        .frame(maxWidth: S.larghezzaPagina, maxHeight: S.altezzaMassimaPagina)
        .superficieApple(S.superficiePagina, raggio: S.raggioPagina)
    }
}

// MARK: - Due velocità

/// «0,3 s», «6 s»: un decimale sotto i 10 secondi.
func secondiVera(_ s: Double) -> String {
    s < 10 ? String(format: "%.1f s", s).replacingOccurrences(of: ".", with: ",") : "\(Int(s.rounded())) s"
}

struct DueVelocitaVista: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let apple = ModelloAppleVera.ammesso
        let veloci = stato.dueVelocita.richieste(.regole) + stato.dueVelocita.richieste(.apple)
        let profonde = stato.dueVelocita.richieste(.qwen) + stato.dueVelocita.richieste(.esterno)
        VStack(alignment: .leading, spacing: S.spazio) {
            HStack(alignment: .top, spacing: D.spazioCorsie) {
                CorsiaVeraVista(titolo: apple ? "Veloce · modello Apple" : "Veloce · regole di Prisma",
                                sottotitolo: apple ? "Sul Mac · comandi, riconoscere un documento, risposte brevi"
                                                   : "Sul Mac · comandi, agenda, routine, tagliando: senza modello",
                                colore: D.veloce, richieste: veloci, media: media(veloci)) {
                    if !apple {
                        HStack(spacing: S.spazioTappa) {
                            VStack(alignment: .leading, spacing: S.spazioTesti) {
                                Text("Modello Apple · spento").carattereApple(D.riga).foregroundColor(C.inchiostro)
                                Text(ModelloAppleVera.descrizioneDisponibilita).carattereApple(D.sottotitolo).foregroundColor(C.inchiostro2)
                            }
                            Spacer(minLength: 0)
                            Pillola(testo: "Da decidere", tono: .neutro)
                        }
                        .padding(D.paddingRiga)
                        .superficieApple(D.superficieRiga)
                    }
                }
                VStack(spacing: S.spazioTappa) {
                    SferaVera(misura: D.sfera, viva: true, pensa: stato.veraInCorso)
                    Text("Vera smista").carattereApple(D.titoloCentro).foregroundColor(C.inchiostro)
                    Text("Sceglie da sola il motore giusto").carattereApple(D.sottotitolo).foregroundColor(C.inchiostro2)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, D.sopraSfera)
                .frame(width: D.colonnaCentro)
                CorsiaVeraVista(titolo: "Profonda · \(nomeQwen)", sottotitolo: "Sul Mac · confronti, proposte, ragionamenti",
                                colore: D.profonda, richieste: profonde, media: media(profonde)) { EmptyView() }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            Text("Tempi indicativi. Se la risposta veloce non basta, Vera passa la domanda a Qwen.")
                .carattereApple(D.nota).foregroundColor(C.inchiostro2)
        }
    }

    private var nomeQwen: String {
        let m = stato.dati.impostazioni.vera.modello
        return SuMisuraVera.eSuMisura(m) ? "Vera su misura" : m
    }

    private func media(_ r: [RichiestaSmistata]) -> Double? {
        r.isEmpty ? nil : r.reduce(0) { $0 + $1.secondi } / Double(r.count)
    }
}

/// Una corsia (`.lane`): pallino, titolo, sottotitolo, le richieste con il tempo, in fondo quante oggi e in media.
struct CorsiaVeraVista<Extra: View>: View {
    let titolo: String
    let sottotitolo: String
    let colore: Color
    let richieste: [RichiestaSmistata]
    let media: Double?
    @ViewBuilder let extra: () -> Extra

    var body: some View {
        let mostrate = Array(richieste.suffix(D.massimoRighe))
        VStack(alignment: .leading, spacing: D.spazioRighe) {
            HStack(spacing: S.spazioTappa) {
                Circle().fill(colore).frame(width: D.pallino, height: D.pallino)
                Text(titolo).carattereApple(D.titoloCorsia).foregroundColor(C.inchiostro).lineLimit(1)
            }
            Text(sottotitolo).carattereApple(D.sottotitolo).foregroundColor(C.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            if mostrate.isEmpty {
                Text("Nessuna richiesta oggi.").carattereApple(D.riga).foregroundColor(C.inchiostro3)
                    .padding(.top, D.spazioRighe)
            }
            ForEach(Array(mostrate.enumerated()), id: \.element.id) { i, r in
                HStack(spacing: S.spazioTappa) {
                    Text(r.testo).carattereApple(D.riga).foregroundColor(C.inchiostro).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(secondiVera(r.secondi)).carattereApple(D.tempo).foregroundColor(colore)
                }
                .padding(D.paddingRiga)
                .superficieApple(D.superficieRiga)
                .entrataCascata(i, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
            }
            Spacer(minLength: 0)
            extra()
            Text(richieste.isEmpty ? "Oggi: nessuna richiesta"
                 : "Oggi: \(richieste.count) \(richieste.count == 1 ? "richiesta" : "richieste") · in media \(secondiVera(media ?? 0))")
                .carattereApple(D.piede).foregroundColor(C.inchiostro2)
                .padding(.top, D.sopraPiede)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().fill(C.separatore).frame(height: D.filoPiede) }
        }
        .padding(D.paddingCorsia)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(D.superficieCorsia)
    }
}

// MARK: - Il cervello grande

struct CervelloGrandeVista: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        HStack(alignment: .top, spacing: K.spazioColonne) {
            motori
                .frame(width: K.larghezzaMotori)
            VStack(alignment: .leading, spacing: S.spazio) {
                regole
                esempi
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var motori: some View {
        let pronto = stato.disponibilitaLocale.pronto
        let tipo = Bindable(stato.dati).impostazioni.vera.motoreEsterno.tipo
        return VStack(alignment: .leading, spacing: K.spazio) {
            Text("I motori di Vera").carattereApple(Tema.Apple.Carattere.etichetta).foregroundColor(C.inchiostro2)
            RigaMotoreVista(titolo: stato.qwen.nome.replacingOccurrences(of: " sul Mac", with: "") + " · " + stato.dati.impostazioni.vera.modello,
                            sotto: "Sul Mac · per ragionare", pillola: Pillola(testo: pronto ? "Attivo" : "Non pronto", tono: pronto ? .ok : .attenzione)) {
                SferaVera(misura: K.icona, viva: false)
            }
            RigaMotoreVista(titolo: "Modello Apple", sotto: "Sul Mac · per le cose rapide", pillola: Pillola(testo: "Spento", tono: .neutro)) {
                RoundedRectangle(cornerRadius: K.raggioIcona, style: .continuous)
                    .fill(LinearGradient(colors: [K.appleChiaro, K.appleScuro], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: K.icona, height: K.icona)
            }
            VStack(alignment: .leading, spacing: K.spazio) {
                HStack(spacing: K.spazio) {
                    RoundedRectangle(cornerRadius: K.raggioIcona, style: .continuous)
                        .strokeBorder(K.coloreTratteggio, style: StrokeStyle(lineWidth: K.trattoTratteggio, dash: K.tratteggio))
                        .frame(width: K.icona, height: K.icona)
                    VStack(alignment: .leading, spacing: S.spazioTesti) {
                        Text(CervelloGrandeVera.nome).carattereApple(K.nomeMotore).foregroundColor(C.inchiostro)
                        Text("Più grande, per le domande generali").carattereApple(K.sotto).foregroundColor(C.inchiostro2)
                    }
                    Spacer(minLength: 0)
                    Pillola(testo: "Non collegato", tono: .neutro)
                }
                SegmentatoPillola(selezione: tipo, voci: TipoMotoreEsterno.allCases.map { ($0, $0.nome) })
                    .fixedSize()
                    .disabled(stato.solaLettura)
                Text(stato.dati.impostazioni.vera.motoreEsterno.tipo.spiegazione)
                    .carattereApple(K.sotto).foregroundColor(C.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Collega quando vuoi") { stato.mostraAvviso("Lo colleghi tu, quando decidi: oggi Vera lavora tutta sul Mac") }
                    .buttonStyle(.applePrimario).fixedSize()
            }
            .padding(K.paddingMotore)
            .background(RoundedRectangle(cornerRadius: K.raggioMotore, style: .continuous)
                .strokeBorder(K.coloreTratteggio, style: StrokeStyle(lineWidth: K.trattoBordo, dash: K.tratteggio)))
        }
    }

    private var regole: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Le regole").carattereApple(Tema.Apple.Carattere.etichetta).foregroundColor(C.inchiostro2)
                .padding(.top, K.paddingRegola.top)
            ForEach(Array(CervelloGrandeVera.regole.enumerated()), id: \.offset) { i, r in
                RegolaCervelloVista(titolo: r.titolo, sotto: r.sotto, avviso: r.avviso, ultima: i == CervelloGrandeVera.regole.count - 1)
            }
        }
        .padding(K.paddingRegole)
        .superficieApple(K.superficieRegole)
    }

    /// Due bolle fac-simile, segnate «Esempio», con le etichette vere.
    private var esempi: some View {
        var esterno = MessaggioVera(autore: .vera, testo: "Studia come decide chi deve tener conto delle mosse degli altri. Il caso più noto è il dilemma del prigioniero.",
                                    motore: CervelloGrandeVera.nome)
        esterno.modalita = .conversazione
        var mac = MessaggioVera(autore: .vera, testo: "Ecco la scheda di Laura: obiettivi, posizioni e scadenze, con le cifre calcolate da Prisma.",
                                motore: MotoreLocale.nome(MotoreLocale.modelloPredefinito))
        mac.modalita = .lavoro
        return VStack(alignment: .leading, spacing: K.spazioBolle) {
            Text("Esempio").carattereApple(Tema.Apple.Carattere.etichetta).foregroundColor(C.inchiostro3)
            BollaEsempioVista(testo: "Spiegami la teoria dei giochi in due righe.", mia: true)
            BollaEsempioVista(testo: esterno.testo, mia: false, messaggio: esterno)
            BollaEsempioVista(testo: "E adesso riassumi la scheda di Laura.", mia: true)
            BollaEsempioVista(testo: mac.testo, mia: false, messaggio: mac)
        }
    }
}

/// Un motore (tile): icona, nome, sottotitolo, pillola.
struct RigaMotoreVista<Icona: View>: View {
    let titolo: String
    let sotto: String
    let pillola: Pillola
    @ViewBuilder let icona: () -> Icona

    var body: some View {
        HStack(spacing: K.spazio) {
            icona()
            VStack(alignment: .leading, spacing: S.spazioTesti) {
                Text(titolo).carattereApple(K.nomeMotore).foregroundColor(C.inchiostro).lineLimit(1)
                Text(sotto).carattereApple(K.sotto).foregroundColor(C.inchiostro2)
            }
            Spacer(minLength: 0)
            pillola
        }
        .padding(K.paddingMotore)
        .superficieApple(K.superficieMotore, raggio: K.raggioMotore)
    }
}

/// Una regola con l'interruttore bloccato (`.sw.lock`): un clic lo scuote e dice perché non si spegne.
struct RegolaCervelloVista: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    let titolo: String
    let sotto: String
    let avviso: String
    let ultima: Bool
    @State private var scosse: CGFloat = 0

    var body: some View {
        HStack(spacing: K.spazio) {
            VStack(alignment: .leading, spacing: S.spazioTesti) {
                Text(titolo).carattereApple(K.titoloRegola).foregroundColor(C.inchiostro)
                Text(sotto).carattereApple(K.sotto).foregroundColor(C.inchiostro2)
            }
            Spacer(minLength: 0)
            InterruttoreBloccatoVista()
                .modifier(ScuotiEffetto(ampiezza: K.scuotimento, volte: K.scuotimenti, animatableData: scosse))
                .contentShape(Rectangle())
                .onTapGesture { scuoti() }
                .accessibilityElement()
                .accessibilityLabel("\(titolo): sempre acceso, non si può spegnere")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { scuoti() }
        }
        .padding(K.paddingRegola)
        .overlay(alignment: .bottom) {
            if !ultima { Rectangle().fill(C.separatore).frame(height: Tema.Apple.Misura.bordo) }
        }
    }

    private func scuoti() {
        if !calmo {
            withAnimation(.linear(duration: K.durataScuoti)) { scosse += 1 }
        }
        stato.mostraAvviso(avviso)
    }
}

/// Lo scuotimento orizzontale dell'interruttore bloccato (Animatable, niente Timer).
struct ScuotiEffetto: GeometryEffect {
    var ampiezza: CGFloat
    var volte: CGFloat
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: ampiezza * sin(animatableData * .pi * volte * 2), y: 0))
    }
}

/// L'interruttore acceso, grigio, con il lucchetto sulla manopola.
struct InterruttoreBloccatoVista: View {
    var body: some View {
        ZStack(alignment: .trailing) {
            Capsule(style: .continuous)
                .fill(K.interruttoreBloccato)
                .frame(width: K.larghezzaInterruttore, height: K.altezzaInterruttore)
            Circle()
                .fill(S.numeroAcceso)
                .frame(width: K.manopola, height: K.manopola)
                .overlay(Image(systemName: "lock.fill").carattereApple(K.lucchetto).foregroundColor(K.interruttoreBloccato))
                .padding(.trailing, (K.altezzaInterruttore - K.manopola) / 2)
        }
    }
}

/// Una bolla della chat d'esempio: tua a destra, di Vera a sinistra con la sua etichetta.
struct BollaEsempioVista: View {
    let testo: String
    let mia: Bool
    var messaggio: MessaggioVera? = nil

    var body: some View {
        VStack(alignment: mia ? .trailing : .leading, spacing: K.spazio) {
            Text(testo)
                .carattereApple(K.bolla)
                .foregroundColor(mia ? K.testoBollaMia : C.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
                .padding(K.paddingBolla)
                .background {
                    if mia {
                        RoundedRectangle(cornerRadius: Tema.Apple.Raggio.voce, style: .continuous).fill(K.fondoBollaMia)
                    }
                }
                .superficieAppleSeVera(!mia)
            if let m = messaggio { EtichettaMotoreVista(messaggio: m) }
        }
        .frame(maxWidth: .infinity, alignment: mia ? .trailing : .leading)
    }
}

private extension View {
    @ViewBuilder
    func superficieAppleSeVera(_ si: Bool) -> some View {
        if si { self.superficieApple(Tema.Apple.Superficie.tile, raggio: Tema.Apple.Raggio.voce) } else { self }
    }
}
