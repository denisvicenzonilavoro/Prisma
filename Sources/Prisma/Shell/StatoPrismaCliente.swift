import Foundation
import SwiftUI

// Il Prisma del cliente nello stato della shell («Luce» giro 15, §2.1): quali voci si possono accendere, il contenuto
// (lo stesso per l'anteprima nel telefono, il PDF e l'HTML), la preparazione del file (PDF protetto sempre; HTML cifrato
// solo con l'interruttore sperimentale acceso, decisione 3), «Manda con Messaggi» (il testo senza la password, decisione
// 4), la traccia nel dossier quando il file esce e le voci aggiunte dalla Sala con «✦ Aggiungi al Prisma di …».
// La password non si conserva mai: passa da qui solo come argomento e se ne va con la preparazione.

/// Com'è andata la preparazione del file.
enum EsitoPrismaCliente: Equatable {
    /// Il PDF protetto (e l'HTML, se acceso) in `CartellaUscite`; la copia leggibile nei Documenti (`documentoId`).
    case pronto(pdf: URL, html: URL?, dimensione: Int64, documentoId: String?)
    case nonRiuscito(String)
}

extension StatoShell {
    // MARK: Dati del cliente per il file

    /// La preparazione della linea della vita (ricordata finché i dati del cliente non cambiano).
    func preparazioneLineaVitaPrisma(_ c: Cliente) -> PreparazioneLineaVita {
        CacheLineaVita.preparazione(cliente: c, posizioni: posizioniCliente(c.id), obiettivi: obiettiviCliente(c.id),
                                    eventi: eventiVitaCliente(c.id), analisi: dati.analisi[c.id])
    }

