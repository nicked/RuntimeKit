//
//  TypeEncodingTests.swift
//  
//
//  Created by Nick Randall on 15/10/2024.
//

import XCTest
@testable import RuntimeKit

final class TypeEncodingTests: XCTestCase {

    func testRoundTripPropertyTypeEncodings() {
        ObjCClass.allClasses.forEach { cls in
            cls.properties.forEach(check)
            cls.classProperties.forEach(check)
        }

        ObjCProtocol.allProtocols.forEach { proto in
            proto.properties.forEach(check)
            proto.classProperties.forEach(check)
        }
    }

    func testRoundTripMethodTypeEncodings() {
        ObjCClass.allClasses.forEach { cls in
            cls.methods.forEach(check)
            cls.classMethods.forEach(check)
        }

        ObjCProtocol.allProtocols.forEach { proto in
            let allMethods = [proto.requiredMethods, proto.optionalMethods, proto.requiredClassMethods, proto.optionalClassMethods].joined()
            for method in allMethods {
                check(method, on: proto)
            }
        }
    }

    func testRoundTripIvarTypeEncodings() {
        ObjCClass.allClasses.forEach { cls in
            cls.ivars.forEach(check)
        }
    }


    func testEmptyObjectName() {
        XCTAssertEqual(TypeEncoding("@"), .id)
        XCTAssertEqual(TypeEncoding(#"@"""#), .object(""))
        XCTAssertEqual(TypeEncoding(#"@"""#)?.encoded, #"@"""#)

        // From std::vector ivars, where "" is the empty name of the next field
        let encoding = #"{vector<id>="__begin_"^@"__end_"^@""{?="__cap_"^@}}"#
        XCTAssertEqual(TypeEncoding(encoding)?.encoded, encoding)
        XCTAssertEqual(TypeEncoding(encoding), .struct("vector<id>", [
            .init("__begin_", type: .pointer(to: .id)),
            .init("__end_", type: .pointer(to: .id)),
            .init("", type: .struct("?", [.init("__cap_", type: .pointer(to: .id))])),
        ]))
    }


    func testObjectInNamedField() {
        // A field name follows the class name
        let className = #"{?="a"@"NSString""b"i}"#
        XCTAssertEqual(TypeEncoding(className), .struct("?", [.init("a", type: .object("NSString")), .init("b", type: .int)]))
        XCTAssertEqual(TypeEncoding(className)?.encoded, className)

        // A type follows the quoted string, so it is the next field name
        let fieldName = #"{?="a"@"b"i}"#
        XCTAssertEqual(TypeEncoding(fieldName), .struct("?", [.init("a", type: .id), .init("b", type: .int)]))
        XCTAssertEqual(TypeEncoding(fieldName)?.encoded, fieldName)

        // The end of the struct or union follows the class name
        let lastField = #"(?="a"i"b"@"NSString")"#
        XCTAssertEqual(TypeEncoding(lastField), .union("?", [.init("a", type: .int), .init("b", type: .object("NSString"))]))
        XCTAssertEqual(TypeEncoding(lastField)?.encoded, lastField)

        // Fields without names can't be ambiguous
        XCTAssertEqual(TypeEncoding(#"{?=@"NSString"i}"#), .struct("?", .object("NSString"), .int))
    }


    func testSizeAndAlignment() {
        XCTAssert(TypeEncoding.char.sizeAndAlignment == (1, 1))
        XCTAssert(TypeEncoding.struct("CGPoint", .double, .double).sizeAndAlignment == (16, 8))

        // NSGetSizeAndAlignment raises an ObjC exception for a bitfield, which RuntimeFix catches
        XCTAssert(TypeEncoding.empty.sizeAndAlignment == (0, 0))
        XCTAssert(TypeEncoding.bitfield(3).sizeAndAlignment == (0, 0))
        XCTAssert(TypeEncoding.unknown.sizeAndAlignment == (0, 0))
    }


    func testBitfieldWithoutNumber() {
        XCTAssertEqual(TypeEncoding("b3"), .bitfield(3))
        XCTAssertEqual(TypeEncoding("b"), .bitfield(nil))
        XCTAssertEqual(TypeEncoding("b")?.encoded, "b")

        let types = MethodTypeEncodings("b@:@")
        XCTAssertEqual(Array(types ?? .init()), [.bitfield(nil), .id, .selector, .id])
        XCTAssertEqual(types?.encoded, "b@:@")
    }


    func testMethodTypesCollection() {
        let types = MethodTypeEncodings.method(returning: .int, params: .double, .id)
        XCTAssertEqual(Array(types), [.int, .id, .selector, .double, .id])
        XCTAssertEqual(types.count, 5)
        XCTAssertEqual(types[2], .selector)
        XCTAssertEqual(types.returnType, .int)
        XCTAssertEqual(Array(types.parameters), [.double, .id])

        let empty = MethodTypeEncodings()
        XCTAssertEqual(empty.returnType, .empty)
        XCTAssert(empty.parameters.isEmpty)
    }


    var alreadyChecked = Set<String>()

    func check(_ property: ObjCProperty) {
        guard let attribs = property_getAttributes(property.prop)?.asString else {
            return
        }

        guard alreadyChecked.insert(attribs).inserted else {
            return
        }

        // Can't just test property.attributes.description == attribs because attributes can be re-encoded in a different order
        var otherAttribs = Substring(attribs)
        if let type = TypeEncoding(propertyAttributes: &otherAttribs) {
            if otherAttribs.isEmpty {
                XCTAssertEqual("T\(type)", attribs)
            } else {
                XCTAssertEqual("T\(type),\(otherAttribs)", attribs)
            }
        } else {
            XCTAssertEqual("T,\(otherAttribs)", attribs)
        }
    }

    func check(_ method: ObjCMethod) {
        check(method.types, method.selector, rawEncoding: method_getTypeEncoding(method.method)?.asString)
    }

    func check(_ method: ObjCProtocol.MethodDetails, on proto: ObjCProtocol) {
        let methodDesc = protocol_getMethodDescription(proto.proto, method.selector, method.isRequired, method.isInstanceMethod)
        let rawEncoding = methodDesc.types.map { String(cString: $0) }
        check(method.types, method.selector, rawEncoding: rawEncoding)
    }
    
    func check(_ methodSig: MethodTypeEncodings?, _ selector: Selector, rawEncoding: String?) {
        guard let rawEncoding, !rawEncoding.isEmpty else {
            XCTFail("No encoding for method: \(selector)")
            return
        }

        guard alreadyChecked.insert(rawEncoding).inserted else {
            return
        }

        guard let methodSig else {
            XCTFail("Couldn't parse encoding for \(selector): \(rawEncoding)")
            return
        }

        XCTAssertEqual(methodSig.encoded, rawEncoding, "Couldn't parse encoding for method \(selector)")
    }

    func check(_ ivar: ObjCIvar) {
        guard let rawEncoding = ivar_getTypeEncoding(ivar.ivar)?.asString, !rawEncoding.isEmpty else {
            return
        }

        guard alreadyChecked.insert(rawEncoding).inserted else {
            return
        }

        XCTAssertEqual(ivar.type.encoded, rawEncoding, "Couldn't parse encoding for ivar \(ivar.name)")
    }

}
