//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// A type that can represent either failure with an error or success with a result value.
public protocol ResultProtocol {
    associatedtype Value
    
    /// Constructs a successful result wrapping a `value`.
    init(value: Value)
    
    /// Constructs a failed result wrapping an `error`.
    init(error: Error)
    
    /// Case analysis for ResultProtocol.
    ///
    /// Returns the value produced by appliying `ifFailure` to the error if self represents a failure, or `ifSuccess` to the result value if self represents a success.
    func analysis<U>(ifSuccess: (Value) -> U, ifFailure: (Error) -> U) -> U
    
    /// Returns the value if self represents a success, `nil` otherwise.
    ///
    /// A default implementation is provided by a protocol extension. Conforming types may specialize it.
    var value: Value? { get }
    
    /// Returns the error if self represents a failure, `nil` otherwise.
    ///
    /// A default implementation is provided by a protocol extension. Conforming types may specialize it.
    var error: Error? { get }
}

public extension ResultProtocol {
    
    /// Returns the value if self represents a success, `nil` otherwise.
    public var value: Value? {
        return analysis(ifSuccess: { $0 }, ifFailure: { _ in nil })
    }
    
    /// Returns the error if self represents a failure, `nil` otherwise.
    public var error: Error? {
        return analysis(ifSuccess: { _ in nil }, ifFailure: { $0 })
    }
    
    /// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
    public func map<U>(_ transform: (Value) -> U) -> Result<U> {
        return flatMap { .success(transform($0)) }
    }
    
    /// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
    public func flatMap<U>(_ transform: (Value) -> Result<U>) -> Result<U> {
        return analysis(
            ifSuccess: transform,
            ifFailure: Result<U>.failure)
    }
}

public extension ResultProtocol {
    
    // MARK: Higher-order functions
    
    /// Returns `self.value` if this result is a .Success, or the given value otherwise. Equivalent with `??`
    public func recover(_ value: @autoclosure () -> Value) -> Value {
        return self.value ?? value()
    }
    
    /// Returns this result if it is a .Success, or the given result otherwise. Equivalent with `??`
    public func recover(with result: @autoclosure () -> Self) -> Self {
        return analysis(
            ifSuccess: { _ in self },
            ifFailure: { _ in result() })
    }
}

/// Protocol used to constrain `tryMap` to `Result`s with compatible `Error`s.
public protocol ErrorProtocolConvertible: Swift.Error {
    static func error(from error: Swift.Error) -> Self
}

// MARK: - Operators

infix operator &&& {
/// Same associativity as &&.
associativity left

/// Same precedence as &&.
precedence 120
}

/// Returns a Result with a tuple of `left` and `right` values if both are `Success`es, or re-wrapping the error of the earlier `Failure`.
public func &&& <L: ResultProtocol, R: ResultProtocol> (left: L, right: @autoclosure () -> R) -> Result<(L.Value, R.Value)>
{
    return left.flatMap { left in right().map { right in (left, right) } }
}

infix operator >>- {
// Left-associativity so that chaining works like you’d expect, and for consistency with Haskell, Runes, swiftz, etc.
associativity left

// Higher precedence than function application, but lower than function composition.
precedence 100
}

/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
///
/// This is a synonym for `flatMap`.
public func >>- <T: ResultProtocol, U> (result: T, transform: (T.Value) -> Result<U>) -> Result<U> {
    return result.flatMap(transform)
}

/// Returns `true` if `left` and `right` are both `Success`es and their values are equal, or if `left` and `right` are both `Failure`s and their errors are equal.
public func == <T: ResultProtocol> (left: T, right: T) -> Bool
    where T.Value: Equatable
{
    if let left = left.value, let right = right.value {
        return left == right
    }
    return false
}

/// Returns `true` if `left` and `right` represent different cases, or if they represent the same case but different values.
public func != <T: ResultProtocol> (left: T, right: T) -> Bool
    where T.Value: Equatable
{
    return !(left == right)
}

/// Returns the value of `left` if it is a `Success`, or `right` otherwise. Short-circuits.
public func ?? <T: ResultProtocol> (left: T, right: @autoclosure () -> T.Value) -> T.Value {
    return left.recover(right())
}

/// Returns `left` if it is a `Success`es, or `right` otherwise. Short-circuits.
public func ?? <T: ResultProtocol> (left: T, right: @autoclosure () -> T) -> T {
    return left.recover(with: right())
}

// MARK: - migration support
@available(*, unavailable, renamed: "ResultProtocol")
public typealias ResultType = ResultProtocol

@available(*, unavailable, renamed: "Error")
public typealias ResultErrorType = Swift.Error

@available(*, unavailable, renamed: "ErrorProtocolConvertible")
public typealias ErrorTypeConvertible = ErrorProtocolConvertible

extension ResultProtocol {
    @available(*, unavailable, renamed: "recover(with:)")
    public func recoverWith(_ result: @autoclosure () -> Self) -> Self {
        fatalError()
    }
}

extension ErrorProtocolConvertible {
    @available(*, unavailable, renamed: "error(from:)")
    public static func errorFromErrorType(_ error: Swift.Error) -> Self {
        fatalError()
    }
}
