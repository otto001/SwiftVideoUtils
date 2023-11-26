//
//  MP4TimeToSampleBox.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


public class MP4TimeToSampleBox: MP4VersionedBox {
    public static let typeName: String = "stts"
    public static let fullyParsable: Bool = true
    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public struct TimeToSampleEntry {
        var sampleCount: UInt32
        var sampleDuration: UInt32
    }
    
    public var entries: [TimeToSampleEntry]
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await .init(readFrom: reader)
        
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.entries = []
        for _ in 0..<entryCount {
            self.entries.append(TimeToSampleEntry(sampleCount: try await reader.readInteger(byteOrder: .bigEndian),
                                                  sampleDuration: try await reader.readInteger(byteOrder: .bigEndian)))
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
    
//    public func sample(time: UInt32) -> MP4Index<UInt32>? {
//        guard !entries.isEmpty else { return nil }
//        
//        var entryIndex = 0
//        var inEntryIndex = 0
//        var timestepSampleEnd: UInt32 = 0 + entries.first!.sampleDuration
//        var sample: MP4Index<UInt32> = .init(index0: 0)
//        
//        
//        while timestepSampleEnd < time {
//            sample += 1
//            inEntryIndex += 1
//            
//            while inEntryIndex >= entries[entryIndex].sampleCount {
//                entryIndex += 1
//                inEntryIndex = 0
//                guard entryIndex < entries.endIndex else {
//                    return sample
//                }
//            }
//            
//            timestepSampleEnd += entries[entryIndex].sampleDuration
//        }
//        
//        return sample
//    }
}
