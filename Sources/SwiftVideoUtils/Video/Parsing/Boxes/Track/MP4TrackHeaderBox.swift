//
//  MP4TrackHeaderBox.swift
//
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation


public class MP4TrackHeaderBox: MP4VersionedBox {
    public static let typeName: MP4FourCC = "tkhd"

    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var creationTime: Date
    public var modificationTime: Date
    
    public var trackID: UInt32
    
    /// 4 byte reserved data
    public var reserved1: UInt32
    
    public var duration: UInt64
    
    /// 8 byte reserved data
    public var reserved2: UInt64
    
    public var layer: UInt16
    public var alternateGroup: UInt16
    
    public var volume: UInt16
    
    /// 2 byte reserved data
    public var reserved3: UInt16
    
    public var displayMatrix: MP4TransformationMatrix
    
    public var trackWidth: Double
    public var trackHeight: Double

    required public init(reader: MP4SequentialReader) async throws {
        let version: UInt8 = try await reader.read()
        self.version = version
        self.flags = try await reader.read()
        
        if version == 0 {
            self.creationTime = try await reader.readDate(UInt32.self)
            self.modificationTime = try await reader.readDate(UInt32.self)
            
            self.trackID = try await reader.readInteger(byteOrder: .bigEndian)
            
            self.reserved1 = try await reader.readInteger(byteOrder: .bigEndian)
            
            self.duration = UInt64(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian))
        } else if version == 1 {
            self.creationTime = try await reader.readDate(UInt64.self)
            self.modificationTime = try await reader.readDate(UInt64.self)
            
            self.trackID = try await reader.readInteger(byteOrder: .bigEndian)
            
            self.reserved1 = try await reader.readInteger(byteOrder: .bigEndian)
            
            self.duration = try await reader.readInteger(UInt64.self, byteOrder: .bigEndian)
        } else {
            throw MP4Error.failedToParseBox(description: "tkhd box version \(version) not supported")
        }
       
        
        self.reserved2 = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.layer = try await reader.readInteger(byteOrder: .bigEndian)
        self.alternateGroup = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.volume = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.reserved3 = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.displayMatrix = try await .init(reader: reader)
        
        self.trackWidth = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.trackHeight = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        if self.version == 0 {
            try await writer.write(creationTime, UInt32.self, byteOrder: .bigEndian)
            try await writer.write(modificationTime, UInt32.self, byteOrder: .bigEndian)

            try await writer.write(trackID, byteOrder: .bigEndian)
            
            try await writer.write(reserved1, byteOrder: .bigEndian)
            
            try await writer.write(UInt32(duration), byteOrder: .bigEndian)
        } else if self.version == 1 {
            try await writer.write(creationTime, UInt64.self, byteOrder: .bigEndian)
            try await writer.write(modificationTime, UInt64.self, byteOrder: .bigEndian)

            try await writer.write(trackID, byteOrder: .bigEndian)
            
            try await writer.write(reserved1, byteOrder: .bigEndian)
            
            try await writer.write(duration, byteOrder: .bigEndian)
        } else {
            throw MP4Error.failedToParseBox(description: "tkhd box version \(version) not supported")
        }
       
        try await writer.write(reserved2, byteOrder: .bigEndian)
        
        try await writer.write(layer, byteOrder: .bigEndian)
        try await writer.write(alternateGroup, byteOrder: .bigEndian)
        
        try await writer.write(volume, byteOrder: .bigEndian)
        
        try await writer.write(reserved3, byteOrder: .bigEndian)
        
        try await writer.write(displayMatrix)
        
        try await writer.write(fixedPoint: trackWidth, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: trackHeight, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
    }
}
