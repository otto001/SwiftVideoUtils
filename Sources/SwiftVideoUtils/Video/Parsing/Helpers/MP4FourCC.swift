//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 20.12.23.
//

import Foundation

extension UInt32 {
    var bytes: [UInt8] {
        [
            UInt8(truncatingIfNeeded: self >> 24 & 0xff),
            UInt8(truncatingIfNeeded: self >> 16 & 0xff),
            UInt8(truncatingIfNeeded: self >> 8 & 0xff),
            UInt8(truncatingIfNeeded: self & 0xff),
        ]
    }
    
    init?(bytes: [UInt8]) {
        guard bytes.count == 4 else { return nil}
        self = UInt32(bytes[0]) << 24 + UInt32(bytes[1]) << 16 + UInt32(bytes[2]) << 8 + UInt32(bytes[3])
    }
}


public struct MP4FourCC {
    public var value: UInt32
    
    public var bytes: [UInt8] { value.bytes }
    
    public var ascii: String {
        String(bytes: bytes, encoding: .ascii)!
    }
    
    public init(_ value: UInt32) {
        self.value = value
    }
    
    public init(_ string: any StringProtocol) throws {
        guard string.count == 4 else {
            throw MP4Error.failedToParseBox(description: "\(string) is not a valid FourCC")
        }
        self.value = UInt32(bytes: try string.map {
            guard $0.isASCII else {
                throw MP4Error.failedToParseBox(description: "\(string) is not a valid FourCC")
            }
            return $0.asciiValue!
        })!
    }
}

extension MP4FourCC: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = try! .init(value)
    }
}

extension MP4FourCC: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .init(UInt32(value))
    }
}

extension MP4FourCC: CustomStringConvertible {
    public var description: String { self.ascii }
}

extension MP4FourCC: CustomDebugStringConvertible {
    public var debugDescription: String { self.ascii }
}

extension MP4FourCC: MP4Readable {
    public init(readingFrom reader: MP4SequentialReader) async throws {
        self.value = try await reader.readInteger(byteOrder: .bigEndian)
    }
}

extension MP4FourCC: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(value, byteOrder: .bigEndian)
    }
}

extension MP4FourCC: Equatable {
    
}

extension MP4FourCC: Hashable {
    
}

extension MP4FourCC: Comparable {
    public static func < (lhs: MP4FourCC, rhs: MP4FourCC) -> Bool {
        lhs.value < rhs.value
    }
    
    
}
