//
//  ObjCProperty.swift
//  
//
//  Created by Nick Randall on 27/12/2022.
//

import Foundation

/// Wraps a runtime property.
public struct ObjCProperty {
    @usableFromInline let prop: objc_property_t

    /// Creates a wrapper of the specified property.
    @inlinable public init(_ prop: objc_property_t) {
        self.prop = prop
    }

    /// Returns the name of the property.
    @inlinable public var name: String {
        property_getName(prop).asString
    }

    /// The attributes of the property.
    ///
    /// To access multiple attributes, it is best to assign this to a variable since it parses an attribute string on creation.
    @inlinable public var attributes: Attributes {
        Attributes(of: prop)
    }
}

extension ObjCProperty {
    /// Represents a property for adding to a class.
    public struct Details: Equatable {
        let name: String
        let attributes: Attributes

        public init(name: String, attributes: Attributes) {
            self.name = name
            self.attributes = attributes
        }
    }
}


extension ObjCProperty: CustomStringConvertible {
    public var description: String {
        return "\(name) = \(attributes)"
    }
}

extension ObjCProperty: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(Self.self)(\(name))"
    }
}
