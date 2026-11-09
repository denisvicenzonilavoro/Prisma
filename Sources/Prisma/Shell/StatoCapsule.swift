import CryptoKit
import Foundation

// La capsula del tempo nello stato («Luce» giro 15, §3.4): sigillare, aprire (il testo si decifra solo in memoria e non
// si salva mai), consegnare, cambiare quando si apre, eliminare, il PDF su carta bianca e l'apertura dai traguardi.
// Le chiavi: le capsule di prova con la chiave di prova dichiarata; nell'app vera il Portachiavi del Mac
// (`PortachiaviCapsule`); nelle istantanee e nelle prove (stato non persistente) una chiave casuale solo in memoria.

/// Le chiavi delle capsule già lette in questa esecuzione (dal Portachiavi o create in memoria per le istantanee e le
/// prove): il Portachiavi non si interroga a ogni disegno. Mai su disco.
enum ChiaviCapsuleInMemoria {
    private static let chiusura = NSLock()
    nonisolated(unsafe) private static var chiavi: [String: SymmetricKey] = [:]
    /// La chiave in memoria delle istantanee e delle prove (stato non persistente), creata alla prima capsula.
    nonisolated(unsafe) private static var diSessione: SymmetricKey?

    static func chiave(_ id: String) -> SymmetricKey? {
        chiusura.lock()
        defer { chiusura.unlock() }
        return chiavi[id]
    }

    static func ricorda(_ k: SymmetricKey) {
        chiusura.lock()
        defer { chiusura.unlock() }
        chiavi[SigilloCapsule.chiaveId(k)] = k
    }

    static func sessione() -> SymmetricKey {
        chiusura.lock()
        defer { chiusura.unlock() }
        if let k = diSessione { return k }
        let k = SymmetricKey(size: .bits256)
        diSessione = k
        chiavi[SigilloCapsule.chiaveId(k)] = k
        return k
    }
}

extension StatoShell {
    /// Le capsule del cliente per la Sala (solo il cliente visibile: in modalità cliente mai quelle degli altri).
    func capsuleCliente(_ id: String) -> [CapsulaTempo] {
        guard cliente(id) != nil else { return [] }
        return MotoreCapsule.delCliente(dati.capsule, clienteId: id, obiettivi: dati.obiettivi, oggi: Date())
    }

    /// Lo stato della capsula oggi, con la chiave di questo Mac.
    func statoCapsula(_ c: CapsulaTempo) -> StatoCapsula {
        MotoreCapsule.stato(c, obiettivi: dati.obiettivi, oggi: Date(), chiavePresente: chiaveCapsula(c) != nil)
    }

    /// La chiave che ha sigillato la capsula (nil = non c'è su questo Mac).
    func chiaveCapsula(_ c: CapsulaTempo) -> SymmetricKey? {
        // Istantanea 657: la chiave che manca (Mac nuovo, backup in chiaro)
        if !persistente, sala.provaUscite.capsulaChiaveMancante, c.stato == .sigillata { return nil }
        if c.diProva == true, c.chiaveId == SigilloCapsule.chiaveIdDiProva { return SigilloCapsule.chiaveDiProva }
        if let k = ChiaviCapsuleInMemoria.chiave(c.chiaveId) { return k }
        guard persistente, let k = PortachiaviCapsule.chiave(id: c.chiaveId) else { return nil }
        ChiaviCapsuleInMemoria.ricorda(k)
        return k
    }

    /// Sigilla il testo per il cliente. false se il testo è vuoto, in sola lettura o senza una chiave (il Portachiavi
    /// non risponde): allora non si salva nulla.
    @discardableResult
    func sigillaCapsula(_ testo: String, apertura: CapsulaTempo.Apertura, cliente: Cliente) -> Bool {
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !solaLettura, !pulito.isEmpty, dati.clienti.contains(where: { $0.id == cliente.id }) else { return false }
        let chiave: SymmetricKey
        if persistente {
            guard let k = PortachiaviCapsule.creaSeManca() else { return false }
            ChiaviCapsuleInMemoria.ricorda(k)
            chiave = k
        } else {
            chiave = ChiaviCapsuleInMemoria.sessione()
        }
        let id = "capsula-\(UUID().uuidString.prefix(8).lowercased())"
        guard let sigillo = try? SigilloCapsule.sigilla(pulito, id: id, clienteId: cliente.id, chiave: chiave) else { return false }
        let adesso = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
        dati.capsule.append(CapsulaTempo(id: id, clienteId: cliente.id, apertura: apertura, titoloObiettivo: titoloObiettivo(apertura),
                                         sigillataIl: adesso, sigillo: sigillo, chiaveId: SigilloCapsule.chiaveId(chiave),
                                         schemaSigillo: SigilloCapsule.schema))
        return true
    }

