//
//  MP4TransformationMatrix.swift
//
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation
import CoreGraphics

public struct MP4TransformationMatrix {
    public var a: FixedPointNumber<Int32>
    public var b: FixedPointNumber<Int32>
    public var c: FixedPointNumber<Int32>
    public var d: FixedPointNumber<Int32>
    
    public var x: FixedPointNumber<Int32>
    public var y: FixedPointNumber<Int32>
    
    public var u: FixedPointNumber<Int32>
    public var v: FixedPointNumber<Int32>
    public var w: FixedPointNumber<Int32>
    
    public init(a: FixedPointNumber<Int32>, b: FixedPointNumber<Int32>, c: FixedPointNumber<Int32>,
                d: FixedPointNumber<Int32>, x: FixedPointNumber<Int32>, y: FixedPointNumber<Int32>,
                u: FixedPointNumber<Int32>, v: FixedPointNumber<Int32>, w: FixedPointNumber<Int32>) {
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
    
    public init(reader: MP4SequentialReader) async throws {
        self.a = try await reader.readSignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        self.b = try await reader.readSignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        self.u = try await reader.readSignedFixedPoint(fractionBits: 30, byteOrder: .bigEndian)
        
        self.c = try await reader.readSignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        self.d = try await reader.readSignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        self.v = try await reader.readSignedFixedPoint(fractionBits: 30, byteOrder: .bigEndian)
        
        self.x = try await reader.readSignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        self.y = try await reader.readSignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        self.w = try await reader.readSignedFixedPoint(fractionBits: 30, byteOrder: .bigEndian)
    }
    
    public var affineTransform: CGAffineTransform {
        get {
            .init(CGFloat(a.double), CGFloat(b.double), CGFloat(c.double), CGFloat(d.double), CGFloat(x.double), CGFloat(y.double))
        }
        set {
            a.double = newValue.a
            b.double = newValue.b
            c.double = newValue.c
            d.double = newValue.d
            x.double = newValue.tx
            y.double = newValue.ty
            
            u.double = 0
            v.double = 0
            w.double = 0
        }
    }
    
    public var exifOrientation: ExifOrientation? {
        return .init(matrix: self)
    }
}

extension MP4TransformationMatrix: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(self.a, byteOrder: .bigEndian)
        try await writer.write(self.b, byteOrder: .bigEndian)
        try await writer.write(self.u, byteOrder: .bigEndian)
        
        try await writer.write(self.c, byteOrder: .bigEndian)
        try await writer.write(self.d, byteOrder: .bigEndian)
        try await writer.write(self.v, byteOrder: .bigEndian)
        
        try await writer.write(self.x, byteOrder: .bigEndian)
        try await writer.write(self.y, byteOrder: .bigEndian)
        try await writer.write(self.w, byteOrder: .bigEndian)
    }
    
    public var overestimatedByteSize: Int {
        return 36
    }
}

extension MP4TransformationMatrix: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(format: "%.3f  %.3f  %.3f\n%.3f  %.3f  %.3f\n%.3f  %.3f  %.3f", a.double, b.double, u.double, c.double, d.double, v.double, x.double, y.double, w.double)
    }
}
