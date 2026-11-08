#if os(macOS)
import AppKit
#endif
import Foundation
import Observation
import UniformTypeIdentifiers

// Lo stato di Studio › Spese («Luce» giro 9): il mese scelto, la spesa appena inquadrata (riga evidenziata), il foglio
// aperto e il pacchetto per il commercialista. Un oggetto a parte da StatoShell (come la palestra): non si salva.
// Le azioni che scrivono l'archivio (spese, scadenze, corsi, km) sono in fondo, su StatoShell: niente si salva senza
// la conferma dell'utente (lo scontrino letto è solo una proposta finché non si preme «Aggiungi la spesa»).

@Observable final class StatoSpese {
    /// Il foglio aperto sopra la scheda.
    enum Foglio: Identifiable, Equatable {
        /// «Inquadra lo scontrino» (con un file già trascinato, se c'è).
        case inquadra(URL?)
        /// Una spesa nuova scritta a mano.
        case nuovaSpesa
        case spesa(String)
        case nuovaScadenza
        case scadenza(String)
        case corsi
        /// L'elenco completo delle visite del mese, con «Dove eri?» e i km mancanti.
        case visite
        /// L'elenco completo delle spese del mese.
        case spese
        /// La correzione a mano dei km di un giro («aaaa-mm-gg»).
        case correzione(String)

        var id: String {
            switch self {
            case .inquadra(let u): return "inquadra-\(u?.path ?? "")"
            case .nuovaSpesa: return "nuova-spesa"
            case .spesa(let id): return "spesa-\(id)"
            case .nuovaScadenza: return "nuova-scadenza"
            case .scadenza(let id): return "scadenza-\(id)"
            case .corsi: return "corsi"
            case .visite: return "visite"
            case .spese: return "spese"
            case .correzione(let g): return "correzione-\(g)"
            }
        }
    }

    /// Com'è il pacchetto per il commercialista.
    enum Pacchetto: Equatable {
        case nessuno
        /// In preparazione: la frazione del lavoro fatto (file scritti / totale).
        case inPreparazione(Double)
        case pronto(url: URL?, nome: String, descrizione: String)
        case errore(String)
    }

    /// Il mese scelto con le frecce o le colonne (nil = quello automatico: il mese prima fino al giorno di cambio).
    var meseScelto: Date?
    /// La spesa appena aggiunta da uno scontrino: in cima all'elenco, evidenziata.
    var nuovaSpesaId: String?
    var foglio: Foglio?
    var pacchetto = Pacchetto.nessuno
    /// Solo per l'istantanea 787: Impostazioni › Studio mostra in cima la sezione dei chilometri e delle spese.
    var impostazioniInCima = false

    /// Il mese mostrato.
    func mese(oggi: Date = Date(), impostazioni: ImpostazioniSpese) -> Date {
        meseScelto ?? MotoreChilometri.meseMostrato(oggi: oggi, giornoCambio: impostazioni.giornoCambioMese)
    }

    /// Cambia il mese di `passo` mesi (‹ ›); il pacchetto pronto riguarda il mese di prima e si toglie.
    func sposta(_ passo: Int, oggi: Date = Date(), impostazioni: ImpostazioniSpese) {
        let attuale = mese(oggi: oggi, impostazioni: impostazioni)
        guard let nuovo = Calendar.current.date(byAdding: .month, value: passo, to: attuale) else { return }
        scegli(nuovo)
    }

    func scegli(_ mese: Date) {
        meseScelto = MotoreChilometri.inizioMese(mese)
        nuovaSpesaId = nil
        if case .inPreparazione = pacchetto { return }
        pacchetto = .nessuno
    }
}

// MARK: - Le azioni sull'archivio

extension StatoShell {
    /// Apre Studio › Spese.
    func apriSpese() { apriStudio(.spese) }

    /// Il nome di un cliente (vuoto se non c'è più).
    func nomeClienteSpese(_ id: String) -> String { dati.clienti.first { $0.id == id }?.nome ?? "" }

    /// Aggiunge o sostituisce una spesa confermata dall'utente. Con `fileScontrino` copia prima il file nella cartella
    /// degli scontrini (se la copia non riesce la spesa non si salva e lo dice); lo scontrino di prima della stessa spesa,
    /// se c'era e non serve più, si toglie (niente file orfani nei backup).
    @discardableResult
    func salvaSpesa(_ spesa: SpesaStudio, fileScontrino: URL? = nil, evidenzia: Bool = false) -> Bool {
        guard !solaLettura else { return false }
        var s = spesa
        if let url = fileScontrino, persistente {
            do {
                s.scontrino = try Archivio.copiaFileStudio(url, in: Archivio.cartellaScontrini())
            } catch {
                mostraAvviso("Lo scontrino non è stato salvato: \(error.localizedDescription)")
                return false
            }
        }
        var a = dati.speseStudio
        let vecchio = a.spese.first(where: { $0.id == s.id })?.scontrino
        if let i = a.spese.firstIndex(where: { $0.id == s.id }) { a.spese[i] = s } else { a.spese.append(s) }
        dati.speseStudio = a
        if let vecchio, vecchio != s.scontrino, persistente {
            try? FileManager.default.removeItem(at: Archivio.cartellaScontrini().appendingPathComponent(vecchio))
        }
        if evidenzia { studioSpese.nuovaSpesaId = s.id }
        return true
    }