    /// Decifra il testo (solo in memoria, mai salvato) e segna la capsula «aperta il …» la prima volta. nil se la capsula
    /// non c'è, non è pronta (né già aperta) o la chiave manca.
    func apriCapsula(_ id: String) -> String? {
        guard let i = dati.capsule.firstIndex(where: { $0.id == id }) else { return nil }
        let c = dati.capsule[i]
        guard cliente(c.clienteId) != nil else { return nil }
        let s = statoCapsula(c)
        guard s.pronta || !s.chiusa, let k = chiaveCapsula(c), let testo = try? SigilloCapsule.apri(c, chiave: k) else { return nil }
        if c.stato == .sigillata, !solaLettura {
            dati.capsule[i].stato = .aperta
            dati.capsule[i].apertaIl = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
        }
        return testo
    }

    /// «Stampala su carta» (o il PDF condiviso): la capsula diventa «consegnata il …».
    func segnaCapsulaConsegnata(_ id: String) {
        guard !solaLettura, let i = dati.capsule.firstIndex(where: { $0.id == id }), dati.capsule[i].stato != .consegnata else { return }
        let adesso = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down))
        if dati.capsule[i].apertaIl == nil { dati.capsule[i].apertaIl = adesso }
        dati.capsule[i].stato = .consegnata
        dati.capsule[i].consegnataIl = adesso
    }

    /// «Cambia quando si apre» (l'obiettivo può sparire o cambiare): solo per le capsule ancora sigillate. Il sigillo non
    /// cambia (lega cliente e capsula, non il momento).
    func cambiaAperturaCapsula(_ id: String, _ a: CapsulaTempo.Apertura) {
        guard !solaLettura, let i = dati.capsule.firstIndex(where: { $0.id == id }), dati.capsule[i].stato == .sigillata else { return }
        dati.capsule[i].apertura = a
        dati.capsule[i].titoloObiettivo = titoloObiettivo(a)
    }

    /// «Elimina la capsula»: il testo si distrugge senza essere letto.
    func eliminaCapsula(_ id: String) {
        guard !solaLettura, dati.capsule.contains(where: { $0.id == id }) else { return }
        dati.capsule.removeAll { $0.id == id }
    }

    /// Il PDF su carta bianca della capsula aperta (sopratitolo, testo, nome, piede «Aperta il … · Prisma»).
    @MainActor
    func pdfCapsula(_ c: CapsulaTempo, testo: String) -> Data? {
        let nome = cliente(c.clienteId)?.nome ?? ""
        return StampaCarta.pdf(PaginaCapsula.documento(testo: testo, sigillataIl: c.sigillataIl, apertaIl: c.apertaIl ?? Date(),
                                                       cliente: nome))
    }

    /// «Apri la capsula» dai traguardi: la Sala con il cliente giusto, che apre subito la consegna.
    func apriCapsulaDalTraguardo(_ capsulaId: String, cliente: String) {
        sala.capsulaDaAprire = capsulaId
        apriEsperienza(.capsula, cliente: cliente)
    }

    /// La capsula pronta di un traguardo (nil se il traguardo non ne ha una o non è pronta).
    func capsulaProntaDelTraguardo(_ t: Traguardo) -> CapsulaTempo? {
        guard let id = t.capsulaId, let c = dati.capsule.first(where: { $0.id == id }), statoCapsula(c).pronta else { return nil }
        return c
    }

    /// L'obiettivo di una capsula (nil per le capsule a data o con l'obiettivo eliminato).
    func obiettivoCapsula(_ c: CapsulaTempo) -> Obiettivo? {
        guard case .obiettivo(let id) = c.apertura else { return nil }
        return dati.obiettivi.first { $0.id == id }
    }

    private func titoloObiettivo(_ a: CapsulaTempo.Apertura) -> String? {
        guard case .obiettivo(let id) = a else { return nil }
        return dati.obiettivi.first { $0.id == id }?.titolo
    }
}
