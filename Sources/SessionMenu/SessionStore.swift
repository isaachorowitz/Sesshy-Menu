import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    var sessions: [ActiveSession] = []
    var errorMessage: String?

    @ObservationIgnored private let scanner: any SessionScanning
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var refreshGeneration = 0

    init(scanner: any SessionScanning = SessionScanner()) {
        self.scanner = scanner
    }

    func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration

        do {
            let nextSessions = try await scanner.scan()
            guard generation == refreshGeneration else { return }
            if nextSessions != sessions { sessions = nextSessions }
            errorMessage = nil
        } catch {
            guard generation == refreshGeneration else { return }
            errorMessage = error.localizedDescription
        }
    }
}
