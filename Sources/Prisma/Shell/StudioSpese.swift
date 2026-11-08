import SwiftUI
import UniformTypeIdentifiers

// Studio › Spese, «Chilometri, spese e scadenze» (Design/template-luce-specifica.md §6.3, template `speseHTML` righe
// 2050-2061, «Luce» giro 9):
//
//   ┌─ I chilometri di ottobre ─┐┌──── Le spese ────┐┌─ Le tue scadenze ─┐
//   │ 412 km · giri · colonne    ││ 358,80 € · righe ││ righe · ore · zip  │
//
// - Tre card piatte (senza ombra), 1,1 : 1 : 1, 14 fra loro, alte quanto l'area; sotto i 900 di larghezza in colonna.
//   Entrano a cascata; non si inclinano.
// - I chilometri vengono da MotoreChilometri sulle visite concluse dell'agenda e sui km scritti dall'utente (niente
//   servizi di percorso, decisione 22); le spese e le scadenze da MotoreSpese. Il mese: fino al giorno di cambio quello
//   prima (frecce ‹ › e colonne per cambiarlo); le scadenze guardano avanti da oggi.
// - Niente cifre inventate: dove manca un dato la card lo dice (stati del §6.3.1.7) e porta dove scriverlo.
// - «Inquadra lo scontrino» apre il foglio dove trascinare la foto o il PDF (decisione 34: niente iPhone in questo giro);
//   trascinare un file sulla card delle spese fa lo stesso. Ciò che Prisma legge è una proposta: si salva solo con
//   «Aggiungi la spesa».
// - «Prepara il pacchetto per il commercialista»: zip salvato dove sceglie l'utente, nessun invio (decisione 14).
// - Modalità cliente: Studio non si mostra (CorpoStudio). «Riduci movimento» e istantanee: tutto subito fermo.

/// I testi di Studio › Spese.
enum TestiSpese {
    static let ancoraImpostazioni = "impostazioni-spese"
    static let messaggioPacchetto = "Prisma prepara lo zip e non lo invia a nessuno: lo consegni tu al commercialista."
    static let fonteKm = "dalle visite dell’agenda"
    static let datiDiProva = "dati di prova"
    static let inquadra = "Inquadra lo scontrino"
    static let pacchetto = "Prepara il pacchetto per il commercialista"
    static let mostraNelFinder = "Mostra nel Finder"
    static let impostaPartenza = "Imposta da dove parti"
    static let impostaOre = "Imposta le ore richieste per l’anno"
    static let aggiungi = "+ Aggiungi"
    static let aggiungiAMano = "+ Aggiungi a mano"
    static let aggiungiScadenza = "+ Aggiungi scadenza"
    static let nessunaScadenza = "Aggiungi le tue scadenze: F24, acconti, polizza RC, aggiornamento."
    static let verificaCommercialista = "Le date le decidi tu: verificale con il tuo commercialista."
    static let corsiAttestati = "Gli attestati sono nei tuoi corsi."
    static let inPreparazione = "Preparo il pacchetto…"
    static let partenzaPredefinita = "Partenza"

    private static let formatoMese = Formati.formato("MMMM")
    private static let formatoGiorno = Formati.formato("d MMM")
    private static let formatoMeseBreve = Formati.formato("MMM")

    /// «ottobre».
    static func mese(_ d: Date) -> String { formatoMese.string(from: d) }
    /// «3 ott».
    static func giorno(_ d: Date) -> String { formatoGiorno.string(from: d).replacingOccurrences(of: ".", with: "") }
    /// «NOV».
    static func meseBreve(_ d: Date) -> String { formatoMeseBreve.string(from: d).replacingOccurrences(of: ".", with: "") }
    /// «G» per gennaio: l'iniziale sotto la colonna.
    static func iniziale(_ d: Date) -> String { String(mese(d).prefix(1)).uppercased() }

    static func titoloKm(_ mese: Date) -> String { "I chilometri di \(Self.mese(mese))" }

    /// «22 visite · 14 clienti».
    static func visiteClienti(_ visite: Int, _ clienti: Int) -> String {
        (visite == 1 ? "1 visita" : "\(visite) visite") + " · " + (clienti == 1 ? "1 cliente" : "\(clienti) clienti")
    }

    /// «+ altre 14 visite».
    static func altreVisite(_ n: Int) -> String { n == 1 ? "+ 1 altra visita" : "+ altre \(n) visite" }
    static func altreSpese(_ n: Int) -> String { n == 1 ? "+ 1 altra spesa" : "+ altre \(n) spese" }

