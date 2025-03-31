//
//  MP4MetaBox.swift
//
//
//  Created by Matteo Ludwig on 20.12.23.
//

import Foundation

public class MP4MetaBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "meta"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4HandlerReferenceBox.self, MP4MetadataItemKeysBox.self, MP4MetadataItemListBox.self]
    
    public var readByteRange: Range<Int>?
    
    public var writeVersionAndFlags: Bool
    
    public var children: [any MP4Box]
    
    required public init(contentReader reader: MP4SequentialReader) async throws {
        if reader.remainingCount >= 4 {
            let firstByte: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            let hasVersionAndFlags: Bool = firstByte == 0
            self.writeVersionAndFlags = hasVersionAndFlags
            if !hasVersionAndFlags {
                reader.offset -= 4
            }
            self.children = try await reader.readBoxes(parentType: Self.self)
        } else {
            writeVersionAndFlags = false
            self.children = []
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        
        if self.writeVersionAndFlags {
            try await writer.write(UInt32(0), byteOrder: .bigEndian)
        }
        try await writer.write(children)
    }
    
    public var overestimatedContentByteSize: Int {
        4 + self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
}
