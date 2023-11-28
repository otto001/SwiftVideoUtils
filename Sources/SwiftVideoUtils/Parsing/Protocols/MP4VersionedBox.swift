//
//  MP4LeafBox.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public protocol MP4VersionedBox: MP4ParsableBox {
    var version: UInt8 { get }
    var flags: MP4BoxFlags { get }
    
}

public extension MP4VersionedBox {
    var children: [MP4Box] { [] }
}

