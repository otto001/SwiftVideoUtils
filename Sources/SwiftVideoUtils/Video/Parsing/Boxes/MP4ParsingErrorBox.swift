//
//  MP4ParsingErrorBox.swift
//
//
//  Created by Matteo Ludwig on 03.12.23.
//

import Foundation

public class MP4ParsingErrorBox: MP4SimpleDataBox {
    public var error: Error

    public init(typeName: MP4FourCC, reader: MP4SequentialReader, error: Error) async throws {
        self.error = error
        try await super.init(typeName: typeName, reader: reader, lazy: true)
    }
    
    override public func indentedString(level: Int) -> String {
        return String(repeating: "  ", count: level) + typeName.description + " \(size) bytes (\(error)"
    }
}