    /// «3 visite senza chilometri: aggiungili».
    static func senzaKm(_ n: Int) -> String {
        n == 1 ? "1 visita senza chilometri: aggiungili" : "\(n) visite senza chilometri: aggiungili"
    }

    static func nessunKm(_ mese: Date) -> String { "Nessuna visita con i chilometri a \(Self.mese(mese))." }
    static func nessunaSpesa(_ mese: Date) -> String {
        "Nessuna spesa a \(Self.mese(mese)). Inquadra uno scontrino o aggiungila a mano."
    }

    /// «a ottobre, con gli scontrini» / «a ottobre · 3 scontrini su 5».
    static func sottoTotale(_ mese: Date, spese: [SpesaStudio]) -> String {
        let con = spese.filter { $0.scontrino != nil }.count
        if con == 0 { return "a \(Self.mese(mese))" }
        if con == spese.count { return "a \(Self.mese(mese)), con gli scontrini" }
        return "a \(Self.mese(mese)) · \(con == 1 ? "1 scontrino" : "\(con) scontrini") su \(spese.count)"
    }

    /// «28 km», «— km».
    static func km(_ v: Double?) -> String { v.map { FormatoCifra.migliaia($0) + " km" } ?? "— km" }

    /// Il fumetto di un giro: «Studio → Giulia Rossi → Laura Moretti → Studio · 28 km».
    static func percorso(_ g: MotoreChilometri.Giro, partenza: String, nome: (String) -> String) -> String {
        let p = partenza.isEmpty ? partenzaPredefinita : partenza
        let tappe = g.visite.map { $0.clienteId.isEmpty ? "senza cliente" : nome($0.clienteId) }
        return ([p] + tappe + [p]).joined(separator: " → ") + " · " + km(g.km ?? (g.kmNoti > 0 ? g.kmNoti : nil))
            + (g.corretto ? " · corretto a mano" : (g.km == nil ? " · da completare" : ""))
    }

    /// «Ore di aggiornamento dell'anno (IVASS). Gli attestati sono nei tuoi corsi.»
    static func ore(ente: String) -> String {
        "Ore di aggiornamento dell’anno" + (ente.isEmpty ? "" : " (\(ente))") + ". " + corsiAttestati
    }

    /// «22 ore nei tuoi corsi».
    static func oreFatte(_ ore: Double) -> String { "\(FormatoCifra.mesi.testo(ore)) ore nei tuoi corsi dell’anno" }

    /// «22/30».
    static func oreSu(_ fatte: Double, _ obiettivo: Double) -> String {
        "\(FormatoCifra.mesi.testo(fatte))/\(FormatoCifra.mesi.testo(obiettivo))"
    }

    static func erroreBreve(_ m: String) -> String { "Il pacchetto non è stato creato: \(m)" }
}

// MARK: - La scheda

struct SpeseStudioVista: View {
    let stato: StatoShell
    let base: Double
    let ritardoAnelli: Double

    @Environment(\.modoIstantanea) private var istantanea

    var body: some View {
        let s = stato.studioSpese
        let imp = stato.dati.impostazioni.studio.spese
        let mese = s.mese(impostazioni: imp)
        // I motori sono puri e leggeri (un mese di appuntamenti): si calcolano qui, sui campi osservati dell'archivio
        let km = MotoreChilometri.riepilogo(mese: mese, appuntamenti: stato.dati.appuntamenti, impostazioni: imp)
        let spese = MotoreSpese.delMese(stato.dati.speseStudio.spese, mese: mese)
        let archivio = stato.dati.speseStudio
        return GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                griglia(misura: geo.size, mese: mese, km: km, spese: spese, archivio: archivio, imp: imp)
            }
        }
        .sheet(item: Bindable(s).foglio) { f in
            FoglioSpese(foglio: f)
                .environment(stato)
        }
        .overlay {
            // Nelle istantanee il foglio non si disegna da sé: sta sopra la scheda, con il velo
            if istantanea, let f = s.foglio {
                ZStack {
                    Tema.Apple.Studio.Spese.Moduli.velo
                    FoglioSpese(foglio: f)
                }
            }
        }
    }

    @ViewBuilder private func griglia(misura: CGSize, mese: Date, km: MotoreChilometri.Riepilogo, spese: [SpesaStudio],
                                      archivio: ArchivioSpese, imp: ImpostazioniSpese) -> some View {
        let d = Tema.Apple.Studio.Spese.Disposizione.self
        let card1 = CardKmSpese(stato: stato, mese: mese, km: km, imp: imp).cardSpese(0, base: base)
        let card2 = CardSpeseStudio(stato: stato, mese: mese, spese: spese).cardSpese(1, base: base)
        let card3 = CardScadenzeSpese(stato: stato, archivio: archivio, imp: imp, ritardoAnelli: ritardoAnelli)
            .cardSpese(2, base: base)
        if misura.width < d.larghezzaColonna {
            VStack(alignment: .leading, spacing: d.spazio) {
                card1
                card2
                card3
            }
            .frame(width: misura.width, alignment: .topLeading)
        } else {
            let somma = d.quote.reduce(0, +)
            let libero = max(0, misura.width - d.spazio * CGFloat(d.quote.count - 1))
            let l = d.quote.map { libero * $0 / somma }
            let alta = max(d.altezzaMinima, misura.height)
            HStack(alignment: .top, spacing: d.spazio) {
                card1.frame(width: l[0], height: alta)
                card2.frame(width: l[1], height: alta)
                card3.frame(width: l[2], height: alta)
            }
            .frame(width: misura.width, alignment: .topLeading)
        }
    }
}

