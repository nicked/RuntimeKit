//
//  ObjCIvar.swift
//  
//
//  Created by Nick Randall on 27/12/2022.
//

import Foundation


/// Wraps a runtime instance variable.
public struct ObjCIvar {
    @usableFromInline let ivar: Ivar

    /// Creates a wrapper of the specified Ivar.
    @inlinable public init(_ ivar: Ivar) {
        self.ivar = ivar
    }

    /// The name of this instance variable.
    @inlinable public var name: String {
        ivar_getName(ivar)?.asString ?? ""  // should never be nil
    }

    /// The type encoding of this instance variable.
    /// Backing ivars of Swift properties will return an empty encoding.
    @inlinable public var type: TypeEncoding {
        ivar_getTypeEncoding(ivar)?.asTypeEncoding ?? .empty
    }

    /// The offset of this instance variable from the start of the class backing struct in bytes.
    @inlinable public var offset: Int {
        ivar_getOffset(ivar)
    }
}


// MARK: - Values

extension ObjCIvar {

    /// Returns the value of this ivar on `instance`, as an object.
    ///
    /// A weak ivar is read with the correct memory management.
    /// - Precondition: The type of this ivar must be an object, a class or a block.
    ///     For other types, use `value(on:as:)`.
    /// - Important: The class of `instance` must be the class that declares this ivar, or a subclass of it.
    public func object(on instance: AnyObject) -> AnyObject? {
        check(isObject: true, on: instance)
        return object_getIvar(instance, ivar) as AnyObject?
    }

    /// Sets the value of this ivar on `instance` to an object.
    ///
    /// If the memory management of the ivar is not known, the value is retained.
    /// - Precondition: The type of this ivar must be an object, a class or a block.
    ///     For other types, use `setValue(_:on:)`.
    /// - Important: The class of `instance` must be the class that declares this ivar, or a subclass of it.
    public func setObject(_ value: AnyObject?, on instance: AnyObject) {
        check(isObject: true, on: instance)
        object_setIvarWithStrongDefault(instance, ivar, value)
    }

    /// Returns the value of this ivar on `instance`, as a value of type `T`.
    ///
    /// Copies the bytes of the ivar directly, without memory management.
    /// - Precondition: `T` must have the same size as the ivar,
    ///     and the type of this ivar must not be an object. For objects, use `object(on:)`.
    /// - Important: The class of `instance` must be the class that declares this ivar, or a subclass of it.
    public func value<T: BitwiseCopyable>(on instance: AnyObject, as _: T.Type) -> T {
        check(isObject: false, on: instance)
        checkSize(of: T.self)
        return withExtendedLifetime(instance) {
            Unmanaged.passUnretained(instance).toOpaque().loadUnaligned(fromByteOffset: offset, as: T.self)
        }
    }

    /// Sets the value of this ivar on `instance` to a value of type `T`.
    ///
    /// Copies the bytes of the value directly, without memory management.
    /// - Precondition: `T` must have the same size as the ivar,
    ///     and the type of this ivar must not be an object. For objects, use `setObject(_:on:)`.
    /// - Important: The class of `instance` must be the class that declares this ivar, or a subclass of it.
    public func setValue<T: BitwiseCopyable>(_ value: T, on instance: AnyObject) {
        check(isObject: false, on: instance)
        checkSize(of: T.self)
        withExtendedLifetime(instance) {
            Unmanaged.passUnretained(instance).toOpaque().storeBytes(of: value, toByteOffset: offset, as: T.self)
        }
    }

    private func check(isObject: Bool, on instance: AnyObject) {
        // An instance of a different class has different ivars at this offset.
        // Only an assert, because the lookup has a cost on each access.
        assert(
            class_getInstanceVariable(object_getClass(instance), name) == ivar,
            "\(name) is not an ivar of \(Swift.type(of: instance))"
        )
        precondition(
            type.withoutModifiers.isObject == isObject,
            isObject ? "\(name) is not an object, use value(on:as:)" : "\(name) is an object, use object(on:)"
        )
    }

    /// Traps if `T` does not have the size of the ivar.
    private func checkSize<T>(of _: T.Type) {
        let size = type.sizeAndAlignment.size
        precondition(
            MemoryLayout<T>.size == size,
            "\(T.self) is \(MemoryLayout<T>.size) bytes, but \(name) is \(size) bytes"
        )
    }
}

@_documentation(visibility: internal)
extension ObjCIvar {
    /// Represents an ivar for creating a new class.
    public struct Details {
        let name: String
        let type: TypeEncoding
        let size: Int
        let alignment: Int

        public init(_ name: String, type: TypeEncoding) {
            self.name = name
            self.type = type
            (self.size, self.alignment) = type.sizeAndAlignment
        }

        /// For `class_addIvar` we need the alignment as the number of bits to shift
        var alignmentShift: UInt8 {
            // The alignment is a power of 2, except for `void` which has an alignment of 0
            UInt8(max(alignment, 1).trailingZeroBitCount)
        }
    }
}

extension ObjCIvar: CustomStringConvertible {
    public var description: String {
        "\(name) = \(type)"
    }
}

extension ObjCIvar: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(Self.self)(\(name))"
    }
}
