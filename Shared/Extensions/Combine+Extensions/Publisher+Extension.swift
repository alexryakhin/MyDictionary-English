//
//  Publisher+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Combine

public extension Publisher {

    func asVoid() -> AnyPublisher<Void, Failure> {
        map { _ in Void() }.eraseToAnyPublisher()
    }

    func asTrue() -> AnyPublisher<Bool, Failure> {
        map { _ in true }.eraseToAnyPublisher()
    }

    func asFalse() -> AnyPublisher<Bool, Failure> {
        map { _ in false }.eraseToAnyPublisher()
    }

    func asOptional() -> AnyPublisher<Output?, Failure> {
        map { $0 }.eraseToAnyPublisher()
    }
}

public extension Publisher where Output == Bool {

    /// `Bool` publisher, ignores `false` input
    func ifTrue() -> AnyPublisher<Bool, Failure> {
        filter { $0 == true }.eraseToAnyPublisher()
    }

    /// `Bool` publisher, ignores `true` input
    func ifFalse() -> AnyPublisher<Bool, Failure> {
        filter { $0 == false }.eraseToAnyPublisher()
    }

    /// `Void` publisher, ignores `false` input
    func whenTrue() -> AnyPublisher<Void, Failure> {
        ifTrue().asVoid().eraseToAnyPublisher()
    }

    /// `Void` publisher, ignores `true` input
    func whenFalse() -> AnyPublisher<Void, Failure> {
        ifFalse().asVoid().eraseToAnyPublisher()
    }
}

public extension Publisher {

    /// Ignores output when last value of `filteringPublisher` is `false`
    func filter<O: Publisher>(whenTrue filteringPublisher: O) -> AnyPublisher<Output, Failure> where O.Output == Bool, O.Failure == Failure {
        withLatestFrom(filteringPublisher).filter { $0.1 == true }.map { $0.0 }.eraseToAnyPublisher()
    }

    /// Ignores output when last value of `filteringPublisher` is `true`
    func filter<O: Publisher>(whenFalse filteringPublisher: O) -> AnyPublisher<Output, Failure> where O.Output == Bool, O.Failure == Failure {
        filter(whenTrue: filteringPublisher.inverted())
    }
}

public extension Publisher where Output: OptionalType {

    /// `Output.Wrapped` publisher, ignores `nil` input
    func ifNotNil() -> AnyPublisher<Output.Wrapped, Failure> {
        flatMap { output -> AnyPublisher<Output.Wrapped, Failure> in
            if let value = output.value {
                return Future<Output.Wrapped, Failure> {
                    $0(.success(value))
                }
                .eraseToAnyPublisher()
            } else {
                return Empty<Output.Wrapped, Failure>().eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }

    /// `Void` publisher, ignores `nil` input
    func whenNotNil() -> AnyPublisher<Void, Failure> {
        ifNotNil().asVoid().eraseToAnyPublisher()
    }
}

public extension Publisher where Output == Bool {

    func isTrue() -> AnyPublisher<Bool, Failure> {
        map { $0 == true }.eraseToAnyPublisher()
    }

    func isFalse() -> AnyPublisher<Bool, Failure> {
        map { $0 == false }.eraseToAnyPublisher()
    }

    func inverted() -> AnyPublisher<Bool, Failure> {
        map { !$0 }.eraseToAnyPublisher()
    }
}

public extension Publisher where Output == String {

    func isEmpty() -> AnyPublisher<Bool, Failure> {
        map { $0.isEmpty }.eraseToAnyPublisher()
    }

    func isNotEmpty() -> AnyPublisher<Bool, Failure> {
        isEmpty().inverted()
    }
}

public extension Publisher {

    func replace<O>(withElement element: O) -> AnyPublisher<O, Failure> {
        map { _ in element }.eraseToAnyPublisher()
    }
}

public extension Publisher where Output: AdditiveArithmetic {

    func isZero() -> AnyPublisher<Bool, Failure> {
        map { $0 == .zero }.eraseToAnyPublisher()
    }

    func isNotZero() -> AnyPublisher<Bool, Failure> {
        isZero().inverted()
    }
}

public extension Publisher where Output: OptionalType {

    func isNil() -> AnyPublisher<Bool, Failure> {
        flatMap { output -> AnyPublisher<Bool, Failure> in
            if output.value != nil {
                return Future<Bool, Failure> {
                    $0(.success(false))
                }
                .eraseToAnyPublisher()
            } else {
                return Future<Bool, Failure> {
                    $0(.success(true))
                }
                .eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }

    func isNotNil() -> AnyPublisher<Bool, Failure> {
        isNil().inverted()
    }
}

public extension Publisher where Output == Bool {

    func or<P: Publisher>(_ other: P) -> AnyPublisher<Bool, Failure> where P.Output == Bool, P.Failure == Failure {
        Publishers.CombineLatest(self, other)
            .map { $0 || $1 }
            .eraseToAnyPublisher()
    }

    func and<P: Publisher>(_ other: P) -> AnyPublisher<Bool, Failure> where P.Output == Bool, P.Failure == Failure {
        Publishers.CombineLatest(self, other)
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }
}

public extension Publisher {

    func withLatestFrom<P>(
        _ other: P
    ) -> AnyPublisher<(Self.Output, P.Output), Failure> where P: Publisher, Self.Failure == P.Failure {
        let other = other
        // Note: Do not use `.map(Optional.some)` and `.prepend(nil)`.
        // There is a bug in iOS versions prior 14.5 in `.combineLatest`. If P.Output itself is Optional.
        // In this case prepended `Optional.some(nil)` will become just `nil` after `combineLatest`.
            .map { (value: $0, ()) }
            .prepend((value: nil, ()))

        return map { (value: $0, token: UUID()) }
            .combineLatest(other)
            .removeDuplicates(by: { (old, new) in
                let lhs = old.0, rhs = new.0
                return lhs.token == rhs.token
            })
            .map { ($0.value, $1.value) }
            .compactMap { (left, right) in
                right.map { (left, $0) }
            }
            .eraseToAnyPublisher()
    }

    func withLatestFrom2<P, R>(
        _ one: P, _ two: R
    ) -> AnyPublisher<(Output, P.Output, R.Output), Failure> where P: Publisher, R: Publisher, Self.Failure == P.Failure, Self.Failure == R.Failure {
        self.withLatestFrom(one)
            .withLatestFrom(two)
            .map { ($0.0, $0.1, $1) }
            .eraseToAnyPublisher()
    }

    func withLatestFrom3<P, R, Q>(
        _ one: P, _ two: R, _ three: Q
    ) -> AnyPublisher<(Output, P.Output, R.Output, Q.Output), Failure> where P: Publisher, R: Publisher, Q: Publisher, Self.Failure == P.Failure, Self.Failure == R.Failure, Self.Failure == Q.Failure {
        self.withLatestFrom2(one, two)
            .withLatestFrom(three)
            .map { ($0.0, $0.1, $0.2, $1) }
            .eraseToAnyPublisher()
    }
}