// MARK: - Cornice e pezzi comuni

extension View {
    /// Una card di Spese: padding 20×22, card piatta del tema (senza ombra, non si inclina) e cascata.
    fileprivate func cardSpese(_ indice: Int, base: Double) -> some View {
        let c = Tema.Apple.Studio.Spese.Card.self
        let forma = RoundedRectangle(cornerRadius: c.raggio, style: .continuous)
        return padding(c.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipShape(forma)
            .superficieApple(c.superficie, raggio: c.raggio)
            .entrataCascata(indice, base: base)
    }
}

/// Il titolo `.lbl` di una card, con «dati di prova» accanto quando serve.
private struct TitoloSpese: View {
    let testo: String
    let prova: Bool

    var body: some View {
        let c = Tema.Apple.Studio.Spese.Card.self
        HStack(alignment: .firstTextBaseline, spacing: c.spazioProva) {
            Text(testo)
                .carattereApple(c.etichetta)
                .foregroundColor(c.coloreEtichetta)
                .lineLimit(1)
                .minimumScaleFactor(c.riduzioneTesto)
                .layoutPriority(1)
            if prova {
                Text(TestiSpese.datiDiProva)
                    .carattereApple(c.prova)
                    .foregroundColor(c.coloreProva)
                    .lineLimit(1)
            }
        }
    }
}

/// Una frase `.k`.
private struct NotaSpese: View {
    let testo: String
    var colore: Color = Tema.Apple.Studio.Spese.Card.coloreNota

    init(_ testo: String, colore: Color = Tema.Apple.Studio.Spese.Card.coloreNota) {
        self.testo = testo
        self.colore = colore
    }

    var body: some View {
        Text(testo)
            .carattereApple(Tema.Apple.Studio.Spese.Card.nota)
            .foregroundColor(colore)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Un collegamento in fondo a un elenco («+ altre 14 visite», «+ Aggiungi a mano»).
private struct CollegamentoSpese: View {
    let testo: String
    var colore: Color = Tema.Apple.Studio.Spese.Card.coloreCollegamento
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            Text(testo)
                .carattereApple(Tema.Apple.Studio.Spese.Card.collegamento)
                .foregroundColor(colore)
                .lineLimit(1)
                .minimumScaleFactor(Tema.Apple.Studio.Spese.Card.riduzioneTesto)
        }
        .buttonStyle(.plain)
        .padding(.top, Tema.Apple.Studio.Spese.Card.collegamentoSopra)
    }
}

/// Il filo sotto una riga.
private struct FiloSpese: View {
    var body: some View {
        Rectangle()
            .fill(Tema.Apple.Studio.Spese.Riga.filo)
            .frame(height: Tema.Apple.Misura.bordo)
    }
}

// MARK: - Card 1 · I chilometri

private struct CardKmSpese: View {
    let stato: StatoShell
    let mese: Date
    let km: MotoreChilometri.Riepilogo
    let imp: ImpostazioniSpese

    private typealias K = Tema.Apple.Studio.Spese.Km

    private var prova: Bool { km.giri.contains { $0.visite.contains { $0.appuntamentoId.hasPrefix(SpeseDiProva.prefisso) } } }

