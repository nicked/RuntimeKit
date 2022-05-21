//
//  TypeEncoding.swift
//  
//
//  Created by Nick Randall on 10/12/2023.
//

import Foundation


/// Wraps a type encoding string.
/// Does not perform any validation.
public struct TypeEncoding: Equatable, LosslessStringConvertible, ExpressibleByStringLiteral {
    @usableFromInline let str: String

    @inlinable init() {
        self.str = ""
    }

    public init(_ str: String) {
        self.str = str
    }

    public init(stringLiteral str: String) {
        self.str = str
    }

    var sizeAndAlignment: (size: Int, alignment: Int) {
        var size = 0
        var alignment = 0
        NSGetSizeAndAlignment(str, &size, &alignment)
        return (size, alignment)
    }

    public var description: String {
        str
    }
}

