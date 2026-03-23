import Foundation
import MoriCore

enum SSHControlOptions {
    static let controlPersist = "8h"

    static func controlPath(for ssh: SSHWorkspaceLocation) -> String {
        let allowed = CharacterSet.alphanumerics
        let sanitized = String(
            ssh.endpointKey.unicodeScalars.map { scalar in
                allowed.contains(scalar) ? Character(scalar) : "_"
            }
        )
        let suffix = String(sanitized.prefix(32))
        return (NSTemporaryDirectory() as NSString).appendingPathComponent("mori_ssh_\(suffix).sock")
    }

    static func sshOptions(for ssh: SSHWorkspaceLocation) -> [String] {
        [
            "-o", "BatchMode=yes",
            "-o", "ControlMaster=auto",
            "-o", "ControlPersist=\(controlPersist)",
            "-o", "ControlPath=\(controlPath(for: ssh))",
        ]
    }
}

enum SSHBootstrapError: LocalizedError {
    case passwordRequired
    case processFailed(String)

    var errorDescription: String? {
        switch self {
        case .passwordRequired:
            return "Password is required for password authentication."
        case .processFailed(let message):
            return message
        }
    }
}

enum SSHBootstrapper {
    static func bootstrapPasswordSession(
        ssh: SSHWorkspaceLocation,
        password: String?
    ) async throws {
        guard let password, !password.isEmpty else {
            throw SSHBootstrapError.passwordRequired
        }

        let scriptPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("mori-askpass-\(UUID().uuidString).sh")
        let script = "#!/bin/sh\necho \"$MORI_SSH_PASSWORD\"\n"
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptPath)
        defer { try? FileManager.default.removeItem(atPath: scriptPath) }

        var args: [String] = [
            "-o", "ConnectTimeout=8",
            "-o", "ControlMaster=auto",
            "-o", "ControlPersist=\(SSHControlOptions.controlPersist)",
            "-o", "ControlPath=\(SSHControlOptions.controlPath(for: ssh))",
            "-o", "PreferredAuthentications=password,keyboard-interactive",
            "-o", "PubkeyAuthentication=no",
            "-o", "NumberOfPasswordPrompts=1",
        ]
        if let port = ssh.port {
            args += ["-p", "\(port)"]
        }
        args += [ssh.target, "exit"]

        var environment = ProcessInfo.processInfo.environment
        environment["SSH_ASKPASS"] = scriptPath
        environment["SSH_ASKPASS_REQUIRE"] = "force"
        environment["DISPLAY"] = "mori"
        environment["MORI_SSH_PASSWORD"] = password

        let (stdout, stderr, code) = try await runProcess(
            executablePath: "/usr/bin/ssh",
            arguments: args,
            environment: environment
        )

        if code != 0 {
            let message = stderr.isEmpty ? stdout : stderr
            throw SSHBootstrapError.processFailed(message.isEmpty ? "SSH authentication failed." : message)
        }
    }

    private static func runProcess(
        executablePath: String,
        arguments: [String],
        environment: [String: String]
    ) async throws -> (stdout: String, stderr: String, code: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            process.environment = environment
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.standardInput = FileHandle.nullDevice

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }

            process.terminationHandler = { _ in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                continuation.resume(returning: (stdout, stderr, process.terminationStatus))
            }
        }
    }
}
