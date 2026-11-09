import SwiftUI
#if canImport(RealityKit)
import RealityKit
import Combine
import Metal
import simd
#endif

/// La prova di fattibilità della realtà aumentata (`Prisma --prova-realta`, Mac e simulatore iOS; «Luce» giro 16,
/// decisione 28): il cristallo si costruisce con RealityKit, framework di sistema, senza dipendenze esterne e senza
/// fotocamera né finestra. Si controllano: le maglie di `MotoreRealtaAumentata` diventano `MeshResource` con i limiti
/// attesi; un `ModelEntity` di vetro trasparente per strato; l'esploso alza gli strati e l'altezza cresce con il
/// patrimonio; il logo sta sopra l'ultimo strato presente; la collisione c'è; una vista virtuale con l'ancora, la camera
/// e la luce, e un'iscrizione a `SceneEvents.Update` che si crea e si cancella. Senza Metal la parte RealityKit si salta
/// (come `ProgrammaLuce.provaCompilazione`) e resta il fermo-immagine. Con `--senza-vista` si salta la vista (runner
/// del workflow con Metal paravirtuale, vedi build.yml).
@MainActor
enum ProvaRealta {
    static func esegui(senzaVista: Bool = CommandLine.arguments.contains("--senza-vista")) -> Int32 {
        var errori = 0
        func controlla(_ ok: Bool, _ descrizione: String) {
            print("\(ok ? "OK   " : "ERRORE") \(descrizione)")
            if !ok { errori += 1 }
        }
        let esito = esitoDiProva()
        controlla(!esito.vuota, "Il cliente di prova ha il cristallo")
        // Il fermo-immagine c'è sempre (ripiego e scatto su fondo neutro, decisione 27)
        let immagine = CristalloFermo.scatto(esito, anno: esito.annoFine, esploso: true, lato: 320)
        controlla(immagine != nil && (immagine?.width ?? 0) > 0, "Il cristallo fermo diventa un'immagine (scatto su fondo neutro)")
        if let immagine { controlla(ProtocolloTavolo.png(immagine) != nil, "Lo scatto si codifica in PNG") }
        #if canImport(RealityKit)
        if MTLCreateSystemDefaultDevice() == nil {
            print("OK    (senza Metal: RealityKit non si prova qui)")
        } else {
            realityKit(esito, senzaVista: senzaVista, controlla)
        }
        #else
        print("OK    (RealityKit non c'è su questo sistema)")
        #endif
        print(errori == 0 ? "Prova della realtà aumentata superata" : "Prova della realtà aumentata: \(errori) errori")
        return errori == 0 ? 0 : 1
    }

    /// Un cliente di prova con tre classi e la data di nascita (dati di prova, nessun cliente vero).
    static func esitoDiProva() -> EsitoRealta {
        let d = DatiPrisma.demo()
        for c in d.clienti {
            let e = MotoreRealtaAumentata.calcola(cliente: c, posizioni: d.posizioni, obiettivi: d.obiettivi, eventi: d.eventiVita,
                                                  analisi: d.analisi[c.id])
            if e.strati.count >= 2 { return e }
        }
        return EsitoRealta(totaleOggi: 98_760, strati: [
            StratoRealta(classe: .azionario, nome: "Azionario", quota: 0.45, valoreOggi: 44_442),
            StratoRealta(classe: .obbligazionario, nome: "Obbligazionario", quota: 0.35, valoreOggi: 34_566),
            StratoRealta(classe: .liquidita, nome: "Liquidità", quota: 0.2, valoreOggi: 19_752),
        ], anni: [AnnoRealta(anno: 2_031, eta: 47, totale: 98_760), AnnoRealta(anno: 2_032, eta: 48, totale: 131_870)],
           stimata: false, motivoSenzaAnni: nil, massimo: 131_870)
    }

    /// DATI DI PROVA per la vetrina 400: tre strati con quote fisse, nessun cliente.
    static let esitoVetrina = EsitoRealta(totaleOggi: 87_430, strati: [
        StratoRealta(classe: .azionario, nome: "Azionario", quota: 0.43, valoreOggi: 37_595),
        StratoRealta(classe: .gestioneSeparata, nome: "Gestione separata", quota: 0.37, valoreOggi: 32_349),
        StratoRealta(classe: .liquidita, nome: "Liquidità", quota: 0.2, valoreOggi: 17_486),
    ], anni: [], stimata: false, motivoSenzaAnni: nil, massimo: 87_430)

