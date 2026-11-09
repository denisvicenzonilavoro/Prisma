import Foundation

// La capsula del tempo («Luce» giro 15, §3.4): quando una capsula è pronta. Motore puro: riceve le capsule, gli
// obiettivi, `oggi` e il calendario; non legge mai il testo (il sigillo lo apre solo lo stato, in memoria).
// - Pronta per data: `.data(d)` e oggi è il giorno `d` o dopo.
// - Pronta per obiettivo: l'obiettivo ha `raggiuntoIl` (decisione 86: lo scrive lo stato come per i traguardi; il calcolo
//   propone, «Apri e consegna» è la conferma del consulente).
// - Obiettivo eliminato: «da decidere» (il consulente sceglie di nuovo quando si apre).
// - Chiave mancante (Mac nuovo, backup in chiaro): «non apribile», mai un testo inventato.

/// Lo stato di una capsula da mostrare (non si salva: «pronta» si calcola).
enum StatoCapsula: Equatable {
    case sigillata
    case pronta(dal: Date)
    case daDecidere
    case aperta(Date)
    case consegnata(Date)
    case nonApribile

    /// Ancora da aprire (sigillata, pronta, da decidere o senza chiave).
    var chiusa: Bool {
        switch self {
        case .sigillata, .pronta, .daDecidere, .nonApribile: return true
        case .aperta, .consegnata: return false
        }
    }

    var pronta: Bool {
        if case .pronta = self { return true }
        return false
    }
}

enum MotoreCapsule {
    /// Lo stato della capsula oggi. `chiavePresente`: la chiave che l'ha sigillata è disponibile su questo Mac.
    static func stato(_ c: CapsulaTempo, obiettivi: [Obiettivo], oggi: Date, chiavePresente: Bool,
                      cal: Calendar = .current) -> StatoCapsula {
        switch c.stato {
        case .consegnata: return .consegnata(c.consegnataIl ?? c.apertaIl ?? c.sigillataIl)
        case .aperta: return .aperta(c.apertaIl ?? c.sigillataIl)
        case .sigillata: break
        }
        let calcolato: StatoCapsula
        switch c.apertura {
        case .data(let d):
            calcolato = cal.startOfDay(for: oggi) >= cal.startOfDay(for: d) ? .pronta(dal: d) : .sigillata
        case .obiettivo(let id):
            if let o = obiettivi.first(where: { $0.id == id }) {
                if let raggiunto = o.raggiuntoIl {
                    calcolato = .pronta(dal: raggiunto)
                } else {
                    calcolato = .sigillata
                }
            } else {
                calcolato = .daDecidere
            }
        }
        return chiavePresente ? calcolato : .nonApribile
    }

    /// Gli id delle capsule pronte (con la chiave presente: chi decide se si apre è lo stato).
    static func pronte(_ capsule: [CapsulaTempo], obiettivi: [Obiettivo], oggi: Date, cal: Calendar = .current) -> [String] {
        capsule.filter { stato($0, obiettivi: obiettivi, oggi: oggi, chiavePresente: true, cal: cal).pronta }.map(\.id)
    }

    /// Le capsule di un cliente, per la Sala (mai quelle di altri clienti): prima le pronte, poi le chiuse, poi le aperte e
    /// le consegnate; dentro ogni gruppo dalla più recente.
    static func delCliente(_ capsule: [CapsulaTempo], clienteId: String, obiettivi: [Obiettivo], oggi: Date,
                           cal: Calendar = .current) -> [CapsulaTempo] {
        func gruppo(_ c: CapsulaTempo) -> Int {
            switch stato(c, obiettivi: obiettivi, oggi: oggi, chiavePresente: true, cal: cal) {
            case .pronta: return 0
            case .sigillata, .daDecidere, .nonApribile: return 1
            case .aperta: return 2
            case .consegnata: return 3
            }
        }
        return capsule.filter { $0.clienteId == clienteId }.sorted { a, b in
            let ga = gruppo(a), gb = gruppo(b)
            if ga != gb { return ga < gb }
            if a.sigillataIl != b.sigillataIl { return a.sigillataIl > b.sigillataIl }
            return a.id < b.id
        }
    }

    /// La capsula legata a un obiettivo (per il traguardo «obiettivo raggiunto»): prima una ancora sigillata.
    static func perObiettivo(_ capsule: [CapsulaTempo], obiettivoId: String) -> CapsulaTempo? {
        let legate = capsule.filter { c in
            if case .obiettivo(let id) = c.apertura { return id == obiettivoId }
            return false
        }
        return legate.first { $0.stato == .sigillata } ?? legate.first
    }

    /// «si apre quando «Anticipo casa» è raggiunto», «si apre a settembre 2036», «si apre nel 2037»; con l'obiettivo
    /// sparito, la frase che chiede di scegliere.
    static func quando(_ c: CapsulaTempo, obiettivo: Obiettivo?, cal: Calendar = .current) -> String {
        switch c.apertura {
        case .data(let d):
            let parti = cal.dateComponents([.year, .month, .day], from: d)
            if parti.month == 1, parti.day == 1, let anno = parti.year { return "si apre nel \(anno)" }
            return "si apre a " + Formati.meseAnno.string(from: d)
        case .obiettivo:
            guard let obiettivo else { return TestiCapsule.obiettivoSparito }
            return "si apre quando «\(obiettivo.titolo)» è raggiunto"
        }
    }
}
