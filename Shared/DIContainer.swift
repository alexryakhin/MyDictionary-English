//
//  DIContainer.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Swinject

public final class DIContainer {

    nonisolated(unsafe) public static let shared = DIContainer()

    private let assembler: Assembler

    public var resolver: Resolver { assembler.resolver }

    private var assembled: Set<String> = .init()

    private init() {
        self.assembler = Assembler([])
    }

    public func assemble<T>(assembly: T) where T: Assembly, T: Identifiable {
        guard let id = assembly.id as? String else {
            return
        }
        guard !assembled.contains(id) else {
            return
        }
        assembler.apply(assembly: assembly)
    }
}
