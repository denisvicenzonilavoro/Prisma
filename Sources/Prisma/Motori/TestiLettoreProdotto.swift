import Foundation

/// Documenti di prova per «La scheda dai documenti» (LettoreProdotto): un KID e un DIP aggiuntivo IBIP con le formule
/// del Regolamento PRIIPs e del Regolamento IVASS 41/2018, compagnia e prodotto inventati («Compagnia di Prova»).
/// Servono alle prove (`ProvaCalcoliLettoreProdotto`); nessun dato reale.
enum TestiLettoreProdotto {
    static let kid: [String] = [
        """
        Documento contenente le informazioni chiave
        Scopo
        Il presente documento contiene informazioni chiave relative a questo prodotto d'investimento.
        Prodotto
        Nome del prodotto: Risparmio Sereno Più
        Ideatore del PRIIP: Compagnia di Prova S.p.A.
        Codice ISIN: IT0000000017
        Data di realizzazione del documento: 01/03/2026
        Cos'è questo prodotto?
        Tipo: Contratto di assicurazione sulla vita a premi ricorrenti con rivalutazione annua del capitale collegato
        a una gestione separata.
        Quali sono i rischi e qual è il potenziale rendimento?
        Abbiamo classificato questo prodotto al livello 2 su 7, che corrisponde alla classe di rischio bassa.
        Periodo di detenzione raccomandato: 10 anni
        """,
        """
        Scenari di performance
        Periodo di detenzione raccomandato: 10 anni
        Premio annuo: 1.000 EUR
        In caso di uscita dopo 1 anno    In caso di uscita dopo 10 anni
        Minimo Non esiste un rendimento minimo garantito se uscite prima di 10 anni.
        Stress Possibile rimborso al netto dei costi 870 EUR 8.950 EUR
        Rendimento medio per ciascun anno -13,0% -2,0%
        Sfavorevole Possibile rimborso al netto dei costi 930 EUR 10.050 EUR
        Rendimento medio per ciascun anno -7,0% 0,1%
        Moderato Possibile rimborso al netto dei costi 950 EUR 10.900 EUR
        Rendimento medio per ciascun anno -5,0% 1,6%
        Favorevole Possibile rimborso al netto dei costi 970 EUR 11.700 EUR
        Rendimento medio per ciascun anno -3,0% 2,9%
        """,
        """
        Quali sono i costi?
        Costi nel tempo
        In caso di uscita dopo 1 anno    In caso di uscita dopo 10 anni
        Costi totali 95 EUR 1.150 EUR
        Incidenza annuale dei costi (*) 9,5% 2,1% ogni anno
        Composizione dei costi
        Costi di ingresso 3,00% del premio pagato. 30 EUR
        Costi di uscita Non addebitiamo una commissione di uscita per questo prodotto. 0 EUR
        Commissioni di gestione e altri costi amministrativi o di esercizio 1,30% del valore dell'investimento all'anno.
        Costi di transazione 0,05% del valore dell'investimento all'anno.
        Commissioni di performance Non si applica.
        """,
    ]

    static let dipAggiuntivo: [String] = [
        """
        Assicurazione sulla vita a premi ricorrenti
        Documento informativo precontrattuale aggiuntivo per i prodotti d'investimento assicurativi
        (DIP aggiuntivo IBIP)
        Compagnia di Prova S.p.A. Prodotto: Risparmio Sereno Più
        Quali costi devo sostenere?
        Caricamenti: 3,00% di ciascun premio versato.
        Diritti fissi di emissione: 25 euro una tantum.
        Rendimento trattenuto dalla compagnia: 1,30 punti percentuali sul rendimento della gestione separata.
        Tasso minimo garantito: 0,50% annuo.
        """,
        """
        Sono previsti riscatti o riduzioni?
        Il riscatto è possibile trascorso almeno un anno dalla decorrenza.
        Penali di riscatto: 2° anno 3,00%; 3° anno 2,00%; 4° anno 1,00%; 5° anno 0,50%.
        Quali sono i costi per il riscatto?
        Regime fiscale
        Le prestazioni sono soggette a imposta sostitutiva del 26% sui rendimenti; la parte di rendimento derivante
        dai titoli di Stato, pari al 60% del portafoglio della gestione separata, è tassata al 12,5%.
        """,
    ]
}
