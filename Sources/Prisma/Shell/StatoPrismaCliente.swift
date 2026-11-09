import Foundation

// Il Prisma del cliente nello stato della shell («Luce» giro 15, §2.1). Stub del giro 15·0: la parte 15a sostituisce il
// file (preparazione del PDF protetto e dell'HTML, Messaggi, voci aggiunte dalla Sala) senza cambiare queste due firme,
// usate dal pulsante «✦ Aggiungi al Prisma di …» del palco (Shell/AppSala.swift).
extension StatoShell {
    /// «✦ Aggiungi al Prisma di …»: accende la voce dell'esperienza nel prossimo file del cliente.
    func aggiungiAlPrismaCliente(_ e: EsperienzaSala, cliente: Cliente) {}

    /// La voce dell'esperienza è già nel prossimo file del cliente («✓ Nel Prisma di …»).
    func voceAggiunta(_ e: EsperienzaSala, cliente: Cliente) -> Bool { false }
}
