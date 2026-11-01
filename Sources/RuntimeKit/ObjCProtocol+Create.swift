//
//  ObjCProtocol+Create.swift
//
//
//  Created by Nick Randall on 28/11/2024.
//

import Foundation

extension ObjCProtocol {

    /// Creates and registers a new Protocol, with the specified name, properties, methods and protocols.
    ///
    /// Note that `properties` and `classProperties` are always `@required` properties,
    /// since the runtime doesn't support dynamically creating `@optional` properties.
    ///
    /// - Returns: A new protocol instance or `nil` if a protocol with the same name as `name` already exists.
    public static func create(
        _ name: String,
        properties: [ObjCProperty.Details],
        classProperties: [ObjCProperty.Details],
        methods: [MethodDetails],
        protocols: [ObjCProtocol]
    ) -> ObjCProtocol? {
        guard let proto = objc_allocateProtocol(name) else {
            return nil
        }
        for property in properties {
            property.attributes.withObjCTypes { attribs in
                protocol_addProperty(proto, property.name, attribs, UInt32(attribs.count), true, true)
            }
        }
        for property in classProperties {
            property.attributes.withObjCTypes { attribs in
                protocol_addProperty(proto, property.name, attribs, UInt32(attribs.count), true, false)
            }
        }
        for method in methods {
            protocol_addMethodDescription(proto, method.selector, method.types?.encoded, method.isRequired, method.isInstanceMethod)
        }
        for other in protocols {
            protocol_addProtocol(proto, other.proto)
        }
        objc_registerProtocol(proto)
        return ObjCProtocol(proto)
    }


    /// Details about a single protocol method.
    public struct MethodDetails: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
        public let selector: Selector
        public let isRequired: Bool
        public let isInstanceMethod: Bool
        @usableFromInline let storage: Storage

        @usableFromInline enum Storage {
            case runtime(Protocol)
            case parsed(MethodTypeEncodings?)
        }

        public init(selector: Selector, types: MethodTypeEncodings?, isRequired: Bool, isInstanceMethod: Bool) {
            self.selector = selector
            self.storage = .parsed(types)
            self.isRequired = isRequired
            self.isInstanceMethod = isInstanceMethod
        }

        public init?(_ desc: objc_method_description, isRequired: Bool, isInstanceMethod: Bool) {
            // the runtime returns { name: nil, types: nil } if the method is not found
            guard let selector = desc.name else {
                return nil
            }
            self.selector = selector
            self.storage = .parsed(desc.types.flatMap { MethodTypeEncodings(String(cString: $0)) })
            self.isRequired = isRequired
            self.isInstanceMethod = isInstanceMethod
        }

        @inlinable init(selector: Selector, on proto: Protocol, isRequired: Bool, isInstanceMethod: Bool) {
            self.selector = selector
            self.storage = .runtime(proto)
            self.isRequired = isRequired
            self.isInstanceMethod = isInstanceMethod
        }

        public var types: MethodTypeEncodings? {
            switch storage {
                case .runtime(let proto):
                    protocol_getMethodDescription(proto, selector, isRequired, isInstanceMethod)
                        .types.flatMap { MethodTypeEncodings(String(cString: $0)) }
                case .parsed(let types):
                    types
            }
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selector == rhs.selector
                && lhs.isRequired == rhs.isRequired
                && lhs.isInstanceMethod == rhs.isInstanceMethod
                && lhs.types == rhs.types
        }

        public var description: String {
            "\(selector) = \(types?.description ?? "")"
        }

        public var debugDescription: String {
            "\(Self.self)(\(selector))"
        }
    }
}