    var body: some View {
        let c = Tema.Apple.Studio.Spese.Card.self
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: K.spazioFrecce) {
                freccia("chevron.left", -1, aiuto: "Il mese prima")
                TitoloSpese(testo: TestiSpese.titoloKm(mese), prova: prova)
                freccia("chevron.right", 1, aiuto: "Il mese dopo")
                Spacer(minLength: K.spazioFrecce)
                NotaSpese(TestiSpese.fonteKm)
                    .lineLimit(1)
            }
            if km.vuoto {
                NotaSpese(TestiSpese.nessunKm(mese))
                    .padding(.top, c.vuotoSopra)
                if imp.partenza.isEmpty {
                    Button(TestiSpese.impostaPartenza) { stato.apriImpostazioniSpese() }
                        .buttonStyle(.apple)
                        .padding(.top, c.pulsanteSopra)
                }
            } else {
                totale
                    .padding(.top, K.numeroSopra)
                NotaSpese(TestiSpese.visiteClienti(km.visite, km.clienti))
                elenco
                    .padding(.top, K.elencoSopra)
            }
            // Senza km in nessuno dei mesi il grafico non dice niente: non si disegna
            if km.serie.contains(where: { $0.km > 0 }) {
                grafico
                    .padding(.top, K.graficoSopra)
            }
            Spacer(minLength: 0)
        }
    }

    private func freccia(_ simbolo: String, _ passo: Int, aiuto: String) -> some View {
        Button {
            stato.studioSpese.sposta(passo, impostazioni: imp)
        } label: {
            Image(systemName: simbolo)
                .carattereApple(K.freccia)
                .foregroundColor(K.coloreFreccia)
        }
        .buttonStyle(.plain)
        .help(aiuto)
    }

    private var totale: some View {
        HStack(alignment: .bottom, spacing: K.spazioUnita) {
            if !km.completo {
                Text("almeno")
                    .carattereApple(K.almeno)
                    .foregroundColor(Tema.Apple.Studio.Spese.Card.coloreAvviso)
                    .padding(.bottom, K.sopraBase)
            }
            NumeroCheConta(km.totale, formato: .intero)
                .carattereApple(K.numero)
                .foregroundColor(K.coloreNumero)
                .lineLimit(1)
                .minimumScaleFactor(Tema.Apple.Studio.Spese.Card.riduzioneTesto)
            Text("km")
                .carattereApple(K.unita)
                .foregroundColor(K.coloreNumero)
                .padding(.bottom, K.sopraBase)
        }
    }

    @ViewBuilder private var elenco: some View {
        let visibili = Array(km.giri.prefix(K.righeVisibili))
        let mostrate = visibili.map(\.visite.count).reduce(0, +)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(visibili) { g in
                RigaGiroSpese(giro: g, nomi: nomi(g),
                              percorso: TestiSpese.percorso(g, partenza: imp.partenza, nome: stato.nomeClienteSpese),
                              apri: { stato.apriAgendaGiorno(g.giorno) },
                              correggi: { stato.studioSpese.foglio = .correzione(g.chiave) })
            }
            if km.visite > mostrate {
                CollegamentoSpese(testo: TestiSpese.altreVisite(km.visite - mostrate)) {
                    stato.studioSpese.foglio = .visite
                }
            }
            if km.senzaKm > 0 {
                CollegamentoSpese(testo: TestiSpese.senzaKm(km.senzaKm), colore: Tema.Apple.Studio.Spese.Card.coloreAvviso) {
                    stato.studioSpese.foglio = .visite
                }
            }
        }
    }

    private func nomi(_ g: MotoreChilometri.Giro) -> String {
        g.visite.map { $0.clienteId.isEmpty ? "Senza cliente" : stato.nomeClienteSpese($0.clienteId) }
            .joined(separator: " · ")
    }

    private var grafico: some View {
        let t = Tema.Apple.Studio.Spese.Colonne.self
        let massimo = km.serie.map(\.km).max() ?? 0
        return VStack(alignment: .leading, spacing: 0) {
            TitoloSpese(testo: "Chilometri per mese", prova: false)
            HStack(alignment: .bottom, spacing: t.spazio) {
                ForEach(Array(km.serie.enumerated()), id: \.element.id) { i, m in
                    VStack(spacing: t.etichettaSopra) {
                        ColonnaKmSpese(altezza: massimo > 0 ? t.massima * CGFloat(m.km / massimo) : 0,
                                       colore: i == km.serie.count - 1 ? t.mese : t.altri, indice: i)
                        Text(TestiSpese.iniziale(m.inizio))
                            .carattereApple(t.etichetta)
                            .foregroundColor(t.coloreEtichetta)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { stato.studioSpese.scegli(m.inizio) }
                    .help("\(TestiSpese.mese(m.inizio)) · \(TestiSpese.km(m.km))")
                }
            }
            .frame(height: t.altezza, alignment: .bottom)
            .padding(.top, t.sopra)
        }
    }
}

