//
//  MP4Index.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public struct MP4Index<T: BinaryInteger> {
    
    /// Always starts at 0
    private var inner: T
    
    /// Index representation starting at 0
    public var index0: T { inner }
    /// Index representation starting at 1
    public var index1: T { inner + 1 }
    
    public init(index0: T) {
        self.inner = index0
    }
    
    public init(index1: T) {
        self.inner = index1 - 1
    }
}

extension MP4Index: Equatable {
    public static func == (lhs: MP4Index<T>, rhs: MP4Index<T>) -> Bool {
        lhs.index0 == rhs.index0
    }
}

extension MP4Index: Comparable {
    public static func < (lhs: MP4Index<T>, rhs: MP4Index<T>) -> Bool {
        lhs.index0 < rhs.index0
    }
}

extension MP4Index: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(index0)
    }
}

extension MP4Index: AdditiveArithmetic {
    public static var zero: Self {
        .init(index0: 0)
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(index0: lhs.inner + rhs.inner)
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(index0: lhs.inner - rhs.inner)
    }
    
    public static func += (lhs: inout Self, rhs: Self) {
        lhs.inner += rhs.inner
    }
    
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.inner -= rhs.inner
    }
    
    public static func + (lhs: Self, rhs: T) -> Self {
        .init(index0: lhs.index0 + rhs)
    }
    
    public static func - (lhs: Self, rhs: T) -> Self {
        .init(index0: lhs.index0 - rhs)
    }
    
    public static func += (lhs: inout Self, rhs: T) {
        lhs.inner += rhs
    }
    
    public static func -= (lhs: inout Self, rhs: T) {
        lhs.inner -= rhs
    }
}

extension MP4Index: Strideable {
    public func advanced(by n: Int) -> Self {
        return .init(index0: T(Int(index0) + n))
    }


    public func distance(to other: Self) -> Int {
        return Int(other.inner) - Int(inner)
    }
}

public extension RandomAccessCollection where Index == Int {
    subscript<T: BinaryInteger>(position: MP4Index<T>) -> Self.Element {
        self[Int(position.index0)]
    }
    
    func contains<T: BinaryInteger>(index: MP4Index<T>) -> Bool {
        startIndex <= Int(index.index0) && Int(index.index0) <= endIndex
    }
}

