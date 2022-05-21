# RuntimeKit

RuntimeKit is a Swift wrapper around the Objective-C runtime.
It provides an intuitive Swift API for inspecting and manipulating Objective-C classes and protocols dynamically.

RuntimeKit does _not_ add any reflection to Swift-only types.
It only operates on types that are already visible to the runtime,
namely classes and protocols defined in Objective-C or exposed from Swift using `@objc`.

See below for [installation instructions](#installation).


## Example

Here's how you would normally get all the property names of an Objective-C class in Swift _without_ RuntimeKit:

```swift
let cls = ExampleClass.self

var count: UInt32 = 0
guard let props = class_copyPropertyList(cls, &count) else {
    return []
}

var names: [String] = []
for n in 0..<count {
    let prop = props[Int(n)]
    let nameCStr = property_getName(prop)
    let name = String(cString: nameCStr)
    names.append(name)
}
free(props)

return names
```

With RuntimeKit this becomes as simple as:

```swift
ObjCClass(ExampleClass.self)
    .properties
    .map(\.name)
```


## Usage

Each of the main Objective-C runtime types are wrapped by a corresponding RuntimeKit type:

* [ObjCClass](Sources/RuntimeKit/ObjCClass.swift)
* [ObjCProtocol](Sources/RuntimeKit/ObjCProtocol.swift)
* [ObjCProperty](Sources/RuntimeKit/ObjCProperty.swift)
* [ObjCMethod](Sources/RuntimeKit/ObjCMethod.swift)
* [ObjCIvar](Sources/RuntimeKit/ObjCIvar.swift)

Just wrap an `AnyClass` or `Protocol` to start introspecting it:

```swift
let cls = ObjCClass(NSMeasurement.self)

print(cls.superclass)   // NSObject
print(cls.isRootClass)  // false
print(cls.protocols)    // NSCopying, NSSecureCoding
print(cls.properties)   // unit, doubleValue
print(cls.ivars)        // _unit, _doubleValue
print(cls.methods)      // canBeConvertedToUnit:, measurementByAddingMeasurement:, hash, isEqual: ...
print(cls.classMethods) // supportsSecureCoding
```



### Iterating over members

Properties, methods, ivars and protocols can be iterated using standard `for-in` loop syntax:

```swift
for prop in cls.properties {
    print(prop.name, prop.attributes.encoding)
}

// unit  @"NSUnit"
// doubleValue  d
```

Or accessed by name using subscripts:

```swift
let ivar = cls.ivars["_unit"]!
print(ivar.offset)      // 8
```

Every class and protocol known to the runtime can also be iterated:

```swift
for cls in ObjCClass.allClasses {
    // ...
}

for proto in ObjCProtocol.allProtocols {
    // ...
}
```


### Traversing superclasses

Normally only the direct members of the wrapped class are returned.
To access the members inherited from superclasses, use the `upTo` function:

```swift
let cls = ObjCClass(NSMutableArray.self)

// Only methods directly on NSMutableArray:
print(cls.methods)                     // 122 methods

// Include methods on superclasses up to but excluding NSObject.
// i.e. NSMutableArray + NSArray:
print(cls.methods.upTo(NSObject.self)) // 552 methods

// Include methods on all superclasses.
// i.e. NSMutableArray + NSArray + NSObject:
print(cls.methods.upTo(nil))           // 998 methods
```


### Dynamically add members to classes

Properties, methods and protocols can be attached to any class at runtime:

```swift
let cls = ObjCClass(NSObject.self)

let obj = NSObject()

// obj.value(forKey: "foo")
// -- would crash with: class is not key value coding-compliant for the key foo.

// Create a method body
let body: @convention(block) (AnyClass) -> Int = { _ in
    return 123
}

// Dynamically add it to the class
cls.methods.add(with: "foo", types: "q@:", block: body)

// Add a corresponding property (not strictly necessary)
cls.properties.add("foo", attributes: .init(
    nonAtomic: true,
    readOnly: true,
    encoding: "q"
))

// Now this will succeed
print(obj.value(forKey: "foo")) // 123
```


### Swizzle methods

Exchange the implementations of two methods:

```swift
cls.methods.swizzle("foo", with: "bar")

// or:
let m1 = cls.methods["foo"]!
let m2 = cls.methods["bar"]!
m1.swizzle(with: m2)

// or replace an implementation directly:
m1.implementationBlock = { _ in
    return 999
} as @convention(block) (AnyClass) -> Int
```


### Create classes and protocols dynamically

Entirely new classes can be defined at runtime:

```swift
let newCls = ObjCClass.create(
    "MyClass",
    superclass: cls,
    ivars: [
        .init(name: "_foo", encoding: "i"),
        .init(name: "_bar", encoding: "c"),
    ]
)

// add any properties, methods, protocols...
```

### Runtime helpers

Swift wrappers for `NSInvocation` and `NSMethodSignature` are also included, with strongly typed accessors for arguments and return types.


## Performance notes

RuntimeKit is designed to have almost no overhead compared to calling the Objective-C runtime functions directly.

* The wrapper types (`ObjCClass` etc) are single-member structs with zero cost to create.
* Most functions are `@inlinable` thus have zero additional cost to call.

An exception is where C strings are converted to `String` but to minimise this, methods are referenced by `Selector` instead of name.

### Iterator performance

Class and protocol members (properties, methods, etc) are returned as `Sequence` not`Array` so no heap allocations are required.
The performance of iterating these using `for-in` loops is close to that of using the runtime functions directly.
However if maximum performance is needed (e.g. iterating every property of every class), use the alternate `forEach` method:

```swift
// Fast:
for prop in cls.properties {
    // ...
}

// Fastest:
cls.properties.forEach { prop in
    // ...
}
```

Avoid using `count` on these member iterators if you plan to loop through them anyway, as it requires fetching all the items from the runtime.

See my [post on iterator performance](https://ko9.org/posts/swift-runtime-2-performance/) for all the details.



## Installation

Add RuntimeKit to your `Package.swift`:

```swift
Package(
    // ...
    dependencies: [
        .package(url: "https://github.com/nicked/RuntimeKit.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            // ...
            dependencies: ["RuntimeKit"]
        ),
    ]
)

```


