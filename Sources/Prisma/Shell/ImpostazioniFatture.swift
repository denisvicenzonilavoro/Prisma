import SwiftUI

// Impostazioni › Studio › Dati per le fatture (Design/template-novita-specifica.md §3.6.1 e §6.3): i dati fiscali del
// consulente che servono alla fattura su carta e al file XML del tracciato FatturaPA (`Impostazioni.studio.fatturazione`).
// Come le altre pagine del tema Apple: righe come card senza ombra, titolo e spiegazione a sinistra, il campo a destra.
//
// - NESSUN VALORE PREDEFINITO: i campi nascono vuoti, i codici del tracciato (RF, N, TC, RT, MP, TP) si scelgono da un
//   elenco con la descrizione ufficiale e partono da «Da scegliere»; contributo, ritenuta e bollo partono da «Da
//   indicare» (né sì né no). Prisma non sceglie il regime fiscale e non mette aliquote: li scrive il consulente, con il
//   suo commercialista. Finché manca qualcosa, in cima c'è l'elenco di ciò che manca e la fattura XML non si prepara.
// - Prisma prepara il file e non lo invia: nessun collegamento al Sistema di Interscambio.
// - I campi del contributo, della ritenuta e del bollo compaiono quando si sceglie «Sì».

struct SezioneDatiFatture: View {
    @Environment(StatoShell.self) var stato

    /// L'ancora della sezione (`StatoShell.apriImpostazioniFatture`).
    static var ancora: String { TestiParcelle.ancoraImpostazioni }

    private typealias I = Tema.Apple.Parcelle.Impostazioni

