import Combine
import Foundation
import Observation
#if os(iOS)
import UIKit
#endif

// La nota vocale sull'iPhone e sull'iPad («Luce» giro 13, Design/template-luce-specifica.md §6.2.1 §1.3, §6.2.4): lo
// stato della schermata «Una nota veloce». Il microfono e il riconoscimento sono quelli del copilota (`AscoltoVera` con
// `PermessiCopilota.chiedi`), **sul dispositivo**: l'audio non si registra né si salva. La nota è fatta di frasi
// concatenate (una frase si chiude dopo 50 s o alla pausa), con il limite totale di 3 minuti (`Movimenti.dopo`, niente
// Timer). Con l'app in background o lo schermo bloccato l'ascolto si ferma e il testo resta (nessuna modalità audio in
// background, decisione 33). Il file è comune (StatoShell lo tiene anche sul Mac, dove non si usa): le parti di UIKit
// stanno sotto `#if os(iOS)`.

/// A che punto è la nota.
enum FaseNotaTelefono: Equatable {
    /// Tocca per iniziare.
    case pronta
    case ascolto
    /// Fermata: il testo si corregge, poi «Manda al Mac».
    case fermata
    /// Il Mac ha risposto «accettata».
    case mandata
    /// Il Mac non risponde: la nota è nelle «Note in partenza».
    case inCoda
}

@Observable final class StatoNotaVocaleTelefono {
    /// La durata massima di una nota (3 minuti).
    static let durataMassima: TimeInterval = 180
    /// Senza voce l'ascolto aspetta di più prima di chiudere una frase (come il copilota).
    static let attesaSenzaVoce: TimeInterval = 45
    /// I livelli dell'onda tenuti (le ultime 39 barre).
    static let livelliTenuti = 39

    private(set) var fase: FaseNotaTelefono = .pronta
    /// Il testo dettato (le frasi finite), correggibile a nota fermata.
    var testo = ""
    /// La frase in corso (mentre parli).
    private(set) var inCorso = ""
    private(set) var livelli: [Float] = []
    /// La riga di stato («Ascolto · sull’iPhone», «Pronta. Tocca ✓ per mandarla al Mac»…).
    private(set) var riga = ""
    /// «Scarico il riconoscimento dell’italiano da Apple» quando serve (decisione 32).
    private(set) var avviso: String?
    /// Le note in partenza (la coda cifrata sul telefono).
    var coda: [CodaNoteVocali.VoceCoda] = []
    /// L'id della nota di adesso: stabile fra un tentativo e l'altro.
    private(set) var id = StatoNotaVocaleTelefono.nuovoId()
    /// Il cliente dell'appuntamento appena concluso, se l'iPhone lo sa (solo come indizio per il Mac).
    var clienteSuggerito: String?
    var appuntamentoSuggerito: String?
    /// La nota si è fermata da sola a 3 minuti.
    private(set) var fermataAlLimite = false
    @ObservationIgnored private var inizio: Date?
    @ObservationIgnored private(set) var durata: Double = 0
    @ObservationIgnored private var giro = 0
    @ObservationIgnored private var ultimaFrase = false
    @ObservationIgnored private var ascolto: AscoltoVera?
    @ObservationIgnored private var abbonamenti = Set<AnyCancellable>()
    @ObservationIgnored private var sfondoOsservato = false

    static func nuovoId() -> String { "nota-\(UUID().uuidString.prefix(8).lowercased())" }

    var ascolta: Bool { fase == .ascolto }

    /// Il testo con la frase in corso (quello che si vede mentre parli).
    var testoMostrato: String {
        let t = testo.trimmingCharacters(in: .whitespaces)
        let c = inCorso.trimmingCharacters(in: .whitespaces)
        if c.isEmpty { return t }
        return t.isEmpty ? c : t + " " + c
    }

    // MARK: Ascolto

    /// Tocca il pulsante: inizia (i permessi la prima volta) o ferma.
    func alterna() {
        if fase == .ascolto { ferma() } else { avvia() }
    }

    func avvia() {
        guard fase != .ascolto else { return }
        if fase == .mandata || fase == .inCoda { nuova() }
        giro += 1
        let g = giro
        fase = .ascolto
        fermataAlLimite = false
        ultimaFrase = false
        riga = "Ascolto · sull’iPhone"
        if inizio == nil { inizio = Date() }
        osservaSfondo()
        ascoltaFrase()
        // Il limite di 3 minuti dall'inizio della nota (niente Timer)
        let mancano = max(1, Self.durataMassima - durata)
        Movimenti.dopo(mancano) { [weak self] in
            guard let self, self.giro == g, self.fase == .ascolto else { return }
            self.fermataAlLimite = true
            self.ferma()
            self.riga = "Nota lunga: fermata a 3 minuti"
        }
    }

    /// Ferma l'ascolto: l'ultima frase arriva con il testo definitivo, poi «Pronta».
    func ferma() {
        guard fase == .ascolto else { return }
        giro += 1
        ultimaFrase = true
        if let i = inizio { durata += Date().timeIntervalSince(i) }
        inizio = nil
        fase = .fermata
        riga = "Pronta. Tocca ✓ per mandarla al Mac"
        livelli = []
        ascolto?.ferma(invia: true)
    }

