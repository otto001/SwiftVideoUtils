//
//  FixedWidthNumberTests.swift
//
//
//  Created by Matteo Ludwig on 01.12.23.
//

import XCTest

@testable import SwiftVideoUtils

final class FixedWidthNumberTests: XCTestCase {

    func assertSigned<T: FixedWidthInteger & SignedInteger>(value: Double, type: T.Type, maxFractionBytes: Int, assertThrows: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        
        for fractionBits in 0..<MemoryLayout<T>.size*8-1 {
            let accuracy: Double = 1.0/pow(2.0, Double(fractionBits))
            var fixedPoint: FixedPointNumber<T>? = nil
            
            if fractionBits <= maxFractionBytes {
                XCTAssertNoThrow(fixedPoint = try FixedPointNumber(value, fractionBits: UInt8(fractionBits)),
                                 "threw error for value \(value) with fractionBits \(fractionBits)", file: file, line: line)
                
                if let fixedPoint = fixedPoint {
                    let reEncoded = fixedPoint.double
                    
                    XCTAssertEqual(value, reEncoded, accuracy: accuracy, file: file, line: line)
                }
            } else if assertThrows {
                XCTAssertThrowsError(fixedPoint = try FixedPointNumber(value, fractionBits:  UInt8(fractionBits)), file: file, line: line) { error in
                    switch error {
                    case MP4Error.fixedPointOverflow:
                        break
                    default:
                        XCTAssertTrue(false, "Wrong type of error thrown in fixed point overflow", file: file, line: line)
                    }
                }
            }
        }
    }
    
    func assertUnsigned<T: FixedWidthInteger & UnsignedInteger>(value: Double, type: T.Type, maxFractionBytes: Int, assertThrows: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        
        for fractionBits in 0..<MemoryLayout<T>.size*8 {
            let accuracy: Double = 1.0/pow(2.0, Double(fractionBits))
            var fixedPoint: FixedPointNumber<T>? = nil
            
            if fractionBits <= maxFractionBytes {
                XCTAssertNoThrow(fixedPoint = try FixedPointNumber(value, fractionBits:  UInt8(fractionBits)),
                                 "threw error for value \(value) with fractionBits \(fractionBits)", file: file, line: line)
                
                if let fixedPoint = fixedPoint {
                    let reEncoded = fixedPoint.double
                    
                    XCTAssertEqual(value, reEncoded, accuracy: accuracy, file: file, line: line)
                }
            } else if assertThrows {
                XCTAssertThrowsError(fixedPoint = try FixedPointNumber(value, fractionBits:  UInt8(fractionBits)), "did not throw error for value \(value) with fractionBits \(fractionBits)", file: file, line: line) { error in
                    switch error {
                    case MP4Error.fixedPointOverflow:
                        break
                    default:
                        XCTAssertTrue(false, "Wrong type of error thrown in fixed point overflow", file: file, line: line)
                    }
                }
            }
        }
    }
    
    func testSignedFixedWidth() throws {
        assertSigned(value: 0, type: Int32.self, maxFractionBytes: 30)
        
        assertSigned(value: 1, type: Int32.self, maxFractionBytes: 30)
        assertSigned(value: -1, type: Int32.self, maxFractionBytes: 30)
        
        assertSigned(value: 0.5, type: Int32.self, maxFractionBytes: 31)
        assertSigned(value: -0.5, type: Int32.self, maxFractionBytes: 31)

        for frac in 2...100 {
            assertSigned(value: 1.0/Double(frac), type: Int32.self, maxFractionBytes: 32)
            assertSigned(value: 1.0/Double(frac), type: Int64.self, maxFractionBytes: 64)
            
            assertSigned(value: -1.0/Double(frac), type: Int32.self, maxFractionBytes: 32)
            assertSigned(value: -1.0/Double(frac), type: Int64.self, maxFractionBytes: 64)
        }
        
        for frac in 4...100 {
            assertSigned(value: Double.pi/Double(frac), type: Int32.self, maxFractionBytes: 31)
            assertSigned(value: Double.pi/Double(frac), type: Int64.self, maxFractionBytes: 63)
            
            assertSigned(value: -Double.pi/Double(frac), type: Int32.self, maxFractionBytes: 31)
            assertSigned(value: -Double.pi/Double(frac), type: Int64.self, maxFractionBytes: 63)
        }
        
        for exp in 1...64 {
            assertSigned(value: pow(2, Double(exp)), type: Int32.self, maxFractionBytes: 32-2-exp)
            assertSigned(value: pow(2, Double(exp)), type: Int64.self, maxFractionBytes: 64-2-exp)
            
            assertSigned(value: -pow(2, Double(exp)), type: Int32.self, maxFractionBytes: 32-1-exp)
            assertSigned(value: -pow(2, Double(exp)), type: Int64.self, maxFractionBytes: 64-1-exp)
        }
        
        for exp in 1...8 {
            assertSigned(value: pow(10, Double(exp)), type: Int32.self, maxFractionBytes: 4, assertThrows: false)
            assertSigned(value: -pow(10, Double(exp)), type: Int32.self, maxFractionBytes: 4, assertThrows: false)
        }
        
        for exp in 1...12 {
            assertSigned(value: pow(10, Double(exp)), type: Int64.self, maxFractionBytes: 12, assertThrows: false)
            assertSigned(value: -pow(10, Double(exp)), type: Int64.self, maxFractionBytes: 12, assertThrows: false)
        }

    }
    
    func testUnsignedFixedWidth() throws {
        assertUnsigned(value: 0, type: UInt32.self, maxFractionBytes: 32)
        
        assertUnsigned(value: 1, type: UInt32.self, maxFractionBytes: 31)
        
        assertUnsigned(value: 0.5, type: UInt32.self, maxFractionBytes: 32)

        for frac in 2...100 {
            assertUnsigned(value: 1.0/Double(frac), type: UInt32.self, maxFractionBytes: 32)
            assertUnsigned(value: 1.0/Double(frac), type: UInt64.self, maxFractionBytes: 64)
        }
        
        for frac in 4...100 {
            assertUnsigned(value: Double.pi/Double(frac), type: UInt32.self, maxFractionBytes: 31)
            assertUnsigned(value: Double.pi/Double(frac), type: UInt64.self, maxFractionBytes: 63)
            
        }
        
        for exp in 1...64 {
            assertUnsigned(value: pow(2, Double(exp)), type: UInt32.self, maxFractionBytes: 32-1-exp)
            assertUnsigned(value: pow(2, Double(exp)), type: UInt64.self, maxFractionBytes: 64-1-exp)
        }
        
        for exp in 1...8 {
            assertUnsigned(value: pow(10, Double(exp)), type: UInt32.self, maxFractionBytes: 4, assertThrows: false)
        }
        
        for exp in 1...12 {
            assertUnsigned(value: pow(10, Double(exp)), type: UInt64.self, maxFractionBytes: 12, assertThrows: false)
        }

    }
}
