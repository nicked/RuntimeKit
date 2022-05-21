//
//  ObjCClass+RuntimeFuncs.swift
//
//
//  Created by Nick Randall on 28/11/2024.
//

import Foundation


public extension RuntimeList where F: RuntimeClassFuncs {
    /// Returns all items of this class and any superclasses up to but not including `topmostClass`.
    ///
    /// If `topmostClass` is `nil`, all items are returned, even those of the root class.
    func upTo(_ topmostClass: ObjCClass?) -> some Sequence<F.WrapperType> {
        funcs.cls.superclasses(excluding: topmostClass, includeSelf: true)
            .reversed()
            .map { $0[keyPath: F.keyPath] }
            .joined()
    }

    /// Returns all items of this class and any superclasses up to but not including `topmostClass`.
    ///
    /// If `topmostClass` is `nil`, all items are returned, even those of the root class.
    func upTo(_ topmostClass: AnyClass) -> some Sequence<F.WrapperType> {
        upTo(ObjCClass(topmostClass))
    }
}


@_documentation(visibility: internal)
public extension ObjCClass {

    struct Ivars: RuntimeClassFuncs {
        public let cls: ObjCClass

        @inlinable public init(on cls: ObjCClass) {
            self.cls = cls
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Ivar>? {
            class_copyIvarList(cls.cls, &count)
        }

        @inlinable public func lookup(name: String) -> Ivar? {
            class_getInstanceVariable(cls.cls, name)
        }

        @inlinable public func wrap(_ ivar: Ivar) -> ObjCIvar {
            ObjCIvar(ivar)
        }

        public static let keyPath = \ObjCClass.ivars
    }

    struct Properties: RuntimeClassFuncs {
        public let cls: ObjCClass

        @inlinable public init(on cls: ObjCClass) {
            self.cls = cls
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<objc_property_t>? {
            class_copyPropertyList(cls.cls, &count)
        }

        @inlinable public func lookup(name: String) -> objc_property_t? {
            class_getProperty(cls.cls, name)
        }

        @inlinable public func wrap(_ prop: objc_property_t) -> ObjCProperty {
            ObjCProperty(prop)
        }

        public static let keyPath = \ObjCClass.properties
    }

    struct Methods: RuntimeClassFuncs {
        public let cls: ObjCClass

        @inlinable public init(on cls: ObjCClass) {
            self.cls = cls
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Method>? {
            class_copyMethodList(cls.cls, &count)
        }

        @inlinable public func lookup(name: Selector) -> Method? {
            class_getInstanceMethod(cls.cls, name)
        }

        @inlinable public func wrap(_ method: Method) -> ObjCMethod {
            ObjCMethod(method)
        }

        public static let keyPath = \ObjCClass.methods
    }

    struct Protocols: RuntimeClassFuncs {
        public let cls: ObjCClass

        @inlinable public init(on cls: ObjCClass) {
            self.cls = cls
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<Protocol>? {
            UnsafeMutablePointer(mutating: class_copyProtocolList(cls.cls, &count))
        }

        @inlinable public func lookup(name: String) -> Protocol? {
            let proto = objc_getProtocol(name)
            return class_conformsToProtocol(cls.cls, proto) ? proto : nil
        }

        @inlinable public func wrap(_ proto: Protocol) -> ObjCProtocol {
            ObjCProtocol(proto)
        }

        public static let keyPath = \ObjCClass.protocols
    }

    struct All: RuntimeFuncs {
        @inlinable public init() {}

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<AnyClass>? {
            UnsafeMutablePointer(mutating: objc_copyClassList(&count))
        }

        @inlinable public func lookup(name: String) -> AnyClass? {
            objc_lookUpClass(name)
        }

        @inlinable public func wrap(_ cls: AnyClass) -> ObjCClass {
            ObjCClass(cls)
        }
    }

    struct Image: RuntimeFuncs {
        public let imageName: String

        @inlinable public init(named imageName: String) {
            self.imageName = imageName
        }

        @inlinable public func createList(_ count: inout UInt32) -> UnsafeMutablePointer<UnsafePointer<CChar>>? {
            objc_copyClassNamesForImage(imageName, &count)
        }

        @inlinable public func lookup(name: String) -> UnsafePointer<CChar>? {
            guard let cls = objc_lookUpClass(name), let clsImgName = class_getImageName(cls) else {
                return nil
            }
            return String(cString: clsImgName) == imageName ? clsImgName : nil
        }

        @inlinable public func wrap(_ name: UnsafePointer<CChar>) -> ObjCClass {
            ObjCClass(named: String(cString: name))!
        }
    }

}
