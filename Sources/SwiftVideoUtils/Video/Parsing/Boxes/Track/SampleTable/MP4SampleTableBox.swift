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
    
    public init(children: [any MP4Box]) throws {
        self.children = children
    }
    
    required public convenience init(reader: any MP4Reader) async throws {
        try self.init(children: try await MP4BoxParser(reader: reader).readBoxes())
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
    
    func byteRange(for sample: MP4Index<UInt32>) throws -> Range<Int> {
        guard let samplePositon = try self.sampleToChunkBox.unwrapOrFail().samplePosition(for: sample) else {
            throw MP4Error.internalError("failed to get chunk for sample")
        }
        
        let chunkOffset = try self.chunkOffsetBox.unwrapOrFail(with: MP4Error.failedToFindBox(path: "stco")).chunkOffset(of: samplePositon.chunk)
        
        let sampleSizeBox = try self.sampleSizeBox.unwrapOrFail()
        
        var sampleOffset = Int(chunkOffset)
        
        let firstSampleOfChunk = sample - samplePositon.sampleOfChunkIndex
        
        for i in firstSampleOfChunk..<sample {
            sampleOffset += Int(sampleSizeBox.sampleSize(for: i))
        }
        let syncSampleSize = Int(sampleSizeBox.sampleSize(for: sample))
        
        return sampleOffset..<sampleOffset+syncSampleSize
    }
}
