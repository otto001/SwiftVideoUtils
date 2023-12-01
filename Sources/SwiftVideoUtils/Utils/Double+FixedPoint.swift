//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 30.11.23.
//

import Foundation


extension Double {
    
    init<T: FixedWidthInteger>(fixedPoint: T, fractionBits: Int) {
        let totalBits = 8 * MemoryLayout<T>.size
        assert(fractionBits <= totalBits, "Cannot have more than \(totalBits) fraction bits in an \(totalBits) integer")
        assert(fractionBits >= 0, "fractionBits may not be negative")
        let integerPart = fixedPoint >> fractionBits
        let fractionPart = (fixedPoint << (totalBits-fractionBits)) >> (totalBits-fractionBits)

        self = Double(integerPart) + Double(fractionPart)/pow(2, Double(fractionBits))
    }
    
    func fixedPoint<T: FixedWidthInteger>(fractionBits: Int) -> T {
        let totalBits = 8 * MemoryLayout<T>.size
        assert(fractionBits <= totalBits, "Cannot have more than \(totalBits) fraction bits in an \(totalBits) integer")
        assert(fractionBits >= 0, "fractionBits may not be negative")
        
        let integerPart = T(self)
        let fraction = self - Double(integerPart)
        let fractionPart = T(fraction * pow(2, Double(fractionBits)))
        
        let result = integerPart << fractionBits + fractionPart
        // TODO: remove assert
        assert(abs(Double(fixedPoint: result, fractionBits: fractionBits) - self) < 0.00001)
        return result
    }
}
