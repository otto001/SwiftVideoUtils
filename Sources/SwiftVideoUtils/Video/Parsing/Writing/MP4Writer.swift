//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation

public protocol MP4Writer {
    var count: Int { get }
    var offset: Int { get }
    
    var context: MP4IOContext { get }
    
    func write(_ data: Data) async throws
    
    func write(_ string: String, encoding: String.Encoding, length: Int?) async throws
    
    func write<T: FixedWidthInteger>(_ integer: T, byteOrder: ByteOrder) async throws
    
    func write<T: FixedWidthInteger>(_ date: Date, referenceDate: Date, _ type: T.Type, byteOrder: ByteOrder) async throws
    
    func write<T: FixedWidthInteger & SignedInteger>(_ value: FixedPointNumber<T>, byteOrder: ByteOrder) async throws
    func write<T: FixedWidthInteger & UnsignedInteger>(_ value: FixedPointNumber<T>, byteOrder: ByteOrder) async throws
    
    func write(_ writeable: any MP4Writeable) async throws
    func write(_ writeables: [any MP4Writeable]) async throws
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
    
    func write<T: FixedWidthInteger & SignedInteger>(_ value: FixedPointNumber<T>, byteOrder: ByteOrder) async throws {
        try await self.write(value.value, byteOrder: byteOrder)
    }
    
    func write<T: FixedWidthInteger & UnsignedInteger>(_ value: FixedPointNumber<T>, byteOrder: ByteOrder) async throws {
        try await self.write(value.value, byteOrder: byteOrder)
    }
}
