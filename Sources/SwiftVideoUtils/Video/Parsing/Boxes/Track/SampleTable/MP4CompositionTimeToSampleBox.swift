//
//  MP4CompositionTimeToSampleBox.swift
//
//
//  Created by Matteo Ludwig on 19.12.23.
//

import Foundation


public class MP4CompositionTimeToSampleBox: MP4FullBox {
    public static let typeName: MP4FourCC = "ctts"
    
    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public struct Entry {
        public var sampleCount: UInt32
        public var offset: Int32
        
        public init(sampleCount: UInt32, offset: Int32) {
            self.sampleCount = sampleCount
            self.offset = offset
        }
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
        
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)

        self.entries = []
        self.entries.reserveCapacity(Int(entryCount))
        
        for _ in 0..<entryCount {
            var entry = Entry(sampleCount: try await reader.readInteger(byteOrder: .bigEndian), offset: 0)
            
            if self.version == .isoMp4(0){
                let offset: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
                entry.offset = Int32(offset)
            } else {
                entry.offset = try await reader.readInteger(byteOrder: .bigEndian)
            }
            
            self.entries.append(entry)
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(entries.count), byteOrder: .bigEndian)
        
        for entry in entries {
            try await writer.write(entry.sampleCount, byteOrder: .bigEndian)
            
            if self.version == .isoMp4(0) {
                try await writer.write(UInt32(entry.offset), byteOrder: .bigEndian)
            } else {
                try await writer.write(entry.offset, byteOrder: .bigEndian)
            }
        }
    }
    
    public func offsets(for samples: Range<MP4Index<UInt32>>) -> [Int32] {
        var currentSample: MP4Index<UInt32> = .zero
        var result: [Int32] = []
        result.reserveCapacity(samples.count)
        
        for entry in entries {
            let entryEnd = currentSample + entry.sampleCount
            
            if currentSample > samples.lowerBound {
                for _ in currentSample..<min(entryEnd, samples.upperBound) {
                    result.append(entry.offset)
                }
            } else if entryEnd > samples.lowerBound {
                for _ in max(currentSample, samples.lowerBound)..<min(entryEnd, samples.upperBound) {
                    result.append(entry.offset)
                }
            }
            
            currentSample = entryEnd
            
            if currentSample >= samples.upperBound {
                break
            }
        }
        
        return result
    }
}
