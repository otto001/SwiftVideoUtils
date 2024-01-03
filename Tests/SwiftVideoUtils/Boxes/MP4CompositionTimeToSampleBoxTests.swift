//
//  MP4CompositionTimeToSampleBoxTests.swift
//
//
//  Created by Matteo Ludwig on 19.12.23.
//

import XCTest
@testable import SwiftVideoUtils


final class MP4CompositionTimeToSampleBoxTests: XCTestCase {
    func exampleBox() -> MP4CompositionTimeToSampleBox {
        .init(version: .isoMp4(0), flags: .init(), entries: [.init(sampleCount: 10, offset: 10),
                                                    .init(sampleCount: 1, offset: -10),
                                                    .init(sampleCount: 3, offset: 12),
                                                    .init(sampleCount: 7, offset: 9),
                                                    .init(sampleCount: 10, offset: 10)])
    }
    
    func testOffsetsForSamples() throws {
        let box = exampleBox()
        XCTAssertEqual(box.offsets(for: MP4Index(index0: 0)..<MP4Index(index0: 1)), [10])
        XCTAssertEqual(box.offsets(for: MP4Index(index0: 0)..<MP4Index(index0: 2)), [10, 10])
        XCTAssertEqual(box.offsets(for: MP4Index(index0: 0)..<MP4Index(index0: 10)), [10, 10, 10, 10, 10, 10, 10, 10, 10, 10])
        XCTAssertEqual(box.offsets(for: MP4Index(index0: 0)..<MP4Index(index0: 11)), [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, -10])
        XCTAssertEqual(box.offsets(for: MP4Index(index0: 0)..<MP4Index(index0: 15)), [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, -10, 12, 12, 12, 9])
        XCTAssertEqual(box.offsets(for: MP4Index(index0: 9)..<MP4Index(index0: 15)), [10, -10, 12, 12, 12, 9])
    }
    
}