    var body: some View {
        let _ = ContaCorpi.segna()
        let f = stato.datiFatturazione
        let mancanti = MotoreFattura.mancantiConsulente(f)
        let anno = Calendar.current.component(.year, from: Date())
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Pagina.spazioGruppi) {
            VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
                GruppoImpostazioni(titolo: "Dati per le fatture") {
                    RigaImpostazione(titolo: "Prisma prepara il file, non lo invia",
                                     sottotitolo: "Il PDF e il file XML della fattura elettronica (tracciato FatturaPA): il file lo carichi tu sul portale «Fatture e Corrispettivi» o lo dai al commercialista",
                                     stato: mancanti.isEmpty ? Pillola(testo: "Dati completi", tono: .ok)
                                                             : Pillola(testo: "Da completare", tono: .attenzione),
                                     avvertenza: mancanti.isEmpty ? nil
                                                                  : "Per il file XML mancano: " + TestiParcelle.elenco(mancanti, massimo: 8)) {
                        EmptyView()
                    }
                }
                if mancanti.isEmpty {
                    NotaImpostazioni("Ci sono tutti i dati per il file XML. Le voci fiscali seguono il regime che hai scritto qui.")
                }
                NotaImpostazioni("Prisma non sceglie il regime fiscale e non mette aliquote, contributi, ritenute o bolli: "
                                 + "scrivi i tuoi, con il tuo commercialista. Un campo vuoto resta vuoto.")
            }
            gruppoAnagrafica
            gruppoSede
            gruppoRegime(f)
            gruppoCassa(f)
            gruppoRitenuta(f)
            gruppoBollo(f)
            gruppoPagamento
            gruppoNumerazione(f, anno: anno)
            gruppoTrasmittente(f)
        }
        .disabled(stato.solaLettura)
    }

    // MARK: Gruppi

    private var gruppoAnagrafica: some View {
        GruppoImpostazioni(titolo: "Chi emette la fattura") {
            riga("Nome", "Come va in fattura") { testo(\.nome, larghezza: I.campoMedio) }
            riga("Cognome") { testo(\.cognome, larghezza: I.campoMedio) }
            riga("Denominazione", "In alternativa a nome e cognome, per esempio uno studio associato") {
                testo(\.denominazione, larghezza: I.campoLungo)
            }
            riga("Partita IVA", "11 cifre") { testo(\.partitaIVA, larghezza: I.campoMedio) }
            riga("Codice fiscale") { testo(\.codiceFiscale, larghezza: I.campoMedio) }
            riga("Email", "Facoltativa, sulla fattura") { testo(\.email, larghezza: I.campoLungo) }
            riga("Telefono", "Facoltativo, sulla fattura") { testo(\.telefono, larghezza: I.campoMedio) }
            riga("PEC", "Facoltativa") { testo(\.pec, larghezza: I.campoLungo) }
        }
    }

    private var gruppoSede: some View {
        GruppoImpostazioni(titolo: "Sede") {
            riga("Indirizzo") { testo(\.sede.indirizzo, larghezza: I.campoLungo) }
            riga("Numero civico") { testo(\.sede.numeroCivico, larghezza: I.campoCorto) }
            riga("CAP", "5 cifre") { testo(\.sede.cap, larghezza: I.campoCorto) }
            riga("Comune") { testo(\.sede.comune, larghezza: I.campoMedio) }
            riga("Provincia", "Sigla di 2 lettere") { testo(\.sede.provincia, larghezza: I.campoCorto) }
            riga("Nazione", "Sigla di 2 lettere, per esempio IT") { testo(\.sede.nazione, larghezza: I.campoCorto) }
        }
    }

    private func gruppoRegime(_ f: DatiFatturazione) -> some View {
        GruppoImpostazioni(titolo: "Regime fiscale e IVA") {
            riga("Regime fiscale", "Il codice RF del tracciato") {
                MenuTendina(selezione: legame(\.regime.regimeFiscale),
                            opzioni: Self.scelte(CodiceRegimeFiscale.allCases) { $0.etichetta }, larghezza: I.menu)
            }
            riga("Aliquota IVA", "Oppure la natura dell’operazione, non tutte e due") {
                numero(\.regime.aliquotaIVA, unita: "%", larghezza: I.campoCorto)
            }
            riga("Natura dell’operazione", "Il codice N quando l’IVA non c’è") {
                MenuTendina(selezione: legame(\.regime.natura),
                            opzioni: Self.scelte(NaturaIVA.allCases) { $0.etichetta }, larghezza: I.menu)
            }
            if f.regime.natura != nil {
                riga("Riferimento normativo", "Obbligatorio con la natura: il testo lo scrivi tu") {
                    testo(\.regime.riferimentoNormativo, larghezza: I.campoLungo)
                }
            }
            riga("Esigibilità dell’IVA", "Facoltativa") {
                MenuTendina(selezione: legame(\.regime.esigibilitaIVA),
                            opzioni: Self.scelte(EsigibilitaIVA.allCases) { "\($0.rawValue) · \($0.descrizione)" },
                            larghezza: I.menu)
            }
            riga("Dicitura sulla fattura", "Facoltativa: il testo esatto lo dai tu o il commercialista") {
                // Come gli altri testi: passa all'archivio poco dopo l'ultimo tasto
                TestoRinviato(testo: legame(\.regime.frasePiede), salvaOra: { stato.salvaOra() }) { bozza in
                    TextField("", text: bozza, axis: .vertical)
                        .lineLimit(I.righeDicitura)
                        .campoTesto()
                        .frame(width: I.campoLungo)
                }
            }
        }
    }

    private func gruppoCassa(_ f: DatiFatturazione) -> some View {
        GruppoImpostazioni(titolo: "Contributo previdenziale") {
            riga("Si applica", "Rivalsa o contributo integrativo della tua cassa") {
                MenuTendina(selezione: legame(\.regime.applicaCassa), opzioni: Self.siNo, larghezza: I.menuBreve)
            }
            if f.regime.applicaCassa == true {
                riga("Tipo di cassa", "Il codice TC del tracciato") {
                    MenuTendina(selezione: legame(\.regime.cassa.tipo),
                                opzioni: Self.scelte(TipoCassa.allCases) { $0.etichetta }, larghezza: I.menu)
                }
                riga("Aliquota del contributo", "Sull’imponibile delle righe") {
                    numero(\.regime.cassa.aliquota, unita: "%", larghezza: I.campoCorto)
                }
                riga("Soggetto a ritenuta") {
                    MenuTendina(selezione: legame(\.regime.cassa.soggettoARitenuta), opzioni: Self.siNo, larghezza: I.menuBreve)
                }
            }
        }
    }

    private func gruppoRitenuta(_ f: DatiFatturazione) -> some View {
        GruppoImpostazioni(titolo: "Ritenuta d’acconto") {
            riga("Si applica", "Dipende anche dal cliente: privato o sostituto d’imposta") {
                MenuTendina(selezione: legame(\.regime.applicaRitenuta), opzioni: Self.siNo, larghezza: I.menuBreve)
            }
            if f.regime.applicaRitenuta == true {
                riga("Tipo di ritenuta", "Il codice RT del tracciato") {
                    MenuTendina(selezione: legame(\.regime.ritenuta.tipo),
                                opzioni: Self.scelte(TipoRitenuta.allCases) { $0.etichetta }, larghezza: I.menu)
                }
                riga("Aliquota della ritenuta") {
                    numero(\.regime.ritenuta.aliquota, unita: "%", larghezza: I.campoCorto)
                }
                riga("Causale di pagamento", "Il codice della CU (per esempio una lettera)") {
                    testo(\.regime.ritenuta.causale, larghezza: I.campoCorto)
                }
                riga("Quota dell’imponibile", "Facoltativa: vuota, la ritenuta è su tutto l’imponibile") {
                    numero(\.regime.ritenuta.quotaImponibile, unita: "%", larghezza: I.campoCorto)
                }
            }
        }
    }

    private func gruppoBollo(_ f: DatiFatturazione) -> some View {
        GruppoImpostazioni(titolo: "Imposta di bollo") {
            riga("Si applica", "Bollo virtuale sulle fatture") {
                MenuTendina(selezione: legame(\.regime.applicaBollo), opzioni: Self.siNo, larghezza: I.menuBreve)
            }
            if f.regime.applicaBollo == true {
                riga("Importo del bollo") {
                    numero(\.regime.bollo.importo, unita: "€", larghezza: I.campoCorto)
                }
                riga("Soglia", "Facoltativa: il bollo è dovuto quando l’imponibile senza IVA la supera") {
                    numero(\.regime.bollo.soglia, unita: "€", larghezza: I.campoCorto)
                }
                riga("A carico del cliente", "Una riga in fattura e nel totale") {
                    MenuTendina(selezione: legame(\.regime.bollo.aCaricoCliente), opzioni: Self.siNo, larghezza: I.menuBreve)
                }
                if f.regime.bollo.aCaricoCliente == true {
                    riga("Natura della riga del bollo") {
                        MenuTendina(selezione: legame(\.regime.bollo.naturaRiga),
                                    opzioni: Self.scelte(NaturaIVA.allCases) { $0.etichetta }, larghezza: I.menu)
                    }
                    riga("Riferimento della riga", "Se la natura è diversa da quella delle righe") {
                        testo(\.regime.bollo.riferimentoNormativoRiga, larghezza: I.campoLungo)
                    }
                }
            }
        }
    }

    private var gruppoPagamento: some View {
        GruppoImpostazioni(titolo: "Pagamento") {
            riga("Modalità", "Il codice MP del tracciato") {
                MenuTendina(selezione: legame(\.modalitaPagamento),
                            opzioni: Self.scelte(ModalitaPagamento.allCases) { $0.etichetta }, larghezza: I.menu)
            }
            riga("Condizioni", "Il codice TP del tracciato") {
                MenuTendina(selezione: legame(\.condizioniPagamento),
                            opzioni: Self.scelte(CondizioniPagamento.allCases) { "\($0.codice) · \($0.descrizione)" },
                            larghezza: I.menu)
            }
            riga("Giorni per pagare", "Facoltativi: la scadenza proposta nelle parcelle nuove") {
                intero(\.giorniPagamento, unita: "giorni", larghezza: I.campoCorto)
            }
            riga("IBAN") { testo(\.iban, larghezza: I.campoLungo) }
            riga("Banca", "Facoltativa") { testo(\.banca, larghezza: I.campoMedio) }
            riga("Beneficiario", "Facoltativo") { testo(\.beneficiario, larghezza: I.campoMedio) }
        }
    }

    private func gruppoNumerazione(_ f: DatiFatturazione, anno: Int) -> some View {
        GruppoImpostazioni(titolo: "Numerazione") {
            riga("Modello del numero", "{anno}, {numero}, {numero:3} (almeno 3 cifre), {prefisso}; vuoto: il prefisso e il numero") {
                testo(\.numerazione.modello, larghezza: I.campoMedio)
            }
            riga("Prefisso", "Facoltativo") { testo(\.numerazione.prefisso, larghezza: I.campoCorto) }
            riga("Primo numero del \(String(anno))", "Se cominci a usare Prisma a metà anno; vuoto: da 1") {
                intero(primoNumero(anno), unita: "", larghezza: I.campoCorto)
            }
            riga("Prossimo numero", "La parcella emessa oggi prenderebbe questo numero") {
                Text(verbatim: stato.prossimoNumeroParcella())
                    .carattereApple(Tema.Apple.Carattere.barra)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
            }
            if f.numerazione.ultimoProgressivoInvio > 0 {
                riga("File XML preparati", "Il progressivo d’invio del nome del file non si ripete") {
                    Text(verbatim: MotoreParcelle.progressivoInvio(f.numerazione.ultimoProgressivoInvio))
                        .carattereApple(Tema.Apple.Carattere.barra)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
            }
        }
    }

    private func gruppoTrasmittente(_ f: DatiFatturazione) -> some View {
        GruppoImpostazioni(titolo: "Chi carica il file") {
            riga("Trasmittente", "Chi carica il file sul portale dell’Agenzia delle Entrate") {
                MenuTendina(selezione: legame(\.trasmittente.chi),
                            opzioni: Self.scelte(TrasmittenteFattura.Chi.allCases) { $0.nome }, larghezza: I.menu)
            }
            if f.trasmittente.chi == .intermediario {
                riga("Codice fiscale dell’intermediario") {
                    testo(\.trasmittente.codiceFiscaleIntermediario, larghezza: I.campoMedio)
                }
            }
        }
    }

    // MARK: Righe e campi

    private func riga<C: View>(_ titolo: String, _ sottotitolo: String? = nil, @ViewBuilder _ campo: @escaping () -> C) -> some View {
        RigaImpostazione(titolo: titolo, sottotitolo: sottotitolo, accessorio: campo)
    }

    /// Il testo passa all'archivio poco dopo l'ultimo tasto (TestoRinviato), come il nome dell'utente: ogni lettera
    /// ridisegna solo il campo, non cambia le impostazioni (e tutte le cache dei calcoli) a ogni tasto.
    private func testo(_ k: WritableKeyPath<DatiFatturazione, String>, larghezza: CGFloat) -> some View {
        TestoRinviato(testo: legame(k), salvaOra: { stato.salvaOra() }) { bozza in
            TextField("", text: bozza, prompt: Text(verbatim: "—"))
                .campoTesto()
                .autocorrectionDisabled()
                .frame(width: larghezza)
        }
    }

    private func numero(_ k: WritableKeyPath<DatiFatturazione, Double?>, unita: String, larghezza: CGFloat) -> some View {
        HStack(spacing: I.spazioUnita) {
            TextField("", value: legame(k), format: Self.formatoNumero, prompt: Text(verbatim: "—"))
                .campoTesto()
                .multilineTextAlignment(.trailing)
                .frame(width: larghezza)
            Text(verbatim: unita)
                .carattereApple(I.unita)
                .foregroundColor(I.coloreUnita)
        }
    }

    private func intero(_ k: WritableKeyPath<DatiFatturazione, Int?>, unita: String, larghezza: CGFloat) -> some View {
        intero(legame(k), unita: unita, larghezza: larghezza)
    }

    private func intero(_ legame: Binding<Int?>, unita: String, larghezza: CGFloat) -> some View {
        HStack(spacing: I.spazioUnita) {
            TextField("", value: legame, format: IntegerFormatStyle<Int>.number.grouping(.never), prompt: Text(verbatim: "—"))
                .campoTesto()
                .multilineTextAlignment(.trailing)
                .frame(width: larghezza)
            if !unita.isEmpty {
                Text(verbatim: unita)
                    .carattereApple(I.unita)
                    .foregroundColor(I.coloreUnita)
            }
        }
    }

    // MARK: Legami

    /// Il valore di un campo: si scrive solo se cambia davvero.
    private func legame<T>(_ k: WritableKeyPath<DatiFatturazione, T>) -> Binding<T> {
        let stato = self.stato
        return Binding(get: { stato.datiFatturazione[keyPath: k] },
                       set: { nuovo in stato.modificaDatiFatturazione { $0[keyPath: k] = nuovo } })
    }

    /// Il numero di partenza dell'anno (vuoto o meno di 1: da 1).
    private func primoNumero(_ anno: Int) -> Binding<Int?> {
        let stato = self.stato
        return Binding(get: { stato.datiFatturazione.numerazione.primoNumeroPerAnno[anno] },
                       set: { nuovo in
                           stato.modificaDatiFatturazione { f in
                               if let n = nuovo, n >= 1, n < Int(Int32.max) {
                                   f.numerazione.primoNumeroPerAnno[anno] = n
                               } else {
                                   f.numerazione.primoNumeroPerAnno[anno] = nil
                               }
                           }
                       })
    }

    /// «Da scegliere» e i codici dell'elenco: nessuna scelta di base.
    private static func scelte<V: Hashable>(_ casi: [V], _ nome: (V) -> String) -> [(V?, String)] {
        var r: [(V?, String)] = [(nil, "Da scegliere")]
        r += casi.map { (Optional($0), nome($0)) }
        return r
    }

    /// Né sì né no finché il consulente non lo dice.
    private static let siNo: [(Bool?, String)] = [(nil, "Da indicare"), (true, "Sì"), (false, "No")]

    /// Cifre all'italiana, fino a due decimali; un valore negativo non si scrive (`DatiFatturazione` lo legge vuoto).
    private static var formatoNumero: FloatingPointFormatStyle<Double> {
        FloatingPointFormatStyle<Double>.number.locale(Formati.localeImporti).precision(.fractionLength(0...2))
    }
}
