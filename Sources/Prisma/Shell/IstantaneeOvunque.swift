import Foundation

/// Le istantanee di Impostazioni › iPhone e iPad, «Prisma ovunque» (Design/template-novita-specifica.md §13.7), sul
/// Mac 560-566 in chiaro e in scuro, su iPhone e iPad 610-613 (iOS/IstantaneeMobile.swift). Tutte nello
/// stato finale (`\.modoIstantanea`): pallini fermi, andata al 25% e ritorno al 75% di ciascun arco, nessuna cascata.
/// - 560: copia sincronizzata 2 minuti fa, 3 modifiche in arrivo dall'iPhone di stamattina (una nota e due attività);
/// - 561: copia spenta (schema fermo e grigio, nessun pulsante); 562: «Sincronizzo…», pulsante disattivato;
/// - 563: «Serve la passphrase»; 564: «iCloud Drive non risponde», nuvola grigia;
/// - 565: «Vedi» aperto con la nota, le due attività e un conflitto con le due versioni affiancate;
/// - 566: «Nessuna: Mac, iPhone e iPad sono allineati.».
///
/// DATI DI PROVA DICHIARATI: lo spazio, il suo stato, le operazioni del giornale dell'iPhone e il conflitto esistono
/// SOLO dentro queste scene (lo stato dell'istantanea non si salva, nessun file scritto): servono a mostrare la pagina.
/// I clienti sono quelli di prova; patrimonio e aree del telefono d'esempio li calcolano i motori.
enum DatiProvaOvunque {
    static let iPhone = "dispositivo-iphoneprova"
    static let iPad = "dispositivo-ipadprova"
    static let mac = "mac-prova"
    static let percorso = "/Users/denis/Library/Mobile Documents/com~apple~CloudDocs/Prisma ovunque"

    /// Oggi alle 9:12 (le modifiche «di stamattina»).
    static var stamattina: Date {
        Calendar.current.date(bySettingHour: 9, minute: 12, second: 0, of: Date()) ?? Date()
    }

    static func json<T: Encodable>(_ x: T) -> String {
        JSONOvunque.canonico(JSONOvunque.dizionario(x, con: JSONOvunque.codificatore()))
    }

    /// Le tre modifiche dell'iPhone: una nota nuova per Giulia e due attività nuove.
    static func operazioni(dispositivo: String = iPhone) -> [OperazioneOvunque] {
        let quando = stamattina
        let nota = Nota(id: "nota-ovunque-prova", clienteId: "giulia", titolo: "Casa",
                        testo: "Vuole anticipare la casa di un anno.", creataIl: quando, aggiornataIl: quando)
        let attivita1 = Attivita(id: "task-ovunque-preventivo", clienteId: "giulia", titolo: "Chiedere il preventivo del mutuo",
                                 scadenza: quando.addingTimeInterval(3 * 86_400), priorita: .alta, completata: false)
        let attivita2 = Attivita(id: "task-ovunque-polizza", clienteId: "marco", titolo: "Mandare il confronto delle coperture",
                                 scadenza: quando.addingTimeInterval(5 * 86_400), priorita: .normale, completata: false)
        let elementi: [(EntitaOvunque, String, String)] = [(.nota, nota.id, json(nota)),
                                                           (.attivita, attivita1.id, json(attivita1)),
                                                           (.attivita, attivita2.id, json(attivita2))]
        return elementi.enumerated().map { i, e in
            OperazioneOvunque(id: "op-ovunque-prova-\(i + 1)", dispositivo: dispositivo, lamport: 120 + i, seq: 40 + i,
                              data: quando.addingTimeInterval(Double(i) * 60), base: 12, entita: e.0, entitaId: e.1,
                              tipo: .crea, campo: nil, prima: nil, dopo: e.2)
        }
    }

