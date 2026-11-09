#if os(macOS)
import AppKit
#endif
import SwiftUI

// Proprietario: G1 (movimento delle finestre). Spostato qui da StatoShell.swift dalle fondamenta (G0).
// Ogni azione ha la sua curva (DesignSystem/Movimento.swift); con lo stato non persistente (istantanee e prove)
// tutto cambia di colpo e subito, come prima.
// In un giro del run loop la prima modifica dello stato porta la transazione giusta: le modifiche senza
// animazione vengono dopo quella animata, mai prima, altrimenti la vista le leggerebbe tutte insieme senza animazione.

// MARK: - Inoltri a StatoFinestre

extension StatoShell {
    // Le finestre, i pannelli e il blocco vivono in `sistema` (StatoFinestre): cambiarli non pubblica StatoShell,
    // così le app aperte e i widget non si ricalcolano. I nomi restano quelli di sempre.

    /// Finestre aperte; l'ultima è quella in primo piano.
    var finestre: [Finestra] {
        get { sistema.elenco }
        set {
            sistema.elenco = newValue
            // Istantanee e prove (tutto di colpo): subito ciò che il Mac mostra a transizione finita
            if !persistente { allineaCoperteSubito() }
        }
    }

    /// La schermata di benvenuto copre le finestre (il lucchetto in alto).
    var bloccato: Bool {
        get { sistema.bloccato }
        set { sistema.bloccato = newValue }
    }

    var pannelloAppAperte: Bool {
        get { sistema.pannelloAppAperte }
        set { sistema.pannelloAppAperte = newValue }
    }

    /// Il pannello degli spazi di lavoro è aperto.
    var pannelloSpazi: Bool {
        get { sistema.pannelloSpazi }
        set { sistema.pannelloSpazi = newValue }
    }

    /// Il centro notifiche è aperto.
    var pannelloNotifiche: Bool {
        get { sistema.pannelloNotifiche }
        set { sistema.pannelloNotifiche = newValue }
    }

    var finestreVisibili: [Finestra] { sistema.visibili }

    /// App in primo piano (nil = scrivania).
    var appAttiva: AppPrisma? { sistema.appAttiva }

    /// Lo sfondo d'acqua non si vede affatto: lo copre la sala (opaca) della presentazione dei Prospetti o di
    /// un'esperienza della Sala («Luce», `SovrapposizioneLuce.coprente`). Solo allora l'acqua si ferma: lo sfondo è
    /// sempre attivo, anche sotto le finestre aperte e ingrandite (si vede dal vetro e dalla cornice attorno) e sotto
    /// la schermata di benvenuto.
    var scrivaniaCoperta: Bool { presentazione != nil || sistema.sovrapposizione?.coprente == true }

    func aperta(_ app: AppPrisma) -> Bool { sistema.aperta(app) }
}

// MARK: - Finestre

