//
//  MP4MetaDataTests.swift
//  
//
//  Created by Matteo Ludwig on 26.11.23.
//

import XCTest
import CoreLocation


@testable import SwiftVideoUtils

private var dateFormatter: ISO8601DateFormatter = .init()
extension Date {
    var isoString: String {
        dateFormatter.string(from: self)
    }
}

final class MP4MetaDataTests: XCTestCase {
    
    func assertLocationEqual(_ lhd: CLLocation?, _ rhd: CLLocation, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNotNil(lhd, file: file, line: line)
        
        if let lhd = lhd {
            XCTAssertEqual(lhd.coordinate.latitude, rhd.coordinate.latitude, accuracy: 0.0001, file: file, line: line)
            XCTAssertEqual(lhd.coordinate.longitude, rhd.coordinate.longitude, accuracy: 0.0001, file: file, line: line)
            XCTAssertEqual(lhd.altitude, rhd.altitude, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(lhd.horizontalAccuracy, rhd.horizontalAccuracy, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(lhd.verticalAccuracy, rhd.verticalAccuracy, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(lhd.timestamp, rhd.timestamp, file: file, line: line)
        }
    }

    func testiPhoneFHD() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD.MOV")))
        let metaData = try await asset.metaData()
        print(try await asset.moovBox.description)
        XCTAssertEqual(metaData.creationTime.isoString, "2023-11-23T20:07:53Z")
        XCTAssertEqual(metaData.modificationTime.isoString, "2023-11-23T20:07:58Z")
        
        XCTAssertEqual(metaData.duration, 5.001, accuracy: 0.001)
        XCTAssertEqual(metaData.nextTrackID, 6)
        
        XCTAssertEqual(metaData.videoTrackWidth, 1920)
        XCTAssertEqual(metaData.videoTrackHeight, 1080)
        
        XCTAssertEqual(metaData.videoCodec, .h264)
        XCTAssertEqual(metaData.videoEncodedWidth, 1920)
        XCTAssertEqual(metaData.videoEncodedHeight, 1080)
        XCTAssertEqual(metaData.videoBitDepth, 24)
        
        XCTAssertEqual(metaData.videoOrientation, .identity)
        XCTAssertEqual(metaData.videoWidth, 1920)
        XCTAssertEqual(metaData.videoHeight, 1080)
        
        XCTAssertEqual(metaData.videoAverageFrameRate ?? -1, 59.96, accuracy: 0.01)
        
        XCTAssertNotNil(metaData.appleMetaData)
        
        if let appleMetaData = metaData.appleMetaData {
            XCTAssertEqual(appleMetaData.make, "Apple")
            XCTAssertEqual(appleMetaData.model, "iPhone 13 Pro")
            XCTAssertEqual(appleMetaData.software, "17.1.1")
            XCTAssertEqual(appleMetaData.cameraLensModel, "iPhone 13 Pro back camera 5.7mm f/1.5")
            XCTAssertEqual(appleMetaData.focalLength35mm, 27)
            XCTAssertEqual(appleMetaData.creationDate?.isoString, "2023-11-23T20:07:53Z")
            
            XCTAssertEqual(appleMetaData.orientations, [.init(time: 0, orientation: 1)])
            
            assertLocationEqual(appleMetaData.location, .init(coordinate: .init(latitude: 52.3734, longitude: 4.8921), altitude: 5.223, horizontalAccuracy: 4.75, verticalAccuracy: 0, timestamp: metaData.appleMetaData?.creationDate ?? Date()))
        }
    }
    
    func testiPhoneFHDPotrait() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD_Portrait.MOV")))
        let metaData = try await asset.metaData()
        print(try await asset.moovBox.description)
        XCTAssertEqual(metaData.creationTime.isoString, "2023-11-30T10:43:29Z")
        XCTAssertEqual(metaData.modificationTime.isoString, "2023-11-30T10:43:31Z")
        
        XCTAssertEqual(metaData.duration, 1.551, accuracy: 0.001)
        XCTAssertEqual(metaData.nextTrackID, 6)
        
        XCTAssertEqual(metaData.videoTrackWidth, 1920)
        XCTAssertEqual(metaData.videoTrackHeight, 1080)
        
        XCTAssertEqual(metaData.videoCodec, .h264)
        XCTAssertEqual(metaData.videoEncodedWidth, 1920)
        XCTAssertEqual(metaData.videoEncodedHeight, 1080)
        XCTAssertEqual(metaData.videoBitDepth, 24)
        
        XCTAssertEqual(metaData.videoOrientation, .rotate90deg)
        XCTAssertEqual(metaData.videoWidth, 1080)
        XCTAssertEqual(metaData.videoHeight, 1920)
        
        XCTAssertEqual(metaData.videoAverageFrameRate ?? -1, 59.935, accuracy: 0.01)
        
        XCTAssertNotNil(metaData.appleMetaData)
        
        if let appleMetaData = metaData.appleMetaData {
            XCTAssertEqual(appleMetaData.make, "Apple")
            XCTAssertEqual(appleMetaData.model, "iPhone 13 Pro")
            XCTAssertEqual(appleMetaData.software, "17.1.1")
            XCTAssertEqual(appleMetaData.cameraLensModel, "iPhone 13 Pro back camera 1.57mm f/1.8")
            XCTAssertEqual(appleMetaData.focalLength35mm, 22)
            XCTAssertEqual(appleMetaData.creationDate?.isoString, "2023-11-30T10:43:29Z")
            
            XCTAssertEqual(appleMetaData.orientations, [.init(time: 0, orientation: 6)])
            
            assertLocationEqual(appleMetaData.location, .init(coordinate: .init(latitude: 50.7793, longitude: 6.0593), altitude: 226.482, horizontalAccuracy: 35.0, verticalAccuracy: 0, timestamp: metaData.appleMetaData?.creationDate ?? Date()))
        }
    }
    
    func testiPhoneUHD() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_UHD.MOV")))
        let metaData = try await asset.metaData()
        
        XCTAssertEqual(metaData.creationTime.isoString, "2023-11-23T20:08:03Z")
        XCTAssertEqual(metaData.modificationTime.isoString, "2023-11-23T20:08:10Z")
        
        XCTAssertEqual(metaData.duration, 5.92, accuracy: 0.001)
        XCTAssertEqual(metaData.nextTrackID, 6)
        
        XCTAssertEqual(metaData.videoTrackWidth, 3840)
        XCTAssertEqual(metaData.videoTrackHeight, 2160)
        
        XCTAssertEqual(metaData.videoCodec, .hevc)
        XCTAssertEqual(metaData.videoEncodedWidth, 3840)
        XCTAssertEqual(metaData.videoEncodedHeight, 2160)
        XCTAssertEqual(metaData.videoBitDepth, 24)
        
        XCTAssertEqual(metaData.videoOrientation, .identity)
        XCTAssertEqual(metaData.videoWidth, 3840)
        XCTAssertEqual(metaData.videoHeight, 2160)
        XCTAssertEqual(metaData.videoAverageFrameRate ?? -1, 59.96, accuracy: 0.01)

        XCTAssertNotNil(metaData.appleMetaData)
        
        if let appleMetaData = metaData.appleMetaData {
            XCTAssertEqual(appleMetaData.make, "Apple")
            XCTAssertEqual(appleMetaData.model, "iPhone 13 Pro")
            XCTAssertEqual(appleMetaData.software, "17.1.1")
            XCTAssertEqual(appleMetaData.cameraLensModel, "iPhone 13 Pro back camera 5.7mm f/1.5")
            XCTAssertEqual(appleMetaData.focalLength35mm, 27)
            XCTAssertEqual(appleMetaData.creationDate?.isoString, "2023-11-23T20:08:03Z")
            
            XCTAssertEqual(appleMetaData.orientations, [.init(time: 0, orientation: 1)])
            
            assertLocationEqual(appleMetaData.location, .init(coordinate: .init(latitude: 52.3734, longitude: 4.8921), altitude: 4.994, horizontalAccuracy: 4.73873, verticalAccuracy: 0, timestamp: metaData.appleMetaData?.creationDate ?? Date()))
        }
    }
    
