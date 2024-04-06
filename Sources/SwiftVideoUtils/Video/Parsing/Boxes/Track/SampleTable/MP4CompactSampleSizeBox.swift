//
//  MP4CompactSampleSizeBox.swift
//
//
//  Created by Matteo Ludwig on 21.12.23.
//

import Foundation


public class MP4CompactSampleSizeBox: MP4SampleSizeBox {
    public static let typeName: MP4FourCC = "stz2"

    public var readByteRange: Range<Int>?
    
    public var version:  MP4BoxVersion
    public var flags: MP4BoxFlags
    
    // 3 bytes reserved
    public var reserved: Data
    public var fieldSize: UInt8
    public var sampleSizes: [UInt16]
    
    public var sampleCount: UInt32 { UInt32(self.sampleSizes.count) }
    
    public init(version:  MP4BoxVersion, flags: MP4BoxFlags, fieldSize: UInt8, sampleSizes: [UInt16]) {
        self.version = version
        self.flags = flags
        self.reserved = Data(repeating: 0, count: 3)
        self.fieldSize = fieldSize
        self.sampleSizes = sampleSizes
    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
        self.reserved = try await reader.readData(count: 3)
        self.fieldSize = try await reader.read()
        
        let sampleCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleSizes = []
        
        switch self.fieldSize {
        case 4:
            for _ in 0..<(sampleCount+1)/2 {
                let pair = try await reader.readInteger(UInt8.self, byteOrder: .bigEndian)
                self.sampleSizes.append(UInt16(truncatingIfNeeded: (pair >> 4) & 0xf))
                self.sampleSizes.append(UInt16(truncatingIfNeeded: pair & 0xf))
            }
            if sampleCount % 2 == 1 {
                self.sampleSizes.removeLast()
            }
        case 8:
            for _ in 0..<sampleCount {
                self.sampleSizes.append(UInt16(try await reader.readInteger(UInt8.self, byteOrder: .bigEndian)))
            }
        case 16:
            for _ in 0..<sampleCount {
                self.sampleSizes.append(try await reader.readInteger(UInt16.self, byteOrder: .bigEndian))
            }
        default:
            throw MP4Error.failedToParseBox(description: "stz2.fieldSize must be 4, 8 or 16, but is \(self.fieldSize)")
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(self.reserved)
        try await writer.write(self.fieldSize, byteOrder: .bigEndian)
        try await writer.write(UInt32(self.sampleSizes.count), byteOrder: .bigEndian)
        
        // TODO: validate sampleCount
        
        switch self.fieldSize {
        case 4:
            if self.sampleSizes.count % 2 == 1 {
                self.sampleSizes.append(0)
            }
            for i in stride(from: 0, to: self.sampleSizes.count, by: 2) {
                let pair: UInt8 = UInt8(self.sampleSizes[i] << 4) + UInt8(self.sampleSizes[i+1])
                try await writer.write(pair, byteOrder: .bigEndian)
            }
        case 8:
            for sampleSize in sampleSizes {
                try await writer.write(UInt8(sampleSize), byteOrder: .bigEndian)
            }
        case 16:
            for sampleSize in sampleSizes {
                try await writer.write(UInt16(sampleSize), byteOrder: .bigEndian)
            }
        default:
            throw MP4Error.failedToParseBox(description: "stz2.fieldSize must be 4, 8 or 16, but is \(self.fieldSize)")
        }
    }
    
    public var overestimatedContentByteSize: Int {
        switch self.fieldSize {
        case 4:
            return 8 + (sampleSizes.count+1)/2
        case 8:
            return 8 + sampleSizes.count * 1
        case 16:
            return 8 + sampleSizes.count * 2
        default:
            return 0
        }
    }
    
    public func sampleSize(for sample: MP4Index<UInt32>) -> UInt32? {
        if self.sampleSizes.contains(index: sample) {
            return UInt32(self.sampleSizes[sample])
        }
        return nil
    }
}
