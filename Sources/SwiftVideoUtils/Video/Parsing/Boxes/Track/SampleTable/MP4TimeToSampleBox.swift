//
//  MP4TimeToSampleBox.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


public class MP4TimeToSampleBox: MP4VersionedBox {
    public static let typeName: MP4FourCC = "stts"

    
    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public struct TimeToSampleEntry {
        public var sampleCount: UInt32
        public var sampleDuration: UInt32
        
        public init(sampleCount: UInt32, sampleDuration: UInt32) {
            self.sampleCount = sampleCount
            self.sampleDuration = sampleDuration
        }
    }
    
    public var entries: [TimeToSampleEntry]
    
    public init(version:  MP4BoxVersion, flags: MP4BoxFlags, entries: [TimeToSampleEntry]) {
        self.version = version
        self.flags = flags
        self.entries = entries
    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.entries = []
        for _ in 0..<entryCount {
            self.entries.append(TimeToSampleEntry(sampleCount: try await reader.readInteger(byteOrder: .bigEndian),
                                                  sampleDuration: try await reader.readInteger(byteOrder: .bigEndian)))
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(entries.count), byteOrder: .bigEndian)
        
        for entry in entries {
            try await writer.write(entry.sampleCount, byteOrder: .bigEndian)
            try await writer.write(entry.sampleDuration, byteOrder: .bigEndian)
        }
    }
    
    public func totalSampleCount() -> Int {
        entries.map { Int($0.sampleCount) }.reduce(0, +)
    }
    
    public func totalSampleDuration() -> Int {
        entries.map { Int($0.sampleDuration) * Int($0.sampleCount) }.reduce(0, +)
    }
    
    public func averageSampleDuration() -> Double {
        return Double(totalSampleDuration())/Double(totalSampleCount())
    }
    
    public func time(for sample: MP4Index<UInt32>) -> Range<UInt32>? {
        self.times(for: sample..<sample+1).first
    }
    
    public func times(for samples: Range<MP4Index<UInt32>>) -> [Range<UInt32>] {
        var currentSample: MP4Index<UInt32> = .zero
        var currentTime: UInt32 = 0
        
        var result: [Range<UInt32>] = []
        
        for entry in entries {
            let entrySampleEnd = currentSample + entry.sampleCount
            guard samples.lowerBound < entrySampleEnd else {
                currentSample += entry.sampleCount
                currentTime += entry.sampleDuration * entry.sampleCount
                continue
            }
            
            if currentSample < samples.lowerBound {
                currentTime += (samples.lowerBound.index0 - currentSample.index0) * entry.sampleDuration
                currentSample = samples.lowerBound
            }
            
            let rangeEnd = min(entrySampleEnd, samples.upperBound)
            for _ in currentSample..<rangeEnd {
                result.append(currentTime..<currentTime+entry.sampleDuration)
                currentTime += entry.sampleDuration
            }
            
            currentSample = rangeEnd
            
            guard samples.upperBound != currentSample else {
                break
            }
        }
        
        return result
    }
    
    public func sample(at time: UInt32) -> MP4Index<UInt32>? {
        guard !entries.isEmpty else { return nil }
        
        var currentSample: MP4Index<UInt32> = .zero
        var currentTime: UInt32 = 0
        
        for entry in entries {
            let entryDuration = entry.sampleCount * entry.sampleDuration
            if entryDuration + currentTime >= time {
                return currentSample + (time - currentTime)/entry.sampleDuration
            } else {
                currentSample += entry.sampleCount
                currentTime += entryDuration
            }
        }
        
        return nil
    }
}
