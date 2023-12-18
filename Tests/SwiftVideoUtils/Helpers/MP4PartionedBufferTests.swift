//
//  MP4PartionedBufferTests.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import XCTest

@testable import SwiftVideoUtils

final class MP4PartionedBufferTests: XCTestCase {

    func testInsertRetrieve() throws {
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
    
    func testContains() {
        var buffer = MP4PartionedBuffer()
        
        buffer.insert(data: Data(repeating: 0, count: 1_000), at: 0)
        buffer.insert(data: Data(repeating: 0, count: 1_000), at: 2_000)
        buffer.insert(data: Data(repeating: 0, count: 500), at: 3_000)
        
        XCTAssertTrue(buffer.contains(range: 0..<10))
        XCTAssertTrue(buffer.contains(range: 100..<200))
        XCTAssertTrue(buffer.contains(range: 0..<1_000))
        XCTAssertTrue(buffer.contains(range: 2_000..<2_001))
        XCTAssertTrue(buffer.contains(range: 2_000..<3_000))
        XCTAssertTrue(buffer.contains(range: 2_000..<3_500))
        
        XCTAssertFalse(buffer.contains(range: 1_000..<1_001))
        XCTAssertFalse(buffer.contains(range: 1_999..<2_000))
        XCTAssertFalse(buffer.contains(range: 1_999..<2_001))
        XCTAssertFalse(buffer.contains(range: 0..<3_500))
        XCTAssertFalse(buffer.contains(range: 2_000..<3_501))
        XCTAssertFalse(buffer.contains(range: 1_000..<3_501))
        XCTAssertFalse(buffer.contains(range: 3500..<3_501))
    }
    
    

}