    func testGoProH8() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_GoPro_H8.mp4")))
        let metaData = try await asset.metaData()
        
        XCTAssertEqual(metaData.creationTime.isoString, "2019-11-08T17:57:16Z")
        XCTAssertEqual(metaData.modificationTime.isoString, "2019-11-08T17:57:16Z")
        
        XCTAssertEqual(metaData.duration, 86.16925, accuracy: 0.001)
        XCTAssertEqual(metaData.nextTrackID, 3)
        
        XCTAssertEqual(metaData.videoTrackWidth, 1920)
        XCTAssertEqual(metaData.videoTrackHeight, 1080)
        
        XCTAssertEqual(metaData.videoCodec, .h264)
        XCTAssertEqual(metaData.videoEncodedWidth, 1920)
        XCTAssertEqual(metaData.videoEncodedHeight, 1080)
        XCTAssertEqual(metaData.videoBitDepth, 24)
        
        XCTAssertEqual(metaData.videoOrientation, .identity)
        XCTAssertEqual(metaData.videoWidth, 1920)
        XCTAssertEqual(metaData.videoHeight, 1080)
        
        XCTAssertEqual(metaData.videoAverageFrameRate ?? -1, 29.942, accuracy: 0.01)
    }
    
    func testGooglePhotosAndroid10() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_GooglePhotos_Android10.mp4")))
        let metaData = try await asset.metaData()
        
        XCTAssertEqual(metaData.creationTime.isoString, "2020-02-26T20:05:56Z")
        XCTAssertEqual(metaData.modificationTime.isoString, "2020-02-26T20:05:56Z")
        
        XCTAssertEqual(metaData.duration, 12.962, accuracy: 0.001)
        XCTAssertEqual(metaData.nextTrackID, 3)
        
        XCTAssertEqual(metaData.videoTrackWidth, 3840)
        XCTAssertEqual(metaData.videoTrackHeight, 2160)
        
        XCTAssertEqual(metaData.videoCodec, .h264)
        XCTAssertEqual(metaData.videoEncodedWidth, 3840)
        XCTAssertEqual(metaData.videoEncodedHeight, 2160)
        XCTAssertEqual(metaData.videoBitDepth, 24)
        
        XCTAssertEqual(metaData.videoOrientation, .identity)
        XCTAssertEqual(metaData.videoWidth, 3840)
        XCTAssertEqual(metaData.videoHeight, 2160)
        XCTAssertEqual(metaData.videoAverageFrameRate ?? -1, 60.02, accuracy: 0.01)
    }
}
