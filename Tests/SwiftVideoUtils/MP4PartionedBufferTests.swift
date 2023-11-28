//
//  MP4PartionedBufferTests.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import XCTest

@testable import SwiftVideoUtils

final class MP4PartionedBufferTests: XCTestCase {

    func testPartionedBuffer() throws {
        let data = try Data(contentsOf: urlForFileName("TestVideo_iPhone_FHD.MOV"))
        
        var buffer = MP4PartionedBuffer()
        
        buffer.insert(data: Data(data[0..<10_000]), at: 0)
        buffer.insert(data: Data(data[20_000..<30_000]), at: 20_000)
        
        XCTAssertEqual(buffer[0..<10_000], data[0..<10_000])
        XCTAssertEqual(buffer[20_000..<30_000], data[20_000..<30_000])
        
        XCTAssertEqual(buffer[0..<5_000], data[0..<5_000])
        XCTAssertEqual(buffer[1_000..<8_000], data[1_000..<8_000])
        XCTAssertEqual(buffer[22_000..<28_000], data[22_000..<28_000])
        
        
        buffer.insert(data: Data(data[30_000..<32_000]), at: 30_000)
        XCTAssertEqual(buffer[30_000..<32_000], data[30_000..<32_000])
        XCTAssertEqual(buffer[20_000..<32_000], data[20_000..<32_000])
        XCTAssertEqual(buffer[20_000..<32_000], data[20_000..<32_000])
        
        
        buffer.insert(data: Data(data[30_000..<33_000]), at: 30_000)
        XCTAssertEqual(buffer[32_000..<33_000], data[32_000..<33_000])
        XCTAssertEqual(buffer[30_000..<33_000], data[30_000..<33_000])
        XCTAssertEqual(buffer[20_000..<33_000], data[20_000..<33_000])
        
        
        buffer.insert(data: Data(data[30_000..<32_000]), at: 30_000)
        XCTAssertEqual(buffer[20_000..<33_000], data[20_000..<33_000])
        
        
        buffer.insert(data: Data(data[18_000..<20_000]), at: 18_000)
        XCTAssertEqual(buffer[18_000..<20_000], data[18_000..<20_000])
        XCTAssertEqual(buffer[18_000..<33_000], data[18_000..<33_000])
        
        buffer.insert(data: Data(data[10_000..<20_000]), at: 10_000)
        XCTAssertEqual(buffer[10_000..<20_000], data[10_000..<20_000])
        XCTAssertEqual(buffer[00_000..<33_000], data[00_000..<33_000])
    }

}
