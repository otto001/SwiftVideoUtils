//
//  MP4SoundMediaHeaderBox.swift
//  
//
//  Created by Matteo Ludwig on 23.12.23.
//

import Foundation


public class MP4SoundMediaHeaderBox: MP4FullBox {
    public static let typeName: MP4FourCC = "smhd"
    public var readByteRange: Range<Int>?
    
    public var version: MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var balance: FixedPointNumber<Int16>
    public var reserved: UInt16
    
   public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()

        self.balance = try await reader.readSignedFixedPoint(fractionBits: 8, byteOrder: .bigEndian)
        self.reserved = try await reader.readInteger(byteOrder: .bigEndian)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(self.balance, byteOrder: .bigEndian)
        try await writer.write(self.reserved, byteOrder: .bigEndian)
    }
    
    public var overestimatedContentByteSize: Int {
        8
    }
}
