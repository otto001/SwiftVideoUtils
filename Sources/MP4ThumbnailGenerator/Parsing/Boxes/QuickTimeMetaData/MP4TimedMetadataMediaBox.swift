//
//  MP4TimedMetadataMediaBox.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public class MP4TimedMetadataMediaBox: MP4ParsableBox {
    public static let typeName: String = "mebx"
    
    public var children: [MP4Box]
    
    public required init(reader: any MP4Reader) async throws {
        // TODO: I dont know what these 4 byte do
        reader.offset += 4
        
        // We dont need an entryCount, so just skip reading it
        reader.offset += 4
        //let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.children = try await MP4BoxParser(reader: reader).readBoxes()
    }
}
