//
//  MP4TrackBox.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


public class MP4TrackBox: MP4ParsableBox {
    public static let typeName: String = "trak"

    
    public var children: [any MP4Box]
    
    public var mediaBox: MP4MediaBox? { firstChild(ofType: MP4MediaBox.self) }
    
    
    public init(children: [any MP4Box]) throws {
        self.children = children
    }
    
    required public convenience init(reader: any MP4Reader) async throws {
        try self.init(children: try await MP4BoxParser(reader: reader).readBoxes())
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(children)
    }
}
