//
//  Typealiases.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

typealias AsyncVoidHandler = () async throws -> Void
typealias VoidHandler = () -> Void
typealias BoolHandler = (Bool) -> Void
typealias IntHandler = (Int) -> Void
typealias StringHandler = (String) -> Void
typealias StringOptionalHandler = (String?) -> Void
typealias DateHandler = (Date) -> Void
