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
    public static let fullyParsable: Bool = true

    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var creationTime: Date
    public var modificationTime: Date
    public var timescale: UInt32
    public var duration: TimeInterval
    public var nextTrackId: UInt32
    public var rate: Int32
    public var volume: Int16
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await .init(readFrom: reader)
        
        let creationTime = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        let modificationTime = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        let timescale = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        
        
        self.creationTime = Date(timeInterval: TimeInterval(creationTime), since: referenceDate)
        self.modificationTime = Date(timeInterval: TimeInterval(modificationTime), since: referenceDate)
        self.timescale = timescale
        
        self.duration = TimeInterval(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian))/TimeInterval(timescale)
        self.nextTrackId = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.rate = try await reader.readInteger(byteOrder: .littleEndian)
        self.volume = try await reader.readInteger(byteOrder: .littleEndian)
    }
}
