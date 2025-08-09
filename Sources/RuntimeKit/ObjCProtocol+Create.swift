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
            protocol_addMethodDescription(proto, method.selector, method.encoding?.encoded, method.isRequired, method.isInstanceMethod)
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
        public let encoding: MethodTypeEncodings?
        public let isRequired: Bool
        public let isInstanceMethod: Bool

        public init(selector: Selector, encoding: MethodTypeEncodings?, isRequired: Bool, isInstanceMethod: Bool) {
            self.selector = selector
            self.encoding = encoding
            self.isRequired = isRequired
            self.isInstanceMethod = isInstanceMethod
        }

        public init?(_ desc: objc_method_description, isRequired: Bool, isInstanceMethod: Bool) {
            // the runtime returns { name: nil, types: nil } if the method is not found
            guard let selector = desc.name else {
                return nil
            }
            self.selector = selector
            self.encoding = desc.types.flatMap { MethodTypeEncodings(String(cString: $0)) }
            self.isRequired = isRequired
            self.isInstanceMethod = isInstanceMethod
        }

        public var description: String {
            "\(selector) = \(encoding?.description ?? "")"
        }

        public var debugDescription: String {
            "\(Self.self)(\(selector))"
        }
    }
}
