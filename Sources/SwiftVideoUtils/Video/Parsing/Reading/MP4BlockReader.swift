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
    private var buffer: MP4PartionedBuffer = .init()
    
    public init(totalSize: Int, closure: @escaping (_: Range<Int>) async throws -> Data) {
        self.totalSize = totalSize
        self.closure = closure
    }
    
    public func prepareToRead(byteRange: Range<Int>) async throws {
        guard !buffer.contains(range: byteRange) else { return }
        
        var byteRange = byteRange
        if let newLowerBound = buffer.upperBound(for: byteRange.lowerBound) {
            byteRange = newLowerBound..<byteRange.upperBound
        }

        let data = try await closure(byteRange)
        guard data.count >= byteRange.count else {
            throw MP4Error.insufficientDataReturned
        }
        buffer.insert(data: data, at: byteRange.lowerBound)
    }
    
    public func isPreparedToRead(byteRange: Range<Int>) -> Bool {
        return buffer.contains(range: byteRange)
    }
    
    public func readData(byteRange: Range<Int>) async throws -> Data {
        try await prepareToRead(byteRange: byteRange)
        return buffer[byteRange]!
    }
}
