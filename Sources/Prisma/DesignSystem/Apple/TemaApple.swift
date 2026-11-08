import SwiftUI

// Tema «stile Apple» (Design/template-apple.html, specifica in Design/template-apple-specifica.md §1).
// Colori, superfici, ombre, raggi, misure e caratteri: le schermate nuove usano solo questi nomi.
// I tempi e le curve stanno in TemaAppleMoto.swift; «Riduci movimento» e istantanee in AmbienteMovimento.swift.
// Unità: 1 px CSS del template = 1 pt SwiftUI.

extension Tema {
    /// Gettoni del tema «stile Apple». Convivono con quelli di oggi finché le schermate non sono spostate tutte.
    enum Apple {}
}

// MARK: - Colori (§1.1, §1.2)

extension Tema.Apple {
    enum Colore {
        private static func d(_ chiaro: Color, _ scuro: Color) -> Color { .dinamico(chiaro: chiaro, scuro: scuro) }
        private static func nero(_ a: Double) -> Color { Color(r: 0, g: 0, b: 0, a: a) }
        private static func bianco(_ a: Double) -> Color { Color(r: 255, g: 255, b: 255, a: a) }

        // MARK: Cambiano con l'aspetto

        /// Testo principale (--ink).
        static let inchiostro = d(nero(0.87), bianco(0.94))
        /// Testo secondario, `.k`, `.lbl` (--ink2).
        static let inchiostro2 = d(nero(0.55), bianco(0.62))
        /// Etichette di assi, ore, giorni fuori mese (--ink3).
        static let inchiostro3 = d(nero(0.34), bianco(0.38))
        /// Bordi da 1 pt e divisori (--sep).
        static let separatore = d(nero(0.08), bianco(0.09))
        /// Fondo della finestra interna (--win).
        static let finestra = d(Color(r: 246, g: 248, b: 251, a: 0.86), Color(r: 16, g: 26, b: 35, a: 0.86))
        /// Barre laterali `.side` (--panel).
        static let pannello = d(bianco(0.72), bianco(0.05))
        /// Card, tile, suggerimenti (--card).
        static let card = d(bianco(0.82), bianco(0.07))
        /// Dettaglio, pulsanti, pillola del segmentato, campo di Vera (--cardE).
        static let cardPiena = d(Color(hex: "#FFFFFF"), Color(hex: "#283642"))
        /// Binari di barre, interruttori, cursori, mesi vuoti, cerchietti (--track).
        static let binario = d(nero(0.07), bianco(0.10))
        /// Fondo dei segmentati, ricerca, hover, bolle di Vera, fondo dell'anteprima (--chip).
        static let chip = d(nero(0.05), bianco(0.08))
        /// Riempimento del vetro `.glass` (--glass).
        static let vetro = d(bianco(0.50), Color(r: 16, g: 32, b: 44, a: 0.42))
        /// Vetro dei pannelli che galleggiano sopra altri contenuti (notifiche, ricerca ⌘K, app aperte) quando
        /// non c'è sfocatura (istantanee, ImageRenderer, vetro semplificato): coprente come i pannelli della shell,
        /// così le scritte della scrivania o della finestra sotto non si leggono attraverso.
        static let vetroSopra = d(Color(r: 246, g: 248, b: 251, a: 0.98), Color(r: 16, g: 26, b: 35, a: 0.97))
        /// Bordo del vetro e della finestra (--glassE).
        static let bordoVetro = d(bianco(0.70), bianco(0.16))
        /// Testo sopra l'acqua: barra, saluto, dock (--wallInk).
        static let inchiostroAcqua = d(Color(r: 8, g: 26, b: 38, a: 0.88), Color(hex: "#FFFFFF"))
        /// Sottotitolo del saluto (--wallInk2).
        static let inchiostroAcqua2 = d(Color(r: 8, g: 26, b: 38, a: 0.60), bianco(0.66))
        /// Velo sotto il dettaglio (--scrim).
        static let velo = d(Color(r: 220, g: 232, b: 240, a: 0.40), Color(r: 5, g: 12, b: 18, a: 0.50))
        /// Testo e pallino dell'etichetta Alleanza, barra del canale (--chA).
        static let canaleAlleanza = d(Color(hex: "#2563EB"), Color(hex: "#6B95FF"))
        /// Testo e pallino dell'etichetta indipendente (--chI).
        static let canaleIndipendente = d(Color(hex: "#B06E12"), Color(hex: "#D0954A"))
        /// Fuori dal palco del template (html, body): nell'app non serve, resta per completezza.
        static let fuoriPalco = d(Color(hex: "#BFD4DF"), Color(hex: "#081219"))
        /// Velo del blocco (con sfocatura `Tema.Apple.Superficie.sfocaturaBlocco`).
        static let veloBlocco = d(Color(r: 220, g: 234, b: 242, a: 0.18), Color(r: 5, g: 14, b: 20, a: 0.25))
        /// Logo Prisma nella barra e nel blocco.
        static let logo = d(Color(hex: "#0F2433"), Color(hex: "#FFFFFF"))
        /// Riflesso delle schede inclinabili (`.sheen`): fusione con `fusioneRiflesso(scuro:)`.
        static let riflessoInclinazione = d(bianco(0.60), bianco(0.16))
        /// Fusione del riflesso: `softLight` in chiaro, `normal` in scuro.
        static func fusioneRiflesso(scuro: Bool) -> BlendMode { scuro ? .normal : .softLight }
        /// Filo di luce interno in alto del vetro (inset 0 1 0).
        static let filoVetro = d(bianco(0.55), bianco(0.12))
        /// `.lbl` «La mossa del giorno»: #1D6FC4 in chiaro; in scuro la stessa tinta più chiara (#6EA7E2),
        /// leggibile sul vetro scuro (contrasto circa 5,9:1 contro 2,9:1 del blu fisso).
        static let mossaDelGiorno = d(Color(hex: "#1D6FC4"), Color(hex: "#6EA7E2"))

