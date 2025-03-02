struct LogEvent {
    let level: LogEventLevel
    let moduleName: String?
    let messages: [String]

    var fullLogRecord: String {
        if let moduleName {
            return "\(level.prefixEmoji) [[\(moduleName)]] [\(level.name)] \(messages.joined(separator: " "))"
        } else {
            return "\(level.prefixEmoji) [\(level.name)] \(messages.joined(separator: " "))"
        }
    }

    var fullLogRecordForOSLog: String {
        if let moduleName {
            return "[\(moduleName)] \(messages.joined(separator: " "))"
        } else {
            return messages.joined(separator: " ")
        }
    }
}
