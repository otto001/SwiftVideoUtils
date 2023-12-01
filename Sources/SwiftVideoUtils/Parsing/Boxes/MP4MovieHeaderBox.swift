//
//  MP4MovieHeaderBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


private let referenceDate: Date = {
    //DateComponents(calendar: .init(identifier: .gregorian), year: 1904, month: 1, day: 1, hour: 0, minute: 0, second: 0).date!.timeIntervalSince1970).date!
    return Date(timeIntervalSince1970: -2082848400.0)
}()


public class MP4MovieHeaderBox: MP4VersionedBox {
    public static let typeName: String = "mvhd"


    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var creationTime: Date
    public var modificationTime: Date
    
    public var timescale: UInt32
    public var duration: UInt32
    
    public var rate: Double
    public var volume: Double
    
    /// 10-bytes of reserved data
    public var reserved: Data
    
    public var matrix: MP4TransformationMatrix
    
    public var previewTime: UInt32
    public var previewDuration: UInt32
    
    public var posterTime: UInt32
    
    public var selectionTime: UInt32
    public var selectionDuration: UInt32
    
    public var currentTime: UInt32
    
    public var nextTrackID: UInt32
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await reader.readBoxFlags()
        
        self.creationTime = try await reader.readDate(UInt32.self)
        self.modificationTime = try await reader.readDate(UInt32.self)
        
        self.timescale = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        self.duration = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        
        self.rate = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.volume = try await reader.readFixedPoint(underlyingType: UInt16.self, fractionBits: 8, byteOrder: .bigEndian)
        
        self.reserved = try await reader.readData(count: 10)
        
        self.matrix = try await .init(reader: reader)
        
        self.previewTime = try await reader.readInteger(byteOrder: .bigEndian)
        self.previewDuration = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.posterTime = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.selectionTime = try await reader.readInteger(byteOrder: .bigEndian)
        self.selectionDuration = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.currentTime = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.nextTrackID = try await reader.readInteger(byteOrder: .bigEndian)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(creationTime, UInt32.self, byteOrder: .bigEndian)
        try await writer.write(modificationTime, UInt32.self, byteOrder: .bigEndian)

        try await writer.write(timescale, byteOrder: .bigEndian)
        try await writer.write(duration, byteOrder: .bigEndian)
        
        try await writer.write(fixedPoint: rate, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: volume, UInt16.self, fractionBits: 8, byteOrder: .bigEndian)
        
        try await writer.write(reserved)
        
        try await writer.write(matrix)
        
        try await writer.write(previewTime, byteOrder: .bigEndian)
        try await writer.write(previewDuration, byteOrder: .bigEndian)
        
        try await writer.write(posterTime, byteOrder: .bigEndian)
        
        try await writer.write(selectionTime, byteOrder: .bigEndian)
        try await writer.write(selectionDuration, byteOrder: .bigEndian)
        
        try await writer.write(currentTime, byteOrder: .bigEndian)
        
        try await writer.write(nextTrackID, byteOrder: .bigEndian)
    }
    
    public var durationSeconds: TimeInterval {
        TimeInterval(duration)/TimeInterval(timescale)
    }
}
