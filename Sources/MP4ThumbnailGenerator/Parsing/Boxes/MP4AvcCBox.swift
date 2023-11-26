//
//  MP4AvcCBox.swift
//  
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public class MP4AvcCBox: MP4ParsableBox {
    public static let typeName: String = "avcC"
    public static let fullyParsable: Bool = true
    
    public var data: Data
    
    required public init(reader: any MP4Reader) async throws {
        self.data = try await reader.readAllData()
    }
}
