//
//  MP4PagingReaderTests.swift
//  
//
//  Created by Matteo Ludwig on 25.12.23.
//

import XCTest
@testable import SwiftVideoUtils


final class MP4PagingReaderTests: XCTestCase {

    func testPagingReader() async throws {
        let url = urlForFileName("TestVideo_iPhone_FHD.MOV")
        
        var readCount: Int = 0
        let testData = try Data(contentsOf: url)
        let blockReader = MP4BlockReader(totalSize: testData.count, context: .init(fileType: .quicktime)) { range in
            readCount += 1
            return Data(testData[range])
        }
        let reader = MP4PagingReader(reader: blockReader,
                                    maxPagesInMemory: 8, pageSize: 1024)
        
        var readData: Data = .init()
        XCTAssertEqual(reader.currentMemoryUsage, 0)
        XCTAssertEqual(reader.pagesInMemory, 0)
        XCTAssertEqual(readCount, 0)
        
        readData = try await reader.readData(byteRange: 0..<1000)
        XCTAssertEqual(readData, testData[0..<1000])
        XCTAssertEqual(reader.currentMemoryUsage, 1024)
        XCTAssertEqual(reader.pagesInMemory, 1)
        XCTAssertEqual(readCount, 1)
        
        readData = try await reader.readData(byteRange: 0..<1024)
        XCTAssertEqual(readData, testData[0..<1024])
        XCTAssertEqual(reader.currentMemoryUsage, 1024)
        XCTAssertEqual(reader.pagesInMemory, 1)
        XCTAssertEqual(readCount, 1)
        
        readData = try await reader.readData(byteRange: 0..<8192)
        XCTAssertEqual(readData, testData[0..<8192])
        XCTAssertEqual(reader.currentMemoryUsage, 8192)
        XCTAssertEqual(reader.pagesInMemory, 8)
        XCTAssertEqual(readCount, 8)
        
        readData = try await reader.readData(byteRange: 1024..<8193)
        XCTAssertEqual(readData, testData[1024..<8193])
        XCTAssertEqual(reader.currentMemoryUsage, 8192)
        XCTAssertEqual(reader.pagesInMemory, 8)
        XCTAssertEqual(readCount, 9)
        
        readData = try await reader.readData(byteRange: 0..<8193)
        XCTAssertEqual(readData, testData[0..<8193])
        XCTAssertEqual(reader.currentMemoryUsage, 8192)
        XCTAssertEqual(reader.pagesInMemory, 8)
        XCTAssertEqual(readCount, 10)
        
        readData = try await reader.readData(byteRange: 1024..<8193)
        XCTAssertEqual(readData, testData[1024..<8193])
        XCTAssertEqual(reader.currentMemoryUsage, 8192)
        XCTAssertEqual(reader.pagesInMemory, 8)
        XCTAssertEqual(readCount, 10)
    }
}
