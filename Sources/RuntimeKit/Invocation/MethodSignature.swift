//
//  MethodSignature.swift
//
//
//  Created by Nick Randall on 4/9/2024.
//

import Foundation


/// Swift wrapper for `NSMethodSignature`.
public struct MethodSignature {
    let inner: NSMethodSignatureProtocol

    init(_ inner: NSMethodSignatureProtocol) {
        self.inner = inner
    }

    /// Returns a MethodSignature for the given method type encodings.
    public init?(with typeEncodings: MethodTypeEncodings) {
        guard let obj = Self.castCls.signature(withObjCTypes: typeEncodings.encoded) else {
            return nil
        }
        self.inner = obj
    }


    /// The number of arguments recorded in the receiver.
    ///
    /// There are always at least two arguments, because an NSMethodSignature object includes the implicit arguments `self` and `_cmd`,
    /// which are the first two arguments passed to every method implementation.
    public var numberOfArguments: Int {
        Int(inner.numberOfArguments)
    }

    /// Returns the type encoding for the argument at a given index.
    ///
    /// Indexes begin with 0. The implicit arguments `self` (of type `AnyObject`) and `_cmd` (of type `Selector`) are at indexes 0 and 1;
    /// explicit arguments begin at index 2.
    public func argumentType(at index: Int) -> TypeEncoding {
        inner.getArgumentType(at: UInt(index)).asTypeEncoding
    }

    /// A string encoding the return type of the method in Objective-C type encoding.
    public var methodReturnType: TypeEncoding {
        inner.methodReturnType.asTypeEncoding
    }

    /// The number of bytes required for the return value.
    public var methodReturnLength: Int {
        Int(inner.methodReturnLength)
    }

    /// The number of bytes that the arguments, taken together, occupy on the stack.
    ///
    /// This number varies with the hardware architecture the application runs on.
    public var frameLength: Int {
        Int(inner.frameLength)
    }

    /// Whether the receiver is asynchronous when invoked through distributed objects.
    ///
    /// If the method is oneway, the sender of the remote message doesn’t block awaiting a reply.
    public var isOneway: Bool {
        inner.isOneway
    }


    // MARK: - Private

    /// Gets the real NSMethodSignature ObjC class as a protocol (NSMethodSignatureProtocol)
    private static let castCls: NSMethodSignatureProtocol.Type = {
        let proto = ObjCProtocol(NSMethodSignatureProtocol.self)
        let cls = ObjCClass(named: "NSMethodSignature")!
        _ = cls.protocols.add(proto)
        precondition(cls.protocols.contains(proto))
        return cls.cls as! NSMethodSignatureProtocol.Type
    }()
}

extension MethodSignature: Equatable {
    public static func == (lhs: MethodSignature, rhs: MethodSignature) -> Bool {
        lhs.inner.isEqual(rhs.inner)
    }
}


/// Matches the API of the real NSMethodSignature
@objc protocol NSMethodSignatureProtocol: NSObjectProtocol {
    static func signature(withObjCTypes types: UnsafePointer<CChar>!) -> NSMethodSignatureProtocol?
    var numberOfArguments: UInt { get }
    @objc(getArgumentTypeAtIndex:) func getArgumentType(at idx: UInt) -> UnsafePointer<CChar>!
    var frameLength: UInt { get }
    var isOneway: Bool { get }
    var methodReturnType: UnsafePointer<CChar>! { get }
    var methodReturnLength: UInt { get }
}
