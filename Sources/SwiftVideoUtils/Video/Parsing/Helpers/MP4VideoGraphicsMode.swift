//
//  MP4VideoGraphicsMode.swift
//
//
//  Created by Matteo Ludwig on 23.12.23.
//

import Foundation

public struct MP4VideoGraphicsMode: RawRepresentable {
    public var rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    static let copy: MP4VideoGraphicsMode = .init(rawValue: 0)
    static let dither: MP4VideoGraphicsMode = .init(rawValue: 0x40)
    static let blend: MP4VideoGraphicsMode = .init(rawValue: 0x20)
    static let transparent: MP4VideoGraphicsMode = .init(rawValue: 0x24)
    static let straightAlpha: MP4VideoGraphicsMode = .init(rawValue: 0x100)
    static let premulWhiteAlpha: MP4VideoGraphicsMode = .init(rawValue: 0x101)
    static let premulBlackAlpha: MP4VideoGraphicsMode = .init(rawValue: 0x102)
    static let straightAlphaBlend: MP4VideoGraphicsMode = .init(rawValue: 0x104)
    static let ditherCopy: MP4VideoGraphicsMode = .init(rawValue: 0x103)
}

extension MP4VideoGraphicsMode: MP4Readable {
    public init(readingFrom reader: MP4SequentialReader) async throws {
        self.rawValue = try await reader.readInteger(byteOrder: .bigEndian)
    }
}

extension MP4VideoGraphicsMode: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(rawValue, byteOrder: .bigEndian)
    }
}
