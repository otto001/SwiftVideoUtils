//
//  DoubleFixedWidthTests.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import XCTest

@testable import SwiftVideoUtils

final class DoubleFixedWidthTests: XCTestCase {

    func assert<T: FixedWidthInteger & UnsignedInteger>(value: Double, type: T.Type, maxFractionBytes: Int, assertThrows: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        
        for fractionBits in 0..<MemoryLayout<T>.size*8 {
            let accuracy: Double = 1.0/pow(2.0, Double(fractionBits))
            var fixedPoint: T? = nil
            
            if fractionBits <= maxFractionBytes {
                XCTAssertNoThrow(fixedPoint = try value.fixedPoint(fractionBits: fractionBits),
                                 "threw error for value \(value) with fractionBits \(fractionBits)", file: file, line: line)
                
                if let fixedPoint = fixedPoint {
                    let reEncoded = Double(fixedPoint: fixedPoint, fractionBits: fractionBits)
                    
                    XCTAssertEqual(value, reEncoded, accuracy: accuracy, file: file, line: line)
                }
            } else if assertThrows {
                XCTAssertThrowsError(fixedPoint = try value.fixedPoint(fractionBits: fractionBits), file: file, line: line) { error in
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
    
    func testFixedWidthDecodeEncode() throws {
        

        assert(value: 0, type: UInt32.self, maxFractionBytes: 31)

        for frac in 2...100 {
            assert(value: 1.0/Double(frac), type: UInt32.self, maxFractionBytes: 32)
            assert(value: 1.0/Double(frac), type: UInt64.self, maxFractionBytes: 64)
            
            assert(value: -1.0/Double(frac), type: UInt32.self, maxFractionBytes: 32)
            assert(value: -1.0/Double(frac), type: UInt64.self, maxFractionBytes: 64)
        }
        
        for frac in 4...100 {
            assert(value: Double.pi/Double(frac), type: UInt32.self, maxFractionBytes: 31)
            assert(value: Double.pi/Double(frac), type: UInt64.self, maxFractionBytes: 63)
            
            assert(value: -Double.pi/Double(frac), type: UInt32.self, maxFractionBytes: 31)
            assert(value: -Double.pi/Double(frac), type: UInt64.self, maxFractionBytes: 63)
        }
        
        for exp in 1...64 {
            assert(value: pow(2, Double(exp)), type: UInt32.self, maxFractionBytes: 32-2-exp)
            assert(value: pow(2, Double(exp)), type: UInt64.self, maxFractionBytes: 64-2-exp)
            
            assert(value: -pow(2, Double(exp)), type: UInt32.self, maxFractionBytes: 32-2-exp)
            assert(value: -pow(2, Double(exp)), type: UInt64.self, maxFractionBytes: 64-2-exp)
        }
        
        for exp in 1...8 {
            assert(value: pow(10, Double(exp)), type: UInt32.self, maxFractionBytes: 4, assertThrows: false)
            assert(value: -pow(10, Double(exp)), type: UInt32.self, maxFractionBytes: 4, assertThrows: false)
        }
        
        for exp in 1...12 {
            assert(value: pow(10, Double(exp)), type: UInt64.self, maxFractionBytes: 12, assertThrows: false)
            assert(value: -pow(10, Double(exp)), type: UInt64.self, maxFractionBytes: 12, assertThrows: false)
        }

    }
}
