import SwiftUI

struct LobbyTableCardView: View {
    let model: LobbyScreenModel
    @Binding var displayNameDraft: String
    let canSaveDisplayName: Bool
    let showRules: () -> Void
    let invite: () -> Void
    let join: () -> Void
    let saveDisplayName: () -> Void
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            brandBar
            titleBlock

            if let warningText = model.warningText {
                warning(text: warningText)
            }

            LobbySeatTableView(model: model)

            if let nameEditor = model.nameEditor {
                nameEditorView(nameEditor)
            }

            primaryAction
            footer
        }
        .accessibilityIdentifier("uls.lobby.tableSurface")
    }

    private var brandBar: some View {
        HStack(spacing: 10) {
            LobbyTableMark()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("Unlucky Sevens")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(LobbyPalette.cream)

                Label(statusLabel, systemImage: statusSystemImage)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(LobbyPalette.mutedCream)
            }

            Spacer(minLength: 8)

            Button("Game rules", systemImage: "questionmark", action: showRules)
                .labelStyle(.iconOnly)
                .font(.body.bold())
                .foregroundStyle(LobbyPalette.cream)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .overlay(Circle().stroke(LobbyPalette.openSeatEdge, lineWidth: 1))
                .buttonStyle(.plain)
                .accessibilityIdentifier("uls.lobby.rulesHelp")
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.title)
                .font(GameTheme.displayFont)
                .foregroundStyle(LobbyPalette.cream)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(model.showsInviteEntryHero ? "uls.lobby.inviteTitle" : "uls.lobby.title")

            Text(model.subtitle)
                .font(GameTheme.bodyFont)
                .foregroundStyle(LobbyPalette.mutedCream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func nameEditorView(_ editor: LobbyNameEditorModel) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(editor.title)
                .font(GameTheme.chipFont)
                .foregroundStyle(LobbyPalette.mutedCream)

            HStack(spacing: 8) {
                TextField(
                    "",
                    text: $displayNameDraft,
                    prompt: Text(editor.placeholder).foregroundStyle(LobbyPalette.mutedCream)
                )
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .font(GameTheme.bodyFont.bold())
                .foregroundStyle(LobbyPalette.cream)
                .tint(LobbyPalette.cream)
                .onSubmit(submitNameIfPossible)
                .accessibilityIdentifier("uls.lobby.nameField")

                if let saveButton = editor.saveButton {
                    Button(saveButton.title, systemImage: saveButton.systemImage, action: saveDisplayName)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(LobbyPalette.cream)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(LobbyPalette.moss))
                        .disabled(!canSaveDisplayName)
                        .opacity(canSaveDisplayName ? 1 : 0.42)
                        .accessibilityIdentifier("uls.lobby.action.\(saveButton.title)")
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.black.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(LobbyPalette.openSeatEdge, lineWidth: 1)
            )

            Text(editor.helperText)
                .font(GameTheme.metaFont)
                .foregroundStyle(LobbyPalette.mutedCream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        if let button = model.joinButton {
            actionButton(button, tint: LobbyPalette.clay, action: join)
        } else if let button = model.startButton {
            actionButton(button, tint: LobbyPalette.moss, action: start)
        } else if let button = model.inviteButton {
            actionButton(button, tint: LobbyPalette.clay, action: invite)
        }
    }

    private func actionButton(
        _ button: LobbyActionButtonModel,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(button.title, systemImage: button.systemImage)
                .font(GameTheme.headingFont)
                .foregroundStyle(LobbyPalette.cream)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.black.opacity(0.24), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!button.isEnabled)
        .opacity(button.isEnabled ? 1 : 0.5)
        .accessibilityHint(button.isEnabled ? "" : "Action unavailable in the current lobby state")
        .accessibilityIdentifier("uls.lobby.action.\(button.title)")
    }

    @ViewBuilder
    private var footer: some View {
        if model.startButton != nil {
            Label {
                Text("Starting locks these seats and hands the table to initial placement.")
            } icon: {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(LobbyPalette.moss)
            }
            .font(GameTheme.metaFont)
            .foregroundStyle(LobbyPalette.mutedCream)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("uls.lobby.setupHandoff")
        } else {
            Text(model.helperText)
                .font(GameTheme.metaFont)
                .foregroundStyle(LobbyPalette.mutedCream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func warning(text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(GameTheme.metaFont)
            .foregroundStyle(LobbyPalette.cream)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LobbyPalette.clay.opacity(0.34))
            .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func submitNameIfPossible() {
        if canSaveDisplayName {
            saveDisplayName()
        }
    }

    private var statusLabel: String {
        if model.startButton != nil { return "Table ready" }
        if model.joinButton != nil { return "Invitation received" }
        if model.showsInviteEntryHero { return "New table" }
        if model.participants.isEmpty { return "Invitation sent" }
        return "Lobby open"
    }

    private var statusSystemImage: String {
        if model.startButton != nil { return "checkmark.seal.fill" }
        if model.joinButton != nil { return "envelope.open.fill" }
        if model.showsInviteEntryHero { return "plus.message.fill" }
        if model.participants.isEmpty { return "ellipsis.message.fill" }
        return "person.2.fill"
    }
}
