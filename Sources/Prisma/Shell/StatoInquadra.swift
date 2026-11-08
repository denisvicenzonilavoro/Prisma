import Combine
import Observation
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// Inquadra e capisci (Design/template-novita-specifica.md §9, Orizzonte giro 5): lo stato della scena.
// - Sul Mac il pulsante «◎ Inquadra con l’iPhone» (testata di Posizioni › Portafoglio) o la voce 6 delle Novità aprono
//   la scena: con il ponte acceso (Impostazioni › Vera › iPhone e iPad) si aspetta il testo dall'iPhone, altrimenti si
//   trascina una foto o un PDF, letti sul Mac con LetturaDocumenti (Vision, sul dispositivo).
// - I campi trovati (MotoreInquadra) si illuminano sul foglio uno alla volta e compaiono nella scheda «Prisma sul Mac».
// - Niente entra nel dossier senza conferma: «Aggiungi a Posizioni di …» chiede di confermare i dati letti, poi crea il
//   documento (senza file: la foto non si salva) e la posizione in essere con `creaDaDocumento`.
// - «Confronta»: se la polizza è già in Prisma, il confronto «Nel documento / In Prisma» di Documenti; altrimenti la
//   tabella con una temporanea caso morte (tariffa delle temporanee in archivio, fabbisogno della famiglia).
// - Sull'iPhone lo stesso oggetto tiene il foglio letto con la fotocamera e l'invio al Mac (iOS/InquadraTelefono.swift).
// La foto vive solo in memoria e se ne va alla chiusura. I passi della cascata sono `asyncAfter` legati al giro:
// chiudendo a metà, i passi in attesa non fanno più nulla (niente Timer).

/// A che punto è la scena.
enum FaseInquadra: Equatable {
    /// Il ponte con l'iPhone è acceso: si aspetta il testo inquadrato (si può anche trascinare un file).
    case attesa
    /// Il ponte è spento: si trascina una foto o un PDF.
    case trascina
    /// Il Mac sta leggendo il file.
    case lettura
    /// I dati ci sono (tutti o una parte).
    case letto
    /// Il riconoscimento non ha trovato niente.
    case illeggibile
}

/// Lo stato della scena (un oggetto a parte: la cascata non pubblica StatoShell e le altre app non si ridisegnano).
@Observable final class StatoInquadra {
    private(set) var aperto = false
    private(set) var fase: FaseInquadra = .trascina
    /// Le righe lette, il risultato del motore e (solo per una foto trascinata o scattata) l'immagine, in memoria.
    private(set) var righe: [RigaLetta] = []
    private(set) var dati: DatiInquadrati?
    private(set) var immagine: ImmaginePiattaforma?
    /// Da dove viene il testo: «iPhone di Denis», «polizza.jpg».
    private(set) var origine = ""
    /// L'inquadratura arrivata sul ponte (esce da quelle in arrivo quando entra nel dossier).
    private(set) var inquadraturaId: String?
    /// Il cliente scelto (dall'iPhone o dal menu); nil = quello probabile.
    var clienteScelto: String?
    /// Quante righe della scheda si vedono (la cascata) e se la lettura è finita («✓ Fatto», i pulsanti).
    private(set) var mostrate = 0
    private(set) var finito = false
    /// La tabella del confronto con una temporanea (dopo «Confronta»).
    var confronto: ConfrontoTemporanea?
    /// «Aggiungi…» chiede di confermare i dati letti.
    var conferma = false
    /// Un file trascinato sopra la zona.
    var fileSopra = false
    /// iPhone: la schermata della fotocamera è aperta; l'invio al Mac in corso e la sua ricevuta.
    var telefonoAperto = false
    var inInvio = false
    var ricevuta: RicevutaPonte?
    /// Ogni apertura, foglio nuovo o chiusura cambia il giro: i passi in attesa di un giro vecchio non fanno nulla.
    @ObservationIgnored private(set) var giro = 0

    /// Le righe della scheda (cinque per le polizze), con il canale proposto.
    func righeScheda(canale: Canale) -> [RigaInquadra] {
        dati.map { MotoreInquadra.righe($0, canale: canale) } ?? []
    }

