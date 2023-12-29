//
//  MP4BoxTypeMap.swift
//
//
//  Created by Matteo Ludwig on 20.12.23.
//

import Foundation


public struct MP4BoxTypeMap {
    public var parsableBoxTypeMap: [MP4FourCC: MP4ParsableBox.Type]
    
    public init(_ parsableBoxTypeMap: [MP4FourCC : MP4ParsableBox.Type]) {
        self.parsableBoxTypeMap = parsableBoxTypeMap
    }
    
    public init(_ boxTypes: [MP4ParsableBox.Type]) {
        self.parsableBoxTypeMap = Dictionary(uniqueKeysWithValues: boxTypes.flatMap { type in
            type.supportedTypeNames.map { typeName in
                (typeName, type.self)
            }
        })
    }
    
    public func boxType(for typeName: MP4FourCC) -> MP4ParsableBox.Type? {
        self.parsableBoxTypeMap[typeName]
    }
}


extension MP4BoxTypeMap: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = MP4ParsableBox.Type
    
    public init(arrayLiteral elements: MP4ParsableBox.Type...) {
        self = .init(elements)
    }
}
