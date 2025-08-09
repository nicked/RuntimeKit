//
//  InvocationTests.swift
//  
//
//  Created by Nick Randall on 5/9/2024.
//

import RuntimeKit
import XCTest

final class InvocationTests: XCTestCase {

    func testMethodSignature() {
        let signature = MethodSignature(with: .method())!
        let invocation = Invocation(methodSignature: signature)
        XCTAssertEqual(invocation.methodSignature, signature)
    }

    func testTarget() {
        let signature = MethodSignature(with: .method())!
        let invocation = Invocation(methodSignature: signature)
        XCTAssertNil(invocation.target)
        XCTAssertNil(invocation.getArgument(at: 0, as: AnyObject?.self))

        invocation.target = self
        XCTAssertIdentical(invocation.target, self)
        XCTAssertIdentical(invocation.getArgument(at: 0, as: AnyObject.self), self)

        invocation.target = nil
        XCTAssertNil(invocation.target)
        XCTAssertNil(invocation.getArgument(at: 0, as: AnyObject?.self))
    }

    func testSelector() {
        let signature = MethodSignature(with: .method())!
        let invocation = Invocation(methodSignature: signature)
        XCTAssertNil(invocation.selector)
        XCTAssertNil(invocation.getArgument(at: 1, as: Selector?.self))

        let sel = #selector(testSelector)
        invocation.selector = sel
        XCTAssertEqual(invocation.selector, sel)
        XCTAssertEqual(invocation.getArgument(at: 1, as: Selector.self), sel)

        invocation.selector = nil
        XCTAssertNil(invocation.selector)
        XCTAssertNil(invocation.getArgument(at: 1, as: Selector?.self))
            // .selector = nil sets it to the empty selector
    }

    func testArguments() {
        let types = MethodTypeEncodings.method(params: .id, .char, .struct("CGSize", .double, .double))
        let signature = MethodSignature(with: types)!
        let invocation = Invocation(methodSignature: signature)

        XCTAssertNil(invocation.getArgument(at: 2, as: AnyClass?.self))
        XCTAssertFalse(invocation.getArgument(at: 3, as: Bool.self))
        XCTAssertEqual(invocation.getArgument(at: 4, as: CGSize.self), .zero)

        let size = CGSize(width: .min, height: .max)
        invocation.setArgument(at: 2, to: self)
        invocation.setArgument(at: 3, to: true)
        invocation.setArgument(at: 4, to: size)

        XCTAssertIdentical(invocation.getArgument(at: 2, as: AnyClass?.self), self)
        XCTAssertTrue(invocation.getArgument(at: 3, as: Bool.self))
        XCTAssertEqual(invocation.getArgument(at: 4, as: CGSize.self), size)

        invocation.setArgument(at: 2, to: nil as AnyObject?)
        invocation.setArgument(at: 3, to: false)
        invocation.setArgument(at: 4, to: CGSize.zero)

        XCTAssertNil(invocation.getArgument(at: 2, as: AnyClass?.self))
        XCTAssertFalse(invocation.getArgument(at: 3, as: Bool.self))
        XCTAssertEqual(invocation.getArgument(at: 4, as: CGSize.self), .zero)
    }

    func testRetainArguments() {
        let signature = MethodSignature(with: .setter(for: .id))!
        let invocation = Invocation(methodSignature: signature)

        XCTAssertFalse(invocation.argumentsRetained)

        var obj: AnyObject? = NSObject()
        invocation.setArgument(at: 2, to: obj)
        invocation.retainArguments()    // will crash if this is not called or not working
        obj = nil

        XCTAssertTrue(invocation.argumentsRetained)

        _ = invocation.getArgument(at: 2, as: AnyObject.self)
    }

    func testInvoke() {
        let cls = ObjCClass(NSString.self)
        let sel = #selector(NSString.range(of:))
        let method = cls.methods[sel]!

        let signature = MethodSignature(with: method.encoding)!
        let invocation = Invocation(methodSignature: signature)

        let str: NSString = "Hello world"

        invocation.target = str
        invocation.selector = sel
        invocation.setArgument(at: 2, to: "ll" as NSString)

        invocation.invoke()
        XCTAssertEqual(invocation.returnValue(as: NSRange.self), NSRange(location: 2, length: 2))

        invocation.invoke(withTarget: "x" as NSString)
        XCTAssertEqual(invocation.returnValue(as: NSRange.self), NSRange(location: NSNotFound, length: 0))

        let imp = imp_implementationWithBlock({ _ in
            NSRange(location: .min, length: .max)
        } as (@convention(block) (NSString) -> NSRange))

        invocation.invoke(imp: imp)
        XCTAssertEqual(invocation.returnValue(as: NSRange.self), NSRange(location: .min, length: .max))
    }

    func testReturnValue() {
        var signature = MethodSignature(with: .getter(for: .id))!
        var invocation = Invocation(methodSignature: signature)

        XCTAssertNil(invocation.returnValue(as: AnyObject?.self))
        invocation.setReturnValue(self)
        XCTAssertIdentical(invocation.returnValue(as: AnyClass?.self), self)
        invocation.setReturnValue(nil as AnyObject?)
        XCTAssertNil(invocation.returnValue(as: AnyObject?.self))

        signature = MethodSignature(with: .getter(for: .struct("CGSize", .double, .double)))!
        invocation = Invocation(methodSignature: signature)
        
        let size = CGSize(width: .min, height: .max)
        invocation.setReturnValue(size)
        XCTAssertEqual(invocation.returnValue(as: CGSize.self), size)
    }
}
