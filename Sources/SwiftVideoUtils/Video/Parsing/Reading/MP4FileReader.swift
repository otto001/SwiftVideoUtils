//
//  MP4FileReader.swift
//
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation

public enum MP4FileReaderError: Error {
    case noDataAvaliable
}

public class MP4FileReader: MP4Reader {
    private static let fileReaderQueue = DispatchQueue(label: "de.mludwig.MP4Utils.MP4FileReader")
    
    private let fileHandle: FileHandle
    public let totalSize: Int
    
    public var context: MP4IOContext
    
    public let fileURL: URL
    
    
    public init(url: URL, context: MP4IOContext = .init()) throws {
        self.fileHandle = try .init(forReadingFrom: url)
        self.fileURL = url
        self.totalSize = Int(try FileManager.default.attributesOfItem(atPath: url.relativePath)[.size] as! UInt64)
        self.context = context
    }
    
    public func prepareToRead(byteRange: Range<Int>) throws {
        if byteRange.upperBound > self.totalSize {
            throw MP4Error.tooFewBytes
        }
        if try fileHandle.offset() != byteRange.lowerBound {
            try fileHandle.seek(toOffset: UInt64(byteRange.lowerBound))
        }
    }
    
    public func isPreparedToRead(byteRange: Range<Int>) throws -> Bool {
        if byteRange.upperBound > self.totalSize {
            throw MP4Error.tooFewBytes
        }
        return true
    }

    public func readData(byteRange: Range<Int>) async throws -> Data {
        guard !byteRange.isEmpty else {
            return .init()
        }
        if byteRange.upperBound > self.totalSize {
            throw MP4Error.tooFewBytes
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            Self.fileReaderQueue.async {
                do {
                    try self.prepareToRead(byteRange: byteRange)
                    guard let data = try self.fileHandle.read(upToCount: byteRange.count) else {
                        throw MP4FileReaderError.noDataAvaliable
                    }
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
