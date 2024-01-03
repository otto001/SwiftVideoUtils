//
//  MP4SyncSampleBoxTests.swift
//  
//
//  Created by Matteo Ludwig on 17.12.23.
//

import XCTest
@testable import SwiftVideoUtils

final class MP4SyncSampleBoxTests: XCTestCase {

    func testSyncSampleBeforeSample() throws {
        let box = MP4SyncSampleBox(version: .isoMp4(0), flags: .init(), syncSamples: [0, 10, 20, 100].map {.init(index0: $0)})
        
        XCTAssertEqual(box.syncSample(before: .init(index0: 0)), .init(index0: 0))
        XCTAssertEqual(box.syncSample(before: .init(index0: 9)), .init(index0: 0))
        XCTAssertEqual(box.syncSample(before: .init(index0: 10)), .init(index0: 10))
        XCTAssertEqual(box.syncSample(before: .init(index0: 19)), .init(index0: 10))
        XCTAssertEqual(box.syncSample(before: .init(index0: 20)), .init(index0: 20))
        XCTAssertEqual(box.syncSample(before: .init(index0: 29)), .init(index0: 20))
        XCTAssertEqual(box.syncSample(before: .init(index0: 99)), .init(index0: 20))
        XCTAssertEqual(box.syncSample(before: .init(index0: 100)), .init(index0: 100))
        XCTAssertEqual(box.syncSample(before: .init(index0: 1000)), .init(index0: 100))
    }
}
