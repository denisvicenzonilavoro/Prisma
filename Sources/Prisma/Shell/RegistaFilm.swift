import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation

// La codifica del film del piano («Luce» giro 15, §3.2.5 punto 3), senza dipendenze esterne: AVFoundation del sistema.
// MP4 H.264 profilo High, 1920×1080, 30 fotogrammi al secondo, circa 4 Mbit/s, Rec.709, niente audio, niente metadati
// (`writer.metadata = []`), indice in testa (`shouldOptimizeForNetworkUse`). Ogni fotogramma lo disegna `DisegnoFilm`
// in un pixel buffer del pool (memoria costante), su una coda propria: niente lavoro sul thread principale. L'avanzamento
// arriva **con una callback** ogni 10 fotogrammi (mai `await MainActor`: la prova blocca il thread principale con un
// semaforo; la vista lo riporta con `DispatchQueue.main.async`). Annullata: `cancelWriting()` e file tolto.

enum ErroreFilm: Error, Equatable {
    case codificatoreNonDisponibile
    case scrittura(String)
    case annullato

    var messaggio: String {
        switch self {
        case .codificatoreNonDisponibile: return TestiFilm.codificatoreNonDisponibile
        case .scrittura(let m): return TestiFilm.scrittura(m)
        case .annullato: return TestiFilm.annulla
        }
    }
}

final class RegistaFilm: @unchecked Sendable {
    static let dimensione = CGSize(width: 1920, height: 1080)
    static let fps: Int32 = 30
    static let bitrate = 4_000_000

    private let blocco = NSLock()
    private var _annullato = false

    private var annullato: Bool {
        blocco.lock(); defer { blocco.unlock() }
        return _annullato
    }

