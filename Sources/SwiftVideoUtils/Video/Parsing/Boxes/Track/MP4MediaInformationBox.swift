//
//  MP4MediaInformationBox.swift
//
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation

public class MP4MediaInformationBox: MP4ParsableBox {
    public static let typeName: String = "minf"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4SampleTableBox.self]
    
    public var children: [any MP4Box]
    
    public var sampleTableBox: MP4SampleTableBox? { firstChild(ofType: MP4SampleTableBox.self) }
    
    public init(children: [any MP4Box]) throws {
        self.children = children
    }
    
    required public convenience init(reader: any MP4Reader) async throws {
        try self.init(children: try await reader.readBoxes(parentType: Self.self))
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
}
