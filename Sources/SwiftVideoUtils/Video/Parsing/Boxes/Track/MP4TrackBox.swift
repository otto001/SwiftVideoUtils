//
//  MP4TrackBox.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


public class MP4TrackBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "trak"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4VideoMediaHeaderBox.self, MP4TrackHeaderBox.self, MP4MediaBox.self, MP4MetaBox.self]
    
    public var children: [any MP4Box]
    
    public var mediaBox: MP4MediaBox? { firstChild(ofType: MP4MediaBox.self) }
    public var trackHeaderBox: MP4TrackHeaderBox? { firstChild(ofType: MP4TrackHeaderBox.self) }
    
    public init(children: [any MP4Box]) throws {
        self.children = children
    }
    
    public required convenience init(contentReader reader: MP4SequentialReader) async throws {
        try self.init(children: try await reader.readBoxes(parentType: Self.self))
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
}
