//
//  MP4MetadataItemListBox.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public class MP4MetadataItemListBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "ilst"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = []
    public var children: [MP4Box] { [] }
    
    public struct Item: MP4Writeable {
        /// https://developer.apple.com/documentation/quicktime-file-format/well-known_types
        public enum TypeIndicator: UInt32 {
            case utf8 = 1
            case signedIntegerBigEndian = 21
            case unsignedIntegerBigEndian = 22
        }
        
        public struct LanguageIndicator {
            public var country: String
            public var language: String
        }
        
        public var reserved: Data
        public var index: MP4Index<UInt32>
        public var itemType: String
        public var typeIndicatorInteger: UInt32
        public var typeIndicator: TypeIndicator? {
            get {
                .init(rawValue: typeIndicatorInteger)
            }
            set {
                typeIndicatorInteger = newValue!.rawValue
            }
        }
        public var localeInformation: Data
        public var data: Data
        
        public init(reserved: Data, index: MP4Index<UInt32>, itemType: String, typeIndicatorInteger: UInt32, localeInformation: Data, data: Data) {
            self.reserved = reserved
            self.index = index
            self.itemType = itemType
            self.typeIndicatorInteger = typeIndicatorInteger
            self.localeInformation = localeInformation
            self.data = data
        }
        
        public init(reserved: Data, index: MP4Index<UInt32>, itemType: String, typeIndicator: TypeIndicator, localeInformation: Data, data: Data) {
            self.reserved = reserved
            self.index = index
            self.itemType = itemType
            self.typeIndicatorInteger = typeIndicator.rawValue
            self.localeInformation = localeInformation
            self.data = data
        }
        
        public init(from reader: MP4SequentialReader) async throws {
            // TODO: What are these bytes?
            let reserved = try await reader.readData(count: 4)
            
            let index: MP4Index<UInt32> = .init(index1: try await reader.readInteger(byteOrder: .bigEndian))
            let itemSize: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            let itemType = try await reader.readAscii(byteCount: 4)
            let typeIndicatorInteger: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            
            let localeInformation = try await reader.readData(count: 4)
            
            guard itemSize > 16 else {
                throw MP4Error.failedToParseBox(description: "ilst box entry with invalid item size")
            }
            
            let data = Data(try await reader.readData(count: Int(itemSize)-16))

            self = Item(reserved: reserved,
                        index: index,
                        itemType: itemType,
                        typeIndicatorInteger: typeIndicatorInteger,
                        localeInformation: localeInformation,
                        data: data)
        }
        
        public func write(to writer: MP4Writer) async throws {
            try await writer.write(reserved)
            try await writer.write(index.index1, byteOrder: .bigEndian)
            
            let itemSize: UInt32 = UInt32(data.count) + 16
            try await writer.write(itemSize, byteOrder: .bigEndian)
            try await writer.write(itemType, encoding: .ascii, length: 4)
            try await writer.write(typeIndicatorInteger, byteOrder: .bigEndian)
            try await writer.write(localeInformation[0..<4])
            try await writer.write(data)
        }
        
        public var overestimatedByteSize: Int {
            reserved.count + 4 + data.count + 16
        }
        
        public func asString() -> String? {
            switch typeIndicator {
            case .utf8:
                return String(data: data, encoding: .utf8)
            default:
                return nil
            }
        }
        
        public func asFixedInteger<T: FixedWidthInteger>() -> T? {
            switch typeIndicator {
            case .signedIntegerBigEndian, .unsignedIntegerBigEndian:
                return data.asFixedInteger<T>(byteOrder: .bigEndian)
            default:
                return nil
            }
        }
        
        public func asInteger() -> Int? {
            switch typeIndicator {
            case .signedIntegerBigEndian:
                return data.asInteger(byteOrder: .bigEndian, signed: true)
            case .unsignedIntegerBigEndian:
                return data.asInteger(byteOrder: .bigEndian, signed: false)
            default:
                return nil
            }
        }
        
        public func asDouble() -> Double? {
            switch typeIndicator {
            case .utf8:
                return Double(asString()!)
            case .signedIntegerBigEndian, .unsignedIntegerBigEndian:
                return Double(asInteger()!)
            default:
                return nil
            }
        }
    }
    
    public var items: [MP4Index<UInt32>: Item]
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.items = [:]
        
        while reader.remainingCount > 12 {
            let item = try await Item(from: reader)
            self.items[item.index] = item
        }
    }
    
    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(Array(items.values).sorted(by: {$0.index < $1.index}))
    }
    
    public var overestimatedContentByteSize: Int {
        items.values.map {$0.overestimatedByteSize}.reduce(0, +)
    }
    
    public func items(metadataItemKeysBox: MP4MetadataItemKeysBox) -> [MP4MetadataItemKeysBox.Key: Item] {
        var result: [MP4MetadataItemKeysBox.Key: Item] = [:]
        
        for (keyIndex, key) in metadataItemKeysBox.keys.enumerated() {
            if let item = items[MP4Index(index0: UInt32(keyIndex))] {
                result[key] = item
            }
        }
        
        return result
    }
}
