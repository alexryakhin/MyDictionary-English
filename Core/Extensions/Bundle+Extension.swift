//
//  Bundle+Extension.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/6/24.
//

import Foundation

extension Bundle {
    // Use generic T type here to decode anything from almost any JSON Data file.
    func decode<T: Decodable>(_ file: String) -> T? {
        // Getting the location of the file in our bundle and setting a temporary URL constant.
        guard let url = self.url(forResource: file, withExtension: "json") else {
            logger.error("Failed to locate \(file) in bundle.")
            return nil
        }

        // Setting a temporary data constant with Data from the file found in the bundle.
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            logger.error("Failed to read \(file) from bundle: \(error)")
            return nil
        }

        // Decoder instance.
        let decoder = JSONDecoder()

        // Format date to read easier.
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)

        // Loading data from the data constant.
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Failed to decode \(file) from bundle: \(error)")
            return nil
        }
    }
}
