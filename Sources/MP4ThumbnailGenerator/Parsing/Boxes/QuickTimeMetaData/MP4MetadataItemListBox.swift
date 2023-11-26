//
//  MP4MetadataItemListBox.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public class MP4MetadataItemListBox: MP4ParsableBox {
    public static let typeName: String = "ilst"

    
    public struct Item {
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
        
        var index: MP4Index<UInt32>
        var typeIndicator: TypeIndicator
        var data: Data
        
        func asString() -> String? {
            switch typeIndicator {
            case .utf8:
                return String(data: data, encoding: .utf8)
            default:
                return nil
            }
        }
        
        func asFixedInteger<T: FixedWidthInteger>() -> T? {
            switch typeIndicator {
            case .signedIntegerBigEndian, .unsignedIntegerBigEndian:
                return data.asFixedInteger<T>(byteOrder: .bigEndian)
            default:
                return nil
            }
        }
        
        func asInteger() -> Int? {
            switch typeIndicator {
            case .signedIntegerBigEndian:
                return data.asInteger(byteOrder: .bigEndian, signed: true)
            case .unsignedIntegerBigEndian:
                return data.asInteger(byteOrder: .bigEndian, signed: false)
            default:
                return nil
            }
        }
        
        func asDouble() -> Double? {
            switch typeIndicator {
            case .utf8:
                return Double(asString()!)
            case .signedIntegerBigEndian, .unsignedIntegerBigEndian:
                return Double(asInteger()!)
            }
        }
    }
    
    public var items: [MP4Index<UInt32>: Item]
    
    public required init(reader: any MP4Reader) async throws {
        self.items = [:]
        
        while reader.remainingCount > 12 {
            reader.offset += 4
            
            let index: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            let itemSize: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            let itemType = try await reader.readString(byteCount: 4, encoding: .ascii)!
            let typeIndicator: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            
            // TODO: Support locales?
            //let localeIndicator = try await reader.readString(byteCount: 4, encoding: .ascii)!
            reader.offset += 4
            
            //try await reader.printBytes(count: Int(itemSize))
            let data = Data(try await reader.readData(count: Int(itemSize)-8-8))
            
            guard let typeIndicator = Item.TypeIndicator(rawValue: typeIndicator), itemType == "data" else {
                continue
            }
            
            self.items[.init(index1: index)] = Item(index: .init(index1: index), typeIndicator: typeIndicator, data: data)
        }
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
