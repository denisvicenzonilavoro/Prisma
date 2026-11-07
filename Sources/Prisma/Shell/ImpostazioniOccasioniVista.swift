import SwiftUI

/// Impostazioni › Promemoria e occasioni › Occasioni: lo strato nel calendario, l'anticipo di notifiche e
/// promemoria, i gruppi di tipi accesi e le età limite di TCM e LTC. Si salva con le altre impostazioni e vale
/// subito. AppImpostazioni la mette sotto i promemoria, con `.id("impostazioni-occasioni")`.
struct GruppoOccasioniImpostazioni: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        let m = Misure.Occasioni.self
        GruppoImpostazioni(titolo: "Occasioni") {
            RigaImpostazione(titolo: "Nel calendario", sottotitolo: "Settimana e mese dell'Agenda",
                             aiuto: "Le date in cui cambia qualcosa nella settimana e nel mese dell'Agenda; la vista «Occasioni» c'è sempre") {
                Toggle("", isOn: $stato.dati.impostazioni.occasioni.inAgenda)
                    .toggleStyle(StileInterruttore())
                    .labelsHidden()
            }
            RigaImpostazione(titolo: "Anticipo", sottotitolo: "Notifiche e promemoria del Mac") {
                MenuTendina(selezione: $stato.dati.impostazioni.occasioni.anticipoGiorni,
                            opzioni: ImpostazioniOccasioni.anticipi.map { ($0, "\($0) giorni prima") },
                            larghezza: m.menuImpostazioni)
            }
            rigaGruppo(.contratti, "Contratti", "Riscatto, penali, KID, gestione separata",
                       "Fine del blocco di riscatto, penali finite, periodo del KID, ricorrenza della gestione separata")
            rigaGruppo(.previdenza, "Previdenza", "Anticipazioni, aliquota, pensione",
                       "8 anni per le anticipazioni, aliquota che scende, 5 anni alla pensione")
            rigaGruppo(.famiglia, "Famiglia", "Figli maggiorenni, fine del carico", nil)
            rigaGruppo(.protezione, "Protezione", "Debito residuo, ultimi anni TCM e LTC",
                       "Caso morte sotto il debito residuo, ultimi anni per TCM e LTC")
            rigaGruppo(.fisco, "Fisco", "Deduzioni, detrazioni, bollo",
                       "Deduzioni entro il 31 dicembre, contributi non dedotti, detrazioni dei premi e bollo")
            // Due menu, ognuno con la sua etichetta sopra: una piccola griglia
            RigaImpostazione(titolo: "Età limite delle coperture", sottotitolo: "Controlla quelle del prodotto",
                             aiuto: "Oltre queste età di solito non si sottoscrivono: controlla quelle del prodotto",
                             ultima: true) {
                HStack(alignment: .bottom, spacing: Tema.Misura.Impostazioni.spazioGriglia) {
                    eta("TCM", $stato.dati.impostazioni.occasioni.etaLimiteTCM)
                    eta("LTC", $stato.dati.impostazioni.occasioni.etaLimiteLTC)
                }
            }
        }
    }

    /// Un interruttore per gruppo di tipi: acceso se almeno un tipo del gruppo è acceso.
    private func rigaGruppo(_ g: GruppoOccasione, _ titolo: String, _ sottotitolo: String, _ aiuto: String?) -> some View {
        RigaImpostazione(titolo: titolo, sottotitolo: sottotitolo, aiuto: aiuto) {
            Toggle("", isOn: Binding(get: { stato.dati.impostazioni.occasioni.attivo(g) },
                                     set: { stato.dati.impostazioni.occasioni.imposta(g, attivo: $0) }))
                .toggleStyle(StileInterruttore())
                .labelsHidden()
        }
    }

    /// Etichetta sopra il suo menu (TCM, LTC).
    private func eta(_ testo: String, _ valore: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Tema.Misura.Impostazioni.spazioEtichettaGriglia) {
            Text(testo)
                .font(Tema.Testo.secondario)
                .foregroundColor(Tema.Colore.inchiostroSecondario)
            MenuTendina(selezione: valore,
                        opzioni: ImpostazioniOccasioni.etaLimiti.map { ($0, "\($0) anni") },
                        larghezza: Misure.Occasioni.menuEta)
        }
    }
}
