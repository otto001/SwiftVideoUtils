//
//  MP4SampleTableBox.swift
//
//
//  Created by Matteo Ludwig on 24.11.23.
//

import Foundation


public class MP4SampleTableBox: MP4ParsableBox {
    public static let typeName: String = "stbl"
    public static let fullyParsable: Bool = true
    
    public var children: [any MP4Box]
    
    public var sampleDescriptionBox: MP4SampleDescriptionBox!
    public var sampleToChunkBox: MP4SampleToChunkBox!
    public var sampleSizeBox: MP4SampleSizeBox!
    public var chunkOffsetBox: MP4ChunkOffsetBox!
    public var syncSamplesBox: MP4SyncSampleBox?
    public var timeToSampleBox: MP4TimeToSampleBox?
    
    var sampleCount: UInt32 {
        sampleSizeBox.sampleCount
    }
    
    var samples: Range<MP4Index<UInt32>> {
        .zero..<MP4Index(index0: sampleSizeBox.sampleCount)
    }
    
    public init(children: [any MP4Box]) throws {
        self.children = children
        
        self.sampleDescriptionBox = try self.firstChild(ofType: MP4SampleDescriptionBox.self).unwrapOrFail(with: MP4Error.failedToFindBox(path: MP4SampleDescriptionBox.typeName))
        
        self.sampleToChunkBox = try self.firstChild(ofType: MP4SampleToChunkBox.self).unwrapOrFail(with: MP4Error.failedToFindBox(path: MP4SampleToChunkBox.typeName))
        
        self.sampleSizeBox = try self.firstChild(ofType: MP4SampleSizeBox.self).unwrapOrFail(with: MP4Error.failedToFindBox(path: MP4SampleSizeBox.typeName))
        
        self.chunkOffsetBox = try (self.firstChild(ofType: MP4ChunkOffset32Box.self) ?? self.firstChild(ofType: MP4ChunkOffset64Box.self)).unwrapOrFail(with: MP4Error.failedToFindBox(path: MP4ChunkOffset32Box.typeName))
        
        self.syncSamplesBox = self.firstChild(ofType: MP4SyncSampleBox.self)
        self.timeToSampleBox = self.firstChild(ofType: MP4TimeToSampleBox.self)
    }
    
    required public convenience init(reader: any MP4Reader) async throws {
        let children = try await MP4BoxParser(reader: reader).readBoxes()
        
        try self.init(children: children)
    }
    
//    public func syncSample(time: UInt32) async throws -> MP4Index<UInt32>? {
//        guard let syncSamples = syncSamplesBox?.syncSamples else {
//            return timeToSampleBox?.sample(time: time)
//        }
//    }
    
    func byteRange(for sample: MP4Index<UInt32>) -> Range<Int> {
        let samplePositon = self.sampleToChunkBox.samplePosition(for: sample)
        
        let chunkOffset = self.chunkOffsetBox.chunkOffset(of: samplePositon.chunk)
        
        var sampleOffset = Int(chunkOffset)
        
        let firstSampleOfChunk = sample - samplePositon.sampleOfChunkIndex
        
        for i in firstSampleOfChunk..<sample {
            sampleOffset += Int(self.sampleSizeBox.sampleSize(for: i))
        }
        let syncSampleSize = Int(self.sampleSizeBox.sampleSize(for: sample))
        
        return sampleOffset..<sampleOffset+syncSampleSize
    }
}
