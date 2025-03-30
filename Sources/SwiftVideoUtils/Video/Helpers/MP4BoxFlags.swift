//
//  MP4BoxFlags.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public struct MP4BoxFlags {
    public let inner: (UInt8, UInt8, UInt8)
    
    public init(_ inner: (UInt8, UInt8, UInt8) = (0, 0, 0)) {
        self.inner = inner
    }
    
    public init(combined: UInt32) {
        self.inner = (UInt8((combined & 0xFF0000) >> 16),
                      UInt8((combined & 0x00FF00) >> 8),
                      UInt8(combined & 0x0000FF))
    }
    
    public var combined: UInt32 {
        return UInt32(inner.2) | (UInt32(inner.1) << 8) | (UInt32(inner.0) << 16)
    }
    
    public func has(_ flag: UInt32) -> Bool {
        (combined & flag) != 0
    }
}

extension MP4BoxFlags: MP4Readable {
    public init(readingFrom reader: MP4SequentialReader) async throws {
        self.init((try await reader.read(), try await reader.read(), try await reader.read()))
    }
}

extension MP4BoxFlags: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(inner.0)
        try await writer.write(inner.1)
        try await writer.write(inner.2)
    }
    
    public var overestimatedByteSize: Int {
        return 3
    }
}
