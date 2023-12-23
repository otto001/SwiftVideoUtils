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
    public private(set) var offset: Int = 0
    
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
                    try self.fileHandle.write(contentsOf: data)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
