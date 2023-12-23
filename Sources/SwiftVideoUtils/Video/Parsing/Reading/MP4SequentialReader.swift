//
//  MP4SequentialReader.swift
//  
//
//  Created by Matteo Ludwig on 20.12.23.
//

import Foundation



public class MP4SequentialReader {
    public let reader: any MP4Reader
    
    var context: MP4IOContext {
        reader.context
    }
    
    // TODO: make read-only
    public var offset: Int = 0
    public let baseOffset: Int
    public let limit: Int
    public var remainingCount: Int {
        limit - baseOffset - offset
    }
    
    public init(reader: any MP4Reader) {
        self.reader = reader
        self.baseOffset = 0
        self.limit = reader.totalSize
    }
    
    public init(reader: any MP4Reader, startingAt: Int, count: Int) throws {
        self.reader = reader
        self.baseOffset = startingAt

        self.limit = startingAt + count
        if self.limit > reader.totalSize {
            throw MP4Error.tooFewBytes
        }
    }
    
    public init(sequentialReader: MP4SequentialReader, count: Int?) throws {
        self.reader = sequentialReader.reader
        self.baseOffset = sequentialReader.baseOffset + sequentialReader.offset
        if let count = count {
            self.limit = sequentialReader.baseOffset + sequentialReader.offset + count
            if self.limit > reader.totalSize {
                throw MP4Error.tooFewBytes
            }
        } else {
            self.limit = reader.totalSize
        }
    }
    
    private func byteRange(count: Int) throws -> Range<Int> {
        guard self.remainingCount >= count else {
            throw MP4Error.tooFewBytes
        }
        return baseOffset+offset..<baseOffset+offset+count
    }

    public func prepareToRead(count readCount: Int) async throws {
        try await self.reader.prepareToRead(byteRange: self.byteRange(count: readCount))
    }
    
    public func isPreparedToRead(count readCount: Int) async throws -> Bool {
        try await self.reader.isPreparedToRead(byteRange: self.byteRange(count: readCount))
    }
    
    public func readData(count readCount: Int) async throws -> Data {
        guard readCount <= remainingCount else {
            throw MP4Error.tooFewBytes
        }
        defer { offset += readCount }
        return try await self.reader.readData(byteRange: self.byteRange(count: readCount))
    }
    
    public func readInteger<T: FixedWidthInteger>(_ type: T.Type, byteOrder: ByteOrder) async throws -> T {
        guard MemoryLayout<T>.size <= remainingCount else {
            throw MP4Error.tooFewBytes
        }
        defer { offset += MemoryLayout<T>.size }
        return try await self.reader.readInteger(startingAt: baseOffset+offset, type.self, byteOrder: byteOrder)
    }
    
    public func readFixedPoint<T: FixedWidthInteger & UnsignedInteger>(underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws -> Double {
        guard MemoryLayout<T>.size <= remainingCount else {
            throw MP4Error.tooFewBytes
        }
        defer { offset += MemoryLayout<T>.size }
        return try await self.reader.readFixedPoint(startingAt: baseOffset+offset, underlyingType: underlyingType.self, fractionBits: fractionBits, byteOrder: byteOrder)
    }
}

// MARK: Integers
public extension MP4SequentialReader {
    func readInteger<T: FixedWidthInteger>(byteOrder: ByteOrder) async throws -> T {
        try await self.readInteger(T.self, byteOrder: byteOrder)
    }
}


// MARK: Date
public extension MP4SequentialReader {
    func readDate<T: FixedWidthInteger>(_ type: T.Type, referenceDate: Date = .mp4ReferenceDate) async throws -> Date {
        Date(timeInterval: TimeInterval(try await readInteger(T.self, byteOrder: .bigEndian)),
             since: referenceDate)
    }
}

// MARK: Flags
public extension MP4SequentialReader {
    func read<T: MP4Readable>(_ type: T.Type) async throws -> T {
        return try await .init(readingFrom: self)
    }
    
    func read<T: MP4Readable>() async throws -> T {
        return try await .init(readingFrom: self)
    }
}

// MARK: Data & String
public extension MP4SequentialReader {
    
    func readAllData() async throws -> Data {
        try await self.readData(count: self.remainingCount)
    }
    
    func readString(byteCount: Int, encoding: String.Encoding, dropLengthPrefix: Bool = false) async throws -> String? {
        var byteCount = byteCount
        if dropLengthPrefix {
            try await self.prepareToRead(count: byteCount)
            let length: Int8 = try await self.read()
            if length == byteCount {
                byteCount -= 1
            } else {
                self.offset -= 1
            }
        }
        
        if byteCount == 0 {
            return ""
        }
        
        return try await String(data: self.readData(count: byteCount), encoding: encoding)
    }
    
