import Foundation
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

// «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1, «Luce» giro 13) nello stato della shell:
// apertura e chiusura della scena, le carte arrivate dall'iPhone (solo in memoria, scartate al blocco e al riposo:
// decisione 25), la lettura dei file trascinati sul Mac, la creazione del cliente con «Crea il dossier» (mai da sola),
// l'aggiornamento del solo documento di un cliente già in Prisma e «Scrivi a mano».

extension StatoShell {
    /// Le carte arrivate dall'iPhone e non ancora usate (le ultime tre, solo in memoria).
    static let massimoCarteInArrivo = 3

    /// Apre la scena (testata di Clienti, ⌘N, Novità, notifica). Mai in modalità cliente, sotto il benvenuto o in
    /// presentazione. Se c'è una carta arrivata dall'iPhone, la mostra subito.
    func apriNuovoCliente(potenziale: String? = nil) {
        guard presentazione == nil, !bloccato else { return }
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente il nuovo cliente non si crea: la scena mostra i dati di un'altra persona.")
            return
        }
        // I modelli dei moduli (privacy e adeguata verifica) si leggono qui, mai nel body: cambia `moduli.modelli`
        moduli.carica()
        apriSovrapposizione(.scena(.cartaIdentita))
        guard sovrapposizione == .scena(.cartaIdentita) else { return }
        nuovoCliente.apri(fase: ponteInquadraAcceso ? .attesa : .trascina, potenziale: potenziale)
        if let ultima = carteInArrivo.last { prendiCarta(ultima) }
    }

    /// Chiude la scena e scarta tutto ciò che si è letto (lo svuotamento lo fa `chiudiSovrapposizione`).
    func chiudiNuovoCliente() {
        chiudiScenaNuovoCliente()
    }

    /// La scena del nuovo cliente è aperta.
    var nuovoClienteAperto: Bool { sovrapposizione == .scena(.cartaIdentita) }

    /// Dal pannello Novità (voce 10): Clienti, poi la scena dopo 0,5 s se Clienti era già davanti, 0,9 s se no.
    func apriNuovoClienteDaNovita() {
        #if os(macOS)
        let davanti = appAttiva == .clienti
        apriApp(.clienti)
        let m = Tema.Apple.Moto.Inquadra.self
        Movimenti.dopo(davanti ? m.aperturaDaNovita : m.aperturaDaNovitaFinestra) { [weak self] in
            self?.apriNuovoCliente()
        }
        #else
        apriApp(.clienti)
        #endif
    }

    /// Una carta arrivata dall'iPhone entra nella scena (fronte e retro già insieme). Resta in memoria fino a «Crea il
    /// dossier» o alla chiusura della scena (che la scartano).
    func prendiCarta(_ c: CartaIdentitaPonte) {
        nuovoCliente.mostra(righe: c.righe, origine: c.dispositivo, carta: c.id)
        ricalcolaNotifiche()
    }

    /// La carta in uso nella scena se ne va (chiusura, «Crea», «Aggiorna il documento», «Scrivi a mano»).
    func scartaCartaInUso() {
        guard let id = nuovoCliente.cartaId, carteInArrivo.contains(where: { $0.id == id }) else { return }
        carteInArrivo.removeAll { $0.id == id }
        ricalcolaNotifiche()
    }

    /// Chiude la scena dopo un'azione (o, se la scena non è aperta, svuota lo stato e scarta la carta in uso).
    private func chiudiScenaNuovoCliente() {
        if nuovoClienteAperto {
            chiudiSovrapposizione()
        } else {
            scartaCartaInUso()
            svuotaNuovoCliente()
        }
    }

    /// Svuota la scena (chiusura, blocco, riposo, un'altra sovrapposizione). Se era aperta da «Diventa cliente» e il
    /// dossier non è nato, il potenziale torna in «Proposta» (§9.2.4, come il modulo annullato).
    func svuotaNuovoCliente() {
        if let p = nuovoCliente.potenzialeId { annullaClienteDaPotenziale(p) }
        nuovoCliente.chiudi()
    }

    /// Una carta arrivata sul ponte: in memoria (al massimo tre, senza doppioni), notifica interna **senza il nome**, la
    /// scena si apre da sola se Clienti è davanti (mai in modalità cliente né durante una presentazione).
    func accogliCarta(_ c: CartaIdentitaPonte) {
        carteInArrivo.removeAll { $0.id == c.id }
        carteInArrivo.append(c)
        if carteInArrivo.count > Self.massimoCarteInArrivo {
            carteInArrivo.removeFirst(carteInArrivo.count - Self.massimoCarteInArrivo)
        }
        if nuovoClienteAperto, nuovoCliente.fase == .attesa || nuovoCliente.fase == .trascina {
            prendiCarta(c)
            return
        }
        ricalcolaNotifiche()
        guard !inModoCliente, presentazione == nil else { return }
        #if os(macOS)
        if appAttiva == .clienti, sovrapposizione == nil {
            apriNuovoCliente()
            return
        }
        #endif
        mostraAvviso("Una carta d’identità dall’iPhone: crea il cliente.")
    }

    /// Al blocco di Prisma e al riposo del Mac: le carte in arrivo si scartano (decisione 25).
    func scartaCarteInArrivo() {
        guard !carteInArrivo.isEmpty else { return }
        carteInArrivo = []
        ricalcolaNotifiche()
    }

    // MARK: File trascinati

    /// Una foto o un PDF della carta trascinati sulla scena: letti sul Mac (Vision), con i riquadri se è una foto.
    /// Fronte e retro si trascinano uno dopo l'altro: i campi si sommano.
    func leggiFileNuovoCliente(_ url: URL) {
        let estensione = url.pathExtension.lowercased()
        guard LetturaDocumenti.estensioniAccettate.contains(estensione) else {
            mostraAvviso("\(url.lastPathComponent) non si legge: Prisma legge PDF e immagini (PNG, JPEG, TIFF, HEIC).")
            return
        }
        let nome = url.lastPathComponent
        let giro = nuovoCliente.inizioLettura(origine: nome, file: url)
        Self.codaInquadra.async { [weak self] in
            let righe = autoreleasepool { () -> [RigaLetta]? in
                if estensione == "pdf" {
                    guard let esito = LetturaDocumenti.leggi(url),
                          let pagina = esito.pagine.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { return nil }
                    return pagina.components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .prefix(PonteVera.massimoRighe)
                        .map { RigaLetta(testo: String($0.prefix(PonteVera.massimoTestoRiga))) }
                }
                // L'immagine resta in memoria solo il tempo della lettura: la carta non si disegna mai
                guard let immagine = LetturaDocumenti.anteprima(url, lato: Self.latoImmagineInquadra) else { return nil }
                return LetturaDocumenti.riconosciConRiquadri(immagine)
            }
            DispatchQueue.main.async {
                guard let self, self.nuovoClienteAperto else { return }
                guard let righe, !righe.isEmpty else {
                    self.nuovoCliente.illeggibile(origine: nome, giroAtteso: giro)
                    return
                }
                self.nuovoCliente.mostra(righe: righe, origine: nome, file: url, giroAtteso: giro)
            }
        }
    }

    #if os(macOS)
    /// «Scegli un file…»: il pannello di apertura del Mac (PDF e immagini).
    func scegliFileNuovoCliente() {
        let pannello = NSOpenPanel()
        pannello.allowedContentTypes = [.pdf, .image]
        pannello.allowsMultipleSelection = false
        pannello.canChooseDirectories = false
        pannello.prompt = "Leggi"
        pannello.message = "Scegli la foto o il PDF della carta d’identità: Prisma la legge sul Mac e non la salva."
        guard pannello.runModal() == .OK, let url = pannello.url else { return }
        leggiFileNuovoCliente(url)
    }
    #endif

    // MARK: La scheda

    /// Le cinque righe della scheda, con le correzioni.
    func righeNuovoCliente(oggi: Date = Date()) -> [RigaNuovoCliente] {
        MotoreCartaIdentita.righe(nuovoCliente.lettura, correzioni: nuovoCliente.correzioni, oggi: oggi)
    }

    /// Il potenziale della scena (§9.1, «È un potenziale cliente»): quello da cui la scena è stata aperta, se c'è ancora;
    /// altrimenti, a lettura avviata, quello con lo stesso nome della carta. Mai se la carta è di un cliente già in Prisma.
    /// Aperta da un potenziale, la carta di un'altra persona (nomi che non si contengono) non prende quel potenziale.
    var potenzialeDaCarta: PotenzialeCliente? {
        let l = nuovoCliente.letturaCorretta
        if let id = nuovoCliente.potenzialeId, let p = dati.potenziali.first(where: { $0.id == id }),
           l.nomeCompleto.map({ MotorePassaparola.nomiCompatibili($0, p.nome) }) ?? true {
            return p
        }
        guard !l.vuota, clienteGiaPresenteDaCarta == nil else { return nil }
        return MotorePassaparola.potenzialeCorrispondente(nome: l.nomeCompleto, potenziali: dati.potenziali, clienti: dati.clienti)
    }

    /// «Elena Marchi è tra i potenziali, presentata da Sofia»: il nome letto (o quello del potenziale) e il genere dalla
    /// carta (sesso letto o codice fiscale), mai indovinato.
    func frasePotenzialeDaCarta(_ p: PotenzialeCliente) -> String {
        let l = nuovoCliente.letturaCorretta
        let sesso = l.sessoLetto ?? l.codiceFiscale.flatMap { CodiceFiscale.sesso($0) }
        let femminile: Bool? = sesso.map { $0 == .femmina }
        return TestiPassaparola.traIPotenziali(p, nome: l.nomeCompleto, clienti: dati.clienti, femminile: femminile)
    }

    /// Il cliente già in Prisma con lo stesso codice fiscale (o stesso nome e data di nascita).
    var clienteGiaPresenteDaCarta: Cliente? {
        let l = nuovoCliente.letturaCorretta
        guard !l.vuota else { return nil }
        return MotoreCartaIdentita.clienteGiaPresente(l, clienti: dati.clienti)
    }

    /// I modelli dei moduli di privacy e adeguata verifica che Prisma sa compilare (caricati in Pratiche › Moduli).
    var modelliPrivacyEVerifica: [ModelloModulo] {
        moduli.tutti.filter { ($0.tipo == .privacy || $0.tipo == .adeguataVerifica) && $0.compilabile }
    }

    /// Il nome per i pulsanti: «Elena» (il nome di battesimo letto) o «questo cliente».
    var nomeBreveDaCarta: String? {
        nuovoCliente.letturaCorretta[.nome].map { MotoreCartaIdentita.maiuscoleIniziali($0.valore) }
            .flatMap { $0.split(separator: " ").first.map(String.init) }
    }

    /// La bozza del cliente con i soli dati della carta (non salvata): nome, codice fiscale, nascita, luogo,
    /// cittadinanza e documento. Mai canali, consensi, email, telefono o professione: la completezza li chiede.
    func clienteDaCarta() -> Cliente {
        let l = nuovoCliente.letturaCorretta
        var c = Cliente.nuovo(tinta: prossimaTinta)
        c.nome = l.nomeCompleto ?? ""
        c.iniziali = Cliente.iniziali(di: c.nome)
        c.dataNascita = l.dataNascita
        c.codiceFiscale = l.codiceFiscale ?? ""
        c.luogoNascita = l.luogoNascita
        c.cittadinanza = l.cittadinanza
        let documento = l.documento
        if documento.tipo != nil || documento.numero != nil || documento.scadenza != nil || documento.rilasciatoIl != nil {
            var k = c.conformita ?? ConformitaCliente()
            k.documento = documento
            c.conformita = k
        }
        return c
    }

    /// «Crea il dossier di Elena»: il cliente nasce con i dati letti, il dossier si apre su «Panoramica», il toast dice
    /// cosa è stato creato. Con l'interruttore acceso (e un file trascinato) la copia del documento va nei suoi Documenti.
    @discardableResult
    func creaClienteDaCarta() -> Cliente? {
        guard !solaLettura else {
            mostraAvviso("Archivio in sola lettura: aggiorna Prisma per creare il cliente.")
            return nil
        }
        let potenziale = clienteGiaPresenteDaCarta == nil ? potenzialeDaCarta : nil
        var c = clienteDaCarta()
        if let p = potenziale { c = MotorePassaparola.cliente(c, dalPotenziale: p) }
        guard !c.nome.trimmingCharacters(in: .whitespaces).isEmpty else {
            mostraAvviso("Manca il nome: scrivilo nella scheda o usa «Scrivi a mano».")
            return nil
        }
        let copia = nuovoCliente.salvaCopia ? nuovoCliente.fileOrigine : nil
        let conModuli = !modelliPrivacyEVerifica.isEmpty
        salvaCliente(c)
        // «È un potenziale cliente»: la scheda passa in «Cliente», collegata al dossier, ed entra nell'albero
        if let p = potenziale, let i = dati.potenziali.firstIndex(where: { $0.id == p.id }) {
            dati.potenziali[i] = MotorePassaparola.diventato(dati.potenziali[i], cliente: c.id, il: MessaggioCliente.adesso)
        }
        nuovoCliente.lasciaPotenziale()
        clienteAttivoId = c.id
        schedaCliente = .panoramica
        vistaClienti = .rubrica
        if let url = copia {
            let prima = Set(dati.documenti.map(\.id))
            importaDocumenti([url])
            if let nuovo = dati.documenti.first(where: { !prima.contains($0.id) && $0.clienteId == c.id }) {
                rinominaDocumento(nuovo.id, titolo: "Documento d’identità", tipo: .altro)
            }
        }
        // Pratiche › Moduli ha già il cliente scelto: i moduli si compilano da lì (nessun PDF scritto da solo)
        if conModuli { moduli.clienteId = c.id }
        chiudiScenaNuovoCliente()
        #if os(macOS)
        apri(.clienti)
        #else
        apriApp(.clienti)
        #endif
        mostraAvviso(conModuli ? "Dossier di \(c.nome) creato, con i moduli da firmare"
                               : "Dossier di \(c.nome) creato. I moduli si preparano quando carichi i modelli in Pratiche")
        return c
    }

    /// «Aggiorna il documento» per un cliente già in Prisma: cambia solo `conformita.documento`.
    func aggiornaDocumentoDaCarta(_ clienteId: String) {
        guard !solaLettura, let i = dati.clienti.firstIndex(where: { $0.id == clienteId }) else { return }
        let documento = nuovoCliente.letturaCorretta.documento
        var c = dati.clienti[i]
        var k = c.conformita ?? ConformitaCliente()
        k.documento = documento
        c.conformita = k
        dati.clienti[i] = c
        mostraAvviso("Documento di \(c.nome) aggiornato.")
        chiudiScenaNuovoCliente()
    }

    /// «Apri il suo dossier» per un cliente già in Prisma.
    func apriDossierDaCarta(_ clienteId: String) {
        chiudiScenaNuovoCliente()
        clienteAttivoId = clienteId
        schedaCliente = .panoramica
        #if os(macOS)
        apri(.clienti)
        #else
        apriApp(.clienti)
        #endif
    }

    /// «Scrivi a mano» (o «Completa e crea il dossier»): il modulo del cliente con i dati letti fin lì.
    /// Se la scena è di un potenziale, il modulo porta chi l'ha presentato e, salvato, collega la scheda (AppClienti).
    func scriviAManoDaCarta() {
        var c = clienteDaCarta()
        if clienteGiaPresenteDaCarta == nil, let p = potenzialeDaCarta {
            c = MotorePassaparola.cliente(c, dalPotenziale: p)
            potenzialeDellaBozza = p.id
            nuovoCliente.lasciaPotenziale()
        }
        bozzaNuovoCliente = c
        vistaClienti = .rubrica
        chiudiScenaNuovoCliente()
        #if os(macOS)
        apri(.clienti)
        #else
        apriApp(.clienti)
        #endif
    }
}
