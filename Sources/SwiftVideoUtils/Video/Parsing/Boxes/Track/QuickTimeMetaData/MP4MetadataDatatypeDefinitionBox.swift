//
//  MP4MetadataDatatypeDefinitionBox.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation

public class MP4MetadataDatatypeDefinitionBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "dtyp"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var readByteRange: Range<Int>?
    
    public var children: [MP4Box] { [] }
    
    public var namespace: String
    public var value: Data
    
    var mdtaValue: String? {
        guard namespace == "mdta" else { return nil }
        return String(data: value, encoding: .ascii)
    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.namespace = try await reader.readAscii(byteCount: 4)
        self.value = try await reader.readAllData()
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(namespace, encoding: .ascii, length: 4)
        try await writer.write(value)
    }
    
    public var overestimatedContentByteSize: Int {
        4 + value.count
    }
}