/// Una riga di un giro: data, clienti visitati, km. Clic: l'Agenda del giorno; doppio clic sui km: la correzione.
private struct RigaGiroSpese: View {
    let giro: MotoreChilometri.Giro
    let nomi: String
    let percorso: String
    let apri: () -> Void
    let correggi: () -> Void

    var body: some View {
        let r = Tema.Apple.Studio.Spese.Riga.self
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: r.spazio) {
                HStack(alignment: .firstTextBaseline, spacing: r.spazio) {
                    Text(TestiSpese.giorno(giro.giorno))
                        .carattereApple(r.forte)
                        .frame(width: r.data, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(Tema.Apple.Studio.Spese.Card.riduzioneTesto)
                    Text(nomi)
                        .carattereApple(r.testo)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: apri)
                Text(TestiSpese.km(giro.km))
                    .carattereApple(r.forte)
                    .foregroundColor(giro.corretto ? Tema.Apple.Studio.Spese.Km.coloreCorretto : r.colore)
                    .lineLimit(1)
                    .fixedSize()
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, perform: correggi)
                    .help(giro.corretto ? "corretto a mano · doppio clic per cambiarlo" : "Doppio clic per correggere i km del giro")
            }
            .foregroundColor(r.colore)
            .padding(.vertical, r.padding)
            FiloSpese()
        }
        .help(percorso)
    }
}

/// Una colonna dei km per mese: cresce dal basso (0,9 s, ritardo 0,20 + i·0,05); ferma con «Riduci movimento».
private struct ColonnaKmSpese: View {
    let altezza: CGFloat
    let colore: Color
    let indice: Int

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaScatto) private var scatto
    @State private var cresciuta = false

    var body: some View {
        let t = Tema.Apple.Studio.Spese.Colonne.self
        FormaColonnaStudio(alto: t.raggioSopra, basso: t.raggioSotto)
            .fill(colore)
            .frame(maxWidth: .infinity)
            .frame(height: max(0, altezza))
            .scaleEffect(x: 1, y: (fermo || cresciuta) ? 1 : 0.001, anchor: .bottom)
            .onAppear {
                guard !fermo else {
                    if !scatto { cresciuta = true }
                    return
                }
                guard !cresciuta else { return }
                let m = Tema.Apple.Studio.Spese.Moto.self
                withAnimation(m.animazioneColonne.delay(m.ritardoColonna(indice))) { cresciuta = true }
            }
    }
}

// MARK: - Card 2 · Le spese

private struct CardSpeseStudio: View {
    let stato: StatoShell
    let mese: Date
    let spese: [SpesaStudio]

    @State private var sopra = false

    private var prova: Bool { spese.contains { $0.id.hasPrefix(SpeseDiProva.prefisso) } }

    var body: some View {
        let c = Tema.Apple.Studio.Spese.Card.self
        let p = Tema.Apple.Studio.Spese.Spesa.self
        let nuova = stato.studioSpese.nuovaSpesaId
        // La spesa appena inquadrata in cima, evidenziata; le altre in ordine di data
        let ordinate = spese.filter { $0.id == nuova } + spese.filter { $0.id != nuova }
        let visibili = Array(ordinate.prefix(p.righeVisibili))
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: c.spazioProva) {
                TitoloSpese(testo: "Le spese", prova: prova)
                Spacer(minLength: c.spazioProva)
                Button {
                    stato.studioSpese.foglio = .inquadra(nil)
                } label: {
                    Label(TestiSpese.inquadra, systemImage: "viewfinder")
                }
                .buttonStyle(.apple)
                .fixedSize()
                .disabled(stato.solaLettura)
            }
            if spese.isEmpty {
                NotaSpese(TestiSpese.nessunaSpesa(mese))
                    .padding(.top, c.vuotoSopra)
                Button(TestiSpese.aggiungi) { stato.studioSpese.foglio = .nuovaSpesa }
                    .buttonStyle(.apple)
                    .padding(.top, c.pulsanteSopra)
                    .disabled(stato.solaLettura)
            } else {
                NumeroCheConta(MotoreSpese.totale(spese), formato: .personalizzato(Formati.euroDecimali))
                    .carattereApple(p.totale)
                    .foregroundColor(p.coloreTotale)
                    .lineLimit(1)
                    .padding(.top, p.totaleSopra)
                NotaSpese(TestiSpese.sottoTotale(mese, spese: spese))
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(visibili) { s in
                        RigaSpesaStudio(spesa: s, nuova: s.id == nuova) { stato.studioSpese.foglio = .spesa(s.id) }
                    }
                }
                .padding(.top, p.elencoSopra)
                if spese.count > visibili.count {
                    CollegamentoSpese(testo: TestiSpese.altreSpese(spese.count - visibili.count)) {
                        stato.studioSpese.foglio = .spese
                    }
                }
                CollegamentoSpese(testo: TestiSpese.aggiungiAMano) { stato.studioSpese.foglio = .nuovaSpesa }
                    .disabled(stato.solaLettura)
            }
            Spacer(minLength: 0)
        }
        .overlay {
            // Trascinare una foto o un PDF sulla card = inquadrare
            if sopra {
                RoundedRectangle(cornerRadius: Tema.Apple.Studio.Spese.Moduli.raggioZona, style: .continuous)
                    .strokeBorder(Tema.Apple.Studio.Spese.Moduli.bordoZonaAttiva, lineWidth: Tema.Apple.Studio.Spese.Moduli.spessoreZona)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $sopra) { fornitori in
            guard !stato.solaLettura, let f = fornitori.first else { return false }
            _ = f.loadObject(ofClass: URL.self) { url, _ in
                guard let url, LetturaDocumenti.estensioniAccettate.contains(url.pathExtension.lowercased()) else { return }
                DispatchQueue.main.async { stato.studioSpese.foglio = .inquadra(url) }
            }
            return true
        }
    }
}