    /// Una nota nuova (dopo l'invio o «Ricomincia»).
    func nuova() {
        giro += 1
        ascolto?.ferma(invia: false)
        testo = ""
        inCorso = ""
        livelli = []
        durata = 0
        inizio = nil
        id = Self.nuovoId()
        fase = .pronta
        riga = ""
        fermataAlLimite = false
    }

    /// Chiudendo la schermata l'ascolto si ferma (il testo non mandato si perde: l'audio non c'è mai stato).
    func chiudi() {
        if fase == .ascolto { ferma() }
        ascolto?.ferma(invia: false)
        PermessiCopilota.rilascia()
    }

    private func motore() -> AscoltoVera {
        if let a = ascolto { return a }
        let a = AscoltoVera(permessi: PermessiCopilota.chiedi)
        a.tempi.attesaMassima = Self.attesaSenzaVoce
        a.$trascritto
            .removeDuplicates()
            .sink { [weak self] t in
                guard let self, self.fase == .ascolto || self.ultimaFrase else { return }
                self.inCorso = t
            }
            .store(in: &abbonamenti)
        a.$livello
            .sink { [weak self] l in
                guard let self, self.fase == .ascolto else { return }
                var x = self.livelli
                x.append(l)
                if x.count > Self.livelliTenuti { x.removeFirst(x.count - Self.livelliTenuti) }
                self.livelli = x
            }
            .store(in: &abbonamenti)
        a.$nota
            .sink { [weak self] n in
                // Solo l'avviso del primo scaricamento dell'italiano (decisione 32)
                self?.avviso = n == Trascrizioni.avvisoScaricamento ? n : nil
            }
            .store(in: &abbonamenti)
        ascolto = a
        return a
    }

    private func ascoltaFrase() {
        let a = motore()
        a.concluso = { [weak self] frase in self?.fraseFinita(frase) }
        a.problema = { [weak self] motivo in self?.problema(motivo) }
        a.azzera()
        a.avvia(.automatico)
    }

    private func fraseFinita(_ frase: String) {
        let f = frase.trimmingCharacters(in: .whitespacesAndNewlines)
        if !f.isEmpty { testo = testo.isEmpty ? f : testo + " " + f }
        inCorso = ""
        if ultimaFrase {
            ultimaFrase = false
            PermessiCopilota.rilascia()
            return
        }
        guard fase == .ascolto else { return }
        let g = giro
        Movimenti.dopo(Tema.Apple.Moto.Copilota.ripresaAscolto) { [weak self] in
            guard let self, self.giro == g, self.fase == .ascolto else { return }
            self.ascoltaFrase()
        }
    }

    private func problema(_ motivo: String) {
        if ultimaFrase {
            ultimaFrase = false
            PermessiCopilota.rilascia()
            return
        }
        // Una frase senza parole durante una pausa lunga: si torna ad ascoltare; il resto ferma la nota con il motivo
        if fase == .ascolto, ascolto?.senzaParole == true {
            let g = giro
            Movimenti.dopo(Tema.Apple.Moto.Copilota.ripresaAscolto) { [weak self] in
                guard let self, self.giro == g, self.fase == .ascolto else { return }
                self.ascoltaFrase()
            }
            return
        }
        giro += 1
        if let i = inizio { durata += Date().timeIntervalSince(i) }
        inizio = nil
        fase = testo.isEmpty ? .pronta : .fermata
        riga = motivo
        livelli = []
        PermessiCopilota.rilascia()
    }

    /// App in background o schermo bloccato: l'ascolto si ferma, il testo resta (decisione 33).
    private func osservaSfondo() {
        guard !sfondoOsservato else { return }
        sfondoOsservato = true
        #if os(iOS)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.ferma() }
            .store(in: &abbonamenti)
        #endif
    }

    // MARK: Invio

    /// La nota da mandare (solo testo).
    func notaPonte(dispositivo: String) -> NotaVocalePonte? {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        return NotaVocalePonte(id: id, testo: String(t.prefix(PonteVera.massimoTestoNota)), quando: Date(),
                               durata: min(600, max(0, durata)), dispositivo: String(dispositivo.prefix(PonteVera.massimoDispositivo)),
                               clienteId: clienteSuggerito, appuntamentoId: appuntamentoSuggerito)
    }

    /// L'esito della consegna della nota di adesso.
    func esito(_ r: RicevutaPonte?, inCoda: Bool) {
        if r?.accettato == true {
            fase = .mandata
            riga = "✓ Nota mandata al Mac"
        } else if inCoda {
            fase = .inCoda
            if let r, !r.macIrraggiungibile, let motivo = r.motivo {
                riga = motivo
            } else {
                riga = "Il Mac non è raggiungibile: la nota parte quando sarai in rete con il Mac"
            }
        } else {
            riga = r?.motivo ?? PonteVera.macNonTrovato
        }
    }

    /// La coda è piena (20 note): la nota non entra, resta sullo schermo.
    func codaPiena() {
        riga = "Ci sono già \(CodaNoteVocali.massimo) note in partenza: mandale al Mac o cancellane una."
    }

    /// Solo per le istantanee (dati di prova dichiarati): la schermata in uno stato fermo.
    func preparaIstantanea(fase f: FaseNotaTelefono, testo t: String, livelli l: [Float], riga r: String, coda c: [CodaNoteVocali.VoceCoda]) {
        giro += 1
        fase = f
        testo = t
        inCorso = ""
        livelli = l
        riga = r
        coda = c
    }
}
