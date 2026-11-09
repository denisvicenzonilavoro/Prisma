import SwiftUI

// «Le 25 novità di Vera» (Vera/BRIEF.md; Design/template-vera.html, pannello `#novP` e indice `#side`): le venticinque
// funzioni del brief nei cinque gruppi del template, tutte accese. Il pannello si apre dalla testata di Vera («✦ Novità») e
// dal pannello «Le novità» di Prisma («Le 25 novità di Vera»); ogni voce porta dove la funzione si prova: una pagina di Vera
// (routine, tagliando, memoria, su misura, motori), l'app giusta (il dossier per il sussurro, Impostazioni per il filo
// lungo) oppure la chat con una frase d'esempio già scritta nel campo, da mandare con Invio (niente parte da sola). Mai in
// modalità cliente: le voci portano anche a pagine che parlano di tutti i clienti.

/// Una delle 25 novità di Vera, con il numero del brief e del template.
enum NovitaVera: String, CaseIterable, Identifiable {
    // Vera che fa le cose
    case falloTu, clientela, routine, agenda, tagliando
    // Vera che conosce i tuoi clienti
    case trentaSecondi, sussurro, promesse, lasciaCadere
    // Vera che legge e controlla
    case secondaLettura, differenze, cosaNonCopre, codiceInTasca, mercato
    // Vera che scrive come te
    case scriveComeTe, resoconto, treLivelli
    // Vera più intelligente
    case memoria, maiACaso, ragionaAPassi, impara, suMisura, dueVelocita, filoLungo, cervelloGrande

    var id: String { rawValue }

    /// I cinque gruppi del template, con il loro colore (`Tema.Apple.PannelloVeraNovita.colori`).
    enum Gruppo: Int, CaseIterable, Identifiable {
        case faLeCose, conosceIClienti, leggeEControlla, scriveComeTe, piuIntelligente

        var id: Int { rawValue }

        var titolo: String {
            switch self {
            case .faLeCose: return "Vera che fa le cose"
            case .conosceIClienti: return "Vera che conosce i tuoi clienti"
            case .leggeEControlla: return "Vera che legge e controlla"
            case .scriveComeTe: return "Vera che scrive come te"
            case .piuIntelligente: return "Vera più intelligente"
            }
        }

        var colore: Color { Tema.Apple.PannelloVeraNovita.colori[rawValue] }

        var voci: [NovitaVera] { NovitaVera.allCases.filter { $0.gruppo == self } }
    }

