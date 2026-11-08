import Foundation
import PDFKit

// La compilazione dei moduli (Pratiche › Moduli, «Luce» giro 10, §7.2.5 punto 3). L'anteprima prende i dati solo dalle
// fonti strutturate del dossier (mai indovinati: nome e indirizzo dell'anagrafica sono stringhe uniche e non si spezzano,
// cognome, nome e sede vengono dalla scheda fiscale), dice cosa manca e dove firmare. Le risposte del cliente non si
// riempiono mai (decisione 62); l'IBAN solo se l'utente lo conserva (decisione 40); i moduli Alleanza non si compilano
// (decisione 60). La scrittura produce il PDF compilato: nei campi AcroForm il valore del campo, sui PDF piatti un testo
// libero dentro la casella. Formati italiani: date gg/mm/aaaa, euro con la virgola.

/// Le fonti della compilazione.
struct FonteCompilazione {
    var cliente: Cliente
    /// La proposta (o la posizione) a cui si riferisce il modulo, se c'è.
    var posizione: Posizione?
    var prodotto: Prodotto?
    /// Nome e cognome del consulente dai dati di fatturazione (vuoto = non inseriti).
    var consulente: String
    /// Il comune della sede del consulente (per «Luogo e data»; vuoto = non inserito).
    var comuneConsulente: String
    var oggi: Date
    /// «Conserva l'IBAN nel dossier» acceso.
    var conservaIban: Bool
}

/// Il valore di una casella nell'anteprima.
struct ValoreCampo: Hashable {
    let testo: String
    /// Scritto a mano in questa compilazione (non cambia il dossier).
    var aMano = false
}

/// L'anteprima della compilazione: i valori per casella, ciò che manca, le firme, le risposte del cliente.
struct AnteprimaCompilazione: Equatable {
    var valori: [String: ValoreCampo]
    /// Le caselle con un dato che il dossier non ha (rosse con «?»), nell'ordine del modulo.
    var mancanti: [ModelloModulo.Campo]
    var firme: [ModelloModulo.Campo]
    var risposte: [ModelloModulo.Campo]
    /// Le caselle che Prisma sa riempire (con un dato), nell'ordine del modulo: il «di 15».
    var totale: Int

    var compilati: Int { valori.count }
    /// I dati che mancano, una volta sola ciascuno.
    var datiMancanti: [DatoModulo] {
        var visti = Set<DatoModulo>()
        return mancanti.compactMap(\.dato).filter { visti.insert($0).inserted }
    }
}

enum CompilatoreModuli {
    /// Il valore di un dato dalle fonti; nil = manca nel dossier.
    static func valore(_ dato: DatoModulo, _ f: FonteCompilazione) -> String? {
        let c = f.cliente
        let sede = c.fiscale?.sede
        let p = f.posizione
        func pieno(_ s: String?) -> String? {
            guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
            return t
        }
        func data(_ d: Date?) -> String? { d.map { Formati.dataBreve.string(from: $0) } }
        switch dato {
        case .cognome: return pieno(c.fiscale?.cognome)
        case .nome: return pieno(c.fiscale?.nome)
        case .codiceFiscale: return pieno(c.codiceFiscale)?.uppercased()
        case .dataNascita: return data(c.dataNascita)
        case .luogoNascita: return pieno(c.luogoNascita)
        case .indirizzo:
            guard let via = pieno(sede?.indirizzo) else { return nil }
            return pieno(sede?.numeroCivico).map { "\(via) \($0)" } ?? via
        case .cap: return pieno(sede?.cap)
        case .comune: return pieno(sede?.comune)
        case .provincia: return pieno(sede?.provincia)?.uppercased()
        case .telefono: return pieno(c.telefono)
        case .email: return pieno(c.email)
        case .professione: return pieno(c.professione)
        case .statoCivile: return c.statoCivile?.nome
        case .documentoTipo: return c.conformita?.documento?.tipo?.nome
        case .documentoNumero: return pieno(c.conformita?.documento?.numero)
        case .documentoRilascio: return data(c.conformita?.documento?.rilasciatoIl)
        case .documentoScadenza: return data(c.conformita?.documento?.scadenza)
        case .beneficiari: return pieno(p?.beneficiari)
        case .premio:
            guard let p, p.premio > 0 else { return nil }
            return Formati.euroDecimali(p.premio) + (perFrequenza(p.frequenza).map { " \($0)" } ?? "")
        case .frequenza:
            guard let p, p.premio > 0 else { return nil }
            return p.frequenza.nome
        case .decorrenza: return data(p?.decorrenza)
        case .scadenza: return data(p?.scadenza)
        case .capitale: return p?.capitaleAssicurato.flatMap { $0 > 0 ? Formati.euroDecimali($0) : nil }
        case .prodotto: return pieno(f.prodotto?.nome) ?? pieno(p?.nome)
        case .numeroContratto: return pieno(p?.numeroContratto)
        case .iban:
            // Solo se l'utente conserva l'IBAN e solo un IBAN valido (decisione 40)
            guard f.conservaIban, let i = c.iban, IBAN.valido(i) else { return nil }
            return IBAN.aGruppi(i)
        case .luogoData:
            guard let comune = pieno(f.comuneConsulente) else { return nil }
            return "\(comune), \(Formati.dataBreve.string(from: f.oggi))"
        case .consulente: return pieno(f.consulente)
        }
    }

