//
//  ObjCClass+Create.swift
//
//
//  Created by Nick Randall on 22/8/2024.
//

import Foundation


extension ObjCClass {

    /// Creates and registers a new class with the specified name and ivars.
    ///
    /// Methods, properties and protocol conformances can be added after a class is created.
    ///
    /// - Parameter name: The string to use as the new class's name.
    /// - Parameter superclass: The class to use as the new class's superclass, or `nil` to create a new root class.
    /// - Parameter ivars: Instance variables to add to the new class.
    /// - Parameter extraBytes: The number of bytes to allocate for indexed ivars at the end of the class and metaclass objects. This should usually be 0.
    /// - Returns: Returns `false` if the class name already exists or any duplicate ivar names were passed in.
    public static func create(_ name: String, superclass: ObjCClass?, ivars: [ObjCIvar.Details], extraBytes: Int = 0) -> ObjCClass? {
        guard let cls = objc_allocateClassPair(superclass?.cls, name, extraBytes) else {
            return nil
        }
        for ivar in ivars {
            guard class_addIvar(cls, ivar.name, ivar.size, ivar.alignmentShift, ivar.encoding.str) else {
                return nil
            }
        }
        objc_registerClassPair(cls)
        return ObjCClass(cls)
    }

    /// Destroys a dynamically-created class and its associated metaclass.
    ///
    /// This class must have been created using `create(_:superclass:ivars:extraBytes:)` or `objc_allocateClassPair`.
    /// Do not call this function if instances of the class or any subclass exist.
    public func dispose() {
        objc_disposeClassPair(cls)
    }


    /// Creates an instance of the class.
    ///
    /// - Parameter extraBytes: An integer indicating the number of extra bytes to allocate.
    ///                         The additional bytes can be used to store additional instance variables beyond those defined in the class definition.
    public func createInstance(extraBytes: Int = 0) -> AnyObject? {
        class_createInstance(cls, extraBytes) as AnyObject?
    }
}
