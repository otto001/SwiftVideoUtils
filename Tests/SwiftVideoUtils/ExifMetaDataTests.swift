//
//  ExifMetaDataTests.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import XCTest

@testable import SwiftVideoUtils

final class ExifMetaDataTests: XCTestCase {
    
    func testJpegNikon() throws {
        let data = try Data(contentsOf: urlForFileName("TestImage.jpeg"))
        let metaData = try ExifMetaData(imageData: data)
        
        
        XCTAssertEqual(metaData.dateTimeOriginal?.deviceTime?.isoString, "2012-08-08T14:55:30Z")
        XCTAssertEqual(metaData.dateTimeDigitized?.deviceTime?.isoString, "2012-08-08T14:55:30Z")
        XCTAssertEqual(metaData.dateTimeTiff?.deviceTime?.isoString, "2012-08-08T14:55:30Z")
        
        XCTAssertEqual(metaData.make, "NIKON CORPORATION")
        XCTAssertEqual(metaData.model, "NIKON D800E")
        XCTAssertEqual(metaData.lensMake, nil)
        XCTAssertEqual(metaData.lensModel, "16.0-35.0 mm f/4.0")
        
        XCTAssertEqual(metaData.artist, "Nicolas Cornet")
        XCTAssertEqual(metaData.software, "Aperture 3.4.5")
        XCTAssertEqual(metaData.copyright, "Nicolas Cornet")
        
        XCTAssertEqual(metaData.profileName, "sRGB IEC61966-2.1")
        
        XCTAssertEqual(metaData.dataWidth, 3000)
        XCTAssertEqual(metaData.dataHeight, 2002)
        XCTAssertEqual(metaData.orientation, .identity)
        XCTAssertEqual(metaData.width, 3000)
        XCTAssertEqual(metaData.height, 2002)
        
        XCTAssertEqual(metaData.bitDepth, 8)
        
        XCTAssertEqual(metaData.horizontalResolution, 72)
        XCTAssertEqual(metaData.verticalResolution, 72)
        
        XCTAssertEqual(metaData.focalLength, 16)
        XCTAssertEqual(metaData.focalLength35mm, 16)
        XCTAssertEqual(metaData.aperatureValue ?? -1, 6.6438, accuracy: 0.001)
        XCTAssertEqual(metaData.fValue ?? -1, 10, accuracy: 0.001)
        XCTAssertEqual(metaData.contrast, 0)
        XCTAssertEqual(metaData.saturation, 0)
        XCTAssertEqual(metaData.sharpness, 0)
        XCTAssertEqual(metaData.exposureMode, 1)
        XCTAssertEqual(metaData.isoSpeedRatings, [200])
        XCTAssertEqual(metaData.exposureTime ?? -1, 20, accuracy: 0.001)
        
        assertLocationEqual(metaData.location, .init(coordinate: .init(latitude: 63.5314, longitude: -19.5112), altitude: 107.46, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date()))
        
    }
    
