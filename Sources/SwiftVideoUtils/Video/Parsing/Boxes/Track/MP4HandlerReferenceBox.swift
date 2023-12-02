//
//  MP4HandlerReferenceBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4HandlerReferenceBox: MP4VersionedBox {
    public static let typeName: String = "hdlr"

    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var componentType: String = ""
    public var componentSubtype: String = ""
    
    public var componentManufacturer: UInt32
    public var componentFlags: UInt32
    public var componentFlagsMask: UInt32
    
    public var componentName: String = ""
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await reader.readBoxFlags()
        
        self.componentType = try await reader.readAscii(byteCount: 4)
        self.componentSubtype = try await reader.readAscii(byteCount: 4)
        
        self.componentManufacturer = try await reader.readInteger(byteOrder: .bigEndian)
        self.componentFlags = try await reader.readInteger(byteOrder: .bigEndian)
        self.componentFlagsMask = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.componentName = try await reader.readAscii(byteCount: reader.remainingCount)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(componentType, encoding: .ascii, length: 4)
        try await writer.write(componentSubtype, encoding: .ascii, length: 4)
        
        try await writer.write(componentManufacturer, byteOrder: .bigEndian)
        try await writer.write(componentFlags, byteOrder: .bigEndian)
        try await writer.write(componentFlagsMask, byteOrder: .bigEndian)
        
        try await writer.write(componentName, encoding: .ascii)
    }
}

