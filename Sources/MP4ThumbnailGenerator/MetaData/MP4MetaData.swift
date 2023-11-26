//
//  MP4MetaData.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation
import CoreLocation

struct MP4MetaData {
    public var creationTime: Date
    public var modificationTime: Date
    
    public var duration: TimeInterval
    public var nextTrackId: Int
    
    public var videoCodec: MP4VideoCodec
    
    public var videoWidth: Int
    public var videoHeight: Int
    public var videoBitDepth: Int
    public var videoAverageFrameRate: Double?
    
    public var orientationData: MP4OrientationMetaData?
    
    public var appleMetaData: MP4AppleMetaData?
    
    public var location: CLLocation? {
        appleMetaData?.location
    }
    
    init(moovBox: MP4MoovieBox, reader: any MP4Reader) async throws {
        guard let movieHeaderBox = moovBox.firstChild(ofType: MP4MovieHeaderBox.self) else {
            throw MP4Error.failedToFindBox(path: "moov.mvhd")
        }
        
        let minfBox = moovBox.children(path: "trak.mdia.minf").first { $0.firstChild(ofType: "vmhd") != nil }
        guard let minfBox = minfBox else {
            throw MP4Error.failedToFindBox(path: "moov.trak.mdia.minf.vmhd")
        }
        
        guard let stblBox = minfBox.firstChild(path: "stbl") else {
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
            self.videoCodec = .h265
            self.videoWidth = Int(hvc1Box.width)
            self.videoHeight = Int(hvc1Box.height)
            self.videoBitDepth = Int(hvc1Box.bitDepth)
        } else {
            // TODO: better error reporting
            throw MP4Error.failedToFindBox(path: "stsd.hvc1")
        }
        
        self.videoAverageFrameRate = (moovBox.videoTrack?.sampleTableBox.timeToSampleBox?.averageSampleDuration()).map {
            Double(movieHeaderBox.timescale)/$0
        }
        
        self.orientationData = try? await .init(moovBox: moovBox, reader: reader)
        self.appleMetaData = try? await .init(moovBox: moovBox, reader: reader)
    }
    
    init(boxes: [any MP4Box], reader: any MP4Reader) async throws {
        guard let moovBox = boxes.first(where: {$0.typeName == "moov"}) as? MP4MoovieBox else {
            throw MP4Error.failedToFindBox(path: "moov")
        }
        
        self = try await .init(moovBox: moovBox, reader: reader)
    }
}
