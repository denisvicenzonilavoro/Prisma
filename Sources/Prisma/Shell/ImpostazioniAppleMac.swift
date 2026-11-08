import SwiftUI

// Impostazioni nel tema Apple, sul Mac e sull'iPad (Design/template-apple-specifica.md §4.6, riferimenti PIE i01-i09):
//
//   ┌─ Panoramica ─────────┐  Aspetto
//   │ ▌Aspetto    (scelta) │  ┌──────────────────────────────────────────────────────────────┐
//   │  Archivio e backup   │  │ Aspetto                          [Chiaro | Scuro | Automatico] │
//   │  Vera                 │  │ Chiaro, scuro o automatico come il Mac.                        │
//   │  Profilo             │  └──────────────────────────────────────────────────────────────┘
//   │ IL LAVORO            │  ┌──────────────────────────────────────────────────────────────┐
//   │  Agenda e lavoro …   │  │ Riduci movimento                                        (●  ) │
//   │ PER LE PROVE         │  └──────────────────────────────────────────────────────────────┘
//   │  Strumenti           │
//   │ ● Archivio locale    │
//   └──────────────────────┘
//
// - Barra laterale 260 (`.side`): le sezioni del template (Aspetto, Archivio e backup, Vera, Profilo) dopo la
//   Panoramica, poi le altre pagine di Prisma sotto «Il lavoro» e Strumenti sotto «Per le prove». Voci `.rub`.
// - Pagina: titolo `.h2` (4 sopra, 14 sotto) e le righe come card senza ombra (`.impostazioniApple()`); cambiando
//   sezione la cascata riparte con base 0. Aspetto, Archivio e backup, Vera e Profilo come nel template; le altre
//   pagine sono quelle di sempre, nelle card del tema.
// - «Riduci movimento» e istantanee: tutto è subito fermo nello stato finale.
// Valori in DesignSystem/Apple/Tema.Apple+Impostazioni.swift.

extension AppImpostazioni {
    /// Le sezioni della barra laterale, dall'alto in basso (tutte le pagine di sempre).
    /// L'ordine del template di Orizzonte (§13.1.2): Aspetto · iPhone e iPad · Archivio e backup · Vera · Profilo.
    static let sezioniPrincipali: [SchedaImpostazioni] = [.panoramica, .aspetto, .ovunque, .archivio, .vera, .profilo]
    static let sezioniLavoro: [SchedaImpostazioni] = [.studio, .mercato, .portafogliModello, .pratiche, .moduli, .lavoro, .promemoria, .conformita, .proposte, .rendimenti, .scorciatoie]
    static let sezioniProve: [SchedaImpostazioni] = [.strumenti]

