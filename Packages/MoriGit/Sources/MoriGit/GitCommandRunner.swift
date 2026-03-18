import Foundation

/// Runs git commands via `Process` (Foundation).
/// Resolves the git binary path via PATH lookup with common fallback locations.
public actor GitCommandRunner {

    /// Cached path to the git binary, resolved on first use.
    private var resolvedBinaryPath: String?

    public init() {}

    // MARK: - Binary Resolution

    /// Resolve the git binary path. Checks common locations first, then falls back to `which git`.
    public func resolveBinaryPath() async throws -> String {
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
        arguments: [String]
    ) async throws -> (output: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

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
}
