//
//  ObjCProtocol+RuntimeFuncs.swift
//
//
//  Created by Nick Randall on 28/11/2024.
//

import Foundation


public extension ObjCProtocol {

    /// The instance or class properties declared by a protocol.
    struct Properties: RuntimeList {
        public typealias Element = ObjCProperty

        @usableFromInline let proto: ObjCProtocol
        @usableFromInline let isInstance: Bool

        @inlinable init(on proto: ObjCProtocol, isInstance: Bool) {
            self.proto = proto
            self.isInstance = isInstance
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<objc_property_t>? {
            // isRequiredProperty is not used by the runtime and should always be true
            protocol_copyPropertyList2(proto.proto, &count, true, isInstance)
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> OpaquePointer? {
            protocol_getProperty(proto.proto, name, true, isInstance)
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ prop: objc_property_t) -> ObjCProperty {
            ObjCProperty(prop)
        }
    }

    /// The instance or class methods declared by a protocol.
    struct Methods: RuntimeList {
        public typealias Element = ObjCProtocol.MethodDetails

        @usableFromInline let proto: ObjCProtocol
        @usableFromInline let isRequired: Bool
        @usableFromInline let isInstance: Bool

        @inlinable init(on proto: ObjCProtocol, isRequired: Bool, isInstance: Bool) {
            self.proto = proto
            self.isRequired = isRequired
            self.isInstance = isInstance
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<objc_method_description>? {
            protocol_copyMethodDescriptionList(proto.proto, isRequired, isInstance, &count)
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: Selector) -> objc_method_description? {
            let desc = protocol_getMethodDescription(proto.proto, name, isRequired, isInstance)
            // the runtime returns { name: nil, types: nil } if the method is not found
            return desc.name != nil ? desc : nil
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ desc: objc_method_description) -> ObjCProtocol.MethodDetails {
            // The runtime sets the name of each item in the list
            ObjCProtocol.MethodDetails(selector: desc.name!, on: proto.proto, isRequired: isRequired, isInstanceMethod: isInstance)
        }
    }

    /// The protocols adopted by a protocol.
    struct Protocols: RuntimeList {
        public typealias Element = ObjCProtocol

        @usableFromInline let proto: ObjCProtocol

        @inlinable init(on proto: ObjCProtocol) {
            self.proto = proto
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Protocol>? {
            UnsafeMutablePointer(mutating: protocol_copyProtocolList(proto.proto, &count))
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> Protocol? {
            guard let superProto = ObjCProtocol(named: name) else {
                return nil
            }
            return proto.protocols.contains(superProto) ? superProto.proto : nil
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ proto: Protocol) -> ObjCProtocol {
            ObjCProtocol(proto)
        }
    }

    /// All the protocols known to the runtime.
    struct AllProtocols: RuntimeList {
        public typealias Element = ObjCProtocol

        @inlinable init() {}

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Protocol>? {
            UnsafeMutablePointer(mutating: objc_copyProtocolList(&count))
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> Protocol? {
            objc_getProtocol(name)
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ proto: Protocol) -> ObjCProtocol {
            ObjCProtocol(proto)
        }
    }
}
