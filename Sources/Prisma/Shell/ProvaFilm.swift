import AVFoundation
import CoreMedia
import Foundation
import ImageIO

// `Prisma --prova-film [cartella]` («Luce» giro 15, §3.2.5 punto 7): il video dei dati di prova di Giulia (DATI DI PROVA
// DICHIARATI: i clienti del template, con «DATI DI PROVA» nell'angolo del video) in una cartella temporanea, riletto con
// `AVURLAsset`: durata 20,2 s ± un fotogramma (con tutte le scene), una traccia video 1920×1080 a 30 fotogrammi H.264,
// nessuna traccia audio, nessun metadato, meno di 16 MB. Con la cartella anche i cinque fotogrammi finali delle scene
// (`film-1.png`…`film-5.png`, ImageIO) per le anteprime: si disegnano con lo stesso `DisegnoFilm` del video, anche senza
// codificatore. Se sul runner manca il codificatore H.264 la prova scrive «AVVISO: …» ed esce con 0 dopo le altre
// verifiche (decisione 108: il Mac M1 dell'utente ha il codificatore hardware). Esce con 1 al primo errore vero.
@MainActor enum ProvaFilm {
    static let limiteByte = 16 * 1024 * 1024
    /// DATO DI PROVA DICHIARATO: il versamento mensile per l'obiettivo della casa di Giulia, che nei dati di prova non ne
    /// ha (senza, la scena «Ogni mese» si salterebbe). Non tondo.
    nonisolated static let versamentoDiProva = 553.0

    /// Giulia con il versamento di prova (anche le istantanee 644-648 lo usano, per avere tutte e cinque le scene).
    nonisolated static func preparaDati(_ s: StatoShell) {
        if let i = s.dati.obiettivi.firstIndex(where: { $0.clienteId == "giulia" && $0.area == .casa }),
           s.dati.obiettivi[i].versamentoMensile <= 0 {
            s.dati.obiettivi[i].versamentoMensile = versamentoDiProva
        }
    }

