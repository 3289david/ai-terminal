import Foundation
import CPty

final class PTYService {
    private var masterFD: Int32 = -1
    private var childPID: pid_t = -1
    private var readSource: DispatchSourceRead?
    private var outputHandler: ((Data) -> Void)?
    private var exitHandler: (() -> Void)?
    private let queue = DispatchQueue(label: "com.aiterminal.pty", qos: .userInteractive)

    var isRunning: Bool { childPID > 0 }

    // MARK: - Lifecycle

    func start(
        shell: String = "/bin/zsh",
        rows: UInt16 = 24,
        cols: UInt16 = 80,
        workingDirectory: String,
        onOutput: @escaping (Data) -> Void,
        onExit: @escaping () -> Void
    ) {
        outputHandler = onOutput
        exitHandler = onExit

        var fd: Int32 = 0
        let pid = pty_start(&fd, rows, cols, shell, workingDirectory)
        guard pid > 0 else { return }

        masterFD = fd
        childPID = pid

        // Non-blocking reads
        let flags = fcntl(masterFD, F_GETFL)
        _ = fcntl(masterFD, F_SETFL, flags | O_NONBLOCK)

        // Dispatch source for reading PTY output
        let source = DispatchSource.makeReadSource(fileDescriptor: masterFD, queue: queue)
        source.setEventHandler { [weak self] in
            self?.handleRead()
        }
        source.setCancelHandler { /* fd closed in stop() */ }
        readSource = source
        source.resume()

        // Monitor child exit
        let cpid = childPID
        DispatchQueue.global(qos: .utility).async { [weak self] in
            var status: Int32 = 0
            waitpid(cpid, &status, 0)
            DispatchQueue.main.async {
                self?.childPID = -1
                self?.exitHandler?()
            }
        }
    }

    // MARK: - I/O

    func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        writeData(data)
    }

    func writeData(_ data: Data) {
        queue.async { [weak self] in
            guard let self, self.masterFD >= 0 else { return }
            data.withUnsafeBytes { ptr in
                if let base = ptr.baseAddress {
                    _ = Darwin.write(self.masterFD, base, data.count)
                }
            }
        }
    }

    func resize(rows: UInt16, cols: UInt16) {
        guard masterFD >= 0 else { return }
        _ = pty_resize(masterFD, rows, cols)
    }

    func sendInterrupt() {
        write("\u{03}") // Ctrl-C
    }

    func sendEOF() {
        write("\u{04}") // Ctrl-D
    }

    // MARK: - Cleanup

    func stop() {
        readSource?.cancel()
        readSource = nil
        if childPID > 0 {
            kill(childPID, SIGTERM)
            childPID = -1
        }
        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }
    }

    deinit { stop() }

    // MARK: - Private

    private func handleRead() {
        var buffer = [UInt8](repeating: 0, count: 8192)
        let n = Darwin.read(masterFD, &buffer, buffer.count)
        guard n > 0 else { return }
        let data = Data(buffer[0..<n])
        DispatchQueue.main.async { [weak self] in
            self?.outputHandler?(data)
        }
    }
}