        // MARK: Fissi

        /// Pulsante primario, collegamenti, bolle dell'utente, puntini dell'agenda (uguale in scuro).
        static let accento = Color(hex: "#007AFF")
        /// Urgenza, oggi nel calendario, linea dell'ora, area Protezione.
        static let rosso = Color(hex: "#E5484D")
        /// Urgenza media, completezza sotto l'85%.
        static let arancio = Color(hex: "#E08A00")
        /// Positivo, spunte, «Ti preparo», delta.
        static let verde = Color(hex: "#2FA35A")
        /// Interruttore acceso.
        static let verdeInterruttore = Color(hex: "#34C759")
        /// Badge della campanella.
        static let rossoBadge = Color(hex: "#FF3B30")
        /// Anelli: in regola (anche verde del backup), riesami, proposte.
        static let anello1 = Color(hex: "#30B15C")
        static let anello2 = Color(hex: "#0A84FF")
        static let anello3 = Color(hex: "#8B5CF6")
        /// Stime e proposte nei grafici.
        static let stima = Color(hex: "#8B5CF6")
        /// Fondo dell'etichetta Alleanza (non cambia in scuro).
        static let fondoAlleanza = Color(r: 37, g: 99, b: 235, a: 0.13)
        /// Fondo dell'etichetta indipendente (non cambia in scuro).
        static let fondoIndipendente = Color(r: 176, g: 110, b: 18, a: 0.14)
        /// Fondo del toast (testo bianco).
        static let toast = Color(r: 15, g: 36, b: 51, a: 0.92)
        /// Testo del toast.
        static let testoToast = Color.white
        /// Velo della presentazione.
        static let sala = Color(r: 6, g: 14, b: 20, a: 0.92)
        /// «tra 45 giorni».
        static let scadenza = Color(hex: "#C25E00")
        /// Voce selezionata in rubrica e barre laterali.
        static let selezioneVoce = Color(r: 0, g: 122, b: 255, a: 0.13)
        /// Giorno scelto nel calendario.
        static let selezioneGiorno = Color(r: 0, g: 122, b: 255, a: 0.14)
        /// Card «Da non dimenticare».
        static let avvisoFondo = Color(r: 224, g: 138, b: 0, a: 0.10)
        static let avvisoBordo = Color(r: 224, g: 138, b: 0, a: 0.25)
        /// Semafori della finestra.
        static let semaforoChiudi = Color(hex: "#FF5F57")
        static let semaforoRiduci = Color(hex: "#FEBC2E")
        static let semaforoIngrandisci = Color(hex: "#28C840")
        /// Avatar del consulente: gradiente dall'alto in basso.
        static let avatarDVAlto = Color(hex: "#7FA5D9")
        static let avatarDVBasso = Color(hex: "#4B79B8")

        /// Aree di Analisi 360.
        enum Area {
            static let previdenza = Color(hex: "#8B5CF6")
            static let protezione = Color(hex: "#E5484D")
            static let investimenti = Color(hex: "#0A84FF")
            static let liquidita = Color(hex: "#30B15C")
        }

        /// Composizione del portafoglio.
        enum Composizione {
            static let azionario = Color(hex: "#0A84FF")
            static let obbligazionario = Color(hex: "#5AC8FA")
            static let gestioneSeparata = Color(hex: "#2563EB")
            static let liquidita = Color(hex: "#9FB3C2")
        }

        /// Colori degli impegni dell'agenda; il fondo è il colore a `alfaFondo` (0x22).
        enum Impegno {
            static let giulia = Color(hex: "#C45A75")
            static let marco = Color(hex: "#4B79B8")
            static let laura = Color(hex: "#7D63C4")
            static let andrea = Color(hex: "#2C7A55")
            static let sofia = Color(hex: "#B98A35")
            static let formazioneAlleanza = Color(hex: "#2563EB")
            static let attivita = Color(hex: "#7A8794")
            static let riesame = Color(hex: "#6B8199")
            /// Opacità del fondo degli impegni (0x22 / 255).
            static let alfaFondo: Double = 34.0 / 255.0
        }

