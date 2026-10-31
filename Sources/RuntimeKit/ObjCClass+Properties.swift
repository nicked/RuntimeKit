//
//  ObjCClass+Properties.swift
//  
//
//  Created by Nick Randall on 7/1/2023.
//

import Foundation


public extension ObjCClass {

    /// Returns all instance properties of this class, not including those on superclasses.
    @inlinable var properties: RuntimeList<Properties> {
        RuntimeList(Properties(on: self))
    }


    /// Returns all class properties of this class, not including those on superclasses.
    @inlinable var classProperties: RuntimeList<Properties> {
        RuntimeList(Properties(on: metaClass))
    }
}


public extension RuntimeList where F == ObjCClass.Properties {
    /// Adds a property to this class, only if it doesn't already exist.
    /// - Returns: Returns `false` if this class already has a property with the same name.
    /// - Note: To add a class property, call `self.classProperties.add(_:attributes:)`.
    func add(_ name: String, attributes: ObjCProperty.Attributes) -> Bool {
        attributes.withObjCTypes { attribs in
            class_addProperty(funcs.cls.cls, name, attribs, UInt32(attribs.count))
        }
    }

    /// Adds or replaces a property on this class.
    /// - Note: To set a class property, call `self.classProperties.set(_:attributes:)`.
    func set(_ name: String, attributes: ObjCProperty.Attributes) {
        attributes.withObjCTypes { attribs in
            class_replaceProperty(funcs.cls.cls, name, attribs, UInt32(attribs.count))
        }
    }
}
