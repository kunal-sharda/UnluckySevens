import SwiftUI

struct LobbyInviteNameField: View {
    let editor: LobbyNameEditorModel
    @Binding var displayName: String
    let canSaveDisplayName: Bool
    let saveDisplayName: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
            Label(editor.title, systemImage: "person.fill")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GameTheme.ink)

            HStack(spacing: GameTheme.inlineSpacing) {
                TextField(
                    editor.title,
                    text: $displayName,
                    prompt: Text(editor.placeholder)
                        .foregroundStyle(GameTheme.mutedInk)
                )
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .font(GameTheme.bodyFont)
                .foregroundStyle(GameTheme.ink)
                .tint(GameTheme.outline)
                .onSubmit {
                    if canSaveDisplayName {
                        saveDisplayName()
                    }
                }

                if let saveButton = editor.saveButton {
                    Button(saveButton.title, systemImage: saveButton.systemImage, action: saveDisplayName)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(GamePhysicalTurnPalette.nameTileFill)
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
                    .fill(LobbyInvitePalette.controlSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(GameTheme.outline.opacity(0.48), lineWidth: 1)
            }
            .accessibilityIdentifier("uls.lobby.nameField")

            if !editor.helperText.isEmpty {
                Text(editor.helperText)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