        /// Sfera di Vera: radiale con centro a (34%, 28%).
        static let centroSfera = UnitPoint(x: 0.34, y: 0.28)
        static let fermateSfera: [Gradient.Stop] = [
            .init(color: Color(hex: "#FFFFFF"), location: 0),
            .init(color: Color(hex: "#D6ECF9"), location: 0.18),
            .init(color: Color(hex: "#7FB9E6"), location: 0.48),
            .init(color: Color(hex: "#3F79C0"), location: 0.78),
            .init(color: Color(hex: "#2C4F9A"), location: 1),
        ]
        /// Sfera «MB» della mossa del giorno (stesso centro).
        static let fermateSferaMossa: [Gradient.Stop] = [
            .init(color: Color(hex: "#FFFFFF"), location: 0),
            .init(color: Color(hex: "#CFE6F6"), location: 0.22),
            .init(color: Color(hex: "#78B2DB"), location: 0.58),
            .init(color: Color(hex: "#3C76B0"), location: 1),
        ]
        /// Riflesso conico della sfera (`:after`), da fondere con `.overlay`.
        static let fermateRiflessoSfera: [Gradient.Stop] = [
            .init(color: .clear, location: 0),
            .init(color: bianco(0.45), location: 0.15),
            .init(color: .clear, location: 0.30),
            .init(color: Color(r: 160, g: 120, b: 255, a: 0.35), location: 0.45),
            .init(color: .clear, location: 0.60),
            .init(color: Color(r: 120, g: 230, b: 255, a: 0.40), location: 0.80),
            .init(color: .clear, location: 1),
        ]
    }

    // MARK: - Carta (PDF e anteprime: sempre chiara, mai vetro)

    enum Carta {
        static let fondo = Color(hex: "#FFFFFF")
        static let testo = Color(hex: "#14202B")
        static let sottotitolo = Color(hex: "#4A5964")
        static let testoCorrente = Color(hex: "#33424D")
        static let etichetta = Color(hex: "#5A6873")
        static let piede = Color(hex: "#7A8790")
        static let filetto = Color(hex: "#E3E8EC")
        static let linea = Color(hex: "#C9D3DA")
        static let binario = Color(hex: "#EEF2F5")
        static let binarioBlu = Color(hex: "#E6EEF7")
        static let binarioRosso = Color(hex: "#F6E3E4")
        static let sopratitolo = Color(hex: "#2563EB")
        static let positivo = Color(hex: "#2F7A4A")
        static let ambra = Color(hex: "#B45309")
        static let rosso = Color(hex: "#E5484D")
        static let bluGrafico = Color(hex: "#0A84FF")
    }
}

// MARK: - Raggi (§1.5)

extension Tema.Apple {
    enum Raggio {
        /// Pulsanti, chip, segmentati, interruttori, avatar, toast, campo di Vera: usare `Capsule()`.
        static let pillola: CGFloat = 99
        static let dettaglioAperto: CGFloat = 28
        /// Riquadri della scrivania, dock.
        static let riquadro: CGFloat = 26
        static let finestra: CGFloat = 24
        /// Card, notifiche, dettaglio chiuso, schede «Da fare», spunta.
        static let card: CGFloat = 22
        /// Barre laterali, bolle di chat, anteprima dei prospetti.
        static let pannello: CGFloat = 20
        static let tile: CGFloat = 18
        /// Voci di rubrica e notifiche, impegni, palco.
        static let voce: CGFloat = 14
        /// Caselle del calendario, blocchi mese, contenitore della composizione.
        static let giorno: CGFloat = 12
        static let kpiCarta: CGFloat = 10
        /// Barre da 8, binario del cursore, puntini.
        static let barra: CGFloat = 9
        /// Angolo stretto delle bolle, pezzi della composizione.
        static let bollaPiccola: CGFloat = 6
    }
}

// MARK: - Ombre (§1.4)

extension Tema.Apple {
    /// Ombre del tema: ogni caso dà gli strati CSS esatti (`strati(scuro:)`, con l'espansione)
    /// per `OmbraVetroPronta`, oppure si applica a una vista qualsiasi con `.ombraApple(_:)`.
    enum Ombra: CaseIterable {
        case card, vetro, finestra, inclinata, dettaglio, carta, pillola, manopolaInterruttore, manopolaCursore, sfera
        /// Il tassello delle scene della giornata della pensione (Sala, «Luce» giro 4): 0 10 20 −10 nero al 40%.
        case tasselloScena
        /// Il foglio della lettera dal futuro (Sala, «Luce» giro 8): 0 22 50 −18 rgba(40,30,20,.35), uguale in chiaro e scuro.
        case foglioLettera

        private static func blu(_ a: Double) -> Color { Color(r: 8, g: 40, b: 60, a: a) }
        private static func nero(_ a: Double) -> Color { Color(r: 0, g: 0, b: 0, a: a) }

