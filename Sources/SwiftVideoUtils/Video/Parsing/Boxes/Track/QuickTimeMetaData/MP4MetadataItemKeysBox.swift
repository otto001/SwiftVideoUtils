//
//  MP4MetadataItemKeysBox.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation
import CoreMedia

public class MP4MetadataItemKeysBox: MP4VersionedBox {
    public static let typeName: MP4FourCC = "keys"

    public var version: UInt8
    public var flags: MP4BoxFlags
    
    public var endPadding: Data
    
    public struct Key: Equatable, Hashable, MP4Writeable {
        var namespace: String
        var value: String
        
        public init(namespace: String, value: String) {
            self.namespace = namespace
            self.value = value
        }
        
        public init(from reader: MP4SequentialReader) async throws {
            let keySize: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            let namespace = try await reader.readAscii(byteCount: 4)
            let value = try await reader.readAscii(byteCount: Int(keySize)-8)
            
            self = .init(namespace: namespace, value: value)
        }
        
        public func write(to writer: MP4Writer) async throws {
            let keySize = UInt32(value.count + 8)
            try await writer.write(keySize, byteOrder: .bigEndian)
            try await writer.write(namespace, encoding: .ascii, length: 4)
            try await writer.write(value, encoding: .ascii)
        }
    }
    
    public var keys: [Key]
    
    public required init(reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
        self.flags = try await reader.read()
        
        self.keys = []

        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            self.keys.append(try await Key(from: reader))
        }
        
        self.endPadding = try await reader.readAllData()
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(version)
        try await writer.write(flags)
        
        try await writer.write(UInt32(keys.count), byteOrder: .bigEndian)
        
        try await writer.write(keys)
        
        try await writer.write(endPadding)
    }
    
    public func index(of key: Key) -> MP4Index<UInt32>? {
        keys.firstIndex(of: key).map { MP4Index<UInt32>(index0: UInt32($0)) }
    }
}
