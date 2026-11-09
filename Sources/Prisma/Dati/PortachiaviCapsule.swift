import Foundation

// Le chiavi delle capsule del tempo («Luce» giro 15, §3.4, decisione 42). Stub del giro 15·0: la parte 15c sostituisce il
// file (anello nel Portachiavi del Mac, chiavi nei soli backup protetti) senza cambiare `CapsuleNelBackup.installa()`,
// chiamata solo nell'«Avvio vero» di PrismaApp (mai nelle prove).
enum CapsuleNelBackup {
    /// All'avvio vero: le chiavi entrano nei backup protetti e tornano dal ripristino.
    static func installa() {}
}
