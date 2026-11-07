import Foundation

/// Giro 6 di Orizzonte: le tabelle delle famiglie (Impostazioni) e l'allenamento OCF (Studio). Scritture
/// sull'archivio; i calcoli stanno in `MotoreFamiglie` e `MotoreOCF`.
extension StatoShell {
    // MARK: Famiglie come la sua

    /// Le tabelle in uso: quelle caricate dal consulente o, senza, le tavole pubblicate dalla Banca d'Italia incluse
    /// nell'app (`Risorse/famiglie-bdi-2022.json`).
    var tabelleFamiglie: TabelleFamiglie? { dati.famiglie?.tabelle ?? TabelleFamiglie.tabellePredefinite }

    /// Carica un file delle tabelle: se è valido lo copia nell'archivio (e quindi nel backup) e prevale sulle tavole
    /// incluse; se non lo è restano le tabelle di prima. Restituisce il messaggio d'errore (nil = caricato).
    @discardableResult
    func caricaTabelleFamiglie(da url: URL) -> String? {
        let accesso = url.startAccessingSecurityScopedResource()
        defer { if accesso { url.stopAccessingSecurityScopedResource() } }
        guard let contenuto = try? Data(contentsOf: url) else { return TestiFamiglie.fileIlleggibile }
        do {
            let t = try TabelleFamiglie.leggi(contenuto)
            dati.famiglie = FamiglieCaricate(tabelle: t, nomeFile: url.lastPathComponent, caricateIl: Posizione.oggiArrotondato)
            return nil
        } catch let e as ErroreTabelleFamiglie {
            return TestiFamiglie.erroreFile(e.messaggio)
        } catch {
            return TestiFamiglie.fileIlleggibile
        }
    }

    /// Toglie le tabelle caricate: si torna alle tavole della Banca d'Italia incluse nell'app.
    func usaFamigliePredefinite() {
        guard dati.famiglie != nil else { return }
        dati.famiglie = nil
    }

    /// Il confronto del cliente con le tabelle in uso (nil senza tabelle o senza cliente).
    func confrontoFamiglie(_ clienteId: String) -> ConfrontoFamiglie? {
        guard let t = tabelleFamiglie, let c = dati.clienti.first(where: { $0.id == clienteId }) else { return nil }
        return MotoreFamiglie.confronta(cliente: c, posizioni: dati.posizioni, tabelle: t)
    }

    // MARK: Esame OCF

    /// Applica un'importazione confermata dal riepilogo.
    func applicaImportazioneOCF(_ i: ImportazioneOCF) {
        var ocf = dati.ocf
        ocf.applica(i)
        if ocf != dati.ocf { dati.ocf = ocf }
    }

    /// Aggiunge le domande di esempio di Prisma (quelle che mancano); restituisce il riepilogo.
    @discardableResult
    func aggiungiDomandeEsempioOCF() -> ImportazioneOCF? {
        guard let i = ImportaOCF.esempio(archivio: dati.ocf) else { return nil }
        applicaImportazioneOCF(i)
        return i
    }

    /// Registra una risposta; restituisce se era giusta (nil se la domanda non c'è).
    @discardableResult
    func rispondiOCF(_ domandaId: String, scelta: Int) -> Bool? {
        var ocf = dati.ocf
        guard let r = ocf.rispondi(domandaId, scelta: scelta, il: Posizione.oggiArrotondato) else { return nil }
        dati.ocf = ocf
        return r.giusta
    }

    func impostaDataEsameOCF(_ data: Date?) {
        guard dati.ocf.dataEsame != data else { return }
        dati.ocf.dataEsame = data
    }
}
