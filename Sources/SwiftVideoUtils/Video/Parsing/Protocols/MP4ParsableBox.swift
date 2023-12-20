//
//  MP4ParsableBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public protocol MP4ParsableBox: MP4Box {
    static var typeName: String { get }
    static var supportedChildBoxTypes: MP4BoxTypeMap { get }
    
    init(reader: any MP4Reader) async throws
}

public extension MP4ParsableBox {
    var typeName: String { Self.typeName }
}
