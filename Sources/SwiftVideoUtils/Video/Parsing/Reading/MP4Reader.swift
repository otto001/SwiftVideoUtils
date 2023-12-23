//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation


public protocol MP4Reader: AnyObject {
    var totalSize: Int { get }
    var context: MP4IOContext { get }

    func prepareToRead(byteRange: Range<Int>) async throws
    func isPreparedToRead(byteRange: Range<Int>) async throws -> Bool
    
    func readData(byteRange: Range<Int>) async throws -> Data
    
    func readInteger<T: FixedWidthInteger>(startingAt: Int, _ type: T.Type, byteOrder: ByteOrder) async throws -> T
    
    func readFixedPoint<T: FixedWidthInteger & UnsignedInteger>(startingAt: Int, underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws -> Double
}


public extension MP4Reader {
    func readInteger<T: FixedWidthInteger>(startingAt: Int, _ type: T.Type, byteOrder: ByteOrder) async throws  -> T {
        switch byteOrder {
        case .native:
            guard startingAt + MemoryLayout<T>.size <= totalSize else {
                throw MP4Error.tooFewBytes
            }
            return try await self.readData(byteRange: startingAt..<startingAt+MemoryLayout<T>.size).withUnsafeBytes { rawBuffer in
                rawBuffer.loadUnaligned(as: T.self)
            }
        case .littleEndian:
            return try await T(littleEndian: self.readInteger(startingAt: startingAt, T.self, byteOrder: .native))
        case .bigEndian:
            return try await T(bigEndian: self.readInteger(startingAt: startingAt, T.self, byteOrder: .native))
        }
    }
    
    func readFixedPoint<T: FixedWidthInteger & UnsignedInteger>(startingAt: Int, underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws -> Double {
        let underlyingInteger: T = try await self.readInteger(startingAt: startingAt, T.self, byteOrder: byteOrder)
        return Double(fixedPoint: underlyingInteger, fractionBits: fractionBits)
    }
}
