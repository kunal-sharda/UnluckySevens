import ULS_CoreGame

struct GameScreenContext {
    let selectedState: CoreGameStateV1?
    let actingAs: String?
    let contextBanner: String
    let contextMeta: String
    let actionAvailability: GameActionAvailability
}
