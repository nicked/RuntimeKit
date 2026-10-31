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

@_documentation(visibility: internal)
extension ObjCIvar {
    /// Represents an instance variable for creating a new class.
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
