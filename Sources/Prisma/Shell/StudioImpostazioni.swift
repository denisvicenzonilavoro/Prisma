import SwiftUI

// Impostazioni › Studio (versione «Orizzonte», Design/template-novita-specifica.md §2.5.4 e §2.6): le aliquote
// provvigionali Alleanza per tipo di prodotto e gli obiettivi dell'anno, che Studio usa per il Cruscotto e per il
// riquadro della scrivania. Come le altre pagine del tema Apple: righe come card senza ombra, titolo e spiegazione a
// sinistra, i campi a destra.
//
// - Nessun valore predefinito: i campi nascono vuoti e un campo vuoto resta vuoto (nil). Studio allora lo dice
//   («Inserisci le tue aliquote in Impostazioni › Studio», «Imposta gli obiettivi dell'anno»), senza inventare cifre.
// - Per ogni tipo di prodotto due aliquote: la nuova produzione (alla decorrenza) e quella delle rate dal secondo anno,
//   ricorrenti per investimento, risparmio e previdenza, rinnovi per la protezione (`AliquoteProvvigione.voceSuccessiva`).
// - Gli obiettivi valgono per un anno: l'anno in corso o il prossimo (per prepararli a fine anno).
// - I valori stanno nell'archivio e nel backup (`Impostazioni.studio`) e cambiano i calcoli di Studio.
// - In fondo i dati per le fatture (`SezioneDatiFatture`, ImpostazioniFatture.swift), con la loro ancora.

struct PaginaImpostazioniStudio: View {
    @EnvironmentObject var stato: StatoShell
    /// L'anno degli obiettivi che si stanno scrivendo (l'anno in corso, o il prossimo).
    @State private var anno = Calendar.current.component(.year, from: Date())

