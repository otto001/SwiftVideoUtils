//
//  MP4PartionedBuffer.swift
//
//
//  Created by Matteo Ludwig on 22.11.23.
//

import Foundation


public struct MP4PartionedBuffer {
    private var ranges: [Range<Int>] = []
    private var dataArray: [Data] = []
    
    private func partitionIndex(for offset: Int) -> Int {
        for (index, range) in ranges.enumerated() {
            if range.upperBound > offset{
                return index
            }
        }
        return ranges.endIndex
    }
    
    @discardableResult
    mutating private func mergeRight(index left: Int) -> Bool {
        guard left < ranges.endIndex - 1 else { return false }
        let right = left+1
        let leftRange = ranges[left]
        let rightRange = ranges[right]
        guard leftRange.upperBound >= rightRange.lowerBound else { return false }
        
        if rightRange.upperBound > leftRange.upperBound {
            ranges[left] = leftRange.lowerBound..<rightRange.upperBound
            dataArray[left].append(contentsOf: dataArray[right][leftRange.upperBound - rightRange.lowerBound..<rightRange.count])
        } else {
            
        }
        ranges.remove(at: right)
        dataArray.remove(at: right)
        
        return true
    }
    
    public mutating func insert(data newData: Data, at offset: Int) {
        let newRange = offset..<offset+newData.count
        
        if let insertionIndex = ranges.lastIndex(where: { $0.lowerBound <= offset }) {
            dataArray.insert(newData, at: insertionIndex + 1)
            ranges.insert(newRange, at: insertionIndex + 1)
            
            while self.mergeRight(index: insertionIndex+1) {}
            while self.mergeRight(index: insertionIndex) {}
        } else {
            ranges.append(newRange)
            dataArray.append(newData)
            
            if ranges.count >= 2 {
                while self.mergeRight(index: ranges.count-2) {}
            }
        }
    }
    
    private func get(range: Range<Int>) -> Data? {
        let index = partitionIndex(for: range.lowerBound)
        guard index < ranges.endIndex else { return nil }
        let bufferedRange = ranges[index]
        guard bufferedRange.lowerBound <= range.lowerBound && bufferedRange.upperBound >= range.upperBound else { return nil }
        
        let subRange = range.lowerBound - bufferedRange.lowerBound..<range.upperBound - bufferedRange.lowerBound
        return dataArray[index][subRange]
    }
    
    public func contains(range: Range<Int>) -> Bool {
        let index = partitionIndex(for: range.lowerBound)
        guard index < ranges.endIndex else { return false }
        let bufferedRange = ranges[index]
        guard bufferedRange.lowerBound <= range.lowerBound && bufferedRange.upperBound >= range.upperBound else { return false }
        return true
    }
    
    public subscript(range: Range<Int>) -> Data? {
        get {
            get(range: range)
        }
    }
    
    public func upperBound(for index: Int) -> Int? {
        let pi = partitionIndex(for: index)
        guard pi < ranges.endIndex else { return nil }
        guard ranges[pi].lowerBound <= index && index < ranges[pi].upperBound else { return nil }
        return ranges[pi].upperBound
    }
}
