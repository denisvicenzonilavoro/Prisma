import Foundation

/// Le capsule del tempo dei clienti di prova («Luce» giro 15, §3.4 e §8 del piano). DATI DI PROVA DICHIARATI: solo con i
/// clienti di prova, `diProva = true`, sigillate con la chiave di prova pubblica (`SigilloCapsule.chiaveDiProva`, non è un
/// segreto e non apre capsule vere); `rimuoviDatiDiProva` le toglie. I testi sono fittizi (quello di Sofia è il testo del
/// template), le date relative a oggi:
/// - Giulia: «Anticipo per la casa», sigillata un anno fa;
/// - Marco: si apre a settembre fra dieci anni, sigillata un anno e otto mesi fa;
/// - Laura: si apre il 1° gennaio fra undici anni («si apre nel …»), sigillata dieci mesi fa;
/// - Sofia: «Rendita integrativa» (l'obiettivo di prova raggiunto ieri, `TraguardiDiProva.obiettivoSofia`): pronta.
enum CapsuleDiProva {
    static let idGiulia = "capsula-prova-giulia"
    static let idMarco = "capsula-prova-marco"
    static let idLaura = "capsula-prova-laura"
    static let idSofia = "capsula-prova-sofia"

    static func applica(_ d: inout DatiPrisma, oggi: Date = Date()) {
        let cal = Calendar(identifier: .gregorian)
        let inizio = cal.startOfDay(for: oggi)
        func mezzogiorno(_ g: Date) -> Date { cal.date(bySettingHour: 12, minute: 0, second: 0, of: g) ?? g }
        func mesiFa(_ m: Int) -> Date { mezzogiorno(cal.date(byAdding: .month, value: -m, to: inizio) ?? inizio) }
        let anno = cal.component(.year, from: inizio)
        func giorno(_ a: Int, _ mese: Int, _ g: Int) -> Date {
            mezzogiorno(cal.date(from: DateComponents(year: a, month: mese, day: g)) ?? inizio)
        }
        let sofiaSigillata = mesiFa(17)
        let meseSofia = Formati.meseAnno.string(from: sofiaSigillata)
        let voci: [(id: String, cliente: String, apertura: CapsulaTempo.Apertura, titolo: String?, sigillata: Date, testo: String)] = [
            (idGiulia, "giulia", .obiettivo(id: "obiettivo-giulia-casa"), "Anticipo per la casa", mesiFa(12),
             "Giulia, dati di prova: questo è un messaggio fittizio per la casa nuova."),
            (idMarco, "marco", .data(giorno(anno + 10, 9, 15)), nil, mesiFa(20),
             "Marco, dati di prova: un messaggio fittizio per la famiglia, fra dieci anni."),
            (idLaura, "laura", .data(giorno(anno + 11, 1, 1)), nil, mesiFa(10),
             "Laura, dati di prova: un messaggio fittizio per le possibilità che verranno."),
            (idSofia, "sofia", .obiettivo(id: TraguardiDiProva.obiettivoSofia), "Rendita integrativa", sofiaSigillata,
             "Sofia, lo stai facendo per goderti i nipoti senza pensare ai soldi. Se stai leggendo, ce l’hai fatta: adesso goditeli davvero. — Sofia, \(meseSofia)"),
        ]
        for v in voci where d.clienti.contains(where: { $0.id == v.cliente }) && !d.capsule.contains(where: { $0.id == v.id }) {
            guard let sigillo = sigilloRicordato(v.testo, id: v.id, clienteId: v.cliente) else { continue }
            d.capsule.append(CapsulaTempo(id: v.id, clienteId: v.cliente, apertura: v.apertura, titoloObiettivo: v.titolo,
                                          sigillataIl: v.sigillata, sigillo: sigillo, chiaveId: SigilloCapsule.chiaveIdDiProva,
                                          schemaSigillo: SigilloCapsule.schema, diProva: true))
        }
    }

    // MARK: Sigilli ricordati

    /// Il sigillo cambia a ogni cifratura (sale e nonce casuali): i dati di prova devono restare uguali fra una lettura e
    /// l'altra (`DatiPrisma.demo() == DatiPrisma.demo()`, prove e istantanee), quindi il sigillo di uno stesso testo si
    /// ricorda per tutta la vita del processo.
    private static let chiusura = NSLock()
    nonisolated(unsafe) private static var ricordati: [String: Data] = [:]

    private static func sigilloRicordato(_ testo: String, id: String, clienteId: String) -> Data? {
        let chiave = "\(clienteId)|\(id)|\(testo)"
        chiusura.lock()
        defer { chiusura.unlock() }
        if let gia = ricordati[chiave] { return gia }
        guard let nuovo = try? SigilloCapsule.sigilla(testo, id: id, clienteId: clienteId, chiave: SigilloCapsule.chiaveDiProva) else {
            return nil
        }
        ricordati[chiave] = nuovo
        return nuovo
    }
}
