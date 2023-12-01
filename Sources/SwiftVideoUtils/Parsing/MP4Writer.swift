//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation

public protocol MP4Writeable {
    func write(to writer: any MP4Writer) async throws
}

public protocol MP4Writer {
    var count: Int { get }
    var offset: Int { get }
    func write(_ data: Data) async throws
    func write<T: FixedWidthInteger>(_ integer: T, byteOrder: ByteOrder) async throws
    func write<T: FixedWidthInteger>(_ date: Date, referenceDate: Date, _ type: T.Type, byteOrder: ByteOrder) async throws
    func write(_ writeable: any MP4Writeable) async throws
}

public extension MP4Writer {
    func write<T: FixedWidthInteger>(_ integer: T, byteOrder: ByteOrder) async throws {
        let value: T
        switch byteOrder {
        case .littleEndian:
            value = integer.littleEndian
        case .bigEndian:
            value = integer.bigEndian
        case .native:
            value = integer
        }
        
        try await self.write(value.data)
    }
    
    func write(_ integer: UInt8) async throws {
        try await write(integer, byteOrder: .native)
    }
    
    func write(_ integer: Int8) async throws {
        try await write(integer, byteOrder: .native)
    }
    
    func write(_ string: String, encoding: String.Encoding, length: Int? = nil) async throws {
        guard var data = string.data(using: encoding) else {
            throw MP4Error.stringEncodingError
        }
        
        if let length = length {
            if data.count > length {
                data = data[..<length]
            } else if data.count < length {
                data.append(Data(repeating: 0, count: length - data.count))
            }
        }
        
        try await self.write(data)
    }
    
    func write<T: FixedWidthInteger>(_ date: Date, referenceDate: Date = .mp4ReferenceDate, _ type: T.Type, byteOrder: ByteOrder) async throws {
        let timeInterval = date.timeIntervalSince(referenceDate)
        try await write(T(timeInterval), byteOrder: byteOrder)
    }
    
    func write(_ writeable: any MP4Writeable) async throws {
        try await writeable.write(to: self)
    }
    
    func write(_ writeables: [any MP4Writeable]) async throws {
        for writeable in writeables {
            try await write(writeable)
        }
    }
    
    func write<T: FixedWidthInteger>(fixedPoint value: Double, _ underlyingType: T.Type, fractionBits: Int, byteOrder: ByteOrder) async throws {
        let integer: T = value.fixedPoint(fractionBits: fractionBits)
        try await self.write(integer, byteOrder: byteOrder)
    }
}

public class MP4BufferWriter: MP4Writer {
    public private(set) var data: Data = .init()
    
    public var count: Int { data.count }
    public var offset: Int { data.endIndex }
    
    public func write(_ data: Data) async throws {
        self.data.append(contentsOf: data)
    }
    
}

public class MP4BoxSerializer {
    let writer: any MP4Writer
    
    init(writer: any MP4Writer) {
        self.writer = writer
    }
    
    public func write<Box: MP4Box>(_ box: Box) async throws {
        if let parsableBox = box as? MP4ParsableBox {
            let contentWriter = MP4BufferWriter()
            try await parsableBox.write(to: contentWriter)
            
            let boxSize = contentWriter.data.count
            
            if boxSize <= UInt32.max {
                try await self.writer.write(UInt32(boxSize), byteOrder: .bigEndian)
            } else {
                try await self.writer.write(UInt32(1), byteOrder: .bigEndian)
            }
            
            try await self.writer.write(parsableBox.typeName, encoding: .ascii, length: 4)
            
            if boxSize > UInt32.max {
                try await self.writer.write(UInt64(boxSize), byteOrder: .bigEndian)
            }
            
            try await self.writer.write(contentWriter.data)
        }
    }
}
