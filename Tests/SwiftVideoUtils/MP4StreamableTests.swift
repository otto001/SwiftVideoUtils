//
//  MP4StreamableTests.swift
//  
//
//  Created by Matteo Ludwig on 18.12.23.
//

import XCTest
@testable import SwiftVideoUtils

final class MP4StreamableTests: XCTestCase {

    func testiPhoneFHD() async throws {
        let originalData = try Data(contentsOf: urlForFileName("TestVideo_iPhone_FHD.MOV"))
        let asset = try await MP4Asset(reader: MP4BufferReader(data: originalData))
        let isStreamable = try await asset.isStreamable
        XCTAssertEqual(isStreamable, false)
        
        let result = try await asset.makeStreamable()
        XCTAssertEqual(result, true)
        let isStreamable2 = try await asset.isStreamable
        XCTAssertEqual(isStreamable2, true)
        
    }

}
