//
//  MP4FileWriter.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation



public class MP4FileWriter: MP4Writer {
    private static let fileWriterQueue = DispatchQueue(label: "de.mludwig.MP4Utils.MP4FileWriter")
    
    private let fileHandle: FileHandle
    
    public var context: MP4IOContext
    
    public var count: Int { offset }
    public var offset: Int = 0
    
    public init(url: URL, context: MP4IOContext = .init()) throws {
        if !FileManager.default.fileExists(atPath: url.relativePath) {
            FileManager.default.createFile(atPath: url.relativePath, contents: nil)
        }
        
        self.fileHandle = try FileHandle(forWritingTo: url)
        self.context = context
    }
    
    public func write(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let fileHandle = self.fileHandle
            let offset = self.offset
            Self.fileWriterQueue.async {
                do {
                    let fileHandleOffset = try fileHandle.offset()
                    if fileHandleOffset != offset {
                        try fileHandle.seek(toOffset: UInt64(offset))
                    }
                    try fileHandle.write(contentsOf: data)
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        self.offset = Int(try self.fileHandle.offset())
    }
    
    public func close() async throws {
        let fileHandle = self.fileHandle
        try await withCheckedThrowingContinuation { continuation in
            Self.fileWriterQueue.async {
                do {
                    try fileHandle.synchronize()
                    try fileHandle.close()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
