import Foundation
import Testing
@testable import SessionMenu

struct SessionScannerTests {
    @Test
    func buildsActiveSessionsFromShellOutput() async throws {
        let shell = StubShellRunner(outputs: [
            "/bin/ps|-ax|-o|pid=|-o|ppid=|-o|tty=|-o|etimes=|-o|command=": """
              1     0 ??       500 /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal
             10     1 ttys001  200 /bin/zsh -l
             20    10 ttys001  120 ssh isaac@example.com
             21    10 ttys001   80 node dev-server.js
            """,
            "/usr/sbin/lsof|-a|-n|-P|-p|20|-i": """
            COMMAND PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
            ssh      20 isaac   3u  IPv4 0x1234567890abcdef      0t0  TCP 10.0.0.2:56123->192.168.1.15:22 (ESTABLISHED)
            """,
            "/usr/sbin/lsof|-a|-p|20|-d|cwd|-Fn": """
            p20
            n/Users/isaac/bax-app
            """
        ])

        let scanner = SessionScanner(shellRunner: shell)
        let sessions = try await scanner.scan()

        #expect(sessions.count == 1)
        #expect(sessions[0].terminalName == "Terminal")
        #expect(sessions[0].target == "isaac@example.com")
        #expect(sessions[0].workingDirectory == "/Users/isaac/bax-app")
        #expect(sessions[0].connections.first?.remoteEndpoint == "192.168.1.15:22")
    }
}

private struct StubShellRunner: ShellRunning {
    let outputs: [String: String]

    func run(_ executable: String, args: [String]) async throws -> String {
        let key = ([executable] + args).joined(separator: "|")
        guard let output = outputs[key] else {
            throw NSError(domain: "SessionMenuTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing stub for \(key)"
            ])
        }
        return output
    }
}