    func readAscii(byteCount: Int, dropLengthPrefix: Bool = false) async throws -> String {
        try await self.readString(byteCount: byteCount, encoding: .ascii, dropLengthPrefix: dropLengthPrefix)!
    }
}



// MARK: Print Bytes
public extension MP4SequentialReader {
    
    
    func printBytes(count printCount: Int? = nil, mode: DataDebugFormatMode = .ascii, grouping: Int = 4) async throws  {
        let startOffset = self.offset
        let printCount = min(printCount ?? self.remainingCount, self.remainingCount)
        let data = try await self.readData(count: printCount)
        self.offset = startOffset
        print(data.debugString(mode: mode, grouping: grouping))
    }
}

public extension MP4SequentialReader {
    
    func readBox(boxTypeMap: MP4BoxTypeMap) async throws -> any MP4Box {
        guard self.remainingCount >= 8 else {
            throw MP4Error.endOfFile
        }
        
        try await self.prepareToRead(count: min(16, self.remainingCount))
        
        let startOffset = self.offset
        
        var size = Int(try await self.readInteger(UInt32.self, byteOrder: .bigEndian))
        
        if (size != 1 && size < 8) || size-8 > self.remainingCount {
            throw MP4Error.failedToParseBox(description: "Box size `\(size)` invalid (below 8 or larger than parent box)")
        }
        
        let typeName: MP4FourCC = try await self.read()
        
        if size == 1 {
            size = Int(try await self.readInteger(UInt64.self, byteOrder: .bigEndian))
        }
        
        let remainingSizeOfBox = size - (self.offset - startOffset)
        
        guard remainingSizeOfBox <= self.remainingCount else {
            throw MP4Error.failedToParseBox(description: "Box size invalid (below 8 or larger than parent box)")
        }
        
        let box = try await readBoxContent(boxTypeMap: boxTypeMap, typeName: typeName, size: size, contentOffset: self.offset - startOffset)
        
        self.offset = startOffset + size
        
        return box
    }
    
    func readBoxes(boxTypeMap: MP4BoxTypeMap) async throws -> [any MP4Box] {
        var result: [any MP4Box] = []
        
        do {
            while self.remainingCount >= 8 {
                result.append(try await readBox(boxTypeMap: boxTypeMap))
            }
        } catch MP4Error.endOfFile {
            
        }
        
        return result
    }
    
    func readBoxes(parentType: MP4ParsableBox.Type) async throws -> [any MP4Box] {
        return try await self.readBoxes(boxTypeMap: parentType.supportedChildBoxTypes)
    }
    
    func readBoxes<T: MP4ParsableBox>(parent: T) async throws -> [any MP4Box] {
        return try await self.readBoxes(boxTypeMap: T.supportedChildBoxTypes)
    }
    
    private func readBoxContent(boxTypeMap: MP4BoxTypeMap, typeName: MP4FourCC, size: Int, contentOffset: Int) async throws -> any MP4Box {
        
        let contentReader = try MP4SequentialReader(sequentialReader: self, count: min(size - contentOffset, self.remainingCount))

        
        var result: any MP4Box
        
        do {
            if let boxType = boxTypeMap.boxType(for: typeName) {
                try await self.prepareToRead(count: min(contentReader.remainingCount + 16, self.remainingCount))
                
                result = try await boxType.init(reader: contentReader)
                if contentReader.remainingCount != 0 {
                    try await contentReader.printBytes()
                }
                
                if contentReader.remainingCount > 0 {
                    // TODO: We could do something about that in the future
                    throw MP4Error.failedToParseBox(description: "Did not parse \(contentReader.remainingCount) bytes at the end of the box.")
                }
                
            } else if MP4BoxTypeMap.knownContainerTypes.contains(typeName) {
                result = try await MP4SimpleContainerBox(typeName: typeName, reader: contentReader)
            } else {
                contentReader.offset = 0
                result = try await MP4SimpleDataBox(typeName: typeName, reader: contentReader, lazy: true)
            }
        } catch {
            switch error {
            case MP4Error.failedToParseBox, MP4Error.failedToParseBox:
                result = try await MP4ParsingErrorBox(typeName: typeName, reader: contentReader, error: error)
            default:
                throw error
            }
        }
        
        return result
    }
    
}