    /// Elimina una spesa (dopo la conferma dell'utente) e il file del suo scontrino.
    func eliminaSpesa(_ id: String) {
        guard !solaLettura, let s = dati.speseStudio.spese.first(where: { $0.id == id }) else { return }
        dati.speseStudio.spese.removeAll { $0.id == id }
        if let f = s.scontrino, persistente {
            try? FileManager.default.removeItem(at: Archivio.cartellaScontrini().appendingPathComponent(f))
        }
        if studioSpese.nuovaSpesaId == id { studioSpese.nuovaSpesaId = nil }
    }

    func salvaScadenza(_ s: ScadenzaStudio) {
        guard !solaLettura else { return }
        var a = dati.speseStudio
        if let i = a.scadenze.firstIndex(where: { $0.id == s.id }) { a.scadenze[i] = s } else { a.scadenze.append(s) }
        dati.speseStudio = a
    }

    func eliminaScadenza(_ id: String) {
        guard !solaLettura else { return }
        dati.speseStudio.scadenze.removeAll { $0.id == id }
    }

    /// Segna fatta una scadenza: sparisce dalla card, e se è ricorrente nasce la prossima.
    func segnaScadenzaFatta(_ id: String, il: Date = Date()) {
        guard !solaLettura else { return }
        let nuove = MotoreSpese.segnaFatta(id, in: dati.speseStudio.scadenze, il: il)
        if nuove != dati.speseStudio.scadenze { dati.speseStudio.scadenze = nuove }
    }

    /// Aggiunge o sostituisce un corso; con `fileAttestato` copia prima l'attestato nella sua cartella e toglie quello di
    /// prima dello stesso corso («Cambia file…»), che non serve più.
    func salvaCorso(_ corso: CorsoAggiornamento, fileAttestato: URL? = nil) {
        guard !solaLettura else { return }
        var c = corso
        if let url = fileAttestato, persistente {
            do {
                c.attestato = try Archivio.copiaFileStudio(url, in: Archivio.cartellaAttestati())
            } catch {
                mostraAvviso("L'attestato non è stato salvato: \(error.localizedDescription)")
                return
            }
        }
        var a = dati.speseStudio
        let vecchio = a.corsi.first(where: { $0.id == c.id })?.attestato
        if let i = a.corsi.firstIndex(where: { $0.id == c.id }) { a.corsi[i] = c } else { a.corsi.append(c) }
        dati.speseStudio = a
        if let vecchio, vecchio != c.attestato, persistente {
            try? FileManager.default.removeItem(at: Archivio.cartellaAttestati().appendingPathComponent(vecchio))
        }
    }

    func eliminaCorso(_ id: String) {
        guard !solaLettura, let c = dati.speseStudio.corsi.first(where: { $0.id == id }) else { return }
        dati.speseStudio.corsi.removeAll { $0.id == id }
        if let f = c.attestato, persistente {
            try? FileManager.default.removeItem(at: Archivio.cartellaAttestati().appendingPathComponent(f))
        }
    }

    /// I km di andata e ritorno di un cliente (nil li toglie). Un valore negativo o non finito non si scrive.
    func impostaKmCliente(_ clienteId: String, _ km: Double?) {
        guard !solaLettura else { return }
        let pulito = km.flatMap { $0.isFinite && $0 >= 0 && $0 < 100_000 ? $0 : nil }
        guard dati.kmClienti[clienteId] != pulito else { return }
        dati.kmClienti[clienteId] = pulito
    }

    /// La correzione a mano dei km di un giro (nil la toglie).
    func correggiKmGiro(_ chiave: String, _ km: Double?) {
        guard !solaLettura else { return }
        let pulito = km.flatMap { $0.isFinite && $0 >= 0 && $0 < 100_000 ? $0 : nil }
        guard dati.impostazioni.studio.spese.kmCorretti[chiave] != pulito else { return }
        dati.impostazioni.studio.spese.kmCorretti[chiave] = pulito
    }

    /// Dove si è svolto un appuntamento («Dove eri?»).
    func impostaPresso(_ appuntamentoId: String, _ presso: LuogoIncontro?) {
        guard !solaLettura, let i = dati.appuntamenti.firstIndex(where: { $0.id == appuntamentoId }),
              dati.appuntamenti[i].presso != presso else { return }
        dati.appuntamenti[i].presso = presso
    }