    var corpoApple: some View {
        let d = Tema.Apple.Impostazioni.Disposizione.self
        return HStack(alignment: .top, spacing: d.spazioLaterale) {
            barraLateraleApple
                .frame(width: d.larghezzaLaterale)
                .frame(maxHeight: .infinity, alignment: .top)
            paginaApple
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .impostazioniApple()
    }

    // MARK: Barra laterale

    private var barraLateraleApple: some View {
        let l = Tema.Apple.Impostazioni.Laterale.self
        let forma = RoundedRectangle(cornerRadius: l.raggio, style: .continuous)
        let principali = Self.sezioniPrincipali
        let lavoro = Self.sezioniLavoro
        return VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    gruppoLateraleApple(nil, principali, primo: 0)
                    gruppoLateraleApple("Il lavoro", lavoro, primo: principali.count)
                    gruppoLateraleApple("Per le prove", Self.sezioniProve, primo: principali.count + lavoro.count + 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            piedeLateraleApple
                .padding(.top, l.sopraPiede)
        }
        .padding(l.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(forma)
        .superficieApple(l.superficie, raggio: l.raggio)
    }

    private func gruppoLateraleApple(_ titolo: String?, _ pagine: [SchedaImpostazioni], primo: Int) -> some View {
        let l = Tema.Apple.Impostazioni.Laterale.self
        return VStack(alignment: .leading, spacing: l.fraVoci) {
            if let titolo {
                Text(titolo)
                    .carattereApple(l.etichetta)
                    .foregroundColor(l.coloreEtichetta)
                    .lineLimit(1)
                    .padding(.leading, l.rientroEtichetta)
                    .padding(.top, l.sopraGruppo)
                    .padding(.bottom, max(0, l.sottoEtichetta - l.fraVoci))
                    .entrataCascata(primo)
            }
            ForEach(Array(pagine.enumerated()), id: \.element) { i, p in
                // Il pallino di «Prisma ovunque» legge `stato.ovunque.problema`: StatoOvunque è @Observable, quindi
                // un errore della sincronizzazione in background lo accende da solo
                voceLateraleApple(p)
                .entrataCascata(primo + i + (titolo == nil ? 0 : 1), sfocatura: false)
            }
        }
    }

    private func voceLateraleApple(_ p: SchedaImpostazioni) -> some View {
        VoceLateraleImpostazioniApple(titolo: p.titolo, attiva: stato.schedaImpostazioni == p,
                                      stato: statoVoceLaterale(p)) {
            stato.schedaImpostazioni = p
        }
    }

    /// Un pallino accanto alla sezione solo quando c'è da guardare (backup, archivio, Vera non pronta).
    private func statoVoceLaterale(_ p: SchedaImpostazioni) -> Pillola.Tono? {
        switch p {
        case .archivio:
            if stato.solaLettura || stato.dati.impostazioni.backup.ultimoErrore != nil { return .errore }
            if stato.copieNonLeggibili > 0 || stato.dati.impostazioni.backup.inRitardo { return .attenzione }
            return nil
        case .vera:
            return stato.disponibilitaLocale.pronto ? nil : .attenzione
        case .ovunque:
            guard stato.dati.impostazioni.ovunque.acceso else { return nil }
            if stato.ovunque.problema != nil { return .errore }
            return stato.dati.conflittiOvunque.isEmpty ? nil : .attenzione
        case .mercato:
            // L'ultimo scaricamento non riuscito del tutto
            return stato.dati.impostazioni.mercato.attivo && stato.dati.mercato.ultimoErrore != nil ? .attenzione : nil
        default:
            return nil
        }
    }

    /// In fondo: l'archivio locale (con il pallino verde) e la versione di Prisma.
    private var piedeLateraleApple: some View {
        let l = Tema.Apple.Impostazioni.Laterale.self
        return VStack(alignment: .leading, spacing: l.spazioPiede) {
            HStack(spacing: Tema.Apple.Impostazioni.Stato.spazio) {
                Circle()
                    .fill(l.colorePallinoPiede)
                    .frame(width: l.pallinoPiede, height: l.pallinoPiede)
                Text(Self.notaArchivio)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Text("Prisma \(Self.versioneApp)")
                .lineLimit(1)
        }
        .carattereApple(l.piede)
        .foregroundColor(l.colorePiede)
        .padding(.horizontal, l.rientroEtichetta)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Pagina

    /// La sezione scelta: titolo `.h2` e righe, in una colonna leggibile (i rendimenti prendono tutta la larghezza).
    /// Cambiando sezione si riparte dall'alto e la cascata riparte (la pagina nasce di nuovo con il suo `.id`).
    private var paginaApple: some View {
        let scelta = stato.schedaImpostazioni
        let p = Tema.Apple.Impostazioni.Pagina.self
        return ScrollViewReader { lettore in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TitoloPaginaImpostazioni(testo: scelta.titolo)
                        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                    contenutoApple(scelta)
                }
                .frame(maxWidth: scelta == .rendimenti || scelta == .ovunque ? .infinity : p.larghezzaMassima, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(p.margine)
            }
            .scrollIndicators(.hidden)
            .id(scelta)
            .onAppear { scorri(lettore) }
            .onChange(of: stato.ancoraImpostazioni) { _ in scorri(lettore) }
        }
    }

    /// Le quattro sezioni del template hanno le righe a cascata una per una; le altre entrano tutte insieme.
    @ViewBuilder private func contenutoApple(_ pagina: SchedaImpostazioni) -> some View {
        switch pagina {
        case .aspetto, .archivio, .vera, .ovunque:
            contenuto(pagina)
        case .profilo:
            profiloApple
        default:
            VStack(alignment: .leading, spacing: M.spazioGruppi) {
                contenuto(pagina)
            }
            .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
        }
    }

    // MARK: Profilo

    /// Come nel template (PIE i08): la card con l'avatar 64 «DV», il nome e «Consulente finanziario», poi il nome
    /// da modificare e le due righe dei canali con le loro etichette.
    private var profiloApple: some View {
        let f = Tema.Apple.Impostazioni.Profilo.self
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: f.spazio) {
                AvatarProfiloApple(iniziali: stato.inizialiUtente)
                VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.sottoTitolo) {
                    Text(stato.nomeUtente)
                        .carattereApple(f.nome)
                        .foregroundColor(f.coloreNome)
                        .lineLimit(1)
                    Text("Consulente finanziario")
                        .carattereApple(f.ruolo)
                        .foregroundColor(f.coloreRuolo)
                }
                Spacer(minLength: 0)
            }
            .padding(f.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .superficieApple(f.superficie, raggio: f.raggio)
            .padding(.bottom, f.sottoCard)
            .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
            GruppoImpostazioni {
                RigaImpostazione(titolo: "Il tuo nome", sottotitolo: "Come ti accoglie la scrivania.") {
                    ValoreRiga(testo: stato.nomeUtente) { modificaNome = true }
                        .popover(isPresented: $modificaNome, arrowEdge: .leading) { campoNomeApple }
                }
                .cascataImpostazioni(2)
                RigaImpostazione(titolo: "Canale Alleanza", sottotitolo: "Etichetta in vetro blu con il logo Alleanza. Solo prodotti Alleanza.") {
                    EtichettaCanaleApple(canale: .alleanza)
                }
                .cascataImpostazioni(3)
                RigaImpostazione(titolo: "Canale indipendente",
                                 sottotitolo: "«Denis Vicenzoni · Consulenza finanziaria». Investimenti, risparmio, previdenza, protezione.") {
                    EtichettaCanaleApple(canale: .indipendente)
                }
                .cascataImpostazioni(4)
            }
            NotaImpostazioni("Ogni posizione e ogni proposta porta l'etichetta del suo canale.")
                .padding(.top, Tema.Apple.Impostazioni.Riga.fraRighe)
                .cascataImpostazioni(5)
        }
    }

    /// Il nome nel popover: entra nei documenti e passa all'archivio poco dopo l'ultimo tasto.
    private var campoNomeApple: some View {
        let f = Tema.Apple.Impostazioni.Profilo.self
        return VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.spazioControlliAffiancati) {
            Text("Il tuo nome")
                .carattereApple(Tema.Apple.Impostazioni.Riga.titolo)
                .foregroundColor(Tema.Apple.Impostazioni.Riga.coloreTitolo)
            TestoRinviato(testo: Bindable(stato.dati).impostazioni.nomeUtente, salvaOra: { stato.salvaOra() }) { bozza in
                TextField("Nome", text: bozza)
                    .campoTesto()
                    .frame(width: f.larghezzaCampo)
                    .onSubmit { modificaNome = false }
            }
        }
        .padding(f.paddingPopover)
    }
}

/// L'avatar del consulente nel profilo (`.av` 64): «DV» 22 semibold bianco sul gradiente dall'alto in basso.
private struct AvatarProfiloApple: View {
    let iniziali: String

    var body: some View {
        let f = Tema.Apple.Impostazioni.Profilo.self
        Text(iniziali)
            .carattereApple(f.iniziali)
            .foregroundColor(f.coloreIniziali)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: f.avatar, height: f.avatar)
            .background {
                Circle()
                    .fill(LinearGradient(colors: [f.avatarAlto, f.avatarBasso], startPoint: .top, endPoint: .bottom))
            }
            .accessibilityHidden(true)
    }
}
