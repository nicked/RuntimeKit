//
//  ObjCClass+Ivars.swift
//  
//
//  Created by Nick Randall on 7/10/2024.
//

import Foundation


public extension ObjCClass {

    /// Returns all instance variables of this class, not including those on superclasses.
    @inlinable var ivars: RuntimeList<Ivars> {
        RuntimeList(Ivars(on: self))
    }

}
