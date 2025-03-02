import Foundation
import Combine
import os

final class Logger {

    // Mutable properties
    var moduleName: String?
    var minLogLevel: LogEventLevel
    var printMessages: Bool
    let eventsSubject = CurrentValueSubject<LogEvent?, Never>(nil)

    private static let osLogger = os.Logger(subsystem: subsystem, category: "app")
    private static let subsystem = Bundle.main.bundleIdentifier!

    private let queue = DispatchQueue(label: "LoggerQueue") // Synchronization queue

    init(
        moduleName: String? = Bundle.main.bundleIdentifier,
        minLogLevel: LogEventLevel = .info,
        printMessages: Bool = false
    ) {
        self.moduleName = moduleName
        self.minLogLevel = minLogLevel
        self.printMessages = printMessages
    }

    static private func makeDefaultShared() -> Logger {
        Logger(moduleName: nil, minLogLevel: .debug, printMessages: false)
    }

    // MARK: - Methods

    func log(_ messages: String..., eventLevel: LogEventLevel = .debug) {
        queue.async {
            self.log(
                event: LogEvent(
                    level: eventLevel,
                    moduleName: self.moduleName,
                    messages: messages
                )
            )
        }
    }

    func debug(_ messages: String...) {
        log(messages.joined(separator: " "), eventLevel: .debug)
    }

    func info(_ messages: String...) {
        log(messages.joined(separator: " "), eventLevel: .info)
    }

    func warn(_ messages: String...) {
        log(messages.joined(separator: " "), eventLevel: .warn)
    }

    func error(_ messages: String...) {
        log(messages.joined(separator: " "), eventLevel: .error)
    }

    func logDeinit<T>(_ object: T) {
        logDeinit(String(describing: type(of: object)))
    }

    private func logDeinit(_ name: String) {
        debug("Deinit", name)
    }

    // MARK: - Private Methods

    private func log(event: LogEvent) {
        guard event.level != .none, event.level.level >= minLogLevel.level else {
            return
        }

        Self.osLogger.log(level: event.level.osLogType, "\(event.fullLogRecord, privacy: .public)")

        if printMessages {
            print(event.fullLogRecord)
        }

        // Pass events through the publisher
        eventsSubject.send(event)
    }
}
