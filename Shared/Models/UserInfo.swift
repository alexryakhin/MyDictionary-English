//
//  UserInfo.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import Foundation
import FirebaseFirestore

struct UserInfo: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let nickname: String?
    let registrationDate: Date?
    
    init(
        id: String,
        email: String,
        displayName: String? = nil,
        nickname: String? = nil,
        registrationDate: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.nickname = nickname
        self.registrationDate = registrationDate
    }
    
    init?(from firestoreData: [String: Any]) {
        guard let id = firestoreData["userId"] as? String,
              let email = firestoreData["email"] as? String else {
            return nil
        }
        
        self.id = id
        self.email = email
        self.displayName = firestoreData["name"] as? String
        self.nickname = firestoreData["nickname"] as? String
        
        if let timestamp = firestoreData["registrationDate"] as? Timestamp {
            self.registrationDate = timestamp.dateValue()
        } else {
            self.registrationDate = nil
        }
    }
    
    init?(fromCloudFunctionData cloudFunctionData: [String: Any]) {
        guard let id = cloudFunctionData["id"] as? String,
              let email = cloudFunctionData["email"] as? String else {
            return nil
        }
        
        self.id = id
        self.email = email
        self.displayName = cloudFunctionData["displayName"] as? String
        self.nickname = cloudFunctionData["nickname"] as? String
        
        // Handle registration date from Cloud Function (might be ISO string or timestamp)
        if let registrationDateString = cloudFunctionData["registrationDate"] as? String {
            let formatter = ISO8601DateFormatter()
            self.registrationDate = formatter.date(from: registrationDateString)
        } else if let timestamp = cloudFunctionData["registrationDate"] as? [String: Any],
                  let seconds = timestamp["_seconds"] as? Int64 {
            self.registrationDate = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            self.registrationDate = nil
        }
    }
}
