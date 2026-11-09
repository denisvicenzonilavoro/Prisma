import Foundation

// Le bozze di Vera della notte («Luce» giro 14, decisione 101): il modello si carica una volta, si scrive una bozza alla
// volta (al più `massimo`, mai oltre 10), poi si libera subito. `ferma(_:)` (avviso di memoria, stop del Mac, 20 minuti)
// interrompe dopo la bozza in corso: le bozze non scritte diventano «Da finire». Senza thread principale: si prova da sé.

/// Com'è andata: le bozze fatte (in ordine), quante restano da scrivere, perché si è fermato, se il modello si è caricato.
struct EsitoBozzeNotte<R> {
    var fatte: [R]
    var daFinire: Int
    var motivo: MotivoStopNotte?
    var caricato: Bool
}

final class EsecutoreBozzeNotte: @unchecked Sendable {
    private let serratura = NSLock()
    private var fermato: MotivoStopNotte?

    init() {}

    /// Ferma il lavoro dopo la bozza in corso (il primo motivo vince).
    func ferma(_ motivo: MotivoStopNotte) {
        serratura.lock()
        if fermato == nil { fermato = motivo }
        serratura.unlock()
    }

    var motivo: MotivoStopNotte? {
        serratura.lock()
        defer { serratura.unlock() }
        return fermato
    }

    /// Le bozze, una alla volta. `carica` false = il modello non è pronto: nessuna bozza, tutte «da finire» con motivo
    /// `.qwenNonPronto`. `scrivi` nil = quella bozza non è riuscita (conta fra le «da finire»). `libera` si chiama sempre una
    /// volta alla fine se c'era almeno un compito (anche se `carica` fallisce).
    func esegui<C, R>(_ compiti: [C], massimo: Int,
                      carica: () async -> Bool,
                      scrivi: (C) async -> R?,
                      libera: () async -> Void) async -> EsitoBozzeNotte<R> {
        let fila = Array(compiti.prefix(max(0, min(ImpostazioniNotte.tettoBozze, massimo))))
        guard !fila.isEmpty else { return EsitoBozzeNotte(fatte: [], daFinire: 0, motivo: motivo, caricato: false) }
        if let m = motivo { return EsitoBozzeNotte(fatte: [], daFinire: fila.count, motivo: m, caricato: false) }
        let caricato = await carica()
        guard caricato else {
            await libera()
            return EsitoBozzeNotte(fatte: [], daFinire: fila.count, motivo: .qwenNonPronto, caricato: false)
        }
        var fatte: [R] = []
        var tentate = 0
        for c in fila {
            if motivo != nil { break }
            tentate += 1
            if let r = await scrivi(c) { fatte.append(r) }
        }
        await libera()
        return EsitoBozzeNotte(fatte: fatte, daFinire: fila.count - fatte.count, motivo: motivo ?? (tentate < fila.count ? .tempo : nil),
                               caricato: true)
    }
}
