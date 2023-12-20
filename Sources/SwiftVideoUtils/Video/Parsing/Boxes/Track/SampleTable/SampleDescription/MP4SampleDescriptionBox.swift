//
//  MP4SampleDescriptionBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


// TODO: implement stz2


public class MP4SampleDescriptionBox: MP4ParsableBox {
    public static let typeName: MP4FourCC = "stsd"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4Avc1Box.self, MP4Hvc1Box.self, MP4ColorParameterBox.self, MP4TimedMetadataMediaBox.self]
    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var children: [MP4Box]
    
    public required init(reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
        
        //let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        reader.offset += MemoryLayout<UInt32>.size
        
        self.children = try await reader.readBoxes(parentType: Self.self)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(children.count), byteOrder: .bigEndian)
        try await writer.write(children)
    }
}
