//
//  MP4TrackFragmentHeaderBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//

public class MP4TrackFragmentHeaderBox: MP4FullBox {
    public static var typeName: MP4FourCC = "tfhd"

    public var readByteRange: Range<Int>?

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags

    public struct FlagInterpretation: OptionSet {
        public let rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let baseDataOffsetPresent: Self = .init(rawValue: 0x000001)
        public static let sampleDescriptionIndexPresent: Self = .init(rawValue: 0x000002)
        public static let defaultSampleDurationPresent: Self = .init(rawValue: 0x000008)
        public static let defaultSampleSizePresent: Self = .init(rawValue: 0x000010)
        public static let defaultSampleFlagsPresent: Self = .init(rawValue: 0x000020)
        public static let durationIsEmpty: Self = .init(rawValue: 0x010000)
        public static let defaultBaseIsMoof: Self = .init(rawValue: 0x020000)
    }
    
    public var trackID: UInt32
    
    public var baseDataOffset: UInt64?
    public var sampleDescriptionIndex: UInt32?
    public var defaultSampleDuration: UInt32?
    public var defaultSampleSize: UInt32?
    public var defaultSampleFlags: MP4SampleDepedencyFlags?
    
    required public init(contentReader reader: MP4SequentialReader) async throws {
        let version: MP4BoxVersion = try await reader.read()
        let flags: MP4BoxFlags = try await reader.read()
        self.version = version
        self.flags = flags
        
        let flagInterpretation = FlagInterpretation(rawValue: flags.combined)

        self.trackID = try await reader.readInteger(byteOrder: .bigEndian)
        
        if flagInterpretation.contains(.baseDataOffsetPresent) {
            self.baseDataOffset = try await reader.readInteger(UInt64.self, byteOrder: .bigEndian)
        }
        if flagInterpretation.contains(.sampleDescriptionIndexPresent) {
            self.sampleDescriptionIndex = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        }
        if flagInterpretation.contains(.defaultSampleDurationPresent) {
            self.defaultSampleDuration = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        }
        if flagInterpretation.contains(.defaultSampleSizePresent) {
            self.defaultSampleSize = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
        }
        if flagInterpretation.contains(.defaultSampleFlagsPresent) {
            self.defaultSampleFlags = try await reader.read()
        }
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags) // TODO: check that flags match presence of optional fields
        try await writer.write(trackID, byteOrder: .bigEndian)

        if let baseDataOffset = baseDataOffset {
            try await writer.write(baseDataOffset, byteOrder: .bigEndian)
        }
        if let sampleDescriptionIndex = sampleDescriptionIndex {
            try await writer.write(sampleDescriptionIndex, byteOrder: .bigEndian)
        }
        if let defaultSampleDuration = defaultSampleDuration {
            try await writer.write(defaultSampleDuration, byteOrder: .bigEndian)
        }
        if let defaultSampleSize = defaultSampleSize {
            try await writer.write(defaultSampleSize, byteOrder: .bigEndian)
        }
        if let defaultSampleFlags = defaultSampleFlags {
            try await writer.write(defaultSampleFlags)
        }
    }
    
    public var overestimatedContentByteSize: Int {
        4 + 7*4
    }
}
