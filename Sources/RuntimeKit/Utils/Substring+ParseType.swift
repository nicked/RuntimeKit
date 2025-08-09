//
//  Substring+ParseType.swift
//
//
//  Created by Nick Randall on 7/7/2025.
//

import Foundation


extension Substring {
    private enum ParseError: Error {
        case expectedDigit
        case unexpectedEnd
        case unknownCharacter
    }

    /// Attempts to parse a type encoding, returns `nil` if no type is found.
    /// Throws if an invalid character or type is found.
    mutating func parseOptionalTypeEncoding() throws -> TypeEncoding? {
        // Could be an empty type encoding
        guard let first else {
            return nil
        }
        switch first {
            // Peek at the next character, if it is a known valid character in an encoding
            // but not the start of a type, leave the character un-popped.
            case "]", "}", ")", "\"", ",", ">", "0"..."9":
                return nil
            default:
                return try parseTypeEncoding()
        }
    }

    /// Attempts to parse a type encoding, throws if an invalid character or type is found.
    mutating func parseTypeEncoding() throws -> TypeEncoding {
        guard let firstChar = popFirst() else {
            throw ParseError.unexpectedEnd
        }

        switch firstChar {
            case "c": return .char
            case "i": return .int
            case "s": return .short
            case "l": return .long      // Note: long encodes to 'q' on 64 bit
            case "q": return .longLong
            case "C": return .unsignedChar
            case "I": return .unsignedInt
            case "S": return .unsignedShort
            case "L": return .unsignedLong
            case "Q": return .unsignedLongLong
            case "f": return .float
            case "d": return .double
            case "B": return .bool      // Note: BOOL encodes to 'c' on 64 bit
            case "t": return .int128
            case "D": return .longDouble

            case " ": return .blank
            case "v": return .void
            case "*": return .cString
            case "#": return .class
            case ":": return .selector
            case "?": return .unknown

            case "@": return try parseObject()
            case "[": return try parseArray()
            case "{": return try parseCompoundType(isStruct: true)
            case "(": return try parseCompoundType(isStruct: false)
            case "b": return try .bitfield(parseInt())
            case "^": return try .pointer(to: parseOptionalTypeEncoding())

            case "r": return try .const(parseTypeEncoding())
            case "A": return try .atomic(parseTypeEncoding())
            case "n": return try .in(parseTypeEncoding())
            case "o": return try .out(parseTypeEncoding())
            case "N": return try .inOut(parseTypeEncoding())
            case "V": return try .oneWay(parseTypeEncoding())
            case "O": return try .byCopy(parseTypeEncoding())
            case "R": return try .byRef(parseTypeEncoding())

            default:
                throw ParseError.unknownCharacter
        }
    }

    /// Parses a specific character from the encoding.
    mutating func parseChar(_ char: Character) -> Bool {
        guard !isEmpty, first == char else {
            return false
        }
        removeFirst()
        return true
    }

    /// Parses a single digit (0-9) from the encoding.
    mutating func parseDigit() -> Int? {
        guard let first, first.isASCII, let n = first.wholeNumberValue else {
            // Check isASCII because wholeNumberValue also matches Unicode digits
            return nil
        }
        removeFirst()
        return n
    }

    /// Parses an integer from the encoding, throws an error if no leading digit was matched.
    mutating func parseInt() throws -> Int {
        guard var n = parseDigit() else {
            throw ParseError.expectedDigit
        }
        while let digit = parseDigit() {
            n = n * 10 + digit
        }
        return n
    }

    /// Parses a quoted string from the encoding.
    mutating func parseStr() -> String? {
        guard parseChar("\"") else {
            return nil
        }
        if let idx = firstIndex(of: "\"") {
            return String(removePrefix(upTo: idx))
        }
        return nil
    }

    /// Parses an unquoted string up until any of the specified characters.
    mutating func parseStr(until chars: Character...) -> (String, Character)? {
        if let idx = firstIndex(where: { chars.contains($0) }) {
            let matchedChar = self[idx]
            return (String(removePrefix(upTo: idx)), matchedChar)
        }
        return nil
    }

    /// Splits a string at the given index, removes and returns the first part.
    mutating func removePrefix(upTo idx: Index) -> Substring {
        let prefix = prefix(upTo: idx)
        self = suffix(from: index(after: idx))
        return prefix
    }

    /// Attempts to parse the size and type of a C-array, after the opening bracket has been parsed.
    mutating func parseArray() throws -> TypeEncoding {
        let count = try parseInt()
        let type = try parseOptionalTypeEncoding()     // can be no type, e.g. [3]
        guard parseChar("]") else {
            throw ParseError.unexpectedEnd
        }
        return .array(count: count, type)
    }

    /// Attempts to parse the name and types of a struct or union, after the opening bracket has been parsed.
    /// Structs/unions can just have a name and no fields, or field names with no types: `{?=\"max\"\"min\"}`
    mutating func parseCompoundType(isStruct: Bool) throws -> TypeEncoding {
        let endChar: Character = isStruct ? "}" : ")"
        guard let (name, match) = parseStr(until: "=", endChar) else {
            throw ParseError.unexpectedEnd
        }
        var fields: [TypeEncoding.Field]? = nil
        if match == "=" {
            fields = []
            while let field = try TypeEncoding.Field(&self) {
                fields!.append(field)
            }
            guard parseChar(endChar) else { throw ParseError.unexpectedEnd }
        }
        return isStruct ? .struct(name: name, fields) : .union(name: name, fields)
    }

    /// Attempts to parse the class name and protocols of an object type, after the `@` has been parsed.
    /// Could also parse a block type.
    /// An object encoding can have an optional quoted class name and optional angle bracket-delimited protocol names.
    /// Example: `@"NSObject<NSCopying><NSCoding>"`
    mutating func parseObject() throws -> TypeEncoding {
        if parseChar("?") {     // '@?' = block
            return try parseBlock()
        }

        guard let names = parseStr() else {
            return .id
        }
        var clsName: String?
        var protocols: [String] = []
        let parts = names.split(separator: "<")
        for part in parts {
            if part.last == ">" {
                protocols.append(String(part.dropLast()))
            } else {
                guard clsName == nil, protocols.isEmpty else {
                    // Found a string which does not end in ">" but class name or a protocol was already found
                    throw ParseError.unexpectedEnd
                }
                clsName = String(part)
            }
        }
        return .object(name: clsName, protocols: protocols)
    }

    /// Attempts to parse the parameter details of a block type, after the block type encoding `@?` has been parsed.
    /// Blocks can have signatures such as `@?<v@?@"NSURLRequest">` (return type + "block self" + arguments).
    mutating func parseBlock() throws -> TypeEncoding {
        guard parseChar("<") else {
            return .block(nil)
        }
        var blockParams = [TypeEncoding]()
        while let type = try parseOptionalTypeEncoding() {
            blockParams.append(type)
        }
        guard parseChar(">") else {
            throw ParseError.unexpectedEnd
        }
        return .block(blockParams)
    }
}
