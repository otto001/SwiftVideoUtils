//
//  MP4BoxFlags.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public struct MP4BoxFlags: MP4Writeable {
    public let inner: (UInt8, UInt8, UInt8)
    
    public init(_ inner: (UInt8, UInt8, UInt8) = (0, 0, 0)) {
        self.inner = inner
    }
    
    public init(readFrom reader: any MP4Reader) async throws {
        self.init((try await reader.readInteger(UInt8.self, byteOrder: .native), try await reader.readInteger(UInt8.self, byteOrder: .native), try await reader.readInteger(UInt8.self, byteOrder: .native)))
    }
    
    public func write(to writer: any MP4Writer) async throws {
        try await writer.write(inner.0)
        try await writer.write(inner.1)
        try await writer.write(inner.2)
    }
}
