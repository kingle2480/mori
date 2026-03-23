import Foundation

/// SSH configuration for running git commands on a remote host.
public struct GitSSHConfig: Sendable {
    public let host: String
    public let user: String?
    public let port: Int?
    public let sshOptions: [String]
    /// Optional password used for password-auth control-master bootstrap.
    public let askpassPassword: String?

    public init(
        host: String,
        user: String? = nil,
        port: Int? = nil,
        sshOptions: [String] = [],
        askpassPassword: String? = nil
    ) {
        self.host = host
        self.user = user
        self.port = port
        self.sshOptions = sshOptions
        self.askpassPassword = askpassPassword
    }

    var target: String {
        if let user, !user.isEmpty {
            return "\(user)@\(host)"
        }
        return host
    }
}

/// Runs git commands via `Process` (Foundation).
/// Resolves the git binary path via PATH lookup with common fallback locations.
public actor GitCommandRunner {

    /// Cached path to the git binary, resolved on first use.
    private var resolvedBinaryPath: String?
    private let sshConfig: GitSSHConfig?

    public init(sshConfig: GitSSHConfig? = nil) {
        self.sshConfig = sshConfig
    }

    // MARK: - Binary Resolution

    /// Resolve the git binary path. Checks common locations first, then falls back to `which git`.
    public func resolveBinaryPath() async throws -> String {
        if sshConfig != nil {
            return "git"
        }
        if let cached = resolvedBinaryPath {
            return cached
        }

        let commonPaths = [
            "/opt/homebrew/bin/git",
            "/usr/local/bin/git",
            "/usr/bin/git",
        ]

        for path in commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                resolvedBinaryPath = path
                return path
            }
        }

        // Fall back to `which git`
        let (output, exitCode) = try await runProcess(
            executablePath: "/usr/bin/which",
            arguments: ["git"]
        )

        if exitCode == 0 {
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty {
                resolvedBinaryPath = path
                return path
            }
        }

        throw GitError.binaryNotFound
    }

    /// Check if git is available on this system.
    public func isAvailable() async -> Bool {
        if sshConfig != nil {
            do {
                _ = try await run(["--version"])
                return true
            } catch {
                return false
            }
        }
        do {
            _ = try await resolveBinaryPath()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Command Execution

    /// Run a git command with the given arguments. Returns stdout as a string.
    public func run(_ arguments: String...) async throws -> String {
        try await run(arguments)
    }

    /// Run a git command with the given arguments array. Returns stdout as a string.
    public func run(_ arguments: [String]) async throws -> String {
        if let sshConfig {
            let remoteCommand = (["git"] + arguments).map(Self.shellEscape).joined(separator: " ")
            var sshArguments: [String] = ["-o", "ConnectTimeout=8"]
            sshArguments += sshConfig.sshOptions
            if let port = sshConfig.port {
                sshArguments += ["-p", "\(port)"]
            }
            sshArguments += [sshConfig.target, remoteCommand]

            var (stdout, exitCode) = try await runProcess(
                executablePath: "/usr/bin/ssh",
                arguments: sshArguments
            )

            if exitCode == 255,
               let password = sshConfig.askpassPassword,
               !password.isEmpty {
                try await bootstrapPasswordControlMaster(sshConfig: sshConfig, password: password)
                (stdout, exitCode) = try await runProcess(
                    executablePath: "/usr/bin/ssh",
                    arguments: sshArguments
                )
            }

            if exitCode != 0 {
                let cmd = "ssh \(sshConfig.target) \(remoteCommand)"
                throw GitError.executionFailed(command: cmd, exitCode: exitCode, stderr: stdout)
            }

            return stdout
        }

        let binaryPath = try await resolveBinaryPath()
        let (stdout, exitCode) = try await runProcess(
            executablePath: binaryPath,
            arguments: arguments
        )

        if exitCode != 0 {
            let cmd = "git \(arguments.joined(separator: " "))"
            throw GitError.executionFailed(command: cmd, exitCode: exitCode, stderr: stdout)
        }

        return stdout
    }

    /// Run a git command in a specific working directory.
    public func run(in directory: String, _ arguments: [String]) async throws -> String {
        try await run(["-C", directory] + arguments)
    }

    // MARK: - Private

    private func runProcess(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil,
        stdinNull: Bool = false
    ) async throws -> (output: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            if let environment {
                process.environment = environment
            }
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            if stdinNull {
                process.standardInput = FileHandle.nullDevice
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }

            // Use terminationHandler to avoid blocking the cooperative thread pool
            process.terminationHandler = { _ in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                // Prefer stderr for error messages, fall back to stdout
                let output = stderr.isEmpty ? stdout : stderr
                continuation.resume(returning: (output, process.terminationStatus))
            }
        }
    }

    private func bootstrapPasswordControlMaster(
        sshConfig: GitSSHConfig,
        password: String
    ) async throws {
        let scriptPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("mori-askpass-\(UUID().uuidString).sh")
        let script = "#!/bin/sh\necho \"$MORI_SSH_PASSWORD\"\n"
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptPath)
        defer { try? FileManager.default.removeItem(atPath: scriptPath) }

        var args: [String] = ["-o", "ConnectTimeout=8"]
        args += Self.removingBatchMode(from: sshConfig.sshOptions)
        args += [
            "-o", "PreferredAuthentications=password,keyboard-interactive",
            "-o", "PubkeyAuthentication=no",
            "-o", "NumberOfPasswordPrompts=1",
        ]
        if let port = sshConfig.port {
            args += ["-p", "\(port)"]
        }
        args += [sshConfig.target, "exit"]

        var env = ProcessInfo.processInfo.environment
        env["SSH_ASKPASS"] = scriptPath
        env["SSH_ASKPASS_REQUIRE"] = "force"
        env["DISPLAY"] = "mori"
        env["MORI_SSH_PASSWORD"] = password

        let (output, exitCode) = try await runProcess(
            executablePath: "/usr/bin/ssh",
            arguments: args,
            environment: env,
            stdinNull: true
        )
        guard exitCode == 0 else {
            throw GitError.executionFailed(
                command: "ssh \(sshConfig.target) exit",
                exitCode: exitCode,
                stderr: output.isEmpty ? "SSH authentication failed." : output
            )
        }
    }

    private static func removingBatchMode(from options: [String]) -> [String] {
        var filtered: [String] = []
        var i = 0
        while i < options.count {
            if options[i] == "-o", i + 1 < options.count, options[i + 1].hasPrefix("BatchMode=") {
                i += 2
                continue
            }
            filtered.append(options[i])
            i += 1
        }
        return filtered
    }

    private static func shellEscape(_ value: String) -> String {
        if value.isEmpty {
            return "''"
        }
        let escaped = value.replacingOccurrences(of: "'", with: "'\"'\"'")
        return "'\(escaped)'"
    }
}
