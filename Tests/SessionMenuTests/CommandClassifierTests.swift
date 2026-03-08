import Testing
@testable import SessionMenu

struct CommandClassifierTests {
    @Test
    func classifiesSSHHostTarget() {
        let process = ProcessSnapshot(
            pid: 101,
            parentPID: 1,
            tty: "ttys001",
            elapsedSeconds: 120,
            commandLine: "ssh -i ~/.ssh/id_ed25519 user@example.com"
        )

        let session = SessionClassifier.classify(
            process: process,
            terminalName: "Ghostty",
            workingDirectory: "/Users/dev/my-app",
            connections: []
        )

        #expect(session?.kind == .ssh)
        #expect(session?.target == "user@example.com")
        #expect(session?.title == "SSH")
    }

    @Test
    func classifiesSSHHostTargetWhenRemoteCommandIsPresent() {
        let process = ProcessSnapshot(
            pid: 104,
            parentPID: 1,
            tty: "ttys004",
            elapsedSeconds: 120,
            commandLine: "ssh user@example.com tail -f /var/log/app.log"
        )

        let session = SessionClassifier.classify(
            process: process,
            terminalName: "Ghostty",
            workingDirectory: "/Users/dev/my-app",
            connections: []
        )

        #expect(session?.kind == .ssh)
        #expect(session?.target == "user@example.com")
    }

    @Test
    func classifiesSSHHostTargetWithQuotedOptionValue() {
        let process = ProcessSnapshot(
            pid: 106,
            parentPID: 1,
            tty: "ttys006",
            elapsedSeconds: 120,
            commandLine: #"ssh -o ProxyCommand="ssh -W %h:%p bastion" prod"#
        )

        let session = SessionClassifier.classify(
            process: process,
            terminalName: "Ghostty",
            workingDirectory: "/Users/dev/my-app",
            connections: []
        )

        #expect(session?.kind == .ssh)
        #expect(session?.target == "prod")
    }

    @Test
    func classifiesKubectlPortForward() {
        let process = ProcessSnapshot(
            pid: 102,
            parentPID: 1,
            tty: "ttys002",
            elapsedSeconds: 60,
            commandLine: "kubectl port-forward deployment/api 5432:5432 -n production"
        )

        let session = SessionClassifier.classify(
            process: process,
            terminalName: "iTerm2",
            workingDirectory: "/Users/dev/my-app",
            connections: []
        )

        #expect(session?.kind == .tunnel)
        #expect(session?.target == "deployment/api")
        #expect(session?.subtitle == "5432:5432")
    }

    @Test
    func classifiesPostgresConnectionFromURL() {
        let process = ProcessSnapshot(
            pid: 103,
            parentPID: 1,
            tty: "ttys003",
            elapsedSeconds: 180,
            commandLine: "psql postgresql://user@db.internal:5432/analytics"
        )

        let session = SessionClassifier.classify(
            process: process,
            terminalName: "Terminal",
            workingDirectory: "/Users/dev/my-app",
            connections: []
        )

        #expect(session?.kind == .database)
        #expect(session?.target == "db.internal")
        #expect(session?.subtitle == "analytics")
    }

    @Test
    func classifiesPostgresConnectionFromFlags() {
        let process = ProcessSnapshot(
            pid: 105,
            parentPID: 1,
            tty: "ttys005",
            elapsedSeconds: 180,
            commandLine: "psql -h db.internal -d analytics"
        )

        let session = SessionClassifier.classify(
            process: process,
            terminalName: "Terminal",
            workingDirectory: "/Users/dev/my-app",
            connections: []
        )

        #expect(session?.kind == .database)
        #expect(session?.target == "db.internal")
        #expect(session?.subtitle == "analytics")
    }
}