    func testJpegIPhone() throws {
        let data = try Data(contentsOf: urlForFileName("TestImage-iPhone.jpg"))
        let metaData = try ExifMetaData(imageData: data)
        
        
        XCTAssertEqual(metaData.dateTimeOriginal?.deviceTime?.isoString, "2024-09-13T16:21:05Z")
        XCTAssertEqual(metaData.dateTimeDigitized?.deviceTime?.isoString, "2024-09-13T16:21:05Z")
        XCTAssertEqual(metaData.dateTimeOriginal?.timeOffset, -7 * 3600)
        XCTAssertEqual(metaData.dateTimeDigitized?.timeOffset, -7 * 3600)
        XCTAssertEqual(metaData.dateTimeTiff?.deviceTime?.isoString, "2024-09-13T16:21:05Z")
        
        XCTAssertEqual(metaData.make, "Apple")
        XCTAssertEqual(metaData.model, "iPhone 13 Pro")
        XCTAssertEqual(metaData.lensMake, "Apple")
        XCTAssertEqual(metaData.lensModel, "iPhone 13 Pro back triple camera 5.7mm f/1.5")
        
        XCTAssertEqual(metaData.artist, nil)
        XCTAssertEqual(metaData.software, "17.6.1")
        XCTAssertEqual(metaData.copyright, nil)
        
        XCTAssertEqual(metaData.profileName, "Display P3")
        
        XCTAssertEqual(metaData.dataWidth, 4032)
        XCTAssertEqual(metaData.dataHeight, 3024)
        XCTAssertEqual(metaData.orientation, .identity)
        XCTAssertEqual(metaData.width, 4032)
        XCTAssertEqual(metaData.height, 3024)
        
        XCTAssertEqual(metaData.bitDepth, 8)
        
        XCTAssertEqual(metaData.horizontalResolution, 72)
        XCTAssertEqual(metaData.verticalResolution, 72)
        
        XCTAssertEqual(metaData.focalLength, 5.7)
        XCTAssertEqual(metaData.focalLength35mm, 26)
        XCTAssertEqual(metaData.aperatureValue ?? -1, 1.169, accuracy: 0.001)
        XCTAssertEqual(metaData.fValue ?? -1, 1.5, accuracy: 0.001)
        XCTAssertEqual(metaData.contrast, nil)
        XCTAssertEqual(metaData.saturation, nil)
        XCTAssertEqual(metaData.sharpness, nil)
        XCTAssertEqual(metaData.exposureMode, 0)
        XCTAssertEqual(metaData.isoSpeedRatings, [50])
        XCTAssertEqual(metaData.exposureTime ?? -1, 0.0002, accuracy: 0.0001)
        
        assertLocationEqual(metaData.location, .init(coordinate: .init(latitude: 36.05365283333333, longitude: -112.0832445), altitude: 2192.6988505747127, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date()))
        
    }
    
    func testHeic() throws {
        let data = try Data(contentsOf: urlForFileName("TestImage.heic"))
        let metaData = try ExifMetaData(imageData: data)
        
        
        XCTAssertEqual(metaData.dateTimeOriginal?.deviceTime?.isoString, "2018-03-30T12:14:19Z")
        XCTAssertEqual(metaData.dateTimeDigitized?.deviceTime?.isoString, "2018-03-30T12:14:19Z")
        XCTAssertEqual(metaData.dateTimeTiff?.deviceTime?.isoString, "2018-03-30T12:14:19Z")
        
        XCTAssertEqual(metaData.make, "Apple")
        XCTAssertEqual(metaData.model, "iPhone X")
        XCTAssertEqual(metaData.lensMake, "Apple")
        XCTAssertEqual(metaData.lensModel, "iPhone X back dual camera 6mm f/2.4")
        
        XCTAssertEqual(metaData.artist, nil)
        XCTAssertEqual(metaData.software, "12.0")
        XCTAssertEqual(metaData.copyright, nil)
        
        XCTAssertEqual(metaData.profileName, "Display P3")
        
        XCTAssertEqual(metaData.dataWidth, 4032)
        XCTAssertEqual(metaData.dataHeight, 3024)
        XCTAssertEqual(metaData.orientation, .rotate180deg)
        XCTAssertEqual(metaData.width, 4032)
        XCTAssertEqual(metaData.height, 3024)
        
        XCTAssertEqual(metaData.bitDepth, 8)
        
        XCTAssertEqual(metaData.horizontalResolution, 72)
        XCTAssertEqual(metaData.verticalResolution, 72)
        
        XCTAssertEqual(metaData.focalLength, 6.0)
        XCTAssertEqual(metaData.focalLength35mm, 52)
        XCTAssertEqual(metaData.aperatureValue ?? -1, 2.526, accuracy: 0.001)
        XCTAssertEqual(metaData.fValue ?? -1, 2.4, accuracy: 0.001)
        XCTAssertEqual(metaData.contrast, nil)
        XCTAssertEqual(metaData.saturation, nil)
        XCTAssertEqual(metaData.sharpness, nil)
        XCTAssertEqual(metaData.exposureMode, 0)
        XCTAssertEqual(metaData.isoSpeedRatings, [16])
        XCTAssertEqual(metaData.exposureTime ?? -1, 0.0047, accuracy: 0.001)
        
        assertLocationEqual(metaData.location, .init(coordinate: .init(latitude: 37.760, longitude: -122.50956), altitude: 4.583, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date()))
        
    }
}
