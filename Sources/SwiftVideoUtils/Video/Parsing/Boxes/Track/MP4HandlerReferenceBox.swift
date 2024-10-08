//
//  MP4HandlerReferenceBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4HandlerReferenceBox: MP4FullBox {
    public static let typeName: MP4FourCC = "hdlr"
    
    public var readByteRange: Range<Int>?

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var componentType: String = ""
    public var componentSubtype: String = ""
    
    public var componentManufacturer: UInt32
    public var componentFlags: UInt32
    public var componentFlagsMask: UInt32
    
    public var componentName: String = ""
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
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
    
    public var overestimatedContentByteSize: Int {
        24 + componentName.utf8.count + 10
    }
}

