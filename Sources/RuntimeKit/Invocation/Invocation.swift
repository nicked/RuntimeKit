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

    /// Returns an Invocation able to construct messages using a given method,
    /// or `nil` if MethodSignature cannot parse the type encodings of the method.
    public init?(method: ObjCMethod) {
        guard let signature = method.signature else {
            return nil
        }
        self.init(methodSignature: signature)
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
    /// - Precondition: `T` must have the same size as the argument type in the method signature.
    public func getArgument<T>(at index: Int, as type: T.Type) -> T {
        valueFromPointer(byteCount: argumentSize(at: index)) {
            inner.getArgument($0, at: index)
        }
    }

    /// Sets an argument of the receiver.
    ///
    /// Indices 0 and 1 indicate the hidden arguments `self` and `_cmd`, respectively;
    /// you should set these values directly with the `target` and `selector` properties.
    /// Use indices 2 and greater for the arguments normally passed in a message.
    /// This method raises NSInvalidArgumentException if index is greater than the actual number of arguments for the selector.
    /// - Precondition: `T` must have the same size as the argument type in the method signature.
    /// - Important: The invocation does not retain an object argument. Keep the object alive until `invoke` returns,
    ///     or until you call `retainArguments()` after you set the arguments.
    public func setArgument<T>(at index: Int, to value: T) {
        withPointerFromValue(value, byteCount: argumentSize(at: index)) {
            inner.setArgument($0, at: index)
        }
    }

    /// If the receiver hasn’t already done so, retains the target and all object arguments of the receiver
    /// and copies all of its C-string arguments and blocks. If a return value has been set, this is also retained or copied.
    ///
    /// - Warning: Do not call this if a method writes into a `char *` argument. The method writes into the copy, not into your buffer.
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
    /// - Precondition: `T` must have the same size as the return type in the method signature.
    public func returnValue<T>(as type: T.Type) -> T {
        valueFromPointer(byteCount: Int(inner.methodSignature.methodReturnLength)) {
            inner.getReturnValue($0)
        }
    }

    /// Sets the return value.
    /// This value is normally set when you call `invoke`.
    ///
    /// Note that for reference types you must pass an Objective-C type here and not the Swift value type
    /// (e.g. `NSString` instead of `String`).
    /// - Precondition: `T` must have the same size as the return type in the method signature.
    /// - Important: The invocation does not retain an object return value. Keep the object alive while you use the invocation,
    ///     or until you call `retainArguments()` after you set the return value.
    public func setReturnValue<T>(_ value: T) {
        withPointerFromValue(value, byteCount: Int(inner.methodSignature.methodReturnLength)) {
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

    /// The size in bytes of the argument at `index`, as declared in the method signature.
    private func argumentSize(at index: Int) -> Int {
        var size = 0
        NSGetSizeAndAlignment(inner.methodSignature.getArgumentType(at: UInt(index)), &size, nil)
        return size
    }

    /// Traps if `T` does not have the size that the method signature declares.
    ///
    /// NSInvocation copies exactly `byteCount` bytes, so a different size would read or write past the end of the value.
    private func checkSize<T>(of type: T.Type, byteCount: Int) {
        precondition(
            MemoryLayout<T>.size == byteCount,
            "\(T.self) is \(MemoryLayout<T>.size) bytes, but the method signature declares \(byteCount) bytes"
        )
    }

    /// Gets a reference or value type from a raw pointer
    private func valueFromPointer<T>(byteCount: Int, using block: (UnsafeMutableRawPointer) -> Void) -> T {
        checkSize(of: T.self, byteCount: byteCount)
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: MemoryLayout<T>.alignment)
        defer { ptr.deallocate() }
        block(ptr)
        return ptr.load(as: T.self)
    }

    /// Gets a raw pointer to a reference or value type
    private func withPointerFromValue<T>(_ value: T, byteCount: Int, using block: (UnsafeMutableRawPointer) -> Void) {
        checkSize(of: T.self, byteCount: byteCount)
        withUnsafePointer(to: value) {
            block(UnsafeMutableRawPointer(mutating: $0))
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
