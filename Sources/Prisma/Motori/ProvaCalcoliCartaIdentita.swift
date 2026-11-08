import Foundation

/// Prove di «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1, «Luce» giro 13), solo su dati di prova
/// dichiarati (la carta fac-simile «Elena Marchi» del template, numero «CA00000AA» palesemente finto): codice fiscale
/// (carattere di controllo, omocodie, coerenza con cognome, nome, data e sesso, comune mai controllato), zona a lettura
/// ottica con le cifre di controllo 7-3-1, fronte con le etichette, campi mancanti mai inventati, fronte e retro, documento
/// scaduto, doppioni, limiti della busta del ponte e creazione del cliente. Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliCartaIdentita {
    static func esegui(_ verifica: VerificaCalcoli) {
        codiceFiscale(verifica)
        zonaOttica(verifica)
        fronte(verifica)
        doppioni(verifica)
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

    // MARK: - Punti 5-6: la zona a lettura ottica

    private static func zonaOttica(_ verifica: VerificaCalcoli) {
        verifica.vero("Carta: cifre di controllo 7-3-1 (CA00000AA → 4, 900403 → 4, 310403 → 5)",
                      MotoreCartaIdentita.cifraDiControllo("CA00000AA") == 4 && MotoreCartaIdentita.cifraDiControllo("900403") == 4
                        && MotoreCartaIdentita.cifraDiControllo("310403") == 5)
        let z = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righeRetro())
        let tutti: [CampoCarta] = [.numero, .dataNascita, .sesso, .scadenza, .cittadinanza, .cognome, .nome]
        verifica.vero("Carta: la zona TD1 dà numero, nascita, sesso, scadenza, cittadinanza, cognome e nome, tutti dalla zona",
                      z.conZonaOttica && z.tipo == .cartaIdentita && tutti.allSatisfy { z[$0]?.fonte == .zonaOttica && z[$0]?.daGuardare == false })
        verifica.vero("Carta: dalla zona «CA00000AA», 3/4/1990, F, 3/4/2031, ITA, Marchi Elena",
                      z.numero == "CA00000AA" && z.dataNascita == giorno(1990, 4, 3) && z.sessoLetto == .femmina
                        && z.scadenza == giorno(2031, 4, 3) && z[.cittadinanza]?.valore == "ITA" && z.cittadinanza == "Italiana"
                        && z.nomeCompleto == "Elena Marchi")
        var sbagliata = CartaIdentitaFacSimile.zonaRetro
        sbagliata[1] = "9004035F3104035ITA<<<<<<<<<<<2"
        let zs = MotoreCartaIdentita.zonaOttica(sbagliata)
        verifica.vero("Carta: con la cifra della nascita sbagliata la nascita resta da guardare",
                      zs?[.dataNascita]?.daGuardare == true && zs?[.scadenza]?.daGuardare == false)
        let unite = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righe() + sbagliata.map { RigaLetta(testo: $0) })
        verifica.vero("Carta: con la zona che non torna vale il fronte, segnato da guardare",
                      unite[.dataNascita]?.fonte == .fronte && unite[.dataNascita]?.daGuardare == true)
        let nonZona = MotoreCartaIdentita.zonaOttica(CartaIdentitaFacSimile.zonaDisegnata)
        verifica.vero("Carta: la zona disegnata del template (troppo corta) non si legge come zona ottica", nonZona == nil)
        let td3 = [
            "P<ITAMARCHI<<ELENA<<<<<<<<<<<<<<<<<<<<<<<<<<",
            "YA00000008ITA9004034F3104035<<<<<<<<<<<<<<00",
        ]
        let p = MotoreCartaIdentita.zonaOttica(td3)
        verifica.vero("Carta: la zona TD3 del passaporto si legge (tipo passaporto, nascita e scadenza)",
                      td3.allSatisfy { $0.count == 44 } && p?.tipo == .passaporto && p?.dataNascita == giorno(1990, 4, 3)
                        && p?.scadenza == giorno(2031, 4, 3) && p?.nomeCompleto == "Elena Marchi")
    }

    // MARK: - Punti 7-10 e 12: fronte, mancanti, fronte e retro, scaduto, limiti del ponte

    private static func fronte(_ verifica: VerificaCalcoli) {
        let oggi = giorno(2026, 11, 8)
        let f = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righe())
        verifica.vero("Carta: il fronte del fac-simile dà i campi del template, ognuno con il suo riquadro",
                      !f.conZonaOttica && f.tipo == .cartaIdentita
                        && CartaIdentitaFacSimile.campiDisegnati.allSatisfy { f[$0]?.fonte == .fronte && f[$0]?.riquadro != nil })
        let righe = MotoreCartaIdentita.righe(f, correzioni: [:], oggi: oggi)
        verifica.vero("Carta: cinque righe nell'ordine del template", righe.map(\.id) == ["nome", "nascita", "cf", "documento", "eta"])
        verifica.vero("Carta: «Elena Marchi», «Nata il» «3 aprile 1990, a Bologna», «36 anni»",
                      righe[0].valore == "Elena Marchi" && righe[1].etichetta == "Nata il" && righe[1].valore == "3 aprile 1990, a Bologna"
                        && righe[4].valore == "36 anni")
        verifica.vero("Carta: «MRCLNE90D43A944S · ✓ coerente (comune non controllato)» e «carta d'identità · scade nel 2031»",
                      righe[2].valore == "MRCLNE90D43A944S · ✓ coerente (comune non controllato)"
                        && righe[3].valore == "carta d'identità · scade nel 2031" && righe.allSatisfy { $0.stato == .letta })
        verifica.vero("Carta: con il fronte intero «Anagrafica completa»", MotoreCartaIdentita.sottotitolo(f) == "Anagrafica completa")

        let parziale = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righeParziali())
        let rp = MotoreCartaIdentita.righe(parziale, correzioni: [:], oggi: oggi)
        verifica.vero("Carta: i campi non letti restano nil, mai inventati", parziale[.scadenza] == nil && parziale[.luogoNascita] == nil)
        verifica.vero("Carta: lettura parziale «Mancano 2 dati», documento «non letto: lo scrivi tu», codice fiscale da guardare",
                      MotoreCartaIdentita.sottotitolo(parziale) == "Mancano 2 dati" && rp[3].stato == .mancante
                        && rp[3].valore == MotoreCartaIdentita.nonLetto && rp[2].stato == .daGuardare
                        && rp[2].valore.hasSuffix("non torna con la data di nascita: controllalo"))
        let corretta = MotoreCartaIdentita.righe(parziale, correzioni: [.codiceFiscale: "MRCLNE90D43A944S"], oggi: oggi)
        verifica.vero("Carta: il codice corretto a mano si ricontrolla e diventa «scritto da te»", corretta[2].stato == .scrittaDaTe)

        let retro = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righeRetro())
        let unita = parziale.unita(con: retro)
        verifica.vero("Carta: fronte e retro si sommano (la scadenza arriva dal retro, il nome del fronte resta)",
                      unita.scadenza == giorno(2031, 4, 3) && unita[.nome]?.fonte == .fronte && unita.conZonaOttica
                        && unita[.cittadinanza] != nil)
        let soloFronte = f.unita(con: LetturaCartaIdentita())
        verifica.vero("Carta: una seconda faccia vuota non cancella nulla", soloFronte == f)

        let scaduta = MotoreCartaIdentita.righe(f, correzioni: [.scadenza: "03.04.2026"], oggi: oggi)
        verifica.vero("Carta: documento scaduto «carta d'identità · scaduta il 3 aprile 2026», da guardare, con la nota",
                      scaduta[3].stato == .daGuardare && scaduta[3].valore == "carta d'identità · scaduta il 3 aprile 2026"
                        && scaduta[3].nota == MotoreCartaIdentita.notaScaduto)

        let righeCarta = CartaIdentitaFacSimile.righe()
        verifica.vero("Carta: la busta della carta del fac-simile è valida",
                      CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: righeCarta).valido)
        let troppe = Array(repeating: RigaLetta(testo: "riga"), count: PonteVera.massimoRighe + 1)
        verifica.vero("Carta: oltre il massimo delle righe la busta è rifiutata",
                      !CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: troppe).valido)
        verifica.vero("Carta: tre facce non vanno", !CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: righeCarta, facce: 3).valido)
        verifica.vero("Carta: un nome del dispositivo troppo lungo non va",
                      !CartaIdentitaPonte(dispositivo: String(repeating: "x", count: PonteVera.massimoDispositivo + 1), righe: righeCarta).valido)
        verifica.vero("Carta: una busta senza righe non va", !CartaIdentitaPonte(dispositivo: "iPhone di prova", righe: []).valido)
    }

    // MARK: - Punto 11: doppioni

    private static func doppioni(_ verifica: VerificaCalcoli) {
        let f = MotoreCartaIdentita.leggi(CartaIdentitaFacSimile.righe())
        var conCodice = Cliente.nuovo(tinta: .verde)
        conCodice.nome = "Elena Rossi"
        conCodice.codiceFiscale = "mrclne90d43a944s"
        verifica.vero("Carta: doppione per codice fiscale (anche minuscolo)",
                      MotoreCartaIdentita.clienteGiaPresente(f, clienti: [conCodice])?.id == conCodice.id)
        var conNome = Cliente.nuovo(tinta: .blu)
        conNome.nome = "MARCHI ELENA"
        conNome.dataNascita = giorno(1990, 4, 3)
        verifica.vero("Carta: doppione per nome (invertito) e data di nascita",
                      MotoreCartaIdentita.clienteGiaPresente(f, clienti: [conNome])?.id == conNome.id)
        var altraData = conNome
        altraData.dataNascita = giorno(1991, 4, 3)
        verifica.vero("Carta: stesso nome e data diversa non è un doppione",
                      MotoreCartaIdentita.clienteGiaPresente(f, clienti: [altraData]) == nil)
    }
}
