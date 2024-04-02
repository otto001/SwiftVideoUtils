//
//  MP4TimedMetadataMediaBox.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public class MP4TimedMetadataMediaBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "mebx"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4MetadataKeyTableBox.self]
    
    /// 6-bytes of reserved data
    public var reserved1: Data
    public var dataReferenceIndex: UInt16
    
    public var children: [MP4Box]
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.reserved1 = try await reader.readData(count: 6)
        self.dataReferenceIndex = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.children = try await reader.readBoxes(parentType: Self.self)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(reserved1)
        try await writer.write(dataReferenceIndex, byteOrder: .bigEndian)
        
        try await writer.write(children)
    }
    
    public var overestimatedContentByteSize: Int {
        8 + self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
}
