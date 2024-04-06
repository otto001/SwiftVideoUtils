//
//  MP4FileTypeBox.swift
//  
//
//  Created by Matteo Ludwig on 26.11.23.
//

import Foundation


public class MP4FileTypeBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "ftyp"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var readByteRange: Range<Int>?
    
    public var children: [MP4Box] { [] }
    
    public var majorBrand: String
    public var minorBrand: UInt32
    public var compatibleBrands: [String]
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.majorBrand = try await reader.readAscii(byteCount: 4)
        self.minorBrand = try await reader.readInteger(byteOrder: .bigEndian)
        self.compatibleBrands = []
        
        while reader.remainingCount >= 4 {
            self.compatibleBrands.append(try await reader.readAscii(byteCount: 4))
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(majorBrand, encoding: .ascii, length: 4)
        try await writer.write(minorBrand, byteOrder: .bigEndian)
        
        for compatibleBrand in compatibleBrands {
            try await writer.write(compatibleBrand, encoding: .ascii, length: 4)
        }
    }
    
    public var overestimatedContentByteSize: Int {
        8 + compatibleBrands.count * 4
    }
}

