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
    /// Adds or replaces a method on this class.
    ///
    /// To add a class method, call `self.classMethods.add(with:types:imp:canReplace:)`.
    /// - Returns: Returns `false` if a method with the same name already exists and `canReplace` was not set.
    /// - Parameter types: The full method encoding including the return type, receiver, selector and argument types.
    /// - Returns: Returns `false` if a method with the same name already exists and `canReplace` was not set.
    func add(with selector: Selector, types: MethodTypeEncodings, imp: IMP, canReplace: Bool = false) -> Bool {
        if canReplace {
            class_replaceMethod(funcs.cls.cls, selector, imp, types.encoded)
            return true
        } else {
            return class_addMethod(funcs.cls.cls, selector, imp, types.encoded)
        }
    }

    /// Adds or replaces a method on this class.
    ///
    /// To add a class method, call `self.classMethods.add(with:types:block:canReplace:)`.
    /// - Returns: Returns `false` if a method with the same name already exists and `canReplace` was not set.
    /// - Parameter types: The full method encoding including the return type, receiver, selector and argument types.
    /// - Parameter block: A closure that accepts an instance of this class (the receiver) as the first argument.
    ///     It must be declared with `@convention(block)`.
    /// - Returns: Returns `false` if a method with the same name already exists and `canReplace` was not set.
    func add(with selector: Selector, types: MethodTypeEncodings, block: Any, canReplace: Bool = false) -> Bool {
        add(with: selector, types: types, imp: imp_implementationWithBlock(block), canReplace: canReplace)
    }

    /// The function pointer that would be called if the given message was sent to an instance of this class.
    ///
    /// If instances of this class do not respond to the selector, the returned `IMP` will be part of the runtime's message forwarding machinery.
    /// May be faster than calling `methods[selector].implementation`.
    func implementation(for selector: Selector) -> IMP {
        class_getMethodImplementation(funcs.cls.cls, selector)!
    }

    /// Exchanges the implementations of two methods on this class.
    ///
    /// Both methods must be declared `@objc dynamic` in Swift for this to work.
    /// - Returns: Returns `false` if either of the methods don't exist or if both selectors are the same.
    /// - Warning: Will cause an assertion if the method encodings are different.
    func swizzle(_ sel1: Selector, with sel2: Selector) -> Bool {
        guard sel1 != sel2, let m1 = self[sel1], let m2 = self[sel2] else {
            return false
        }

        m1.swizzle(with: m2)
        return true
    }
}