    /// Solo una parte dei dati: meno di quattro righe trovate.
    var pochiDati: Bool {
        guard let d = dati else { return false }
        return MotoreInquadra.righe(d, canale: .indipendente).filter(\.trovata).count < MotoreInquadra.righeMinime
    }

    /// Apre la scena in attesa (o sul trascinamento), senza foglio.
    func apri(fase: FaseInquadra) {
        giro += 1
        svuota()
        self.fase = fase
        aperto = true
    }

    func chiudi() {
        giro += 1
        aperto = false
        svuota()
    }

    /// Torna all'attesa (o al trascinamento) dopo «Riprova».
    func ricomincia(fase: FaseInquadra) {
        giro += 1
        svuota()
        self.fase = fase
    }

    private func svuota() {
        righe = []
        dati = nil
        immagine = nil
        origine = ""
        inquadraturaId = nil
        clienteScelto = nil
        mostrate = 0
        finito = false
        confronto = nil
        conferma = false
        fileSopra = false
        ricevuta = nil
        inInvio = false
    }

    /// Il Mac comincia a leggere un file: il giro nuovo, da passare a `mostra`.
    func inizioLettura(origine: String) -> Int {
        giro += 1
        svuota()
        self.origine = origine
        fase = .lettura
        return giro
    }

