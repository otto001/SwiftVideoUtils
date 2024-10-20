//
//  MP4MetadataKeyTableBox.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation

public class MP4MetadataKeyTableBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "keys"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var readByteRange: Range<Int>?
    
    public class MP4MetaDataKeyBox: MP4Box {
        public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4MetadataKeyDeclarationBox.self, MP4MetadataDatatypeDefinitionBox.self]
        
        public var typeName: MP4FourCC
       
        public var readByteRange: Range<Int>?
        
        public var children: [MP4Box]
        
        public required init(contentReader reader: MP4SequentialReader) async throws {
            let size: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            
            self.readByteRange = (reader.readOffset - 4)..<(reader.readOffset - 4 + Int(size))
            
            self.typeName = try await reader.read()
            self.children = try await MP4SequentialReader(sequentialReader: reader, count: Int(size)-8).readBoxes(boxTypeMap: Self.supportedChildBoxTypes)
            
            reader.offset += Int(size)-8
        }
        
        public func write(to writer: MP4Writer) async throws {
            let contentWriter = MP4BufferWriter()
            try await writeContent(to: contentWriter)
            
            try await writer.write(UInt32(contentWriter.count) + 8, byteOrder: .bigEndian)
            try await writer.write(typeName)
            
            try await writer.write(contentWriter.buffer)
        }
        
        public func writeContent(to writer: MP4Writer) async throws {
            try await writer.write(children)
        }
        
        public var overestimatedContentByteSize: Int {
            self.children.map {$0.overestimatedByteSize}.reduce(0, +)
        }
    }
    public var children: [MP4Box]

    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.children = []
        
        while reader.remainingCount > 0 {
            self.children.append(try await MP4MetaDataKeyBox(contentReader: reader))
        }
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(children)
    }
    
    public var overestimatedContentByteSize: Int {
        return self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
}
