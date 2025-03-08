//
//  Relay.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Combine
import struct SwiftUI.Binding

@propertyWrapper
public struct Relay<Value> {
    private var publisher: Publisher

    public init(wrappedValue: Value) {
        publisher = Publisher(wrappedValue)
    }

    public var projectedValue: Publisher {
        publisher
    }

    private var observablePublisher: ObservableObjectPublisher? {
        get { publisher.observablePublisher }
        set { publisher.observablePublisher = newValue }
    }

    public var wrappedValue: Value {
        get { publisher.subject.value }
        set { publisher.subject.send(newValue) }
    }

    public struct Publisher: Combine.Publisher {
        public typealias Output = Value
        public typealias Failure = Never

        public var subject: CurrentValueSubject<Value, Never>
        public weak var observablePublisher: ObservableObjectPublisher?

        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subject.subscribe(subscriber)
        }

        public init(_ output: Output) {
            subject = .init(output)
        }

            public var binding: Binding<Value> {
            .init(
                get: { subject.value },
                set: {
                    observablePublisher?.send()
                    subject.send($0)
                }
            )
        }
    }

    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            if observed[keyPath: storageKeyPath].observablePublisher == nil {
                observed[keyPath: storageKeyPath].observablePublisher = observed.objectWillChange as? ObservableObjectPublisher
            }

            return observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            if let willChange = observed.objectWillChange as? ObservableObjectPublisher {
                willChange.send() // Before modifying wrappedValue
                observed[keyPath: storageKeyPath].wrappedValue = newValue
            }
        }
    }
}
