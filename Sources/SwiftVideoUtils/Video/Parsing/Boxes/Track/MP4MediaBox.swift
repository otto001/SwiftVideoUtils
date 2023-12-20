//
//  MP4MediaBox.swift
//
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation

public class MP4MediaBox: MP4ParsableBox {
    public static let typeName: MP4FourCC = "mdia"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4MediaHeaderBox.self, MP4HandlerReferenceBox.self, MP4MediaInformationBox.self]
    
    public var children: [any MP4Box]
    
    public var mediaHeaderBox: MP4MediaHeaderBox? { firstChild(ofType: MP4MediaHeaderBox.self) }
    public var mediaInformationBox: MP4MediaInformationBox? { firstChild(ofType: MP4MediaInformationBox.self) }
    
    public init(children: [any MP4Box]) throws {
        self.children = children
    }
    
    required public convenience init(reader: MP4SequentialReader) async throws {
        try self.init(children: try await reader.readBoxes(parentType: Self.self))
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
}