        /// Gli strati CSS nell'ordine del `box-shadow` (le ombre interne sono a parte).
        func strati(scuro: Bool) -> [StratoOmbra] {
            typealias S = StratoOmbra
            switch self {
            case .card:
                return scuro
                    ? [S(colore: Self.nero(0.8), y: 26, sfocatura: 52, espansione: -26),
                       S(colore: Self.nero(0.35), y: 3, sfocatura: 10, espansione: -3)]
                    : [S(colore: Self.blu(0.4), y: 24, sfocatura: 48, espansione: -28),
                       S(colore: Self.blu(0.1), y: 2, sfocatura: 8, espansione: -3)]
            case .vetro:
                return scuro
                    ? [S(colore: Self.nero(0.7), y: 26, sfocatura: 52, espansione: -24)]
                    : [S(colore: Self.blu(0.36), y: 22, sfocatura: 44, espansione: -24),
                       S(colore: Self.blu(0.12), y: 3, sfocatura: 10, espansione: -4)]
            case .finestra:
                return [S(colore: Self.blu(0.45), y: 40, sfocatura: 80, espansione: -24)]
            case .inclinata:
                return [S(colore: Self.blu(0.5), y: 40, sfocatura: 60, espansione: -30),
                        S(colore: Self.blu(0.16), y: 4, sfocatura: 12, espansione: -4)]
            case .dettaglio:
                return [S(colore: Self.blu(0.55), y: 50, sfocatura: 90, espansione: -30)]
            case .carta:
                return [S(colore: Self.nero(0.25), y: 20, sfocatura: 50, espansione: -10)]
            case .pillola:
                return [S(colore: Self.nero(0.14), y: 1, sfocatura: 4)]
            case .manopolaInterruttore:
                return [S(colore: Self.nero(0.25), y: 2, sfocatura: 5)]
            case .manopolaCursore:
                return [S(colore: Self.nero(0.28), y: 3, sfocatura: 10)]
            case .sfera:
                return [S(colore: Color(r: 40, g: 90, b: 170, a: 0.6), y: 4, sfocatura: 12, espansione: -4)]
            case .tasselloScena:
                return [S(colore: Self.nero(0.40), y: 10, sfocatura: 20, espansione: -10)]
            case .foglioLettera:
                return [S(colore: Color(r: 40, g: 30, b: 20, a: 0.35), y: 22, sfocatura: 50, espansione: -18)]
            }
        }

        /// Ombra interna della sfera (inset 0 −4 10).
        static let internaSfera = StratoOmbra(colore: Color(r: 10, g: 30, b: 80, a: 0.35), y: -4, sfocatura: 10)
        /// Ombra della sfera a metà del respiro.
        static let respiroSfera = StratoOmbra(colore: Color(r: 90, g: 140, b: 255, a: 0.7), y: 10, sfocatura: 30, espansione: -6)
        /// Filo interno del vetro (inset 0 1 0): spessore; il colore è `Colore.filoVetro`.
        static let spessoreFiloVetro: CGFloat = 1

        /// `.shadow` di SwiftUI non ha l'espansione: con espansione negativa l'opacità scende di
        /// `1 + espansione / sfocatura`, mai sotto questo minimo. Per la resa esatta: `OmbraVetroPronta`.
        static let riduzioneMinima: Double = 0.35
        /// Raggio SwiftUI per un punto di sfocatura CSS.
        static let raggioPerSfocatura: CGFloat = 0.5

        static func opacitaApprossimata(_ s: StratoOmbra) -> Double {
            guard s.espansione < 0, s.sfocatura > 0 else { return 1 }
            return max(riduzioneMinima, Double(1 + s.espansione / s.sfocatura))
        }
    }
}

private struct StratoOmbraApple: ViewModifier {
    let strato: StratoOmbra?
    @ViewBuilder func body(content: Content) -> some View {
        if let s = strato {
            content.shadow(color: s.colore.opacity(Tema.Apple.Ombra.opacitaApprossimata(s)),
                           radius: s.sfocatura * Tema.Apple.Ombra.raggioPerSfocatura, x: 0, y: s.y)
        } else {
            content
        }
    }
}

private struct ModificatoreOmbraApple: ViewModifier {
    let ombra: Tema.Apple.Ombra
    @Environment(\.colorScheme) private var schema

    func body(content: Content) -> some View {
        let s = ombra.strati(scuro: schema == .dark)
        // Prima lo strato stretto, poi quello largo: l'ombra dell'ombra resta trascurabile.
        return content
            .modifier(StratoOmbraApple(strato: s.count > 1 ? s[1] : nil))
            .modifier(StratoOmbraApple(strato: s.first))
    }
}

extension View {
    /// Ombra del tema Apple (chiara o scura secondo l'aspetto), approssimata con `.shadow`.
    /// Va messa sulla forma di fondo, non sul contenuto con il testo.
    func ombraApple(_ ombra: Tema.Apple.Ombra) -> some View {
        modifier(ModificatoreOmbraApple(ombra: ombra))
    }
}

