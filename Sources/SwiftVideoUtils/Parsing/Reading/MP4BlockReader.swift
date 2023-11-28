//
//  MP4BlockReader.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public class MP4BlockReader: MP4Reader {
    public let count: Int
    
    public var offset: Int
    
    public var remainingCount: Int {
        count - offset
    }
    
    private let closure: (_ range: Range<Int>) async throws -> Data
    private var buffer: MP4PartionedBuffer = .init()
    
    public init(count: Int, closure: @escaping (_: Range<Int>) async throws -> Data) {
        self.offset = 0
        self.count = count
        self.closure = closure
    }
    
    public func prepareToRead(count readCount: Int) async throws {
        var range = offset..<offset+readCount
        guard !buffer.contains(range: range) else { return }
        
        if let newLowerBound = buffer.upperBound(for: range.lowerBound) {
            range = newLowerBound..<range.upperBound
        }
        
        let data = try await closure(range)
        buffer.insert(data: data, at: range.lowerBound)
    }
    
    public func readData(count readCount: Int) async throws -> Data {
        try await prepareToRead(count: readCount)
        defer {
            offset += readCount
        }
        return buffer[offset..<offset+readCount]!
    }
}
