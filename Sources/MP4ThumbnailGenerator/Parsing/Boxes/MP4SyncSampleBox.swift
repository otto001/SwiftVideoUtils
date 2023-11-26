//
//  MP4SyncSampleBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4SyncSampleBox: MP4VersionedBox {
    public static let typeName: String = "stss"
    public static let fullyParsable: Bool = true
    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var syncSamples: [MP4Index<UInt32>]
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await .init(readFrom: reader)
        
        self.syncSamples = []
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.syncSamples.append(.init(index1: try await reader.readInteger(byteOrder: .bigEndian)))
        }
    }
}
