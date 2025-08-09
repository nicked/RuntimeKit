//
//  ObjCProperty.Attributes.swift
//  
//
//  Created by Nick Randall on 27/12/2022.
//

import Foundation


extension ObjCProperty {

    enum Attribute: LosslessStringConvertible {
        case type(TypeEncoding)
        case nonAtomic
        case readOnly
        case copy
        case retain
        case weak
        case dynamic
        case getter(String)
        case setter(String)
        case ivar(String)

        init?(_ description: String) {
            guard let first = description.first else { return nil }
            let rest = String(description.dropFirst())

            switch first {
                case "T": self = .type(TypeEncoding(rest) ?? .empty)
                case "N": self = .nonAtomic
                case "R": self = .readOnly
                case "C": self = .copy
                case "&": self = .retain
                case "W": self = .weak
                case "D": self = .dynamic
                case "G" where !rest.isEmpty: self = .getter(rest)
                case "S" where !rest.isEmpty: self = .setter(rest)
                case "V" where !rest.isEmpty: self = .ivar(rest)
                default: return nil
            }
        }

        var description: String {
            switch self {
                case .type(let enc):    "T\(enc)"
                case .nonAtomic:        "N"
                case .readOnly:         "R"
                case .copy:             "C"
                case .retain:           "&"
                case .weak:             "W"
                case .dynamic:          "D"
                case .getter(let name): "G\(name)"
                case .setter(let name): "S\(name)"
                case .ivar(let name):   "V\(name)"
            }
        }

        var code: String {
            String(description.prefix(1))
        }

        var value: String {
            String(description.dropFirst())
        }
    }
}

extension ObjCProperty {

    /// Represents a set of property attributes, can be converted to and from an attributes string.
    public struct Attributes: Equatable, CustomStringConvertible {
        /// Whether the property has the `nonatomic` attribute.
        public var nonAtomic: Bool = false
        /// Whether the property has the `readonly` attribute.
        public var readOnly: Bool = false
        /// Whether the property has the `dynamic` attribute.
        public var dynamic: Bool = false
        /// The setter behaviour of the property (`assign`, `strong`, `copy` or `weak`).
        public var setterType: SetterType = .assign
        /// The type encoding of the property.
        public var encoding: TypeEncoding
        /// The name of the custom property getter.
        public var customGetter: String?
        /// The name of the custom property setter.
        public var customSetter: String?
        /// The name of the backing instance variable.
        public var ivarName: String?

        /// Parses attributes from a runtime property.
        public init(_ prop: objc_property_t) {
            self = Self(property_getAttributes(prop)!.asString)
        }

        /// Parses attributes from a property description string, e.g. "T@,R,V_name"
        init(_ attribsStr: String) {
            var attribsStr = attribsStr
            self.encoding = TypeEncoding(propertyAttributes: &attribsStr) ?? .empty

            let attribs = attribsStr
                .split(separator: ",")
                .map(String.init)
                .compactMap(Attribute.init)

            for attrib in attribs {
                switch attrib {
                    case .readOnly: readOnly = true
                    case .nonAtomic: nonAtomic = true
                    case .dynamic: dynamic = true
                    case .copy: setterType = .copy
                    case .retain: setterType = .strong
                    case .weak: setterType = .weak
                    case .type(let enc): encoding = enc
                    case .getter(let name): customGetter = name
                    case .setter(let name): customSetter = name
                    case .ivar(let name): ivarName = name
                }
            }
        }

        /// Creates a set of property attributes.
        public init(
            nonAtomic: Bool = false, readOnly: Bool = false, dynamic: Bool = false, setterType: SetterType = .assign,
            encoding: TypeEncoding, customGetter: String? = nil, customSetter: String? = nil, ivarName: String? = nil
        ) {
            self.nonAtomic = nonAtomic
            self.readOnly = readOnly
            self.dynamic = dynamic
            self.setterType = setterType
            self.encoding = encoding
            self.customGetter = customGetter
            self.customSetter = customSetter
            self.ivarName = ivarName
        }

        func attributeList() -> [Attribute] {
            var attribs: [Attribute] = [.type(encoding)]
            if readOnly     { attribs.append(.readOnly) }
            if nonAtomic    { attribs.append(.nonAtomic) }
            if dynamic      { attribs.append(.dynamic) }
            switch setterType {
                case .assign:   break
                case .strong:   attribs.append(.retain)
                case .weak:     attribs.append(.weak)
                case .copy:     attribs.append(.copy)
            }
            if let customGetter { attribs.append(.getter(customGetter)) }
            if let customSetter { attribs.append(.setter(customSetter)) }
            if let ivarName     { attribs.append(.ivar(ivarName)) }
            return attribs
        }

        public var description: String {
            attributeList().map(\.description).joined(separator: ",")
        }

        public enum SetterType {
            case assign
            case strong
            case weak
            case copy
        }

        /// Converts the attributes into an array of `objc_property_attribute_t`.
        /// The C string data needs to be retained while the array is in use.
        func withObjCTypes<Result>(_ block: ([objc_property_attribute_t]) -> Result) -> Result {
            let attribs = attributeList()

            // Join all the attributes into a single array of null-terminated C strings
            let cStrings = attribs.flatMap { $0.code.utf8CString + $0.value.utf8CString }

            return cStrings.withUnsafeBufferPointer {
                var strPtr = $0.baseAddress!

                let attribTs = (0..<attribs.count).map { _ in
                    objc_property_attribute_t(name: strPtr.thenMoveToNextCString(), value: strPtr.thenMoveToNextCString())
                }

                return block(attribTs)
            }
        }
    }
}