    /// Il foglio letto: i campi dal motore, poi la cascata delle righe (dopo `ritardoPrimo` se il foglio è appena
    /// arrivato). Calmo o istantanea: tutto subito. `giroAtteso`: la lettura partita in quel giro (nil = adesso).
    func mostra(righe nuove: [RigaLetta], immagine foto: ImmaginePiattaforma? = nil, origine da: String,
                inquadratura: String? = nil, cliente: String? = nil, giroAtteso: Int? = nil,
                ritardoPrimo: Double = Tema.Apple.Moto.Inquadra.ritardoPrimo, subito: Bool = false) {
        if let g = giroAtteso, g != giro { return }
        giro += 1
        let g = giro
        let letti = MotoreInquadra.leggi(nuove)
        righe = nuove
        dati = letti
        immagine = foto
        origine = da
        inquadraturaId = inquadratura
        if let cliente { clienteScelto = cliente }
        confronto = nil
        conferma = false
        ricevuta = nil
        guard !letti.campi.isEmpty else {
            fase = .illeggibile
            mostrate = 0
            finito = true
            return
        }
        fase = .letto
        let n = MotoreInquadra.righeScheda.count
        if subito || Movimenti.calmo {
            let tutto = {
                self.mostrate = n
                self.finito = true
            }
            if subito { tutto() } else { withAnimation(Tema.Moto.dissolvenzaCalma, tutto) }
            return
        }
        mostrate = 0
        finito = false
        let m = Tema.Apple.Moto.Inquadra.self
        for i in 0..<n {
            DispatchQueue.main.asyncAfter(deadline: .now() + ritardoPrimo + Double(i) * m.passoCampo) { [weak self] in
                guard let self, self.giro == g, self.aperto || self.telefonoAperto else { return }
                withAnimation(m.accensione) { self.mostrate = i + 1 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ritardoPrimo + Double(n) * m.passoCampo + m.codaFatto) { [weak self] in
            guard let self, self.giro == g else { return }
            // «✓ Fatto» e i pulsanti di colpo, come nel template
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { self.finito = true }
        }
    }

    /// Il riconoscimento non ha letto niente (file illeggibile, foto vuota).
    func illeggibile(origine da: String, giroAtteso: Int? = nil) {
        if let g = giroAtteso, g != giro { return }
        giro += 1
        righe = []
        dati = nil
        immagine = nil
        origine = da
        fase = .illeggibile
        finito = true
    }

    /// Solo per le istantanee: la cascata ferma a `n` righe, la lettura non ancora finita («Sto leggendo…»).
    func fermaCascata(a n: Int) {
        giro += 1
        mostrate = min(n, MotoreInquadra.righeScheda.count)
        finito = false
    }

    /// La sola apertura della scena per l'iPhone (la schermata della fotocamera ha il suo `telefonoAperto`).
    func apriTelefono() {
        giro += 1
        svuota()
        fase = .attesa
        telefonoAperto = true
    }

    func chiudiTelefono() {
        giro += 1
        telefonoAperto = false
        svuota()
    }
}

// MARK: - Nello stato della shell

extension StatoShell {
    /// La coda della lettura dei file trascinati (una alla volta: le foto pesano sulla memoria di un Mac da 8 GB).
    static let codaInquadra = DispatchQueue(label: "prisma.inquadra", qos: .userInitiated)
    /// Il lato massimo dell'immagine tenuta in memoria e letta da Vision.
    static let latoImmagineInquadra = 2_000

    /// Il ponte con iPhone e iPad è acceso e ha un codice (Impostazioni › Vera).
    var ponteInquadraAcceso: Bool {
        let p = dati.impostazioni.vera.ponte
        return p.condividi && p.abbinato
    }

    /// Apre la scena (testata di Posizioni, Novità). Mai in modalità cliente, sotto il benvenuto o in presentazione.
    /// Se c'è già un testo arrivato dall'iPhone, lo mostra subito.
    func apriInquadra() {
        guard presentazione == nil, !bloccato else { return }
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente Inquadra e capisci non si apre: parla anche degli altri clienti.")
            return
        }
        if pannelloNovita { chiudiNovita() }
        inquadra.apri(fase: ponteInquadraAcceso ? .attesa : .trascina)
        if let ultima = inquadratureInArrivo.last { prendiInquadratura(ultima) }
    }

    func chiudiInquadra() {
        guard inquadra.aperto else { return }
        inquadra.chiudi()
    }

    /// «Riprova»: di nuovo in attesa del documento.
    func riprovaInquadra() {
        inquadra.ricomincia(fase: ponteInquadraAcceso ? .attesa : .trascina)
    }

    /// Dal pannello Novità (voce 6): Posizioni › Portafoglio, poi la scena dopo 0,5 s se Posizioni era già davanti,
    /// 0,9 s se la finestra si sta aprendo.
    func apriInquadraDaNovita() {
        let davanti = appAttiva == .posizioni
        if !inModoCliente {
            posizioneInDettaglio = nil
            portafoglio = true
            provaFuoco.vista = .portafoglio
        }
        apriApp(.posizioni)
        #if os(macOS)
        let m = Tema.Apple.Moto.Inquadra.self
        Movimenti.dopo(davanti ? m.aperturaDaNovita : m.aperturaDaNovitaFinestra) { [weak self] in
            self?.apriInquadra()
        }
        #endif
    }

    /// Un testo inquadrato arrivato dall'iPhone entra nella scena.
    func prendiInquadratura(_ x: InquadraturaPonte) {
        inquadra.mostra(righe: x.righe, origine: x.dispositivo, inquadratura: x.id, cliente: x.clienteId)
    }

    /// Mentre la scena aspetta, il testo che arriva dall'iPhone entra da solo (`riceviDalPonte` lo mette in arrivo).
    func osservaInquadrature() {
        inquadratureCambiate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] elenco in
                // Con lo Smontaggio davanti le righe le legge MotoreSmontaggio («Luce» giro 2)
                if let self, let ultima = elenco.last, self.appAttiva == .posizioni, self.provaFuoco.vista == .smontaggio,
                   !self.inquadra.aperto, self.smontaggio.ultimaInquadratura != ultima.id {
                    self.smontaggio.ultimaInquadratura = ultima.id
                    self.prendiInquadraturaSmontaggio(ultima)
                    return
                }
                guard let self, let ultima = elenco.last, self.inquadra.aperto,
                      self.inquadra.fase == .attesa || self.inquadra.fase == .trascina,
                      self.inquadra.inquadraturaId != ultima.id else { return }
                self.prendiInquadratura(ultima)
            }
            .store(in: &abbonamenti)
    }

    // MARK: File trascinati

    /// Una foto o un PDF trascinati sulla zona (o scelti): letti sul Mac, con i riquadri delle righe se è una foto.
    func leggiFileInquadra(_ url: URL) {
        let estensione = url.pathExtension.lowercased()
        guard LetturaDocumenti.estensioniAccettate.contains(estensione) else {
            mostraAvviso("\(url.lastPathComponent) non si legge: Prisma legge PDF e immagini (PNG, JPEG, TIFF, HEIC).")
            return
        }
        let nome = url.lastPathComponent
        let giro = inquadra.inizioLettura(origine: nome)
        Self.codaInquadra.async { [weak self] in
            let letto = autoreleasepool { () -> (righe: [RigaLetta], immagine: ImmaginePiattaforma?)? in
                if estensione == "pdf" {
                    // Il testo della prima pagina con testo (PDFKit, o Vision per le scansioni): righe senza riquadro
                    guard let esito = LetturaDocumenti.leggi(url),
                          let pagina = esito.pagine.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { return nil }
                    let righe = pagina.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .prefix(PonteVera.massimoRighe)
                        .map { RigaLetta(testo: String($0.prefix(PonteVera.massimoTestoRiga))) }
                    return (righe: Array(righe), immagine: nil)
                }
                guard let immagine = LetturaDocumenti.anteprima(url, lato: Self.latoImmagineInquadra),
                      let righe = LetturaDocumenti.riconosciConRiquadri(immagine) else { return nil }
                return (righe: righe, immagine: immagine)
            }
            DispatchQueue.main.async {
                guard let self, self.inquadra.aperto else { return }
                guard let letto, !letto.righe.isEmpty else {
                    self.inquadra.illeggibile(origine: nome, giroAtteso: giro)
                    return
                }
                self.inquadra.mostra(righe: letto.righe, immagine: letto.immagine, origine: nome, giroAtteso: giro)
            }
        }
    }

    #if os(macOS)
    /// «Scegli un file…»: il pannello di apertura del Mac (PDF e immagini).
    func scegliFileInquadra() {
        let pannello = NSOpenPanel()
        pannello.allowedContentTypes = [.pdf, .image]
        pannello.allowsMultipleSelection = false
        pannello.canChooseDirectories = false
        pannello.prompt = "Leggi"
        pannello.message = "Scegli la foto o il PDF della polizza: Prisma la legge sul Mac e non la salva."
        guard pannello.runModal() == .OK, let url = pannello.url else { return }
        leggiFileInquadra(url)
    }
    #endif

    // MARK: Cliente, canale e polizza già presente

    /// Il cliente a cui va la polizza: quello scelto, poi quello il cui nome è il contraente, poi il cliente attivo se
    /// la scena non si è aperta dal Portafoglio di tutti i clienti. nil = da scegliere.
    var clienteInquadra: Cliente? {
        if let id = inquadra.clienteScelto, let c = cliente(id) { return c }
        if let c = MotoreInquadra.clienteProbabile(contraente: inquadra.dati?.contraente, clienti: clienti) { return c }
        return portafoglio ? nil : clienteAttivo
    }

    /// Canale e area proposti per la posizione.
    var canaleEAreaInquadra: (canale: Canale, area: AreaPosizione) {
        guard let d = inquadra.dati else { return (.indipendente, .protezione) }
        return MotoreInquadra.canaleEArea(d)
    }

    /// La posizione del cliente che è già questa polizza (numero di contratto, nome): «Aggiorna la posizione».
    var posizioneGiaInquadrata: Posizione? {
        guard let d = inquadra.dati, let c = clienteInquadra else { return nil }
        return MotoreConfrontoDossier.posizioneProbabile(MotoreInquadra.documentoProvvisorio(d, clienteId: c.id), tra: dati.posizioni)?.0
    }

    /// Il nome breve del cliente nei pulsanti («Giulia»).
    static func nomeBreveInquadra(_ c: Cliente) -> String {
        c.nome.split(separator: " ").first.map(String.init) ?? c.nome
    }

    // MARK: Aggiungi e confronta

    /// Il documento del cliente con i dati letti (senza file), aggiunto all'archivio; da un testo arrivato
    /// dall'iPhone, quello in arrivo esce dall'elenco. I campi non sono confermati.
    private func documentoInquadrato(cliente c: Cliente, dati d: DatiInquadrati) -> Documento? {
        let titolo = MotoreInquadra.titoloDocumento(d)
        let doc: Documento
        if let id = inquadra.inquadraturaId, let arrivato = documentoDaInquadratura(id, clienteId: c.id, titolo: titolo) {
            doc = arrivato
        } else {
            doc = MotoreInquadra.documento(d, clienteId: c.id, titolo: titolo, quando: Appuntamento.alMinuto(Date()))
            dati.documenti.append(doc)
        }
        memorizzaTesto(doc.id, [d.testo])
        return doc
    }

    /// «Conferma e aggiungi»: i dati letti entrano come confermati (il consulente li ha visti nella scheda), poi la
    /// posizione in essere del cliente con il canale e l'area proposti. La scena si chiude con l'avviso.
    func aggiungiInquadrata() {
        guard !solaLettura else {
            mostraAvviso("Archivio in sola lettura: aggiorna Prisma per creare schede e posizioni.")
            return
        }
        guard let d = inquadra.dati, !d.campi.isEmpty else { return }
        guard let c = clienteInquadra else {
            mostraAvviso("Scegli prima il cliente a cui va la polizza.")
            return
        }
        guard let doc = documentoInquadrato(cliente: c, dati: d) else { return }
        let (canale, area) = MotoreDocumenti.canaleEArea(doc, posizione: nil, prodotto: nil)
        creaDaDocumento(doc.id, cosa: .posizione, canale: canale, area: area, confermaPrima: true)
        inquadra.chiudi()
        let provenienza = canale == .alleanza ? "Alleanza" : "indipendente" + (d.compagnia.map { ", \($0)" } ?? ", altra compagnia")
        mostraAvviso("Aggiunta alle posizioni di \(Self.nomeBreveInquadra(c)), canale \(provenienza)")
    }

    /// «Aggiorna la posizione»: la polizza c'è già; il documento (dati da confermare) collegato alla posizione si apre
    /// in Documenti sul confronto «Nel documento / In Prisma», dove si sceglie cosa aggiornare.
    func confrontaInquadrataConPosizione() {
        guard !solaLettura else {
            mostraAvviso("Archivio in sola lettura: aggiorna Prisma per confrontare e aggiornare.")
            return
        }
        guard let d = inquadra.dati, let c = clienteInquadra, let p = posizioneGiaInquadrata,
              let doc = documentoInquadrato(cliente: c, dati: d) else { return }
        aggiornaDocumento(doc.id) { $0.posizioneId = p.id }
        inquadra.chiudi()
        clienteAttivoId = c.id
        documentoSelezionato = doc.id
        vistaDocumenti.scheda = .confronto
        vistaDocumenti.pannelloDati = true
        apri(.documenti)
    }

    /// «Confronta»: la polizza già in Prisma va al confronto di Documenti; altrimenti la tabella con una temporanea
    /// (fabbisogno della famiglia del cliente, tariffa delle temporanee del cliente o dell'archivio).
    func confrontaInquadrata() {
        guard let d = inquadra.dati else { return }
        if posizioneGiaInquadrata != nil {
            confrontaInquadrataConPosizione()
            return
        }
        inquadra.confronto = confrontoInquadra(d)
    }

    /// Il confronto con una temporanea sui dati del cliente scelto (senza cliente: solo la tariffa dell'archivio).
    func confrontoInquadra(_ d: DatiInquadrati) -> ConfrontoTemporanea {
        let c = clienteInquadra
        let mie = c.map { posizioniCliente($0.id) } ?? []
        let fabbisogno: Double? = c.map { cl in
            MotoreProtezioneFamiglia.calcola(mie, cliente: cl, analisi: analisi360(cl.id).protezione).fabbisogno
        }
        let tariffa = MotoreSimulatoriAnalisi.tariffaCasoMorte(cliente: MotoreInquadra.temporanee(mie),
                                                              archivio: MotoreInquadra.temporanee(dati.posizioni))
        return MotoreInquadra.confronta(d, fabbisogno: fabbisogno, tariffa: tariffa)
    }
}
