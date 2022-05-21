//
//  ObjCProperty.Attributes.swift
//  
//
//  Created by Nick Randall on 27/12/2022.
//

import Foundation


extension ObjCProperty {

    struct Attribute: LosslessStringConvertible {
        let code: Code
        let value: String

        enum Code: String {
            case type = "T"
            case readOnly = "R"
            case copy = "C"
            case retain = "&"
            case nonAtomic = "N"
            case getter = "G"
            case setter = "S"
            case dynamic = "D"
            case weak = "W"
            case ivar = "V"
        }

        init(_ code: Code, _ value: String = "") {
            self.code = code
            self.value = value
        }

        init?(_ attribute: objc_property_attribute_t) {
            guard let code = Code.init(rawValue: attribute.name.asString) else {
                assertionFailure("Unknown attribute: \(attribute.name.asString) \(attribute.value.asString)")
                return nil
            }
            self.code = code
            self.value = attribute.value.asString
        }

        init?(_ description: String) {
            self.init(Substring(description))
        }

        init?(_ substring: Substring) {
            guard let char = substring.first, let code = Code(rawValue: String(char)) else {
                return nil
            }
            self.code = code
            self.value = String(substring.dropFirst())
        }

        var description: String {
            "\(code.rawValue)\(value)"
        }
    }
}

extension ObjCProperty {

    /// Represents a set of property attributes, can be converted to and from an attributes string.
    public struct Attributes: Equatable, LosslessStringConvertible {
        public let nonAtomic: Bool
        public let readOnly: Bool
        public let dynamic: Bool
        public let setterType: SetterType
        public let encoding: TypeEncoding
        public let getter: String?
        public let setter: String?
        public let ivarName: String?

        /// Parses attributes from a runtime property.
        public init(of prop: objc_property_t) {
            self = Self(property_getAttributes(prop)!.asString)

        }

        /// Parses attributes from a property description string, e.g. "T@,R,V_name"
        public init(_ description: String) {
            var attribs: [Attribute] = []
            let parts = description.split(separator: ",")
            for part in parts {
                if let attr = Attribute(part) {
                    attribs.append(attr)
                } else {
                    // Sometimes a type encoding can contain commas even though it shouldn't, e.g.
                    //  "T{vector<long long, std::allocator<long long>>=^q^q{__compressed_pair<long long *, std::allocator<long long>>=^q}}"
                    // So if we get an attribute that can't be parsed, append it to the previous attribute value
                    if let prev = attribs.popLast() {
                        attribs.append(Attribute(prev.code, "\(prev.value),\(part)"))
                    }
                }
            }

            self = Self(attribs: attribs)
        }

        private init(attribs: [Attribute]) {
            var nonAtomic = false
            var readOnly = false
            var dynamic = false
            var setterType: SetterType = .assign
            var encoding = TypeEncoding()
            var getter: String? = nil
            var setter: String? = nil
            var ivarName: String? = nil

            for attrib in attribs {
                switch attrib.code {
                    case .readOnly: readOnly = true
                    case .nonAtomic: nonAtomic = true
                    case .dynamic: dynamic = true
                    case .copy: setterType = .copy
                    case .retain: setterType = .strong
                    case .weak: setterType = .weak
                    case .type: encoding = TypeEncoding(attrib.value)
                    case .getter: getter = attrib.value
                    case .setter: setter = attrib.value
                    case .ivar: ivarName = attrib.value
                }
            }

            self = Attributes(
                nonAtomic: nonAtomic, readOnly: readOnly, dynamic: dynamic, setterType: setterType,
                encoding: encoding, getter: getter, setter: setter, ivarName: ivarName
            )
        }

        /// Creates a set of property attributes.
        public init(
            nonAtomic: Bool = false, readOnly: Bool = false, dynamic: Bool = false, setterType: SetterType = .assign,
            encoding: TypeEncoding, getter: String? = nil, setter: String? = nil, ivarName: String? = nil
        ) {
            self.nonAtomic = nonAtomic
            self.readOnly = readOnly
            self.dynamic = dynamic
            self.setterType = setterType
            self.encoding = encoding
            self.getter = getter
            self.setter = setter
            self.ivarName = ivarName
        }

        func attributeList() -> [Attribute] {
            var attribs = [Attribute(.type, encoding.str)]
            if readOnly {
                attribs.append(Attribute(.readOnly))
            }
            if nonAtomic {
                attribs.append(Attribute(.nonAtomic))
            }
            if dynamic {
                attribs.append(Attribute(.dynamic))
            }
            switch setterType {
                case .assign:
                    break
                case .strong:
                    attribs.append(Attribute(.retain))
                case .weak:
                    attribs.append(Attribute(.weak))
                case .copy:
                    attribs.append(Attribute(.copy))
            }
            if let getter {
                attribs.append(Attribute(.getter, getter))
            }
            if let setter {
                attribs.append(Attribute(.setter, setter))
            }
            if let ivarName {
                attribs.append(Attribute(.ivar, ivarName))
            }
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
            let cStrings = attribs.flatMap { $0.code.rawValue.utf8CString + $0.value.utf8CString }

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
