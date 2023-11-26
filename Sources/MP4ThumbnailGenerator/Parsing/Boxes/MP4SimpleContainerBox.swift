//
//  MP4SimpleContainerBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 17.11.23.
//

import Foundation


public class MP4SimpleContainerBox: MP4Box {
    public var typeName: String
    public var children: [any MP4Box]
    
    public init(typeName: String, children: [any MP4Box]) {
        self.typeName = typeName
        self.children = children
    }
    
    public convenience init?(typeName: String, reader: any MP4Reader) async throws {
        let children = try await MP4BoxParser(reader: reader).readBoxes()
        
        if children.isEmpty && reader.remainingCount >= 8 {
            return nil
        }
        
        self.init(typeName: typeName, children: children)
    }
}