    /// Il numero del brief e del template (1…25).
    var numero: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }

    var gruppo: Gruppo {
        switch self {
        case .falloTu, .clientela, .routine, .agenda, .tagliando: return .faLeCose
        case .trentaSecondi, .sussurro, .promesse, .lasciaCadere: return .conosceIClienti
        case .secondaLettura, .differenze, .cosaNonCopre, .codiceInTasca, .mercato: return .leggeEControlla
        case .scriveComeTe, .resoconto, .treLivelli: return .scriveComeTe
        case .memoria, .maiACaso, .ragionaAPassi, .impara, .suMisura, .dueVelocita, .filoLungo, .cervelloGrande: return .piuIntelligente
        }
    }

    var titolo: String {
        switch self {
        case .falloTu: return "Fallo tu"
        case .clientela: return "Chiedi alla tua clientela"
        case .routine: return "Le routine"
        case .agenda: return "L’agenda che si organizza"
        case .tagliando: return "Il tagliando dei dati"
        case .trentaSecondi: return "Il cliente in 30 secondi"
        case .sussurro: return "Il sussurro"
        case .promesse: return "Le promesse"
        case .lasciaCadere: return "Lascia cadere qui"
        case .secondaLettura: return "La seconda lettura"
        case .differenze: return "Trova le differenze"
        case .cosaNonCopre: return "Cosa non copre"
        case .codiceInTasca: return "Il codice in tasca"
        case .mercato: return "Il mercato per i tuoi clienti"
        case .scriveComeTe: return "Scrive come te"
        case .resoconto: return "Il resoconto dell’incontro"
        case .treLivelli: return "Tre livelli"
        case .memoria: return "La memoria"
        case .maiACaso: return "Mai a caso"
        case .ragionaAPassi: return "Ragiona a passi"
        case .impara: return "Impara dalle correzioni"
        case .suMisura: return "Vera su misura"
        case .dueVelocita: return "Due velocità"
        case .filoLungo: return "Il filo lungo"
        case .cervelloGrande: return "Il cervello grande"
        }
    }

    /// La frase del template, con ciò che Prisma fa davvero (il modello Apple è spento, il motore esterno non è collegato,
    /// l'esportazione di «Vera su misura» aspetta la tua approvazione).
    var frase: String {
        switch self {
        case .falloTu: return "Le chiedi una cosa a parole e Vera la fa, in qualsiasi app di Prisma, dopo la tua conferma"
        case .clientela: return "Domande su tutti i clienti insieme: Vera le traduce in filtri, Prisma fa il calcolo"
        case .routine: return "Sequenze di lavoro salvate una volta e lanciate con una frase"
        case .agenda: return "Gli orari giusti, gli spostamenti in blocco, due orari da proporre al cliente"
        case .tagliando: return "Ogni notte il controllo dell’archivio: tu approvi le correzioni"
        case .trentaSecondi: return "Prima di una chiamata, la relazione raccontata in cinque punti"
        case .sussurro: return "Aprendo la scheda, le due o tre cose da sapere adesso"
        case .promesse: return "Gli impegni presi con i clienti, ricordati prima che scadano"
        case .lasciaCadere: return "Trascini un documento: Vera capisce cos’è, di chi è e dove va"
        case .secondaLettura: return "Prima che esca, Vera rilegge: profilo, numeri, frasi a rischio, allegati"
        case .differenze: return "Due documenti a confronto, voce per voce"
        case .cosaNonCopre: return "Esclusioni, carenze, franchigie e massimali, ognuno con l’articolo"
        case .codiceInTasca: return "Le norme che hai caricato, con l’articolo citato"
        case .mercato: return "Un evento di mercato e i clienti che tocca, con cosa fare"
        case .scriveComeTe: return "Il tuo stile, imparato dai messaggi che hai mandato"
        case .resoconto: return "Il verbale dell’incontro dalla nota vocale e dal copilota"
        case .treLivelli: return "La stessa spiegazione per te, per il cliente e in una pagina"
        case .memoria: return "I ricordi su di te e sui clienti: si vedono, si correggono, si cancellano"
        case .maiACaso: return "Ogni cifra con la sua fonte; se manca, Vera lo dice"
        case .ragionaAPassi: return "Un piano visibile, eseguito un passo alla volta con i motori di Prisma"
        case .impara: return "Pollici e correzioni diventano lezioni"
        case .suMisura: return "L’addestramento sui tuoi esempi resi anonimi, solo se supera l’esame"
        case .dueVelocita: return "Le cose rapide alle regole di Prisma, il resto a Qwen (il modello Apple è spento)"
        case .filoLungo: return "Più contesto e un riassunto progressivo: nelle chat lunghe Vera non perde il filo"
        case .cervelloGrande: return "Un motore esterno predisposto e non collegato: i dati dei clienti restano sul Mac"
        }
    }

    /// Tutte le 25 sono in Prisma (le fasi 1-5 del brief): nessuna voce «in arrivo».
    var disponibile: Bool { true }

    /// La frase d'esempio che la voce scrive nel campo di Vera (nil per le voci che aprono una pagina o un'app).
    /// `nome` è il nome del cliente aperto (o del primo dell'archivio).
    func esempio(nome: String) -> String? {
        switch self {
        case .falloTu: return "Liberami venerdì pomeriggio"
        case .clientela: return "Chi compie 50 anni entro marzo?"
        case .agenda: return "Trovami un'ora per il riesame di \(nome) entro giovedì, attaccata a un altro incontro in studio"
        case .trentaSecondi: return "Raccontami \(nome) in 30 secondi"
        case .promesse: return "Tutte le mie promesse"
        case .secondaLettura: return "Rileggi: "
        case .differenze: return "Confronta la polizza di \(nome) con la proposta"
        case .cosaNonCopre: return "Cosa non copre la polizza di \(nome)?"
        case .codiceInTasca: return "Entro quanto un cliente può ripensarci dopo aver firmato una polizza vita?"
        case .mercato: return "Le borse hanno perso l'8% in una settimana"
        case .scriveComeTe: return "Mostrami il mio stile"
        case .resoconto: return "Il resoconto dell'incontro con \(nome)"
        case .treLivelli: return "Perché il fondo pensione conviene a \(nome)?"
        case .maiACaso: return "Quanto vale il patrimonio di \(nome)?"
        case .ragionaAPassi: return "\(nome) ha 400 € al mese: protezione e obiettivi, come li divido?"
        default: return nil
        }
    }

    /// Le richieste su tutti i clienti vanno nella conversazione del portafoglio.
    var nelPortafoglio: Bool { [.clientela, .promesse, .mercato, .agenda].contains(self) }
}

