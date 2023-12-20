//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 20.12.23.
//

import Foundation


public protocol MP4Readable {
    init(readingFrom reader: MP4SequentialReader) async throws
}

extension UInt8: MP4Readable {
    public init(readingFrom reader: MP4SequentialReader) async throws {
        self = try await reader.readInteger(byteOrder: .native)
    }
}

extension Int8: MP4Readable {
    public init(readingFrom reader: MP4SequentialReader) async throws {
        self = try await reader.readInteger(byteOrder: .native)
    }
}
