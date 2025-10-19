//
//  CloudKitService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CloudKit
import Combine

enum CloudKitError: Error {
    case accountNotAvailable
    case recordIDNotFound
    case timeout
    case fetchFailed(Error)
}

final class CloudKitService: ObservableObject {
    
    static let shared = CloudKitService()
    
    @Published var isAvailable: Bool = false
    @Published var isSyncing: Bool = false
    
    private let container: CKContainer
    private var cancellables = Set<AnyCancellable>()
    private var syncObserver: NSObjectProtocol?
    
    private init() {
        self.container = CKContainer.default()
        setupSyncMonitoring()
    }
    
    deinit {
        if let observer = syncObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - iCloud Availability
    
    func checkAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            let available = status == .available
            await MainActor.run {
                self.isAvailable = available
            }
            return available
        } catch {
            logError("CloudKit availability check failed: \(error)")
            await MainActor.run {
                self.isAvailable = false
            }
            return false
        }
    }
    
    func checkAvailabilityWithTimeout(timeout: TimeInterval = 5.0) async -> Bool {
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await self.checkAvailability()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return false
            }
            
            // Return the first result
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            
            return false
        }
    }
    
    // MARK: - User Record ID
    
    func fetchUserRecordID() async throws -> String {
        do {
            let recordID = try await container.userRecordID()
            return recordID.recordName
        } catch {
            logError("Failed to fetch user record ID: \(error)")
            throw CloudKitError.recordIDNotFound
        }
    }
    
    func fetchUserRecordIDWithTimeout(timeout: TimeInterval = 5.0) async -> String? {
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                try? await self.fetchUserRecordID()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            
            // Return the first result
            if let result = await group.next() {
                group.cancelAll()
                return result
            }
            
            return nil
        }
    }
    
    // MARK: - Sync Monitoring
    
    private func setupSyncMonitoring() {
        syncObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isSyncing = true
            
            // Reset syncing flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self?.isSyncing = false
            }
        }
    }
}

