//
//  ObjCProtocol.swift
//  
//
//  Created by Nick Randall on 27/12/2022.
//

import Foundation


/// Wraps a runtime protocol.
public struct ObjCProtocol {
    @usableFromInline let proto: Protocol

    /// Creates a wrapper of the specified Protocol.
    @inlinable public init(_ proto: Protocol) {
        self.proto = proto
    }

    /// Creates a wrapper of the named protocol.
    /// - Returns: Returns `nil` if the protocol could not be found.
    @inlinable public init?(named name: String) {
        guard let proto = objc_getProtocol(name) else {
            return nil
        }
        self = Self(proto)
    }

    // MARK: - Basic attributes

    /// Returns the name of the protocol.
    ///
    /// This can be a mangled or prefixed name if the protocol is defined in Swift.
    @inlinable public var name: String {
        protocol_getName(proto).asString
    }

    // MARK: - Properties

    /// A list of the instance properties declared by the protocol.
    @inlinable public var properties: RuntimeList<Properties> {
        RuntimeList(Properties(on: self, isInstance: true))
    }

    /// A list of the class properties declared by the protocol.
    @inlinable public var classProperties: RuntimeList<Properties> {
        RuntimeList(Properties(on: self, isInstance: false))
    }


    // MARK: - Methods

    /// A list of the required instance methods declared by the protocol.
    @inlinable public var requiredMethods: RuntimeList<Methods> {
        RuntimeList(Methods(on: self, isRequired: true, isInstance: true))
    }

    /// A list of the optional instance methods declared by the protocol.
    @inlinable public var optionalMethods: RuntimeList<Methods> {
        RuntimeList(Methods(on: self, isRequired: false, isInstance: true))
    }

    /// A list of the required class methods declared by the protocol.
    @inlinable public var requiredClassMethods: RuntimeList<Methods> {
        RuntimeList(Methods(on: self, isRequired: true, isInstance: false))
    }

    /// A list of the optional class methods declared by the protocol.
    @inlinable public var optionalClassMethods: RuntimeList<Methods> {
        RuntimeList(Methods(on: self, isRequired: false, isInstance: false))
    }

    
    // MARK: - Other protocols

    /// A list of the protocols adopted by the protocol.
    @inlinable public var protocols: RuntimeList<Protocols> {
        RuntimeList(Protocols(on: self))
    }

    /// A list of all the protocols known to the runtime.
    @inlinable public static var allProtocols: RuntimeList<All> {
        RuntimeList(All())
    }
}


extension ObjCProtocol: Equatable {
    public static func == (lhs: ObjCProtocol, rhs: ObjCProtocol) -> Bool {
        protocol_isEqual(lhs.proto, rhs.proto)
    }
}


extension ObjCProtocol: CustomStringConvertible {
    public var description: String {
        name
    }
}

extension ObjCProtocol: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(Self.self)(\(name))"
    }
}


extension RuntimeList where F == ObjCProtocol.Protocols {
    /// Returns a boolean value that indicates whether this protocol conforms to another protocol.
    public func contains(_ other: ObjCProtocol) -> Bool {
        protocol_conformsToProtocol(funcs.proto.proto, other.proto)
    }
}
