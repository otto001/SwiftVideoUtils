//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation
import CoreGraphics

public struct MP4TransformationMatrix {
    public var a: Double
    public var b: Double
    public var c: Double
    public var d: Double
    
    public var x: Double
    public var y: Double
    
    public var u: Double
    public var v: Double
    public var w: Double
    
    public init(a: Double, b: Double, c: Double, d: Double, x: Double, y: Double, u: Double, v: Double, w: Double) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.x = x
        self.y = y
        self.u = u
        self.v = v
        self.w = w
    }
    
    public init(reader: any MP4Reader) async throws {
        self.a = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.b = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.u = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        let x1: UInt16 = try await reader.readInteger(byteOrder: .bigEndian)
        let x2: UInt16 = try await reader.readInteger(byteOrder: .bigEndian)
        reader.offset -= 4
        print(x1, x2)
        self.c = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.d = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.v = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        self.x = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.y = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.w = try await reader.readFixedPoint(underlyingType: UInt32.self, fractionBits: 30, byteOrder: .bigEndian)
    }
    
    public var affineTransform: CGAffineTransform {
        get {
            .init(CGFloat(a), CGFloat(b), CGFloat(c), CGFloat(d), CGFloat(x), CGFloat(y))
        }
        set {
            a = newValue.a
            b = newValue.b
            c = newValue.c
            d = newValue.d
            x = newValue.tx
            y = newValue.ty
            
            u = 0
            v = 0
            w = 0
        }
    }
    
    public var exifOrientation: ExifOrientation? {
        return .init(matrix: self)
    }
}

extension MP4TransformationMatrix: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(fixedPoint: a, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: b, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: u, UInt32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        try await writer.write(fixedPoint: c, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: d, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: v, UInt32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        try await writer.write(fixedPoint: x, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: y, UInt32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: w, UInt32.self, fractionBits: 30, byteOrder: .bigEndian)
    }
}

extension MP4TransformationMatrix: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(format: "%.3f  %.3f  %.3f\n%.3f  %.3f  %.3f\n%.3f  %.3f  %.3f", a, b, u, c, d, v, x, y, w)
    }
}
