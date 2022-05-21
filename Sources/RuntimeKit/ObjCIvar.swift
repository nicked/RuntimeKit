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
    @inlinable public var encoding: TypeEncoding {
        ivar_getTypeEncoding(ivar)?.asTypeEncoding ?? TypeEncoding()
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
        let encoding: TypeEncoding
        let size: Int
        let alignment: Int

        public init(name: String, encoding: TypeEncoding) {
            self.name = name
            self.encoding = encoding
            (self.size, self.alignment) = encoding.sizeAndAlignment
        }

        /// For `class_addIvar` we need the as the number of bits to shift
        var alignmentShift: UInt8 {
            UInt8(log2(Double(alignment)))
        }
    }
}

extension ObjCIvar: CustomStringConvertible {
    public var description: String {
        "\(name) = \(encoding)"
    }
}

extension ObjCIvar: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(Self.self)(\(name))"
    }
}
