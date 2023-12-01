//
//  MP4WriteTests.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import XCTest
@testable import SwiftVideoUtils

final class MP4WriteTests: XCTestCase {

    func testiPhoneFHD() async throws {
        let originalData = try Data(contentsOf: urlForFileName("TestVideo_iPhone_FHD.MOV"))
        let asset = try await MP4Asset(reader: MP4BufferReader(data: originalData))
        
        var writer = MP4BufferWriter()
        
        for box in try await asset.boxes {
            try await writer.write(box)
            XCTAssertEqual(originalData[0..<writer.data.count], writer.data, "failed to re-encode box of type \(box.typeName)")
        }

//        for i in 0..<originalData.count {
//            if originalData[i] != writer.data[i] {
//                print(i)
//                print(Data(originalData[i-160..<i+50]).debugString(mode: .both))
//                print(Data(writer.data[i-160..<i+50]).debugString(mode: .both))
//                print()
//            }
//        }
//
        XCTAssertEqual(originalData, writer.data)
    }
}
