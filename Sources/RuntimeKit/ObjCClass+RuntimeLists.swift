//
//  ObjCClass+RuntimeFuncs.swift
//
//
//  Created by Nick Randall on 28/11/2024.
//

import Foundation


public extension RuntimeClassList {
    /// Returns all items of this class and any superclasses up to but not including `topmostClass`.
    ///
    /// If `topmostClass` is `nil`, all items are returned, even those of the root class.
    func upTo(_ topmostClass: ObjCClass?) -> some Sequence<Element> {
        // Lists of class members (e.g. `classMethods`) are on the metaclass,
        // so the traversal must stop at the metaclass of `topmostClass`.
        var topmostClass = topmostClass
        if cls.isMetaClass, let top = topmostClass, !top.isMetaClass {
            topmostClass = top.metaClass
        }
        return cls.superclasses(excluding: topmostClass, includeSelf: true)
            .reversed()
            .map { $0[keyPath: Self.keyPath] }
            .joined()
    }

    /// Returns all items of this class and any superclasses up to but not including `topmostClass`.
    ///
    /// If `topmostClass` is `nil`, all items are returned, even those of the root class.
    func upTo(_ topmostClass: AnyClass) -> some Sequence<Element> {
        upTo(ObjCClass(topmostClass))
    }
}


public extension ObjCClass {

    /// The instance variables of a class.
    struct Ivars: RuntimeClassList {
        public typealias Element = ObjCIvar

        @_documentation(visibility: internal)
        public let cls: ObjCClass

        @inlinable init(on cls: ObjCClass) {
            self.cls = cls
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Ivar>? {
            class_copyIvarList(cls.cls, &count)
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> Ivar? {
            class_getInstanceVariable(cls.cls, name)
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ ivar: Ivar) -> ObjCIvar {
            ObjCIvar(ivar)
        }

        @_documentation(visibility: internal)
        public static let keyPath = \ObjCClass.ivars
    }

    /// The instance or class properties of a class.
    struct Properties: RuntimeClassList {
        public typealias Element = ObjCProperty

        @_documentation(visibility: internal)
        public let cls: ObjCClass

        @inlinable init(on cls: ObjCClass) {
            self.cls = cls
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<objc_property_t>? {
            class_copyPropertyList(cls.cls, &count)
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> objc_property_t? {
            class_getProperty(cls.cls, name)
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ prop: objc_property_t) -> ObjCProperty {
            ObjCProperty(prop)
        }

        @_documentation(visibility: internal)
        public static let keyPath = \ObjCClass.properties
    }

    /// The instance or class methods of a class.
    struct Methods: RuntimeClassList {
        public typealias Element = ObjCMethod

        @_documentation(visibility: internal)
        public let cls: ObjCClass

        @inlinable init(on cls: ObjCClass) {
            self.cls = cls
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Method>? {
            class_copyMethodList(cls.cls, &count)
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: Selector) -> Method? {
            class_getInstanceMethod(cls.cls, name)
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ method: Method) -> ObjCMethod {
            ObjCMethod(method)
        }

        @_documentation(visibility: internal)
        public static let keyPath = \ObjCClass.methods
    }

    /// The protocols that a class directly conforms to.
    struct Protocols: RuntimeClassList {
        public typealias Element = ObjCProtocol

        @_documentation(visibility: internal)
        public let cls: ObjCClass

        @inlinable init(on cls: ObjCClass) {
            self.cls = cls
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Protocol>? {
            UnsafeMutablePointer(mutating: class_copyProtocolList(cls.cls, &count))
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> Protocol? {
            guard let proto = objc_getProtocol(name) else {
                return nil
            }
            return class_conformsToProtocol(cls.cls, proto) ? proto : nil
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ proto: Protocol) -> ObjCProtocol {
            ObjCProtocol(proto)
        }

        @_documentation(visibility: internal)
        public static let keyPath = \ObjCClass.protocols
    }

    /// All the classes registered in the runtime.
    struct AllClasses: RuntimeList {
        public typealias Element = ObjCClass

        @inlinable init() {}

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<AnyClass>? {
            UnsafeMutablePointer(mutating: objc_copyClassList(&count))
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> AnyClass? {
            objc_lookUpClass(name)
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ cls: AnyClass) -> ObjCClass {
            ObjCClass(cls)
        }
    }

    /// The classes defined in a library or framework.
    struct ImageClasses: RuntimeList {
        public typealias Element = ObjCClass

        @usableFromInline let imageName: String

        @inlinable init(named imageName: String) {
            self.imageName = imageName
        }

        @_documentation(visibility: internal)
        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<UnsafePointer<CChar>>? {
            objc_copyClassNamesForImage(imageName, &count)
        }

        @_documentation(visibility: internal)
        @inlinable public func lookup(name: String) -> UnsafePointer<CChar>? {
            guard let cls = objc_lookUpClass(name), let clsImgName = class_getImageName(cls) else {
                return nil
            }
            return String(cString: clsImgName) == imageName ? class_getName(cls) : nil
        }

        @_documentation(visibility: internal)
        @inlinable public func wrap(_ name: UnsafePointer<CChar>) -> ObjCClass {
            // objc_copyClassNamesForImage skips the classes that the runtime ignores
            ObjCClass(objc_lookUpClass(name)!)
        }
    }

}
