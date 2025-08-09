//
//  TypeEncoding.swift
//  
//
//  Created by Nick Randall on 10/12/2023.
//

import Foundation

/// The encoding of a single type which can be parsed from an Objective-C type encoding string.
///
/// - Note: If a type can be parsed from an encoding string, it should always re-encode to the same string.
///
/// The reason why this parser is so complex is that some C++ type encodings are extremely long (multiple Kb strings).
/// Some can even include commas, such as for `ETDataTensor.blob`:
///
///     {shared_ptr<Espresso::blob<float, 4>>=^v^{__shared_weak_count}}
///
/// Even the runtime fails to parse these encodings correctly. Since commas are used to delimit property attributes,
/// this also causes functions like `property_copyAttributeValue` to not work.
public indirect enum TypeEncoding: Equatable {
    // Standard scalars
    case char
    case int
    case short
    case long
    case longLong
    case unsignedChar
    case unsignedInt
    case unsignedShort
    case unsignedLong
    case unsignedLongLong
    case float
    case double
    case bool

    // Undocumented scalars
    case int128
    case longDouble

    // Compound and other types
    case void
    case cString
    case `class`
    case selector
    case unknown
    case object(name: String? = nil, protocols: [String] = [])
    case block([TypeEncoding]?)
    case array(count: Int, TypeEncoding?)
    case `struct`(name: String, [Field]?)
    case union(name: String, [Field]?)
    case bitfield(Int)
    case pointer(to: TypeEncoding?)

    // Modifiers
    case const(TypeEncoding)
    case atomic(TypeEncoding)
    case `in`(TypeEncoding)
    case out(TypeEncoding)
    case inOut(TypeEncoding)
    case oneWay(TypeEncoding)
    case byCopy(TypeEncoding)
    case byRef(TypeEncoding)

    // Special - not valid types but can appear as runtime encodings
    case blank
    case empty

    public static let id = Self.object()

    public static func `struct`(_ name: String, _ types: TypeEncoding...) -> Self {
        .struct(name: name, types.map { Field(type: $0) })
    }
}

extension TypeEncoding: LosslessStringConvertible {
    /// Parse a single type encoding.
    ///
    /// - Returns: Nil if the string does not contain a single valid type encoding.
    public init?(_ description: String) {
        guard !description.isEmpty else {
            self = .empty
            return
        }
        var encoding = Substring(description)
        guard let parsed = try? encoding.parseTypeEncoding(), encoding.isEmpty else {
            return nil
        }
        self = parsed
    }
}

extension TypeEncoding {
    /// Parse a type encoding from a property attributes string ("T<type enc>,...").
    /// After a successful parsing, `propertyAttributes` will contain the remainder of the attributes with the type encoding removed.
    public init?(propertyAttributes: inout String) {
        guard propertyAttributes.first == "T" else {
            return nil
        }

        // Remove the leading "T"
        var encoding = propertyAttributes.dropFirst()
        guard encoding.first != "," else {
            // Got a "T,X,Y,Z" with no actual encoding, just drop the T and first comma and return the rest
            propertyAttributes = String(encoding.dropFirst())
            self = .empty
            return
        }
        guard let type = try? encoding.parseTypeEncoding() else {
            return nil
        }
        guard encoding.first == "," || encoding.isEmpty else {
            return nil
        }

        // Remove leading comma
        propertyAttributes = String(encoding.dropFirst())
        self = type
    }
}

extension TypeEncoding {
    /// Returns the type encoded as a String.
    public var encoded: String {
        description
    }

    /// Whether the type is an integer, floating-point or boolean.
    public var isScalar: Bool {
        switch self {
            case .char, .int, .short, .long, .longLong,
                    .unsignedChar, .unsignedInt, .unsignedShort, .unsignedLong, .unsignedLongLong,
                    .float, .double, .bool, .int128, .longDouble:
                return true
            default:
                return false
        }
    }

    /// Strips off any type modifiers, e.g. `.const(.cString)` becomes just `.cString`.
    public var withoutModifiers: TypeEncoding {
        switch self {
            case .const(let inner), .atomic(let inner), .in(let inner), .out(let inner),
                    .inOut(let inner), .oneWay(let inner), .byCopy(let inner), .byRef(let inner):
                return inner.withoutModifiers
            default: return self
        }
    }

    /// Obtains the actual size and the aligned size of the encoded type.
    var sizeAndAlignment: (size: Int, alignment: Int) {
        var sizeInfo = (0, 0)
        NSGetSizeAndAlignment(encoded, &sizeInfo.0, &sizeInfo.1)
        return sizeInfo
    }
}

extension TypeEncoding {
    /// The name and type of a struct or union field.
    public struct Field: CustomStringConvertible, Equatable {
        public let name: String?
        public let type: TypeEncoding?

        public init(name: String? = nil, type: TypeEncoding?) {
            self.name = name
            self.type = type
        }

        init?(_ typeEnc: inout Substring) throws {
            let name = typeEnc.parseStr()
            let type = try typeEnc.parseOptionalTypeEncoding()
            if name == nil, type == nil {
                return nil
            }
            self = Field(name: name, type: type)
        }

        public var description: String {
            if let name {
                "\"\(name)\"\(type)"
            } else {
                "\(type)"
            }
        }
    }
}


extension TypeEncoding: CustomStringConvertible {
    public var description: String {
        switch self {
            case .char:             "c"
            case .int:              "i"
            case .short:            "s"
            case .long:             "l"
            case .longLong:         "q"
            case .unsignedChar:     "C"
            case .unsignedInt:      "I"
            case .unsignedShort:    "S"
            case .unsignedLong:     "L"
            case .unsignedLongLong: "Q"
            case .float:            "f"
            case .double:           "d"
            case .bool:             "B"
            case .int128:           "t"
            case .longDouble:       "D"
            case .void:             "v"
            case .cString:          "*"
            case .selector:         ":"
            case .class:            "#"
            case .unknown:          "?"
            case .blank:            " "
            case .empty:            ""
            case .object(nil, []):  "@"
            case let .object(name, protos): "@\"\(name ?? "")\("<", protos, separator: "><", ">")\""
            case let .array(count, type):   "[\(count)\(type)]"
            case let .bitfield(count):      "b\(count)"
            case let .block(params):        "@?\("<", params, ">")"
            case let .union(name, fields):  "(\(name)\("=", fields, outputEmpty: true))"
            case let .struct(name, fields): "{\(name)\("=", fields, outputEmpty: true)}"
            case let .pointer(to):  "^\(to)"
            case let .const(type):  "r\(type)"
            case let .atomic(type): "A\(type)"
            case let .out(type):    "o\(type)"
            case let .in(type):     "n\(type)"
            case let .inOut(type):  "N\(type)"
            case let .oneWay(type): "V\(type)"
            case let .byCopy(type): "O\(type)"
            case let .byRef(type):  "R\(type)"
        }
    }
}


private extension String.StringInterpolation {
    mutating func appendInterpolation(_ type: TypeEncoding?) {
        if let type {
            appendLiteral(type.description)
        }
    }

    mutating func appendInterpolation<T: CustomStringConvertible>(
        _ prefix: String = "", _ arr: [T]?, separator: String = "", _ suffix: String = "", outputEmpty: Bool = false
    ) {
        if let arr, !arr.isEmpty || outputEmpty {
            appendInterpolation("\(prefix)\(arr.map(\.description).joined(separator: separator))\(suffix)")
        }
    }
}
