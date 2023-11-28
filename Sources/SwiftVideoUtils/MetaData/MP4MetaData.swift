//
//  MP4MetaData.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation
import CoreLocation
import CoreMedia


struct MP4MetaData {
    public var creationTime: Date
    public var modificationTime: Date
    
    public var duration: TimeInterval
    public var nextTrackId: Int
    
    public var videoCodec: CMFormatDescription.MediaSubType
    
    public var videoWidth: Int
    public var videoHeight: Int
    public var videoBitDepth: Int
    public var videoAverageFrameRate: Double?
    
    public var appleMetaData: MP4AppleMetaData?
    
    public var location: CLLocation? {
        appleMetaData?.location
    }
    
    init(moovBox: MP4MoovieBox, reader: any MP4Reader) async throws {
        guard let movieHeaderBox = moovBox.firstChild(ofType: MP4MovieHeaderBox.self) else {
            throw MP4Error.failedToFindBox(path: "moov.mvhd")
        }
        
        let mediaBox = moovBox.children(path: "trak.mdia").first { $0.firstChild(path: "minf.vmhd") != nil }
        guard let mediaBox = mediaBox else {
            throw MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.vmhd")
        }
        
        guard let mediaHeader = mediaBox.firstChild(ofType: MP4MediaHeaderBox.self) else {
            throw MP4Error.failedToFindBox(path: "moov.trak.mdia.mdhd")
        }
        
        guard let stblBox = mediaBox.firstChild(path: "minf.stbl") else {
            throw MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.stbl")
        }

        self.creationTime = movieHeaderBox.creationTime
        self.modificationTime = movieHeaderBox.modificationTime
        self.duration = movieHeaderBox.duration
        self.nextTrackId = Int(movieHeaderBox.nextTrackId)
        
        if let avc1Box = stblBox.firstChild(path: "stsd.avc1") as? MP4Avc1Box {
            self.videoCodec = .h264
            self.videoWidth = Int(avc1Box.width)
            self.videoHeight = Int(avc1Box.height)
            self.videoBitDepth = Int(avc1Box.bitDepth)
        } else if let hvc1Box = stblBox.firstChild(path: "stsd.hvc1") as? MP4Hvc1Box {
            self.videoCodec = .hevc
            self.videoWidth = Int(hvc1Box.width)
            self.videoHeight = Int(hvc1Box.height)
            self.videoBitDepth = Int(hvc1Box.bitDepth)
        } else {
            // TODO: better error reporting
            throw MP4Error.failedToFindBox(path: "stsd.hvc1")
        }
        
        self.videoAverageFrameRate = (moovBox.videoTrack?.sampleTableBox.timeToSampleBox?.averageSampleDuration()).map {
            Double(mediaHeader.timescale)/$0
        }
        
        self.appleMetaData = try? await .init(moovBox: moovBox, reader: reader)
    }
    
    init(boxes: [any MP4Box], reader: any MP4Reader) async throws {
        guard let moovBox = boxes.first(where: {$0.typeName == "moov"}) as? MP4MoovieBox else {
            throw MP4Error.failedToFindBox(path: "moov")
        }
        
        self = try await .init(moovBox: moovBox, reader: reader)
    }
}
