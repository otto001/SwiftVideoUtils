//
//  MP4MovieFragmentBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//


public class MP4MovieFragmentBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "moof"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4MovieFragmentHeaderBox.self, MP4TrackFragmentBox.self, MP4MetaBox.self]
    
    public var readByteRange: Range<Int>?
    
    public var children: [any MP4Box]
    
    public var trackFragments: [MP4TrackFragmentBox] { children(ofType: MP4TrackFragmentBox.self) }

    public var moovieFragmentHeaderBox: MP4MovieFragmentHeaderBox? { firstChild(ofType: MP4MovieFragmentHeaderBox.self) }
    
    public init(children: [any MP4Box]) throws {
        self.children = children
    }
    
    public required convenience init(contentReader reader: MP4SequentialReader) async throws {
        try self.init(children: try await reader.readBoxes(parentType: Self.self))
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
    
    public var overestimatedContentByteSize: Int {
        self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
}
