import SwiftUI

// «Riduci movimento» per il tema Apple (Design/template-apple-specifica.md §2.0).
// `\.prismaCalmo` è vero con «Riduci movimento» del sistema (Mac, iPhone, iPad) OPPURE con la scelta
// di Prisma (Impostazioni › Aspetto › «Riduci movimento», salvata nell'archivio: la radice delle viste la passa con
// `.prismaCalmo(_:)`, ShellView sul Mac e RadiceMobile su iPhone e iPad; `Movimenti.calmo` la legge fuori dalle viste).
// Calmo: tutto compare già nello stato finale, al più con una dissolvenza di 0,15 s; molle senza superamento;
// niente inclinazioni, riflessi, sollevamenti, cascate né ingrandimento del dock.
// Istantanee (`\.modoIstantanea`): stato finale a riposo, senza nessuna animazione.

private struct ChiaveCalmoPrisma: EnvironmentKey {
    static let defaultValue = false
}

private struct ChiaveStatoFinaleSchermo: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// true con «Riduci movimento» del sistema o con la scelta di Prisma.
    /// Impostarlo cambia solo la scelta di Prisma: `false` non spegne «Riduci movimento» del sistema.
    var prismaCalmo: Bool {
        get { self[ChiaveCalmoPrisma.self] || accessibilityReduceMotion }
        set { self[ChiaveCalmoPrisma.self] = newValue }
    }

    /// true quando un componente animato deve disegnarsi subito nello stato finale (calmo o istantanea).
    var prismaStatoFinale: Bool {
        prismaCalmo || modoIstantanea || istantaneaSchermo
    }

    /// true nelle istantanee (del Mac o dello schermo di iPhone e iPad), che non cambiano mai durante la vita di una
    /// vista: lì lo stato finale è per sempre, quindi un componente non ha bisogno di scriverlo nel suo `@State` alla
    /// comparsa (ogni scrittura rifà la vista una seconda volta, nelle istantanee e nella prova di fluidità).
    /// Con «Riduci movimento» invece la scrittura resta: la scelta può cambiare mentre la vista è in schermo.
    var prismaScatto: Bool {
        modoIstantanea || istantaneaSchermo
    }

    /// true nelle istantanee di iPhone e iPad (`IstantaneeMobile`): lo scatto è dello schermo vero, con il vetro e
    /// i materiali di iOS (niente `modoIstantanea`), ma ogni componente del tema Apple è già nello stato finale:
    /// numeri completi, anelli pieni, linee tracciate, cascate concluse.
    var istantaneaSchermo: Bool {
        get { self[ChiaveStatoFinaleSchermo.self] }
        set { self[ChiaveStatoFinaleSchermo.self] = newValue }
    }
}

extension View {
    /// Imposta la scelta «Riduci movimento» di Prisma per questa vista e le sue figlie
    /// (si somma a quella del sistema).
    func prismaCalmo(_ calmo: Bool) -> some View {
        environment(\.prismaCalmo, calmo)
    }
}

extension Tema.Apple.Moto {
    /// Durata della dissolvenza calma (la stessa di `Tema.Moto.dissolvenzaCalma`).
    static let durataCalma = 0.15

    /// L'animazione data, oppure la dissolvenza breve di 0,15 s quando `calmo`.
    static func animazione(_ a: Animation, calmo: Bool) -> Animation {
        calmo ? Tema.Moto.dissolvenzaCalma : a
    }

    /// Come `animazione(_:calmo:)`, ma nil nelle istantanee (il cambiamento avviene di colpo).
    static func animazione(_ a: Animation, calmo: Bool, istantanea: Bool) -> Animation? {
        istantanea ? nil : animazione(a, calmo: calmo)
    }

    /// Una molla di ripiego, o la dissolvenza calma.
    static func animazione(_ m: Molla, calmo: Bool) -> Animation {
        animazione(m.animazione, calmo: calmo)
    }

    /// Il ritardo dato, o 0 con calma e nelle istantanee (niente cascate).
    static func ritardo(_ r: Double, calmo: Bool, istantanea: Bool = false) -> Double {
        (calmo || istantanea) ? 0 : r
    }

    /// true se il componente va disegnato subito nello stato finale (numeri completi, anelli pieni,
    /// linee tracciate, cascate concluse).
    static func statoFinale(calmo: Bool, istantanea: Bool) -> Bool {
        calmo || istantanea
    }
}
