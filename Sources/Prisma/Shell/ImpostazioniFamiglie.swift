#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

/// Impostazioni › Rendimenti di confronto › «Famiglie italiane» (Orizzonte giro 6, specifica §10.5.3): quali tabelle
/// usa il confronto «Rispetto alle famiglie come la sua». Senza file caricato si usano le tavole pubblicate dalla
/// Banca d'Italia incluse nell'app (`Risorse/famiglie-bdi-2022.json`); si può caricare un file aggiornato. Il file
/// scelto si controlla: se non è valido restano le tabelle di prima e l'errore si legge sotto la riga, con il campo e
/// il motivo. Sul Mac il file si sceglie con NSOpenPanel, su iPhone e iPad con
/// il selettore dei file (`fileImporter`). «Usa le tavole incluse» toglie il file caricato. L'etichetta «Dati di
/// prova…» di Analisi 360 (solo con un file di prova caricato) porta qui
/// (`TestiFamiglie.ancoraImpostazioni`).
struct ImpostazioniFamiglie: View {
    @Environment(StatoShell.self) var stato
    @State private var errore: String?
    /// Su iPhone e iPad: il selettore dei file è aperto.
    @State private var sceltaFile = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let caricate = stato.dati.famiglie
        let predefinite = TabelleFamiglie.tabellePredefinite
        let diProva = caricate.map { $0.tabelle.diProva } ?? (predefinite?.diProva ?? false)
        let titolo: String = caricate.map { TestiFamiglie.titoloCaricate($0.tabelle.fonte, edizione: $0.tabelle.edizione) }
            ?? TestiFamiglie.titoloPredefinite(predefinite)
        let sottotitolo: String = caricate.map { TestiFamiglie.spiegaCaricate($0.nomeFile, il: $0.caricateIl) }
            ?? (predefinite == nil ? TestiFamiglie.senzaPredefinite : TestiFamiglie.spiegaPredefinite)
        let pillola: Pillola
        if diProva {
            pillola = Pillola(testo: TestiFamiglie.pillolaDiProva, tono: .attenzione)
        } else {
            pillola = Pillola(testo: caricate == nil ? TestiFamiglie.pillolaPredefinite : TestiFamiglie.pillolaCaricate, tono: .ok)
        }
        return GruppoImpostazioni(titolo: TestiFamiglie.gruppo) {
            RigaImpostazione(titolo: titolo, sottotitolo: sottotitolo, stato: pillola, avvertenza: errore, ultima: true) {
                HStack(spacing: Tema.Misura.Famiglie.spazioPulsanti) {
                    if caricate != nil {
                        ValoreRiga(testo: TestiFamiglie.usaPredefinite) {
                            errore = nil
                            stato.usaFamigliePredefinite()
                        }
                    }
                    ValoreRiga(testo: TestiFamiglie.carica) { scegliFile() }
                }
            }
        }
        .id(TestiFamiglie.ancoraImpostazioni)
        .fileImporter(isPresented: $sceltaFile, allowedContentTypes: [.json]) { esito in
            switch esito {
            case .success(let url): errore = stato.caricaTabelleFamiglie(da: url)
            case .failure: errore = TestiFamiglie.fileIlleggibile
            }
        }
    }

    private func scegliFile() {
        #if os(macOS)
        let pannello = NSOpenPanel()
        pannello.canChooseDirectories = false
        pannello.canChooseFiles = true
        pannello.allowsMultipleSelection = false
        pannello.allowedContentTypes = [.json]
        pannello.prompt = TestiFamiglie.pannelloPulsante
        pannello.message = TestiFamiglie.pannelloMessaggio
        if pannello.runModal() == .OK, let url = pannello.url {
            errore = stato.caricaTabelleFamiglie(da: url)
        }
        #elseif os(iOS)
        sceltaFile = true
        #endif
    }
}
