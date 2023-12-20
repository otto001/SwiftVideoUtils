//
//  MP4MetadataDatatypeDefinitionBox.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation

public class MP4MetadataDatatypeDefinitionBox: MP4ParsableBox {
    public static let typeName: String = "dtyp"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var namespace: String
    public var value: Data
    
    var mdtaValue: String? {
        guard namespace == "mdta" else { return nil }
        return String(data: value, encoding: .ascii)
    }
    
    public required init(reader: any MP4Reader) async throws {
        self.namespace = try await reader.readAscii(byteCount: 4)
        self.value = try await reader.readAllData()
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(namespace, encoding: .ascii)
        try await writer.write(value)
    }
}
