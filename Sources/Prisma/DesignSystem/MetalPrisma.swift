import Foundation
import Metal
import SwiftUI

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

extension ImageRenderer {
    /// L'immagine della vista. Di solito `cgImage`; con `PRISMA_SENZA_METAL=1` (le prove sul runner) la stessa vista si
    /// disegna con CoreGraphics in una bitmap (`render`, la strada dei PDF), perché `cgImage` passa da Metal e la GPU
    /// virtuale del runner ferma il processo.
    var immaginePrisma: CGImage? {
        guard MetalPrisma.spento else { return cgImage }
        let fattore = scale
        var risultato: CGImage?
        render(rasterizationScale: fattore) { misura, disegna in
            let w = Int((misura.width * fattore).rounded()), h = Int((misura.height * fattore).rounded())
            guard w > 0, h > 0,
                  let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return }
            ctx.scaleBy(x: fattore, y: fattore)
            disegna(ctx)
            risultato = ctx.makeImage()
        }
        return risultato
    }
}