/// Una riga di spesa: miniatura dello scontrino, descrizione con la data, importo. Clic: il dettaglio.
private struct RigaSpesaStudio: View {
    let spesa: SpesaStudio
    let nuova: Bool
    let apri: () -> Void

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaScatto) private var scatto
    @State private var entrata = false

    var body: some View {
        let r = Tema.Apple.Studio.Spese.Riga.self
        let p = Tema.Apple.Studio.Spese.Spesa.self
        let m = Tema.Apple.Studio.Spese.Moto.self
        let evidenza: Color? = spesa.daControllare ? p.evidenzaControllo : (nuova ? p.evidenzaNuovo : nil)
        let mostrata = fermo || entrata || !nuova
        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: r.spazioSpese) {
                MiniaturaScontrino(conScontrino: spesa.scontrino != nil)
                VStack(alignment: .leading, spacing: 0) {
                    Text(spesa.descrizione.isEmpty ? spesa.categoria.nome : spesa.descrizione)
                        .carattereApple(r.testo)
                        .foregroundColor(r.colore)
                        .lineLimit(1)
                    Text(sotto)
                        .carattereApple(r.sotto)
                        .foregroundColor(spesa.daControllare ? Tema.Apple.Studio.Spese.Card.coloreAvviso : r.coloreSotto)
                        .lineLimit(1)
                }
                Spacer(minLength: r.spazioSpese)
                Text(Formati.euroDecimali(spesa.importo))
                    .carattereApple(r.forte)
                    .foregroundColor(r.colore)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.vertical, r.padding)
            .padding(.horizontal, evidenza == nil ? 0 : r.margineEvidenza)
            .background {
                if let evidenza {
                    RoundedRectangle(cornerRadius: r.raggioEvidenza, style: .continuous).fill(evidenza)
                }
            }
            FiloSpese()
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: apri)
        .opacity(mostrata ? 1 : 0)
        .scaleEffect(mostrata ? 1 : m.scala)
        .offset(y: mostrata ? 0 : m.spostamento)
        .onAppear {
            guard nuova, !fermo, !entrata else {
                if fermo && !scatto { entrata = true }
                return
            }
            withAnimation(m.animazioneScontrino) { entrata = true }
        }
    }

    private var sotto: String {
        let g = TestiSpese.giorno(spesa.data)
        if spesa.daControllare { return "\(g) · da controllare" }
        if nuova && spesa.letta { return "\(Calendar.current.isDateInToday(spesa.data) ? "oggi" : g) · letto dallo scontrino" }
        return g
    }
}

/// La miniatura 26×32 di uno scontrino (vuota se la spesa non ne ha).
struct MiniaturaScontrino: View {
    let conScontrino: Bool

    var body: some View {
        let t = Tema.Apple.Studio.Spese.Scontrino.self
        let forma = RoundedRectangle(cornerRadius: t.raggio, style: .continuous)
        forma.fill(conScontrino ? t.fondo : Color.clear)
            .overlay(forma.strokeBorder(t.bordo, lineWidth: Tema.Apple.Misura.bordo))
            .overlay {
                if conScontrino {
                    Image(systemName: "doc.text")
                        .carattereApple(t.simbolo)
                        .foregroundColor(t.coloreSimbolo)
                }
            }
            .frame(width: t.miniatura.width, height: t.miniatura.height)
            .help(conScontrino ? "Con lo scontrino" : "Senza scontrino")
    }
}

