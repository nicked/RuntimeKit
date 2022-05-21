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
/// Extended with different functions based on the type of contained item,
/// such as `properties.add()` or `methods.swizzle()`.
public struct RuntimeList<F: RuntimeFuncs>: Sequence {
    @usableFromInline let funcs: F

    @inlinable init(_ fn: F) {
        self.funcs = fn
    }

    /// Fetches the list of items from the runtime.
    /// - Note: The returned buffer must be freed after use.
    @_documentation(visibility: internal)
    @inlinable public func createBuffer() -> UnsafeBufferPointer<F.RuntimeType> {
        var count: UInt32 = 0
        let ptr = funcs.createList(&count)
        return UnsafeBufferPointer(start: ptr, count: Int(count))
    }

    /// Calls the given closure on each element in the list.
    /// 
    /// This is slightly faster than using a `for-in` loop and as fast as calling the runtime C functions directly.
    @inlinable public func forEach(_ body: (Element) throws -> Void) rethrows {
        let buffer = createBuffer()
        for item in buffer {
            try body(funcs.wrap(item))
        }
        buffer.free()
    }

    @_documentation(visibility: internal)
    @inlinable public func makeIterator() -> Iterator {
        Iterator(list: self)
    }

    /// Returns the item for the given `name` if it exists.
    @inlinable public subscript(name: F.KeyType) -> Element? {
        funcs.lookup(name: name).map(funcs.wrap)
    }

    /// The number of items in the list.
    /// - Note: The whole list of items will need to be copied from the runtime,
    ///     so using `count` should be avoided if the list will be iterated anyway.
    @inlinable public var count: Int {
        var count: UInt32 = 0
        let ptr = funcs.createList(&count)
        free(ptr)
        return Int(count)
    }
}

extension RuntimeList: CustomDebugStringConvertible {
    public var debugDescription: String {
        Array(self).debugDescription
    }
}

extension RuntimeList {
    public struct Iterator: IteratorProtocol {
        @usableFromInline let list: RuntimeList
        @usableFromInline let buffer: FreeingBuffer<F.RuntimeType>
        @usableFromInline var iterator: UnsafeBufferPointer<F.RuntimeType>.Iterator

        @inlinable init(list: RuntimeList) {
            self.list = list
            self.buffer = FreeingBuffer(list.createBuffer())
            self.iterator = self.buffer.buffer.makeIterator()
        }

        @inlinable mutating public func next() -> F.WrapperType? {
            iterator.next().map(list.funcs.wrap)
        }
    }
}

@_documentation(visibility: internal)
extension RuntimeList {
    public final class FreeingBuffer<T> {
        @usableFromInline let buffer: UnsafeBufferPointer<T>

        @inlinable init(_ buffer: UnsafeBufferPointer<T>) {
            self.buffer = buffer
        }

        @inlinable deinit {
            buffer.free()
        }
    }
}