// MARK: - Superfici (§1.3)

extension Tema.Apple {
    /// Una superficie del tema: riempimento, sfocatura dietro, bordo, ombra e raggio.
    struct Superficie {
        let riempimento: Color
        /// Sfocatura CSS di ciò che sta dietro (0 = nessuna).
        let sfocatura: CGFloat
        /// Saturazione del `backdrop-filter` (sul ripiego con `Material` non si riproduce).
        let saturazione: Double
        let bordo: Color?
        let spessoreBordo: CGFloat
        let ombra: Ombra?
        let raggio: CGFloat
        /// Filo di luce interno in alto (solo il vetro).
        let filoInterno: Bool
        /// Riempimento quando la sfocatura non c'è (istantanee, vetro semplificato): nil = `riempimento`.
        /// Lo hanno solo le superfici che stanno sopra altri contenuti.
        var riempimentoFermo: Color? = nil

        /// `.glass`: barra, dock, riquadri della scrivania, notifiche, pulsante del blocco (raggio secondo l'elemento).
        static let vetro = Superficie(riempimento: Colore.vetro, sfocatura: 16, saturazione: 1.4,
                                      bordo: Colore.bordoVetro, spessoreBordo: 1, ombra: .vetro,
                                      raggio: Raggio.riquadro, filoInterno: true)
        /// `#win`: finestra interna.
        static let finestra = Superficie(riempimento: Colore.finestra, sfocatura: 34, saturazione: 1.3,
                                         bordo: Colore.bordoVetro, spessoreBordo: 1, ombra: .finestra,
                                         raggio: Raggio.finestra, filoInterno: false)
        /// `.glass` di un pannello sopra altri contenuti (centro notifiche): nell'app sfoca come `vetro`; senza
        /// sfocatura il riempimento è coprente (`Colore.vetroSopra`).
        static let vetroSopra = Superficie(riempimento: Colore.vetro, sfocatura: 16, saturazione: 1.4,
                                          bordo: Colore.bordoVetro, spessoreBordo: 1, ombra: .vetro,
                                          raggio: Raggio.riquadro, filoInterno: true,
                                          riempimentoFermo: Colore.vetroSopra)
        /// `#win` di un pannello sopra altri contenuti (ricerca ⌘K, app aperte): coprente senza sfocatura.
        static let finestraSopra = Superficie(riempimento: Colore.finestra, sfocatura: 34, saturazione: 1.3,
                                             bordo: Colore.bordoVetro, spessoreBordo: 1, ombra: .finestra,
                                             raggio: Raggio.finestra, filoInterno: false,
                                             riempimentoFermo: Colore.vetroSopra)
        /// Card con l'ombra (nelle app quasi sempre si usa `cardPiatta`).
        static let card = Superficie(riempimento: Colore.card, sfocatura: 0, saturazione: 1,
                                     bordo: Colore.separatore, spessoreBordo: 1, ombra: .card,
                                     raggio: Raggio.card, filoInterno: false)
        /// Card senza ombra, come nelle app.
        static let cardPiatta = Superficie(riempimento: Colore.card, sfocatura: 0, saturazione: 1,
                                           bordo: Colore.separatore, spessoreBordo: 1, ombra: nil,
                                           raggio: Raggio.card, filoInterno: false)
        static let tile = Superficie(riempimento: Colore.card, sfocatura: 0, saturazione: 1,
                                     bordo: Colore.separatore, spessoreBordo: 1, ombra: nil,
                                     raggio: Raggio.tile, filoInterno: false)
        /// `.side`: barre laterali.
        static let pannello = Superficie(riempimento: Colore.pannello, sfocatura: 0, saturazione: 1,
                                         bordo: Colore.separatore, spessoreBordo: 1, ombra: nil,
                                         raggio: Raggio.pannello, filoInterno: false)
        /// `#det`: dettaglio (raggio 22 chiuso → 28 aperto).
        static let dettaglio = Superficie(riempimento: Colore.cardPiena, sfocatura: 0, saturazione: 1,
                                          bordo: Colore.separatore, spessoreBordo: 1, ombra: .dettaglio,
                                          raggio: Raggio.card, filoInterno: false)
        /// `.paper`: carta dei prospetti, sempre bianca.
        static let carta = Superficie(riempimento: Carta.fondo, sfocatura: 0, saturazione: 1,
                                      bordo: nil, spessoreBordo: 0, ombra: .carta,
                                      raggio: 0, filoInterno: false)

        /// Sfocatura del velo del blocco.
        static let sfocaturaBlocco: CGFloat = 3
        /// Sfocatura del velo sotto il dettaglio aperto (§1.8 `velo`: 0 → 10).
        static let sfocaturaVelo: CGFloat = 10
    }
}

