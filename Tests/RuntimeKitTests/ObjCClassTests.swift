//
//  ObjCClassTests.swift
//  
//
//  Created by Nick Randall on 28/12/2022.
//

import RuntimeKit
import XCTest


final class ObjCClassTests: XCTestCase {

    let cls = ObjCClass(ExampleClass.self)
    let prop = ObjCProperty.Details(name: "exampleProp", attributes: .init(nonAtomic: true, encoding: .longLong, ivarName: "exampleProp"))
    let clsProp = ObjCProperty.Details(name: "exampleClassProp", attributes: .init(nonAtomic: true, encoding: .longLong))

    let subCls = ObjCClass(ExampleSubClass.self)
    let subProp = ObjCProperty.Details(name: "exampleSubProp", attributes: .init(nonAtomic: true, encoding: .longLong, ivarName: "exampleSubProp"))
    let subClsProp = ObjCProperty.Details(name: "exampleSubClassProp", attributes: .init(nonAtomic: true, encoding: .longLong))

    let nsObjCls = ObjCClass(NSObject.self)

    func testInstanceProperties() {
        XCTAssertEqual(cls.properties.map(\.details), [prop])
        XCTAssertEqual(cls.properties["exampleProp"]?.details, prop)
        XCTAssertNil(cls.properties["exampleClassProp"])
        XCTAssertGreaterThan(Array(cls.properties.upTo(nil)).count, 1)
    }

    func testClassProperties() {
        XCTAssertEqual(cls.classProperties.map(\.details), [clsProp])
        XCTAssertEqual(cls.classProperties["exampleClassProp"]?.details, clsProp)
        XCTAssertNil(cls.classProperties["exampleProp"])
        XCTAssertGreaterThan(Array(cls.classProperties.upTo(nil)).count, 1)
    }

    func testSubclassInstanceProperties() {
        XCTAssertEqual(subCls.properties.map(\.details), [subProp])
        XCTAssertEqual(subCls.properties["exampleSubProp"]?.details, subProp)
        XCTAssertNil(subCls.properties["exampleSubClassProp"])
        XCTAssertEqual(subCls.properties.upTo(nsObjCls).map(\.details), [prop, subProp])
    }

    func testSubclassClassProperties() {
        XCTAssertEqual(subCls.classProperties.map(\.details), [subClsProp])
        XCTAssertEqual(subCls.classProperties["exampleSubClassProp"]?.details, subClsProp)
        XCTAssertNil(subCls.classProperties["exampleSubProp"])
        XCTAssertEqual(subCls.classProperties.upTo(nsObjCls).map(\.details), [clsProp, subClsProp])
    }

    func testSubclasses() {
        XCTAssert(cls.isSubclass(of: nsObjCls, directOnly: true))
        XCTAssert(cls.isSubclass(of: nsObjCls, directOnly: false))

        XCTAssert(subCls.isSubclass(of: cls, directOnly: true))
        XCTAssert(subCls.isSubclass(of: cls, directOnly: false))

        XCTAssertFalse(subCls.isSubclass(of: nsObjCls, directOnly: true))
        XCTAssert(subCls.isSubclass(of: nsObjCls, directOnly: false))

        XCTAssertFalse(nsObjCls.isSubclass(of: cls))

        XCTAssertEqualSeq(cls.subclasses(), [subCls])
        XCTAssertEqualSeq(subCls.subclasses(), [])
        XCTAssertGreaterThan(Array(nsObjCls.subclasses(directOnly: false)).count, Array(nsObjCls.subclasses(directOnly: true)).count)
    }

    func testProtocols() {
        XCTAssertEqualSeq(cls.protocols, [ObjCProtocol(NSCopying.self)])
        XCTAssertEqualSeq(subCls.protocols, [ObjCProtocol(NSCoding.self)])
        XCTAssertEqualSeq(subCls.protocols.upTo(nsObjCls), [ObjCProtocol(NSCopying.self), ObjCProtocol(NSCoding.self)])

        XCTAssert(subCls.protocols.contains(ObjCProtocol(NSCoding.self)))
        XCTAssertFalse(subCls.protocols.contains(ObjCProtocol(NSCopying.self)))

        XCTAssertFalse(subCls.protocols.contains(ObjCProtocol(NSSecureCoding.self)))
        XCTAssert(subCls.protocols.add(ObjCProtocol(NSSecureCoding.self)))
        XCTAssert(subCls.protocols.contains(ObjCProtocol(NSSecureCoding.self)))
    }

