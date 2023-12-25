//
//  MP4BlockReader.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public class MP4BlockReader: MP4Reader {
    public let totalSize: Int

    private let closure: (_ range: Range<Int>) async throws -> Data
    
    public var context: MP4IOContext
    
    public init(totalSize: Int, context: MP4IOContext = .init(), closure: @escaping (_: Range<Int>) async throws -> Data) {
        self.totalSize = totalSize
        self.context = context
        self.closure = closure
    }
    
    public func prepareToRead(byteRange: Range<Int>) async throws {
        if byteRange.upperBound > self.totalSize {
            throw MP4Error.tooFewBytes
        }
    }
    
    public func isPreparedToRead(byteRange: Range<Int>) -> Bool {
        return false
    }
    
    public func readData(byteRange: Range<Int>) async throws -> Data {
        try await prepareToRead(byteRange: byteRange)
        return try await self.closure(byteRange)
    }
}
