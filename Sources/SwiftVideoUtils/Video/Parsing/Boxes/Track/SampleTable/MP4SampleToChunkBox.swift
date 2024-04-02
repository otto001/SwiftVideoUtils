//
//  MP4SampleToChunkBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4SampleToChunkBox: MP4FullBox {
    public static let typeName: MP4FourCC = "stsc"

    
    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public struct Entry: MP4Writeable {
        public var firstChunk: MP4Index<UInt32>
        public var sampleCount: UInt32
        /// Description (see the sample description box - stsd)
        public var sampleDescriptionID: UInt32
        
        public init(firstChunk: MP4Index<UInt32>, sampleCount: UInt32, sampleDescriptionID: UInt32) {
            self.firstChunk = firstChunk
            self.sampleCount = sampleCount
            self.sampleDescriptionID = sampleDescriptionID
        }

        public init(reader: MP4SequentialReader) async throws {
            self.firstChunk = .init(index1: try await reader.readInteger(byteOrder: .bigEndian))
            self.sampleCount = try await reader.readInteger(byteOrder: .bigEndian)
            self.sampleDescriptionID = try await reader.readInteger(byteOrder: .bigEndian)
        }
        
        public func write(to writer: MP4Writer) async throws {
            try await writer.write(firstChunk.index1, byteOrder: .bigEndian)
            try await writer.write(sampleCount, byteOrder: .bigEndian)
            try await writer.write(sampleDescriptionID, byteOrder: .bigEndian)
        }
        
        public var overestimatedByteSize: Int { 12 }
    }

    public var entries: [Entry]
    
    public init(version:  MP4BoxVersion, flags: MP4BoxFlags, entries: [Entry]) {
        self.version = version
        self.flags = flags
        self.entries = entries
    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
        self.entries = []
        
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.entries.append(try await .init(reader: reader))
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(entries.count), byteOrder: .bigEndian)
        
        for entry in entries {
            try await writer.write(entry)
        }
    }
    
    public var overestimatedContentByteSize: Int {
        8 + entries.count * 12
    }
    
    public struct SamplePosition: Equatable, Hashable {
        public var chunk: MP4Index<UInt32>
        public var sampleOfChunkIndex: MP4Index<UInt32>
        public var samplesInChunk: UInt32
    }
    
    public func samplePosition(for sample: MP4Index<UInt32>) -> SamplePosition? {
        var currentSample: MP4Index<UInt32> = .zero

        for (entryIndex, entry) in entries.enumerated() {
            if entryIndex < entries.count-1 {
                let entryChunkEnd = entries[entryIndex+1].firstChunk
                let lastSampleOfChunk = currentSample + (entryChunkEnd.index0 - entry.firstChunk.index0) * entry.sampleCount
                
                if sample >= lastSampleOfChunk {
                    currentSample = lastSampleOfChunk
                    continue
                }
            }
            
            guard entry.sampleCount != 0 else {
                return nil
            }
            
            let sampleOfEntry = sample.index0 - currentSample.index0
            let chunkOfEntry = sampleOfEntry/entry.sampleCount
            let sampleOfChunkIndex = (sampleOfEntry - chunkOfEntry * entry.sampleCount)
            return .init(chunk: .init(index0: chunkOfEntry) + entry.firstChunk, 
                         sampleOfChunkIndex: .init(index0: sampleOfChunkIndex),
                         samplesInChunk: entry.sampleCount)
        }
        
        return nil
    }
}
