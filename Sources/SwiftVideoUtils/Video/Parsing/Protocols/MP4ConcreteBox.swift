//
//  MP4ConcreteBox.swift
//
//
//  Created by Matteo Ludwig on 29.12.23.
//

import Foundation


public protocol MP4ConcreteBox: MP4ParsableBox {
    static var typeName: MP4FourCC { get }
    static var supportedChildBoxTypes: MP4BoxTypeMap { get }
    
    init(contentReader: MP4SequentialReader) async throws
}

public extension MP4ConcreteBox {
    var typeName: MP4FourCC { Self.typeName }
    static var supportedTypeNames: [MP4FourCC] { [Self.typeName] }
    
    init(typeName: MP4FourCC, contentReader: MP4SequentialReader) async throws {
        try await self.init(contentReader: contentReader)
    }
}
