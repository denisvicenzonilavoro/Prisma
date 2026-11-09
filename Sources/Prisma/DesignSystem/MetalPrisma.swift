import Foundation
import Metal

/// Il device Metal di Prisma (acqua della scrivania, prisma di luce, tele degli shader).
///
/// Con la variabile d'ambiente `PRISMA_SENZA_METAL=1` non c'è device: tutto resta sul fermo-immagine, come nelle
/// istantanee. La imposta solo il workflow di GitHub per le prove, perché sulla GPU virtuale dei runner macOS Metal può
/// fermare il processo con un'asserzione interna («Target device architecture is nil») che il codice non può
/// intercettare. Sul Mac dell'utente la variabile non c'è e non cambia nulla.
enum MetalPrisma {
    static let spento = ProcessInfo.processInfo.environment["PRISMA_SENZA_METAL"] == "1"

    static func device() -> (any MTLDevice)? {
        spento ? nil : MTLCreateSystemDefaultDevice()
    }
}
