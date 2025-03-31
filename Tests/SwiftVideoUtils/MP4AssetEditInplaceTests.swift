//
//  MP4AssetEditInplaceTests.swift
//  
//
//  Created by Matteo Ludwig on 06.04.24.
//

import XCTest
@testable import SwiftVideoUtils

final class MP4AssetEditInplaceTests: XCTestCase {

    func testOverwriteCreationTimeInplace() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD_Inplace.MOV")))
        let testTime = Date()
        try await asset.overwriteCreationTimeInplace(creationTime: testTime, modificationTime: testTime)
        
        let asset2 = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD_Inplace.MOV")))
        let moovBox = try await asset2.moovBox
        XCTAssertEqual(moovBox.movieHeaderBox?.creationTime.timeIntervalSince1970 ?? 0, testTime.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(moovBox.movieHeaderBox?.modificationTime.timeIntervalSince1970 ?? 0, testTime.timeIntervalSince1970, accuracy: 1)
    }


}
