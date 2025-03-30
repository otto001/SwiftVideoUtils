//
//  MP4MovieFragmentHeaderBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//

public class MP4MovieFragmentHeaderBox: MP4FullBox {
    public static var typeName: MP4FourCC = "mfhd"

    public var readByteRange: Range<Int>?

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var sequenceNumber: UInt32
    
    required public init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        self.sequenceNumber = try await reader.readInteger(byteOrder: .bigEndian)
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        try await writer.write(sequenceNumber, byteOrder: .bigEndian)
    }
    
    public var overestimatedContentByteSize: Int {
        4 + 4
    }
}
