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
    /// Adds or replaces a property on this class.
    /// - Returns: Returns `false` if a property with the same name already exists and `canReplace` was not set.
    /// - Note: To add a class property, call `self.classProperties.add(_:canReplace:)`.
    func add(_ name: String, attributes: ObjCProperty.Attributes, canReplace: Bool = false) -> Bool {
        attributes.withObjCTypes { attribs in
            if canReplace {
                class_replaceProperty(funcs.cls.cls, name, attribs, UInt32(attribs.count))
                return true
            } else {
                return class_addProperty(funcs.cls.cls, name, attribs, UInt32(attribs.count))
            }
        }
    }
}
