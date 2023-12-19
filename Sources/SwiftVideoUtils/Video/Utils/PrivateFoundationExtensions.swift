//
//  PrivateFoundationExtensions.swift
//
//
//  Created by Matteo Ludwig on 19.12.23.
//

import Foundation


internal extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

internal extension String {
    func capture(pattern: String) -> [String] {
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let result = regex.firstMatch(in: self, range: NSRange(location: 0, length: count))
            else { return [] }
        return (0..<result.numberOfRanges).map { String(self[Range(result.range(at: $0), in: self)!]) }
    }
}

internal extension Array where Element == Range<Int> {
    func merged() -> Self {
        let sorted = self.sorted { a, b in
            a.lowerBound < b.lowerBound
        }
        var result = Self()
        for element in sorted {
            if let last = result.last, last.upperBound >= element.lowerBound {
                result[result.endIndex-1] = last.lowerBound..<Swift.max(last.upperBound, element.upperBound)
            } else {
                result.append(element)
            }
        }
        
        return result
    }
}
