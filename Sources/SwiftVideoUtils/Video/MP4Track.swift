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
    
    public var numberOfSyncFrames: Int {
        get throws {
            if let syncSampleCount = self.box.mediaBox?.mediaInformationBox?.sampleTableBox?.syncSamplesBox?.syncSamples.count {
                return syncSampleCount
            }
            return Int(try self.box.mediaBox.unwrapOrFail().mediaInformationBox.unwrapOrFail().sampleTableBox.unwrapOrFail().sampleCount)
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
    
    public func sampleBuffer(for sample: MP4Index<UInt32>) async throws -> CMSampleBuffer {
        let formatDescription = try await self.formatDescription
        
        
        guard let sampleTableBox = self.box.mediaBox?.mediaInformationBox?.sampleTableBox else {
            throw MP4Error.failedToFindBox(path: "mdia.minf.stbl")
        }
        
        let sampleRange = try sampleTableBox.byteRange(for: sample)
        let sampleData = try await self.reader.readData(byteRange: sampleRange)
        
        let blockBuffer = try CMBlockBuffer(length: sampleRange.count)
        try sampleData.withUnsafeBytes { buffer in
            try blockBuffer.replaceDataBytes(with: buffer)
        }
        
        
        var sampleTimingInfo = CMSampleTimingInfo .init(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .zero)
        if let sampleTimeRange = sampleTableBox.timeToSampleBox?.time(for: sample) {
            let timescale = CMTimeScale(try self.timescale)
            sampleTimingInfo.duration = .init(value: CMTimeValue(sampleTimeRange.count), timescale: timescale)
            sampleTimingInfo.presentationTimeStamp = .init(value: CMTimeValue(sampleTimeRange.lowerBound), timescale: timescale)
        }
        
        return try CMSampleBuffer(dataBuffer: blockBuffer,
                                  formatDescription: formatDescription,
                                  numSamples: 1,
                                  sampleTimings: [sampleTimingInfo],
                                  sampleSizes: [sampleRange.count])
        
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
