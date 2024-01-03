//
//  MP4TimeToSampleBoxTests.swift
//
//
//  Created by Matteo Ludwig on 15.12.23.
//

import XCTest
@testable import SwiftVideoUtils

final class MP4TimeToSampleBoxTests: XCTestCase {
    
    func exampleBox() -> MP4TimeToSampleBox {
        MP4TimeToSampleBox(version: .isoMp4(0), flags: .init(), entries: [.init(sampleCount: 10, sampleDuration: 10),
                                                                 .init(sampleCount: 1, sampleDuration: 11),
                                                                 .init(sampleCount: 3, sampleDuration: 12),
                                                                 .init(sampleCount: 7, sampleDuration: 9),
                                                                 .init(sampleCount: 10, sampleDuration: 10)])
    }
    
    func testTotalSampleCount() throws {
        let box = exampleBox()
        XCTAssertEqual(box.totalSampleCount(), 31)
    }
    
    func testTotalSampleDuration() throws {
        let box = exampleBox()
        XCTAssertEqual(box.totalSampleDuration(), 310)
    }
    
    func testAverageSampleDuration() throws {
        let box = exampleBox()
        XCTAssertEqual(box.averageSampleDuration(), 10)
    }
    
    func testTimeForSample() throws {
        let box = exampleBox()
        XCTAssertEqual(box.time(for: .init(index0: 0)), 0..<10)
        XCTAssertEqual(box.time(for: .init(index0: 1)), 10..<20)
        XCTAssertEqual(box.time(for: .init(index0: 9)), 90..<100)
        XCTAssertEqual(box.time(for: .init(index0: 10)), 100..<111)
        XCTAssertEqual(box.time(for: .init(index0: 11)), 111..<123)
        XCTAssertEqual(box.time(for: .init(index0: 30)), 300..<310)
        XCTAssertEqual(box.time(for: .init(index0: 31)), nil)
    }
    
    func testTimeForSamples() throws {
        let box = exampleBox()
        XCTAssertEqual(box.times(for: MP4Index(index0: 7)..<MP4Index(index0: 14)), [70..<80, 80..<90, 90..<100,
                                                                                    100..<111, 111..<123, 123..<135, 135..<147])
        
        XCTAssertEqual(box.times(for: MP4Index(index0: 0)..<MP4Index(index0: 1)), [0..<10])
        XCTAssertEqual(box.times(for: MP4Index(index0: 0)..<MP4Index(index0: 2)), [0..<10, 10..<20])
        XCTAssertEqual(box.times(for: MP4Index(index0: 0)..<MP4Index(index0: 11)), [0..<10, 10..<20, 20..<30, 30..<40, 40..<50,
                                                                                    50..<60, 60..<70, 70..<80, 80..<90, 90..<100,
                                                                                    100..<111])
        
        XCTAssertEqual(box.times(for: MP4Index(index0: 10)..<MP4Index(index0: 14)), [100..<111, 111..<123, 123..<135, 135..<147])
        
        XCTAssertEqual(box.times(for: MP4Index(index0: 7)..<MP4Index(index0: 14)), [70..<80, 80..<90, 90..<100,
                                                                                    100..<111, 111..<123, 123..<135, 135..<147])
        
        XCTAssertEqual(box.times(for: MP4Index(index0: 0)..<MP4Index(index0: 14)), [0..<10, 10..<20, 20..<30, 30..<40, 40..<50,
                                                                                    50..<60, 60..<70, 70..<80, 80..<90, 90..<100,
                                                                                    100..<111, 111..<123, 123..<135, 135..<147])
    }
    
    func testSampleAtTime() throws {
        let box = exampleBox()
        XCTAssertEqual(box.sample(at: 0), .init(index0: 0))
        XCTAssertEqual(box.sample(at: 9), .init(index0: 0))
        XCTAssertEqual(box.sample(at: 10), .init(index0: 1))
        XCTAssertEqual(box.sample(at: 11), .init(index0: 1))
        XCTAssertEqual(box.sample(at: 19), .init(index0: 1))
        XCTAssertEqual(box.sample(at: 20), .init(index0: 2))
        XCTAssertEqual(box.sample(at: 99), .init(index0: 9))
        XCTAssertEqual(box.sample(at: 100), .init(index0: 10))
        XCTAssertEqual(box.sample(at: 110), .init(index0: 10))
        XCTAssertEqual(box.sample(at: 111), .init(index0: 11))
        XCTAssertEqual(box.sample(at: 112), .init(index0: 11))
        XCTAssertEqual(box.sample(at: 122), .init(index0: 11))
        XCTAssertEqual(box.sample(at: 123), .init(index0: 12))
        XCTAssertEqual(box.sample(at: 124), .init(index0: 12))
    }
}
