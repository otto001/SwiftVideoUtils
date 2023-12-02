//
//  MP4SampleSizeBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4SampleSizeBox: MP4VersionedBox {
    public static let typeName: String = "stsz"
    public static let fullyParsable: Bool = true
    
    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var sampleUniformSize: UInt32
    public var sampleCount: UInt32
    public var sampleSizes: [UInt32]
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await reader.readBoxFlags()
        
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
    
    public func sampleSize<T>(for sample: MP4Index<T>) -> UInt32 {
        sampleSizes.isEmpty ? sampleUniformSize : sampleSizes[sample]
    }
}
