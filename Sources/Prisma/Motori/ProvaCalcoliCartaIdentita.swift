import Foundation

/// Prove di «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1, «Luce» giro 13), solo su dati di prova
/// dichiarati (la carta fac-simile «Elena Marchi» del template, numero «CA00000AA» palesemente finto): codice fiscale
/// (carattere di controllo, omocodie, coerenza con cognome, nome, data e sesso, comune mai controllato), zona a lettura
/// ottica con le cifre di controllo 7-3-1, fronte con le etichette, campi mancanti mai inventati, fronte e retro, documento
/// scaduto, doppioni, limiti della busta del ponte e creazione del cliente. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliCartaIdentita {
    static func esegui(_ verifica: VerificaCalcoli) {
        codiceFiscale(verifica)
    }

    /// Una data di nascita come le scrive la carta: giorno a mezzanotte nel calendario gregoriano.
    static func giorno(_ anno: Int, _ mese: Int, _ g: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: anno, month: mese, day: g)) ?? Date()
    }

    // MARK: - Punti 1-4: il codice fiscale

    private static func codiceFiscale(_ verifica: VerificaCalcoli) {
        let cf = "MRCLNE90D43A944S"
        verifica.vero("Carta: il carattere di controllo di «MRCLNE90D43A944» è S",
                      CodiceFiscale.carattereDiControllo("MRCLNE90D43A944") == "S" && CodiceFiscale.carattereDiControlloValido(cf))
        let nascita = giorno(1990, 4, 3)
        verifica.vero("Carta: con l'ultima lettera cambiata il codice non ha la forma valida",
                      CodiceFiscale.coerenza("MRCLNE90D43A944T", cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .femmina) == .formaNonValida)
        // Omocodia: il 4 del comune diventa Q, il controllo ricalcolato è P
        let omocodia = "MRCLNE90D43A94QP"
        verifica.vero("Carta: l'omocodia «MRCLNE90D43A94QP» è valida e torna «MRCLNE90D43A944»",
                      CodiceFiscale.carattereDiControlloValido(omocodia) && CodiceFiscale.formaValida(omocodia)
                        && CodiceFiscale.senzaOmocodia(omocodia).prefix(15) == "MRCLNE90D43A944")
        let esito = CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .femmina)
        verifica.vero("Carta: il codice del fac-simile è coerente, comune non controllato (decisione 70)",
                      esito == .coerenteSenzaComune && esito.testo == "✓ coerente (comune non controllato)" && !CodiceFiscale.comuneControllato)
        verifica.vero("Carta: anche minuscolo e con gli spazi il codice si legge uguale",
                      CodiceFiscale.coerenza("mrcl ne90d43a944s", cognome: "MARCHI", nome: "ELENA", nascita: nascita, sesso: .femmina) == .coerenteSenzaComune)
        verifica.vero("Carta: con l'omocodia la coerenza resta (senza comune)",
                      CodiceFiscale.coerenza(omocodia, cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .femmina) == .coerenteSenzaComune)
        let meseSbagliato = CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: giorno(1990, 5, 3), sesso: .femmina)
        verifica.vero("Carta: con il mese sbagliato «non torna con la data di nascita: controllalo»",
                      meseSbagliato == .diverso([.mese]) && meseSbagliato.testo == "non torna con la data di nascita: controllalo" && meseSbagliato.daGuardare)
        verifica.vero("Carta: un maschio con il giorno 43 non torna con il sesso",
                      CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: nascita, sesso: .maschio) == .diverso([.sesso]))
        verifica.vero("Carta: il sesso si legge dal giorno (43 = femmina)", CodiceFiscale.sesso(cf) == .femmina)
        verifica.vero("Carta: senza la data di nascita il codice non si può confrontare",
                      CodiceFiscale.coerenza(cf, cognome: "Marchi", nome: "Elena", nascita: nil, sesso: nil) == .nonVerificabile)
        verifica.vero("Carta: «Elena» → «LNE» (due consonanti e una vocale)", CodiceFiscale.lettereNome("Elena") == "LNE")
        verifica.vero("Carta: «Gianfranco» → «GFR» (1ª, 3ª e 4ª consonante)", CodiceFiscale.lettereNome("Gianfranco") == "GFR")
        verifica.vero("Carta: «Fo» → «FOX» (cognome corto)", CodiceFiscale.lettereCognome("Fo") == "FOX")
        verifica.vero("Carta: «D'Angelo» → «DNG» (senza apostrofi né accenti)", CodiceFiscale.lettereCognome("D'Angelo") == "DNG")
        let nascitaLetta = CodiceFiscale.nascita(cf) { aa in aa > 30 ? 1900 : 2000 }
        verifica.vero("Carta: la data scritta nel codice è il 3 aprile 1990",
                      nascitaLetta?.year == 1990 && nascitaLetta?.month == 4 && nascitaLetta?.day == 3)
    }
}
