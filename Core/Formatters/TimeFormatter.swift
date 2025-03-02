//
//  TimeFormatter.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/6/24.
//

import Foundation

/// Format seconds to string like "09:55"
class TimeFormatter {

    enum Format {
        case hoursAndMinutes
        case minutesAndSeconds
        case seconds
    }

    // MARK: - Private Properties
    
    private var formatter: DateComponentsFormatter

    // MARK: - Init

    init(formatter: DateComponentsFormatter = TimeFormatter.defaultFormatter()) {
        self.formatter = formatter
    }

    // MARK: - Methods

    func string(seconds: TimeInterval, format: Format = .minutesAndSeconds) -> String? {
        switch format {
        case .hoursAndMinutes:
            formatter.allowedUnits = [.hour, .minute]
        case .minutesAndSeconds:
            formatter.allowedUnits = [.minute, .second]
        case .seconds:
            formatter.allowedUnits = [.second]
        }

        return formatter.string(from: seconds)
    }

    func string(seconds: Int, format: Format = .minutesAndSeconds) -> String? {
        return string(seconds: TimeInterval(seconds), format: format)
    }

    static func defaultFormatter() -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }
}
