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
    private var fileSize: Int
    
    public var offset: Int = 0
    
    public var remainingCount: Int {
        fileSize - offset
    }
    
    public init(url: URL) throws {
        self.fileHandle = try .init(forReadingFrom: url)
        self.fileSize = Int(try FileManager.default.attributesOfItem(atPath: url.relativePath)[.size] as! UInt64)
    }

    public func readData(count readCount: Int) async throws -> Data {
        guard readCount > 0 else {
            return .init()
        }
        
        let currentOffset = try fileHandle.offset()
        if offset != currentOffset {
            try fileHandle.seek(toOffset: UInt64(offset))
        }
        
        offset += readCount
        
        return try await withCheckedThrowingContinuation { continuation in
            Self.fileReaderQueue.async {
                do {
                    guard let data = try self.fileHandle.read(upToCount: readCount) else {
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
