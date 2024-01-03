//
//  MP4SampleTableBoxTests.swift
//
//
//  Created by Matteo Ludwig on 19.12.23.
//

import XCTest
@testable import SwiftVideoUtils


final class MP4SampleTableBoxTests: XCTestCase {

    
    func exampleBox() -> MP4SampleTableBox {
        let sampleCount = 11
        let chunkOffsetBox = MP4ChunkOffset64Box(version: .isoMp4(0), flags: .init(), chunkOffsets: [100, 300, 400])
        let sampleSizeBox = MP4StandardSampleSizeBox(version: .isoMp4(0), flags: .init(), sampleUniformSize: 0, sampleCount: UInt32(sampleCount), sampleSizes: [
        60, 40, 50, 50,
        25, 25, 25,
        40, 10, 25, 25,
        ])
        let sampleToChunkBox = MP4SampleToChunkBox(version: .isoMp4(0), flags: .init(), entries: [.init(firstChunk: .init(index0: 0), sampleCount: 4, sampleDescriptionID: 0),
                                                                                         .init(firstChunk: .init(index0: 1), sampleCount: 3, sampleDescriptionID: 0),
                                                                                         .init(firstChunk: .init(index0: 2), sampleCount: 4, sampleDescriptionID: 0)])
        let timeToSampleBox = MP4TimeToSampleBox(version: .isoMp4(0), flags: .init(), entries: [.init(sampleCount: 3, sampleDuration: 10),
                                                                                       .init(sampleCount: 3, sampleDuration: 9),
                                                                                       .init(sampleCount: 5, sampleDuration: 12)])
        let compositionTimeToSampleBox = MP4CompositionTimeToSampleBox(version: .isoMp4(0), flags: .init(), entries: [.init(sampleCount: 5, offset: 0),
                                                                                                             .init(sampleCount: 3, offset: -4),
                                                                                                             .init(sampleCount: 3, offset: 2)])
        let sampleTableBox = MP4SampleTableBox(children: [sampleSizeBox, sampleToChunkBox, chunkOffsetBox, timeToSampleBox, compositionTimeToSampleBox])
        return sampleTableBox
    }
    
