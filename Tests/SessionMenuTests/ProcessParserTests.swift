import Testing
@testable import SessionMenu

struct ProcessParserTests {
    @Test
    func parsesPSOutputRows() throws {
        let output = """
          100     1 ttys001    120 /usr/bin/ssh ssh user@example.com
          200   100 ttys001     25 /usr/bin/psql psql postgresql://db.internal/app
        """

        let processes = try ProcessSnapshotParser.parsePS(output)

        #expect(processes.count == 2)
        #expect(processes[0].pid == 100)
        #expect(processes[0].parentPID == 1)
        #expect(processes[0].tty == "ttys001")
        #expect(processes[0].elapsedSeconds == 120)
        #expect(processes[0].executableName == "ssh")
        #expect(processes[1].executableName == "psql")
    }

    @Test
    func parsesLsofConnectionRows() throws {
        let output = """
        COMMAND PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        ssh     100 dev     3u  IPv4 0x1234567890abcdef      0t0  TCP 10.0.0.2:56123->192.168.1.15:22 (ESTABLISHED)
        psql    200 dev     4u  IPv4 0xabcdef1234567890      0t0  TCP 10.0.0.2:56124->db.internal:5432 (ESTABLISHED)
        """

        let connections = try ProcessSnapshotParser.parseLSOF(output)

        #expect(connections.count == 2)
        #expect(connections[0].pid == 100)
        #expect(connections[0].remoteEndpoint == "192.168.1.15:22")
        #expect(connections[0].state == "ESTABLISHED")
        #expect(connections[1].pid == 200)
        #expect(connections[1].remoteEndpoint == "db.internal:5432")
    }
}
