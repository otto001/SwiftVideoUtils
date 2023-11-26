//
//  any MP4Reader.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation

public class MP4BufferReader: MP4Reader {
    private let data: Data?
    
    private let _buffer: UnsafeRawBufferPointer
    public var offset: Int
    public var buffer: UnsafeRawBufferPointer {
        UnsafeRawBufferPointer(start: _buffer.baseAddress!.advanced(by: offset), count: _buffer.count - offset)
    }
    public var remainingCount: Int {
        _buffer.count - offset
    }
    
    init(buffer: UnsafeRawBufferPointer) {
        self.data = nil
        self._buffer = buffer
        self.offset = 0
    }
    
    convenience init(buffer: UnsafeRawBufferPointer, count: Int) {
        assert(buffer.count >= count)
        self.init(buffer: .init(start: buffer.baseAddress!, count: count))
    }
    
    init(data: Data) {
        self.data = data
        self._buffer = self.data!.withUnsafeBytes { buffer in
            return buffer
        }
        self.offset = 0
    }
    
    
    public func readInteger<T>(_ type: T.Type) -> T where T : FixedWidthInteger {
        assert(MemoryLayout<T>.size <= remainingCount)
        
        defer { offset += MemoryLayout<T>.size }
        return _buffer.loadUnaligned(fromByteOffset: offset, as: T.self)
    }
    
    
    public func readData(count readCount: Int) -> Data {
        assert(readCount <= self.remainingCount)
        defer { self.offset += readCount }

        return Data(buffer: UnsafeRawBufferPointer(start: self._buffer.baseAddress!.advanced(by: self.offset), count: readCount).assumingMemoryBound(to: UInt8.self))
    }
}
