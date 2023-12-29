//
//  MP4SampleEntryBox.swift
//
//
//  Created by Matteo Ludwig on 28.12.23.
//

import Foundation

public protocol MP4SampleEntryBox: MP4ParsableBox {
    static var supportedFormats: [MP4FourCC] { get }
    static var supportedChildBoxTypes: MP4BoxTypeMap { get }
    
    init(format: MP4FourCC, contentReader: MP4SequentialReader) async throws
}


public extension MP4SampleEntryBox {
    static var supportedTypeNames: [MP4FourCC] { supportedFormats }
    
    init(typeName: MP4FourCC, contentReader reader: MP4SequentialReader) async throws {
        try await self.init(format: typeName, contentReader: reader)
    }
}
