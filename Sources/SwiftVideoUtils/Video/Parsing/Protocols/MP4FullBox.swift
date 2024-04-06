//
//  MP4FullBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public protocol MP4FullBox: MP4ConcreteBox {
    var version: MP4BoxVersion { get }
    var flags: MP4BoxFlags { get }
}

public extension MP4FullBox {
    var children: [MP4Box] { [] }
    static var supportedChildBoxTypes: MP4BoxTypeMap { [] }
}

public protocol MP4BoxProxy: MP4ParsableBox {
    var wrappedBox: any MP4ParsableBox { get }
}

public extension MP4BoxProxy {
    var typeName: MP4FourCC { wrappedBox.typeName }
    var children: [MP4Box] { wrappedBox.children }
    
    var readByteRange: Range<Int>? {
        get {
            wrappedBox.readByteRange
        }
        set {
            
        }
    }
    
    func writeContent(to writer: MP4Writer) async throws {
        try await wrappedBox.writeContent(to: writer)
    }
    
    var overestimatedContentByteSize: Int {
        wrappedBox.overestimatedContentByteSize
    }
    
    func write(to writer: MP4Writer) async throws {
        try await wrappedBox.write(to: writer)
    }
}


