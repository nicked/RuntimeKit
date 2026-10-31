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
        var otherAttribs = attribs
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
