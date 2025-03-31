//
//  MP4SampleDepedencyFlags.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//

/// Check 8.6.4.3 for Semantics
public struct MP4SampleDepedencyFlags {
    public var rawValue: UInt32

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    // bit(4) reserved=0;
    public var reserved: UInt32 {
        get { (rawValue >> 28) & 0xF }
        set { rawValue = (rawValue & ~(0xF << 28)) | ((newValue & 0xF) << 28) }
    }

    // unsigned int(2) is_leading;
    public var isLeading: UInt32 {
        get { (rawValue >> 26) & 0x3 }
        set { rawValue = (rawValue & ~(0x3 << 26)) | ((newValue & 0x3) << 26) }
    }

    // unsigned int(2) sample_depends_on;
    public var sampleDependsOn: UInt32 {
        get { (rawValue >> 24) & 0x3 }
        set { rawValue = (rawValue & ~(0x3 << 24)) | ((newValue & 0x3) << 24) }
    }

    // unsigned int(2) sample_is_depended_on;
    public var sampleIsDependedOn: UInt32 {
        get { (rawValue >> 22) & 0x3 }
        set { rawValue = (rawValue & ~(0x3 << 22)) | ((newValue & 0x3) << 22) }
    }

    // unsigned int(2) sample_has_redundancy;
    public var sampleHasRedundancy: UInt32 {
        get { (rawValue >> 20) & 0x3 }
        set { rawValue = (rawValue & ~(0x3 << 20)) | ((newValue & 0x3) << 20) }
    }

    // bit(3) sample_padding_value;
    public var samplePaddingValue: UInt32 {
        get { (rawValue >> 17) & 0x7 }
        set { rawValue = (rawValue & ~(0x7 << 17)) | ((newValue & 0x7) << 17) }
    }

    // bit(1) sample_is_non_sync_sample;
    public var sampleIsNonSyncSampleFlag: Bool {
        get { ((rawValue >> 16) & 0x1) != 0 }
        set { rawValue = (rawValue & ~(0x1 << 16)) | ((newValue ? 1 : 0) << 16) }
    }

    // unsigned int(16) sample_degradation_priority;
    public var sampleDegradationPriority: UInt32 {
        get { rawValue & 0xFFFF }
        set { rawValue = (rawValue & ~0xFFFF) | (newValue & 0xFFFF) }
    }
}

extension MP4SampleDepedencyFlags: RawRepresentable {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

extension MP4SampleDepedencyFlags: MP4Readable {
    public init(readingFrom reader: MP4SequentialReader) async throws {
        self.rawValue = try await reader.readInteger(byteOrder: .bigEndian)
    }
}

extension MP4SampleDepedencyFlags: MP4Writeable {
    public func write(to writer: any MP4Writer) async throws {
        try await writer.write(rawValue, byteOrder: .bigEndian)
    }
    
    public var overestimatedByteSize: Int {
        4
    }
}
