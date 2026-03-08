import Testing
@testable import SessionMenu

struct ScannerSupportTests {
    @Test
    func resolvesTerminalAncestorName() {
        let processes = [
            ProcessSnapshot(pid: 1, parentPID: 0, tty: "??", elapsedSeconds: 500, commandLine: "/System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal"),
            ProcessSnapshot(pid: 10, parentPID: 1, tty: "ttys001", elapsedSeconds: 300, commandLine: "/bin/zsh -l"),
            ProcessSnapshot(pid: 20, parentPID: 10, tty: "ttys001", elapsedSeconds: 120, commandLine: "ssh isaac@example.com"),
        ]

        let terminalName = SessionScannerSupport.terminalName(for: processes[2], in: processes)

        #expect(terminalName == "Terminal")
    }

    @Test
    func filtersToTTYBackedCandidateProcesses() {
        let processes = [
            ProcessSnapshot(pid: 10, parentPID: 1, tty: "ttys001", elapsedSeconds: 300, commandLine: "ssh isaac@example.com"),
            ProcessSnapshot(pid: 11, parentPID: 1, tty: "??", elapsedSeconds: 300, commandLine: "ssh isaac@example.com"),
            ProcessSnapshot(pid: 12, parentPID: 1, tty: "ttys002", elapsedSeconds: 300, commandLine: "node server.js"),
            ProcessSnapshot(pid: 13, parentPID: 1, tty: "ttys003", elapsedSeconds: 300, commandLine: "psql postgresql://db.internal/app"),
        ]

        let filtered = SessionScannerSupport.candidateProcesses(from: processes)

        #expect(filtered.map(\.pid) == [10, 13])
    }
}