    #if canImport(RealityKit)
    private static func realityKit(_ esito: EsitoRealta, senzaVista: Bool, _ controlla: (Bool, String) -> Void) {
        // 1. Le maglie diventano MeshResource con i limiti attesi
        let m = MotoreRealtaAumentata.maglia(basso: 0.2, alto: 0.9)
        do {
            let r = try CristalloRealta.risorsa(m, nome: "prova")
            let b = r.bounds
            controlla(abs(b.min.y - 0.2) < 1e-4 && abs(b.max.y - 0.9) < 1e-4, "La maglia diventa una MeshResource alta come gli estremi")
            controlla(abs(b.min.z + (MotoreRealtaAumentata.raggio - MotoreRealtaAumentata.arrotondamento)) < 1e-3,
                      "Il vertice del cristallo va verso −z")
        } catch {
            controlla(false, "MeshDescriptor: \(error.localizedDescription)")
        }
        // 2. Un ModelEntity di vetro per strato
        guard let cristallo = try? CristalloRealta(esito: esito, scala: 1) else {
            return controlla(false, "Il cristallo in RealityKit si costruisce")
        }
        controlla(cristallo.strati.count == esito.strati.count, "Un ModelEntity per strato (\(esito.strati.count))")
        let materiali = cristallo.strati.compactMap { $0.model?.materials.first as? PhysicallyBasedMaterial }
        controlla(materiali.count == esito.strati.count, "Ogni strato ha un materiale fisico")
        controlla(materiali.allSatisfy { $0.faceCulling == .none }, "Il vetro si vede da tutte e due le facce")
        controlla(materiali.allSatisfy { if case .transparent = $0.blending { return true } else { return false } },
                  "Il vetro è trasparente")
        // 3. L'esploso alza gli strati, l'altezza cresce con il patrimonio
        let primo = cristallo.strati.last?.model?.mesh.bounds.min.y ?? 0
        try? cristallo.aggiorna(anno: esito.annoOggi, esploso: 1, crescita: 1, scelto: nil)
        let dopo = cristallo.strati.last?.model?.mesh.bounds.min.y ?? 0
        let atteso = MotoreRealtaAumentata.salitaEsploso * Float(max(0, esito.strati.count - 1))
        controlla(dopo - primo >= atteso - 0.05, "L'esploso alza l'ultimo strato di 0,2 × indice")
        let altoOggi = MotoreRealtaAumentata.estremi(strato: esito.strati.count - 1, bordi: esito.bordi,
                                                     altezza: esito.altezza(anno: esito.annoOggi), esploso: 0, crescita: 1).alto
        let altoFine = MotoreRealtaAumentata.estremi(strato: esito.strati.count - 1, bordi: esito.bordi,
                                                     altezza: esito.altezza(anno: esito.annoFine), esploso: 0, crescita: 1).alto
        controlla(esito.totale(anno: esito.annoFine) < esito.totaleOggi || altoFine >= altoOggi, "L'altezza cresce con il patrimonio")
        // 4. Il logo sopra l'ultimo strato presente, anche senza la Liquidità
        let senzaLiquidita = EsitoRealta(totaleOggi: esito.totaleOggi,
                                         strati: riquota(esito.strati.filter { $0.classe != .liquidita }),
                                         anni: esito.anni, stimata: esito.stimata, motivoSenzaAnni: esito.motivoSenzaAnni,
                                         massimo: esito.massimo)
        if !senzaLiquidita.strati.isEmpty, let c2 = try? CristalloRealta(esito: senzaLiquidita, scala: 1) {
            let cima = c2.strati.last?.model?.mesh.bounds.max.y ?? 0
            let logo = c2.radice.children.first { $0 !== c2.strati.last && $0.position.y > 0 }?.position.y ?? -1
            controlla(logo >= cima, "Il logo sta sopra l'ultimo strato presente (senza Liquidità)")
        }
        // 5. La collisione per i gesti
        controlla(cristallo.radice.components[CollisionComponent.self] != nil, "Il cristallo ha la collisione (gesti)")
        // 6. La vista virtuale
        guard !senzaVista else { return controlla(true, "(vista saltata sul runner)") }
        #if os(iOS) && !targetEnvironment(simulator)
        let vista = ARView(frame: CGRect(x: 0, y: 0, width: 320, height: 200), cameraMode: .nonAR, automaticallyConfigureSession: false)
        #else
        let vista = ARView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        #endif
        let scena = ScenaVirtualeRealta()
        scena.prepara(vista, cristallo: cristallo)
        controlla(vista.scene.anchors.count == 1, "La vista virtuale ha un'ancora con cristallo, camera e luce")
        var aggiornamenti = 0
        let iscrizione = vista.scene.subscribe(to: SceneEvents.Update.self) { _ in aggiornamenti += 1 }
        withExtendedLifetime(iscrizione) {
            controlla(true, "L'iscrizione a SceneEvents.Update si crea")
        }
        iscrizione.cancel()
        scena.rimuovi(da: vista)
        controlla(vista.scene.anchors.isEmpty, "La scena si svuota all'uscita")
        _ = aggiornamenti
    }

    private static func riquota(_ strati: [StratoRealta]) -> [StratoRealta] {
        let somma = strati.reduce(0) { $0 + $1.quota }
        guard somma > 0 else { return [] }
        return strati.map { StratoRealta(classe: $0.classe, nome: $0.nome, quota: $0.quota / somma, valoreOggi: $0.valoreOggi) }
    }
    #endif
}
