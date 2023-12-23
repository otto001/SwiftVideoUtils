//
//  MP4SequentialReader.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation

public class MP4BufferReader: MP4Reader {
   
    public let data: Data
    public var totalSize: Int { data.count }
    
    public var context: MP4IOContext
    
    public init(data: Data, context: MP4IOContext = .init()) {
        self.data = data
        self.context = context
    }
    
    public func prepareToRead(byteRange: Range<Int>)  {
        
    }
    
    public func isPreparedToRead(byteRange: Range<Int>)  -> Bool {
        true
    }
    
    public func readData(byteRange: Range<Int>) async throws -> Data {
        if byteRange.upperBound > self.totalSize {
            throw MP4Error.tooFewBytes
        }
        return Data(data[byteRange])
    }
    
    public func readInteger<T>(startingAt: Int, _ type: T.Type, byteOrder: ByteOrder) async throws -> T where T : FixedWidthInteger {
        switch byteOrder {
        case .native:
            guard startingAt + MemoryLayout<T>.size <= totalSize else {
                throw MP4Error.tooFewBytes
            }
            return self.data[startingAt..<startingAt+MemoryLayout<T>.size].withUnsafeBytes { rawBuffer in
                rawBuffer.loadUnaligned(as: T.self)
            }
        case .littleEndian:
            return try await T(littleEndian: self.readInteger(startingAt: startingAt, T.self, byteOrder: .native))
        case .bigEndian:
            return try await T(bigEndian: self.readInteger(startingAt: startingAt, T.self, byteOrder: .native))
        }
    }
}
