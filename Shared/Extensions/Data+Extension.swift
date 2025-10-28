//
//  Data+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CryptoKit

extension Data {
    var prettyPrintedJSONString: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes, .fragmentsAllowed, .sortedKeys]),
              let prettyJSON = String(data: data, encoding: .utf8)
        else { return nil }
        return prettyJSON
    }
    
    /// Returns a SHA256 hash of the data as a hexadecimal string
    var sha256Hash: String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
