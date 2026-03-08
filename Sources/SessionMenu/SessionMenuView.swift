import SwiftUI

struct SessionMenuView: View {
    @Environment(SessionStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sesshy")
                        .font(.headline)
                    Text("\(store.sessions.count) active terminal connections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Refresh") {
                    Task {
                        await store.refresh()
                    }
                }
                .buttonStyle(.borderless)
            }

            Divider()

            if let errorMessage = store.errorMessage, store.sessions.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if store.sessions.isEmpty {
                Text("No active terminal logins, tunnels, or database sessions detected.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(store.sessions) { session in
                            SessionRow(session: session)
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
        }
        .frame(width: 360)
        .padding(12)
    }
}

private struct SessionRow: View {
    let session: ActiveSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(session.terminalName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(session.target)
                .font(.callout)
                .lineLimit(1)

            if !session.subtitle.isEmpty {
                Text(session.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                Label(session.tty, systemImage: "terminal")
                Text(formatElapsed(session.elapsedSeconds))
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)

            if let workingDirectory = session.workingDirectory, !workingDirectory.isEmpty {
                Text(workingDirectory)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

private func formatElapsed(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds)s"
    }

    let minutes = seconds / 60
    if minutes < 60 {
        return "\(minutes)m"
    }

    let hours = minutes / 60
    if hours < 24 {
        return "\(hours)h \(minutes % 60)m"
    }

    return "\(hours / 24)d \(hours % 24)h"
}
