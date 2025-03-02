//
//  Relay.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/29/24.
//

import Combine
import struct SwiftUI.Binding

@propertyWrapper
struct Relay<Value> {
    private var publisher: Publisher

    init(wrappedValue: Value) {
        publisher = Publisher(wrappedValue)
    }

    var projectedValue: Publisher {
        publisher
    }

    private var observablePublisher: ObservableObjectPublisher? {
        get { publisher.observablePublisher }
        set { publisher.observablePublisher = newValue }
    }

    var wrappedValue: Value {
        get { publisher.subject.value }
        set { publisher.subject.send(newValue) }
    }

    struct Publisher: Combine.Publisher {
        typealias Output = Value
        typealias Failure = Never

        var subject: CurrentValueSubject<Value, Never>
        weak var observablePublisher: ObservableObjectPublisher?

        func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subject.subscribe(subscriber)
        }

        init(_ output: Output) {
            subject = .init(output)
        }

            var binding: Binding<Value> {
            .init(
                get: { subject.value },
                set: {
                    observablePublisher?.send()
                    subject.send($0)
                }
            )
        }
    }

    static subscript<OuterSelf: ObservableObject>(
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
