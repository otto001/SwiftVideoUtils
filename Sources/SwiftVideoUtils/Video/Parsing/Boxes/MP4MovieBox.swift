//
//  MP4MovieBox.swift
//  
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


public class MP4MovieBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "moov"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4MovieHeaderBox.self, MP4TrackBox.self, MP4MetaBox.self]
    
    public var children: [any MP4Box]
    
    public var tracks: [MP4TrackBox] { children(ofType: MP4TrackBox.self) }
    public var videoTrack: MP4TrackBox? {
        tracks.first {
            $0.firstChild(path: "mdia.minf.vmhd") != nil
        }
    }

    public var moovieHeaderBox: MP4MovieHeaderBox? { firstChild(ofType: MP4MovieHeaderBox.self) }
    
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
