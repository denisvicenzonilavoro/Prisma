import Foundation

// Clienti › Dossier › La linea della vita (Orizzonte, giro 4; specifica §7 di Design/template-novita-specifica.md).
// Il patrimonio finanziario del cliente anno per anno, da oggi a 90 anni, in euro di oggi:
//   x(a) = x(a−1) × (1 + r) + (a < pensione ? risparmio : −prelievo) + eventi dell'anno a
// Le cifre di partenza vengono dai motori che ci sono già: patrimonio e versamenti dalle posizioni in essere
// (`MotorePatrimonio`), pensione pubblica netta per età di uscita (`MotorePensionePubblica`), reddito desiderato e
// rendimento reale dall'Analisi 360 salvata (`IpotesiPrevidenza`), imposta sul guadagno (`IpotesiCalcolo`).
// `prepara` si chiama una volta (apertura della scheda, dati cambiati); `calcola` è puro e leggero (≤ 60 passi
// annui) e si chiama a ogni passo del trascinamento.
// Nota: `MotorePianificazione` è il motore dell'agenda e non c'entra con questo.

/// Un'entrata o un'uscita sulla linea della vita, già portata all'età del cliente (euro di oggi).
struct MovimentoLineaVita: Identifiable, Equatable, Sendable {
    let id: String
    var eta: Int
    /// > 0 entrata, < 0 uscita.
    var importo: Double
    /// Anni toccati (1 = una volta).
    var perAnni: Int = 1
    /// true se viene da un obiettivo del dossier (e non da un evento).
    var daObiettivo = false
}

/// Tutto ciò che serve a `MotoreLineaVita.calcola`: valori semplici, che la vista cambia durante il trascinamento.
struct IngressoLineaVita: Equatable, Sendable {
    var etaOggi: Int
    var etaPensione: Int
    var etaFine = MotoreLineaVita.etaFinePredefinita
    /// Patrimonio finanziario netto di oggi (posizioni in essere).
    var patrimonioIniziale: Double
    /// Messo da parte ogni anno fino alla pensione: versamenti delle posizioni più il risparmio libero.
    var risparmioAnnuo: Double
    /// Rendimento reale annuo (%), al netto di costi e imposte, in euro di oggi.
    var rendimentoReale: Double
    /// Reddito netto mensile desiderato in pensione (euro di oggi); nil = non indicato, niente prelievo inventato.
    var redditoDesiderato: Double?
    /// Pensione pubblica netta mensile (euro di oggi) per età di uscita; vuota = stima non possibile.
    var pensionePerEta: [Int: Double] = [:]
    /// Rendita integrativa netta mensile contata a parte (0: i fondi pensione stanno già nel patrimonio).
    var renditaIntegrativa: Double = 0
    var mensilita = RegolePensione.mensilita
    var movimenti: [MovimentoLineaVita] = []

    /// La pensione pubblica netta mensile per un'età di uscita (l'età più vicina della tabella; nil senza stima).
    func pensione(_ eta: Int) -> Double? {
        if let p = pensionePerEta[eta] { return p }
        guard let minimo = pensionePerEta.keys.min(), let massimo = pensionePerEta.keys.max() else { return nil }
        return pensionePerEta[min(max(eta, minimo), massimo)]
    }

    /// Il prelievo annuo dal patrimonio in pensione: `max(0, reddito desiderato − pensione − rendita) × mensilità`.
    /// nil se manca il reddito desiderato o la pensione pubblica.
    var prelievoAnnuo: Double? {
        guard let r = redditoDesiderato, let p = pensione(etaPensione) else { return nil }
        return max(0, r - p - renditaIntegrativa) * mensilita
    }
}

struct PuntoLineaVita: Equatable, Sendable {
    let eta: Int
    /// Patrimonio a fine anno (può scendere sotto zero: nel grafico si mostra a 0).
    let valore: Double
}

struct EsitoLineaVita: Equatable, Sendable {
    /// Da oggi a `etaFine`, un punto per anno.
    let punti: [PuntoLineaVita]
    let etaPensione: Int
    let etaFine: Int
    let allaPensione: Double
    let massimo: Double
    let etaMassimo: Int
    /// Primo anno con il patrimonio sotto zero (esattamente 0 non è esaurimento); nil = basta oltre `etaFine`.
    let etaEsaurimento: Int?
    let prelievoAnnuo: Double?

