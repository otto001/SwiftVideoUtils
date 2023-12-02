//
//  MP4BufferWriter.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation


public class MP4BufferWriter: MP4Writer {
    public private(set) var data: Data = .init()
    
    public var count: Int { data.count }
    public var offset: Int { data.endIndex }
    
    public func write(_ data: Data) async throws {
        self.data.append(contentsOf: data)
    }
}
