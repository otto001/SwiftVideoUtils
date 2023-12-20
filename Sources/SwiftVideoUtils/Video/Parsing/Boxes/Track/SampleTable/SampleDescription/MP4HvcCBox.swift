//
//  MP4HvcCBox.swift
//
//
//  Created by Matteo Ludwig on 26.11.23.
//

import Foundation


public class MP4HvcCBox: MP4ParsableBox {
    public static let typeName: MP4FourCC = "hvcC"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var data: Data
    
    required public init(reader: MP4SequentialReader) async throws {
        self.data = try await reader.readAllData()
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(data)
    }
}
