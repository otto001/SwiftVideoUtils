//
//  MP4MediaInformationBox.swift
//
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation

public class MP4MediaInformationBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "minf"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4VideoMediaHeaderBox.self, MP4SoundMediaHeaderBox.self,
                                                               MP4SampleTableBox.self, MP4HandlerReferenceBox.self]
    
    public var children: [any MP4Box]
    
    public var sampleTableBox: MP4SampleTableBox? { firstChild(ofType: MP4SampleTableBox.self) }
    
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
