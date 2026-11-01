//
//  MethodSignatureTests.swift
//  
//
//  Created by Nick Randall on 29/11/2024.
//

import XCTest
import RuntimeKit

final class MethodSignatureTests: XCTestCase {

    func testProperties() throws {
        let ms = try XCTUnwrap(MethodSignature(with: .method(returning: .id, params: .pointer(to: .struct("_NSZone")))))
        XCTAssertEqual(ms.numberOfArguments, 3)
        XCTAssertEqual(ms.argumentType(at: 0).encoded, "@")
        XCTAssertEqual(ms.argumentType(at: 1).encoded, ":")
        XCTAssertEqual(ms.argumentType(at: 2).encoded, "^{_NSZone=}")
        XCTAssertEqual(ms.methodReturnType.encoded, "@")
        XCTAssertEqual(ms.methodReturnLength, 8)
        XCTAssertEqual(ms.frameLength, 224)
        XCTAssertEqual(ms.isOneway, false)
    }

    func testInvalidSignature() {
        XCTAssertNil(MethodSignature(with: MethodTypeEncodings()))
    }

    // NSMethodSignature does not support unions
    func testMethodSignatureWithUnion() throws {
        try withTemporaryClass { cls in
            let sel = Selector(("unionMethod"))
            let types = MethodTypeEncodings.method(returning: .union("?", [.init(type: .int)]))
            let impl: @convention(block) (AnyObject) -> Void = { _ in }
            XCTAssert(cls.methods.add(sel, types: types, block: impl))

            let method = try XCTUnwrap(cls.methods[sel])
            XCTAssertEqual(method.types.encoded, "(?=i)@:")
            XCTAssertNil(method.signature)
            XCTAssertNil(Invocation(method: method))
        }
    }

}
