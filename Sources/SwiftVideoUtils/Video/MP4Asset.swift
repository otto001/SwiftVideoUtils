//
//  MP4Asset.swift
//
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation
import CoreMedia


public class MP4Asset {
    private var reader: any MP4Reader
    private var parser: MP4BoxParser
    
    
    private var _boxes: [any MP4Box] = []
    public var boxes: [any MP4Box] {
        get async throws {
            if !self.parser.endOfFile {
                self._boxes.append(contentsOf: try await parser.readBoxes())
            }
            return self._boxes
        }
    }
    
    private var _moovBox: MP4MoovieBox?
    public var moovBox: MP4MoovieBox {
        get async throws {
            if _moovBox == nil {
                _moovBox = try await findMoovBox()
            }
            return _moovBox!
        }
    }
    
    private var _videoFormatDescription: CMFormatDescription?
    public var videoFormatDescription: CMFormatDescription {
        get async throws {
            if _videoFormatDescription == nil {
                _videoFormatDescription = try await makeVideoFormatDescription()
            }
            return _videoFormatDescription!
        }
    }
    
    public init(reader: any MP4Reader) async throws {
        self.reader = reader
        self.parser = MP4BoxParser(reader: reader)
    }
    
    public convenience init(url: URL) async throws {
        try await self.init(reader: try MP4FileReader(url: url))
    }
    
    public convenience init(data: Data) async throws {
        try await self.init(reader: MP4BufferReader(data: data))
    }
    
    public func metaData() async throws -> MP4MetaData {
        try await MP4MetaData(moovBox: try await moovBox, reader: reader)
    }
    
    private func findMoovBox() async throws -> MP4MoovieBox {
        if let moovBox = self._boxes.first(where: {$0.typeName == "moov"}) {
            return moovBox as! MP4MoovieBox
        }
        
        while true {
            let box = try await self.parser.readBox()
            self._boxes.append(box)
            if box.typeName == "moov" {
                if let moovBox = box as? MP4MoovieBox {
                    return moovBox
                } else {
                    throw (box as? MP4ParsingErrorBox)?.error ?? MP4Error.internalError("moov box parsed as \(box.self)")
                }
            }
        }
    }
    
    public func data(byteRange: Range<Int>) async throws -> Data {
        return try await self.reader.readData(byteRange: byteRange)
    }
    
    public func makeVideoFormatDescription() async throws -> CMFormatDescription {
        let videoTrack = try await self.moovBox.videoTrack.unwrapOrFail(with: MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.vmhd"))
        let sampleDescriptionBox = try (videoTrack.mediaBox?.mediaInformationBox?.sampleTableBox?.sampleDescriptionBox).unwrapOrFail(with: MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.stbl.stsd"))
        
        if let avc1Box = sampleDescriptionBox.firstChild(ofType: MP4Avc1Box.self) {
            return try avc1Box.makeFormatDescription()
        } else if let hvc1Box = sampleDescriptionBox.firstChild(ofType: MP4Hvc1Box.self) {
            return try hvc1Box.makeFormatDescription()
        } else {
            throw MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.stbl.stsd.avc1")
        }
    }
    
    
    public func videoSampleBuffer(for sample: MP4Index<UInt32>) async throws -> CMSampleBuffer {
        let videoFormatDescription = try await self.videoFormatDescription
        
        let videoTrack = try await self.moovBox.videoTrack.unwrapOrFail(with: MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.vmhd"))
        let sampleTableBox = try (videoTrack.mediaBox?.mediaInformationBox?.sampleTableBox).unwrapOrFail(with: MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.stbl"))
        
        let sampleRange = try sampleTableBox.byteRange(for: sample)
        let sampleSize = sampleRange.count
        let sampleData = try await self.data(byteRange: sampleRange)
        
        // TODO: Can i safely avoid copying data?
        let blockBuffer = try CMBlockBuffer(length: sampleSize)
        try sampleData.withUnsafeBytes { buffer in
            try blockBuffer.replaceDataBytes(with: buffer)
        }
        
        return try CMSampleBuffer(dataBuffer: blockBuffer,
                                  formatDescription: videoFormatDescription,
                                  numSamples: 1,
                                  sampleTimings: [.init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero)],
                                  sampleSizes: [sampleSize])

    }
}


extension MP4Asset: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(try await boxes)
    }
}