    func testByteRanges() throws {
        let box = exampleBox()
       
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 0)..<MP4Index(index0: 1)), [100..<160])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 0)..<MP4Index(index0: 2)), [100..<160, 160..<200])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 0)..<MP4Index(index0: 3)), [100..<160, 160..<200, 200..<250])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 0)..<MP4Index(index0: 4)), [100..<160, 160..<200, 200..<250, 250..<300])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 1)..<MP4Index(index0: 4)), [160..<200, 200..<250, 250..<300])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 2)..<MP4Index(index0: 4)), [200..<250, 250..<300])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 3)..<MP4Index(index0: 4)), [250..<300])
        
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 4)..<MP4Index(index0: 5)), [300..<325])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 4)..<MP4Index(index0: 6)), [300..<325, 325..<350])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 4)..<MP4Index(index0: 7)), [300..<325, 325..<350, 350..<375])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 5)..<MP4Index(index0: 7)), [325..<350, 350..<375])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 6)..<MP4Index(index0: 7)), [350..<375])
        
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 7)..<MP4Index(index0: 8)), [400..<440])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 7)..<MP4Index(index0: 9)), [400..<440, 440..<450])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 7)..<MP4Index(index0: 10)), [400..<440, 440..<450, 450..<475])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 7)..<MP4Index(index0: 11)), [400..<440, 440..<450, 450..<475, 475..<500])
        
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 0)..<MP4Index(index0: 6)), [100..<160, 160..<200, 200..<250, 250..<300, 300..<325, 325..<350])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 5)..<MP4Index(index0: 9)), [325..<350, 350..<375, 400..<440, 440..<450])
        XCTAssertEqual(try box.byteRanges(for: MP4Index(index0: 0)..<MP4Index(index0: 11)), [100..<160, 160..<200, 200..<250, 250..<300,
                                                                                             300..<325, 325..<350, 350..<375,
                                                                                             400..<440, 440..<450, 450..<475, 475..<500])
    }

    func testTimingInfo() throws {
        let box = exampleBox()
        
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 0)..<MP4Index(index0: 1)), [.init(duration: 10, decodeTime: 0, displayTime: 0)])
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 0)..<MP4Index(index0: 2)), [
            .init(duration: 10, decodeTime: 0, displayTime: 0),
            .init(duration: 10, decodeTime: 10, displayTime: 10)
        ])
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 0)..<MP4Index(index0: 4)), [
            .init(duration: 10, decodeTime: 0, displayTime: 0),
            .init(duration: 10, decodeTime: 10, displayTime: 10),
            .init(duration: 10, decodeTime: 20, displayTime: 20),
            .init(duration: 9, decodeTime: 30, displayTime: 30),
        ])
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 0)..<MP4Index(index0: 5)), [
            .init(duration: 10, decodeTime: 0, displayTime: 0),
            .init(duration: 10, decodeTime: 10, displayTime: 10),
            .init(duration: 10, decodeTime: 20, displayTime: 20),
            .init(duration: 9, decodeTime: 30, displayTime: 30),
            .init(duration: 9, decodeTime: 39, displayTime: 39),
        ])
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 0)..<MP4Index(index0: 6)), [
            .init(duration: 10, decodeTime: 0, displayTime: 0),
            .init(duration: 10, decodeTime: 10, displayTime: 10),
            .init(duration: 10, decodeTime: 20, displayTime: 20),
            .init(duration: 9, decodeTime: 30, displayTime: 30),
            .init(duration: 9, decodeTime: 39, displayTime: 39),
            .init(duration: 9, decodeTime: 48, displayTime: 44),
        ])
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 0)..<MP4Index(index0: 11)), [
            .init(duration: 10, decodeTime: 0, displayTime: 0),
            .init(duration: 10, decodeTime: 10, displayTime: 10),
            .init(duration: 10, decodeTime: 20, displayTime: 20),
            .init(duration: 9, decodeTime: 30, displayTime: 30),
            .init(duration: 9, decodeTime: 39, displayTime: 39),
            .init(duration: 9, decodeTime: 48, displayTime: 44),
            .init(duration: 12, decodeTime: 57, displayTime: 53),
            .init(duration: 12, decodeTime: 69, displayTime: 65),
            .init(duration: 12, decodeTime: 81, displayTime: 83),
            .init(duration: 12, decodeTime: 93, displayTime: 95),
            .init(duration: 12, decodeTime: 105, displayTime: 107),
        ])
        
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 2)..<MP4Index(index0: 6)), [
            .init(duration: 10, decodeTime: 20, displayTime: 20),
            .init(duration: 9, decodeTime: 30, displayTime: 30),
            .init(duration: 9, decodeTime: 39, displayTime: 39),
            .init(duration: 9, decodeTime: 48, displayTime: 44),
        ])
        
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 3)..<MP4Index(index0: 6)), [
            .init(duration: 9, decodeTime: 30, displayTime: 30),
            .init(duration: 9, decodeTime: 39, displayTime: 39),
            .init(duration: 9, decodeTime: 48, displayTime: 44),
        ])
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 4)..<MP4Index(index0: 7)), [
            .init(duration: 9, decodeTime: 39, displayTime: 39),
            .init(duration: 9, decodeTime: 48, displayTime: 44),
            .init(duration: 12, decodeTime: 57, displayTime: 53),
        ])
        XCTAssertEqual(try box.timingInfo(for: MP4Index(index0: 5)..<MP4Index(index0: 10)), [
            .init(duration: 9, decodeTime: 48, displayTime: 44),
            .init(duration: 12, decodeTime: 57, displayTime: 53),
            .init(duration: 12, decodeTime: 69, displayTime: 65),
            .init(duration: 12, decodeTime: 81, displayTime: 83),
            .init(duration: 12, decodeTime: 93, displayTime: 95),
        ])
    }

}
