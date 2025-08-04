//
//  TagManagementViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine

final class TagManagementViewModel: BaseViewModel {
    
    enum Input {
        case addTag
        case editTag(CDTag)
        case deleteTag(CDTag)
        case confirmDeleteTag
        case saveTag(name: String, color: TagColor)
        case updateTag(name: String, color: TagColor)
    }
    
    @Published private(set) var tags: [CDTag] = []
    @Published var showingAddEditSheet = false
    @Published var showingDeleteAlert = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    @Published var editingTag: CDTag?
    @Published var isEditing = false
    
    private let tagService: TagService
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        self.tagService = ServiceManager.shared.tagService
        super.init()
        loadTags()
        AnalyticsService.shared.logEvent(.tagManagementOpened)
    }
    
    func handle(_ input: Input) {
        switch input {
        case .addTag:
            editingTag = nil
            isEditing = false
            showingAddEditSheet = true
            
        case .editTag(let tag):
            editingTag = tag
            isEditing = true
            showingAddEditSheet = true
            
        case .deleteTag(let tag):
            editingTag = tag
            showingDeleteAlert = true
            
        case .confirmDeleteTag:
            guard let tag = editingTag else { return }
            deleteTag(tag)
            
        case .saveTag(let name, let color):
            createTag(name: name, color: color)
            
        case .updateTag(let name, let color):
            guard let tag = editingTag else { return }
            updateTag(tag, name: name, color: color)
        }
    }
    
    private func loadTags() {
        tags = tagService.getAllTags()
    }
    
    private func createTag(name: String, color: TagColor) {
        do {
            try tagService.createTag(name: name, color: color)
            loadTags()
            showingAddEditSheet = false
            AnalyticsService.shared.logEvent(.tagCreated)
        } catch {
            handleError(error)
        }
    }
    
    private func updateTag(_ tag: CDTag, name: String, color: TagColor) {
        do {
            try tagService.updateTag(tag, name: name, color: color)
            loadTags()
            showingAddEditSheet = false
            AnalyticsService.shared.logEvent(.tagUpdated)
        } catch {
            handleError(error)
        }
    }
    
    private func deleteTag(_ tag: CDTag) {
        do {
            try tagService.deleteTag(tag)
            loadTags()
            editingTag = nil
            AnalyticsService.shared.logEvent(.tagDeleted)
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        if let coreError = error as? CoreError {
            errorMessage = coreError.description
        } else {
            errorMessage = error.localizedDescription
        }
        showingErrorAlert = true
    }
} 