extension StatoShell {
    /// Apre il pannello «Le 25 novità di Vera» sopra la finestra di Vera (chiude le altre pagine di Vera e le Novità).
    func apriNovitaVera() {
        guard !inModoCliente else {
            return mostraAvviso("In modalità cliente le novità di Vera non si aprono: portano anche a pagine su tutti i clienti.")
        }
        chiudiNovita()
        paginaTagliandoAperta = false
        paginaSuMisuraAperta = false
        paginaMotoriAperta = false
        if !aperta(.vera) { apri(.vera) }
        paginaNovitaVeraAperta = true
    }

    func chiudiNovitaVera() {
        paginaNovitaVeraAperta = false
    }

    /// Una voce del pannello: chiude il pannello e porta dove la funzione si prova.
    func apriVoceNovitaVera(_ v: NovitaVera) {
        chiudiNovitaVera()
        guard !inModoCliente else { return }
        let cliente = clienteAttivo ?? dati.clienti.first
        let nome = cliente.map { $0.nome.split(separator: " ").first.map(String.init) ?? $0.nome } ?? "Marco"
        switch v {
        case .routine: apriPaginaRoutine()
        case .tagliando: apriPaginaTagliando()
        case .suMisura: apriPaginaSuMisura()
        case .dueVelocita: apriPaginaMotori(.dueVelocita)
        case .cervelloGrande: apriPaginaMotori(.cervello)
        case .memoria, .impara:
            if !aperta(.vera) { apri(.vera) }
            memoriaVera.aperta = true
        case .sussurro:
            // Il dossier del cliente aperto, sulla Panoramica: lì Vera sussurra
            if let c = cliente, clienteAttivoId != c.id { clienteAttivoId = c.id }
            schedaCliente = .panoramica
            apri(.clienti)
        case .filoLungo:
            schedaImpostazioni = .vera
            apri(.impostazioni)
            mostraAvviso("«Il filo lungo»: la finestra di Vera (8.000, 16.000 o 32.000 token) è in Impostazioni › Vera.")
        case .lasciaCadere:
            if !aperta(.vera) { apri(.vera) }
            mostraAvviso("Trascina un documento su Vera o sulla scrivania: lo leggo sul Mac e ti dico dove va.")
        default:
            guard let frase = v.esempio(nome: nome) else { return }
            // La frase d'esempio nel campo, nella conversazione giusta: si manda con Invio, niente parte da sola
            if v.nelPortafoglio { veraPortafoglio = true } else if veraPortafoglio { veraPortafoglio = false }
            if !aperta(.vera) { apri(.vera) }
            domandaVera = frase
        }
    }
}