    /// Il patrimonio basta fino a `etaFine` e oltre.
    var basta: Bool { etaEsaurimento == nil }
    /// Senza prelievo calcolato la parte dopo la pensione è solo indicativa (linea tratteggiata).
    var dopoPensioneIndicativa: Bool { prelievoAnnuo == nil }
    func valore(_ eta: Int) -> Double? { punti.first { $0.eta == eta }?.valore }
}

/// Ciò che `prepara` ricava dai dati del cliente: l'ingresso (nil se manca un dato essenziale) e le righe per la vista.
struct PreparazioneLineaVita: Equatable, Sendable {
    let ingresso: IngressoLineaVita?
    /// Perché la linea non si può disegnare (nil se si può).
    let motivoAssente: String?
    let avvisi: [String]
    /// Le righe del metodo (da dove viene ogni cifra).
    let ipotesi: [String]
    /// L'età di pensione è un'ipotesi (67) e non un dato del cliente.
    let etaPensioneIpotizzata: Bool
    /// Eventi senza importo: si vedono sulla linea ma non entrano nel calcolo.
    let eventiSenzaCifra: Int
}

enum MotoreLineaVita {
    static let etaFinePredefinita = 90
    /// Limiti del gettone della pensione.
    static let etaPensioneMinima = 55
    static let etaPensioneMassima = 72
    /// Un evento si sposta fra l'anno prossimo e gli 88 anni.
    static let etaEventoMassima = 88

    // MARK: - Il calcolo (a ogni passo del trascinamento)

    static func calcola(_ i: IngressoLineaVita) -> EsitoLineaVita {
        let inizio = i.etaOggi
        let fine = max(i.etaFine, inizio)
        let n = fine - inizio
        // Gli eventi anno per anno: solo dagli anni futuri (oggi è già nel patrimonio di partenza)
        var eventi = [Double](repeating: 0, count: n + 1)
        for m in i.movimenti where m.importo.isFinite {
            let da = max(m.eta, inizio + 1)
            let a = min(m.eta + max(1, m.perAnni) - 1, fine)
            guard da <= a else { continue }
            for eta in da...a { eventi[eta - inizio] += m.importo }
        }
        let r = i.rendimentoReale / 100
        let prelievo = i.prelievoAnnuo ?? 0
        var x = i.patrimonioIniziale
        var punti: [PuntoLineaVita] = []
        punti.reserveCapacity(n + 1)
        punti.append(PuntoLineaVita(eta: inizio, valore: x))
        var esaurimento: Int? = x < 0 ? inizio : nil
        var massimo = x, etaMassimo = inizio
        if n > 0 {
            for k in 1...n {
                let eta = inizio + k
                x = x * (1 + r) + (eta < i.etaPensione ? i.risparmioAnnuo : -prelievo) + eventi[k]
                punti.append(PuntoLineaVita(eta: eta, valore: x))
                if esaurimento == nil, x < 0 { esaurimento = eta }
                if x > massimo { massimo = x; etaMassimo = eta }
            }
        }
        let etaPensione = min(max(i.etaPensione, inizio), fine)
        return EsitoLineaVita(punti: punti, etaPensione: i.etaPensione, etaFine: fine,
                              allaPensione: punti[etaPensione - inizio].valore, massimo: massimo, etaMassimo: etaMassimo,
                              etaEsaurimento: esaurimento, prelievoAnnuo: i.prelievoAnnuo)
    }

    // MARK: - Dai dati del cliente (una volta)

