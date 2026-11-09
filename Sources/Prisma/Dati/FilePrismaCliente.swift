import Foundation

// Il file del Prisma del cliente («Luce» giro 15, §2.1: HTML cifrato, spento finché la prova su iPhone e Android veri non
// passa). Stub del giro 15·0: la parte 15a sostituisce il file (cifratura AES-GCM, lettore JavaScript) senza cambiare
// `verificaRisorse()`, chiamata da `Risorse.verifica()`.
enum FilePrismaCliente {
    /// Per `Prisma --verifica-risorse`: nil = le risorse del lettore ci sono.
    static func verificaRisorse() -> String? { nil }
}
