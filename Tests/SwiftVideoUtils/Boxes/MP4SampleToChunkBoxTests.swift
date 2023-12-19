//
//  MP4SampleToChunkBoxTests.swift
//  
//
//  Created by Matteo Ludwig on 19.11.23.
//

import XCTest
@testable import SwiftVideoUtils


final class MP4SampleToChunkBoxTests: XCTestCase {

    func testSamplePosition() throws {
        let box = MP4SampleToChunkBox(version: 0, flags: .init(), 
                                      entries: [.init(firstChunk: .init(index0: 0), sampleCount: 30, sampleDescriptionID: 0),
                                                .init(firstChunk: .init(index0: 5), sampleCount: 29, sampleDescriptionID: 0)])
        // 30 samples per chunk (first group)
        XCTAssertEqual(box.samplePosition(for: .init(index1: 1)), .init(chunk: .init(index1: 1), sampleOfChunkIndex: .init(index1: 1)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 2)), .init(chunk: .init(index1: 1), sampleOfChunkIndex: .init(index1: 2)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 29)), .init(chunk: .init(index1: 1), sampleOfChunkIndex: .init(index1: 29)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30)), .init(chunk: .init(index1: 1), sampleOfChunkIndex: .init(index1: 30)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 31)), .init(chunk: .init(index1: 2), sampleOfChunkIndex: .init(index1: 31 - 30*1)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30*5)), .init(chunk: .init(index1: 5), sampleOfChunkIndex: .init(index1: 30*5 - 30*4)))
        
        // 29 samples per chunk (second group)
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30*5 + 1)), .init(chunk: .init(index1: 6), sampleOfChunkIndex: .init(index1: 1)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30*5 + 2)), .init(chunk: .init(index1: 6), sampleOfChunkIndex: .init(index1: 2)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30*5 + 29)), .init(chunk: .init(index1: 6), sampleOfChunkIndex: .init(index1: 29)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30*5 + 30)), .init(chunk: .init(index1: 7), sampleOfChunkIndex: .init(index1: 1)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30*5 + 31)), .init(chunk: .init(index1: 7), sampleOfChunkIndex: .init(index1: 2)))
        XCTAssertEqual(box.samplePosition(for: .init(index1: 30*5 + 29*38)), .init(chunk: .init(index1: 43), sampleOfChunkIndex: .init(index1: 29*38 - 29*37)))
    }
}
