//
//  MP4Track.swift
//
//
//  Created by Matteo Ludwig on 15.12.23.
//

import Foundation
import CoreMedia


open class MP4Track {
    public let box: MP4TrackBox
    private var reader: any MP4Reader
    
    private var _formatDescription: CMFormatDescription?
    public var formatDescription: CMFormatDescription {
        get async throws {
            if self._formatDescription == nil {
                self._formatDescription = try await makeFormatDescription()
            }
            return self._formatDescription!
        }
    }
    
    public var transformationMatrix: MP4TransformationMatrix {
        get throws {
            try self.box.firstChild(ofType: MP4TrackHeaderBox.self).unwrapOrFail().displayMatrix
        }
    }
    
    public var timescale: UInt32 {
        get throws {
            try self.box.mediaBox.unwrapOrFail().mediaHeaderBox.unwrapOrFail().timescale
        }
    }
    
    public var duration: TimeInterval {
        get throws {
            try self.box.mediaBox.unwrapOrFail().mediaHeaderBox.unwrapOrFail().duration
        }
    }
    
    public var nSamples: Int {
        get throws {
            Int(try self.box.mediaBox.unwrapOrFail().mediaInformationBox.unwrapOrFail().sampleTableBox.unwrapOrFail().sampleCount)
        }
    }
    
    public var nSyncSamples: Int {
        get throws {
            if let syncSampleCount = self.box.mediaBox?.mediaInformationBox?.sampleTableBox?.syncSamplesBox?.syncSamples.count {
                return syncSampleCount
            }
            return try self.nSamples
        }
    }
    
    public init(box: MP4TrackBox, reader: any MP4Reader) {
        self.box = box
        self.reader = reader
    }
    
    private func makeFormatDescription() async throws -> CMFormatDescription {
        
        let sampleDescriptionBox = try (self.box.mediaBox?.mediaInformationBox?.sampleTableBox?.sampleDescriptionBox).unwrapOrFail(with: MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.stbl.stsd"))
        
        if let avc1Box = sampleDescriptionBox.firstChild(ofType: MP4Avc1Box.self) {
            return try avc1Box.makeFormatDescription()
        } else if let hvc1Box = sampleDescriptionBox.firstChild(ofType: MP4Hvc1Box.self) {
            return try hvc1Box.makeFormatDescription()
        } else {
            throw MP4Error.unsupportedTrackFormat
        }
    }
    
    public func metaData() async throws -> MP4TrackMetaData? {
        do {
            switch try await self.formatDescription.mediaType {
            case .video:
                return try await MP4VideoTrackMetaData(trackBox: self.box, reader: self.reader)
            default:
                return nil
            }
            
        } catch MP4Error.unsupportedTrackFormat {
            return nil
        }
    }
    
    public func sampleData(for samples: Range<MP4Index<UInt32>>) async throws -> ([Range<Int>], Data) {
        let sampleTableBox = try self.box.mediaBox.unwrapOrFail().mediaInformationBox.unwrapOrFail().sampleTableBox.unwrapOrFail()
        let sampleRanges = try sampleTableBox.byteRanges(for: samples)
        
        guard !sampleRanges.isEmpty else { return ([], Data()) }
        
        let readRanges = sampleRanges.merged()
        var data = Data(capacity: readRanges.map { $0.count }.reduce(0, +))
        for readRange in readRanges {
            data.append(try await self.reader.readData(byteRange: readRange))
        }
        return (sampleRanges, data)
    }
    
    public func sampleBuffer(for samples: Range<MP4Index<UInt32>>) async throws -> CMSampleBuffer {
        let formatDescription = try await self.formatDescription
        let sampleTableBox = try self.box.mediaBox.unwrapOrFail().mediaInformationBox.unwrapOrFail().sampleTableBox.unwrapOrFail().timeToSampleBox.unwrapOrFail()
        
        let timescale = CMTimeScale(try self.timescale)
        
        let sampleTimings = sampleTableBox.times(for: samples).map { sampleTimeRange in
            CMSampleTimingInfo(duration: .init(value: CMTimeValue(sampleTimeRange.count), timescale: timescale),
                               presentationTimeStamp: .init(value: CMTimeValue(sampleTimeRange.lowerBound), timescale: timescale),
                               decodeTimeStamp: .init())
        }
        
        let (sampleRanges, samplesData) = try await self.sampleData(for: samples)
        
        guard sampleRanges.count == sampleTimings.count else {
            throw MP4Error.inconsistentSampleTableBox
        }
        
        let blockBuffer = try CMBlockBuffer(length: samplesData.count)
        try samplesData.withUnsafeBytes { buffer in
            try blockBuffer.replaceDataBytes(with: buffer)
        }
        
        return try CMSampleBuffer(dataBuffer: blockBuffer,
                                  formatDescription: formatDescription,
                                  numSamples: sampleRanges.count,
                                  sampleTimings: sampleTimings,
                                  sampleSizes: sampleRanges.map { $0.count })
    
    }
    
    public func sample(at timeOffset: TimeInterval) throws -> MP4Index<UInt32>? {
        
        let time = UInt32(timeOffset * TimeInterval(try self.timescale))
        guard let timeToSampleBox = self.box.mediaBox?.mediaInformationBox?.sampleTableBox?.timeToSampleBox else {
            throw MP4Error.failedToFindBox(path: "mdia.minf.stbl.stts")
        }
        return timeToSampleBox.sample(at: time)
    }
    
    public func syncSample(for timeOffset: TimeInterval) throws -> MP4Index<UInt32>? {
        guard let sample = try self.sample(at: timeOffset) else { return nil }
        guard let syncSampleBox = self.box.mediaBox?.mediaInformationBox?.sampleTableBox?.syncSamplesBox else { return sample }
        return syncSampleBox.syncSample(before: sample)
    }
}
