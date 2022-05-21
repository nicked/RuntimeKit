//
//  UnsafeBuffer+Utils.swift
//  
//
//  Created by Nick Randall on 28/11/2024.
//

import Foundation

extension UnsafePointer<CChar> {
    @inlinable var asString: String {
        String(cString: self)
    }

    @inlinable var asTypeEncoding: TypeEncoding {
        TypeEncoding(asString)
    }

    /// Returns the current pointer, but moves it to the start of the next C string
    mutating func thenMoveToNextCString() -> Self {
        let ret = self
        self = UnsafePointer(strchr(self, 0) + 1)
        return ret
    }
}


extension UnsafeBufferPointer {
    @inlinable func free() {
        Darwin.free(UnsafeMutableRawPointer(mutating: baseAddress))
    }
}


extension UnsafeMutablePointer<CChar> {
    @inlinable func toStringAndFree() -> String {
        defer { free(self) }
        return String(cString: self)
    }

    @inlinable func toTypeEncodingAndFree() -> TypeEncoding {
        TypeEncoding(toStringAndFree())
    }
}
