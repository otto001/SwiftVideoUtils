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
}
