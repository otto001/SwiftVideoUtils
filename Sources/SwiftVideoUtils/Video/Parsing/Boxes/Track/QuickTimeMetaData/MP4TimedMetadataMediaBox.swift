//
//  MP4TimedMetadataMediaBox.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public class MP4TimedMetadataMediaBox: MP4VersionedBox {
    public static let typeName: String = "mebx"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4MetadataKeyTableBox.self]
    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var entryCount: UInt32
    
    public var children: [MP4Box]
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await reader.readBoxFlags()
        
        self.entryCount = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.children = try await reader.readBoxes(parentType: Self.self)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        try await writer.write(entryCount, byteOrder: .bigEndian)
        try await writer.write(children)
    }
}
