//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 26.11.23.
//

import Foundation
import CoreMedia


public class MP4Hvc1Box: MP4ParsableBox {
    public static let typeName: String = "hvc1"
    public static let fullyParsable: Bool = true
    
    public var dataReferenceIndex: UInt16
    
    public var version: UInt16
    public var revisionLevel: UInt16
    public var vendor: UInt32
    public var temporalQuality: UInt32
    public var spatialQuality: UInt32
    
    public var width: UInt16
    public var height: UInt16
    
    public var horizontalResolution: UInt32
    public var verticalResolution: UInt32
    public var entryDataSize: UInt32
    
    public var framesPerSample: UInt16
    
    public var compressorName: String // 32-byte

    public var bitDepth: UInt16
    public var colorTableIndex: Int16
    
    public var children: [MP4Box]
    
    required public init(reader: any MP4Reader) async throws {
        // First 6 bytes are reserved
        reader.offset = 6

        self.dataReferenceIndex = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.version = try await reader.readInteger(byteOrder: .bigEndian)
        self.revisionLevel = try await reader.readInteger(byteOrder: .bigEndian)
        self.vendor = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.temporalQuality = try await reader.readInteger(byteOrder: .bigEndian)
        self.spatialQuality = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.width = try await reader.readInteger(byteOrder: .bigEndian)
        self.height = try await reader.readInteger(byteOrder: .bigEndian)
        
        // TODO: Is this resolution? check for video format
        self.horizontalResolution = try await reader.readInteger(byteOrder: .bigEndian)
        self.verticalResolution = try await reader.readInteger(byteOrder: .bigEndian)
        
        // TODO: what is this?
        self.entryDataSize = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.framesPerSample = try await reader.readInteger(byteOrder: .bigEndian)
        
        let compressorNameLength: UInt8 = try await reader.readInteger()
        self.compressorName = try await reader.readString(byteCount: Int(compressorNameLength), encoding: .ascii)!
        reader.offset += 32 - 1 - Int(compressorNameLength)

        self.bitDepth = try await reader.readInteger(byteOrder: .bigEndian)
        self.colorTableIndex = try await reader.readInteger(byteOrder: .bigEndian)
        
        assert(reader.offset == 78)
        self.children = try await MP4BoxParser(reader: reader).readBoxes()
    }

}


extension MP4Hvc1Box {
    public func makeFormatDescription() throws -> CMFormatDescription {
        // TODO: Missing Extensions:
        // Do i need them all?
        // CVImageBufferChromaLocationBottomField, VerbatimISOSampleEntry, CVImageBufferColorPrimaries, CVImageBufferChromaLocationTopField, CVFieldCount, CVPixelAspectRatio, FullRangeVideo, CVImageBufferYCbCrMatrix, CVImageBufferTransferFunction
        
        var extensions: CMFormatDescription.Extensions = .init()
        
        extensions[.formatName] = .string("HEVC")
        extensions[.version] = .number(version)
        extensions[.revisionLevel] = .number(revisionLevel)
        extensions[.temporalQuality] = .number(temporalQuality)
        extensions[.spatialQuality] = .number(spatialQuality)
        extensions[.depth] = .number(bitDepth)

        if let hvcCBox = firstChild(ofType: MP4HvcCBox.self) {
            let sampleDescriptionExtensionAtoms: NSDictionary = [
                "hvcC": hvcCBox.data as NSData
            ]
            extensions[.sampleDescriptionExtensionAtoms] = .init(sampleDescriptionExtensionAtoms)
        }
        
        return try .init(videoCodecType: .hevc, width: Int(width), height: Int(height), extensions: extensions)
    }
}