    /// Le ore di aggiornamento richieste per un anno (nil le toglie).
    func impostaOreAggiornamento(anno: Int, _ ore: Double?) {
        guard !solaLettura else { return }
        let pulito = ore.flatMap { $0.isFinite && $0 >= 0 && $0 < 10_000 ? $0 : nil }
        guard dati.impostazioni.studio.spese.oreAggiornamentoAnno[anno] != pulito else { return }
        dati.impostazioni.studio.spese.oreAggiornamentoAnno[anno] = pulito
    }

    /// Apre l'Agenda sul giorno di un giro.
    func apriAgendaGiorno(_ giorno: Date) {
        giornoAgenda = Calendar.current.startOfDay(for: giorno)
        apri(.agenda)
    }

    /// Apre Impostazioni › Studio sulla sezione dei chilometri e delle spese.
    func apriImpostazioniSpese() {
        schedaImpostazioni = .studio
        ancoraImpostazioni = TestiSpese.ancoraImpostazioni
        apri(.impostazioni)
    }

    // MARK: Il pacchetto per il commercialista

    #if os(macOS)
    /// «Prepara il pacchetto per il commercialista»: chiede dove salvarlo (`NSSavePanel`, «Ottobre-2026.zip»), prepara
    /// testi e PDF qui, scrive lo zip fuori dal thread principale con la barra che segue il lavoro. Nessun invio.
    @MainActor
    func preparaPacchettoSpese() {
        let s = studioSpese
        if case .inPreparazione = s.pacchetto { return }
        let imp = dati.impostazioni.studio.spese
        let mese = s.mese(impostazioni: imp)
        let nome = PacchettoCommercialista.nome(mese: mese)
        let pannello = NSSavePanel()
        pannello.allowedContentTypes = [.zip]
        pannello.nameFieldStringValue = nome + ".zip"
        pannello.canCreateDirectories = true
        pannello.message = TestiSpese.messaggioPacchetto
        guard pannello.runModal() == .OK, let destinazione = pannello.url else { return }
        let contenuto = contenutoPacchetto(mese: mese)
        s.pacchetto = .inPreparazione(0)
        let descrizione = PacchettoCommercialista.descrizione(scontrini: contenuto.scontrini.count, pdf: contenuto.pdf != nil)
        Task.detached(priority: .userInitiated) {
            do {
                try PacchettoCommercialista.scrivi(contenuto, in: destinazione) { fatti, totale in
                    let f = Double(fatti) / Double(max(totale, 1))
                    Task { @MainActor in
                        if case .inPreparazione = s.pacchetto { s.pacchetto = .inPreparazione(f) }
                    }
                }
                await MainActor.run { s.pacchetto = .pronto(url: destinazione, nome: destinazione.lastPathComponent, descrizione: descrizione) }
            } catch {
                await MainActor.run { s.pacchetto = .errore(error.localizedDescription) }
            }
        }
    }
    #endif

    /// Testi e PDF del pacchetto di un mese (sul thread principale: il PDF si disegna con SwiftUI).
    @MainActor
    func contenutoPacchetto(mese: Date) -> PacchettoCommercialista.Contenuto {
        let imp = dati.impostazioni.studio.spese
        let riepilogo = MotoreChilometri.riepilogo(mese: mese, appuntamenti: dati.appuntamenti, impostazioni: imp,
                                                   kmClienti: dati.kmClienti)
        let spese = MotoreSpese.delMese(dati.speseStudio.spese, mese: mese)
        let nomi: [String: String]? = imp.nomiNelPacchetto
            ? Dictionary(dati.clienti.map { ($0.id, $0.nome) }, uniquingKeysWith: { a, _ in a }) : nil
        let file = PacchettoCommercialista.scontrini(spese, cartella: Archivio.cartellaScontrini())
        let testi = TestiRiepilogoSpese(mese: mese, riepilogo: riepilogo, spese: spese, nomi: nomi,
                                        consulente: dati.impostazioni.studio.fatturazione.nome.isEmpty
                                            ? nomeUtente : dati.impostazioni.studio.fatturazione.nome,
                                        euroPerKm: imp.euroPerKm)
        return PacchettoCommercialista.Contenuto(
            nome: PacchettoCommercialista.nome(mese: mese), suffisso: PacchettoCommercialista.suffisso(mese: mese),
            csvChilometri: PacchettoCommercialista.csvChilometri(riepilogo.giri, nomi: nomi, euroPerKm: imp.euroPerKm),
            csvSpese: PacchettoCommercialista.csvSpese(spese, scontrini: file.perSpesa, nomi: nomi),
            pdf: StampaCarta.pdf(DocumentoStampabile(testi)), scontrini: file.file)
    }
}
