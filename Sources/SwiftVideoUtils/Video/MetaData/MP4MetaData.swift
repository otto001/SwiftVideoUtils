//
//  MP4MetaData.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation
import CoreLocation
import CoreMedia


public struct MP4MetaData {
    public var creationTime: Date
    public var modificationTime: Date
    
    public var duration: TimeInterval
    public var nextTrackID: Int
    
    public var videoTrackWidth: Double
    public var videoTrackHeight: Double
    
    public var videoCodec: CMFormatDescription.MediaSubType
    
    public var videoEncodedWidth: Int
    public var videoEncodedHeight: Int
    public var videoBitDepth: Int
    public var videoAverageFrameRate: Double?
    
    public var videoOrientation: ExifOrientation?
    public var videoWidth: Double {
        videoOrientation?.swapWidthAndHeight == true ? videoTrackHeight : videoTrackWidth
    }
    public var videoHeight: Double {
        videoOrientation?.swapWidthAndHeight == true ? videoTrackWidth : videoTrackHeight
    }
    
    public var appleMetaData: MP4AppleMetaData?
    
    public var location: CLLocation? {
        appleMetaData?.location
    }
    
    public init(moovBox: MP4MoovieBox, reader: any MP4Reader) async throws {
        let movieHeaderBox = try moovBox.firstChild(ofType: MP4MovieHeaderBox.self).unwrapOrFail(
            with: MP4Error.failedToFindBox(path: "moov.mvhd")
        )
        
        let videoTrack = try moovBox.videoTrack.unwrapOrFail(
            with: MP4Error.noVideoTrack
        )
        
        let videoTrackHeader = try videoTrack.trackHeaderBox.unwrapOrFail(
            with: MP4Error.failedToFindBox(path: "moov.trak.tkhd")
        )
        
        let mediaBox = try videoTrack.firstChild(ofType: MP4MediaBox.self).unwrapOrFail(
            with: MP4Error.failedToFindBox(path: "moov.trak.mdia")
        )

        let mediaHeader = try mediaBox.firstChild(ofType: MP4MediaHeaderBox.self).unwrapOrFail(
            with: MP4Error.failedToFindBox(path: "moov.trak.mdia.mdhd")
        )
        
        let stblBox = try mediaBox.firstChild(path: "minf.stbl").unwrapOrFail(
            with: MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.stbl")
        )


        self.creationTime = movieHeaderBox.creationTime
        self.modificationTime = movieHeaderBox.modificationTime
        self.duration = movieHeaderBox.durationSeconds
        self.nextTrackID = Int(movieHeaderBox.nextTrackID)
        
        self.videoTrackWidth = videoTrackHeader.trackWidth
        self.videoTrackHeight = videoTrackHeader.trackHeight
        let videoOrientation = videoTrackHeader.displayMatrix.exifOrientation
        self.videoOrientation = videoOrientation
        
        if let avc1Box = stblBox.firstChild(path: "stsd.avc1") as? MP4Avc1Box {
            self.videoCodec = .h264
            self.videoEncodedWidth = Int(avc1Box.width)
            self.videoEncodedHeight = Int(avc1Box.height)
            self.videoBitDepth = Int(avc1Box.bitDepth)
        } else if let hvc1Box = stblBox.firstChild(path: "stsd.hvc1") as? MP4Hvc1Box {
            self.videoCodec = .hevc
            self.videoEncodedWidth = Int(hvc1Box.width)
            self.videoEncodedHeight = Int(hvc1Box.height)
            self.videoBitDepth = Int(hvc1Box.bitDepth)
        } else {
            // TODO: better error reporting
            throw MP4Error.failedToFindBox(path: "stsd.hvc1")
        }
        
        self.videoAverageFrameRate = (moovBox.videoTrack?.mediaBox?.mediaInformationBox?.sampleTableBox?.timeToSampleBox?.averageSampleDuration()).map {
            Double(mediaHeader.timescale)/$0
        }
        
        self.appleMetaData = try? await .init(moovBox: moovBox, reader: reader)
    }
    
    public init(boxes: [any MP4Box], reader: any MP4Reader) async throws {
        guard let moovBox = boxes.first(where: {$0.typeName == "moov"}) as? MP4MoovieBox else {
            throw MP4Error.failedToFindBox(path: "moov")
        }
        
        self = try await .init(moovBox: moovBox, reader: reader)
    }
}
