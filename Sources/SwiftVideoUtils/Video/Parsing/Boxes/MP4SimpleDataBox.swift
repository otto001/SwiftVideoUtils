//
//  MP4SimpleDataBox.swift
//
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation

public class MP4SimpleDataBox: MP4Box {
    public var typeName: MP4FourCC
    public var children: [MP4Box] { [] }
    
    public var readByteRange: Range<Int>?
    
    public var lazy: Bool {
        reader != nil
    }
    private var reader: (MP4SequentialReader)?
    private var _data: Data?
    
    public var size: Int {
        _data?.count ?? reader!.remainingCount
    }
    
    public var data: Data {
        get async throws {
            if let reader = reader {
                defer { reader.offset = 0 }
                return try await reader.readAllData()
            }
            return _data!
        }
    }

    public init(typeName: MP4FourCC, data: Data?) {
        self.typeName = typeName
        self._data = data
    }
    
    public init(typeName: MP4FourCC, reader: MP4SequentialReader, lazy: Bool = true) async throws {
        self.typeName = typeName
        
        var fetchNow = !lazy
        
        if lazy && reader.remainingCount <= 1024 {
            fetchNow = try await reader.isPreparedToRead(count: reader.remainingCount)
        }
        
        reader.offset = 0
        if fetchNow {
            self._data = try await reader.readAllData()
        } else {
            self.reader = reader
        }
    }
    
    public func write(to writer: any MP4Writer) async throws {
        reader?.offset = 0
        let size = reader?.count ?? _data!.count
        try await writeSizeAndTypename(to: writer, contentSize: size)
        try await writeContent(to: writer)
    }
    
    public var overestimatedContentByteSize: Int {
        (reader?.count ?? _data!.count)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        if let data = _data {
            try await writer.write(data)
        } else {
            let blockSize = 4*1024*1024 // 4MB
            let reader = reader!
            reader.offset = 0
            while reader.remainingCount > 0 {
                let block = try await reader.readData(count: min(blockSize, reader.remainingCount))
                try await writer.write(block)
            }
        }
    }
    
    public func indentedString(level: Int) -> String {
        return String(repeating: "  ", count: level) + typeName.description + " \(_data?.count ?? reader!.remainingCount) bytes"
    }
}

