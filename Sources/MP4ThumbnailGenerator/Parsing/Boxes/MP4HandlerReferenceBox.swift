//
//  MP4HandlerReferenceBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4HandlerReferenceBox: MP4VersionedBox {
    public static let typeName: String = "hdlr"
    public static let fullyParsable: Bool = true
    
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
        self.flags = try await .init(readFrom: reader)
        
        self.componentType = try await reader.readString(byteCount: 4, encoding: .ascii)!
        self.componentSubtype = try await reader.readString(byteCount: 4, encoding: .ascii)!
        
        self.componentManufacturer = try await reader.readInteger(byteOrder: .bigEndian)
        self.componentFlags = try await reader.readInteger(byteOrder: .bigEndian)
        self.componentFlagsMask = try await reader.readInteger(byteOrder: .bigEndian)
        
        
        let componentNameLength: UInt8 = try await reader.readInteger()
        
        self.componentName = try await reader.readString(byteCount: Int(componentNameLength), encoding: .utf8)!
    }
}

