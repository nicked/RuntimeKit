import Benchmark
import Foundation
import RuntimeKit

// To run benchmarks:
//
// > swift package benchmark


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
    ])

    Benchmark("iterateClassesDirect") { _ in
        iterateClassesDirect()
    }
    Benchmark("iterateClassesForEach") { _ in
        iterateClassesForEach()
    }
    Benchmark("iterateClassesList") { _ in
        iterateClassesList()
    }
    Benchmark("iterateMethodsDirect") { _ in
        iterateMethodsDirect()
    }
    Benchmark("iterateMethodsForEach") { _ in
        iterateMethodsForEach()
    }
    Benchmark("iterateMethodsList") { _ in
        iterateMethodsList()
    }
    Benchmark("iteratePropsDirect") { _ in
        iteratePropsDirect()
    }
    Benchmark("iteratePropsForEach") { _ in
        iteratePropsForEach()
    }
    Benchmark("iteratePropsList") { _ in
        iteratePropsList()
    }
    Benchmark("iterateIvarsDirect") { _ in
        iterateIvarsDirect()
    }
    Benchmark("iterateIvarsForEach") { _ in
        iterateIvarsForEach()
    }
    Benchmark("iterateIvarsList") { _ in
        iterateIvarsList()
    }
    Benchmark("iterateProtocolsDirect") { _ in
        iterateProtocolsDirect()
    }
    Benchmark("iterateProtocolsForEach") { _ in
        iterateProtocolsForEach()
    }
    Benchmark("iterateProtocolsList") { _ in
        iterateProtocolsList()
    }
}


// MARK: - Classes

func iterateClassesDirect() {
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

func iterateClassesList() {
    for cls in ObjCClass.allClasses {
        blackHole(cls)
    }
}


// MARK: - Methods

func iterateMethodsDirect() {
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

func iterateMethodsList() {
    for cls in ObjCClass.allClasses {
        for method in cls.methods {
            blackHole(method.selector)
        }
    }
}

func iterateMethodsForEach() {
    for cls in ObjCClass.allClasses {
        cls.methods.forEach { method in
            blackHole(method.selector)
        }
    }
}


// MARK: - Properties

func iteratePropsDirect() {
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

func iteratePropsList() {
    for cls in ObjCClass.allClasses {
        for prop in cls.properties {
            blackHole(prop)
        }
    }
}

func iteratePropsForEach() {
    for cls in ObjCClass.allClasses {
        cls.properties.forEach { prop in
            blackHole(prop)
        }
    }
}


// MARK: - Ivars

func iterateIvarsDirect() {
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

func iterateIvarsList() {
    for cls in ObjCClass.allClasses {
        for ivar in cls.ivars {
            blackHole(ivar)
        }
    }
}

func iterateIvarsForEach() {
    for cls in ObjCClass.allClasses {
        cls.ivars.forEach { ivar in
            blackHole(ivar)
        }
    }
}


// MARK: - Protocols

func iterateProtocolsDirect() {
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

func iterateProtocolsList() {
    for cls in ObjCClass.allClasses {
        for proto in cls.protocols {
            blackHole(proto)
        }
    }
}

func iterateProtocolsForEach() {
    for cls in ObjCClass.allClasses {
        cls.protocols.forEach { proto in
            blackHole(proto)
        }
    }
}
