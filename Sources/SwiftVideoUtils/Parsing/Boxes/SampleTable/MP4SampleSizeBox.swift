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
    public var sampleSize: [UInt32]
    
    public required init(reader: any MP4Reader) async throws {
        self.version = try await reader.readInteger()
        self.flags = try await .init(readFrom: reader)
        
        self.sampleUniformSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleCount = try await reader.readInteger(byteOrder: .bigEndian)

        self.sampleSize = []
        
        if reader.remainingCount > 0 {
            for _ in 0..<self.sampleCount {
                self.sampleSize.append(try await reader.readInteger(byteOrder: .bigEndian))
            }
        }
    }
    
    public func sampleSize<T>(for sample: MP4Index<T>) -> UInt32 {
        sampleSize.isEmpty ? sampleUniformSize : sampleSize[sample]
    }
}