    /// «al mese», «al trimestre»… (nil per il premio unico).
    static func perFrequenza(_ f: Frequenza) -> String? {
        switch f {
        case .unica: return nil
        case .mensile: return "al mese"
        case .trimestrale: return "al trimestre"
        case .semestrale: return "al semestre"
        case .annuale: return "all'anno"
        }
    }

    /// L'anteprima: i valori delle caselle che Prisma sa riempire, ciò che manca, firme e risposte del cliente.
    /// `correzioni`: i valori scritti a mano in questa compilazione (vincono sul dossier, mai sulle risposte del cliente).
    static func anteprima(_ m: ModelloModulo, fonte: FonteCompilazione, correzioni: [String: String] = [:]) -> AnteprimaCompilazione {
        var valori: [String: ValoreCampo] = [:]
        var mancanti: [ModelloModulo.Campo] = []
        let daRiempire = m.campiConDato.filter { !(m.tipo.risposteDelCliente && !($0.dato?.anagrafico ?? false)) }
        for c in daRiempire {
            if let a = correzioni[c.id]?.trimmingCharacters(in: .whitespacesAndNewlines), !a.isEmpty {
                valori[c.id] = ValoreCampo(testo: a, aMano: true)
            } else if let d = c.dato, let v = valore(d, fonte) {
                valori[c.id] = ValoreCampo(testo: v)
            } else {
                mancanti.append(c)
            }
        }
        return AnteprimaCompilazione(valori: valori, mancanti: mancanti, firme: m.firme, risposte: m.risposte, totale: daRiempire.count)
    }

    // MARK: - Il PDF compilato

    /// Il PDF compilato dai valori dell'anteprima, pagina per pagina. nil se il PDF non si apre.
    static func scrivi(_ m: ModelloModulo, pdf: Data, anteprima a: AnteprimaCompilazione) -> Data? {
        guard let documento = PDFDocument(data: pdf), !documento.isLocked else { return nil }
        var perPagina: [Int: [ModelloModulo.Campo]] = [:]
        for c in m.campi where a.valori[c.id] != nil { perPagina[c.pagina, default: []].append(c) }
        for (i, campi) in perPagina {
            autoreleasepool {
                guard let pagina = documento.page(at: i) else { return }
                let widget = pagina.annotations.filter { $0.type == "Widget" }
                for c in campi {
                    guard let v = a.valori[c.id]?.testo else { continue }
                    if let nome = c.nomeAcroForm, let w = widget.first(where: { $0.fieldName == nome }) {
                        if w.isCasella {
                            w.buttonWidgetState = .onState
                        } else {
                            w.widgetStringValue = v
                        }
                    } else {
                        pagina.addAnnotation(testoLibero(v, in: c.riquadro))
                    }
                }
            }
        }
        return documento.dataRepresentation()
    }

    /// Il testo dentro la casella di un PDF piatto: un'annotazione di testo libero senza bordo.
    static func testoLibero(_ testo: String, in r: CGRect) -> PDFAnnotation {
        let a = PDFAnnotation(bounds: r.insetBy(dx: 3, dy: max(0, (r.height - 14) / 2)), forType: .freeText, withProperties: nil)
        a.contents = testo
        if let f = PDFFontPlatform(name: "Helvetica", size: min(10, max(7, r.height * 0.45))) { a.font = f }
        a.color = .clear
        let bordo = PDFBorder()
        bordo.lineWidth = 0
        a.border = bordo
        return a
    }

    /// I valori dei campi AcroForm di un PDF compilato (per la rilettura nelle prove).
    static func valoriAcroForm(_ dati: Data) -> [String: String] {
        guard let d = PDFDocument(data: dati) else { return [:] }
        var r: [String: String] = [:]
        for i in 0..<d.pageCount {
            for a in d.page(at: i)?.annotations ?? [] where a.type == "Widget" {
                if let n = a.fieldName, let v = a.widgetStringValue, !v.isEmpty { r[n] = v }
            }
        }
        return r
    }
}

extension CompilatoreModuli {
    /// La richiesta dei dati che mancano (Messaggi, «Sì, chiediglielo»): solo i nomi dei dati, mai i valori né un dato già
    /// in archivio (D2.6). Una bozza: niente parte da solo.
    static func occasioneDatiMancanti(cliente: Cliente, modello: ModelloModulo, dati: [DatoModulo], oggi: Date) -> OccasioneMessaggio? {
        guard !dati.isEmpty else { return nil }
        let nomi = dati.map(\.nomeInFrase)
        let elenco = nomi.count > 1 ? nomi.dropLast().joined(separator: ", ") + " e " + (nomi.last ?? "") : nomi.joined()
        let quale = (dati.count == 1 ? "Manca " : "Mancano ") + elenco
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .datiMancanti, riferimento: "\(modello.id)-\(dati.map(\.rawValue).joined(separator: "-"))"),
                                  clienteId: cliente.id, canale: modello.canale, gruppo: .oggi,
                                  titolo: "Dati per «\(modello.titolo)»", perche: quale,
                                  oggetto: "I dati per «\(modello.titolo)»",
                                  cifre: [CifraMessaggio(.datiModulo, elenco), CifraMessaggio(.modulo, modello.titolo)],
                                  priorita: .media, data: oggi)
    }
}
