//
//  any MP4Reader.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation

public class MP4BufferReader: MP4Reader {
    private let data: Data
    
    public var offset: Int = 0
    
    public var remainingCount: Int {
        data.count - offset
    }

    public init(data: Data) {
        self.data = data
    }
    
    public func readInteger<T>(_ type: T.Type) throws -> T where T : FixedWidthInteger {
        guard MemoryLayout<T>.size <= remainingCount else {
            throw MP4Error.tooFewBytes
        }
        
        defer { offset += MemoryLayout<T>.size }
        return self.data.withUnsafeBytes { buffer in
            return buffer.loadUnaligned(fromByteOffset: offset, as: T.self)
        }
    }
    
    
    public func readData(count readCount: Int) throws -> Data {
        guard readCount <= remainingCount else {
            throw MP4Error.tooFewBytes
        }
        defer { self.offset += readCount }

        return self.data.withUnsafeBytes { buffer in
            return Data(buffer: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: self.offset),
                                                       count: readCount).assumingMemoryBound(to: UInt8.self))
        }
    }
}
