//
//  ObjCClass.swift
//  
//
//  Created by Nick Randall on 27/12/2022.
//

import Foundation
import RuntimeFix


/// Wraps a runtime class.
public struct ObjCClass {
    @usableFromInline let cls: AnyClass

    /// Creates a wrapper of the specified class.
    @inlinable public init(_ cls: AnyClass) {
        self.cls = cls
    }

    /// Creates a wrapper of the named class.
    /// - Returns: Returns `nil` if the class is not registered with the Objective-C runtime.
    @inlinable public init?(named className: String) {
        guard let cls = objc_lookUpClass(className) else {
            return nil
        }
        self = ObjCClass(cls)
    }
}


// MARK: - Basic attributes

public extension ObjCClass {

    /// Returns the name of this class.
    @inlinable var name: String {
        class_getName(cls).asString
    }

    /// Returns the superclass of this class, or nil if this is a root class.
    @inlinable var superclass: ObjCClass? {
        class_getSuperclass(cls).map(ObjCClass.init)
    }

    /// Returns the size in bytes of instances of this class.
    @inlinable var instanceSize: Int {
        class_getInstanceSize(cls)
    }

    /// Returns the metaclass of this class.
    @inlinable var metaClass: ObjCClass {
        ObjCClass(class_getMetaclass(cls))
    }

    /// Returns a boolean value that indicates whether this class is a metaclass.
    @inlinable var isMetaClass: Bool {
        class_isMetaClass(cls)
    }

    /// Returns a boolean value that indicates whether this class is a root class.
    @inlinable var isRootClass: Bool {
        class_getSuperclass(cls) == nil
    }

    /// Returns the name of the dynamic library this class originated from.
    /// - Returns: Returns `nil` if the class was created dynamically.
    @inlinable var imageName: String? {
        class_getImageName(cls)?.asString
    }

    /// The version number of this class definition.
    @inlinable var version: Int {
        get { Int(class_getVersion(cls)) }
        nonmutating set { class_setVersion(cls, Int32(newValue)) }
    }
}


// MARK: - Other classes

public extension ObjCClass {

    /// A list of all the classes registered in the runtime.
    @inlinable static var allClasses: RuntimeList<All> {
        RuntimeList(All())
    }

    /// Returns all registered class definitions within a specified library or framework.
    static func allClasses(in imageName: String) -> RuntimeList<Image> {
        RuntimeList(Image(named: imageName))
    }

    /// Returns an array of the superclasses of this class up to but not including `topmostClass`.
    /// - Parameter topmostClass: If set to `nil`, all superclasses are returned, even the root class.
    /// - Parameter includeSelf: Whether the current class should be at the start of the returned array.
    func superclasses(excluding topmostClass: ObjCClass? = nil, includeSelf: Bool = false) -> [ObjCClass] {
        var superclasses: [ObjCClass] = []
        var cls = self
        while cls != topmostClass {
            if cls != self || includeSelf {
                superclasses.append(cls)
            }
            guard let superclass = cls.superclass else { break }
            cls = superclass
        }
        return superclasses
    }

    /// Returns a list of all known subclasses of this class.
    /// - Parameter directOnly: Whether to include direct subclasses only or to include all subclasses.
    func subclasses(directOnly: Bool = false) -> some Sequence<ObjCClass> {
        Self.allClasses.lazy.filter {
            $0.isSubclass(of: self, directOnly: directOnly)
        }
    }

    /// Returns a Boolean value that indicates whether the receiving class is a subclass of a given class.
    /// - Parameter directOnly: Whether to test for a direct subclass relationship only or to also include ancestor superclasses.
    func isSubclass(of other: ObjCClass, directOnly: Bool = false) -> Bool {
        if directOnly {
            return superclass == other
        }
        var supercls = superclass
        while supercls != nil {
            if supercls == other {
                return true
            }
            supercls = supercls?.superclass
        }
        return false
    }
}


extension ObjCClass: Equatable {
    public static func == (lhs: ObjCClass, rhs: ObjCClass) -> Bool {
        // Can't compare on cls itself, because the values returned from objc_copyClassList
        // and from objc_lookUpClass for the same class are different
        lhs.name == rhs.name
    }
}

extension ObjCClass: CustomStringConvertible {
    public var description: String {
        "\(name): \(superclass?.name ?? "root class")"
    }
}

extension ObjCClass: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(Self.self)(\(name))"
    }
}