    /// Prepara l'ingresso dai dati del cliente. `analisi` è l'Analisi 360 **salvata** (nil se il cliente non l'ha:
    /// i valori predefiniti di `IpotesiPrevidenza` non si usano come dati del cliente). Con `conObiettivi` gli
    /// obiettivi con scadenza futura sono uscite all'età della scadenza (importo meno l'accantonato), salvo un evento
    /// della stessa area alla stessa età (non si conta due volte).
    static func prepara(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita],
                        analisi: Analisi360?, conObiettivi: Bool = true, oggi: Date = Date()) -> PreparazioneLineaVita {
        let primoNome = cliente.nome.split(separator: " ").first.map(String.init) ?? cliente.nome
        guard let etaOggi = MotorePensionePubblica.etaAl(cliente.dataNascita, oggi) else {
            return PreparazioneLineaVita(ingresso: nil, motivoAssente: "Per disegnare la linea della vita serve la data di nascita di \(primoNome).",
                                         avvisi: [], ipotesi: [], etaPensioneIpotizzata: false, eventiSenzaCifra: 0)
        }
        var avvisi: [String] = []
        var ipotesi: [String] = ["Valori in euro di oggi, anno per anno fino a \(etaFinePredefinita) anni."]

        // Età di pensione: dal lavoro, dall'Analisi 360 salvata, altrimenti quella di vecchiaia come ipotesi
        let lavoro = cliente.profilo.lavoro
        let etaIndicata = lavoro?.etaPensione ?? analisi?.previdenza.etaPensione
        let etaPensione = min(max(etaIndicata ?? RegolePensione.etaVecchiaia, etaPensioneMinima), etaPensioneMassima)
        if etaIndicata == nil { ipotesi.append("Età di pensione non indicata: ipotesi \(etaPensione) anni.") }

        // Patrimonio e versamenti: le posizioni finanziarie in essere, come il patrimonio nel tempo
        let finanziarie = posizioni.filter { $0.clienteId == cliente.id && $0.stato == .inEssere && $0.valore > 0
            && ($0.area.proiettabile || $0.area == .liquidita) }
        let patrimonio = MotorePatrimonio.calcola(finanziarie, oggi: oggi)
        var risparmio = patrimonio.versamentiAnnui
        if let libero = cliente.profilo.risparmioAnnuo, libero.isFinite, libero > 0 {
            risparmio += libero
        } else {
            avvisi.append("Risparmio libero non indicato: conto solo i versamenti delle posizioni.")
        }

        // Rendimento reale: quello dell'Analisi 360 salvata, altrimenti la media delle posizioni (netta di costi e
        // imposta sul guadagno, tolta l'inflazione di Prisma), altrimenti l'ipotesi della previdenza
        let rendimento: Double
        if let a = analisi {
            rendimento = a.previdenza.rendimentoReale
            ipotesi.append("Rendimento reale dell'Analisi 360: \(CifreDoc.condizione(rendimento)) l'anno.")
        } else if let media = rendimentoRealeMedio(finanziarie) {
            rendimento = media
            ipotesi.append("Rendimento reale medio delle posizioni, netto di costi e imposte: \(CifreDoc.percento(media)) l'anno (inflazione del \(CifreDoc.condizione(IpotesiCalcolo.inflazione))).")
        } else {
            rendimento = IpotesiPrevidenza().rendimentoReale
            ipotesi.append("Nessuna posizione in essere: rendimento reale ipotizzato del \(CifreDoc.condizione(rendimento)) l'anno.")
        }

        // Reddito desiderato e pensione pubblica
        let redditoDesiderato = analisi?.previdenza.redditoDesiderato
        if redditoDesiderato == nil {
            avvisi.append("Manca il reddito desiderato in pensione: dopo i \(etaPensione) anni la linea è solo indicativa.")
        }
        var pensioni: [Int: Double] = [:]
        if let a = analisi {
            // La pensione inserita a mano nell'Analisi 360 vince sempre (`pensioneDaUsare`)
            let p = MotorePensionePubblica.pensioneDaUsare(a.previdenza, stima: nil, inseritaAMano: true)
            for e in etaPensioneMinima...etaPensioneMassima { pensioni[e] = p }
        } else if let lavoro {
            for e in etaPensioneMinima...etaPensioneMassima {
                if let s = MotorePensionePubblica.stima(lavoro: lavoro, eta: etaOggi, etaPensione: e, reddito: cliente.profilo.redditoLordoAnnuo) {
                    pensioni[e] = MotoreFiscale.centesimi(s.nettaMensile)
                }
            }
        }
        if pensioni.isEmpty {
            avvisi.append(MotorePensionePubblica.motivoAssente(lavoro, reddito: cliente.profilo.redditoLordoAnnuo)
                          ?? "Pensione pubblica non stimabile: il prelievo in pensione non si calcola.")
        } else {
            ipotesi.append(analisi != nil ? "Pensione pubblica netta dell'Analisi 360." : "Pensione pubblica netta stimata con il contributivo per l'età di uscita.")
        }
        ipotesi.append("I fondi pensione sono nel patrimonio: la loro rendita non si conta a parte.")

        // Eventi e obiettivi
        let annoOggi = Calendar.current.component(.year, from: oggi)
        let propri = eventi.filter { $0.clienteId == cliente.id }
        var movimenti: [MovimentoLineaVita] = []
        var senzaCifra = 0
        var conEta: [(evento: EventoLineaVita, eta: Int)] = []
        for e in propri {
            guard let eta = e.etaEvento(etaOggi: etaOggi, annoOggi: annoOggi) else { senzaCifra += 1; continue }
            conEta.append((e, eta))
            guard let importo = e.importo, importo.isFinite, importo != 0 else { senzaCifra += 1; continue }
            movimenti.append(MovimentoLineaVita(id: e.id, eta: eta, importo: importo, perAnni: e.anniDurata))
        }
        if conObiettivi {
            for o in obiettivi where o.clienteId == cliente.id && o.scadenza > oggi {
                let resta = o.importo - o.accantonato
                guard resta > 0.5, let eta = MotorePensionePubblica.etaAl(cliente.dataNascita, o.scadenza) else { continue }
                let doppio = conEta.contains { $0.eta == eta && $0.evento.tipo.area == o.area && $0.evento.importo != nil }
                guard !doppio else { continue }
                movimenti.append(MovimentoLineaVita(id: o.id, eta: eta, importo: -resta, perAnni: 1, daObiettivo: true))
            }
        }
        if propri.contains(where: { $0.tipo == .eredita && ($0.importo ?? 0) > 0 }) {
            avvisi.append("Eredità al lordo dell'imposta di successione.")
        }

        let ingresso = IngressoLineaVita(etaOggi: etaOggi, etaPensione: etaPensione, patrimonioIniziale: patrimonio.nettoOggi,
                                         risparmioAnnuo: risparmio, rendimentoReale: rendimento, redditoDesiderato: redditoDesiderato,
                                         pensionePerEta: pensioni, movimenti: movimenti)
        return PreparazioneLineaVita(ingresso: ingresso, motivoAssente: nil, avvisi: avvisi, ipotesi: ipotesi,
                                     etaPensioneIpotizzata: etaIndicata == nil, eventiSenzaCifra: senzaCifra)
    }

    /// Rendimento reale medio pesato sul valore (%): netto di costi, poi dell'imposta sul guadagno se positivo
    /// (`IpotesiCalcolo.aliquotaPredefinita`), poi tolta l'inflazione di Prisma. nil senza posizioni.
    static func rendimentoRealeMedio(_ finanziarie: [Posizione]) -> Double? {
        let peso = finanziarie.reduce(0) { $0 + max(0, $1.valore) }
        guard peso > 0 else { return nil }
        let nominale = finanziarie.reduce(0) { $0 + MotoreResistenza.rendimentoNettoInflazione($1) * max(0, $1.valore) } / peso
        let netto = nominale > 0 ? nominale * (1 - IpotesiCalcolo.aliquotaPredefinita / 100) : nominale
        return ((1 + netto / 100) / (1 + IpotesiCalcolo.inflazione / 100) - 1) * 100
    }

    /// Un evento trascinato: l'età resta fra l'anno prossimo e `etaEventoMassima`.
    static func limitaEtaEvento(_ eta: Int, etaOggi: Int) -> Int { min(max(eta, etaOggi + 1), etaEventoMassima) }

    /// La pensione trascinata: fra `etaPensioneMinima` e `etaPensioneMassima`.
    static func limitaEtaPensione(_ eta: Int) -> Int { min(max(eta, etaPensioneMinima), etaPensioneMassima) }
}
