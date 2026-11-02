//
//  RuntimeList.swift
//
//
//  Created by Nick Randall on 18/9/2024.
//

import Foundation


/// A sequence of wrapped runtime types such as `ObjCMethod` or `ObjCIvar`.
///
/// Can be iterated via a for-in loop, or slightly faster by using `forEach()`.
/// Individual elements can also be looked up by name.
///
/// Each conforming type wraps a pair of runtime functions for creating a list of items and looking up an item by name.
/// For example, getting a list of properties on a class (`class_copyPropertyList`)
/// and looking up a property by name (`class_getProperty`).
public protocol RuntimeList: Sequence, CustomDebugStringConvertible {
    /// The type as defined in the ObjC runtime (e.g. `objc_property_t`).
    associatedtype RuntimeType
    /// The type of the name used to look up items, either `Selector` or `String`.
    associatedtype KeyType
    // The same as how Collection declares IndexingIterator as the default
    associatedtype Iterator = RuntimeIterator<Self>

    // These are only for internal usage but are exposed as `public` for performance reasons.

    /// Fetches the list of items from the runtime.
    @_documentation(visibility: internal)
    func createList(_ count: inout UInt32) -> UnsafeMutablePointer<RuntimeType>?

    /// Finds a single item by name.
    @_documentation(visibility: internal)
    func lookup(name: KeyType) -> RuntimeType?

    /// Wraps the native runtime type into the wrapper type (e.g. `ObjCProperty`).
    @_documentation(visibility: internal)
    func wrap(_ item: RuntimeType) -> Element
}


/// A list of the items of a class, which can also include the items of its superclasses.
public protocol RuntimeClassList: RuntimeList {
    /// The class that the items belong to.
    @_documentation(visibility: internal)
    var cls: ObjCClass { get }

    /// The keypath on `ObjCClass` that produces this list, used for `upTo()`.
    ///
    /// - Note: Making this non-static adds a ton of retain/release calls.
    @_documentation(visibility: internal)
    static var keyPath: KeyPath<ObjCClass, Self> { get }
}


extension RuntimeList {
    /// Fetches the list of items from the runtime.
    /// - Note: The returned buffer must be freed after use.
    @inlinable func createBuffer() -> UnsafeBufferPointer<RuntimeType> {
        var count: UInt32 = 0
        let ptr = createList(&count)
        return UnsafeBufferPointer(start: ptr, count: Int(count))
    }

    /// Calls the given closure on each element in the list.
    ///
    /// This is slightly faster than using a `for-in` loop and as fast as calling the runtime C functions directly.
    @inlinable public func forEach(_ body: (Element) throws -> Void) rethrows {
        let buffer = createBuffer()
        defer { buffer.free() }
        for item in buffer {
            try body(wrap(item))
        }
    }

    @_documentation(visibility: internal)
    @inlinable @inline(__always)
    public func makeIterator() -> RuntimeIterator<Self> {
        RuntimeIterator(list: self)
    }

    /// Returns the item for the given `name` if it exists.
    ///
    /// - Note: On classes, this also returns items defined on superclasses.
    @inlinable public subscript(name: KeyType) -> Element? {
        lookup(name: name).map(wrap)
    }

    /// The number of items in the list.
    /// - Note: The whole list of items will need to be copied from the runtime,
    ///     so using `count` should be avoided if the list will be iterated anyway.
    @inlinable public var count: Int {
        var count: UInt32 = 0
        let ptr = createList(&count)
        free(ptr)
        return Int(count)
    }

    public var debugDescription: String {
        Array(self).debugDescription
    }
}


/// Iterates over a `RuntimeList`, and frees the list from the runtime when it is destroyed.
@_documentation(visibility: internal)
public struct RuntimeIterator<L: RuntimeList>: IteratorProtocol {
    @usableFromInline let list: L
    @usableFromInline let buffer: FreeingBuffer<L.RuntimeType>
    @usableFromInline var iterator: UnsafeBufferPointer<L.RuntimeType>.Iterator

    @inlinable @inline(__always)
    init(list: L) {
        self.list = list
        self.buffer = FreeingBuffer(list.createBuffer())
        self.iterator = self.buffer.buffer.makeIterator()
    }

    @inlinable mutating public func next() -> L.Element? {
        iterator.next().map(list.wrap)
    }
}

extension RuntimeIterator {
    // Nested in the generic iterator, because the compiler only promotes it to the stack in this form.
    // Has its own type parameter, so that deinit does not need to look up L.RuntimeType for each list.
    @usableFromInline
    final class FreeingBuffer<T> {
        @usableFromInline let buffer: UnsafeBufferPointer<T>

        @inlinable init(_ buffer: UnsafeBufferPointer<T>) {
            self.buffer = buffer
        }

        @inlinable deinit {
            buffer.free()
        }
    }
}
