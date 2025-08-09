//
//  MethodTypeEncodings.swift
//
//
//  Created by Nick Randall on 7/7/2025.
//

import Foundation

/// Represents the type encoding of a method, including return value, receiver object, selector and parameter types.
///
/// Will always round-trip a method encoding from the runtime back the same encoding, even if it isn't correctly formed.
public struct MethodTypeEncodings {

    /// The types in the method encoding, in order: return type, object type (@), selector type (:) and any parameter types.
    public let types: [TypeEncoding]

    /// Some runtime encodings include offset/size information.
    /// These are not strictly needed, but kept so that types can be re-encoded to identical strings.
    let offsets: [Int]

    /// Some invalid encodings have a leading number because of missing types, e.g. "68@0:8163248f64".
    let leading: Int?

    public init(types: [TypeEncoding] = []) {
        self.types = types
        self.offsets = []
        self.leading = nil
    }

    /// Returns the type encoding for a method with the specified return type and parameters.
    public static func method(returning returnType: TypeEncoding = .void, params: TypeEncoding...) -> Self {
        Self(types: [returnType, .id, .selector] + params)
    }

    /// Returns the type encoding for a getter method of the specified type.
    public static func getter(for type: TypeEncoding) -> Self {
        method(returning: type)
    }

    /// Returns the type encoding for a setter method of the specified type.
    public static func setter(for type: TypeEncoding) -> Self {
        method(params: type)
    }

    /// Returns the method type encoded as a String.
    public var encoded: String {
        description
    }
}

extension MethodTypeEncodings: LosslessStringConvertible {

    /// Parse a method signature with multiple type encodings and offset values.
    public init?(_ description: String) {
        var encoding = Substring(description)
        var types: [TypeEncoding] = []
        var offsets: [Int] = []

        self.leading = try? encoding.parseInt()

        while !encoding.isEmpty {
            guard let type = try? encoding.parseTypeEncoding() else {
                return nil
            }
            types.append(type)

            if let offset = try? encoding.parseInt() {
                offsets.append(offset)
            }
        }

        if !offsets.isEmpty, types.count != offsets.count {
            return nil
        }
        if offsets.isEmpty, leading != nil {
            return nil
        }

        self.types = types
        self.offsets = offsets
    }

    public var description: String {
        if offsets.isEmpty {
            return types.map(\.encoded).joined()
        } else {
            return (leading?.description ?? "") + zip(types, offsets).map { "\($0)\($1)" }.joined()
        }
    }
}

extension MethodTypeEncodings: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        // Ignore offsets when comparing
        lhs.types == rhs.types
    }
}
