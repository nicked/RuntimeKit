import Benchmark
import Foundation
import RuntimeKit

// To run benchmarks from the root of the repo:
//
// > swift package --package-path Benchmarks benchmark


let benchmarks = {
    Benchmark.defaultConfiguration = Benchmark.Configuration(metrics: [
        .cpuTotal,
        .throughput,
        .peakMemoryResidentDelta,
        .mallocCountSmall,
        .mallocCountLarge,
        .memoryLeaked,
        .instructions,
        .objectAllocCount,
        .retainCount,
        .releaseCount,
        .retainReleaseDelta,
    ], units: [
        // Use the same units in every benchmark, so that the results can be compared
        .instructions: .kilo,
        .mallocCountTotal: .count,
        .mallocCountSmall: .count,
        .mallocCountLarge: .count,
        .retainCount: .count,
        .releaseCount: .count,
    ])

    Benchmark("iterateClassesObjC") { _ in
        iterateClassesObjC()
    }
    Benchmark("iterateClassesForEach") { _ in
        iterateClassesForEach()
    }
    Benchmark("iterateClassesSequence") { _ in
        iterateClassesSequence()
    }
    Benchmark("iterateMethodsObjC") { _ in
        iterateMethodsObjC()
    }
    Benchmark("iterateMethodsForEach") { _ in
        iterateMethodsForEach()
    }
    Benchmark("iterateMethodsSequence") { _ in
        iterateMethodsSequence()
    }
    Benchmark("iteratePropsObjC") { _ in
        iteratePropsObjC()
    }
    Benchmark("iteratePropsForEach") { _ in
        iteratePropsForEach()
    }
    Benchmark("iteratePropsSequence") { _ in
        iteratePropsSequence()
    }
    Benchmark("iterateIvarsObjC") { _ in
        iterateIvarsObjC()
    }
    Benchmark("iterateIvarsForEach") { _ in
        iterateIvarsForEach()
    }
    Benchmark("iterateIvarsSequence") { _ in
        iterateIvarsSequence()
    }
    Benchmark("iterateProtocolsObjC") { _ in
        iterateProtocolsObjC()
    }
    Benchmark("iterateProtocolsForEach") { _ in
        iterateProtocolsForEach()
    }
    Benchmark("iterateProtocolsSequence") { _ in
        iterateProtocolsSequence()
    }
    Benchmark("iterateAllProtocolsObjC") { _ in
        iterateAllProtocolsObjC()
    }
    Benchmark("iterateAllProtocolsForEach") { _ in
        iterateAllProtocolsForEach()
    }
    Benchmark("iterateAllProtocolsSequence") { _ in
        iterateAllProtocolsSequence()
    }
    Benchmark("iterateProtocolMethodsObjC") { _ in
        iterateProtocolMethodsObjC()
    }
    Benchmark("iterateProtocolMethodsForEach") { _ in
        iterateProtocolMethodsForEach()
    }
    Benchmark("iterateProtocolMethodsSequence") { _ in
        iterateProtocolMethodsSequence()
    }
    Benchmark("lookupMethodObjC") { _ in
        lookupMethodObjC()
    }
    Benchmark("lookupMethodSubscript") { _ in
        lookupMethodSubscript()
    }
    Benchmark("lookupPropObjC") { _ in
        lookupPropObjC()
    }
    Benchmark("lookupPropSubscript") { _ in
        lookupPropSubscript()
    }
    Benchmark("lookupIvarObjC") { _ in
        lookupIvarObjC()
    }
    Benchmark("lookupIvarSubscript") { _ in
        lookupIvarSubscript()
    }
}


// MARK: - Classes

func iterateClassesObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        blackHole(cls)
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func iterateClassesForEach() {
    ObjCClass.allClasses.forEach { cls in
        blackHole(cls)
    }
}

func iterateClassesSequence() {
    for cls in ObjCClass.allClasses {
        blackHole(cls)
    }
}


// MARK: - Methods

func iterateMethodsObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        var methodCount: UInt32 = 0
        guard let methods = class_copyMethodList(cls, &methodCount) else {
            continue
        }
        for k in 0..<Int(methodCount) {
            let method = methods[k]
            blackHole(method_getName(method))
        }
        free(methods)
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func iterateMethodsSequence() {
    for cls in ObjCClass.allClasses {
        for method in cls.methods {
            blackHole(method.selector)
        }
    }
}

func iterateMethodsForEach() {
    ObjCClass.allClasses.forEach { cls in
        cls.methods.forEach { method in
            blackHole(method.selector)
        }
    }
}


// MARK: - Properties

func iteratePropsObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        var propCount: UInt32 = 0
        guard let props = class_copyPropertyList(cls, &propCount) else {
            continue
        }
        for k in 0..<Int(propCount) {
            let prop = props[k]
            blackHole(prop)
        }
        free(props)
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func iteratePropsSequence() {
    for cls in ObjCClass.allClasses {
        for prop in cls.properties {
            blackHole(prop)
        }
    }
}

func iteratePropsForEach() {
    ObjCClass.allClasses.forEach { cls in
        cls.properties.forEach { prop in
            blackHole(prop)
        }
    }
}


// MARK: - Ivars

func iterateIvarsObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        var ivarCount: UInt32 = 0
        guard let ivars = class_copyIvarList(cls, &ivarCount) else {
            continue
        }
        for k in 0..<Int(ivarCount) {
            let ivar = ivars[k]
            blackHole(ivar)
        }
        free(ivars)
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func iterateIvarsSequence() {
    for cls in ObjCClass.allClasses {
        for ivar in cls.ivars {
            blackHole(ivar)
        }
    }
}

func iterateIvarsForEach() {
    ObjCClass.allClasses.forEach { cls in
        cls.ivars.forEach { ivar in
            blackHole(ivar)
        }
    }
}


// MARK: - Protocols

func iterateProtocolsObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        var protoCount: UInt32 = 0
        guard let protos = class_copyProtocolList(cls, &protoCount) else {
            continue
        }
        for k in 0..<Int(protoCount) {
            let proto = protos[k]
            blackHole(proto)
        }
        free(UnsafeMutableRawPointer(mutating: protos))
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func iterateProtocolsSequence() {
    for cls in ObjCClass.allClasses {
        for proto in cls.protocols {
            blackHole(proto)
        }
    }
}

func iterateProtocolsForEach() {
    ObjCClass.allClasses.forEach { cls in
        cls.protocols.forEach { proto in
            blackHole(proto)
        }
    }
}


// MARK: - All protocols

func iterateAllProtocolsObjC() {
    var protoCount: UInt32 = 0
    let protos = objc_copyProtocolList(&protoCount)!
    for k in 0..<Int(protoCount) {
        blackHole(protos[k])
    }
    free(UnsafeMutableRawPointer(protos))
}

func iterateAllProtocolsSequence() {
    for proto in ObjCProtocol.allProtocols {
        blackHole(proto)
    }
}

func iterateAllProtocolsForEach() {
    ObjCProtocol.allProtocols.forEach { proto in
        blackHole(proto)
    }
}


// MARK: - Protocol methods

func iterateProtocolMethodsObjC() {
    var protoCount: UInt32 = 0
    let protos = objc_copyProtocolList(&protoCount)!
    for k in 0..<Int(protoCount) {
        var methodCount: UInt32 = 0
        guard let methods = protocol_copyMethodDescriptionList(protos[k], true, true, &methodCount) else {
            continue
        }
        for m in 0..<Int(methodCount) {
            blackHole(methods[m].name)
        }
        free(methods)
    }
    free(UnsafeMutableRawPointer(protos))
}

func iterateProtocolMethodsSequence() {
    for proto in ObjCProtocol.allProtocols {
        for method in proto.requiredMethods {
            blackHole(method.selector)
        }
    }
}

func iterateProtocolMethodsForEach() {
    ObjCProtocol.allProtocols.forEach { proto in
        proto.requiredMethods.forEach { method in
            blackHole(method.selector)
        }
    }
}


// MARK: - Lookups by name

// Each lookup runs once on every class, so that it also searches superclasses

let lookupSelector = #selector(NSObject.isEqual(_:))

func lookupMethodObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        blackHole(class_getInstanceMethod(cls, lookupSelector))
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func lookupMethodSubscript() {
    ObjCClass.allClasses.forEach { cls in
        blackHole(cls.methods[lookupSelector])
    }
}

func lookupPropObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        blackHole(class_getProperty(cls, "hash"))
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func lookupPropSubscript() {
    ObjCClass.allClasses.forEach { cls in
        blackHole(cls.properties["hash"])
    }
}

func lookupIvarObjC() {
    var classCount: UInt32 = 0
    let firstCls = objc_copyClassList(&classCount)!
    let classes = UnsafeBufferPointer(start: firstCls, count: Int(classCount))
    for cls in classes {
        blackHole(class_getInstanceVariable(cls, "isa"))
    }
    free(UnsafeMutablePointer(mutating: firstCls))
}

func lookupIvarSubscript() {
    ObjCClass.allClasses.forEach { cls in
        blackHole(cls.ivars["isa"])
    }
}