/// Filo di luce interno in alto (inset 0 1 0): la forma meno sé stessa spostata in basso, ritagliata nella forma.
private struct FiloInternoApple: Shape {
    let raggio: CGFloat
    let spessore: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = RoundedRectangle(cornerRadius: raggio, style: .continuous).path(in: rect)
        p.addPath(RoundedRectangle(cornerRadius: raggio, style: .continuous).path(in: rect.offsetBy(dx: 0, dy: spessore)))
        return p
    }
}

private struct ModificatoreSuperficieApple: ViewModifier {
    let superficie: Tema.Apple.Superficie
    let raggio: CGFloat
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.vetroSemplificato) private var semplificatoQui
    @Environment(\.colorScheme) private var schema

    private var forma: RoundedRectangle { RoundedRectangle(cornerRadius: raggio, style: .continuous) }

    /// Niente materiali né vetro di Apple: istantanee, ImageRenderer, vetro semplificato.
    private var senzaMateriali: Bool { istantanea || semplificatoQui || Vetro.semplificato }

    /// Il riempimento senza sfocatura: per le superfici che sfocherebbero, quello coprente se ce l'hanno.
    private var riempimentoFermo: Color {
        guard superficie.sfocatura > 0 else { return superficie.riempimento }
        return superficie.riempimentoFermo ?? superficie.riempimento
    }

    func body(content: Content) -> some View {
        conVetro(content)
            .overlay { bordo }
            .background { ombra }
    }

    /// Vetro di Apple su macOS 26 e iOS 26; sotto, `Material` più il riempimento; nelle istantanee solo il riempimento.
    private func conVetro(_ content: Content) -> AnyView {
        let sfoca = superficie.sfocatura > 0 && !senzaMateriali
        #if compiler(>=6.2)
        if #available(macOS 26.0, iOS 26.0, *) {
            if sfoca {
                return AnyView(
                    content
                        .background { forma.fill(superficie.riempimento) }
                        .glassEffect(SwiftUI.Glass.regular, in: forma)
                )
            }
        }
        #endif
        if sfoca {
            return AnyView(content.background { fondoMateriale })
        }
        return AnyView(content.background { forma.fill(riempimentoFermo) })
    }

    private var fondoMateriale: some View {
        ZStack {
            forma.fill(.ultraThinMaterial)
            forma.fill(superficie.riempimento)
        }
    }

    @ViewBuilder private var bordo: some View {
        ZStack {
            if let b = superficie.bordo, superficie.spessoreBordo > 0 {
                forma.strokeBorder(b, lineWidth: superficie.spessoreBordo)
            }
            if superficie.filoInterno {
                FiloInternoApple(raggio: raggio, spessore: Tema.Apple.Ombra.spessoreFiloVetro)
                    .fill(Tema.Apple.Colore.filoVetro, style: FillStyle(eoFill: true))
                    .clipShape(forma)
            }
        }
        .allowsHitTesting(false)
    }

    /// Ombra esatta (con l'espansione) dalla bitmap pronta, con il buco della forma: mai sotto il vetro.
    @ViewBuilder private var ombra: some View {
        if let o = superficie.ombra {
            OmbraVetroPronta(raggio: raggio, strati: o.strati(scuro: schema == .dark))
        }
    }
}

extension View {
    /// Disegna dietro la vista la superficie del tema Apple (riempimento, vetro, bordo, filo e ombra).
    /// `raggio` nil = quello della superficie (per il vetro va dato secondo l'elemento).
    func superficieApple(_ superficie: Tema.Apple.Superficie, raggio: CGFloat? = nil) -> some View {
        modifier(ModificatoreSuperficieApple(superficie: superficie, raggio: raggio ?? superficie.raggio))
    }
}

// MARK: - Spaziature e misure (§1.6)

extension Tema.Apple {
    enum Misura {
        /// Padding CSS «verticale orizzontale» (es. 22×26).
        static func padding(_ verticale: CGFloat, _ orizzontale: CGFloat) -> EdgeInsets {
            EdgeInsets(top: verticale, leading: orizzontale, bottom: verticale, trailing: orizzontale)
        }

        /// Spessore dei bordi e dei divisori.
        static let bordo: CGFloat = 1

        enum Finestra {
            /// Margine esterno della finestra.
            static let margine: CGFloat = 16
            /// Bordo alto (barra 34 + 8).
            static let alto: CGFloat = 42
            /// Spazio lasciato in basso per il dock.
            static let fondo: CGFloat = 100
            static let barraTitolo: CGFloat = 38
            static let intestazione: CGFloat = 54
            static let paddingIntestazione = EdgeInsets(top: 4, leading: 18, bottom: 12, trailing: 18)
            /// Contenuto a 12 dai bordi e a 92 dall'alto.
            static let margineContenuto: CGFloat = 12
            static let altoContenuto: CGFloat = 92
        }

        enum Barra {
            /// Altezza della barra superiore.
            static let altezza: CGFloat = 34
        }

