//
//  MP4ParsableBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation

public protocol MP4ParsableBox: MP4Box {
    static var supportedTypeNames: [MP4FourCC] { get }
    
    init(typeName: MP4FourCC, contentReader: MP4SequentialReader) async throws
}
