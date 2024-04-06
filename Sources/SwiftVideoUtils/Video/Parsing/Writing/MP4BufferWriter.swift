//
//  MP4BufferWriter.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation


public class MP4BufferWriter: MP4Writer {
    public private(set) var buffer: Data = .init()
    
    public var context: MP4IOContext
    
    public var count: Int { buffer.count }
    public var offset: Int = 0
    
    public func write(_ data: Data) async throws {
        if offset == self.buffer.endIndex {
            self.buffer.append(contentsOf: data)
        } else {
            let overwriteEnd = min(self.buffer.endIndex, self.offset + data.count)
            self.buffer[self.offset..<overwriteEnd] = data[0..<(overwriteEnd - self.offset)]
            
            if overwriteEnd - self.offset < data.count {
                self.buffer.append(contentsOf: data[(overwriteEnd - self.offset)...])
            }
        }
        
        self.offset += data.count
    }
    
    public init(buffer: Data? = nil, context: MP4IOContext = .init()) {
        self.buffer = buffer ?? .init()
        self.context = context
    }
    
    public func reserveCapacity(bytes: Int) {
        self.buffer.reserveCapacity(bytes)
    }
}
