import Foundation
import Testing
@testable import SessionMenu

@MainActor
struct SessionStoreTests {
    @Test
    func keepsNewestRefreshResult() async throws {
        let first = ActiveSession(
            pid: 1,
            terminalName: "Terminal",
            kind: .ssh,
            title: "SSH",
            target: "old-host",
            subtitle: "",
            commandLine: "ssh old-host",
            workingDirectory: nil,
            tty: "ttys001",
            elapsedSeconds: 10,
            connections: []
        )

        let second = ActiveSession(
            pid: 2,
            terminalName: "Ghostty",
            kind: .ssh,
            title: "SSH",
            target: "new-host",
            subtitle: "",
            commandLine: "ssh new-host",
            workingDirectory: nil,
            tty: "ttys002",
            elapsedSeconds: 5,
            connections: []
        )

        let scanner = SequencedScanner(results: [
            .success([first], delayNanoseconds: 200_000_000),
            .success([second], delayNanoseconds: 20_000_000),
        ])
        let store = SessionStore(scanner: scanner)

        async let firstRefresh: Void = store.refresh()
        async let secondRefresh: Void = store.refresh()
        _ = await (firstRefresh, secondRefresh)

        #expect(store.sessions.map { $0.target } == ["new-host"])
    }

    @Test
    func preservesLastSessionsOnRefreshFailure() async {
        let existing = ActiveSession(
            pid: 3,
            terminalName: "Terminal",
            kind: .database,
            title: "Postgres",
            target: "db.internal",
            subtitle: "analytics",
            commandLine: "psql postgresql://db.internal/analytics",
            workingDirectory: nil,
            tty: "ttys003",
            elapsedSeconds: 15,
            connections: []
        )

        let scanner = SequencedScanner(results: [
            .success([existing], delayNanoseconds: 0),
            .failure("lsof failed", delayNanoseconds: 0),
        ])
        let store = SessionStore(scanner: scanner)

        await store.refresh()
        #expect(store.sessions.count == 1)

        await store.refresh()
        #expect(store.sessions.map { $0.target } == ["db.internal"])
        #expect(store.errorMessage == "lsof failed")
    }
}

private actor SequencedScanner: SessionScanning {
    struct Step {
        let result: Result<[ActiveSession], Error>
        let delayNanoseconds: UInt64

        static func success(_ sessions: [ActiveSession], delayNanoseconds: UInt64) -> Step {
            Step(result: .success(sessions), delayNanoseconds: delayNanoseconds)
        }

        static func failure(_ message: String, delayNanoseconds: UInt64) -> Step {
            Step(
                result: .failure(NSError(domain: "SessionStoreTests", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: message
                ])),
                delayNanoseconds: delayNanoseconds
            )
        }
    }

    private var results: [Step]

    init(results: [Step]) {
        self.results = results
    }

    func scan() async throws -> [ActiveSession] {
        let step = results.removeFirst()
        if step.delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: step.delayNanoseconds)
        }
        return try step.result.get()
    }
}
