//
//  MP4BoxTypeMap.swift
//
//
//  Created by Matteo Ludwig on 20.12.23.
//

import Foundation


public struct MP4BoxTypeMap {
    public var parsableBoxTypeMap: [MP4FourCC: MP4ParsableBox.Type]
    
    public static var knownContainerTypes: Set<MP4FourCC> = .init([
//        "ctps",
//        "dinf",
//        "edts",
//        "gmhd",
//        "meta",
//        "sdpd",
//        "setu",
//        "tapt",
//        "tref",
//        "udta"
    ])
    
    
    
    public init(_ parsableBoxTypeMap: [MP4FourCC : MP4ParsableBox.Type]) {
        self.parsableBoxTypeMap = parsableBoxTypeMap
    }
    
    public init(_ boxTypes: [MP4ParsableBox.Type]) {
        self.parsableBoxTypeMap = Dictionary(uniqueKeysWithValues: boxTypes.map { ($0.typeName, $0) })
    }
    
    public func boxType(for typeName: MP4FourCC) -> MP4ParsableBox.Type? {
        self.parsableBoxTypeMap[typeName] //?? (Self.knownContainerTypes.contains(typeName) ? MP4SimpleContainerBox.self : MP4SimpleDataBox.self)
    }
}


extension MP4BoxTypeMap: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = MP4ParsableBox.Type
    
    public init(arrayLiteral elements: MP4ParsableBox.Type...) {
        self = .init(elements)
    }
}
