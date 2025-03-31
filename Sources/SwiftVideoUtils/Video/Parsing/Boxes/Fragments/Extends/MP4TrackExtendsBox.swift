//
//  MP4TrackExtendsBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//


public class MP4TrackExtendsBox: MP4FullBox {
    public static var typeName: MP4FourCC = "trex"

    public var readByteRange: Range<Int>?

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags

    public var trackID: UInt32
    
    public var defaultSampleDescriptionIndex: UInt32
    public var defaultSampleDuration: UInt32
    public var defaultSampleSize: UInt32
    public var defaultSampleFlags: MP4SampleDepedencyFlags

    
    required public init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()

        self.trackID = try await reader.readInteger(byteOrder: .bigEndian)
        self.defaultSampleDescriptionIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.defaultSampleDuration = try await reader.readInteger(byteOrder: .bigEndian)
        self.defaultSampleSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.defaultSampleFlags = try await reader.read()
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        try await writer.write(trackID, byteOrder: .bigEndian)
        try await writer.write(defaultSampleDescriptionIndex, byteOrder: .bigEndian)
        try await writer.write(defaultSampleDuration, byteOrder: .bigEndian)
        try await writer.write(defaultSampleSize, byteOrder: .bigEndian)
        try await writer.write(defaultSampleFlags)
    }
    
    public var overestimatedContentByteSize: Int {
        4 + 5*4
    }
}


