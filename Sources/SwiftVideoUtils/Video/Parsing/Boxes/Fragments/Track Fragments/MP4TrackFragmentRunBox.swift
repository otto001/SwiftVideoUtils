//
//  MP4TrackFragmentRunBox.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//



public class MP4TrackFragmentRunBox: MP4FullBox {
    public static var typeName: MP4FourCC = "trun"

    public var readByteRange: Range<Int>?

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public struct FlagInterpretation: OptionSet {
        public let rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let dataOffsetPresent: Self = .init(rawValue: 0x000001)
        public static let firstSampleFlagsPresent: Self = .init(rawValue: 0x000004)
        public static let sampleDurationPresent: Self = .init(rawValue: 0x000100)
        public static let sampleSizePresent: Self = .init(rawValue: 0x000200)
        public static let sampleFlagsPresent: Self = .init(rawValue: 0x000400)
        public static let sampleCompositionTimeOffsetPresent: Self = .init(rawValue: 0x000800)
    }
    
    public var sampleCount: UInt32
    
    public var dataOffset: Int32? = nil
    public var firstSampleFlags: MP4SampleDepedencyFlags? = nil
    
    public struct Sample {
        public var duration: UInt32?
        public var size: UInt32?
        public var flags: MP4SampleDepedencyFlags?
        public var compositionTimeOffset: Int32?
    }
    
    public var samples: [Sample] = []
    
    required public init(contentReader reader: MP4SequentialReader) async throws {
        let version: MP4BoxVersion = try await reader.read()
        let flags: MP4BoxFlags = try await reader.read()
        self.version = version
        self.flags = flags
        
        let flagInterpretation = FlagInterpretation(rawValue: flags.combined)
        
        let sampleCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleCount = sampleCount
        
        if flagInterpretation.contains(.dataOffsetPresent) {
            self.dataOffset = try await reader.readInteger(Int32.self, byteOrder: .bigEndian)
        }
        if flagInterpretation.contains(.firstSampleFlagsPresent) {
            self.firstSampleFlags = try await reader.read()
        }
        
        for _ in 0..<sampleCount {
            var sample: MP4TrackFragmentRunBox.Sample = Sample()
            if flagInterpretation.contains(.sampleDurationPresent) {
                sample.duration = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
            }
            if flagInterpretation.contains(.sampleSizePresent) {
                sample.size = try await reader.readInteger(UInt32.self, byteOrder: .bigEndian)
            }
            if flagInterpretation.contains(.sampleFlagsPresent) {
                sample.flags = try await reader.read()
            }
            if flagInterpretation.contains(.sampleCompositionTimeOffsetPresent) {
                if self.version == .isoMp4(0){
                    let offset: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
                    sample.compositionTimeOffset = Int32(offset)
                } else {
                    sample.compositionTimeOffset = try await reader.readInteger(byteOrder: .bigEndian)
                }
            }
            self.samples.append(sample)
        }
        
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        try await writer.write(sampleCount, byteOrder: .bigEndian)
        
        let flagInterpretation = FlagInterpretation(rawValue: flags.combined)
        
        if let dataOffset = self.dataOffset, flagInterpretation.contains(.dataOffsetPresent) {
            try await writer.write(dataOffset, byteOrder: .bigEndian)
        }
        if let firstSampleFlags = self.firstSampleFlags, flagInterpretation.contains(.firstSampleFlagsPresent) {
            try await writer.write(firstSampleFlags)
        }
        
        for sample in samples {
            if flagInterpretation.contains(.sampleDurationPresent) {
                try await writer.write(sample.duration ?? 0, byteOrder: .bigEndian)
            }
            if flagInterpretation.contains(.sampleSizePresent) {
                try await writer.write(sample.size ?? 0, byteOrder: .bigEndian)
            }
            if flagInterpretation.contains(.sampleFlagsPresent) {
                try await writer.write(sample.flags ?? .init(rawValue: 0))
            }
            if flagInterpretation.contains(.sampleCompositionTimeOffsetPresent) {
                if self.version == .isoMp4(0) {
                    try await writer.write(UInt32(sample.compositionTimeOffset ?? 0), byteOrder: .bigEndian)
                } else {
                    try await writer.write(sample.compositionTimeOffset ?? 0, byteOrder: .bigEndian)
                }
            }
        }
    }
    
    public var overestimatedContentByteSize: Int {
        4 + 12 + 4 * samples.count
    }
}