    /// Le impostazioni del codificatore: H.264 High, 1920×1080, 4 Mbit/s, Rec.709.
    static func impostazioniVideo() -> [String: Any] {
        [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(dimensione.width),
            AVVideoHeightKey: Int(dimensione.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitrate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: Int(fps),
                AVVideoMaxKeyFrameIntervalKey: Int(fps) * 2,
            ] as [String: Any],
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ] as [String: Any],
        ]
    }

    /// Ferma l'esportazione in corso (il file si toglie).
    func annulla() {
        blocco.lock(); defer { blocco.unlock() }
        _annullato = true
    }

    /// Scrive il video dei dati in `url` (un file già presente si sostituisce). `avanzamento` riceve 0…1 da una coda
    /// qualsiasi.
    func esporta(_ dati: DatiFilm, in url: URL, avanzamento: @escaping @Sendable (Double) -> Void) async throws {
        let fm = FileManager.default
        try? fm.removeItem(at: url)
        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        } catch {
            throw ErroreFilm.scrittura(error.localizedDescription)
        }
        writer.metadata = []
        writer.shouldOptimizeForNetworkUse = true
        let impostazioni = Self.impostazioniVideo()
        guard writer.canApply(outputSettings: impostazioni, forMediaType: .video) else {
            throw ErroreFilm.codificatoreNonDisponibile
        }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: impostazioni)
        input.expectsMediaDataInRealTime = false
        let larghezza = Int(Self.dimensione.width)
        let altezza = Int(Self.dimensione.height)
        let attributi: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: larghezza,
            kCVPixelBufferHeightKey as String: altezza,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        let adattatore = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributi)
        guard writer.canAdd(input) else { throw ErroreFilm.codificatoreNonDisponibile }
        writer.add(input)
        guard writer.startWriting(), writer.status != .failed else {
            writer.cancelWriting()
            try? fm.removeItem(at: url)
            throw ErroreFilm.codificatoreNonDisponibile
        }
        writer.startSession(atSourceTime: .zero)

        let totale = MotoreFilm.fotogrammi(dati)
        let fps = Self.fps
        let coda = DispatchQueue(label: "prisma.film.codifica", qos: .utility)
        let ciclo = CicloFilm()
        let esito: ErroreFilm? = await withCheckedContinuation { (fine: CheckedContinuation<ErroreFilm?, Never>) in
            input.requestMediaDataWhenReady(on: coda) { [self] in
                while input.isReadyForMoreMediaData && !ciclo.finito {
                    if self.annullato {
                        ciclo.finito = true
                        input.markAsFinished()
                        fine.resume(returning: .annullato)
                        return
                    }
                    if ciclo.indice >= totale {
                        ciclo.finito = true
                        input.markAsFinished()
                        fine.resume(returning: nil)
                        return
                    }
                    let i = ciclo.indice
                    let riuscito: Bool = autoreleasepool {
                        Self.fotogramma(i, fps: fps, dati: dati, adattatore: adattatore, larghezza: larghezza, altezza: altezza)
                    }
                    if !riuscito || writer.status == .failed {
                        ciclo.finito = true
                        input.markAsFinished()
                        // Se cade già il primo fotogramma il codificatore non c'è (macchine virtuali senza H.264)
                        let motivo = writer.error?.localizedDescription ?? "fotogramma \(i + 1) non accettato"
                        let mancante = i == 0 || Self.codificatoreMancante(writer.error)
                        fine.resume(returning: mancante ? .codificatoreNonDisponibile : .scrittura(motivo))
                        return
                    }
                    ciclo.indice += 1
                    if ciclo.indice % 10 == 0 || ciclo.indice == totale {
                        avanzamento(Double(ciclo.indice) / Double(max(1, totale)))
                    }
                }
            }
        }
        if let esito {
            writer.cancelWriting()
            try? fm.removeItem(at: url)
            throw esito
        }
        // La durata esatta (20,2 s): la sessione finisce dopo l'ultimo fotogramma
        writer.endSession(atSourceTime: CMTime(value: CMTimeValue(totale), timescale: fps))
        await withCheckedContinuation { (fatto: CheckedContinuation<Void, Never>) in
            writer.finishWriting { fatto.resume() }
        }
        guard writer.status == .completed else {
            let motivo = writer.error?.localizedDescription ?? "scrittura non completata"
            try? fm.removeItem(at: url)
            throw Self.codificatoreMancante(writer.error) ? ErroreFilm.codificatoreNonDisponibile : ErroreFilm.scrittura(motivo)
        }
        if annullato {
            try? fm.removeItem(at: url)
            throw ErroreFilm.annullato
        }
    }

    /// true se l'errore dice che il codificatore H.264 non c'è (o non è disponibile su questa macchina).
    static func codificatoreMancante(_ errore: Error?) -> Bool {
        guard let e = errore as NSError?, e.domain == AVFoundationErrorDomain else { return false }
        return [AVError.Code.encoderNotFound.rawValue, AVError.Code.encoderTemporarilyUnavailable.rawValue].contains(e.code)
    }

    /// Un fotogramma nel pixel buffer del pool: contesto sRGB BGRA capovolto (origine in alto), disegno, aggiunta.
    private static func fotogramma(_ i: Int, fps: Int32, dati: DatiFilm, adattatore: AVAssetWriterInputPixelBufferAdaptor,
                                   larghezza: Int, altezza: Int) -> Bool {
        guard let pool = adattatore.pixelBufferPool else { return false }
        var creato: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &creato) == kCVReturnSuccess, let buffer = creato else {
            return false
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        guard let base = CVPixelBufferGetBaseAddress(buffer),
              let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: base, width: larghezza, height: altezza, bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: spazio,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return false
        }
        ctx.translateBy(x: 0, y: CGFloat(altezza))
        ctx.scaleBy(x: 1, y: -1)
        DisegnoFilm.disegna(in: ctx, dimensione: CGSize(width: larghezza, height: altezza),
                            tempo: Double(i) / Double(fps), dati: dati, fermo: false)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return adattatore.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
    }

    /// Un fotogramma come immagine (1920×1080, origine in alto): per i PNG delle anteprime e le prove, senza codifica.
    static func immagine(_ dati: DatiFilm, scena: ScenaFilm, t: Double, dimensione: CGSize = RegistaFilm.dimensione) -> CGImage? {
        let w = Int(dimensione.width), h = Int(dimensione.height)
        guard let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: spazio,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else {
            return nil
        }
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
        DisegnoFilm.disegna(in: ctx, dimensione: dimensione, scena: scena, t: t, dati: dati, fermo: false)
        return ctx.makeImage()
    }
}

/// Lo stato del ciclo dei fotogrammi: lo tocca solo la coda della codifica.
private final class CicloFilm: @unchecked Sendable {
    var indice = 0
    var finito = false
}
