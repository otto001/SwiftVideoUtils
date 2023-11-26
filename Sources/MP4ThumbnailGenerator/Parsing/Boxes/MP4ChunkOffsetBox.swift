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
    public static let fullyParsable: Bool = true
    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var chunkOffset: [UInt32]
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await .init(readFrom: reader)
        
        self.chunkOffset = []
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.chunkOffset.append(try await reader.readInteger(byteOrder: .bigEndian))
        }
    }
    
    public func chunkOffset(of chunk: MP4Index<UInt32>) -> Int {
        return Int(chunkOffset[chunk])
    }
}


public class MP4ChunkOffset64Box: MP4ChunkOffsetBox {
    public static let typeName: String = "co64"
    public static let fullyParsable: Bool = true
    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var chunkOffset: [UInt64]
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await .init(readFrom: reader)
        
        self.chunkOffset = []
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.chunkOffset.append(try await reader.readInteger(byteOrder: .bigEndian))
        }
    }
    
    public func chunkOffset(of chunk: MP4Index<UInt32>) -> Int {
        return Int(chunkOffset[chunk])
    }
}