// MARK: - Card 3 · Le scadenze

private struct CardScadenzeSpese: View {
    let stato: StatoShell
    let archivio: ArchivioSpese
    let imp: ImpostazioniSpese
    let ritardoAnelli: Double

    var body: some View {
        let c = Tema.Apple.Studio.Spese.Card.self
        let oggi = Date()
        let anno = Calendar.current.component(.year, from: oggi)
        let prossime = MotoreSpese.prossime(archivio.scadenze, oggi: oggi)
        let fatte = MotoreSpese.ore(archivio.corsi, anno: anno)
        let obiettivo = imp.oreAggiornamentoAnno[anno]
        let prova = prossime.contains { $0.id.hasPrefix(SpeseDiProva.prefisso) }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: c.spazioProva) {
                TitoloSpese(testo: "Le tue scadenze", prova: prova)
                Spacer(minLength: 0)
            }
            if prossime.isEmpty {
                NotaSpese(TestiSpese.nessunaScadenza)
                    .padding(.top, c.vuotoSopra)
                Button(TestiSpese.aggiungi) { stato.studioSpese.foglio = .nuovaScadenza }
                    .buttonStyle(.apple)
                    .padding(.top, c.pulsanteSopra)
                    .disabled(stato.solaLettura)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(prossime) { s in
                        RigaScadenzaSpese(scadenza: s, oggi: oggi, riga: riga(s, fatte: fatte, obiettivo: obiettivo),
                                          apri: { stato.studioSpese.foglio = .scadenza(s.id) },
                                          fatta: { stato.segnaScadenzaFatta(s.id) })
                    }
                }
                CollegamentoSpese(testo: TestiSpese.aggiungiScadenza) { stato.studioSpese.foglio = .nuovaScadenza }
                    .disabled(stato.solaLettura)
            }
            ore(fatte: fatte, obiettivo: obiettivo)
                .padding(.top, Tema.Apple.Studio.Spese.Ore.sopra)
            Spacer(minLength: Tema.Apple.Studio.Spese.Ore.sopra)
            pacchetto
        }
    }

    private func riga(_ s: ScadenzaStudio, fatte: Double, obiettivo: Double?) -> String {
        var parti: [String] = []
        if s.tipo == .aggiornamento, let obiettivo {
            parti.append("\(FormatoCifra.mesi.testo(fatte)) ore su \(FormatoCifra.mesi.testo(obiettivo))")
        }
        if let i = s.importo { parti.append(Formati.euroDecimali(i)) }
        if !s.nota.isEmpty { parti.append(s.nota) }
        if parti.isEmpty, let r = s.ricorrenza { parti.append(r.nome.lowercased()) }
        return parti.joined(separator: " · ")
    }

    @ViewBuilder private func ore(fatte: Double, obiettivo: Double?) -> some View {
        let o = Tema.Apple.Studio.Spese.Ore.self
        if let obiettivo, obiettivo > 0 {
            Button {
                stato.studioSpese.foglio = .corsi
            } label: {
                HStack(alignment: .center, spacing: o.spazio) {
                    AnelliConcentrici(voci: [VoceAnello(id: "ore", valore: MotoreSpese.percentualeOre(fatte: fatte, obiettivo: obiettivo) ?? 0,
                                                        colore: o.colore)],
                                      misura: o.anello, spessore: o.spessore, ritardo: ritardoAnelli) {
                        Text(TestiSpese.oreSu(fatte, obiettivo))
                            .carattereApple(o.centro)
                            .foregroundColor(o.coloreCentro)
                    }
                    .frame(width: o.anello, height: o.anello)
                    Text(TestiSpese.ore(ente: imp.enteAggiornamento))
                        .carattereApple(o.testo)
                        .foregroundColor(o.coloreTesto)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("I tuoi corsi dell’anno, con le ore e gli attestati")
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    stato.studioSpese.foglio = .corsi
                } label: {
                    NotaSpese(TestiSpese.oreFatte(fatte))
                }
                .buttonStyle(.plain)
                Button(TestiSpese.impostaOre) { stato.apriImpostazioniSpese() }
                    .buttonStyle(.apple)
                    .padding(.top, Tema.Apple.Studio.Spese.Card.pulsanteSopra)
            }
        }
    }

    @ViewBuilder private var pacchetto: some View {
        let t = Tema.Apple.Studio.Spese.Pacchetto.self
        VStack(alignment: .leading, spacing: 0) {
            Button {
                #if os(macOS)
                stato.preparaPacchettoSpese()
                #endif
            } label: {
                Text(TestiSpese.pacchetto)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.applePrimarioGrande)
            .disabled(inPreparazione)
            switch stato.studioSpese.pacchetto {
            case .nessuno:
                EmptyView()
            case .inPreparazione(let f):
                BarraPiena(frazione: f, colore: t.coloreBarra, altezza: t.barra, raggio: t.raggioBarra)
                    .padding(.top, t.sopra)
                    .help(TestiSpese.inPreparazione)
            case .pronto(let url, let nome, let descrizione):
                TilePacchettoSpese(nome: nome, descrizione: descrizione, url: url)
                    .padding(.top, t.sopra)
                    .entrataCascata(0, base: 0)
            case .errore(let m):
                NotaSpese(TestiSpese.erroreBreve(m), colore: t.coloreErrore)
                    .padding(.top, t.sopra)
            }
        }
    }

    private var inPreparazione: Bool {
        if case .inPreparazione = stato.studioSpese.pacchetto { return true }
        return false
    }
}

