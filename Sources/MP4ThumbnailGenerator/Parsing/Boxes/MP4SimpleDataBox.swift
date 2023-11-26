//
//  MP4SimpleDataBox.swift
//
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation

public class MP4SimpleDataBox: MP4Box {
    public var typeName: String
    
    public var lazy: Bool {
        reader != nil
    }
    private var reader: (any MP4Reader)?
    private var _data: Data?
    
    public var data: Data {
        get async throws {
            if let reader = reader {
                return try await reader.readAllData()
            }
            return _data!
        }
    }

    public init(typeName: String, data: Data?) {
        self.typeName = typeName
        self._data = data
    }
    
    public init(typeName: String, reader: any MP4Reader, lazy: Bool = false) async throws {
        self.typeName = typeName
        
        if lazy {
            self.reader = reader
        } else {
            self._data = try await reader.readAllData()
        }
        
        if typeName == "mebx" {
            reader.offset = 0
            //let size = reader.remainingCount
            //try await reader.printBytes()
            //print()
//            if content.contains("iPhone") {
//                reader.offset = 0
//                print(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian), size)
//                print(try await reader.readInteger(UInt32.self, byteOrder: .bigEndian))
//                print("A")
//            }
        }
    }
    
    public func indentedString(level: Int) -> String {
        var result = String(repeating: "  ", count: level) + typeName + " \(_data?.count ?? reader!.remainingCount) bytes"
        if !children.isEmpty {
            result += "\n" + children.map {$0.indentedString(level: level+1)}.joined(separator: "\n")
        }
        return result
    }
}