    /// Un conflitto: il titolo della stessa attività cambiato sul Mac e sull'iPhone.
    static func conflitto() -> ConflittoOvunque {
        let op = OperazioneOvunque(id: "op-ovunque-prova-conflitto", dispositivo: iPhone, lamport: 118, seq: 39,
                                   data: stamattina.addingTimeInterval(-25 * 60), base: 12, entita: .attivita, entitaId: "task-dati",
                                   tipo: .modificaCampo, campo: "titolo",
                                   prima: JSONOvunque.canonico("Verificare i dati delle spese mensili"),
                                   dopo: JSONOvunque.canonico("Verificare le spese con Giulia e Paolo"))
        return ConflittoOvunque(operazione: op, motivo: .stessoCampo,
                                valoreMac: JSONOvunque.canonico("Verificare i dati delle spese mensili e i risparmi"),
                                nomeDispositivo: "iPhone", arrivatoIl: stamattina)
    }

    /// Lo spazio acceso sul Mac, sincronizzato 2 minuti fa.
    static func macAcceso(_ s: StatoShell) {
        var o = ImpostazioniOvunque()
        o.acceso = true
        o.ruolo = .mac
        o.idDispositivo = mac
        o.nomeDispositivo = "Mac"
        o.percorso = percorso
        o.generazioneChiave = 1
        o.generazione = 12
        o.vistoFinoA = [iPhone: 39]
        let poco = Date().addingTimeInterval(-120)
        o.ultimaIstantanea = poco
        o.ultimoControllo = poco
        s.dati.impostazioni.ovunque = o
        s.ovunque.nomiDispositivi = [iPhone: "iPhone", iPad: "iPad"]
    }

    /// Lo spazio acceso su iPhone o iPad, con le tre modifiche nel giornale e il Mac che non risponde al ponte.
    static func dispositivoAcceso(_ s: StatoShell, iPad: Bool) {
        var o = ImpostazioniOvunque()
        o.acceso = true
        o.ruolo = .dispositivo
        o.idDispositivo = iPad ? DatiProvaOvunque.iPad : iPhone
        o.nomeDispositivo = iPad ? "iPad" : "iPhone"
        o.percorso = percorso
        o.generazioneChiave = 1
        o.generazione = 12
        o.prossimoSeq = 43
        o.ultimaIstantanea = Date().addingTimeInterval(-2 * 3600)
        o.ultimoControllo = Date().addingTimeInterval(-5 * 60)
        s.dati.impostazioni.ovunque = o
        let ops = operazioni(dispositivo: o.idDispositivo ?? iPhone)
        s.dati.giornaleOvunque = ops
        // Le modifiche sono già nell'archivio del dispositivo (il giornale le registra dopo)
        for op in ops { MotoreUnioneOvunque.applicaForzata(op, a: &s.dati) }
        s.disponibilitaLocale = .nonDisponibile(PonteVera.macNonTrovato)
    }
}

#if os(macOS)
extension Istantanee {
    nonisolated static var sceneOvunque: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
            scene.append((nome: nome + "-scuro", prepara: prepara))
        }
        coppia("560-impostazioni-ovunque") { s in preparaOvunque(s) }
        coppia("561-impostazioni-ovunque-spenta") { s in preparaImpostazioniApple(s, sezione: .ovunque) }
        coppia("562-impostazioni-ovunque-in-corso") { s in
            preparaOvunque(s)
            s.ovunque.inCorso = true
        }
        coppia("563-impostazioni-ovunque-password") { s in
            preparaOvunque(s, inArrivo: false)
            s.ovunque.problema = .passphrase
        }
        coppia("564-impostazioni-ovunque-icloud-assente") { s in
            preparaOvunque(s, inArrivo: false)
            s.ovunque.problema = .iCloud
        }
        coppia("565-impostazioni-ovunque-conflitti") { s in preparaOvunque(s, conflitto: true, aperte: true) }
        coppia("566-impostazioni-ovunque-allineati") { s in preparaOvunque(s, inArrivo: false) }
        return scene
    }

    /// Impostazioni › iPhone e iPad con lo spazio acceso sul Mac (dati di prova di `DatiProvaOvunque`).
    nonisolated static func preparaOvunque(_ s: StatoShell, inArrivo: Bool = true, conflitto: Bool = false, aperte: Bool = false) {
        DatiProvaOvunque.macAcceso(s)
        if inArrivo { s.ovunque.inArrivo = DatiProvaOvunque.operazioni() }
        if conflitto { s.dati.conflittiOvunque = [DatiProvaOvunque.conflitto()] }
        s.ovunque.modificheAperte = aperte
        preparaImpostazioniApple(s, sezione: .ovunque)
    }
}
#endif
