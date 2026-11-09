#if os(macOS)
import Foundation
import IOKit.ps

// La corrente, il caldo e il risparmio energetico del Mac per il lavoro della notte («Luce» giro 14, decisione 30): la
// notte lavora solo alla corrente (se macOS non lo dice, non lavora), con il Mac non caldo e senza risparmio energetico.
// Solo letture: Prisma non cambia mai le impostazioni di energia del Mac.
enum AlimentazioneMac {
    /// Il valore di `kIOPSACPowerValue` («AC Power», IOPSKeys.h).
    static let rete = "AC Power"

    /// true alla corrente, false a batteria, nil se macOS non lo dice (allora la notte non lavora).
    static func allaCorrente() -> Bool? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let tipo = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() else { return nil }
        return (tipo as String) == rete
    }

    /// Il Mac è caldo (stato termico serio o critico).
    static var caldo: Bool {
        let t = ProcessInfo.processInfo.thermalState
        return t == .serious || t == .critical
    }

    /// Il risparmio energetico è acceso.
    static var risparmio: Bool { ProcessInfo.processInfo.isLowPowerModeEnabled }
}
#endif