    static func esegui(cartella: URL?) -> Int32 {
        var errori = 0
        func verifica(_ nome: String, _ ok: Bool, _ dettaglio: String = "") {
            print("\(ok ? "OK   " : "ERRORE") \(nome)\(dettaglio.isEmpty ? "" : ": \(dettaglio)")")
            if !ok { errori += 1 }
        }

        let stato = StatoShell(persistente: false)
        preparaDati(stato)
        guard let giulia = stato.cliente("giulia") else {
            print("ERRORE cliente di prova «giulia» non trovato")
            return 1
        }
        guard let dati = stato.datiFilm(giulia) else {
            print("ERRORE niente film per i dati di prova di Giulia")
            return 1
        }
        verifica("Film di Giulia con i dati di prova segnati", dati.diProva)
        verifica("Titolo «Il piano di Giulia»", dati.titolo == "Il piano di Giulia")
        verifica("Durata = somma delle scene", abs(dati.durataTotale - dati.durate.reduce(0, +)) < 1e-9, "\(dati.durataTotale) s")
        print("     scene: \(dati.scene.map { "\($0)" }.joined(separator: ", "))")

        // I fotogrammi finali delle scene (anche senza codificatore)
        if let cartella {
            do {
                try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
                for (k, scena) in dati.scene.enumerated() {
                    let durata = dati.durate[k]
                    guard let img = RegistaFilm.immagine(dati, scena: scena, t: durata) else {
                        verifica("Fotogramma \(k + 1) disegnato", false)
                        continue
                    }
                    let url = cartella.appendingPathComponent("film-\(k + 1).png")
                    verifica("Fotogramma \(k + 1) (\(scena)) scritto", scriviPNG(img, url), url.lastPathComponent)
                }
            } catch {
                verifica("Cartella dei fotogrammi", false, error.localizedDescription)
            }
        }

        // Il video
        let temporanea = FileManager.default.temporaryDirectory.appendingPathComponent("prova-film-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporanea) }
        do {
            try FileManager.default.createDirectory(at: temporanea, withIntermediateDirectories: true)
        } catch {
            print("ERRORE cartella temporanea: \(error.localizedDescription)")
            return 1
        }
        let url = temporanea.appendingPathComponent(TestiFilm.nomeFile("Giulia"))
        let regista = RegistaFilm()
        let contatore = ContatoreAvanzamento()
        let esito: Result<Void, ErroreFilm> = aspetta {
            do {
                try await regista.esporta(dati, in: url) { f in contatore.segna(f) }
                return .success(())
            } catch let e as ErroreFilm {
                return .failure(e)
            } catch {
                return .failure(.scrittura(error.localizedDescription))
            }
        }
        switch esito {
        case .failure(.codificatoreNonDisponibile):
            print("AVVISO: codificatore H.264 non disponibile su questa macchina: il video non si è scritto (sul Mac dell'utente c'è)")
            print(errori == 0 ? "Prova del film: superata (senza video)" : "Prova del film: \(errori) errori")
            return errori == 0 ? 0 : 1
        case .failure(let e):
            verifica("Video scritto", false, e.messaggio)
            return 1
        case .success:
            verifica("Video scritto", FileManager.default.fileExists(atPath: url.path), url.lastPathComponent)
        }
        verifica("Avanzamento arrivato a 1", contatore.ultimo >= 0.999, String(format: "%.3f", contatore.ultimo))

        // Riletto con AVURLAsset (fuori dal thread principale)
        let lettura: Result<LetturaVideo, Error> = aspetta {
            do { return .success(try await leggi(url)) } catch { return .failure(error) }
        }
        switch lettura {
        case .failure(let e):
            verifica("Video riletto", false, e.localizedDescription)
        case .success(let l):
            let unFotogramma = 1.0 / Double(RegistaFilm.fps)
            verifica("Durata = \(String(format: "%.1f", dati.durataTotale)) s ± un fotogramma",
                     abs(l.durata - dati.durataTotale) <= unFotogramma + 1e-6, String(format: "%.3f s", l.durata))
            if dati.scene.count == ScenaFilm.allCases.count {
                verifica("Con tutte le scene 20,2 s", abs(l.durata - 20.2) <= unFotogramma + 1e-6)
            }
            verifica("Una traccia video", l.tracceVideo == 1, "\(l.tracceVideo)")
            verifica("1920×1080", l.misura == RegistaFilm.dimensione, "\(Int(l.misura.width))×\(Int(l.misura.height))")
            verifica("30 fotogrammi al secondo", abs(l.fotogrammiAlSecondo - 30) < 0.5, String(format: "%.2f", l.fotogrammiAlSecondo))
            verifica("Codec H.264 (avc1)", l.h264)
            verifica("Nessuna traccia audio", l.tracceAudio == 0, "\(l.tracceAudio)")
            verifica("Nessun metadato", l.metadati.isEmpty, l.metadati.joined(separator: ", "))
            verifica("Meno di 16 MB", l.byte > 0 && l.byte < limiteByte, Formati.dimensione(l.byte))
        }

        print(errori == 0 ? "Prova del film: superata" : "Prova del film: \(errori) errori")
        return errori == 0 ? 0 : 1
    }

    /// Ciò che la prova rilegge dal file.
    struct LetturaVideo: Sendable {
        let durata: Double
        let tracceVideo: Int
        let tracceAudio: Int
        let misura: CGSize
        let fotogrammiAlSecondo: Double
        let h264: Bool
        let metadati: [String]
        let byte: Int64
    }

    nonisolated private static func leggi(_ url: URL) async throws -> LetturaVideo {
        let asset = AVURLAsset(url: url)
        let durata = try await asset.load(.duration)
        let video = try await asset.loadTracks(withMediaType: .video)
        let audio = try await asset.loadTracks(withMediaType: .audio)
        let metadati = try await asset.load(.metadata)
        var misura = CGSize.zero
        var fps: Float = 0
        var h264 = false
        if let traccia = video.first {
            let (dimensione, frequenza, formati) = try await traccia.load(.naturalSize, .nominalFrameRate, .formatDescriptions)
            misura = dimensione
            fps = frequenza
            h264 = formati.contains { CMFormatDescriptionGetMediaSubType($0) == kCMVideoCodecType_H264 }
        }
        let attributi = try? FileManager.default.attributesOfItem(atPath: url.path)
        let byte = (attributi?[.size] as? NSNumber)?.int64Value ?? 0
        let nomi = metadati.map { $0.identifier?.rawValue ?? $0.commonKey?.rawValue ?? "?" }
        return LetturaVideo(durata: CMTimeGetSeconds(durata), tracceVideo: video.count, tracceAudio: audio.count, misura: misura,
                            fotogrammiAlSecondo: Double(fps), h264: h264, metadati: nomi, byte: byte)
    }

    /// Un PNG con ImageIO.
    static func scriviPNG(_ img: CGImage, _ url: URL) -> Bool {
        guard let destinazione = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return false }
        CGImageDestinationAddImage(destinazione, img, nil)
        return CGImageDestinationFinalize(destinazione)
    }

    /// Aspetta un lavoro asincrono dal thread delle prove (semaforo + `Task.detached`, mai sul MainActor: il lavoro è
    /// `@Sendable`, quindi non eredita l'isolamento della prova e non aspetta il thread principale bloccato).
    nonisolated private static func aspetta<T>(_ lavoro: @escaping @Sendable () async -> T) -> T {
        let scatola = ScatolaFilm<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

private final class ScatolaFilm<T>: @unchecked Sendable {
    var valore: T?
}

/// L'ultimo avanzamento ricevuto dal regista (da una coda qualsiasi).
private final class ContatoreAvanzamento: @unchecked Sendable {
    private let blocco = NSLock()
    private var _ultimo: Double = 0

    func segna(_ f: Double) {
        blocco.lock(); defer { blocco.unlock() }
        _ultimo = max(_ultimo, f)
    }

    var ultimo: Double {
        blocco.lock(); defer { blocco.unlock() }
        return _ultimo
    }
}
