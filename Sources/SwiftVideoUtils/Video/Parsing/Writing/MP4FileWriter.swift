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
    public private(set) var fileHandleOffset: Int = 0
    
    init(url: URL, context: MP4IOContext = .init()) throws {
        if !FileManager.default.fileExists(atPath: url.relativePath) {
            FileManager.default.createFile(atPath: url.relativePath, contents: nil)
        }
        
        self.fileHandle = try FileHandle(forWritingTo: url)
        self.context = context
    }
    
    public func write(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Self.fileWriterQueue.async {
                do {
                    if self.fileHandleOffset != self.offset {
                        try self.fileHandle.seek(toOffset: UInt64(self.offset))
                    }
                    try self.fileHandle.write(contentsOf: data)
                    self.fileHandleOffset += data.count
                    self.offset = self.fileHandleOffset
                    
                    continuation.resume()
                } catch {
                    self.fileHandleOffset = (try? self.fileHandle.offset()).map {Int($0)} ?? -1
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func close() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Self.fileWriterQueue.async {
                do {
                    try self.fileHandle.synchronize()
                    try self.fileHandle.close()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