extension StatoShell {
    /// Cambia lo stato senza animazione. Con `implicite` le animazioni circoscritte di ShellView (dock, pannelli)
    /// lavorano lo stesso; senza (istantanee, prove, stop del Mac) cambia tutto di colpo.
    fileprivate func diColpo(implicite: Bool = true, _ cambia: () -> Void) {
        if implicite && persistente {
            withTransaction(Transaction(animation: nil), cambia)
        } else {
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t, cambia)
        }
    }

    /// Il centro dell'icona dell'app nel dock (coordinate `ShellView.spazioShell`). Con finestre aperte il dock
    /// è nascosto: l'icona è sul bordo in basso. `nascosto`: come sarà il dock a movimento finito.
    /// nil per le app senza icona nel dock (accorpate, Prodotti, Note, Ricerca): la finestra compare al suo posto.
    fileprivate func centroDock(_ app: AppPrisma, nascosto: Bool? = nil) -> CGPoint? {
        DisposizioneDock.centroIcona(app, tra: AppPrisma.delDock.filter { appConsentita($0) },
                                     in: sistema.misura, nascosto: nascosto ?? !finestreVisibili.isEmpty)
    }

    /// Apre l'app (o la riporta davanti). `origine`: da dove si apre, nelle coordinate `ShellView.spazioShell`
    /// (icona della scrivania, widget). Come in macOS la finestra nuova compare al suo posto e quella ridotta
    /// torna sempre dall'icona del dock: l'origine serve solo se il dock non c'è.
    func apri(_ app: AppPrisma, da origine: CGPoint? = nil) {
        guard appConsentita(app) else {
            mostraAvviso("In modalità cliente \(app.titolo) non si apre: mostra i dati di altri clienti.")
            return
        }
        #if os(macOS)
        // Le app accorpate (Obiettivi, Documenti, Simulazioni, Confronti, Attività) si aprono nel loro ospite,
        // sulla scheda giusta: tutte le chiamate `apri(.documenti)` e simili passano da qui
        if let ospite = app.ospite {
            preparaOspite(per: app)
            apri(ospite, da: origine)
            return
        }
        #endif
        sistema.giroScrivania &+= 1
        // Chiusa un attimo fa e non ancora tolta: si toglie ora e si riapre da capo
        if sistema.inChiusura.contains(app) { completaChiusura(app) }
        if let f = finestre.first(where: { $0.app == app }) {
            if f.ridotta {
                ripristina(app, da: origine)
            } else {
                // Già aperta: davanti di colpo, come su macOS
                primoPiano(app)
            }
        } else {
            nuova(app, da: origine)
        }
        if app == .impostazioni { aggiornaElencoBackup() }
        if app == .vera || app == .impostazioni { verificaMotoreLocale() }
    }

    // MARK: Il volo dall'icona del dock (template-apple-specifica.md §3.5)

    /// Il rettangolo dell'icona dell'app nel dock in vista (spazio `ShellView.spazioShell`), da cui la finestra
    /// esce e in cui rientra. Misura e x sono quelle dell'icona adesso (ingrandita dal puntatore, se ci passa sopra:
    /// la riporta il dock in `iconeDock`), il fondo è quello del dock in vista: durante il volo il dock si mostra.
    /// nil se l'app non ha un'icona nel dock.
    fileprivate func rettangoloIcona(_ app: AppPrisma) -> CGRect? {
        guard let centro = centroDock(app, nascosto: false) else { return nil }
        let lato = Tema.Misura.dockIcona
        let fondo = centro.y + lato / 2
        if let r = sistema.iconeDock.cornici[app], r.width > 0, r.height > 0 {
            return CGRect(x: r.minX, y: fondo - r.height, width: r.width, height: r.height)
        }
        return CGRect(x: centro.x - lato / 2, y: centro.y - lato / 2, width: lato, height: lato)
    }

    /// Da dove esce la finestra: dal punto da cui si apre (icona della scrivania, widget), grande come un'icona,
    /// o dalla sua icona del dock.
    fileprivate func partenzaVolo(_ app: AppPrisma, da origine: CGPoint?) -> CGRect? {
        guard let p = origine else { return rettangoloIcona(app) }
        let lato = Tema.Misura.dockIcona
        return CGRect(x: p.x - lato / 2, y: p.y - lato / 2, width: lato, height: lato)
    }

    /// Segna da dove esce (o dove rientra) la finestra: il rettangolo per il volo e il suo centro come origine.
    fileprivate func segnaVolo(_ app: AppPrisma, _ rettangolo: CGRect?) {
        sistema.iconeDock.voli[app] = rettangolo
        sistema.origini[app] = rettangolo.map { CGPoint(x: $0.midX, y: $0.midY) }
    }

    /// Curva e durata dell'uscita dall'icona: sul Mac 0,6 s con `(0.3,1.12,0.5,1)`; su iPhone e iPad quella di sempre.
    fileprivate var aperturaFinestra: (curva: Animation, durata: Double) {
        #if os(macOS)
        let durata = Tema.Apple.Moto.FinestraApre.durata * rallentamento
        return (Tema.Apple.Moto.VoloFinestra.apertura(durata: durata), durata)
        #else
        return (Tema.Moto.Finestre.apertura, Tema.Moto.Finestre.durataApertura)
        #endif
    }

    /// Curva e durata del rientro nell'icona (chiusura e riduzione): 0,48 s con `(0.5,0,0.3,1)`.
    fileprivate var rientroFinestra: (curva: Animation, durata: Double) {
        let durata = Tema.Apple.Moto.FinestraChiude.durata * rallentamento
        return (Tema.Apple.Moto.VoloFinestra.chiusura(durata: durata), durata)
    }

    /// Una finestra nuova: entra subito dentro la sua icona, invisibile, senza animazione (il corpo dell'app si
    /// costruisce qui); al giro dopo esce dall'icona e arriva al suo posto (VoloDallIcona), già pronta.
    fileprivate func nuova(_ app: AppPrisma, da origine: CGPoint?) {
        let f = Finestra(app: app, cornice: corniceIniziale())
        guard persistente else {
            diColpo(implicite: false) {
                finestre.append(f)
                sistema.spente.remove(app)
            }
            return
        }
        let apertura = aperturaFinestra
        #if os(macOS)
        // Dal punto da cui si apre (icona della scrivania, widget) o dalla sua icona del dock; senza: al suo posto
        let partenza = partenzaVolo(app, da: origine)
        segnaVolo(app, partenza)
        let dalDock = origine == nil && partenza != nil && !Movimenti.calmo
        #elseif os(iOS)
        // Su iPhone e iPad l'origine la legge FinestraMobile (scala dall'ancora)
        sistema.origini[app] = origine ?? (finestreVisibili.isEmpty ? centroDock(app, nascosto: false) : nil)
        let dalDock = false
        #endif
        diColpo {
            finestre.append(f)
            sistema.inArrivo.insert(app)
            if sistema.spente.contains(app) { sistema.spente.remove(app) }
        }
        // Il dock resta in vista mentre la finestra esce dalla sua icona (poi si nasconde, come sempre)
        if dalDock {
            mostraDockPerEffetto(app)
            rilasciaDock(app, dopo: apertura.durata)
        }
        Movimenti.alGiroDopo(apertura.curva, durata: apertura.durata) { [weak self] in
            guard let self else { return }
            self.sistema.inArrivo.remove(app)
        }
        aggiornaCoperte(dopo: apertura.durata)
    }

    /// La finestra ridotta esce di nuovo dalla sua icona del dock: è rimasta montata, non si ricostruisce.
    /// Come macOS torna sempre dall'icona (il punto d'origine serve solo se l'app non ne ha una).
    fileprivate func ripristina(_ app: AppPrisma, da origine: CGPoint?) {
        guard finestre.contains(where: { $0.app == app }) else { return }
        guard persistente else {
            diColpo(implicite: false) {
                rimetti(app)
                sistema.spente.remove(app)
            }
            return
        }
        let calmo = Movimenti.calmo
        #if os(macOS)
        let apertura = aperturaFinestra
        segnaVolo(app, rettangoloIcona(app) ?? partenzaVolo(app, da: origine))
        #elseif os(iOS)
        let m = Tema.Moto.Finestre.self
        let apertura = (curva: m.ripristino, durata: m.durataRipristino * rallentamento)
        let punto = centroDock(app, nascosto: calmo ? nil : false) ?? origine
        if let punto { sistema.origini[app] = punto }
        #endif
        if sistema.spente.contains(app) {
            // I controlli si riaccendono subito, di colpo: il costo cade prima del primo fotogramma
            diColpo { _ = sistema.spente.remove(app) }
            Movimenti.alGiroDopo(apertura.curva, durata: apertura.durata) { [weak self] in self?.rimetti(app) }
        } else {
            // Ripristinata mentre rientrava: torna indietro da dove si trova
            Movimenti.anima(apertura.curva, durata: apertura.durata) { rimetti(app) }
        }
        // Il dock in vista dopo il cambio animato (mai prima, nello stesso giro)
        if !calmo {
            mostraDockPerEffetto(app)
            rilasciaDock(app, dopo: apertura.durata)
        }
        aggiornaCoperte(dopo: apertura.durata)
    }

    /// Riporta l'app ridotta in primo piano (la transazione la dà chi chiama).
    fileprivate func rimetti(_ app: AppPrisma) {
        guard let i = finestre.firstIndex(where: { $0.app == app }), finestre[i].ridotta else { return }
        var elenco = finestre
        var f = elenco.remove(at: i)
        f.ridotta = false
        elenco.append(f)
        finestre = elenco
    }

    /// Porta l'app davanti: istantaneo come su macOS (cambia solo l'ordine e l'ombra passa ad attiva di colpo).
    func primoPiano(_ app: AppPrisma) {
        guard let i = finestre.firstIndex(where: { $0.app == app }), i != finestre.count - 1 else { return }
        sistema.giroScrivania &+= 1
        var elenco = finestre
        let f = elenco.remove(at: i)
        elenco.append(f)
        diColpo { finestre = elenco }
        aggiornaCoperte(dopo: 0)
    }

    /// Chiude l'app. Sul Mac la finestra rientra nella sua icona del dock (0,48 s, svanisce dopo il 60%) e a volo
    /// finito si toglie. Ridotta o coperta da una finestra ingrandita (non si vede), e su iPhone e iPad, se ne va
    /// di colpo. Con «Riduci movimento», nelle istantanee e nelle prove: la dissolvenza di sempre.
    func chiudi(_ app: AppPrisma) {
        if let f = finestre.first(where: { $0.app == app }) {
            let m = Tema.Moto.Finestre.self
            if persistente && !Movimenti.calmo {
                #if os(macOS)
                let volo = !f.ridotta && !sistema.coperte.contains(app)
                #elseif os(iOS)
                let volo = false
                _ = f
                #endif
                if volo {
                    chiudiNellIcona(app)
                } else {
                    // Prima invisibile di colpo (così la sua uscita è senza transizione), poi via al giro dopo
                    diColpo(implicite: false) { _ = sistema.nascoste.insert(app) }
                    sistema.inChiusura.insert(app)
                    rilasciaDock(app, dopo: 0)
                    DispatchQueue.main.async { [weak self] in self?.completaChiusura(app) }
                }
            } else {
                Movimenti.anima(m.chiusura, durata: m.durataChiusura, animato: persistente) {
                    finestre.removeAll { $0.app == app }
                }
                if sistema.flip[app] != nil || sistema.inArrivo.contains(app) || sistema.spente.contains(app)
                    || sistema.nascoste.contains(app) || sistema.rientrano.contains(app) {
                    diColpo {
                        sistema.flip[app] = nil
                        sistema.inArrivo.remove(app)
                        sistema.spente.remove(app)
                        sistema.nascoste.remove(app)
                        sistema.rientrano.remove(app)
                    }
                }
                aggiornaCoperte(dopo: m.durataChiusura)
            }
        }
        if app == .vera { spegniVoceSeVeraSparisce() }
    }

    /// La finestra rientra nella sua icona del dock; resta nell'elenco finché il volo non finisce (`rientrano`:
    /// non prende clic e il suo pallino nel dock è già spento), poi si toglie di colpo. Il dock resta in vista.
    fileprivate func chiudiNellIcona(_ app: AppPrisma) {
        let rientro = rientroFinestra
        let bersaglio = rettangoloIcona(app)
        segnaVolo(app, bersaglio)
        // Prima il cambio animato, poi quelli senza animazione
        Movimenti.anima(rientro.curva, durata: rientro.durata) {
            _ = sistema.rientrano.insert(app)
        }
        // Ciò che c'era sotto (scrivania compresa) torna in vista all'inizio del volo, non con uno scatto alla fine
        aggiornaCoperte(dopo: 0)
        sistema.inChiusura.insert(app)
        if bersaglio != nil { mostraDockPerEffetto(app) }
        rilasciaDock(app, dopo: rientro.durata)
        Movimenti.dopo(rientro.durata) { [weak self] in self?.completaChiusura(app) }
    }

    /// Toglie davvero la finestra chiusa (a volo finito o al giro dopo `chiudi`, o subito se nel frattempo la si riapre).
    fileprivate func completaChiusura(_ app: AppPrisma, coperteDopo: Double = 0) {
        guard sistema.inChiusura.remove(app) != nil else { return }
        diColpo(implicite: false) {
            finestre.removeAll { $0.app == app }
            if sistema.nascoste.contains(app) { sistema.nascoste.remove(app) }
            if sistema.rientrano.contains(app) { sistema.rientrano.remove(app) }
            if sistema.flip[app] != nil { sistema.flip[app] = nil }
            if sistema.inArrivo.contains(app) { sistema.inArrivo.remove(app) }
            if sistema.spente.contains(app) { sistema.spente.remove(app) }
        }
        aggiornaCoperte(dopo: coperteDopo)
    }

    /// Riduce l'app nel dock: la finestra rientra nella sua icona e resta montata, invisibile, con tutto il suo stato.
    func riduci(_ app: AppPrisma) {
        // Se è l'ultima finestra in vista il dock ricompare: la finestra va nella sua icona, non sul bordo
        riduci(app, dockNascosto: finestreVisibili.contains { $0.app != app })
    }

    /// `dockNascosto`: come sarà il dock a riduzione finita (su iPhone e iPad dà il punto in cui rimpicciolire).
    /// `conIstantanea` resta per chi chiama (Mostra la scrivania): il volo non usa istantanee.
    /// Sul Mac la finestra viva rientra nell'icona del dock (che resta in vista durante il volo) in 0,48 s,
    /// con scale x e y separate, e svanisce solo dopo il 60%; con «Riduci movimento» svanisce e basta.
    fileprivate func riduci(_ app: AppPrisma, dockNascosto: Bool, conIstantanea: Bool = true) {
        guard let i = finestre.firstIndex(where: { $0.app == app }), !finestre[i].ridotta else { return }
        guard persistente else {
            diColpo(implicite: false) {
                finestre[i].ridotta = true
                sistema.spente.insert(app)
            }
            if app == .vera { spegniVoceSeVeraSparisce() }
            return
        }
        _ = conIstantanea
        defer {
            #if os(macOS)
            // Il campo con il cursore resta nella finestra ridotta: i tasti non devono finirci
            NSApp.keyWindow?.makeFirstResponder(nil)
            #endif
            if app == .vera { spegniVoceSeVeraSparisce() }
        }
        let calmo = Movimenti.calmo
        #if os(macOS)
        _ = dockNascosto
        let rientro = rientroFinestra
        segnaVolo(app, rettangoloIcona(app))
        #elseif os(iOS)
        // Su iPhone e iPad la finestra viva rimpicciolisce verso l'icona e svanisce, solo con una scala
        let m = Tema.Moto.Finestre.self
        let rientro = (curva: m.ripiegoGenio, durata: m.durataRipiegoGenio * rallentamento)
        let punto = centroDock(app, nascosto: calmo ? dockNascosto : false)
        if let punto { sistema.origini[app] = punto }
        #endif
        Movimenti.anima(rientro.curva, durata: rientro.durata) {
            finestre[i].ridotta = true
        }
        // A movimento finito i controlli dell'app si spengono (se nel frattempo non è tornata)
        Movimenti.dopo(rientro.durata) { [weak self] in
            guard let self, self.finestre.first(where: { $0.app == app })?.ridotta == true,
                  !self.sistema.spente.contains(app) else { return }
            self.sistema.spente.insert(app)
        }
        // Il dock in vista dopo il cambio animato (mai prima, nello stesso giro)
        if !calmo {
            mostraDockPerEffetto(app)
            rilasciaDock(app, dopo: rientro.durata)
        }
        aggiornaCoperte(dopo: rientro.durata)
    }

    #if os(macOS)
    /// Con Maiusc premuto il volo va al rallentatore, come su macOS.
    fileprivate var rallentamento: Double {
        NSEvent.modifierFlags.contains(.shift) ? Tema.Moto.Finestre.fattoreRallentato : 1
    }
    #elseif os(iOS)
    /// Su iPhone e iPad nessun rallentatore (niente Maiusc tenuto premuto da leggere).
    fileprivate var rallentamento: Double { 1 }
    #endif

    /// Il dock resta in vista durante l'effetto dell'app (con il dock nascosto si mostra, come macOS).
    fileprivate func mostraDockPerEffetto(_ app: AppPrisma) {
        guard !sistema.dockPerEffetti.contains(app) else { return }
        diColpo { _ = sistema.dockPerEffetti.insert(app) }
    }

    /// Dopo `dopo` secondi più il ritardo del dock, il dock torna com'era (si nasconde con la sua curva, se ci
    /// sono finestre in vista), a meno che l'app non abbia nel frattempo un altro effetto.
    fileprivate func rilasciaDock(_ app: AppPrisma, dopo: Double) {
        guard sistema.dockPerEffetti.contains(app) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + dopo + Tema.Moto.Dock.ritardoNascondi) { [weak self] in
            #if os(macOS)
            guard let self, self.sistema.dockPerEffetti.contains(app), !MotoreGenio.condiviso.inCorso(app) else { return }
            #elseif os(iOS)
            guard let self, self.sistema.dockPerEffetti.contains(app) else { return }
            #endif
            // Con la transazione vuota il dock scende con la sua animazione
            self.diColpo { _ = self.sistema.dockPerEffetti.remove(app) }
        }
    }

    /// Toglie di colpo tutti gli effetti in corso (blocco, presentazione, stop del Mac): le finestre tornano
    /// come dice lo stato e il dock com'era.
    func annullaEffetti() {
        #if os(macOS)
        MotoreGenio.condiviso.annullaTutto()
        #endif
        // Le finestre chiuse un attimo fa restano nascoste: si tolgono al giro dopo
        let restano = sistema.nascoste.intersection(sistema.inChiusura)
        guard sistema.nascoste != restano || !sistema.dockPerEffetti.isEmpty else { return }
        diColpo(implicite: false) {
            if sistema.nascoste != restano { sistema.nascoste = restano }
            if !sistema.dockPerEffetti.isEmpty { sistema.dockPerEffetti.removeAll() }
        }
    }

    func alternaIngrandimento(_ app: AppPrisma) {
        guard let i = finestre.firstIndex(where: { $0.app == app }) else { return }
        cambiaCornici {
            finestre[i].ingrandita.toggle()
            if !finestre[i].ingrandita {
                finestre[i].cornice = limita(finestre[i].cornice)
            }
        }
        primoPiano(app)
        aggiornaCoperte(dopo: Tema.Moto.Finestre.durataIngrandimento)
    }

    /// Mostra la schermata di benvenuto sopra tutto (chiude i pannelli aperti).
    /// `animato == false`: di colpo (per esempio prima dello stop del Mac).
    func blocca(animato: Bool = true) {
        let movimento = animato && persistente
        let giro = sistema.giroBlocco &+ 1
        sistema.giroBlocco = giro
        // I pannelli escono con le loro curve (contenitori di ShellView), nella stessa transazione del blocco
        Movimenti.anima(Tema.Moto.Blocco.scrivania, durata: Tema.Moto.Blocco.durata, animato: movimento) {
            if pannelloNotifiche { pannelloNotifiche = false }
            if pannelloSpazi { pannelloSpazi = false }
            if pannelloAppAperte { pannelloAppAperte = false }
            if sistema.pannelloNovita { sistema.pannelloNovita = false }
            // La guida si chiude senza segnare l'introduzione come vista: riparte al prossimo sblocco
            if sistema.guida != nil { sistema.guida = nil }
            if !bloccato { bloccato = true }
        }
        // Gli effetti in corso finiscono di colpo (dopo il cambio animato: mai prima, nello stesso giro)
        annullaEffetti()
        // La crescita del Territorio che sta passando gli anni si ferma («Luce» giro 11)
        territorio.fermaCrescita()
        // Dalla schermata di blocco si torna sempre a Prisma completo (e la finestra esce dal tutto schermo)
        chiudiPresentazione()
        // Il blocco (anche quando il Mac va a riposo) chiude le sovrapposizioni di «Luce»: storia, notte, scena del
        // telefono, presentazione di un'esperienza (decisione 53)
        chiudiSovrapposizione(animato: movimento)
        // Le carte d'identità arrivate dall'iPhone si scartano sempre, anche senza la scena aperta («Luce» giro 13,
        // decisione 25); il riposo del Mac passa da qui
        scartaCarteInArrivo()
        // Le copie da spedire delle cose date al cliente si tolgono al blocco («Luce» giro 15)
        CartellaUscite.svuota()
        guard movimento else {
            diColpo(implicite: false) {
                fermaVoce()
                if modoCliente != nil { modoCliente = nil }
                // Allo sblocco si torna alla scrivania con i widget
                if sistema.paginaVera != 0 || sistema.gestoVera.spostamento != 0 { nascondiVeraScrivania(animato: false) }
                sistema.bloccatoStabile = true
            }
            return
        }
        // La voce si ferma al giro dopo; la modalità cliente (che rifiltra tutte le app) a blocco finito, sotto la schermata
        DispatchQueue.main.async { [weak self] in self?.fermaVoce() }
        Movimenti.dopo(Tema.Moto.Blocco.durata) { [weak self] in
            guard let self else { return }
            if self.modoCliente != nil { self.modoCliente = nil }
            // Sotto la schermata: allo sblocco si torna alla scrivania con i widget
            if self.bloccato, self.sistema.paginaVera != 0 || self.sistema.gestoVera.spostamento != 0 {
                self.nascondiVeraScrivania(animato: false)
            }
            if self.sistema.giroBlocco == giro && self.bloccato { self.sistema.bloccatoStabile = true }
        }
    }

    /// Toglie la schermata di benvenuto. `velocita`: quella del gesto di sblocco, in percorsi al secondo
    /// (una parte passa all'entrata della scrivania).
    func sblocca(velocita: Double = 0) {
        guard bloccato else { return }
        // Avvio a due tempi: l'archivio non è ancora tutto in memoria. Lo sblocco parte appena arriva (di solito
        // pochi decimi di secondo, meno del gesto), mai su una scrivania con i dati a metà
        guard archivioPronto else {
            sbloccoInAttesa = velocita
            return
        }
        let giro = sistema.giroBlocco &+ 1
        sistema.giroBlocco = giro
        Movimenti.anima(Tema.Moto.Sblocco.entrata(velocita: velocita), durata: Tema.Moto.Sblocco.durataEntrata,
                        animato: persistente) {
            bloccato = false
        }
        // Il punto unico dello sblocco (EventiShell.swift): chi ascolta risponde, per esempio l'acqua con la goccia
        allaSblocco()
        guard persistente else {
            diColpo(implicite: false) { sistema.bloccatoStabile = false }
            return
        }
        Movimenti.dopo(Tema.Moto.Sblocco.durataEntrata) { [weak self] in
            guard let self, self.sistema.giroBlocco == giro, !self.bloccato else { return }
            self.sistema.bloccatoStabile = false
            // Al primo avvio parte l'introduzione «Come funziona Prisma»
            self.dopoSblocco()
            // Il tagliando, se una notte è saltata (a sblocco finito, mai durante l'entrata; CollegaTagliandoShell.swift)
            self.tagliandoSeDovuto()
        }
    }

    /// Riduce tutte le finestre e mostra la scrivania: una ogni 50 ms, dalla finestra in alto (tema showDesk).
    func mostraScrivania() {
        // «Scrivania» nel dock riporta sempre ai widget, anche dalla Vera della scrivania (VeraScrivania.swift)
        if sistema.paginaVera != 0 || sistema.gestoVera.spostamento != 0 { nascondiVeraScrivania() }
        let davanti = finestreVisibili.reversed().map(\.app)
        guard !davanti.isEmpty else { return }
        guard persistente else {
            var elenco = finestre
            for i in elenco.indices { elenco[i].ridotta = true }
            diColpo(implicite: false) {
                finestre = elenco
                sistema.spente.formUnion(elenco.map(\.app))
            }
            return
        }
        let giro = sistema.giroScrivania &+ 1
        sistema.giroScrivania = giro
        // A scrivania scoperta il dock ricompare: tutte le finestre entrano nelle loro icone
        // Oltre genioIstantaneeTenute finestre il genio delle altre è il ripiego (memoria: 8 GB)
        let tenute = Tema.Moto.Finestre.genioIstantaneeTenute
        for (k, app) in davanti.enumerated() {
            if k == 0 {
                riduci(app, dockNascosto: false)
                continue
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * Tema.Moto.Finestre.sfalsamento) { [weak self] in
                // Nel frattempo si è aperta o portata davanti un'app: quella resta dov'è
                guard let self, self.sistema.giroScrivania == giro else { return }
                self.riduci(app, dockNascosto: false, conIstantanea: k < tenute)
            }
        }
    }

    // MARK: - Transizioni delle cornici e finestre coperte

    /// Ingrandisci, affianca, spazi: la cornice nuova vale subito (una sola impaginazione dell'app), poi una
    /// trasformazione porta ogni finestra dalla cornice vecchia alla nuova (FLIP, come lo zoom di macOS).
    /// `arrivi`: le finestre che compaiono, che entrano con l'apertura.
    fileprivate func cambiaCornici(arrivi: Set<AppPrisma> = [], _ cambia: () -> Void) {
        guard persistente else {
            diColpo(implicite: false, cambia)
            return
        }
        let calmo = Movimenti.calmo
        var prima: [AppPrisma: CGRect] = [:]
        for f in finestreVisibili { prima[f.app] = cornice(di: f) }
        var passaggi: [AppPrisma: CGRect] = [:]
        diColpo {
            cambia()
            sistema.inArrivo.formUnion(arrivi)
            // Con «Riduci movimento» le cornici cambiano di colpo
            guard !calmo else { return }
            for f in finestreVisibili where !arrivi.contains(f.app) {
                guard let da = prima[f.app], da != cornice(di: f) else { continue }
                passaggi[f.app] = da
                sistema.flip[f.app] = PassaggioCornice(da: da, progresso: 0)
            }
        }
        let fatti = passaggi
        if !arrivi.isEmpty {
            let apertura = aperturaFinestra
            Movimenti.alGiroDopo(apertura.curva, durata: apertura.durata) { [weak self] in
                guard let self else { return }
                self.sistema.inArrivo.subtract(arrivi)
            }
        }
        guard !fatti.isEmpty else { return }
        Movimenti.alGiroDopo(Tema.Moto.Finestre.ingrandimento, durata: Tema.Moto.Finestre.durataIngrandimento) { [weak self] in
            guard let self else { return }
            for (app, da) in fatti where self.sistema.flip[app]?.da == da {
                self.sistema.flip[app]?.progresso = 1
            }
        }
        Movimenti.dopo(Tema.Moto.Finestre.fineIngrandimento) { [weak self] in
            guard let self else { return }
            for (app, da) in fatti where self.sistema.flip[app] == PassaggioCornice(da: da, progresso: 1) {
                self.sistema.flip[app] = nil
            }
        }
    }

    /// Le finestre sotto una finestra ingrandita (e la scrivania) a transizione finita non si disegnano: restano
    /// montate. Quelle che tornano in vista si mostrano subito, quelle coperte solo dopo `durata`.
    fileprivate func aggiornaCoperte(dopo durata: Double) {
        // Istantanee e prove: già allineate a ogni cambio delle finestre (`allineaCoperteSubito`)
        guard persistente else { return }
        let giro = sistema.giroCoperte &+ 1
        sistema.giroCoperte = giro
        let previste = copertePreviste
        let scoperte = sistema.coperte.subtracting(previste.finestre)
        if !scoperte.isEmpty || (sistema.scrivaniaNascosta && !previste.scrivania) {
            diColpo {
                if !scoperte.isEmpty { sistema.coperte.subtract(scoperte) }
                if sistema.scrivaniaNascosta && !previste.scrivania { sistema.scrivaniaNascosta = false }
            }
        }
        Movimenti.dopo(durata) { [weak self] in
            guard let self, self.sistema.giroCoperte == giro else { return }
            let ora = self.copertePreviste
            if self.sistema.coperte != ora.finestre { self.sistema.coperte = ora.finestre }
            if self.sistema.scrivaniaNascosta != ora.scrivania { self.sistema.scrivaniaNascosta = ora.scrivania }
        }
    }

    /// Istantanee e prove (stato non persistente, nessuna transizione): finestre e scrivania sotto l'ultima finestra
    /// ingrandita non si disegnano, come sul Mac a transizione finita. Così la prova di fluidità misura ciò che si
    /// vede davvero, non una scrivania al 25% nascosta sotto le finestre. La transazione è quella di chi cambia.
    fileprivate func allineaCoperteSubito() {
        let ora = copertePreviste
        if sistema.coperte != ora.finestre { sistema.coperte = ora.finestre }
        if sistema.scrivaniaNascosta != ora.scrivania { sistema.scrivaniaNascosta = ora.scrivania }
    }

    /// Le finestre visibili sotto l'ultima finestra ingrandita, e se la scrivania è coperta.
    /// Una finestra che rientra nell'icona (`rientrano`) non copre più nulla: dietro il volo si vede ciò che c'è sotto.
    fileprivate var copertePreviste: (finestre: Set<AppPrisma>, scrivania: Bool) {
        let visibili = finestreVisibili.filter { !sistema.rientrano.contains($0.app) }
        guard let i = visibili.lastIndex(where: { $0.ingrandita }) else { return ([], false) }
        return (Set(visibili[..<i].map(\.app)), true)
    }

    // MARK: - Spazi di lavoro

    /// Gli spazi pronti e quelli salvati dal consulente.
    var spaziDiLavoro: [SpazioLavoro] { SpazioLavoro.predefiniti + dati.spazi }

    /// L'area che avranno le finestre: con una finestra aperta il dock si nasconde e lo spazio cresce.
    fileprivate var areaConFinestre: CGRect {
        guard finestreVisibili.isEmpty else { return area }
        var a = area
        a.size.height += Misure.Dock.riservato - Misure.Dock.riservatoNascosto
        return a
    }

    /// Cornice di una finestra dello spazio nell'area, con un piccolo stacco tra finestre affiancate.
    fileprivate func cornice(da f: FinestraSpazio, in area: CGRect) -> CGRect {
        let r = CGRect(x: f.x * area.width, y: f.y * area.height, width: f.larghezza * area.width, height: f.altezza * area.height)
            .insetBy(dx: Misure.Spazi.stacco / 2, dy: Misure.Spazi.stacco / 2)
        return limita(CGRect(origin: r.origin, size: CGSize(width: max(r.width, Misure.Finestra.minima.width),
                                                           height: max(r.height, Misure.Finestra.minima.height))), in: area)
    }

    /// Apre lo spazio: le sue app, disposte come salvate, al posto delle finestre aperte. Le finestre che non ne
    /// fanno parte si chiudono; quelle che restano in vista vanno al loro posto (al giro dopo, FLIP); le altre si aprono.
    func apriSpazio(_ s: SpazioLavoro) {
        let area = areaConFinestre
        sistema.giroScrivania &+= 1
        // In modalità cliente le app che leggono tutti i clienti restano chiuse
        let salvate = s.finestre.filter { appConsentita($0.app) }.map { f in
            Finestra(app: f.app, cornice: cornice(da: f, in: area), ingrandita: f.ingrandita)
        }
        #if os(macOS)
        // Spazi salvati con un'app accorpata: la finestra è quella dell'ospite (una sola, la più in primo piano)
        for f in salvate where f.app.ospite != nil { preparaOspite(per: f.app) }
        let mappate: [Finestra] = salvate.map { f in
            guard let ospite = f.app.ospite else { return f }
            return Finestra(app: ospite, cornice: f.cornice, ingrandita: f.ingrandita)
        }
        let nuove = mappate.enumerated().filter { i, f in !mappate[(i + 1)...].contains { $0.app == f.app } }.map { $0.element }
        #else
        let nuove = salvate
        #endif
        // A cose fatte: le modifiche senza animazione non vanno prima di quelle animate
        defer { if s.finestre.contains(where: { $0.app == .impostazioni }) { aggiornaElencoBackup() } }
        guard persistente else {
            diColpo(implicite: false) {
                if pannelloSpazi { pannelloSpazi = false }
                finestre = nuove
                sistema.spente.removeAll()
            }
            return
        }
        let restano = Set(nuove.map(\.app))
        // Le app nuove si aprono senza punto d'origine; quelle ridotte tornano dal dock
        for app in restano where !aperta(app) { segnaVolo(app, nil) }
        let ferme = Set(finestreVisibili.map(\.app)).intersection(restano)
        guard !ferme.isEmpty else {
            // Nessuna finestra resta in vista: le vecchie si chiudono e quelle dello spazio si aprono insieme
            Movimenti.anima(Tema.Moto.Finestre.chiusura, durata: Tema.Moto.Finestre.durataChiusura) {
                if pannelloSpazi { pannelloSpazi = false }
                finestre = nuove
                sistema.inArrivo.formUnion(restano)
                if !sistema.spente.isEmpty { sistema.spente.removeAll() }
            }
            let apertura = aperturaFinestra
            Movimenti.alGiroDopo(apertura.curva, durata: apertura.durata) { [weak self] in
                self?.sistema.inArrivo.subtract(restano)
            }
            aggiornaCoperte(dopo: apertura.durata)
            return
        }
        Movimenti.anima(Tema.Moto.Finestre.chiusura, durata: Tema.Moto.Finestre.durataChiusura) {
            if pannelloSpazi { pannelloSpazi = false }
            finestre.removeAll { !restano.contains($0.app) }
            // Le finestre dello spazio tornano tutte in vista: i loro controlli si riaccendono
            if !sistema.spente.isEmpty { sistema.spente.removeAll() }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let arrivi = restano.subtracting(self.finestreVisibili.map(\.app))
            self.cambiaCornici(arrivi: arrivi) { self.finestre = nuove }
            self.aggiornaCoperte(dopo: Tema.Moto.Finestre.durataIngrandimento)
        }
    }

    /// Salva le finestre aperte come nuovo spazio (dalla più in fondo a quella in primo piano).
    @discardableResult
    func salvaSpazio(nome: String) -> SpazioLavoro? {
        let n = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty, !finestreVisibili.isEmpty, area.width > 0, area.height > 0 else { return nil }
        let elenco = finestreVisibili.map { f -> FinestraSpazio in
            guard !f.ingrandita else { return .intera(f.app) }
            // Lo stacco tra finestre affiancate si toglie qui e si rimette alla riapertura
            let c = cornice(di: f).insetBy(dx: -Misure.Spazi.stacco / 2, dy: -Misure.Spazi.stacco / 2)
            return FinestraSpazio(app: f.app, x: c.minX / area.width, y: c.minY / area.height,
                                  larghezza: c.width / area.width, altezza: c.height / area.height)
        }
        let spazio = SpazioLavoro(nome: String(n.prefix(Misure.Spazi.nomeMassimo)), finestre: elenco)
        dati.spazi.append(spazio)
        mostraAvviso("Spazio «\(spazio.nome)» salvato.")
        return spazio
    }

    func eliminaSpazio(_ id: String) {
        dati.spazi.removeAll { $0.id == id }
    }

    /// ◫ nella barra del titolo: la finestra a sinistra e quella sotto di lei a destra.
    func affianca(_ app: AppPrisma) {
        let visibili = finestreVisibili
        guard let altra = visibili.last(where: { $0.app != app }) else {
            mostraAvviso("Apri un'altra app dal dock per affiancarla a questa.")
            return
        }
        guard let i = finestre.firstIndex(where: { $0.app == app }),
              let j = finestre.firstIndex(where: { $0.app == altra.app }) else { return }
        let area = self.area
        cambiaCornici {
            finestre[i].ingrandita = false
            finestre[i].cornice = cornice(da: .sinistra(app), in: area)
            finestre[j].ingrandita = false
            finestre[j].cornice = cornice(da: .destra(altra.app), in: area)
        }
        primoPiano(app)
        aggiornaCoperte(dopo: Tema.Moto.Finestre.durataIngrandimento)
    }

    /// Sposta la finestra (al rilascio del trascinamento, senza animazione).
    func sposta(_ app: AppPrisma, origine: CGPoint) {
        guard let i = finestre.firstIndex(where: { $0.app == app }), !finestre[i].ingrandita else { return }
        var c = finestre[i].cornice
        c.origin = origine
        finestre[i].cornice = limita(c)
    }

    /// Ridimensiona la finestra (al rilascio della maniglia, senza animazione).
    func ridimensiona(_ app: AppPrisma, dimensione: CGSize) {
        guard let i = finestre.firstIndex(where: { $0.app == app }), !finestre[i].ingrandita else { return }
        var c = finestre[i].cornice
        c.size = CGSize(width: max(Misure.Finestra.minima.width, dimensione.width),
                        height: max(Misure.Finestra.minima.height, dimensione.height))
        finestre[i].cornice = limita(c)
    }

    /// Cornice effettiva da disegnare.
    func cornice(di f: Finestra) -> CGRect { cornice(di: f, in: area) }

    /// Cornice dentro un'area precisa: il disegno usa la stessa area in cui mette le finestre,
    /// così una finestra non è mai più alta del suo spazio (e la barra del titolo resta visibile).
    func cornice(di f: Finestra, in area: CGRect) -> CGRect {
        f.ingrandita ? CGRect(origin: .zero, size: area.size) : limita(f.cornice, in: area)
    }

    fileprivate func corniceIniziale() -> CGRect {
        let l = max(Misure.Finestra.minima.width, area.width * 0.72)
        let a = max(Misure.Finestra.minima.height, area.height * 0.8)
        let passo = CGFloat(finestre.count % 6) * 24
        return CGRect(x: (area.width - l) / 2 + passo, y: (area.height - a) / 3 + passo, width: l, height: a)
    }

    /// Tiene la finestra dentro l'area (la barra del titolo resta sempre raggiungibile).
    fileprivate func limita(_ c: CGRect) -> CGRect { limita(c, in: area) }

    fileprivate func limita(_ c: CGRect, in area: CGRect) -> CGRect {
        var r = c
        r.size.width = min(r.width, area.width)
        r.size.height = min(r.height, area.height)
        r.origin.x = min(max(r.minX, 0), area.width - r.width)
        r.origin.y = min(max(r.minY, 0), area.height - r.height)
        return r
    }
}
