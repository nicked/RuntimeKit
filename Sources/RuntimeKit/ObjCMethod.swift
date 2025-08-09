//
//  ObjCMethod.swift
//  
//
//  Created by Nick Randall on 27/12/2022.
//

import Foundation


/// Wraps a runtime method.
public struct ObjCMethod {
    @usableFromInline let method: Method

    /// Creates a wrapper of the specified Method.
    @inlinable public init(_ method: Method) {
        self.method = method
    }

    /// Returns the selector of this method.
    @inlinable public var selector: Selector {
        method_getName(method)
    }

    /// Returns an encoding describing this method's parameter and return types.
    @inlinable public var encoding: MethodTypeEncodings {
        MethodTypeEncodings(method_getTypeEncoding(method)!.asString) ?? .init()
    }

    /// Returns the number of arguments accepted by this method.
    ///
    /// - Note: Includes the two hidden arguments for `self` and `_cmd`.
    @inlinable public var argumentCount: Int {
        Int(method_getNumberOfArguments(method))
    }

    /// Returns an encoding describing a single parameter type of this method.
    ///
    /// - Note: The first two arguments are always `self` and `_cmd`.
    @inlinable public func argumentType(at index: Int) -> TypeEncoding {
        method_copyArgumentType(method, UInt32(index))?.toTypeEncodingAndFree() ?? .empty
    }

    /// Returns the encoding of this method's return type.
    @inlinable public var returnType: TypeEncoding {
        method_copyReturnType(method).toTypeEncodingAndFree()
    }

    public var signature: MethodSignature {
        MethodSignature(with: encoding)!
    }


    // MARK: - Swizzling

    /// Exchanges the implementation of this method with that of another.
    ///
    /// Both methods must be declared `@objc dynamic` in Swift.
    /// - Warning: Will cause an assertion if the method encodings are different.
    public func swizzle(with other: ObjCMethod) {
        assert(encoding == other.encoding, "Exchanging implementations of methods with different types")
        method_exchangeImplementations(method, other.method)
    }

    /// The implementation of this method.
    public var implementation: IMP {
        get { method_getImplementation(method) }
        nonmutating set { method_setImplementation(method, newValue) }
    }

    /// The implementation of this method as a block.
    ///
    /// Only returns a block that was previously set using this property.
    /// When setting this property, the block must be declared with `@convention(block)`.
    public var implementationBlock: Any? {
        get { imp_getBlock(implementation) }
        nonmutating set {
            guard let block = newValue else {
                return
            }
            implementation = imp_implementationWithBlock(block)
        }
    }
}

extension ObjCMethod: CustomStringConvertible {
    public var description: String {
        "\(selector) = \(encoding)"
    }
}

extension ObjCMethod: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(Self.self)(\(selector))"
    }
}
