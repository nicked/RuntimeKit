//
//  ProtocolTests.swift
//  
//
//  Created by Nick Randall on 28/12/2022.
//

import XCTest
import RuntimeKit

final class ProtocolTests: XCTestCase {

    let proto = ObjCProtocol(TestProtocol.self)

    func testName() {
        XCTAssertEqual(proto.name, "RuntimeKitTests.TestProtocol")
    }


    func testProperties() {
        let rp = ObjCProperty.Details(
            name: "requiredProp",
            attributes: .init(nonAtomic: true, readOnly: true, encoding: .double)
        )

        let op = ObjCProperty.Details(
            name: "optionalProp",
            attributes: .init(nonAtomic: true, readOnly: true, encoding: .double)
        )

        XCTAssertEqual(proto.properties["requiredProp"]?.details, rp)
        XCTAssertEqual(proto.properties["optionalProp"]?.details, op)

        XCTAssertNil(proto.properties["requiredClassProp"])
        XCTAssertNil(proto.properties["optionalClassProp"])

        XCTAssertEqual(proto.properties.map(\.details), [rp, op])
    }

    func testClassProperties() {
        let rp = ObjCProperty.Details(
            name: "requiredClassProp",
            attributes: .init(nonAtomic: true, readOnly: true, encoding: .double)
        )

        let op = ObjCProperty.Details(
            name: "optionalClassProp",
            attributes: .init(nonAtomic: true, readOnly: true, encoding: .double)
        )

        XCTAssertEqual(proto.classProperties["requiredClassProp"]?.details, rp)
        XCTAssertEqual(proto.classProperties["optionalClassProp"]?.details, op)

        XCTAssertNil(proto.classProperties["requiredProp"])
        XCTAssertNil(proto.classProperties["optionalProp"])

        XCTAssertEqual(proto.classProperties.map(\.details), [rp, op])
    }

    func testProtocols() {
        XCTAssertEqualSeq(proto.protocols, [ObjCProtocol(NSCopying.self)])

        XCTAssert(proto.protocols.contains(ObjCProtocol(NSCopying.self)))
        XCTAssertFalse(proto.protocols.contains(ObjCProtocol(NSMutableCopying.self)))
    }

    let requiredMethod = #selector(TestProtocol.requiredMethod)
    let optionalMethod = #selector(TestProtocol.optionalMethod)
    let requiredProp = #selector(getter: TestProtocol.requiredProp)
    let optionalProp = #selector(getter: TestProtocol.optionalProp)
    let requiredClassMethod = Selector(("requiredClassMethod"))
    let optionalClassMethod = Selector(("optionalClassMethod"))
    let requiredClassProp = Selector(("requiredClassProp"))
    let optionalClassProp = Selector(("optionalClassProp"))

    func testMethods() throws {
        XCTAssertNil(proto.optionalMethods[requiredMethod])
        let rm = try XCTUnwrap(proto.requiredMethods[requiredMethod])
        XCTAssertEqual(rm.selector, requiredMethod)
        XCTAssertEqual(rm.encoding, .method())
        XCTAssert(rm.isRequired)
        XCTAssert(rm.isInstanceMethod)

        XCTAssertNil(proto.requiredMethods[optionalMethod])
        let om = try XCTUnwrap(proto.optionalMethods[optionalMethod])
        XCTAssertEqual(om.selector, optionalMethod)
        XCTAssertEqual(om.encoding, .method())
        XCTAssertFalse(om.isRequired)
        XCTAssert(om.isInstanceMethod)

        XCTAssertNil(proto.requiredMethods[requiredClassMethod])
        XCTAssertNil(proto.optionalMethods[optionalClassMethod])

        XCTAssertEqual(Set(proto.requiredMethods.map(\.selector)), Set([requiredProp, requiredMethod]))
        XCTAssertEqual(Set(proto.optionalMethods.map(\.selector)), Set([optionalProp, optionalMethod]))
    }

    func testClassMethods() throws {
        let rm = try XCTUnwrap(proto.requiredClassMethods[requiredClassMethod])
        XCTAssertEqual(rm.selector, requiredClassMethod)
        XCTAssertEqual(rm.encoding, .method())
        XCTAssertTrue(rm.isRequired)
        XCTAssertFalse(rm.isInstanceMethod)

        let om = try XCTUnwrap(proto.optionalClassMethods[optionalClassMethod])
        XCTAssertEqual(om.selector, optionalClassMethod)
        XCTAssertEqual(om.encoding, .method())
        XCTAssertFalse(om.isRequired)
        XCTAssertFalse(om.isInstanceMethod)

        XCTAssertNil(proto.requiredClassMethods[requiredMethod])
        XCTAssertNil(proto.optionalClassMethods[requiredMethod])
        XCTAssertNil(proto.requiredClassMethods[optionalMethod])
        XCTAssertNil(proto.optionalClassMethods[optionalMethod])

        XCTAssertEqual(Set(proto.requiredClassMethods.map(\.selector)), Set([requiredClassMethod, requiredClassProp]))
        XCTAssertEqual(Set(proto.optionalClassMethods.map(\.selector)), Set([optionalClassProp, optionalClassMethod]))
    }

    func testAllProtocols() {
        XCTAssert(ObjCProtocol.allProtocols.contains(proto))
    }

    func testEquality() {
        XCTAssertEqual(proto, ObjCProtocol(TestProtocol.self))
        XCTAssertNotEqual(proto, ObjCProtocol(NSCopying.self))
    }

    func testCreation() throws {
        let name = "testCreation_Protocol"

        let prop1 = ObjCProperty.Details(
            name: "prop1",
            attributes: .init(readOnly: true, encoding: .double)
        )
        let prop2 = ObjCProperty.Details(
            name: "prop2",
            attributes: .init(nonAtomic: true, dynamic: true, encoding: .double)
        )

        let method1 = ObjCProtocol.MethodDetails(selector: Selector(("method1")), encoding: .method(), isRequired: true, isInstanceMethod: true)
        let method2 = ObjCProtocol.MethodDetails(selector: Selector(("method2")), encoding: .method(), isRequired: false, isInstanceMethod: false)

        let proto = try XCTUnwrap(
            ObjCProtocol.create(name, properties: [prop1], classProperties: [prop2], methods: [method1, method2], protocols: [ObjCProtocol(NSCopying.self)])
        )

        XCTAssertEqual(proto.properties.map(\.details), [prop1])
        XCTAssertEqual(proto.classProperties.map(\.details), [prop2])
        XCTAssertEqualSeq(proto.requiredMethods, [method1])
        XCTAssertEqualSeq(proto.optionalClassMethods, [method2])
        XCTAssertEqualSeq(proto.requiredClassMethods, [])
        XCTAssertEqualSeq(proto.optionalMethods, [])

        XCTAssert(ObjCProtocol.allProtocols.contains(proto))

        XCTAssertEqualSeq(proto.protocols, [ObjCProtocol(NSCopying.self)])
        XCTAssert(proto.protocols.contains(ObjCProtocol(NSCopying.self)))
    }
}


@objc protocol TestProtocol: NSCopying {
    var requiredProp: Double { get }
    static var requiredClassProp: Double { get }

    @objc optional var optionalProp: Double { get }
    @objc optional static var optionalClassProp: Double { get }

    func requiredMethod()
    static func requiredClassMethod()

    @objc optional func optionalMethod()
    @objc optional static func optionalClassMethod()
}
