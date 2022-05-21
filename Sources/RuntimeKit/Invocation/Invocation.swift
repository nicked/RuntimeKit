//
//  Invocation.swift
//  
//
//  Created by Nick Randall on 4/9/2024.
//

import Foundation


/// Swift wrapper for `NSInvocation`.
public struct Invocation {
    private let inner: NSInvocationProtocol

    /// Returns an Invocation able to construct messages using a given method signature.
    public init(methodSignature: MethodSignature) {
        self.inner = Self.castCls.invocation(with: methodSignature.inner)
    }

    /// Returns an Invocation able to construct messages using a given method.
    public init(method: ObjCMethod) {
        self.init(methodSignature: method.signature)
    }


    /// The receiver’s method signature.
    public var methodSignature: MethodSignature {
        MethodSignature(inner.methodSignature)
    }

    /// The target is the receiver of the message sent by `invoke`.
    public unowned(unsafe) var target: AnyObject? {
        get { inner.target }
        nonmutating set { inner.target = newValue }
    }

    /// The receiver’s selector, or `nil` if it hasn’t been set.
    public var selector: Selector? {
        get { inner.selector }
        nonmutating set { inner.selector = newValue }
    }

    /// Returns the receiver's argument at a specified index as the specified type.
    ///
    /// Indices 0 and 1 indicate the hidden arguments `self` and `_cmd`, respectively;
    /// these values can be retrieved directly with the `target` and `selector` methods.
    /// Use indices 2 and greater for the arguments normally passed in a message.
    /// This method raises NSInvalidArgumentException if index is greater than the actual number of arguments for the selector.
    public func getArgument<T>(at index: Int, as type: T.Type) -> T {
        valueFromPointer {
            inner.getArgument($0, at: index)
        }
    }

    /// Sets an argument of the receiver.
    ///
    /// Indices 0 and 1 indicate the hidden arguments `self` and `_cmd`, respectively;
    /// you should set these values directly with the `target` and `selector` properties.
    /// Use indices 2 and greater for the arguments normally passed in a message.
    /// This method raises NSInvalidArgumentException if index is greater than the actual number of arguments for the selector.
    public func setArgument<T>(at index: Int, to value: T) {
        withPointerFromValue(value) {
            inner.setArgument($0, at: index)
        }
    }

    /// If the receiver hasn’t already done so, retains the target and all object arguments of the receiver
    /// and copies all of its C-string arguments and blocks. If a return value has been set, this is also retained or copied.
    public func retainArguments() {
        inner.retainArguments()
    }

    /// Returns `true` if the receiver has retained its arguments.
    public var argumentsRetained: Bool {
        inner.argumentsRetained
    }

    /// Sends the receiver’s message (with arguments) to its target and sets the return value.
    ///
    /// You must set the receiver’s target, selector, and argument values before calling this method.
    public func invoke() {
        inner.invoke()
    }

    /// Sets the `target` before calling `invoke`.
    public func invoke(withTarget target: AnyObject) {
        inner.invoke(withTarget: target)
    }

    /// Calls `invoke` but uses the specified `imp` instead.
    public func invoke(imp: IMP) {
        inner.invoke(imp: imp)
    }

    /// Gets the return value as the specified type.
    ///
    /// Note that for reference types you must use the Objective-C type here and not the Swift value type
    /// (e.g. `NSString` instead of `String`).
    public func returnValue<T>(as type: T.Type) -> T {
        valueFromPointer {
            inner.getReturnValue($0)
        }
    }

    /// Sets the return value.
    /// This value is normally set when you call `invoke`.
    ///
    /// Note that for reference types you must pass an Objective-C type here and not the Swift value type
    /// (e.g. `NSString` instead of `String`).
    public func setReturnValue<T>(_ value: T) {
        withPointerFromValue(value) {
            inner.setReturnValue($0)
        }
    }


    // MARK: - Private

    /// Gets the real NSInvocation ObjC class as a protocol (NSInvocationProtocol)
    private static let castCls: NSInvocationProtocol.Type = {
        let proto = ObjCProtocol(NSInvocationProtocol.self)
        let cls = ObjCClass(named: "NSInvocation")!
        _ = cls.protocols.add(proto)
        precondition(cls.protocols.contains(proto))
        return cls.cls as! NSInvocationProtocol.Type
    }()

    /// Gets a reference or value type from a raw pointer
    private func valueFromPointer<T>(using block: (UnsafeMutableRawPointer) -> Void) -> T {
        if T.self is AnyClass {
            let ptr = UnsafeMutablePointer<T>.allocate(capacity: 1)
            defer { ptr.deallocate() }
            block(ptr)
            return ptr.pointee
        } else {
            let buffer = UnsafeMutableBufferPointer<T>.allocate(capacity: 1)
            defer { buffer.deallocate() }
            block(UnsafeMutableRawPointer(buffer.baseAddress!))
            return buffer[0]
        }
    }

    /// Gets a raw pointer to a reference or value type
    private func withPointerFromValue<T>(_ value: T, using block: (UnsafeMutableRawPointer) -> Void) {
        if T.self is AnyClass {
            withUnsafePointer(to: value) {
                block(UnsafeMutableRawPointer(mutating: $0))
            }
        } else {
            var value = value
            withUnsafeBytes(of: &value) {
                block(UnsafeMutableRawPointer(mutating: $0.baseAddress!))
            }
        }
    }
}


/// Matches the API of the real NSInvocation
@objc private protocol NSInvocationProtocol: NSObjectProtocol {
    @objc(invocationWithMethodSignature:) static func invocation(with sig: NSMethodSignatureProtocol) -> NSInvocationProtocol
    var methodSignature: NSMethodSignatureProtocol { get }
    func retainArguments()
    var argumentsRetained: Bool { get }
    unowned(unsafe) var target: AnyObject? { get set }
    var selector: Selector? { get set }
    @objc(getArgument:atIndex:) func getArgument(_ argumentLocation: UnsafeMutableRawPointer, at idx: Int)
    @objc(setArgument:atIndex:) func setArgument(_ argumentLocation: UnsafeMutableRawPointer, at idx: Int)
    func getReturnValue(_ retLoc: UnsafeMutableRawPointer)
    func setReturnValue(_ retLoc: UnsafeMutableRawPointer)
    func invoke()
    func invoke(withTarget target: Any)
    @objc(invokeUsingIMP:) func invoke(imp: IMP)
}
