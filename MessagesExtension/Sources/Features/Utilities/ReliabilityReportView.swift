import SwiftUI

struct ReliabilityReportView: View {
    let load: () -> Data?
    let clear: () -> Bool
    let storageUnavailable: () -> Bool
    @State private var preview: Data?
    @State private var exportsFile = false
    @State private var confirmsClear = false
    @State private var status: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Reliability Report")
                    .font(.title2.bold())
                Text("This device keeps up to 128 recent diagnostic events for 24 hours. The report below includes only the open game, app and OS versions, and game-state fingerprints. It excludes names, messages, contacts and private cards. Nothing is uploaded automatically.")
                    .font(.callout)
                Text("Each player exports their own report after opening the latest game update. A local send result does not confirm another player received it.")
                    .font(.callout)
                if let preview, let text = String(data: preview, encoding: .utf8) {
                    Button("Export This Report", systemImage: "square.and.arrow.up") {
                        exportsFile = true
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("uls.reliability.export")
                    Text("Exact report contents")
                        .font(.headline)
                    Text(text)
                        .font(.caption)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("uls.reliability.preview")
                } else {
                    Text("Open a game bubble to preview its report. No report is available here.")
                        .accessibilityIdentifier("uls.reliability.empty")
                }
                if let status {
                    Text(status)
                        .font(.callout)
                        .accessibilityIdentifier("uls.reliability.status")
                }
                Button("Clear Local Reports", systemImage: "trash", role: .destructive) {
                    confirmsClear = true
                }
                .frame(minHeight: 44)
                .accessibilityIdentifier("uls.reliability.clear")
                Text("Clearing removes this device’s diagnostic history for all games. It does not change games or files you already exported.")
                    .font(.footnote)
            }
            .padding(16)
            .foregroundStyle(GameTheme.surface)
        }
        .background(GameTheme.feltRaised)
        .navigationTitle("Reliability Report")
        .toolbar(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(GameTheme.feltRaised, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("uls.reliability.surface")
        .onAppear {
            preview = load()
            if storageUnavailable() {
                status = "Local storage is unavailable. This report may contain only events from this session."
            }
        }
        .confirmationDialog("Clear all local diagnostic history?", isPresented: $confirmsClear) {
            Button("Clear Local Reports", role: .destructive) {
                let cleared = clear()
                preview = nil
                status = cleared ? "Local diagnostic history cleared." : "History cleared from memory, but deletion from storage could not be confirmed."
            }
            Button("Cancel", role: .cancel) {}
        }
        .fileExporter(
            isPresented: $exportsFile,
            document: preview.map(ReliabilityReportDocument.init(data:)),
            contentType: .json,
            defaultFilename: "Unlucky-Sevens-Report"
        ) { result in
            switch result {
            case .success:
                status = "Report saved to the location you selected."
            case .failure:
                status = "The report could not be saved. You can try exporting again."
            }
        }
    }
}
