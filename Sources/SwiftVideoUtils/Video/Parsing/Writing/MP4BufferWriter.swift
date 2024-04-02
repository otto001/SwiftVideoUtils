//
//  MP4BufferWriter.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation


public class MP4BufferWriter: MP4Writer {
    public private(set) var data: Data = .init()
    
    public var context: MP4IOContext
    
    public var count: Int { data.count }
    public var offset: Int { data.endIndex }
    
    public func write(_ data: Data) async throws {
        self.data.append(contentsOf: data)
    }
    
    public init(context: MP4IOContext = .init()) {
        self.context = context
    }
    
    public func reserveCapacity(bytes: Int) {
        self.data.reserveCapacity(bytes)
    }
}
