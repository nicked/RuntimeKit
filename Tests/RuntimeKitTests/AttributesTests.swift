//
//  AttributesTests.swift
//
//
//  Created by Nick Randall on 4/9/2024.
//

@testable import RuntimeKit
import XCTest


final class AttributesTests: XCTestCase {
    
    func testSimpleAttribs() {

        let propStrs = [
            "Tc,VcharDefaultc",
            "Td,VdoubleDefault",
            "Ti,VenumDefault",
            "Tf,VfloatDefault",
            "Ti,VintDefault",
            "Tl,VlongDefault",
            "Ts,VshortDefault",
            "Ti,VsignedDefault",
            "T{YorkshireTeaStruct=\"pot\"i\"lady\"c},VstructDefault",
            "T{YorkshireTeaStruct=\"pot\"i\"lady\"c},VtypedefDefault",
            "T(MoneyUnion=\"alone\"f\"down\"d),VunionDefault",
            "TI,VunsignedDefault",
            "T^?,VfunctionPointerDefault",
            "T@,VidDefault",
            "T^i,VintPointer",
            "T^v,VvoidPointerDefault",
            "Ti,V_intSynthEquals",
            "Ti,GintGetFoo,SintSetFoo:,VintSetterGetter",
            "Ti,R,VintReadonly",
            "Ti,R,GisIntReadOnlyGetter",
            "Ti,VintReadwrite",
            "Ti,VintAssign",
            "T@,&,VidRetain",
            "T@,C,VidCopy",
            "Ti,VintNonatomic",
            "T@,R,C,VidReadonlyCopyNonatomic",
            "T@,R,&,VidReadonlyRetainNonatomic",
        ]

        for str in propStrs {
            XCTAssertEqual(str, ObjCProperty.Attributes(str).description)
        }

    }

    func testComplexAttribs() {
        let propStr = "T{vector<long long, std::allocator<long long>>=^q^q{__compressed_pair<long long *, std::allocator<long long>>=^q}},N,V_classesByInt"

        XCTAssertEqual(propStr, ObjCProperty.Attributes(propStr).description)
    }

    func testAttribsSplitFull() {
        let attrs = ObjCProperty.Attributes(
            nonAtomic: true,
            readOnly: true,
            dynamic: true,
            setterType: .copy,
            encoding: TypeEncoding(#"{YorkshireTeaStruct="pot"i"lady"c}"#)!,
            customGetter: "yorkshireTea",
            customSetter: "setYorkshireTea",
            ivarName: "_yorkshireTea"
        )

        XCTAssertEqual(attrs.asDict(), [
            "T": #"{YorkshireTeaStruct="pot"i"lady"c}"#,
            "R": "",
            "N": "",
            "D": "",
            "C": "",
            "G": "yorkshireTea",
            "S": "setYorkshireTea",
            "V": "_yorkshireTea",
        ])
    }

    func testAttribsSplitMinimal() {
        let attrs = ObjCProperty.Attributes(encoding: .int)

        XCTAssertEqual(attrs.asDict(), ["T": "i"])
    }

}


extension ObjCProperty.Attributes {
    func asDict() -> [String: String] {
        Dictionary(uniqueKeysWithValues: attributeList().map { ($0.code, $0.value) } )
    }
}