        enum Padding {
            static let cardPortafoglio = Misura.padding(22, 26)
            static let cardGrande = Misura.padding(22, 24)
            static let cardMedia = Misura.padding(20, 22)
            static let cardPiccola = Misura.padding(18, 20)
            static let rigaImpostazione = Misura.padding(16, 20)
            static let tile = Misura.padding(14, 16)
            static let barraLaterale = Misura.padding(14, 12)
            /// Barra laterale di Vera: in alto 30.
            static let barraLateraleVeraAlto: CGFloat = 30
            static let dettaglio = Misura.padding(26, 30)
            /// Piede del dettaglio: a 30 dai lati e 24 dal fondo.
            static let piedeDettaglioLati: CGFloat = 30
            static let piedeDettaglioFondo: CGFloat = 24
            /// ✕ del dettaglio a 22 dall'alto e da destra.
            static let chiudiDettaglio: CGFloat = 22
            static let segmentato: CGFloat = 3
            static let voceSegmentato = Misura.padding(6, 14)
            static let pulsante = Misura.padding(7, 14)
            static let pulsanteGrande = Misura.padding(10, 18)
            static let etichettaCanale = Misura.padding(3, 9)
            /// Padding interno del nastro (le ombre delle schede non vengono tagliate).
            static let nastro = Misura.padding(10, 28)
        }

        enum Spazio {
            static let griglia: CGFloat = 14
            static let cifre: CGFloat = 12
            static let colonneScrivania: CGFloat = 16
            static let margineScrivania: CGFloat = 44
            static let nastro: CGFloat = 14
            static let etichettaCanale: CGFloat = 5
        }

        enum Laterale {
            static let clienti: CGFloat = 250
            static let prospetti: CGFloat = 290
            static let vera: CGFloat = 300
            static let impostazioni: CGFloat = 260
            static let agenda: CGFloat = 330
        }

        enum Controllo {
            static let interruttore = CGSize(width: 44, height: 26)
            static let manopolaInterruttore: CGFloat = 20
            /// Spostamento della manopola: da 3 (spento) a 21 (acceso).
            static let manopolaSpento: CGFloat = 3
            static let manopolaAcceso: CGFloat = 21
            static let binarioCursore: CGFloat = 6
            static let manopolaCursore: CGFloat = 28
            static let freccia: CGFloat = 32
            static let invio: CGFloat = 36
            static let pallinoCanale: CGFloat = 6
            /// Altezza delle barre che si riempiono.
            static let barra: CGFloat = 8
        }

        /// Lati degli avatar.
        enum Avatar {
            static let minimo: CGFloat = 24
            static let piccolo: CGFloat = 30
            static let voce: CGFloat = 34
            static let medio: CGFloat = 38
            static let grande: CGFloat = 54
            static let dossier: CGFloat = 56
            static let molto: CGFloat = 64
            static let massimo: CGFloat = 70
        }

        enum Dock {
            static let icona: CGFloat = 50
            static let voce: CGFloat = 62
            static let padding = EdgeInsets(top: 8, leading: 10, bottom: 5, trailing: 10)
            static let spazio: CGFloat = 4
            static let dalFondo: CGFloat = 8
            static let pallino: CGFloat = 4
        }
    }
}

// MARK: - Caratteri (§1.7)

extension Tema.Apple {
    /// Un gradino della scala tipografica: dimensione, peso, spaziatura delle lettere, interlinea (multiplo
    /// della dimensione, come `line-height` CSS), maiuscolo e cifre tabellari. Si applica con `.carattereApple(_:)`.
    /// SF Pro: il sistema passa da Text a Display da 20 pt in su (`design: .default`).
    struct Carattere {
        let dimensione: CGFloat
        let peso: Font.Weight
        var tracking: CGFloat = 0
        var interlinea: CGFloat? = nil
        var maiuscolo = false
        var tabellare = false
        /// Il disegno del carattere: di sistema (SF) o, per la lettera dal futuro, serif (New York, decisione 80).
        var disegno: Font.Design = .default

        /// Interlinea propria di SF a cui si aggiunge lo spazio fra le righe.
        static let interlineaSistema: CGFloat = 1.2

        var font: Font {
            let f = Font.system(size: dimensione, weight: peso, design: disegno)
            return tabellare ? f.monospacedDigit() : f
        }

        /// Spazio fra le righe per avvicinare l'interlinea CSS (mai negativo).
        var spazioRighe: CGFloat {
            guard let i = interlinea else { return 0 }
            return max(0, dimensione * (i - Self.interlineaSistema))
        }

        /// Lo stesso gradino con le cifre tabellari.
        var tabellari: Carattere { var c = self; c.tabellare = true; return c }

