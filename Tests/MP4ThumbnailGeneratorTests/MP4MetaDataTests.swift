//
//  MP4MetaDataTests.swift
//  
//
//  Created by Matteo Ludwig on 26.11.23.
//

import XCTest

@testable import MP4ThumbnailGenerator

private var dateFormatter: ISO8601DateFormatter = .init()
extension Date {
    var isoString: String {
        dateFormatter.string(from: self)
    }
}

final class MP4MetaDataTests: XCTestCase {

    func testiPhoneFHD() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD.MOV")))
        let metaData = try await asset.metaData()
        
        XCTAssertEqual(metaData.creationTime.isoString, "2023-11-23T19:07:53Z")
        XCTAssertEqual(metaData.modificationTime.isoString, "2023-11-23T19:07:58Z")
        
        XCTAssertEqual(metaData.duration, 5.001, accuracy: 0.001)
        XCTAssertEqual(metaData.nextTrackId, 65536)
        
        XCTAssertEqual(metaData.videoCodec, .h264)
        XCTAssertEqual(metaData.videoWidth, 1920)
        XCTAssertEqual(metaData.videoHeight, 1080)
        XCTAssertEqual(metaData.videoBitDepth, 24)
        XCTAssertEqual(metaData.videoAverageFrameRate ?? -1, 59.96, accuracy: 0.01)
        
        
    }
    
    func testiPhoneUHD() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_UHD.MOV")))
        let metaData = try await asset.metaData()
        
        XCTAssertEqual(metaData.creationTime.isoString, "2023-11-23T19:08:03Z")
        XCTAssertEqual(metaData.modificationTime.isoString, "2023-11-23T19:08:10Z")
        
        XCTAssertEqual(metaData.duration, 5.92, accuracy: 0.001)
        XCTAssertEqual(metaData.nextTrackId, 65536)
        
        XCTAssertEqual(metaData.videoCodec, .h265)
        XCTAssertEqual(metaData.videoWidth, 3840)
        XCTAssertEqual(metaData.videoHeight, 2160)
        XCTAssertEqual(metaData.videoBitDepth, 24)
        XCTAssertEqual(metaData.videoAverageFrameRate ?? -1, 59.96, accuracy: 0.01)
    }
}