    func testInstanceMethods() {
        XCTAssertEqual(cls.methods.map(\.selector), [
            #selector(getter: ExampleClass.exampleProp),
            #selector(setter: ExampleClass.exampleProp),
            #selector(ExampleClass.exampleFunc),
            #selector(ExampleClass.copy(with:)),
            #selector(ExampleClass.init),
        ])
        XCTAssertNotNil(cls.methods[#selector(ExampleClass.exampleFunc)])
        XCTAssertNil(cls.classMethods[#selector(ExampleClass.exampleFunc)])
    }

    func testClassMethods() {
        XCTAssertEqual(cls.classMethods.map(\.selector), [
            #selector(getter: ExampleClass.exampleClassProp),
            #selector(setter: ExampleClass.exampleClassProp),
            #selector(ExampleClass.exampleClassFunc),
        ])
        XCTAssertNil(cls.classMethods[#selector(ExampleClass.exampleFunc)])
        XCTAssertNotNil(cls.classMethods[#selector(ExampleClass.exampleClassFunc)])
    }

    func testSuperClassMethods() {
        let methods = subCls.classMethods.upTo(nsObjCls).map(\.selector)
        XCTAssertEqual(methods, [
            #selector(getter: ExampleClass.exampleClassProp),
            #selector(setter: ExampleClass.exampleClassProp),
            #selector(ExampleClass.exampleClassFunc),
            #selector(getter: ExampleSubClass.exampleSubClassProp),
            #selector(setter: ExampleSubClass.exampleSubClassProp),
            #selector(ExampleSubClass.exampleSubClassFunc),
        ])
    }

    func testSuperclasses() {
        XCTAssertEqualSeq(subCls.superclasses(), [cls, nsObjCls])
        XCTAssertEqualSeq(subCls.superclasses(includeSelf: true), [subCls, cls, nsObjCls])
        XCTAssertEqualSeq(subCls.superclasses(excluding: nsObjCls), [cls])
        XCTAssertEqualSeq(subCls.superclasses(excluding: nsObjCls, includeSelf: true), [subCls, cls])
        XCTAssertEqualSeq(subCls.superclasses(excluding: cls), [])
        XCTAssertEqualSeq(subCls.superclasses(excluding: cls, includeSelf: true), [subCls])
        XCTAssertEqualSeq(subCls.superclasses(excluding: subCls), [])
        XCTAssertEqualSeq(subCls.superclasses(excluding: subCls, includeSelf: true), [])
    }

    func testNewClass() throws {
        let clsName = "NewExampleClass"
        XCTAssertNil(ObjCClass(named: clsName))

        let newCls = try XCTUnwrap(ObjCClass.create(
            clsName,
            superclass: nsObjCls,
            ivars: [
                .init(name: "_bool", encoding: .char),
                .init(name: "_obj", encoding: .id),
            ]
        ))
        XCTAssertEqual(ObjCClass(named: clsName), newCls)

        let ivars = Array(newCls.ivars)
        XCTAssertEqual(ivars.count, 2)
        XCTAssertEqual(ivars.first?.name, "_bool")
        XCTAssertEqual(ivars.first?.encoding, .char)
        XCTAssertEqual(ivars.first?.offset, 8)
        XCTAssertEqual(ivars.last?.name, "_obj")
        XCTAssertEqual(ivars.last?.encoding, .id)
        XCTAssertEqual(ivars.last?.offset, 16)

        XCTAssertEqual(newCls.instanceSize, 24)

        let propName = "newProp"
        XCTAssertNil(newCls.properties[propName])
        let attribs = ObjCProperty.Attributes(encoding: .int)
        XCTAssert(newCls.properties.add(propName, attributes: attribs))
        XCTAssertEqual(newCls.properties[propName]?.attributes, attribs)

        newCls.dispose()
        XCTAssertNil(ObjCClass(named: clsName))
    }

    func testAddMethod() throws {
        try withTemporaryClass { cls in
            let inst = try XCTUnwrap(cls.createInstance())
            let sel = Selector(("foo"))
            XCTAssertFalse(inst.responds(to: sel))

            let exp = expectation(description: "Should be called")
            let impl: @convention(block) () -> Void = {
                exp.fulfill()
            }
            let ok = cls.methods.add(with: sel, types: .method(), block: impl)
            XCTAssert(ok)
            XCTAssert(inst.responds(to: sel))
            _ = inst.perform(sel)

            wait(for: [exp])
        }
    }

    func testAddProperty() throws {
        try withTemporaryClass { cls in
            let propName = "fooProp"

            XCTAssertNil(cls.properties[propName])

            let attribs = ObjCProperty.Attributes(nonAtomic: true, readOnly: true, dynamic: true, setterType: .copy, encoding: .int)
            XCTAssert(cls.properties.add(propName, attributes: attribs))

            let prop = try XCTUnwrap(cls.properties[propName])
            XCTAssertNotNil(prop)
            XCTAssertEqual(attribs, prop.attributes)

            XCTAssertFalse(cls.properties.add(propName, attributes: attribs, canReplace: false), "Can't add property twice")
        }
    }

    // This will crash if RuntimeFix has been broken
    func testUnreleasableClasses() {
        let cls = ObjCClass(named: "__NSGenericDeallocHandler")!
        _ = cls.metaClass
    }

}


// Creates a temporary class for tests which add methods, properties etc
func withTemporaryClass(_ block: (ObjCClass) throws -> Void, clsName: String = #function) throws {
    let cls = try XCTUnwrap(ObjCClass.create(clsName, superclass: ObjCClass(NSObject.self), ivars: []))

    // Any created instances must be released before disposing of the class
    try autoreleasepool {
        try block(cls)
    }

    cls.dispose()
}



func XCTAssertEqualSeq<T: Sequence, U: Sequence>(
    _ expression1: T, _ expression2: U,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where T.Element == U.Element, T.Element: Equatable {
    XCTAssert(expression1.elementsEqual(expression2), message(), file: file, line: line)
}

extension ObjCProperty {
    var details: Details {
        Details(name: name, attributes: attributes)
    }
}


@objcMembers
class ExampleClass: NSObject, NSCopying {

    var exampleProp: Int = 0
    func exampleFunc() {}

    static var exampleClassProp: Int = 0
    static func exampleClassFunc() {}

    // MARK: NSCopying

    func copy(with zone: NSZone? = nil) -> Any {
        preconditionFailure()
    }
}



@objcMembers
class ExampleSubClass: ExampleClass, NSCoding {

    var exampleSubProp: Int = 0
    func exampleSubFunc() {}

    static var exampleSubClassProp: Int = 0
    static func exampleSubClassFunc() {}


    // MARK: NSCoding

    func encode(with coder: NSCoder) { }

    required init?(coder: NSCoder) { nil }

}


