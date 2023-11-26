//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation


class MP4SubrangeReader: MP4Reader {
    let wrappedReader: any MP4Reader
    let additionalOffset: Int
    let limit: Int
    
    var offset: Int
    
    var remainingCount: Int {
        limit - offset
    }

    init(wrappedReader: any MP4Reader, limit: Int) {
        assert(limit <= wrappedReader.remainingCount)
        
        var underlyingReader = wrappedReader
        var additionalOffset = wrappedReader.offset
        
        if let subrangeReader = wrappedReader as? MP4SubrangeReader {
            underlyingReader = subrangeReader.wrappedReader
            additionalOffset += subrangeReader.additionalOffset
        }
        
        self.wrappedReader = underlyingReader
        self.additionalOffset = additionalOffset
        self.limit = limit
        self.offset = 0
    }
    
    func readInteger<T>(_ type: T.Type) async throws -> T where T : FixedWidthInteger {
        let prevOffset = wrappedReader.offset
        defer {
            offset = wrappedReader.offset - additionalOffset
            wrappedReader.offset = prevOffset
        }
        wrappedReader.offset = offset + additionalOffset
        
        return try await wrappedReader.readInteger()
    }
    
    func readData(count readCount: Int) async throws -> Data {
        let prevOffset = wrappedReader.offset
        defer {
            offset = wrappedReader.offset - additionalOffset
            wrappedReader.offset = prevOffset
        }
        wrappedReader.offset = offset + additionalOffset
        
        return try await wrappedReader.readData(count: readCount)
    }
}
