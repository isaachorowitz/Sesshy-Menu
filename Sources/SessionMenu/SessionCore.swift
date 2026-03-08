import Foundation

struct ProcessSnapshot: Equatable, Sendable {
    let pid: Int32
    let parentPID: Int32
    let tty: String
    let elapsedSeconds: Int
    let commandLine: String

    var executableName: String {
        let token = arguments.first ?? commandLine
        return URL(filePath: token).lastPathComponent
    }

    var arguments: [String] {
        shellSplit(commandLine)
    }
}

struct SocketConnection: Equatable, Sendable {
    let pid: Int32
    let localEndpoint: String
    let remoteEndpoint: String
    let state: String
}

enum SessionKind: String, Equatable, Sendable {
    case ssh
    case database
    case tunnel
    case cloud
    case generic
}

struct ActiveSession: Identifiable, Equatable, Sendable {
    let pid: Int32
    let terminalName: String
    let kind: SessionKind
    let title: String
    let target: String
    let subtitle: String
    let commandLine: String
    let workingDirectory: String?
    let tty: String
    let elapsedSeconds: Int
    let connections: [SocketConnection]

    var id: String {
        "\(pid):\(tty)"
    }
}

enum ProcessSnapshotParser {
    static func parsePS(_ output: String) throws -> [ProcessSnapshot] {
        output
            .split(separator: "\n")
            .compactMap { line in
                let parts = line.split(separator: " ", maxSplits: 4, omittingEmptySubsequences: true)
                guard parts.count == 5,
                      let pid = Int32(parts[0]),
                      let parentPID = Int32(parts[1]),
                      let elapsedSeconds = Int(parts[3])
                else {
                    return nil
                }

                return ProcessSnapshot(
                    pid: pid,
                    parentPID: parentPID,
                    tty: String(parts[2]),
                    elapsedSeconds: elapsedSeconds,
                    commandLine: String(parts[4])
                )
            }
    }

    static func parseLSOF(_ output: String) throws -> [SocketConnection] {
        output
            .split(separator: "\n")
            .dropFirst()
            .compactMap { line in
                let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                guard parts.count >= 10, let pid = Int32(parts[1]) else {
                    return nil
                }

                let stateToken = parts.last.map(String.init) ?? ""
                let state = stateToken.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                let nameIndex = stateToken.hasPrefix("(") ? parts.count - 2 : parts.count - 1
                let endpoint = String(parts[nameIndex])

                let remoteEndpoint: String
                let localEndpoint: String
                if let arrowRange = endpoint.range(of: "->") {
                    localEndpoint = String(endpoint[..<arrowRange.lowerBound])
                    remoteEndpoint = String(endpoint[arrowRange.upperBound...])
                } else {
                    localEndpoint = endpoint
                    remoteEndpoint = endpoint
                }

                return SocketConnection(
                    pid: pid,
                    localEndpoint: localEndpoint,
                    remoteEndpoint: remoteEndpoint,
                    state: state
                )
            }
    }
}

enum SessionClassifier {
    static func classify(
        process: ProcessSnapshot,
        terminalName: String,
        workingDirectory: String?,
        connections: [SocketConnection]
    ) -> ActiveSession? {
        let executable = process.executableName.lowercased()
        if ["ssh", "sftp", "scp", "mosh-client"].contains(executable) {
            let target = firstConnectionTarget(in: process.arguments) ?? executable
            return ActiveSession(
                pid: process.pid,
                terminalName: terminalName,
                kind: .ssh,
                title: "SSH",
                target: target,
                subtitle: connections.first?.remoteEndpoint ?? "",
                commandLine: process.commandLine,
                workingDirectory: workingDirectory,
                tty: process.tty,
                elapsedSeconds: process.elapsedSeconds,
                connections: connections
            )
        }

        if executable == "kubectl", let session = classifyKubectl(process: process, terminalName: terminalName, workingDirectory: workingDirectory, connections: connections) {
            return session
        }

        if executable == "psql" {
            let parsed = parsePostgresTarget(from: process.arguments)
            return ActiveSession(
                pid: process.pid,
                terminalName: terminalName,
                kind: .database,
                title: "Postgres",
                target: parsed.host,
                subtitle: parsed.database,
                commandLine: process.commandLine,
                workingDirectory: workingDirectory,
                tty: process.tty,
                elapsedSeconds: process.elapsedSeconds,
                connections: connections
            )
        }

        return nil
    }

    private static func classifyKubectl(
        process: ProcessSnapshot,
        terminalName: String,
        workingDirectory: String?,
        connections: [SocketConnection]
    ) -> ActiveSession? {
        guard let index = process.arguments.firstIndex(of: "port-forward"),
              process.arguments.indices.contains(index + 1)
        else {
            return nil
        }

        let target = process.arguments[index + 1]
        let mapping = process.arguments.dropFirst(index + 2).first(where: { $0.contains(":") }) ?? ""
        return ActiveSession(
            pid: process.pid,
            terminalName: terminalName,
            kind: .tunnel,
            title: "Port Forward",
            target: target,
            subtitle: mapping,
            commandLine: process.commandLine,
            workingDirectory: workingDirectory,
            tty: process.tty,
            elapsedSeconds: process.elapsedSeconds,
            connections: connections
        )
    }

    private static func firstConnectionTarget(in args: [String]) -> String? {
        let optionArgs = Set(["-i", "-p", "-l", "-J", "-F", "-o", "-S", "-W", "-L", "-R", "-D", "-b", "-c", "-E", "-m", "-Q", "-w"])
        var skipNext = false

        for token in args.dropFirst() {
            if skipNext {
                skipNext = false
                continue
            }
            if optionArgs.contains(token) {
                skipNext = true
                continue
            }
            if token.hasPrefix("-") {
                continue
            }
            return token
        }

        return nil
    }

    private static func parsePostgresTarget(from args: [String]) -> (host: String, database: String) {
        if let urlToken = args.dropFirst().first,
           urlToken.contains("://"),
           let components = URLComponents(string: urlToken) {
            let database = components.path.split(separator: "/").last.map(String.init) ?? ""
            return (components.host ?? "localhost", database)
        }

        var host = "localhost"
        var database = ""
        var iterator = args.dropFirst().makeIterator()

        while let token = iterator.next() {
            switch token {
            case "-h", "--host":
                host = iterator.next() ?? host
            case "-d", "--dbname":
                database = iterator.next() ?? database
            default:
                if !token.hasPrefix("-"), database.isEmpty {
                    database = token
                }
            }
        }

        return (host, database)
    }
}

private func shellSplit(_ commandLine: String) -> [String] {
    var results: [String] = []
    var current = ""
    var inSingleQuotes = false
    var inDoubleQuotes = false
    var isEscaping = false

    for character in commandLine {
        if isEscaping {
            current.append(character)
            isEscaping = false
            continue
        }

        if character == "\\" {
            isEscaping = true
            continue
        }

        if character == "'" && !inDoubleQuotes {
            inSingleQuotes.toggle()
            continue
        }

        if character == "\"" && !inSingleQuotes {
            inDoubleQuotes.toggle()
            continue
        }

        if character.isWhitespace && !inSingleQuotes && !inDoubleQuotes {
            if !current.isEmpty {
                results.append(current)
                current.removeAll(keepingCapacity: true)
            }
            continue
        }

        current.append(character)
    }

    if !current.isEmpty {
        results.append(current)
    }

    return results
}
