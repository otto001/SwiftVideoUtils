//
//  MP4SampleSizeBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation

public protocol MP4SampleSizeBox: MP4FullBox {
    var sampleCount: UInt32 { get }
    func sampleSize(for sample: MP4Index<UInt32>) -> UInt32?
}

public class MP4StandardSampleSizeBox: MP4SampleSizeBox {
    public static let typeName: MP4FourCC = "stsz"
    
    public var readByteRange: Range<Int>?

    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    public var sampleUniformSize: UInt32
    public var sampleCount: UInt32
    public var sampleSizes: [UInt32]
    
    
    public init(version:  MP4BoxVersion, flags: MP4BoxFlags, sampleUniformSize: UInt32, sampleCount: UInt32, sampleSizes: [UInt32]) {
        self.version = version
        self.flags = flags
        self.sampleUniformSize = sampleUniformSize
        self.sampleCount = sampleCount
        self.sampleSizes = sampleSizes
    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
        self.sampleUniformSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleCount = try await reader.readInteger(byteOrder: .bigEndian)

        self.sampleSizes = []
        
        if reader.remainingCount > 0 {
            for _ in 0..<self.sampleCount {
                self.sampleSizes.append(try await reader.readInteger(byteOrder: .bigEndian))
            }
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(sampleUniformSize), byteOrder: .bigEndian)
        try await writer.write(UInt32(sampleCount), byteOrder: .bigEndian)
        
        // TODO: validate sampleCount
        
        for sampleSize in sampleSizes {
            try await writer.write(sampleSize, byteOrder: .bigEndian)
        }
    }
    
    public var overestimatedContentByteSize: Int {
        12 + sampleSizes.count * 4
    }
    
    public func sampleSize(for sample: MP4Index<UInt32>) -> UInt32? {
        if self.sampleSizes.isEmpty {
            return self.sampleUniformSize
        } else if self.sampleSizes.contains(index: sample) {
            return self.sampleSizes[sample]
        }
        return nil
    }
}
