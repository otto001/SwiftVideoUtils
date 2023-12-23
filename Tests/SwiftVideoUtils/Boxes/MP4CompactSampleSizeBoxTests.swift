//
//  MP4CompactSampleSizeBoxTests.swift
//  
//
//  Created by Matteo Ludwig on 22.12.23.
//

import XCTest
@testable import SwiftVideoUtils




final class MP4CompactSampleSizeBoxTests: XCTestCase {

    
    func test16BitReadWrite() async throws {
        let box = MP4CompactSampleSizeBox(version: 0, flags: .init(), fieldSize: 16, sampleSizes: [0, UInt16(UInt8.max), UInt16.max-1, UInt16.max])
        
        try await AssertBoxReadWriteStability(box: box)
        let reReadBox = try await WriteReadBox(box: box)
        
        XCTAssertEqual(reReadBox.fieldSize, 16)
        XCTAssertEqual(reReadBox.sampleSize(for: .init(index0: 0)), 0)
        XCTAssertEqual(reReadBox.sampleSize(for: .init(index0: 1)), UInt32(UInt8.max))
        XCTAssertEqual(reReadBox.sampleSize(for: .init(index0: 2)), UInt32(UInt16.max-1))
        XCTAssertEqual(reReadBox.sampleSize(for: .init(index0: 3)), UInt32(UInt16.max))
    }
    
    func test8BitReadWrite() async throws {
        let box = MP4CompactSampleSizeBox(version: 0, flags: .init(), fieldSize: 8, sampleSizes: [0, UInt16(UInt8.max)])
        
        try await AssertBoxReadWriteStability(box: box)
        let reReadBox = try await WriteReadBox(box: box)
        
        XCTAssertEqual(reReadBox.fieldSize, 8)
        XCTAssertEqual(reReadBox.sampleSize(for: .init(index0: 0)), 0)
        XCTAssertEqual(reReadBox.sampleSize(for: .init(index0: 1)), UInt32(UInt16(UInt8.max)))
    }
    
    func test4BitReadWrite() async throws {
        let boxEvenSamples = MP4CompactSampleSizeBox(version: 0, flags: .init(), fieldSize: 4, sampleSizes: [0, 13, 14, 15])
        
        try await AssertBoxReadWriteStability(box: boxEvenSamples)
        let reReadBoxEven = try await WriteReadBox(box: boxEvenSamples)
        
        XCTAssertEqual(reReadBoxEven.fieldSize, 4)
        XCTAssertEqual(reReadBoxEven.sampleSize(for: .init(index0: 0)), 0)
        XCTAssertEqual(reReadBoxEven.sampleSize(for: .init(index0: 1)), 13)
        XCTAssertEqual(reReadBoxEven.sampleSize(for: .init(index0: 2)), 14)
        XCTAssertEqual(reReadBoxEven.sampleSize(for: .init(index0: 3)), 15)
        
        let boxOddSamples = MP4CompactSampleSizeBox(version: 0, flags: .init(), fieldSize: 4, sampleSizes: [0, 14, 15])
        
        try await AssertBoxReadWriteStability(box: boxOddSamples)
        let reReadBoxOdd = try await WriteReadBox(box: boxOddSamples)
        
        XCTAssertEqual(reReadBoxOdd.fieldSize, 4)
        XCTAssertEqual(reReadBoxOdd.sampleSize(for: .init(index0: 0)), 0)
        XCTAssertEqual(reReadBoxOdd.sampleSize(for: .init(index0: 1)), 14)
        XCTAssertEqual(reReadBoxOdd.sampleSize(for: .init(index0: 2)), 15)
    }
}
