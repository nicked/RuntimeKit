//
//  ObjCClass+Protocols.swift
//
//
//  Created by Nick Randall on 7/10/2024.
//

import Foundation


public extension ObjCClass {

    /// Returns all protocols that this class directly conforms to, not including those on superclasses.
    @inlinable var protocols: RuntimeList<Protocols> {
        RuntimeList(Protocols(on: self))
    }
}


public extension RuntimeList where F == ObjCClass.Protocols {
    /// Returns a boolean value that indicates whether a class directly conforms to a given protocol.
    ///
    /// This does _not_ check superclasses for conformance to the protocol.
    func contains(_ proto: ObjCProtocol) -> Bool {
        class_conformsToProtocol(funcs.cls.cls, proto.proto)
    }

    /// Adds a protocol conformance to this class.
    /// - Returns: Returns `false` if the class already conforms to the protocol.
    func add(_ proto: ObjCProtocol) -> Bool {
        class_addProtocol(funcs.cls.cls, proto.proto)
    }
}
