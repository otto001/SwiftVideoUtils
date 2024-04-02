//
//  MP4SyncSampleBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4SyncSampleBox: MP4FullBox {
    public static let typeName: MP4FourCC = "stss"

    
    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var syncSamples: [MP4Index<UInt32>]
    
    public init(version:  MP4BoxVersion, flags: MP4BoxFlags, syncSamples: [MP4Index<UInt32>]) {
        self.version = version
        self.flags = flags
        self.syncSamples = syncSamples
    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
        self.syncSamples = []
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.syncSamples.append(.init(index1: try await reader.readInteger(byteOrder: .bigEndian)))
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(syncSamples.count), byteOrder: .bigEndian)
        
        for syncSample in syncSamples {
            try await writer.write(syncSample.index1, byteOrder: .bigEndian)
        }
    }
    
    public var overestimatedContentByteSize: Int {
        8 + syncSamples.count * 4
    }
    
    public func syncSample(before sample: MP4Index<UInt32>) -> MP4Index<UInt32>? {
        syncSamples.last { syncSample in
            syncSample <= sample
        }
    }
}
