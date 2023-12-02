//
//  MP4MetadataKeyTableBox.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation

public class MP4MetadataKeyTableBox: MP4ParsableBox {
    public static let typeName: String = "keys"

    public class MP4MetaDataKeyBox: MP4Box {
        public var localKeyId: UInt32
        public var typeName: String {
            String(data: localKeyId.data, encoding: .ascii)!
        }
        
        public var children: [MP4Box]
        
        public required init(reader: any MP4Reader) async throws {
            let _: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            self.localKeyId = try await reader.readInteger(byteOrder: .bigEndian)
            self.children = try await MP4BoxParser(reader: reader).readBoxes()
        }
        
        public func write(to writer: MP4Writer) async throws {
            let contentWriter = MP4BufferWriter()
            try await writeContent(to: contentWriter)
            
            try await writer.write(UInt32(contentWriter.count) + 8, byteOrder: .bigEndian)
            try await writer.write(localKeyId, byteOrder: .bigEndian)
            
            try await writer.write(contentWriter.data)
        }
        
        public func writeContent(to writer: MP4Writer) async throws {
            try await writer.write(children)
        }
    }
    public var children: [MP4MetaDataKeyBox]

    
    public required init(reader: any MP4Reader) async throws {
        self.children = []
        
        while reader.remainingCount > 0 {
            self.children.append(try await .init(reader: reader))
        }
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(children)
    }
}
