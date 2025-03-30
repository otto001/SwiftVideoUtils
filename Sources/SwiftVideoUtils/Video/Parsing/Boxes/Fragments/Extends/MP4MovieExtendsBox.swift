//
//  MP4MovieExtendsBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//


public class MP4MovieExtendsBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "mvex"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4MovieExtendsHeaderBox.self]
    
    public var readByteRange: Range<Int>?
    
    public var children: [any MP4Box]

    public var moovieExtendsHeaderBox: MP4MovieExtendsHeaderBox? {
        firstChild(ofType: MP4MovieExtendsHeaderBox.self)
    }
    
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
