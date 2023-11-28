//
//  MP4HvcCBox.swift
//
//
//  Created by Matteo Ludwig on 26.11.23.
//

import Foundation


public class MP4HvcCBox: MP4ParsableBox {
    public static let typeName: String = "hvcC"
    public static let fullyParsable: Bool = true
    
    public var data: Data
    
    required public init(reader: any MP4Reader) async throws {
        self.data = try await reader.readAllData()
    }
}
