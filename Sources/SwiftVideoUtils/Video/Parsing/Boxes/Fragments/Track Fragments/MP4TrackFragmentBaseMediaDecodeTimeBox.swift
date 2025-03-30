//
//  MP4TrackFragmentBaseMediaDecodeTimeBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//

public class MP4TrackFragmentBaseMediaDecodeTimeBox: MP4FullBox {
    public static var typeName: MP4FourCC = "tfdt"

    public var readByteRange: Range<Int>?

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var baseMediaDecodeTime: UInt64
    
    required public init(contentReader reader: MP4SequentialReader) async throws {
        let version: MP4BoxVersion = try await reader.read()
        self.version = version
        self.flags = try await reader.read()
        if version == .isoMp4(1) {
            self.baseMediaDecodeTime = try await reader.readInteger(UInt64.self, byteOrder: .bigEndian)
        } else {
            self.baseMediaDecodeTime = UInt64(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian))
        }
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        if version == .isoMp4(1) {
            try await writer.write(baseMediaDecodeTime, byteOrder: .bigEndian)
        } else {
            try await writer.write(UInt32(baseMediaDecodeTime), byteOrder: .bigEndian)
        }
    }
    
    public var overestimatedContentByteSize: Int {
        4 + 8
    }
}