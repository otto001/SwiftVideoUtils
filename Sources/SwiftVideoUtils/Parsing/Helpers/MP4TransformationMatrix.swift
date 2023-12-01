//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation
import CoreGraphics

public struct MP4TransformationMatrix {
    var a: Double
    var b: Double
    var c: Double
    var d: Double
    
    var x: Double
    var y: Double
    
    var u: Double
    var v: Double
    var w: Double
    
    
//    (s_x cos(t) | s_x sin(t) | 0
//    h s_y cos(t) - s_y sin(t) | h s_y sin(t) + s_y cos(t) | 0
//    x | y | 1)
    
    /*                      |------------------ CGAffineTransformComponents ----------------|
     *
     *      | a  b  0 |     | sx  0  0 |   |  1  0  0 |   | cos(t)  sin(t)  0 |   | 1  0  0 |
     *      | c  d  0 |  =  |  0 sy  0 | * | sh  1  0 | * |-sin(t)  cos(t)  0 | * | 0  1  0 |
     *      | tx ty 1 |     |  0  0  1 |   |  0  0  1 |   |   0       0     1 |   | tx ty 1 |
     *  CGAffineTransform      scale           shear            rotation          translation
     *
     *
     *      | a  b  0 |     | sx * cos(t)                      sx * sin(t)                      0 |
     *      | c  d  0 |  =  | sh * sy * cos(t) - sy * sin(t)   sh * sy * sin(t) + sy * cos(t)   0 |
     *      | tx ty 1 |     | x                                y                                1 |
     *
     */
    
    
    init(a: Double, b: Double, c: Double, d: Double, x: Double, y: Double, u: Double, v: Double, w: Double) {
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
    
    init(reader: any MP4Reader) async throws {
        self.a = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.b = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.u = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        self.c = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.d = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.v = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        self.x = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.y = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        self.w = try await reader.readFixedPoint(underlyingType: Int32.self, fractionBits: 30, byteOrder: .bigEndian)
    }
    
    var affineTransform: CGAffineTransform {
        .init(CGFloat(a), CGFloat(b), CGFloat(c), CGFloat(d), CGFloat(x), CGFloat(y))
    }
}

extension MP4TransformationMatrix: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(fixedPoint: a, Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: b, Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: u, Int32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        try await writer.write(fixedPoint: c, Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: d, Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: v, Int32.self, fractionBits: 30, byteOrder: .bigEndian)
        
        try await writer.write(fixedPoint: x, Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: y, Int32.self, fractionBits: 16, byteOrder: .bigEndian)
        try await writer.write(fixedPoint: w, Int32.self, fractionBits: 30, byteOrder: .bigEndian)
    }
}

extension MP4TransformationMatrix: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(format: "%.3f  %.3f  %.3f\n%.3f  %.3f  %.3f\n%.3f  %.3f  %.3f", a, b, u, c, d, v, x, y, w)
    }
}
