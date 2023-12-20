//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation


public protocol MP4Reader: AnyObject {
    var offset: Int { get set }
    var remainingCount: Int { get }
    
    var strict: Bool { get }
    
    func prepareToRead(count readCount: Int) async throws
    func bytesAreAvaliable(count readCount: Int) async throws -> Bool
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type) async throws -> T
    
    func readData(count readCount: Int) async throws -> Data
    
    func readFixedPoint<T: FixedWidthInteger & UnsignedInteger>(underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws -> Double
}

// MARK: Integers
public extension MP4Reader {
    
    var strict: Bool { true }
    
    func prepareToRead(count readCount: Int) async throws {
        
    }
    
    func bytesAreAvaliable(count readCount: Int) async throws -> Bool {
        return true
    }
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type) async throws -> T {
        let data = try await self.readData(count: MemoryLayout<T>.size)
        return data.withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(as: T.self)
        }
    }
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type, byteOrder: ByteOrder = .bigEndian) async throws  -> T {
        guard MemoryLayout<T>.size <= remainingCount else {
            throw MP4Error.tooFewBytes
        }
        switch byteOrder {
        case .native:
            return try await self.readInteger(T.self)
        case .littleEndian:
            return try await T(littleEndian: self.readInteger(T.self))
        case .bigEndian:
            return try await T(bigEndian: self.readInteger(T.self))
        }
    }
    
    func readInteger() async throws -> UInt8 {
        try await self.readInteger(UInt8.self)
    }
    
    func readInteger() async throws -> Int8 {
        try await self.readInteger(Int8.self)
    }
    
    func readInteger<T: FixedWidthInteger>(byteOrder: ByteOrder) async throws -> T {
        try await self.readInteger(T.self, byteOrder: byteOrder)
    }
}

// MARK: Fixed Point
public extension MP4Reader {
    func readFixedPoint<T: FixedWidthInteger & UnsignedInteger>(underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws -> Double {
        let underlyingInteger: T = try await self.readInteger(byteOrder: byteOrder)
        return Double(fixedPoint: underlyingInteger, fractionBits: fractionBits)
    }
}

// MARK: Date
public extension MP4Reader {
    func readDate<T: FixedWidthInteger>(_ type: T.Type, referenceDate: Date = .mp4ReferenceDate) async throws -> Date {
        Date(timeInterval: TimeInterval(try await readInteger(T.self, byteOrder: .bigEndian)),
             since: referenceDate)
    }
}

// MARK: Flags
public extension MP4Reader {
    func readBoxFlags() async throws -> MP4BoxFlags {
        return try await .init(readFrom: self)
    }
}

// MARK: Data & String
public extension MP4Reader {
    
    func readAllData() async throws -> Data {
        try await self.readData(count: self.remainingCount)
    }
    
    func readData(byteRange: Range<Int>) async throws -> Data {
        let currentOffset = offset
        offset = byteRange.lowerBound
        defer { offset = currentOffset }
        return try await self.readData(count: byteRange.count)
    }
    
    func readString(byteCount: Int, encoding: String.Encoding, dropLengthPrefix: Bool = false) async throws -> String? {
        var byteCount = byteCount
        if dropLengthPrefix {
            try await self.prepareToRead(count: byteCount)
            let length: Int8 = try await self.readInteger()
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
public extension MP4Reader {
    
    
    func printBytes(count printCount: Int? = nil, mode: DataDebugFormatMode = .ascii, grouping: Int = 4) async throws  {
        let startOffset = self.offset
        let printCount = min(printCount ?? self.remainingCount, self.remainingCount)
        let data = try await self.readData(count: printCount)
        self.offset = startOffset
        print(data.debugString(mode: mode, grouping: grouping))
    }
}

public extension MP4Reader {
    
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
        
        guard let typeName = try await self.readString(byteCount: 4, encoding: .ascii) else {
            throw MP4Error.failedToParseBox(description: "Failed to read FourCC")
        }
        guard typeName.allSatisfy({$0.isASCII && ($0.isLetter || $0.isNumber)}) else {
            throw MP4Error.failedToParseBox(description: "FourCC `\(typeName)` is not ascii")
        }
        
        if size == 1 {
            size = Int(try await self.readInteger(UInt64.self, byteOrder: .bigEndian))
        }
        
        let remainingSizeOfBox = size - (self.offset - startOffset)
        
        guard remainingSizeOfBox <= self.remainingCount else {
            throw MP4Error.failedToParseBox(description: "Box size invalid (below 8 or larger than parent box)")
        }
        
        return try await readBoxContent(boxTypeMap: boxTypeMap, typeName: typeName, size: size, contentOffset: self.offset - startOffset)
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
    
    private func readBoxContent(boxTypeMap: MP4BoxTypeMap, typeName: String, size: Int, contentOffset: Int) async throws -> any MP4Box {
        
        let contentReader: MP4SubrangeReader = try .init(wrappedReader: self,
                                                         limit: min(size - contentOffset, self.remainingCount))
        
        var result: any MP4Box
        
        do {
            if let boxType = boxTypeMap.boxType(for: typeName) {
                try await self.prepareToRead(count: min(contentReader.remainingCount + 16, self.remainingCount))
                
                result = try await boxType.init(reader: contentReader)
                if contentReader.remainingCount != 0 {
                    try await contentReader.printBytes()
                }
                
                if self.strict && contentReader.remainingCount > 0 {
                    // TODO: We could do something about that in the future
                    throw MP4Error.failedToParseBox(description: "Did not parse \(contentReader.remainingCount) bytes at the end of the box.")
                }
                
            } else if self.strict && MP4BoxTypeMap.knownContainerTypes.contains(typeName) {
                result = try await MP4SimpleContainerBox(typeName: typeName, reader: contentReader)
            } else if !self.strict, let containerBox = try? await MP4SimpleContainerBox(typeName: typeName, reader: contentReader) {
                result = containerBox
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