/// Una scadenza: il blocco della data (mese nel colore del tipo, giorno), titolo e riga; il cerchio la segna fatta.
private struct RigaScadenzaSpese: View {
    let scadenza: ScadenzaStudio
    let oggi: Date
    let riga: String
    let apri: () -> Void
    let fatta: () -> Void

    var body: some View {
        let t = Tema.Apple.Studio.Spese.Scadenza.self
        let passata = MotoreSpese.passata(scadenza, oggi: oggi)
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: t.spazio) {
                VStack(spacing: 0) {
                    Text(TestiSpese.meseBreve(scadenza.data))
                        .carattereApple(t.mese)
                        .foregroundColor(passata ? t.colorePassata : t.colore(scadenza.tipo))
                    Text(Formati.giorno.string(from: scadenza.data))
                        .carattereApple(t.giorno)
                        .foregroundColor(t.coloreGiorno)
                }
                .frame(width: t.blocco)
                VStack(alignment: .leading, spacing: 0) {
                    Text(scadenza.titolo)
                        .carattereApple(t.titolo)
                        .foregroundColor(t.coloreTitolo)
                        .lineLimit(1)
                    let testo = passata ? (riga.isEmpty ? "passata: segnala fatta" : "passata · " + riga) : riga
                    if !testo.isEmpty {
                        Text(testo)
                            .carattereApple(t.riga)
                            .foregroundColor(passata ? t.colorePassata : t.coloreRiga)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: apri)
                Button(action: fatta) {
                    Image(systemName: "circle")
                        .resizable()
                        .frame(width: t.spunta, height: t.spunta)
                        .foregroundColor(t.coloreSpunta)
                }
                .buttonStyle(.plain)
                .help(scadenza.ricorrenza == nil ? "Segna fatta" : "Segna fatta: nasce la prossima")
            }
            .padding(.vertical, t.padding)
            FiloSpese()
        }
    }
}

/// «✓ Ottobre-2026.zip» con il bordo verde, la descrizione e «Mostra nel Finder».
private struct TilePacchettoSpese: View {
    let nome: String
    let descrizione: String
    let url: URL?

    var body: some View {
        let t = Tema.Apple.Studio.Spese.Pacchetto.self
        let forma = RoundedRectangle(cornerRadius: t.raggioTile, style: .continuous)
        return HStack(alignment: .center, spacing: t.spazioTile) {
            VStack(alignment: .leading, spacing: t.spazioTile) {
                Text("✓ \(nome)")
                    .carattereApple(t.titolo)
                    .foregroundColor(t.coloreFatto)
                    .lineLimit(1)
                    .minimumScaleFactor(Tema.Apple.Studio.Spese.Card.riduzioneTesto)
                NotaSpese(descrizione)
            }
            Spacer(minLength: t.spazioTile)
            #if os(macOS)
            if let url {
                Button(TestiSpese.mostraNelFinder) { FileFattura.mostra(url) }
                    .buttonStyle(.appleSobrio)
                    .fixedSize()
            }
            #endif
        }
        .padding(t.paddingTile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(t.tile, raggio: t.raggioTile)
        .overlay(forma.strokeBorder(t.bordoFatto, lineWidth: Tema.Apple.Misura.bordo))
    }
}
