//
//  MP4SampleTableBox.swift
//
//
//  Created by Matteo Ludwig on 24.11.23.
//

import Foundation


public class MP4SampleTableBox: MP4ParsableBox {
    public static let typeName: String = "stbl"

    
    public var children: [any MP4Box]
    
    public var sampleDescriptionBox: MP4SampleDescriptionBox? {
        self.firstChild(ofType: MP4SampleDescriptionBox.self)
    }
    public var sampleToChunkBox: MP4SampleToChunkBox? {
        self.firstChild(ofType: MP4SampleToChunkBox.self)
    }
    public var sampleSizeBox: MP4SampleSizeBox? {
        self.firstChild(ofType: MP4SampleSizeBox.self)
    }
    public var chunkOffsetBox: (any MP4ChunkOffsetBox)? {
        self.firstChild(ofType: MP4ChunkOffset32Box.self) ?? self.firstChild(ofType: MP4ChunkOffset64Box.self)
    }
    public var syncSamplesBox: MP4SyncSampleBox? {
        self.firstChild(ofType: MP4SyncSampleBox.self)
    }
    public var timeToSampleBox: MP4TimeToSampleBox? {
        self.firstChild(ofType: MP4TimeToSampleBox.self)
    }
    public var compositionTimeToSampleBox: MP4CompositionTimeToSampleBox? {
        self.firstChild(ofType: MP4CompositionTimeToSampleBox.self)
    }
    
    var sampleCount: UInt32 {
        get throws {
            try sampleSizeBox.unwrapOrFail(with: MP4Error.failedToFindBox(path: MP4SampleSizeBox.typeName)).sampleCount
        }
    }
    
    var samples: Range<MP4Index<UInt32>> {
        get throws {
            .zero..<MP4Index(index0: try self.sampleCount)
        }
    }
    
    public init(children: [any MP4Box]) {
        self.children = children
    }
    
    required public convenience init(reader: any MP4Reader) async throws {
        self.init(children: try await MP4BoxParser(reader: reader).readBoxes())
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
    
    public func byteRange(for sample: MP4Index<UInt32>) throws -> Range<Int> {
        return try self.byteRanges(for: sample..<sample+1).first!
    }
    
    public func byteRanges(for samples: Range<MP4Index<UInt32>>) throws -> [Range<Int>] {
        
        let sampleToChunkBox = try self.sampleToChunkBox.unwrapOrFail()
        let chunkOffsetBox = try self.chunkOffsetBox.unwrapOrFail(with: MP4Error.failedToFindBox(path: "stco/co64"))
        let sampleSizeBox = try self.sampleSizeBox.unwrapOrFail()
        
        var currentSample = samples.lowerBound
        var result: [Range<Int>] = []
        result.reserveCapacity(samples.count)
        
        repeat {
            guard let firstSampleInChunkPos = sampleToChunkBox.samplePosition(for: currentSample) else {
                throw MP4Error.internalError("failed to get chunk for sample")
            }
            let chunkOffset = chunkOffsetBox.chunkOffset(of: firstSampleInChunkPos.chunk)
            
            var sampleOffset = Int(chunkOffset)
            
            let firstSampleOfChunk = currentSample - firstSampleInChunkPos.sampleOfChunkIndex
            let lastSampleOfChunk = min(firstSampleOfChunk + firstSampleInChunkPos.samplesInChunk, samples.upperBound)
            for discardedSample in firstSampleOfChunk..<currentSample {
                sampleOffset += Int(sampleSizeBox.sampleSize(for: discardedSample))
            }
            while currentSample < lastSampleOfChunk {
                let sampleSize = Int(sampleSizeBox.sampleSize(for: currentSample))
                result.append(sampleOffset..<sampleOffset+sampleSize)
                sampleOffset += sampleSize
                currentSample += 1
            }
            
            
        } while currentSample != samples.upperBound
        
        return result
    }
    
    public struct SampleTimingInfo {
        public var duration: UInt32
        public var decodeTime: UInt32
        public var displayTime: UInt32
        
        public init(duration: UInt32, decodeTime: UInt32, displayTime: UInt32) {
            self.duration = duration
            self.decodeTime = decodeTime
            self.displayTime = displayTime
        }
    }
    
    public func timingInfo(for samples: Range<MP4Index<UInt32>>) throws -> [SampleTimingInfo] {
        let timeToSampleBox = try self.timeToSampleBox.unwrapOrFail()
        
        
        let decodeTimes = timeToSampleBox.times(for: samples)
        if let compositionTimeToSampleBox = self.compositionTimeToSampleBox {
            let offsets = compositionTimeToSampleBox.offsets(for: samples)
            
            guard offsets.count == decodeTimes.count else {
                throw MP4Error.internalError("number of sample times from stts does not match number of time offsets from ctts")
            }
            return zip(decodeTimes, offsets).map { decodeTimeRange, offset in
                    .init(duration: UInt32(decodeTimeRange.count), decodeTime: decodeTimeRange.lowerBound,
                          displayTime: UInt32(min(0, Int64(decodeTimeRange.lowerBound) + Int64(offset))))
            }
        } else {
            return decodeTimes.map { .init(duration: UInt32($0.count), decodeTime: $0.lowerBound, displayTime: $0.lowerBound) }
        }
    }
}
