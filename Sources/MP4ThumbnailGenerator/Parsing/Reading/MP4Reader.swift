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
    
    func prepareToRead(count readCount: Int) async throws
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type) async throws -> T
    
    func readData(count readCount: Int) async throws -> Data
}

// MARK: Integers
public extension MP4Reader {
    
    func prepareToRead(count readCount: Int) async throws {
        
    }
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type) async throws -> T {
        let data = try await self.readData(count: MemoryLayout<T>.size)
        return data.withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(as: T.self)
        }
    }
    
    func readInteger<T: FixedWidthInteger>(_ type: T.Type, byteOrder: ByteOrder = .bigEndian) async throws  -> T {
        assert(MemoryLayout<T>.size <= remainingCount)
        switch byteOrder {
        case .native:
            return try await self.readInteger(T.self)
        case .littleEndian:
            return try await T(littleEndian: self.readInteger(T.self))
        case .bigEndian:
            return try await T(bigEndian: self.readInteger(T.self))
        }
    }
    
    func readInteger<T: FixedWidthInteger>() async throws  -> T {
        try await self.readInteger(T.self)
    }
    
    func readInteger<T: FixedWidthInteger>(byteOrder: ByteOrder) async throws -> T {
        try await self.readInteger(T.self, byteOrder: byteOrder)
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
    
    func readString(byteCount: Int, encoding: String.Encoding) async throws -> String? {
        try await String(data: self.readData(count: byteCount), encoding: encoding)
    }
    
    func readString(end: Int, encoding: String.Encoding) async throws -> String? {
        try await String(data: self.readData(count: end - offset), encoding: encoding)
    }
}

public enum MP4PrintBytesMode {
    case ascii
    case hex
}


public extension MP4Reader {
    

    func printBytes(count printCount: Int? = nil, mode: MP4PrintBytesMode = .ascii) async throws  {
        let startOffset = self.offset
        let printCount = min(printCount ?? self.remainingCount, self.remainingCount)
        let groupCount = (printCount+3)/4
        
        var remainingToPrint = printCount
        
        try await self.prepareToRead(count: printCount)
        
        for i in 0..<groupCount {
            guard remainingToPrint > 0 && self.remainingCount > 0 else { break }
            
            var string: String
            
            let readCount = min(4, remainingToPrint)
            
            switch mode {
            case .ascii:
                string = try await self.readString(byteCount: readCount, encoding: .ascii)!.map {
                    if $0.asciiValue == 0 {
                        return "0"
                    } else if $0.isLetter || $0.isNumber {
                        return "\($0)"
                    } else {
                        return "."
                    }
                }.joined()
                
            case .hex:
                string = try await self.readData(count: readCount).withUnsafeBytes { rawBuffer in
                    rawBuffer.withMemoryRebound(to: UInt8.self) { buffer in
                        buffer.map { value in
                            String(value, radix: 16).padding(toLength: 2, withPad: " ", startingAt: 0)
                        }.joined(separator: " ")
                    }
                }
            }
            
            remainingToPrint -= readCount
            
            if i%2 == 0 {
                print("\(i*4)".padding(toLength: 3, withPad: " ", startingAt: 0), string, terminator: "\t")
            } else {
                print(string, terminator: "\n")
            }
        }
        
        if groupCount%2 != 0 {
            print()
        }
        
        self.offset = startOffset
    }
}
