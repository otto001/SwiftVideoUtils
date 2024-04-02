//
//  MP4BoxVersion.swift
//  
//
//  Created by Matteo Ludwig on 28.12.23.
//

import Foundation


public struct MP4BoxVersion: MP4Readable, MP4Writeable, Equatable {
    var version: UInt8
    var fileType: MP4IOContext.FileType?
    
    public init(_ version: UInt8, fileType: MP4IOContext.FileType? = nil) {
        self.version = version
        self.fileType = fileType
    }
    
    public init(readingFrom reader: MP4SequentialReader) async throws {
        self.version = try await reader.read()
    }
   
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(version)
    }
    
    public var overestimatedByteSize: Int {
        1
    }
    
    static func isoMp4(_ version: UInt8) -> MP4BoxVersion {
        .init(version, fileType: .isoMp4)
    }
    
    static func quicktime(_ version: UInt8) -> MP4BoxVersion {
        .init(version, fileType: .quicktime)
    }
}
