//
//  MP4FileTypeBox.swift
//  
//
//  Created by Matteo Ludwig on 26.11.23.
//

import Foundation


public class MP4FileTypeBox: MP4ParsableBox {
    public static let typeName: String = "ftyp"
    public static let fullyParsable: Bool = true
    
    public var majorBrand: String
    public var minorBrand: UInt32
    public var compatibleBrands: [String]
    
    
    required public init(reader: any MP4Reader) async throws {
        self.majorBrand = try await reader.readString(byteCount: 4, encoding: .ascii)!
        self.minorBrand = try await reader.readInteger(byteOrder: .bigEndian)
        self.compatibleBrands = []
        
        while reader.remainingCount > 4 {
            self.compatibleBrands.append(try await reader.readString(byteCount: 4, encoding: .ascii)!)
        }
    }
}

