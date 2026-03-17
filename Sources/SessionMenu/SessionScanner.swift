import Foundation

protocol SessionScanning: Sendable {
    func scan() async throws -> [ActiveSession]
}

enum SessionScannerSupport {
    private static let trackedExecutables: Set<String> = [
        "kubectl",
        "mosh-client",
        "psql",
        "scp",
        "sftp",
        "ssh",
    ]

    private static let knownTerminalNames: [String: String] = [
        "alacritty": "Alacritty",
        "ghostty": "Ghostty",
        "hyper": "Hyper",
        "iterm2": "iTerm2",
        "kitty": "Kitty",
        "terminal": "Terminal",
        "warp": "Warp",
        "wezterm": "WezTerm",
    ]

    static func candidateProcesses(from processes: [ProcessSnapshot]) -> [ProcessSnapshot] {
        processes.filter {
            $0.tty != "??" && trackedExecutables.contains($0.executableName.lowercased())
        }
    }

    static func terminalName(for process: ProcessSnapshot, byPID: [Int32: ProcessSnapshot]) -> String {
        var current = process
        var seen = Set<Int32>()

        while seen.insert(current.pid).inserted, let parent = byPID[current.parentPID] {
            let normalized = parent.executableName.lowercased()
            if let name = knownTerminalNames[normalized] {
                return name
            }

            let fullCommand = parent.commandLine.lowercased()
            if let match = knownTerminalNames.first(where: { fullCommand.contains($0.key) }) {
                return match.value
            }

            current = parent
        }

        return process.tty
    }
}

protocol ShellRunning: Sendable {
    func run(_ executable: String, args: [String]) async throws -> String
}

final class PipeBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    func snapshot() -> Data {
        lock.lock()
        let copy = data
        lock.unlock()
        return copy
    }
}

struct LiveShellRunner: ShellRunning {
    func run(_ executable: String, args: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()
            let stdoutBuffer = PipeBuffer()
            let stderrBuffer = PipeBuffer()
            let readGroup = DispatchGroup()

            process.executableURL = URL(filePath: executable)
            process.arguments = args
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                readGroup.enter()
                readGroup.enter()

                stdout.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if data.isEmpty {
                        handle.readabilityHandler = nil
                        readGroup.leave()
                        return
                    }

                    stdoutBuffer.append(data)
                }

                stderr.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if data.isEmpty {
                        handle.readabilityHandler = nil
                        readGroup.leave()
                        return
                    }

                    stderrBuffer.append(data)
                }

                try process.run()
                process.terminationHandler = { process in
                    process.waitUntilExit()
                    readGroup.wait()

                    let data = stdoutBuffer.snapshot()
                    let errorData = stderrBuffer.snapshot()

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: String(decoding: data, as: UTF8.self))
                    } else {
                        let message = String(decoding: errorData, as: UTF8.self)
                        continuation.resume(throwing: NSError(domain: "SessionMenu", code: Int(process.terminationStatus), userInfo: [
                            NSLocalizedDescriptionKey: message.isEmpty ? "Command failed: \(executable)" : message
                        ]))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

struct SessionScanner: SessionScanning {
    private let shellRunner: any ShellRunning

    init(shellRunner: any ShellRunning = LiveShellRunner()) {
        self.shellRunner = shellRunner
    }

    func scan() async throws -> [ActiveSession] {
        let psOutput = try await shellRunner.run(
            "/bin/ps",
            args: ["-ax", "-o", "pid=", "-o", "ppid=", "-o", "tty=", "-o", "etimes=", "-o", "command="]
        )
        let processes = try ProcessSnapshotParser.parsePS(psOutput)
        let candidates = SessionScannerSupport.candidateProcesses(from: processes)
        guard !candidates.isEmpty else {
            return []
        }

        let pidList = candidates.map(\.pid).map(String.init).joined(separator: ",")
        async let connectionsOutput = shellRunner.run(
            "/usr/sbin/lsof",
            args: ["-a", "-n", "-P", "-p", pidList, "-i"]
        )
        async let cwdOutput = shellRunner.run(
            "/usr/sbin/lsof",
            args: ["-a", "-p", pidList, "-d", "cwd", "-Fn"]
        )

        let connections = (try? ProcessSnapshotParser.parseLSOF(try await connectionsOutput)) ?? []
        let workingDirectories = (try? parseWorkingDirectories(from: try await cwdOutput)) ?? [:]

        let processByPID = Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0) })
        let connectionsByPID = Dictionary(grouping: connections, by: \.pid)

        return candidates.compactMap { process in
            let terminalName = SessionScannerSupport.terminalName(for: process, byPID: processByPID)
            let processConnections = connectionsByPID[process.pid] ?? []
            return SessionClassifier.classify(
                process: process,
                terminalName: terminalName,
                workingDirectory: workingDirectories[process.pid],
                connections: processConnections
            )
        }
        .sorted { lhs, rhs in
            if lhs.terminalName == rhs.terminalName {
                return lhs.elapsedSeconds > rhs.elapsedSeconds
            }
            return lhs.terminalName < rhs.terminalName
        }
    }

    private func parseWorkingDirectories(from output: String) throws -> [Int32: String] {
        var result: [Int32: String] = [:]
        var currentPID: Int32?

        for line in output.split(separator: "\n") {
            if line.hasPrefix("p"), let pid = Int32(line.dropFirst()) {
                currentPID = pid
            } else if line.hasPrefix("n"), let pid = currentPID {
                result[pid] = String(line.dropFirst())
            }
        }

        return result
    }
}
