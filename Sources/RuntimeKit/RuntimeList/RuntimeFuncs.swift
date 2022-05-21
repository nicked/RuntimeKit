//
//  RuntimeFuncs.swift
//
//
//  Created by Nick Randall on 19/10/2024.
//

import Foundation


/// Represents a pair of runtime functions for creating a list of items and looking up an item by name.
///
/// For example, getting a list of properties on a class (`class_copyPropertyList`)
/// and looking up a property by name (`class_getProperty`).
/// 
/// Also maps the runtime type to the corresponding wrapper type.
///
/// - Note: This is only for internal usage but is exposed as `public` for performance reasons.
@_documentation(visibility: internal)
public protocol RuntimeFuncs {
    /// The type as defined in the ObjC runtime (e.g. `objc_property_t`).
    associatedtype RuntimeType
    /// The wrapper type (e.g. `ObjCProperty`).
    associatedtype WrapperType
    /// The type of the name used to look up items, either `Selector` or `String`.
    associatedtype KeyType

    /// Fetches the list of items from the runtime.
    func createList(_ count: inout UInt32) -> UnsafeMutablePointer<RuntimeType>?

    /// Finds a single item by name.
    func lookup(name: KeyType) -> RuntimeType?

    /// Wraps the native runtime type into the wrapper type.
    func wrap(_ ivar: RuntimeType) -> WrapperType
}


/// Represents a pair of runtime functions that apply to ObjCClass.
/// Used to add additional methods that handle superclasses.
@_documentation(visibility: internal)
public protocol RuntimeClassFuncs: RuntimeFuncs {
    /// The class that these functions are called on.
    var cls: ObjCClass { get }

    /// The keypath on `ObjCClass` that produces this list, used for `upTo()`.
    ///
    /// - Note: Making this non-static adds a ton of retain/release calls.
    static var keyPath: KeyPath<ObjCClass, RuntimeList<Self>> { get }
}
