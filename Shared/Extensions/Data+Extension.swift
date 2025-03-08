//
//  Data+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

extension Data {
    var prettyPrintedJSONString: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes, .fragmentsAllowed, .sortedKeys]),
              let prettyJSON = String(data: data, encoding: .utf8)
        else { return nil }
        return prettyJSON
    }
}
