import SwiftUI

struct LobbyInviteNameField: View {
    let editor: LobbyNameEditorModel
    @Binding var displayName: String
    let canSaveDisplayName: Bool
    let saveDisplayName: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
            Text("Playing as")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper)

            HStack(spacing: GameTheme.inlineSpacing) {
                TextField(
                    editor.title,
                    text: $displayName,
                    prompt: Text(editor.placeholder)
                        .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.62))
                )
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .font(GameTheme.bodyFont)
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .tint(GameTheme.accent)
                .onSubmit {
                    if canSaveDisplayName {
                        saveDisplayName()
                    }
                }

                if let saveButton = editor.saveButton {
                    Button(saveButton.title, systemImage: saveButton.systemImage, action: saveDisplayName)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(GameTheme.ink)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(GameTheme.accent)
                        }
                        .disabled(!canSaveDisplayName)
                        .opacity(canSaveDisplayName ? 1 : 0.45)
                        .accessibilityIdentifier("uls.lobby.action.\(saveButton.title)")
                }
            }
            .padding(.leading, GameTheme.compactPadding)
            .padding(.trailing, editor.saveButton == nil ? GameTheme.compactPadding : 4)
            .frame(minHeight: 48)
            .background {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(GameTheme.felt)
            }
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(LobbyInvitePalette.mutedPaper.opacity(0.34), lineWidth: 1)
            }
            .accessibilityIdentifier("uls.lobby.nameField")

            if !editor.helperText.isEmpty {
                Text(editor.helperText)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
