//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation

extension Int {
    init(int8: Int8) {
        self = .init(int8)
    }
    
    init(uint8: UInt8) {
        self = .init(uint8)
    }
    
    init(int16: Int16) {
        self = .init(int16)
    }
    
    init(uint16: UInt16) {
        self = .init(uint16)
    }
    
    init(int32: Int32) {
        self = .init(int32)
    }
    
    init(uint32: UInt32) {
        self = .init(uint32)
    }
    
    init(int64: Int64) {
        self = .init(int64)
    }
    
    init(uint64: UInt64) {
        self = .init(uint64)
    }
}


extension Data {
    func asFixedInteger<T: FixedWidthInteger>() -> T {
        withUnsafeBytes { rawBuffer in
            rawBuffer.loadUnaligned(as: T.self)
        }
    }
    
    func asFixedInteger<T: FixedWidthInteger>(byteOrder: ByteOrder) -> T {
        switch byteOrder {
        case .native:
            return asFixedInteger()
        case .littleEndian:
            return T(littleEndian: asFixedInteger())
        case .bigEndian:
            return T(bigEndian: asFixedInteger())
        }
    }
    
    func asInteger(byteOrder: ByteOrder, signed: Bool) -> Int? {
        switch count {
        case 1:
            if signed {
                return Int(int8: asFixedInteger(byteOrder: byteOrder))
            } else {
                return Int(uint8: asFixedInteger(byteOrder: byteOrder))
            }
        case 2:
            if signed {
                return Int(int16: asFixedInteger(byteOrder: byteOrder))
            } else {
                return Int(uint16: asFixedInteger(byteOrder: byteOrder))
            }
        case 4:
            if signed {
                return Int(int32: asFixedInteger(byteOrder: byteOrder))
            } else {
                return Int(uint32: asFixedInteger(byteOrder: byteOrder))
            }
        case 8:
            if signed {
                return Int(int64: asFixedInteger(byteOrder: byteOrder))
            } else {
                return Int(uint64: asFixedInteger(byteOrder: byteOrder))
            }
        default:
            return nil
        }
        
    }
}
