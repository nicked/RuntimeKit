//
//  ObjCClass+Methods.swift
//  
//
//  Created by Nick Randall on 7/1/2023.
//

import Foundation


public extension ObjCClass {

    /// Returns all instance methods of this class, not including those on superclasses.
    @inlinable var methods: RuntimeList<Methods> {
        RuntimeList(Methods(on: self))
    }

    /// Returns all class methods of this class, not including those on superclasses.
    @inlinable var classMethods: RuntimeList<Methods> {
        RuntimeList(Methods(on: metaClass))
    }
}


public extension RuntimeList where F == ObjCClass.Methods {
    /// Adds a method to this class, only if it doesn't already exist.
    ///
    /// To add a class method, call `self.classMethods.add(_:types:imp:)`.
    /// - Parameter types: All the types of the method: the return type, receiver, selector and argument types.
    /// - Returns: Returns `false` if this class already has a method with the same selector.
    func add(_ selector: Selector, types: MethodTypeEncodings, imp: IMP) -> Bool {
        class_addMethod(funcs.cls.cls, selector, imp, types.encoded)
    }

    /// Adds a method to this class, only if it doesn't already exist.
    ///
    /// To add a class method, call `self.classMethods.add(_:types:block:)`.
    /// - Parameter types: All the types of the method: the return type, receiver, selector and argument types.
    /// - Parameter block: A closure that accepts an instance of this class (the receiver) as the first argument.
    ///     It must be declared with `@convention(block)`.
    /// - Returns: Returns `false` if this class already has a method with the same selector.
    func add(_ selector: Selector, types: MethodTypeEncodings, block: Any) -> Bool {
        let imp = imp_implementationWithBlock(block)
        guard add(selector, types: types, imp: imp) else {
            imp_removeBlock(imp)
            return false
        }
        return true
    }

    /// Adds or replaces a method on this class.
    ///
    /// To set a class method, call `self.classMethods.set(_:types:imp:)`.
    /// - Parameter types: All the types of the method: the return type, receiver, selector and argument types.
    /// - Returns: The previous implementation, or `nil` if this class did not already have the method.
    @discardableResult
    func set(_ selector: Selector, types: MethodTypeEncodings, imp: IMP) -> IMP? {
        class_replaceMethod(funcs.cls.cls, selector, imp, types.encoded)
    }

    /// Adds or replaces a method on this class.
    ///
    /// To set a class method, call `self.classMethods.set(_:types:block:)`.
    /// - Parameter types: All the types of the method: the return type, receiver, selector and argument types.
    /// - Parameter block: A closure that accepts an instance of this class (the receiver) as the first argument.
    ///     It must be declared with `@convention(block)`.
    /// - Returns: The previous implementation, or `nil` if this class did not already have the method.
    @discardableResult
    func set(_ selector: Selector, types: MethodTypeEncodings, block: Any) -> IMP? {
        set(selector, types: types, imp: imp_implementationWithBlock(block))
    }

    /// The function pointer that would be called if the given message was sent to an instance of this class.
    ///
    /// If instances of this class do not respond to the selector, the returned `IMP` will be part of the runtime's message forwarding machinery.
    /// May be faster than calling `methods[selector].implementation`.
    func implementation(for selector: Selector) -> IMP {
        // Only nil for a nil class or selector. Otherwise returns _objc_msgForward if not found
        class_getMethodImplementation(funcs.cls.cls, selector)!
    }

    /// Exchanges the implementations of two methods on this class.
    ///
    /// Both methods must be declared `@objc dynamic` in Swift for this to work.
    /// If either method is inherited, it is first added to this class, so superclasses are not affected.
    /// - Returns: Returns `false` if either of the methods don't exist or if both selectors are the same.
    /// - Warning: Will cause an assertion if the method encodings are different.
    func swizzle(_ sel1: Selector, with sel2: Selector) -> Bool {
        guard sel1 != sel2, var m1 = self[sel1], var m2 = self[sel2] else {
            return false
        }

        // An inherited method belongs to the superclass, so exchanging it would also change the superclass
        // and its other subclasses. class_addMethod does nothing if this class already has the method.
        // If it adds a copy to this class, look up the copy, because that is the method to exchange.
        let cls: AnyClass = funcs.cls.cls
        m1 = class_addMethod(cls, sel1, m1.implementation, method_getTypeEncoding(m1.method)) ? self[sel1]! : m1
        m2 = class_addMethod(cls, sel2, m2.implementation, method_getTypeEncoding(m2.method)) ? self[sel2]! : m2

        m1.swizzle(with: m2)
        return true
    }
}
