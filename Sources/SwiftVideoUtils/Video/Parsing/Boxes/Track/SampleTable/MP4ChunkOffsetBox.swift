//
//  MP4ChunkOffsetBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation

public protocol MP4ChunkOffsetBox: MP4VersionedBox {
    func chunkOffset(of chunk: MP4Index<UInt32>) -> Int
}

public class MP4ChunkOffset32Box: MP4ChunkOffsetBox {
    public static let typeName: String = "stco"

    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var chunkOffsets: [UInt32]
    
    public init(version: UInt8, flags: MP4BoxFlags, chunkOffsets: [UInt32]) {
        self.version = version
        self.flags = flags
        self.chunkOffsets = chunkOffsets
    }
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await reader.readBoxFlags()
        
        self.chunkOffsets = []
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.chunkOffsets.append(try await reader.readInteger(byteOrder: .bigEndian))
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(chunkOffsets.count), byteOrder: .bigEndian)
        
        for chunkOffset in chunkOffsets {
            try await writer.write(chunkOffset, byteOrder: .bigEndian)
        }
    }
    
    public func chunkOffset(of chunk: MP4Index<UInt32>) -> Int {
        return Int(chunkOffsets[chunk])
    }
}


public class MP4ChunkOffset64Box: MP4ChunkOffsetBox {
    public static let typeName: String = "co64"

    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var chunkOffsets: [UInt64]
    
    public init(version: UInt8, flags: MP4BoxFlags, chunkOffsets: [UInt64]) {
        self.version = version
        self.flags = flags
        self.chunkOffsets = chunkOffsets
    }
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await reader.readBoxFlags()
        
        self.chunkOffsets = []
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.chunkOffsets.append(try await reader.readInteger(byteOrder: .bigEndian))
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(chunkOffsets.count), byteOrder: .bigEndian)
        
        for chunkOffset in chunkOffsets {
            try await writer.write(chunkOffset, byteOrder: .bigEndian)
        }
    }
    
    public func chunkOffset(of chunk: MP4Index<UInt32>) -> Int {
        return Int(chunkOffsets[chunk])
    }
}
