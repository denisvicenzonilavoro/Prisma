import Foundation

/// Che cosa ha fatto la conferma di una nota vocale.
struct EsitoNotaVocale: Equatable {
    var note = 0
    var attivita = 0
    var obiettivi = 0
    /// Le proposte di messaggio confermate: lo stato apre Messaggi con l'occasione (qui non si scrive niente).
    var messaggi: [String] = []
}

/// La conferma delle proposte di una nota vocale («Luce» giro 13, §6.2; come `ApplicaCopilota`): ogni voce crea o
/// aggiorna un elemento con un id stabile (nota + voce), così confermare due volte non crea doppioni. Il profilo MiFID
/// non si tocca mai; un obiettivo si aggiorna solo se esiste (mai creato da qui); il messaggio non scrive nell'archivio.
/// Motore puro.
enum ApplicaNotaVocale {
    static let testoNota = "Dalla nota dettata sull’iPhone il "

    /// L'id dell'elemento creato da una voce: «nota-<id della nota>-<voce>».
    static func idElemento(_ prefisso: String, _ n: NotaInArrivo, _ p: PropostaNota) -> String {
        "\(prefisso)-\(n.id)-\(RiconoscitoreCopilota.chiave(p.id))"
    }

    private static func giorno(_ d: Date) -> String { Formati.dataEstesa.string(from: d) }

    /// Conferma le proposte indicate (nil = tutte quelle ancora «proposta»). Senza un cliente non si applica niente.
    @discardableResult
    static func applica(_ ids: Set<String>?, nota n: inout NotaInArrivo, a dati: inout DatiPrisma, oggi: Date) -> EsitoNotaVocale {
        var esito = EsitoNotaVocale()
        guard let clienteId = n.clienteId, dati.clienti.contains(where: { $0.id == clienteId }) else { return esito }
        let adesso = NotaInArrivo.alSecondo(oggi)
        let detta = giorno(n.quando)
        for k in n.proposte.indices {
            let p = n.proposte[k]
            guard p.stato == .proposta, ids.map({ $0.contains(p.id) }) ?? true else { continue }
            switch p.tipo {
            case .nota:
                let id = idElemento("nota", n, p)
                let testo = n.testo + "\n\n" + testoNota + detta + "."
                if let i = dati.note.firstIndex(where: { $0.id == id }) {
                    dati.note[i].testo = testo
                    dati.note[i].aggiornataIl = adesso
                } else {
                    var nota = Nota(clienteId: clienteId, titolo: "Nota dall’iPhone: " + p.titolo, testo: testo)
                    nota.id = id
                    nota.creataIl = adesso
                    nota.aggiornataIl = adesso
                    dati.note.append(nota)
                    esito.note += 1
                }
                n.proposte[k].elementoId = id
            case .attivita:
                let id = idElemento("attivita", n, p)
                var nota = testoNota + detta + "."
                if p.scadenza == nil { nota += " Scadenza da scegliere." } else if p.scadenzaDaConfermare { nota += " Data da confermare." }
                let a = Attivita(id: id, clienteId: clienteId, titolo: p.titolo,
                                 scadenza: p.scadenza ?? Calendar(identifier: .gregorian).startOfDay(for: oggi),
                                 priorita: .normale, completata: false, note: nota, appuntamentoId: n.appuntamentoId)
                if let i = dati.attivita.firstIndex(where: { $0.id == id }) {
                    var b = a
                    b.completata = dati.attivita[i].completata
                    dati.attivita[i] = b
                } else {
                    dati.attivita.append(a)
                    esito.attivita += 1
                }
                n.proposte[k].elementoId = id
            case .obiettivo:
                // Solo un obiettivo che esiste ancora, del cliente: mai creato da qui
                guard let oid = p.obiettivoId, let anni = p.anniSpostamento,
                      let i = dati.obiettivi.firstIndex(where: { $0.id == oid && $0.clienteId == clienteId }),
                      let nuova = Calendar(identifier: .gregorian).date(byAdding: .year, value: anni, to: dati.obiettivi[i].scadenza) else {
                    continue
                }
                dati.obiettivi[i].scadenza = nuova
                let riga = "Scadenza \(anni < 0 ? "anticipata" : "spostata") di \(abs(anni) == 1 ? "un anno" : "\(abs(anni)) anni") dalla nota dettata il \(detta) · da confermare."
                dati.obiettivi[i].note = dati.obiettivi[i].note.isEmpty ? riga : dati.obiettivi[i].note + "\n" + riga
                n.proposte[k].elementoId = oid
                esito.obiettivi += 1
            case .messaggio:
                esito.messaggi.append(p.id)
            }
            n.proposte[k].stato = .confermata
        }
        chiudiSeDecisa(&n, oggi: adesso)
        return esito
    }

    /// Scarta una proposta (non entra mai).
    static func scarta(_ id: String, nota n: inout NotaInArrivo, oggi: Date = Date()) {
        guard let k = n.proposte.firstIndex(where: { $0.id == id }), n.proposte[k].stato == .proposta else { return }
        n.proposte[k].stato = .scartata
        chiudiSeDecisa(&n, oggi: NotaInArrivo.alSecondo(oggi))
    }

    /// Quando nessuna proposta resta aperta la nota è decisa: confermata se almeno una voce è entrata, altrimenti scartata.
    static func chiudiSeDecisa(_ n: inout NotaInArrivo, oggi: Date) {
        guard n.stato == .daGuardare, !n.proposte.isEmpty, n.proposteAperte.isEmpty else { return }
        n.stato = n.proposte.contains { $0.stato == .confermata } ? .confermata : .scartata
        n.decisaIl = NotaInArrivo.alSecondo(oggi)
    }

    /// L'occasione di Messaggi per una proposta di messaggio: solo la cosa detta nella nota, nessuna cifra in più.
    static func occasioneMessaggio(_ p: PropostaNota, nota n: NotaInArrivo, cliente: Cliente) -> OccasioneMessaggio {
        let cosa = p.titolo.prefix(1).lowercased() + p.titolo.dropFirst()
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .notaVocale, riferimento: "\(n.id)-\(RiconoscitoreCopilota.chiave(p.id))"),
                                  clienteId: cliente.id, canale: nil, gruppo: .oggi, titolo: p.titolo,
                                  perche: "Dalla nota dettata il \(giorno(n.quando))", oggetto: p.titolo,
                                  cifre: [CifraMessaggio(.occasione, cosa)], priorita: .media, data: n.quando)
    }
}