        static let oraBlocco = Carattere(dimensione: 128, peso: .light, tracking: -5, interlinea: 1, tabellare: true)
        static let numeroGrande = Carattere(dimensione: 62, peso: .bold, tracking: -2.2, interlinea: 1, tabellare: true)
        static let giornoAgenda = Carattere(dimensione: 76, peso: .light, tabellare: true)
        static let valoreCursore = Carattere(dimensione: 46, peso: .bold, tracking: -1.5, tabellare: true)
        static let valoreCursoreAnalisi = Carattere(dimensione: 44, peso: .bold, tracking: -1.5, tabellare: true)
        /// Centro degli anelli: 44, 42, 36, 32 o 24 secondo l'anello.
        static func centroAnello(_ dimensione: CGFloat) -> Carattere {
            Carattere(dimensione: dimensione, peso: .bold, tabellare: true)
        }
        static let dimensioniCentroAnello: [CGFloat] = [44, 42, 36, 32, 24]
        static let saluto = Carattere(dimensione: 38, peso: .bold, tracking: -1.2)
        static let totaleScrivania = Carattere(dimensione: 36, peso: .bold, tracking: -1, tabellare: true)
        /// Solo PDF.
        static let titoloCarta = Carattere(dimensione: 36, peso: .bold, tracking: -1, interlinea: 1.05)
        /// Titolo del dettaglio: 30, 28 o 26 (tracking −0,6 a 30, altrimenti −0,5).
        static func titoloDettaglio(_ dimensione: CGFloat) -> Carattere {
            Carattere(dimensione: dimensione, peso: .bold, tracking: dimensione >= 30 ? -0.6 : -0.5)
        }
        static let nomeDossier = Carattere(dimensione: 27, peso: .bold, tracking: -0.6)
        static let valore = Carattere(dimensione: 26, peso: .bold, tracking: -0.5, tabellare: true)
        static let titoloMossa = Carattere(dimensione: 25, peso: .bold, tracking: -0.5)
        /// Gruppi del nastro; anche «Ciao, sono Vera.».
        static let titoloGruppo = Carattere(dimensione: 22, peso: .bold, tracking: -0.5, interlinea: 1.1)
        static let h2 = Carattere(dimensione: 21, peso: .bold, tracking: -0.4)
        /// Anche `.leg .n`.
        static let meseAgenda = Carattere(dimensione: 20, peso: .bold)
        /// Schede «Da fare».
        static let perche = Carattere(dimensione: 19, peso: .bold, tracking: -0.3, interlinea: 1.22)
        static let fraseVera = Carattere(dimensione: 19, peso: .semibold, tracking: -0.3, interlinea: 1.3)
        static let titoloFinestra = Carattere(dimensione: 17, peso: .bold)
        static let delta = Carattere(dimensione: 15, peso: .semibold, tabellare: true)
        /// Titoli delle righe d'impostazione.
        static let titoloRiga = Carattere(dimensione: 15, peso: .bold)
        /// Corpo della mossa, messaggi di Vera, spiegazioni (interlinea 1,45-1,55).
        static let corpoGrande = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.5)
        static let corpo = Carattere(dimensione: 14, peso: .regular)
        static let barraTitolo = Carattere(dimensione: 14, peso: .semibold)
        /// `.prep`, «Da fare oggi».
        static let voceLista = Carattere(dimensione: 13.5, peso: .regular)
        /// Barra superiore, voci del segmentato, toast, notifiche.
        static let barra = Carattere(dimensione: 13, peso: .semibold)
        static let orologio = Carattere(dimensione: 13, peso: .medium, tabellare: true)
        static let pulsante = Carattere(dimensione: 12.5, peso: .semibold)
        static let pulsanteGrande = Carattere(dimensione: 13.5, peso: .semibold)
        /// `.k`, colore `inchiostro2`.
        static let secondario = Carattere(dimensione: 12.5, peso: .regular)
        /// `.lbl`, colore `inchiostro2` o dell'area.
        static let etichetta = Carattere(dimensione: 12, peso: .semibold, tracking: 0.6, maiuscolo: true)
        /// `.sub`.
        static let sottotitolo = Carattere(dimensione: 12, peso: .medium, tracking: 0.6, maiuscolo: true)
        /// Tono dell'urgenza.
        static let quando = Carattere(dimensione: 12, peso: .bold, tracking: 0.3, maiuscolo: true)
        /// Etichette `.chA` / `.chI`.
        static let canale = Carattere(dimensione: 11.5, peso: .semibold)
        /// Etichette dei grafici, `inchiostro3`.
        static let asse = Carattere(dimensione: 11, peso: .regular, tabellare: true)
        /// Nomi del dock, `inchiostroAcqua`.
        static let dock = Carattere(dimensione: 10.5, peso: .medium)
        static let badge = Carattere(dimensione: 9, peso: .bold, tabellare: true)
    }
}

extension View {
    /// Applica un gradino della scala tipografica del tema Apple (carattere, tracking, interlinea, maiuscolo),
    /// alla «Dimensione del testo» dell'ambiente (`\.prismaScalaTesto`, ScalaTestoApple.swift).
    func carattereApple(_ c: Tema.Apple.Carattere) -> some View {
        modifier(ModificatoreCarattereApple(carattere: c))
    }
}
