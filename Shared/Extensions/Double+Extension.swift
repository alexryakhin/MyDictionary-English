//
//  Double+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public extension Double {
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter
    }

    var formattedAmount: String {
        let formatter = currencyFormatter
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }

    var defaultSpecifier: String {
        if truncatingRemainder(dividingBy: 1.0) == 0.0 {
            return "%.0f"
        } else if truncatingRemainder(dividingBy: 0.1) == 0.0 {
            return "%.1f"
        } else {
            return "%.2f"
        }
    }

    var defaultFractionLength: Int {
        if truncatingRemainder(dividingBy: 1.0) == 0.0 {
            return 0
        } else if truncatingRemainder(dividingBy: 0.1) == 0.0 {
            return 1
        } else {
            return 2
        }
    }
}
