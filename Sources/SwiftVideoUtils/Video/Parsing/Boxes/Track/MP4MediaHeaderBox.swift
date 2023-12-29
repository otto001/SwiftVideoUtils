//
//  MP4MediaHeaderBox.swift
//  
//
//  Created by Matteo Ludwig on 27.11.23.
//

import Foundation



public class MP4MediaHeaderBox: MP4VersionedBox {
    public static let typeName: MP4FourCC = "mdhd"

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var creationTime: Date
    public var modificationTime: Date
    public var timescale: UInt32
    public var duration: TimeInterval
    
    public var language: Data
    public var quality: Int16
    
   public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()

        self.creationTime = try await reader.readDate(UInt32.self)
        self.modificationTime = try await reader.readDate(UInt32.self)
        self.timescale = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        
        self.duration = TimeInterval(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian))/TimeInterval(timescale)
        
        self.language = try await reader.readData(count: 2)
        self.quality = try await reader.readInteger(byteOrder: .bigEndian)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(creationTime, UInt32.self, byteOrder: .bigEndian)
        try await writer.write(modificationTime, UInt32.self, byteOrder: .bigEndian)

        try await writer.write(timescale, byteOrder: .bigEndian)
        try await writer.write(UInt32(duration * TimeInterval(timescale)), byteOrder: .bigEndian)
        
        try await writer.write(language)
        try await writer.write(quality, byteOrder: .bigEndian)
    }
}
