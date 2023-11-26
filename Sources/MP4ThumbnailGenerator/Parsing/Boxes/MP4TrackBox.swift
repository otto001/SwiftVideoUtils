//
//  MP4TrackBox.swift
//
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


public class MP4TrackBox: MP4ParsableBox {
    public static let typeName: String = "trak"
    public static let fullyParsable: Bool = true
    
    public var children: [any MP4Box]
    
    public var sampleTableBox: MP4SampleTableBox
    
    public init(children: [any MP4Box]) throws {
        self.children = children
        
        guard let stblBox = children.first(where: {$0.typeName == "mdia" })?.firstChild(path:  "minf.stbl") as? MP4SampleTableBox else {
            throw MP4Error.failedToFindBox(path:  "mdia.minf.stbl")
        }
        
        self.sampleTableBox = stblBox
    }
    
    required public convenience init(reader: any MP4Reader) async throws {
        let children = try await MP4BoxParser(reader: reader).readBoxes()
        
        try self.init(children: children)
    }
}
