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
        let ms = try XCTUnwrap(MethodSignature(with: "@24@0:8^{_NSZone=}16"))
        XCTAssertEqual(ms.numberOfArguments, 3)
        XCTAssertEqual(ms.argumentType(at: 0), "@")
        XCTAssertEqual(ms.argumentType(at: 1), ":")
        XCTAssertEqual(ms.argumentType(at: 2), "^{_NSZone=}")
        XCTAssertEqual(ms.methodReturnType, "@")
        XCTAssertEqual(ms.methodReturnLength, 8)
        XCTAssertEqual(ms.frameLength, 224)
        XCTAssertEqual(ms.isOneway, false)
    }

    func testInvalidSignature() {
        XCTAssertNil(MethodSignature(with: ""))
    }

}
