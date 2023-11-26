//
//  MP4BoxFlags.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public struct MP4BoxFlags {
    let inner: (UInt8, UInt8, UInt8)
    
    init(_ inner: (UInt8, UInt8, UInt8) = (0, 0, 0)) {
        self.inner = inner
    }
    
    init(readFrom reader: any MP4Reader) async throws {
        self.init((try await reader.readInteger(UInt8.self, byteOrder: .native), try await reader.readInteger(UInt8.self, byteOrder: .native), try await reader.readInteger(UInt8.self, byteOrder: .native)))
    }
}
