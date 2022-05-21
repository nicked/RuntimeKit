//
//  ObjCProtocol+RuntimeFuncs.swift
//  
//
//  Created by Nick Randall on 28/11/2024.
//

import Foundation


@_documentation(visibility: internal)
public extension ObjCProtocol {
    struct Properties: RuntimeFuncs {
        @usableFromInline let proto: ObjCProtocol
        @usableFromInline let isInstance: Bool

        @inlinable public init(on proto: ObjCProtocol, isInstance: Bool) {
            self.proto = proto
            self.isInstance = isInstance
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<objc_property_t>? {
            // isRequiredProperty is not used by the runtime and should always be true
            protocol_copyPropertyList2(proto.proto, &count, true, isInstance)
        }

        @inlinable public func lookup(name: String) -> OpaquePointer? {
            protocol_getProperty(proto.proto, name, true, isInstance)
        }

        @inlinable public func wrap(_ prop: objc_property_t) -> ObjCProperty {
            ObjCProperty(prop)
        }
    }

    struct Methods: RuntimeFuncs {
        @usableFromInline let proto: ObjCProtocol
        @usableFromInline let isRequired: Bool
        @usableFromInline let isInstance: Bool

        @inlinable public init(on proto: ObjCProtocol, isRequired: Bool, isInstance: Bool) {
            self.proto = proto
            self.isRequired = isRequired
            self.isInstance = isInstance
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<objc_method_description>? {
            protocol_copyMethodDescriptionList(proto.proto, isRequired, isInstance, &count)
        }

        @inlinable public func lookup(name: Selector) -> objc_method_description? {
            let desc = protocol_getMethodDescription(proto.proto, name, isRequired, isInstance)
            // the runtime returns { name: nil, types: nil } if the method is not found
            return desc.name != nil ? desc : nil
        }

        @inlinable public func wrap(_ desc: objc_method_description) -> ObjCProtocol.MethodDetails {
            ObjCProtocol.MethodDetails(desc, isRequired: isRequired, isInstanceMethod: isInstance)!
        }
    }

    struct Protocols: RuntimeFuncs {
        @usableFromInline let proto: ObjCProtocol

        @inlinable public init(on proto: ObjCProtocol) {
            self.proto = proto
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Protocol>? {
            UnsafeMutablePointer(mutating: protocol_copyProtocolList(proto.proto, &count))
        }

        @inlinable public func lookup(name: String) -> Protocol? {
            guard let superProto = ObjCProtocol(named: name) else {
                return nil
            }
            return proto.protocols.contains(superProto) ? superProto.proto : nil
        }

        @inlinable public func wrap(_ proto: Protocol) -> ObjCProtocol {
            ObjCProtocol(proto)
        }
    }

    struct All: RuntimeFuncs {
        @inlinable public init() {}

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Protocol>? {
            UnsafeMutablePointer(mutating: objc_copyProtocolList(&count))
        }

        @inlinable public func lookup(name: String) -> Protocol? {
            objc_getProtocol(name)
        }

        @inlinable public func wrap(_ proto: Protocol) -> ObjCProtocol {
            ObjCProtocol(proto)
        }
    }
}