// MARK: - Le viste

extension View {
    /// Il pannello «Le 25 novità di Vera» sopra la finestra di Vera, quando `paginaNovitaVeraAperta`.
    func paginaNovitaVera() -> some View { modifier(ModificatoreNovitaVera()) }
}

private struct ModificatoreNovitaVera: ViewModifier {
    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        let aperta = stato.paginaNovitaVeraAperta && !stato.inModoCliente
        content
            .overlay {
                if aperta {
                    ZStack(alignment: .top) {
                        Tema.Apple.SuMisura.velo
                            .contentShape(Rectangle())
                            .onTapGesture { stato.chiudiNovitaVera() }
                        PannelloNovitaVera()
                            .padding(Tema.Apple.PannelloVeraNovita.bordo)
                    }
                    .transition(.opacity)
                }
            }
            .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.uscita(Tema.Apple.SuMisura.durataCambio), calmo: calmo, istantanea: istantanea), value: aperta)
    }
}

/// Il pannello del template (`#novP`): la sfera e «Le 25 novità di Vera», «Chiudi», cinque colonne con le voci numerate.
struct PannelloNovitaVera: View {
    @Environment(StatoShell.self) var stato
    private typealias N = Tema.Apple.PannelloVeraNovita

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(alignment: .leading, spacing: N.sopraGriglia) {
            HStack(spacing: N.spazioTestata) {
                SferaVera(misura: N.sfera, viva: true, pensa: false)
                Text("Le \(NovitaVera.allCases.count) novità di Vera").carattereApple(N.titolo).foregroundColor(Tema.Apple.Colore.inchiostro)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Text("Tutte sul Mac · scegli una novità per provarla").carattereApple(N.nota).foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(1)
                Button("Chiudi") { stato.chiudiNovitaVera() }
                    .buttonStyle(.apple).fixedSize()
                    .keyboardShortcut(.cancelAction)
            }
            HStack(alignment: .top, spacing: N.spazioColonne) {
                ForEach(NovitaVera.Gruppo.allCases) { g in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Circle().fill(g.colore).frame(width: N.puntoGruppo, height: N.puntoGruppo)
                            Text(g.titolo).carattereApple(N.gruppo).foregroundColor(g.colore).lineLimit(1).minimumScaleFactor(0.85)
                        }
                        .padding(N.paddingGruppo)
                        .accessibilityAddTraits(.isHeader)
                        ForEach(g.voci) { v in
                            VoceNovitaVera(voce: v)
                                .entrataCascata(v.numero - 1, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .padding(N.padding)
        .frame(maxWidth: N.larghezza)
        .superficieApple(N.superficie, raggio: N.raggio)
    }
}

/// Una voce (`.novI`): il pallino colorato con il numero e il titolo; sotto il puntatore il fondo `chip`.
private struct VoceNovitaVera: View {
    @Environment(StatoShell.self) var stato
    let voce: NovitaVera
    @State private var sopra = false
    private typealias N = Tema.Apple.PannelloVeraNovita

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: N.raggioVoce, style: .continuous)
        Button { stato.apriVoceNovitaVera(voce) } label: {
            HStack(spacing: N.spazioVoce) {
                Text("\(voce.numero)")
                    .carattereApple(N.numero)
                    .foregroundColor(N.numeroColore)
                    .frame(width: N.pallino, height: N.pallino)
                    .background(Circle().fill(voce.gruppo.colore))
                Text(voce.titolo)
                    .carattereApple(N.voce)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(N.paddingVoce)
            .background { if sopra { forma.fill(N.fondoPassaggio) } }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { s in withAnimation(Tema.Apple.Moto.VoceNovita.passaggio) { sopra = s } }
        .help(voce.frase)
        .accessibilityLabel(Text("\(voce.numero). \(voce.titolo): \(voce.frase)"))
    }
}

/// «✦ Novità» nella testata di Vera: apre «Le 25 novità di Vera». Non in modalità cliente.
struct PulsanteNovitaVera: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        if !stato.inModoCliente {
            Button { stato.apriNovitaVera() } label: { Text("✦ Novità") }
                .buttonStyle(StileVetro())
                .help("Le 25 novità di Vera")
        }
    }
}

// MARK: - Prova

/// Le 25 novità di Vera dentro `Prisma --prova-vera`: numeri, gruppi del template, tutte accese, ogni voce porta dove la
/// funzione si prova (una pagina, un'app o la chat con la frase d'esempio, mai mandata da sola), e niente in modalità cliente.
enum ProvaNovitaVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let tutte = NovitaVera.allCases
        controlla(tutte.count == 25 && tutte.map(\.numero) == Array(1...25) && tutte.allSatisfy(\.disponibile)
                  && Set(tutte.map(\.titolo)).count == 25,
                  "Novità di Vera: 25 voci numerate da 1 a 25, tutte accese")
        controlla(NovitaVera.Gruppo.allCases.map { $0.voci.count } == [5, 4, 5, 3, 8]
                  && NovitaVera.falloTu.numero == 1 && NovitaVera.trentaSecondi.numero == 6 && NovitaVera.lasciaCadere.numero == 9
                  && NovitaVera.mercato.numero == 14 && NovitaVera.resoconto.numero == 16 && NovitaVera.ragionaAPassi.numero == 20
                  && NovitaVera.cervelloGrande.numero == 25,
                  "Novità di Vera: i cinque gruppi del template, con i numeri del brief")
        controlla(NovitaVera.dueVelocita.frase.contains("spento") && NovitaVera.cervelloGrande.frase.contains("non collegato"),
                  "Novità di Vera: le frasi dicono ciò che Prisma fa davvero (modello Apple spento, motore esterno non collegato)")
        for v in tutte {
            let s = StatoShell(persistente: false)
            s.clienteAttivoId = "marco"
            s.apriNovitaVera()
            guard s.paginaNovitaVeraAperta, s.aperta(.vera) else { return controlla(false, "Novità di Vera: il pannello si apre sopra Vera") }
            let messaggi = s.conversazione("marco").count + s.conversazione(VeraPortafoglio.chiave).count
            s.apriVoceNovitaVera(v)
            let nessunaRisposta = s.conversazione("marco").count + s.conversazione(VeraPortafoglio.chiave).count == messaggi
            let dove: Bool
            switch v {
            case .routine: dove = s.paginaRoutineVera
            case .tagliando: dove = s.paginaTagliandoAperta
            case .suMisura: dove = s.paginaSuMisuraAperta
            case .dueVelocita: dove = s.paginaMotoriAperta && s.schedaMotori == .dueVelocita
            case .cervelloGrande: dove = s.paginaMotoriAperta && s.schedaMotori == .cervello
            case .memoria, .impara: dove = s.memoriaVera.aperta
            case .sussurro: dove = s.aperta(.clienti) && s.schedaCliente == .panoramica
            case .filoLungo: dove = s.aperta(.impostazioni) && s.schedaImpostazioni == .vera
            case .lasciaCadere: dove = s.aperta(.vera)
            default: dove = s.aperta(.vera) && !s.domandaVera.isEmpty
            }
            controlla(!s.paginaNovitaVeraAperta && dove && nessunaRisposta, "Novità di Vera: «\(v.titolo)» porta dove si prova (e niente parte da solo)")
        }
        let s = StatoShell(persistente: false)
        s.modoCliente = "giulia"
        s.apriNovitaVera()
        controlla(!s.paginaNovitaVeraAperta, "Novità di Vera: in modalità cliente il pannello non si apre")
    }
}
