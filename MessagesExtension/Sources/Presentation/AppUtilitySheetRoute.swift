enum AppUtilitySheetRoute: String, Identifiable {
    case settings
    case tutorial
    case learning
    case playerRecord

    var id: String { rawValue }
}
