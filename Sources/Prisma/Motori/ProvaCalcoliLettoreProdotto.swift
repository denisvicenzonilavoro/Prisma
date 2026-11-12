import Foundation

/// Prove di «La scheda dai documenti» (LettoreProdotto) sui documenti di prova `TestiLettoreProdotto` (KID e DIP
/// aggiuntivo inventati): tipo dei documenti; costi della composizione (ingresso, uscita «non addebitiamo» = 0,
/// gestione, transazione, performance «non si applica» = 0); incidenza a 1 anno e al periodo; i quattro scenari con la
/// colonna a 1 anno e quella al periodo («sfavorevole» non diventa «favorevole»); trattenuto, minimo garantito,
/// caricamento, diritti fissi una tantum, penali per anno, riscatto dopo 12 mesi, aliquota e titoli di Stato; il tipo di
/// prodotto riconosciuto; la scheda: costo annuo senza il trattenuto (non si conta due volte), rendimento lordo dal
/// moderato, aliquota con i titoli di Stato, scenari e penali nelle condizioni, solo le voci scelte; le alternative fra
/// due documenti; gli scarti del KID negli scenari delle proiezioni. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliLettoreProdotto {
    static func esegui(_ verifica: VerificaCalcoli) {
        let kid = LettoreProdotto.DocumentoDaLeggere(nome: "KID di prova.pdf", pagine: TestiLettoreProdotto.kid)
        let dip = LettoreProdotto.DocumentoDaLeggere(nome: "DIP aggiuntivo di prova.pdf", pagine: TestiLettoreProdotto.dipAggiuntivo)
        let l = LettoreProdotto.leggi([kid, dip])
        func n(_ v: LettoreProdotto.Voce) -> Double { l.dato(v)?.numero ?? -999 }
        func ultimo(_ v: LettoreProdotto.Voce) -> Double { l.dato(v)?.numeri.last ?? -999 }

        verifica.vero("Scheda dai documenti: KID e DIP aggiuntivo riconosciuti",
                      l.documenti.map(\.tipo) == [.kid, .dipAggiuntivo])
        verifica("Scheda dai documenti: costi d'ingresso", n(.costoIngresso), 3)
        verifica("Scheda dai documenti: costi d'uscita «non addebitiamo» = 0", n(.costoUscita), 0)
        verifica("Scheda dai documenti: costi di gestione", n(.costoGestione), 1.3)
        verifica("Scheda dai documenti: costi di transazione", n(.costiTransazione), 0.05)
        verifica("Scheda dai documenti: performance «non si applica» = 0", n(.commissioniPerformance), 0)
        verifica("Scheda dai documenti: incidenza a 1 anno", n(.incidenzaUnAnno), 9.5)
        verifica("Scheda dai documenti: incidenza al periodo", n(.incidenzaPeriodo), 2.1)
        verifica("Scheda dai documenti: stress a 1 anno", n(.scenarioStress), -13)
        verifica("Scheda dai documenti: sfavorevole al periodo", ultimo(.scenarioSfavorevole), 0.1)
        verifica("Scheda dai documenti: moderato al periodo", ultimo(.scenarioModerato), 1.6)
        verifica("Scheda dai documenti: favorevole al periodo (non lo sfavorevole)", ultimo(.scenarioFavorevole), 2.9)
        verifica("Scheda dai documenti: esempio del KID, premio annuo", n(.esempioKID), 1_000)
        verifica("Scheda dai documenti: SRI", n(.sri), 2)
        verifica("Scheda dai documenti: periodo raccomandato", n(.periodoRaccomandato), 10)
        verifica("Scheda dai documenti: trattenuto dal DIP aggiuntivo", n(.trattenuto), 1.3)
        verifica("Scheda dai documenti: minimo garantito", n(.minimoGarantito), 0.5)
        verifica("Scheda dai documenti: caricamento", n(.caricamento), 3)
        verifica.vero("Scheda dai documenti: diritti fissi una tantum, non all'anno",
                      l.dato(.costoFisso)?.numeri == [25, 0])
        verifica.vero("Scheda dai documenti: penali dal 2° al 5° anno", l.dato(.penali)?.numeri == [3, 2, 1, 0.5])
        verifica("Scheda dai documenti: riscatto dopo un anno = 12 mesi", n(.bloccoRiscatto), 12)
        verifica("Scheda dai documenti: aliquota 26%", n(.aliquota), 26)
        verifica("Scheda dai documenti: titoli di Stato 60%", n(.quotaTitoliStato), 60)
        verifica.vero("Scheda dai documenti: dato con documento e pagina",
                      l.dato(.penali)?.tipo == .dipAggiuntivo && l.dato(.penali)?.pagina == 2
                        && l.dato(.scenarioModerato)?.tipo == .kid && l.dato(.scenarioModerato)?.pagina == 2)
        verifica.vero("Scheda dai documenti: Ramo I a premi ricorrenti con gestione separata",
                      l.riconoscimento?.area == .risparmio && l.riconoscimento?.gestioneSeparata == true)
        verifica.vero("Scheda dai documenti: nulla manca del KID", l.mancantiKID.isEmpty)

        // La scheda con tutte le voci
        let oggi = AiutiProva.data(2026, 11, 12)
        let p = LettoreProdotto.prodotto(da: l, scelte: Set(l.trovate), canale: .alleanza, oggi: oggi)
        verifica.vero("Scheda dai documenti: nome dal KID", p.nome == "Risparmio Sereno Più")
        verifica.vero("Scheda dai documenti: area dal riconoscimento", p.area == .risparmio)
        verifica("Scheda dai documenti: costo d'ingresso nella scheda", p.costoIngresso ?? -1, 3)
        // 1,30 + 0,05 di costi correnti, meno 1,30 di trattenuto che Prisma conta a parte
        verifica("Scheda dai documenti: costo annuo senza il trattenuto", p.costoAnnuo ?? -1, 0.05)
        verifica("Scheda dai documenti: trattenuto nella scheda", p.trattenuto ?? -1, 1.3)
        verifica("Scheda dai documenti: incidenza del KID", p.incidenzaCostiKID ?? -1, 2.1)
        // 26 − 0,60 × (26 − 12,5) = 17,9
        verifica("Scheda dai documenti: aliquota con il 60% in titoli di Stato", p.aliquotaFiscale ?? -1, 17.9)
        let atteso = MotoreConfrontoDossier.lordoImplicito(moderato: 1.6, ingresso: 3, annuo: 1.35, anni: 10) ?? -1
        verifica("Scheda dai documenti: rendimento lordo dal moderato con tutti i costi correnti",
                 p.rendimentoAtteso ?? -1, (atteso * 100).rounded() / 100)
        verifica.vero("Scheda dai documenti: quattro scenari nelle condizioni",
                      p.condizioni?.scenariKID.map(\.nome) == ["Stress", "Sfavorevole", "Moderato", "Favorevole"])
        verifica.vero("Scheda dai documenti: penali e blocco nelle condizioni",
                      p.condizioni?.penali == [3, 2, 1, 0.5] && p.condizioni?.mesiBloccoRiscatto == 12)
        verifica.vero("Scheda dai documenti: canale Alleanza con la compagnia del KID",
                      p.canale == .alleanza && p.emittente.contains("Compagnia di Prova"))
        verifica.vero("Scheda dai documenti: verificata oggi", p.verificatoIl == Calendar.current.startOfDay(for: oggi))

        // Solo le voci scelte: senza i costi la scheda non li prende
        var base = Prodotto(nome: "Prodotto di prova", canale: .indipendente, area: .investimento)
        base.costoAnnuo = 0.9
        LettoreProdotto.applica(l, scelte: [.sri], a: &base, oggi: oggi)
        verifica.vero("Scheda dai documenti: senza la conferma i costi restano quelli di prima",
                      base.costoAnnuo == 0.9 && base.sri == 2 && base.costoIngresso == nil)

        // Due documenti che non dicono la stessa cosa: il KID vince sui costi, l'altro resta da scegliere
        let altro = LettoreProdotto.DocumentoDaLeggere(nome: "Scheda costi.pdf", pagine: [
            "Scheda costi\nCosti di ingresso 2,50% del premio pagato.\n",
        ])
        let due = LettoreProdotto.leggi([altro, kid])
        verifica("Scheda dai documenti: sui costi vince il KID", due.dato(.costoIngresso)?.numero ?? -1, 3)
        verifica.vero("Scheda dai documenti: la scheda costi resta fra le alternative",
                      due.dato(.costoIngresso)?.alternative.first?.numero == 2.5 && due.dato(.costoIngresso)?.daScegliere == true)

        // Riconoscimento di altri tipi
        verifica.vero("Scheda dai documenti: PIP riconosciuto",
                      LettoreProdotto.riconosci("Piano individuale pensionistico di tipo assicurativo")?.area == .previdenza)
        verifica.vero("Scheda dai documenti: TCM riconosciuta",
                      LettoreProdotto.riconosci("Assicurazione temporanea caso morte a premio annuo")?.area == .protezione)
        verifica.vero("Scheda dai documenti: unit linked a premio unico",
                      LettoreProdotto.riconosci("Contratto unit linked collegato a fondi interni, premio unico")?.tipologia == "Unit linked (Ramo III)")

        // Gli scenari delle proiezioni seguono il KID: scarti −1,5 e +1,3 punti dal moderato
        verifica.vero("Scheda dai documenti: scarti del KID nella scheda",
                      p.scartiScenariKID.map { $0.map { ($0 * 100).rounded() / 100 } } == [-1.5, 1.3])
        let proposta = p.proposta(per: "giulia")
        var par = ParametriProiezione(posizione: proposta, orizzonteCliente: 10)
        par.anni = 10
        let s = MotoreProiezione.scenari(par)
        verifica("Scheda dai documenti: prudente = atteso − 1,5 (KID)", s[0].rendimento, par.rendimento - 1.5)
        verifica("Scheda dai documenti: favorevole = atteso + 1,3 (KID)", s[2].rendimento, par.rendimento + 1.3)
        var senza = par
        senza.scartiKID = nil
        verifica("Scheda dai documenti: senza KID restano i ±2 punti",
                 MotoreProiezione.scenari(senza)[2].rendimento, par.rendimento + IpotesiCalcolo.ampiezzaScenari)
    }
}
