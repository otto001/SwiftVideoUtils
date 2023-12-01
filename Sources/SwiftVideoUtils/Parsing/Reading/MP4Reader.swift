//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation


public protocol MP4Reader: AnyObject {
    var offset: Int { get set }
    var remainingCount: Int { get }
    
    func prepareToRead(count readCount: Int) async throws
    func bytesAreAvaliable(count readCount: Int) async throws -> Bool
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type) async throws -> T
    
    func readData(count readCount: Int) async throws -> Data
    
    func readFixedPoint<T: FixedWidthInteger & UnsignedInteger>(underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws -> Double
}

// MARK: Integers
public extension MP4Reader {
    
    func prepareToRead(count readCount: Int) async throws {
        
    }
    
    func bytesAreAvaliable(count readCount: Int) async throws -> Bool {
        return true
    }
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type) async throws -> T {
        let data = try await self.readData(count: MemoryLayout<T>.size)
        return data.withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(as: T.self)
        }
    }
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type, byteOrder: ByteOrder = .bigEndian) async throws  -> T {
        assert(MemoryLayout<T>.size <= remainingCount)
        switch byteOrder {
        case .native:
            return try await self.readInteger(T.self)
        case .littleEndian:
            return try await T(littleEndian: self.readInteger(T.self))
        case .bigEndian:
            return try await T(bigEndian: self.readInteger(T.self))
        }
    }
    
    func readInteger<T: FixedWidthInteger>() async throws  -> T {
        try await self.readInteger(T.self)
    }
    
    func readInteger<T: FixedWidthInteger>(byteOrder: ByteOrder) async throws -> T {
        try await self.readInteger(T.self, byteOrder: byteOrder)
    }
}

// MARK: Fixed Point
public extension MP4Reader {
    func readFixedPoint<T: FixedWidthInteger & UnsignedInteger>(underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws -> Double {
        let underlyingInteger: T = try await self.readInteger(byteOrder: byteOrder)
        return Double(fixedPoint: underlyingInteger, fractionBits: fractionBits)
    }
}

// MARK: Date
public extension MP4Reader {
    func readDate<T: FixedWidthInteger>(_ type: T.Type, referenceDate: Date = .mp4ReferenceDate) async throws -> Date {
        Date(timeInterval: TimeInterval(try await readInteger(T.self, byteOrder: .bigEndian)),
             since: referenceDate)
    }
}

// MARK: Flags
public extension MP4Reader {
    func readBoxFlags() async throws -> MP4BoxFlags {
        return try await .init(readFrom: self)
    }
}

// MARK: Data & String
public extension MP4Reader {
    
    func readAllData() async throws -> Data {
        try await self.readData(count: self.remainingCount)
    }
    
    func readData(byteRange: Range<Int>) async throws -> Data {
        let currentOffset = offset
        offset = byteRange.lowerBound
        defer { offset = currentOffset }
        return try await self.readData(count: byteRange.count)
    }
    
    func readString(byteCount: Int, encoding: String.Encoding, dropLengthPrefix: Bool = false) async throws -> String? {
        var byteCount = byteCount
        if dropLengthPrefix {
            try await self.prepareToRead(count: byteCount)
            let length: Int8 = try await self.readInteger()
            if length == byteCount {
                byteCount -= 1
            } else {
                self.offset -= 1
            }
        }
        
        if byteCount == 0 {
            return ""
        }
        
        return try await String(data: self.readData(count: byteCount), encoding: encoding)
    }
    
    func readAscii(byteCount: Int, dropLengthPrefix: Bool = false) async throws -> String {
        try await self.readString(byteCount: byteCount, encoding: .ascii, dropLengthPrefix: dropLengthPrefix)!
    }
}


public extension MP4Reader {
    

    func printBytes(count printCount: Int? = nil, mode: DataDebugFormatMode = .ascii, grouping: Int = 4) async throws  {
        let startOffset = self.offset
        let printCount = min(printCount ?? self.remainingCount, self.remainingCount)
        let data = try await self.readData(count: printCount)
        self.offset = startOffset
        print(data.debugString(mode: mode, grouping: grouping))
    }
}
