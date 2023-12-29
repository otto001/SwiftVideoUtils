//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 18.12.23.
//

import Foundation
import CoreMedia

public struct MP4VideoTrackMetaData: MP4TrackMetaData {
    public var trackWidth: Double
    public var trackHeight: Double
    
    public var mediaType: CMFormatDescription.MediaType { .video }
    public var mediaSubType: CMFormatDescription.MediaSubType?
    
    public var encodedWidth: Int?
    public var encodedHeight: Int?
    public var bitDepth: Int?
    public var averageFrameRate: Double?
    
    public var orientation: ExifOrientation?
    public var displayWidth: Double {
        orientation?.swapWidthAndHeight == true ? trackHeight : trackWidth
    }
    public var displayHeight: Double {
        orientation?.swapWidthAndHeight == true ? trackWidth : trackHeight
    }
    
    public init(trackWidth: Double, trackHeight: Double, 
                mediaSubType: CMFormatDescription.MediaSubType? = nil, 
                encodedWidth: Int, encodedHeight: Int,
                bitDepth: Int, averageFrameRate: Double? = nil,
                orientation: ExifOrientation? = nil) {
        self.trackWidth = trackWidth
        self.trackHeight = trackHeight
        self.mediaSubType = mediaSubType
        self.encodedWidth = encodedWidth
        self.encodedHeight = encodedHeight
        self.bitDepth = bitDepth
        self.averageFrameRate = averageFrameRate
        self.orientation = orientation
    }
    
    public init(trackBox: MP4TrackBox, reader: any MP4Reader) async throws {
        let trackHeader = try trackBox.trackHeaderBox.unwrapOrFail()
        let mediaBox = try trackBox.mediaBox.unwrapOrFail()
        let mediaHeader = try mediaBox.mediaHeaderBox.unwrapOrFail()
        let stblBox = try mediaBox.mediaInformationBox.unwrapOrFail().sampleTableBox.unwrapOrFail()
        
        self.trackWidth = trackHeader.trackWidth
        self.trackHeight = trackHeader.trackHeight
        let orientation = trackHeader.displayMatrix.exifOrientation
        self.orientation = orientation
        
        if let videoSampleEntryBox = stblBox.firstChild(ofType: MP4SampleDescriptionBox.self)?.firstChild(ofType: MP4VideoSampleEntryBox.self) {
            self.mediaSubType = videoSampleEntryBox.videoCodecType
            self.encodedWidth = Int(videoSampleEntryBox.width)
            self.encodedHeight = Int(videoSampleEntryBox.height)
            self.bitDepth = Int(videoSampleEntryBox.bitDepth)
        }
        
        self.averageFrameRate = (stblBox.timeToSampleBox?.averageSampleDuration()).map {
            Double(mediaHeader.timescale)/$0
        }
        
    }
}
