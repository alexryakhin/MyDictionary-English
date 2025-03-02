//
//  DateType.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/29/24.
//

import Foundation

extension DateFormatter {

    enum DateType: String {

        /// 10:00
        case time = "HH:mm"

        /// 21 January 2022
        case fullDateWithoutTime = "d MMMM yyyy"

        /// 21 Jan 2022, 16:40
        case fullDateWithoutSeconds = "dd MMM yyyy, HH:mm"

        /// Mon
        case weekdays = "E"

        /// 21 Jan
        case shortDateWithoutYear = "d MMM"

        /// 21 Jan 2022
        case fullDateWithShortMonth = "d MMM yyyy"

        /// 21.12.2022
        case shortDateWithDots = "dd.MM.yyyy"

        /// 2022-12-21
        case dateJson = "yyyy-MM-dd"

        /// 2022-12-21T20:20:18.108Z
        case iso = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    }

    func convertDateToString(date: Date, format: DateType) -> String {
        dateFormat = format.rawValue
        return string(from: date)
    }

    func convertDateToString(date: Date?, format: DateType) -> String? {
        guard let date = date else { return nil }
        dateFormat = format.rawValue
        return string(from: date)
    }

    func convertStringToDate(string: String, format: DateType) -> Date? {
        dateFormat = format.rawValue
        return date(from: string)
    }

    func convertStringToDate(string: String, formatString: String) -> Date? {
        dateFormat = formatString
        return date(from: string)
    }
}
