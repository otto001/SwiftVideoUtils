//
//  Utils.swift
//
//
//  Created by Matteo Ludwig on 22.12.23.
//

import XCTest
import SwiftVideoUtils

func WriteReadBox<Box: MP4ConcreteBox>(box: Box, file: StaticString = #filePath, line: UInt = #line) async throws -> Box {
    let writer1 = MP4BufferWriter(context: .init(fileType: .isoMp4))
    try await writer1.write(box)
    
    let reader = MP4SequentialReader(reader: MP4BufferReader(data: writer1.data, context: writer1.context))
    let reReadBox = try await reader.readBox(boxTypeMap: [Box.self])
    
    XCTAssertNotNil(reReadBox as? Box, file: file, line: line)
    
    return reReadBox as! Box
}

func AssertBoxReadWriteStability<Box: MP4ConcreteBox>(box: Box, file: StaticString = #filePath, line: UInt = #line) async throws {
    let writer1 = MP4BufferWriter(context: .init(fileType: .isoMp4))
    try await writer1.write(box)
    
    let reader = MP4SequentialReader(reader: MP4BufferReader(data: writer1.data, context: writer1.context))
    let reReadBox = try await reader.readBox(boxTypeMap: [Box.self])
    
    XCTAssertEqual(reReadBox.typeName, box.typeName, file: file, line: line)
    XCTAssertNotNil(reReadBox as? Box, file: file, line: line)
    
    let writer2 = MP4BufferWriter(context: writer1.context)
    try await writer2.write(reReadBox)
    
    XCTAssertEqual(writer1.data, writer2.data, file: file, line: line)
}
