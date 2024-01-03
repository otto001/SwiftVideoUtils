//
//  FixedPointNumber.swift
//
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation

public struct FixedPointNumber<T: FixedWidthInteger> {
    public var value: T
    public let fractionBits: UInt8
        
    public init(_ value: T, fractionBits: UInt8) {
        self.value = value
        self.fractionBits = fractionBits
    }
    
    public init(_ double: Double, fractionBits: UInt8) throws {
        let totalBits = 8 * MemoryLayout<T>.size
        
        assert(fractionBits <= totalBits, "Cannot have more than \(totalBits) fraction bits in an \(totalBits) integer")
        
        self.value = try Self.convert(double: double, fractionBits: fractionBits)
   
        self.fractionBits = fractionBits
    }
    
    private static func convert(double: Double, fractionBits: UInt8) throws -> T {
        let denominator = Double(T(1)<<fractionBits)
        assert(denominator > 0)
        let value = double * denominator
        if value >= Double(T.max) || value < Double(T.min) {
            throw MP4Error.fixedPointOverflow
        }
        return T(value)
    }
    
    public var double: Double {
        get {
            return Double(value)/Double(T(1)<<fractionBits)
        }
        set {
            self.value = try! Self.convert(double: newValue, fractionBits: fractionBits)
        }
    }
}

extension FixedPointNumber where T: SignedInteger {
    public static var maxFractionBits: Int {
        T.bitWidth - 1
    }
}

extension FixedPointNumber where T: UnsignedInteger {
    public static var maxFractionBits: Int {
        T.bitWidth
    }
}

//
//public struct FixedPointNumber<T: FixedWidthInteger & SignedInteger> {
//    public var value: T
//    public let fractionBits: Int
//    
//    public init(_ value: T, fractionBits: Int) {
//        self.value = value
//        self.fractionBits = fractionBits
//    }
//    
//    public init(_ double: Double, fractionBits: Int) throws {
//        let totalBits = 8 * MemoryLayout<T>.size
//        
//        assert(fractionBits < totalBits, "Cannot have more than \(totalBits-1) fraction bits in an \(totalBits) integer")
//        assert(fractionBits >= 0, "fractionBits may not be negative")
//        
//        self.value = try Self.convert(double: double, fractionBits: fractionBits)
//   
//        self.fractionBits = fractionBits
//    }
//    
//    private static func convert(double: Double, fractionBits: Int) throws -> T {
//        let value = double * Double(T(1)<<fractionBits)
//        if value >= Double(T.max) || value <= Double(T.min) {
//            throw MP4Error.fixedPointOverflow
//        }
//        return T(value)
//    }
//    
//    public var double: Double {
//        get {
//            return Double(value)/Double(T(1)<<fractionBits)
//        }
//        set {
//            self.value = try! Self.convert(double: newValue, fractionBits: fractionBits)
//        }
//    }
//}
//
//
//public struct FixedPointNumber<T: FixedWidthInteger & UnsignedInteger> {
//    public var value: T
//    public let fractionBits: Int
//    
//    public init(_ value: T, fractionBits: Int) {
//        self.value = value
//        self.fractionBits = fractionBits
//    }
//    
//    public init(_ double: Double, fractionBits: Int) throws {
//        let totalBits = 8 * MemoryLayout<T>.size
//        
//        assert(fractionBits <= totalBits, "Cannot have more than \(totalBits) fraction bits in an \(totalBits) integer")
//        assert(fractionBits >= 0, "fractionBits may not be negative")
//        
//        self.value = try Self.convert(double: double, fractionBits: fractionBits)
//   
//        self.fractionBits = fractionBits
//    }
//    
//    private static func convert(double: Double, fractionBits: Int) throws -> T {
//        let value = double * Double(T(1)<<fractionBits)
//        if value >= Double(T.max) {
//            throw MP4Error.fixedPointOverflow
//        }
//        return T(value)
//    }
//    
//    public var double: Double {
//        get {
//            return Double(value)/Double(T(1)<<fractionBits)
//        }
//        set {
//            self.value = try! Self.convert(double: newValue, fractionBits: fractionBits)
//        }
//    }
//}
