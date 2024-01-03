//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation


public protocol MP4Reader: AnyObject {
    var totalSize: Int { get }
    var context: MP4IOContext { set get }

    func prepareToRead(byteRange: Range<Int>) async throws
    func isPreparedToRead(byteRange: Range<Int>) async throws -> Bool
    
    func readData(byteRange: Range<Int>) async throws -> Data
    
    func readInteger<T: FixedWidthInteger>(startingAt: Int, _ type: T.Type, byteOrder: ByteOrder) async throws -> T
    
    func readSignedFixedPoint<T: FixedWidthInteger & SignedInteger>(startingAt: Int, fractionBits: UInt8, byteOrder: ByteOrder) async throws -> FixedPointNumber<T>
    
    func readUnsignedFixedPoint<T: FixedWidthInteger & UnsignedInteger>(startingAt: Int, fractionBits: UInt8, byteOrder: ByteOrder) async throws -> FixedPointNumber<T>
}


public extension MP4Reader {
    func readInteger<T: FixedWidthInteger>(startingAt: Int, _ type: T.Type, byteOrder: ByteOrder) async throws  -> T {
        guard startingAt + MemoryLayout<T>.size <= totalSize else {
            throw MP4Error.tooFewBytes
        }
        return try await self.readData(byteRange: startingAt..<startingAt+MemoryLayout<T>.size).asFixedInteger(byteOrder: byteOrder)
    }
    
    func readSignedFixedPoint<T: FixedWidthInteger & SignedInteger>(startingAt: Int, fractionBits: UInt8, byteOrder: ByteOrder) async throws -> FixedPointNumber<T> {
        let underlyingInteger: T = try await self.readInteger(startingAt: startingAt, T.self, byteOrder: byteOrder)
        return .init(underlyingInteger, fractionBits: fractionBits)
    }
    
    func readUnsignedFixedPoint<T: FixedWidthInteger & UnsignedInteger>(startingAt: Int, fractionBits: UInt8, byteOrder: ByteOrder) async throws -> FixedPointNumber<T> {
        let underlyingInteger: T = try await self.readInteger(startingAt: startingAt, T.self, byteOrder: byteOrder)
        return .init(underlyingInteger, fractionBits: fractionBits)
    }
}
