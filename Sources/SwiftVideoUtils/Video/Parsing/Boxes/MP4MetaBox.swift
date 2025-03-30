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
    
    public var version: MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var children: [any MP4Box]
    
    public init(children: [any MP4Box]) throws {
        self.version = .isoMp4(0)
        self.flags = .init()
        self.children = children
    }
    
    required public init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        self.children = try await reader.readBoxes(parentType: Self.self)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        try await writer.write(children)
    }
    
    public var overestimatedContentByteSize: Int {
        4 + self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
}
