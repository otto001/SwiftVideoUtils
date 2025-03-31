//
//  MP4WriteTests.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import XCTest
@testable import SwiftVideoUtils

extension MP4Box {
    var selfAndChildren: [any MP4Box] {
        var result = children
        result.append(self)
        return result
    }
    
    
    func allChildrenRecursive() -> [any MP4Box] {
        var workingArray = selfAndChildren
        var result: [any MP4Box] = []
        
        while !workingArray.isEmpty {
            let box = workingArray.removeLast()
            result.append(box)
            workingArray.append(contentsOf: box.children)
        }
        
        return result
    }
}

final class MP4WriteTests: XCTestCase {

    func testiPhoneFHD() async throws {
        let originalData = try Data(contentsOf: urlForFileName("TestVideo_iPhone_FHD.MOV"))
        let asset = try await MP4Asset(reader: MP4BufferReader(data: originalData, context: .init(fileType: .quicktime)))
        
        let boxes = try await asset.readAllBoxes()
        for box in boxes {
            print(box.description)
        }
        
        let allBoxes: [any MP4Box] = boxes.flatMap { $0.allChildrenRecursive() }
        
        for box in allBoxes.reversed() {
            let boxWriter = MP4BufferWriter()
            try await box.write(to: boxWriter)
            
            XCTAssertGreaterThanOrEqual(box.overestimatedByteSize, boxWriter.count)
        }
        
        let writer = MP4BufferWriter(context: .init(fileType: .quicktime))
        var lastOffset = 0
        for box in boxes {
            try await writer.write(box)
            XCTAssertEqual(originalData[lastOffset..<writer.buffer.count], writer.buffer[lastOffset..<writer.buffer.count], "failed to re-encode box of type \(box.typeName)")
            if originalData[lastOffset..<writer.buffer.count] != writer.buffer[lastOffset..<writer.buffer.count] {
                for i in lastOffset..<writer.buffer.count {
                    if originalData[i] != writer.buffer[i] {
                        print(Data(originalData[max(0, i-100)..<min(i+100, writer.buffer.count-1)]).debugString(mode: .both))
                        print()
                        print(Data(writer.buffer[max(0, i-100)..<min(i+100, writer.buffer.count-1)]).debugString(mode: .both))
                        
                        print()
                        print()
                    }
                }
            }
            lastOffset = writer.buffer.count
        }
        XCTAssertEqual(originalData, writer.buffer)
    }
}