    var body: some View {
        let annoCorrente = Calendar.current.component(.year, from: Date())
        let aree = ImpostazioniStudio.areeProvvigionali
        let senzaDecorrenza = stato.cruscottoStudio().posizioniSenzaDecorrenza
        let f = Tema.Apple.Studio.Impostazioni.self
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            NotaImpostazioni("Studio misura il tuo lavoro con i numeri che scrivi qui: Prisma non li inventa. "
                             + "Un campo vuoto resta vuoto, e Studio dice che cosa manca.")
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Le tue aliquote Alleanza") {
                    ForEach(Array(aree.enumerated()), id: \.element) { i, area in
                        let successiva = AliquoteProvvigione.voceSuccessiva(area: area)
                        RigaImpostazione(titolo: area.nome, sottotitolo: Self.spiegazione(area),
                                         aiuto: Self.aiuto(area), ultima: i == aree.count - 1) {
                            HStack(alignment: .bottom, spacing: f.spazioCampi) {
                                CampoNumeroStudio(etichetta: MotoreStudio.TipoProvvigione.nuovaProduzione.nome, unita: "%",
                                                  larghezza: f.campoPercentuale, decimali: 2,
                                                  valore: legameAliquota(area, .nuovaProduzione))
                                CampoNumeroStudio(etichetta: successiva.nome, unita: "%",
                                                  larghezza: f.campoPercentuale, decimali: 2,
                                                  valore: legameAliquota(area, successiva))
                            }
                            .disabled(stato.solaLettura)
                        }
                    }
                }
                NotaImpostazioni("Valgono per le posizioni Alleanza in essere con la data di decorrenza: la nuova produzione "
                                 + "sul versamento iniziale e sui premi del primo anno, nel mese della decorrenza; ricorrenti e "
                                 + "rinnovi su ogni rata dal secondo anno, fino alla scadenza. Le posizioni indipendenti non "
                                 + "hanno provvigioni: la consulenza entra con le parcelle.")
                if senzaDecorrenza > 0 {
                    NotaImpostazioni(senzaDecorrenza == 1
                                     ? "1 posizione Alleanza in essere non ha la data di decorrenza: non entra nelle stime."
                                     : "\(senzaDecorrenza) posizioni Alleanza in essere non hanno la data di decorrenza: non entrano nelle stime.",
                                     colore: Tema.Apple.Impostazioni.Riga.coloreAvvertenza)
                }
            }
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Gli obiettivi dell’anno") {
                    RigaImpostazione(titolo: "Anno", sottotitolo: "Gli obiettivi valgono per un anno solo") {
                        SegmentatoPillola(selezione: $anno,
                                          voci: [(annoCorrente, String(annoCorrente)), (annoCorrente + 1, String(annoCorrente + 1))])
                            .fixedSize()
                    }
                    RigaImpostazione(titolo: VoceObiettivoStudio.produzioneAlleanza.nome,
                                     sottotitolo: "Versamenti iniziali e premi annui delle posizioni Alleanza con decorrenza nell’anno",
                                     aiuto: "Definizione provvisoria della produzione, da confermare: versamento iniziale più premio annuo delle posizioni Alleanza in essere che decorrono nell’anno.") {
                        CampoNumeroStudio(etichetta: nil, unita: "€", larghezza: f.campoImporto, decimali: 0,
                                          valore: legameObiettivo(.produzioneAlleanza))
                            .disabled(stato.solaLettura)
                    }
                    RigaImpostazione(titolo: VoceObiettivoStudio.nuoviClienti.nome,
                                     sottotitolo: "Clienti inseriti in Prisma nell’anno",
                                     aiuto: "Si contano dalla data in cui il cliente è stato inserito in Prisma.") {
                        CampoNumeroStudio(etichetta: nil, unita: "clienti", larghezza: f.campoNumero, decimali: 0,
                                          valore: legameObiettivo(.nuoviClienti))
                            .disabled(stato.solaLettura)
                    }
                    RigaImpostazione(titolo: VoceObiettivoStudio.ricaviConsulenza.nome,
                                     sottotitolo: "Parcelle della consulenza indipendente dell’anno",
                                     ultima: true) {
                        CampoNumeroStudio(etichetta: nil, unita: "€", larghezza: f.campoImporto, decimali: 0,
                                          valore: legameObiettivo(.ricaviConsulenza))
                            .disabled(stato.solaLettura)
                    }
                }
                NotaImpostazioni("Un obiettivo vuoto non disegna il suo anello. Quanto hai fatto lo calcola Prisma dai tuoi dati.")
            }
            // I dati fiscali per le parcelle e il file XML della fattura (giro 2, ImpostazioniFatture.swift)
            SezioneDatiFatture()
                .id(SezioneDatiFatture.ancora)
        }
    }

    // MARK: Legami

    /// Il valore di un'aliquota: vuoto = nil (non inserita).
    private func legameAliquota(_ area: AreaPosizione, _ tipo: MotoreStudio.TipoProvvigione) -> Binding<Double?> {
        let stato = self.stato
        let attuale: Double? = {
            let a = stato.dati.impostazioni.studio.aliquote[area]
            switch tipo {
            case .nuovaProduzione: return a?.nuovaProduzione
            case .ricorrente: return a?.ricorrenti
            case .rinnovo: return a?.rinnovi
            }
        }()
        return Binding<Double?>(get: { attuale }, set: { nuovo in stato.impostaAliquotaStudio(area, tipo, nuovo) })
    }

    /// Il valore di un obiettivo dell'anno scelto: vuoto = nil (non impostato).
    private func legameObiettivo(_ voce: VoceObiettivoStudio) -> Binding<Double?> {
        let stato = self.stato
        let anno = self.anno
        let o = stato.dati.impostazioni.studio.obiettivi[anno]
        let attuale: Double?
        switch voce {
        case .produzioneAlleanza: attuale = o?.produzioneAlleanza
        case .nuoviClienti: attuale = o?.nuoviClienti.map { Double($0) }
        case .ricaviConsulenza: attuale = o?.ricaviConsulenza
        }
        return Binding<Double?>(get: { attuale }, set: { nuovo in stato.impostaObiettivoStudio(anno: anno, voce, nuovo) })
    }

    // MARK: Testi

    private static func spiegazione(_ area: AreaPosizione) -> String {
        area == .protezione
            ? "Nuova produzione sui premi del primo anno · rinnovi su ogni rata dal secondo"
            : "Nuova produzione sul versamento e sul primo anno · ricorrenti su ogni rata dal secondo"
    }

    private static func aiuto(_ area: AreaPosizione) -> String {
        "Le percentuali che Alleanza ti riconosce sui prodotti di \(area.nome.lowercased()). Vuote: Studio non stima "
            + "le provvigioni di questo tipo e lo dice."
    }
}

/// Un campo numerico della pagina: etichetta facoltativa sopra, il valore (vuoto = nil) e l'unità accanto.
private struct CampoNumeroStudio: View {
    let etichetta: String?
    let unita: String
    let larghezza: CGFloat
    let decimali: Int
    @Binding var valore: Double?

    var body: some View {
        let f = Tema.Apple.Studio.Impostazioni.self
        VStack(alignment: .trailing, spacing: f.spazioEtichetta) {
            if let etichetta {
                Text(etichetta)
                    .carattereApple(f.etichettaCampo)
                    .foregroundColor(f.coloreEtichettaCampo)
                    .lineLimit(1)
            }
            HStack(spacing: f.spazioUnita) {
                TextField("", value: $valore, format: formato, prompt: Text(verbatim: "—"))
                    .campoTesto()
                    .multilineTextAlignment(.trailing)
                    .frame(width: larghezza)
                Text(unita)
                    .carattereApple(f.unita)
                    .foregroundColor(f.coloreUnita)
                    .lineLimit(1)
            }
        }
    }

    /// Cifre all'italiana (punto delle migliaia, virgola dei decimali).
    private var formato: FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>.number.locale(Formati.localeImporti).precision(.fractionLength(0...max(0, decimali)))
    }
}
