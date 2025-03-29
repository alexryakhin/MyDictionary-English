//
//  AdditionalPageState.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public enum AdditionalPageState<
    LoaderProps,
    PlaceholderProps,
    ErrorProps
> {
    public typealias LoaderProps = LoaderProps
    public typealias PlaceholderProps = PlaceholderProps
    public typealias ErrorProps = ErrorProps

    case loading(LoaderProps = DefaultLoaderProps())
    case placeholder(PlaceholderProps = DefaultPlaceholderProps())
    case error(ErrorProps)

    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    public var isEmpty: Bool {
        if case .placeholder = self {
            return true
        }
        return false
    }

    public var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}
