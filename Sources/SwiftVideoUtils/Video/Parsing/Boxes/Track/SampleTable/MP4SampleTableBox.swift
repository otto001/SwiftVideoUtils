//
//  MP4SampleTableBox.swift
//
//
//  Created by Matteo Ludwig on 24.11.23.
//

import Foundation


public class MP4SampleTableBox: MP4ParsableBox {
    public static let typeName: MP4FourCC = "stbl"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4SampleDescriptionBox.self,
                                                               MP4TimeToSampleBox.self,
                                                               MP4CompositionTimeToSampleBox.self,
                                                               MP4SampleToChunkBox.self,
                                                               MP4StandardSampleSizeBox.self,
                                                               MP4CompactSampleSizeBox.self,
                                                               MP4ChunkOffset32Box.self,
                                                               MP4ChunkOffset64Box.self,
                                                               MP4SyncSampleBox.self,]
    
    public var children: [any MP4Box]
    
    public var sampleDescriptionBox: MP4SampleDescriptionBox? {
        self.firstChild(ofType: MP4SampleDescriptionBox.self)
    }
    public var sampleToChunkBox: MP4SampleToChunkBox? {
        self.firstChild(ofType: MP4SampleToChunkBox.self)
    }
    public var sampleSizeBox: (any MP4SampleSizeBox)? {
        self.firstChild(ofType: MP4StandardSampleSizeBox.self) ?? self.firstChild(ofType: MP4CompactSampleSizeBox.self)
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
            try sampleSizeBox.unwrapOrFail(with: MP4Error.failedToFindBox(path: "stsz/stz2")).sampleCount
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
    
    required public convenience init(reader: MP4SequentialReader) async throws {
        self.init(children: try await reader.readBoxes(parentType: Self.self))
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
        let sampleSizeBox = try self.sampleSizeBox.unwrapOrFail(with: MP4Error.failedToFindBox(path: "stsz/stz2"))
        
        let samples = samples.lowerBound..<min(samples.upperBound, .init(index0: sampleSizeBox.sampleCount))
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
                sampleOffset += Int(sampleSizeBox.sampleSize(for: discardedSample)!)
            }
            while currentSample < lastSampleOfChunk {
                let sampleSize = Int(sampleSizeBox.sampleSize(for: currentSample)!)
                result.append(sampleOffset..<sampleOffset+sampleSize)
                sampleOffset += sampleSize
                currentSample += 1
            }
            
            
        } while currentSample != samples.upperBound
        
        return result
    }
    
    public struct SampleTimingInfo: Equatable {
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
                          displayTime: UInt32(max(0, Int64(decodeTimeRange.lowerBound) + Int64(offset))))
            }
        } else {
            return decodeTimes.map { .init(duration: UInt32($0.count), decodeTime: $0.lowerBound, displayTime: $0.lowerBound) }
        }
    }
}