    /// La lettera dal futuro per il file: solo «Con il piano» (decisione 7). La stesura vista sul palco se c'è,
    /// altrimenti quella conservata con «Aggiungi al Prisma» (`DatiPrisma.lettere`, §3.1.5: resta dopo un riavvio),
    /// altrimenti la lettera di Prisma con la firma; nil senza scheda (data di nascita) o senza piano.
    func letteraPerIlFile(_ c: Cliente) -> String? {
        guard let s = schedaLettera(c), s.pianoPresente else { return nil }
        if let t = sala.stesureLettera[c.id]?[.conPiano]?.testo,
           !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return t
        }
        if let l = LetteraFuturo.ultima(dati.lettere, cliente: c.id, versione: .conPiano) { return l.testo }
        return MotoreLettera.conFirma(MotoreLettera.fissa(s, .conPiano), s)
    }

    /// Conserva la lettera della versione (§3.1.4: «Aggiungi al Prisma» e il PDF): la stesura vista sul palco se c'è,
    /// altrimenti la lettera di Prisma con la firma. Sostituisce la conservata dello stesso cliente e versione. nil
    /// senza scheda (manca la data di nascita) o in sola lettura. La data al secondo, come si scrive nell'archivio (ISO 8601).
    @discardableResult
    func conservaLettera(_ c: Cliente, versione: VersioneLettera, oggi adesso: Date = Date()) -> LetteraFuturo? {
        guard !solaLettura, let s = schedaLettera(c) else { return nil }
        let oggi = Date(timeIntervalSinceReferenceDate: adesso.timeIntervalSinceReferenceDate.rounded(.down))
        let stesura = sala.stesureLettera[c.id]?[versione]
        let lettera: LetteraFuturo
        if let st = stesura, !st.testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lettera = LetteraFuturo(clienteId: c.id, scrittaIl: oggi, versione: versione, testo: st.testo, autore: st.autore,
                                    modello: st.modello, cifre: LetteraFuturo.cifre(s, versione))
        } else {
            lettera = LetteraFuturo(clienteId: c.id, scrittaIl: oggi, versione: versione,
                                    testo: MotoreLettera.conFirma(MotoreLettera.fissa(s, versione), s), autore: .modelloFisso,
                                    cifre: LetteraFuturo.cifre(s, versione))
        }
        dati.lettere = LetteraFuturo.conserva(lettera, in: dati.lettere)
        return lettera
    }

    /// Il prisma di luce si può mettere nel file: c'è almeno una posizione in essere da scomporre.
    func luceDisponibilePrisma(_ c: Cliente) -> Bool {
        #if os(macOS)
        return !CacheLuce.esito(cliente: c, posizioni: posizioniCliente(c.id), obiettivi: obiettiviCliente(c.id),
                                eventi: eventiVitaCliente(c.id), analisi: dati.analisi[c.id]).vuota
        #else
        return false
        #endif
    }

    /// La giornata della pensione si può mettere nel file: la pensione si calcola (data di nascita e previdenza).
    func giornataDisponibilePrisma(_ c: Cliente) -> Bool {
        if case .pronto = PensioneEsperienze.calcola(cliente: c, posizioni: posizioniCliente(c.id), analisi: dati.analisi[c.id]) {
            return true
        }
        return false
    }

    /// Il piede del file: «Denis Vicenzoni · il tuo consulente» (dalla firma formale), o «Il tuo consulente».
    var consulentePrismaCliente: String {
        TestiPrismaCliente.consulente(ModelliMessaggi.firma(nil, tono: .formale, impostazioni: dati.impostazioni))
    }

    /// Le avvertenze del file: quella scritta dall'utente in Impostazioni › Sala, o il segnaposto (decisione 56).
    var avvertenzePrismaCliente: [String] {
        [ImpostazioniSala.avvertenza(dati.impostazioni.sala.avvertenzaFile).testo]
    }

    /// true se l'avvertenza del file è ancora il segnaposto (avviso nel palco).
    var avvertenzaPrismaSegnaposto: Bool {
        ImpostazioniSala.avvertenza(dati.impostazioni.sala.avvertenzaFile).segnaposto
    }

    /// I sinistri del cliente con gli aggiornamenti accesi, come li vede lui (decisione 10).
    func sinistriPerIlFile(_ c: Cliente, oggi: Date = Date()) -> [SinistroMini] {
        let consulente = consulentePrismaCliente
        return dati.sinistri.filter { $0.clienteId == c.id && $0.mostraAlCliente == true }
            .map { $0.perIlCliente(consulente: consulente, oggi: oggi) }
    }

    /// Le voci che non si possono accendere, con il motivo.
    func disponibilitaPrismaCliente(_ c: Cliente) -> [VoceFilePrisma: String] {
        CompositorePrismaCliente.disponibilita(cliente: c, posizioni: posizioniCliente(c.id), obiettivi: obiettiviCliente(c.id),
                                               preparazione: preparazioneLineaVitaPrisma(c), lettera: letteraPerIlFile(c),
                                               film: ultimoFilm(clienteId: c.id), luce: luceDisponibilePrisma(c),
                                               giornata: giornataDisponibilePrisma(c), sinistri: dati.sinistri)
    }

    /// Le voci accese all'apertura del palco: quelle di base e le aggiunte dalla Sala, solo se disponibili.
    func vociInizialiPrismaCliente(_ c: Cliente) -> Set<VoceFilePrisma> {
        let aggiunte = Set(VoceFilePrisma.da(cliente(c.id)?.prismaCliente?.aggiunteDopoUltimoFile ?? []))
        let spente = Set(disponibilitaPrismaCliente(c).keys)
        return VoceFilePrisma.accesePredefinite.union(aggiunte).subtracting(spente)
    }

    // MARK: Il contenuto

    /// Il contenuto del file. Con `immagini` anche il prisma di luce e la giornata come PNG (solo alla preparazione:
    /// l'anteprima nel telefono li mostra senza rifarli a ogni disegno); `film` = i byte del video (solo per l'HTML).
    @MainActor
    func contenutoPrismaCliente(_ c: Cliente, voci: Set<VoceFilePrisma>, validoFinoAl: Date, immagini: Bool = false,
                                film: Data? = nil, oggi: Date = Date()) -> ContenutoPrismaCliente {
        let attuale = cliente(c.id) ?? c
        let luce = immagini && voci.contains(.luce) ? immagineLucePrisma(attuale) : nil
        let giornata = immagini && voci.contains(.giornata) ? immagineGiornataPrisma(attuale) : nil
        return CompositorePrismaCliente.componi(cliente: attuale, posizioni: posizioniCliente(c.id), obiettivi: obiettiviCliente(c.id),
                                                preparazione: preparazioneLineaVitaPrisma(attuale), voci: voci,
                                                lettera: letteraPerIlFile(attuale), film: film, luce: luce, giornata: giornata,
                                                sinistri: sinistriPerIlFile(attuale, oggi: oggi), consulente: consulentePrismaCliente,
                                                avvertenze: avvertenzePrismaCliente, validoFinoAl: validoFinoAl, oggi: oggi,
                                                diProva: StatoShell.clientiDiProva.contains(c.id),
                                                conFilm: ultimoFilm(clienteId: c.id) != nil)
    }

    /// Il prisma di luce come immagine ferma (decisione 7), sempre notte.
    @MainActor
    func immagineLucePrisma(_ c: Cliente) -> Data? {
        #if os(macOS)
        let e = CacheLuce.esito(cliente: c, posizioni: posizioniCliente(c.id), obiettivi: obiettiviCliente(c.id),
                                eventi: eventiVitaCliente(c.id), analisi: dati.analisi[c.id])
        guard !e.vuota else { return nil }
        let f = e.fasce(.investimento)
        let vista = PrismaDiLuceFermo(fasce: ColoriLuce.colori(f).map { FasciaLuceFermo(colore: $0, peso: 1) },
                                      bordi: GeometriaLuce.bordi(f.map(\.quota)), rotazione: 0,
                                      frazione: e.frazione(anno: e.annoOggi), spento: e.vuota)
        return StatoShell.pngPrisma(vista, misura: CGSize(width: 720, height: 405))
        #else
        return nil
        #endif
    }

    /// Una giornata della pensione «Con il piano», ferma, con le cifre di oggi (decisione 7).
    @MainActor
    func immagineGiornataPrisma(_ c: Cliente) -> Data? {
        let vista = GiornataPensioneVista(cliente: c, conPiano: true, modificabile: false)
            .environment(self)
            .environment(\.modoIstantanea, true)
            .background(Tema.Apple.Colore.cardPiena)
        return StatoShell.pngPrisma(vista, misura: CGSize(width: 1040, height: 620))
    }

    /// Una vista in PNG (scala 2, aspetto chiaro): niente finestra, niente Metal.
    @MainActor
    static func pngPrisma<V: View>(_ v: V, misura: CGSize, scala: CGFloat = 2) -> Data? {
        let renderer = ImageRenderer(content: v.frame(width: misura.width, height: misura.height)
            .environment(\.colorScheme, .light))
        renderer.proposedSize = ProposedViewSize(misura)
        renderer.scale = scala
        guard let cg = renderer.cgImage else { return nil }
        return ProtocolloTavolo.png(cg)
    }

    // MARK: La preparazione

    /// Prepara il file: compone, impagina il PDF, ne salva la copia leggibile nei Documenti (decisione 6), lo protegge con
    /// la password e lo scrive in `CartellaUscite`; con l'interruttore sperimentale anche l'HTML cifrato. `avanzamento`
    /// segue il lavoro vero (0…1). Aggiorna `Cliente.prismaCliente` (data, scadenza, voci; mai la password).
    @MainActor
    func preparaPrismaCliente(_ c: Cliente, voci: Set<VoceFilePrisma>, password: String, validoFinoAl: Date,
                              avanzamento: @escaping @MainActor (Double) -> Void) async -> EsitoPrismaCliente {
        if let motivo = GeneratorePassword.motivoNonValida(password, cliente: c) { return .nonRiuscito(motivo) }
        let accese = voci.subtracting(Set(disponibilitaPrismaCliente(c).keys))
        guard !accese.isEmpty else { return .nonRiuscito(TestiPrismaCliente.accendiUnaVoce) }
        avanzamento(0.05)
        await Task.yield()

        let html = dati.impostazioni.sala.fileHtmlAcceso
        var film: Data?
        if html, accese.contains(.film), let d = ultimoFilm(clienteId: c.id), let url = urlDocumento(d) {
            film = try? Data(contentsOf: url)
        }
        let contenuto = contenutoPrismaCliente(c, voci: accese, validoFinoAl: validoFinoAl, immagini: true, film: film)
        avanzamento(0.3)
        await Task.yield()

        let documento = PaginePrismaCliente.documento(contenuto)
        guard let pdf = StampaCarta.pdf(documento) else { return .nonRiuscito("Non riesco a comporre il PDF") }
        avanzamento(0.5)
        await Task.yield()

        let documentoId = archiviaPDF(pdf, titolo: "Il Prisma di \(contenuto.nomeBattesimo)", tipo: .report, cliente: c.id)
        guard let protetto = StampaCarta.protetto(pdf, password: password) else {
            return .nonRiuscito("Non riesco a proteggere il PDF con la password")
        }
        avanzamento(0.65)
        let urlPDF: URL
        do {
            urlPDF = try CartellaUscite.scrivi(protetto, nome: FilePrismaCliente.nomeFile(contenuto, estensione: "pdf"))
        } catch {
            return .nonRiuscito("Non riesco a scrivere il file: \(error.localizedDescription)")
        }
        var dimensione = Int64(protetto.count)
        var urlHTML: URL?
        if html {
            avanzamento(0.75)
            let chiave = password
            let pagina: Data? = await Task.detached(priority: .userInitiated) {
                try? FilePrismaCliente.html(contenuto, password: chiave)
            }.value
            guard let pagina else {
                CartellaUscite.togli(urlPDF)
                return .nonRiuscito("Non riesco a preparare il file per il browser")
            }
            do {
                urlHTML = try CartellaUscite.scrivi(pagina, nome: FilePrismaCliente.nomeFile(contenuto, estensione: "html"))
                dimensione += Int64(pagina.count)
            } catch {
                CartellaUscite.togli(urlPDF)
                return .nonRiuscito("Non riesco a scrivere il file: \(error.localizedDescription)")
            }
        }
        avanzamento(0.95)

        if let i = dati.clienti.firstIndex(where: { $0.id == c.id }) {
            var s = dati.clienti[i].prismaCliente ?? StatoPrismaCliente()
            s.ultimoFile = contenuto.creatoIl
            s.validoFinoAl = contenuto.validoFinoAl
            s.contenuti = contenuto.voci.map(\.rawValue)
            s.aggiunteDopoUltimoFile = []
            dati.clienti[i].prismaCliente = s
        }
        avanzamento(1)
        return .pronto(pdf: urlPDF, html: urlHTML, dimensione: dimensione, documentoId: documentoId)
    }

    // MARK: Le uscite

    /// «Manda con Messaggi»: Messaggi con il file allegato e il destinatario del dossier, **senza la password nel testo**.
    @MainActor
    func mandaPrismaConMessaggi(_ c: Cliente, file: URL) -> EsitoApertura {
        AperturaMessaggi.apri(testo: TestiPrismaCliente.messaggio(c), oggetto: TestiPrismaCliente.oggetto(c), canale: .messaggi,
                              cliente: c, allegati: [file])
    }

    /// La traccia nel dossier quando il file esce (Messaggi aperto o foglio di condivisione riuscito).
    @discardableResult
    func registraUscitaPrismaCliente(_ c: Cliente, voci: [VoceFilePrisma], via: String?, html: Bool,
                                     documentoId: String?) -> UscitaCliente {
        registraUscita(clienteId: c.id, genere: .prismaCliente, descrizione: TestiPrismaCliente.descrizioneUscita(voci, html: html),
                       via: via, documentoId: documentoId, protetto: true)
    }

    // MARK: Dalla Sala

    /// «✦ Aggiungi al Prisma di …»: accende la voce dell'esperienza nel prossimo file del cliente (un secondo clic la
    /// toglie). Il disegno non ha una voce: entra nel file come obiettivo salvato (decisione 7).
    func aggiungiAlPrismaCliente(_ e: EsperienzaSala, cliente: Cliente) {
        guard let voce = VoceFilePrisma.perEsperienza(e),
              let i = dati.clienti.firstIndex(where: { $0.id == cliente.id }) else { return }
        var s = dati.clienti[i].prismaCliente ?? StatoPrismaCliente()
        if let k = s.aggiunteDopoUltimoFile.firstIndex(of: voce.rawValue) {
            s.aggiunteDopoUltimoFile.remove(at: k)
        } else {
            s.aggiunteDopoUltimoFile = VoceFilePrisma.da(s.aggiunteDopoUltimoFile + [voce.rawValue]).map(\.rawValue)
            // La lettera si conserva (§3.1.4): solo la «Con il piano» (decisione 7), così il file non la perde al riavvio
            if e == .lettera { conservaLettera(cliente, versione: .conPiano) }
        }
        dati.clienti[i].prismaCliente = s
    }

    /// La voce dell'esperienza è già nel prossimo file del cliente («✓ Nel Prisma di …»).
    func voceAggiunta(_ e: EsperienzaSala, cliente: Cliente) -> Bool {
        guard let voce = VoceFilePrisma.perEsperienza(e) else { return false }
        return self.cliente(cliente.id)?.prismaCliente?.aggiunteDopoUltimoFile.contains(voce.rawValue) == true
    }
}
