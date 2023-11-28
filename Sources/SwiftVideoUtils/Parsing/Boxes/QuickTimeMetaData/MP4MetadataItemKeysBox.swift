//
//  MP4MetadataItemKeysBox.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation
import CoreMedia

public class MP4MetadataItemKeysBox: MP4ParsableBox {
    public static let typeName: String = "keys"

    public struct Key: Equatable, Hashable {
        var namespace: String
        var value: String
    }
    
    public var keys: [Key]
    
    public required init(reader: any MP4Reader) async throws {
        self.keys = []
        // try await reader.printBytes()
        
        // TODO: I dont know what these 4 bytes encode
        reader.offset += 4
        
        let entryCount: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
        for _ in 0..<entryCount {
            let keySize: UInt32 = try await reader.readInteger(byteOrder: .bigEndian)
            var namespace = try await reader.readAscii(byteCount: 4)
            
            var valueLength = Int(keySize)-8
            if namespace == "keyd" {
                namespace = try await reader.readAscii(byteCount: 4)
                valueLength -= 4
            }
            
            let key = try await reader.readAscii(byteCount: valueLength)
            self.keys.append(.init(namespace: namespace, value: key))
        }
//        print(kCMMetadataBaseDataType_SInt64)
//        print(kCMMetadataIdentifier_QuickTimeMetadataVideoOrientation)
//        print(kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709)
        print(self.keys)
    }
    
    public func index(of key: Key) -> MP4Index<UInt32>? {
        keys.firstIndex(of: key).map { MP4Index<UInt32>(index0: UInt32($0)) }
    }
}
