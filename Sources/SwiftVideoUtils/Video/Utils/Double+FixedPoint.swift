//
//  Double+FixedPoint.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation

extension Double {
    
    
    init<T: FixedWidthInteger & UnsignedInteger>(fixedPoint: T, fractionBits: Int) {
        let totalBits = 8 * MemoryLayout<T>.size
        assert(fractionBits <= totalBits, "Cannot have more than \(totalBits) fraction bits in an \(totalBits) integer")
        assert(fractionBits >= 0, "fractionBits may not be negative")
        
        let negative = (fixedPoint >> (totalBits-1)) == 1
        let fixedPoint = (negative ? ~fixedPoint : fixedPoint) + (negative ? 1 : 0)
        
        let integerPart = (fixedPoint >> fractionBits)
        let fractionPart = (fixedPoint << (totalBits-fractionBits)) >> (totalBits-fractionBits)

        self = (negative ? -1 : 1) * (Double(integerPart) + Double(fractionPart)/pow(2, Double(fractionBits)))
    }
    
    func fixedPoint<T: FixedWidthInteger & UnsignedInteger>(fractionBits: Int) throws -> T {
        let totalBits = 8 * MemoryLayout<T>.size
        
        assert(fractionBits < totalBits, "Cannot have more than \(totalBits-1) fraction bits in an \(totalBits) integer")
        assert(fractionBits >= 0, "fractionBits may not be negative")
        
        let absoluteSelf = abs(self)
        
        guard absoluteSelf < Double(T.max) else {
            throw MP4Error.fixedPointOverflow
        }
        
        let integerPart = T(absoluteSelf)
        let fraction = absoluteSelf - Double(integerPart)
        let fractionPart = T(fraction * pow(2, Double(fractionBits)))
        
        if integerPart >> (totalBits - fractionBits - 1) != 0 {
            throw MP4Error.fixedPointOverflow
        }

        let result: T = (integerPart << fractionBits) + fractionPart
        
        if self < 0 && result > 0 {
            return ~result + 1
        } else {
            return result
        }
    }
}
