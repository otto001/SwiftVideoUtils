//
//  MP4VideoSampleEntryBox.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation
import CoreMedia


public class MP4VideoSampleEntryBox: MP4SampleEntryBox {
    public static let supportedFormats: [MP4FourCC] = ["avc1", "hvc1"]
    public static let supportedChildBoxTypes: MP4BoxTypeMap = [MP4ColorParameterBox.self]
    
    public var typeName: MP4FourCC
    
    public var reserved1: Data
    
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
    
    public var reserved2: UInt32
    
    public var framesPerSample: UInt16
    
    public var compressorName: String // 32-byte

    public var bitDepth: UInt16
    public var colorTableIndex: Int16
    
    public var children: [MP4Box]
    
    public var reserved3: Data
    
    required public init(format: MP4FourCC, contentReader reader: MP4SequentialReader) async throws {
        self.typeName = format
        
        self.reserved1 = try await reader.readData(count: 6)
        
        self.dataReferenceIndex = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.version = try await reader.readInteger(byteOrder: .bigEndian)
        self.revisionLevel = try await reader.readInteger(byteOrder: .bigEndian)
        self.vendor = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.temporalQuality = try await reader.readInteger(byteOrder: .bigEndian)
        self.spatialQuality = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.width = try await reader.readInteger(byteOrder: .bigEndian)
        self.height = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.horizontalResolution = try await reader.readInteger(byteOrder: .bigEndian)
        self.verticalResolution = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.reserved2 = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.framesPerSample = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.compressorName = try await reader.readAscii(byteCount: 32)

        self.bitDepth = try await reader.readInteger(byteOrder: .bigEndian)
        self.colorTableIndex = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.children = try await reader.readBoxes(boxTypeMap: Self.supportedChildBoxTypes)
        
        self.reserved3 = try await reader.readAllData()
    }

    public func writeContent(to writer: any MP4Writer) async throws {
        try await writer.write(reserved1)
        
        try await writer.write(dataReferenceIndex, byteOrder: .bigEndian)
        
        try await writer.write(version, byteOrder: .bigEndian)
        try await writer.write(revisionLevel, byteOrder: .bigEndian)
        try await writer.write(vendor, byteOrder: .bigEndian)
        
        try await writer.write(temporalQuality, byteOrder: .bigEndian)
        try await writer.write(spatialQuality, byteOrder: .bigEndian)
        
        try await writer.write(width, byteOrder: .bigEndian)
        try await writer.write(height, byteOrder: .bigEndian)
        
        try await writer.write(horizontalResolution, byteOrder: .bigEndian)
        try await writer.write(verticalResolution, byteOrder: .bigEndian)
        
        try await writer.write(reserved2, byteOrder: .bigEndian)
        
        try await writer.write(framesPerSample, byteOrder: .bigEndian)
        
        try await writer.write(compressorName, encoding: .ascii, length: 32)
        
        try await writer.write(bitDepth, byteOrder: .bigEndian)
        try await writer.write(colorTableIndex, byteOrder: .bigEndian)
        
        try await writer.write(children)
        
        try await writer.write(reserved3)
    }
}


extension MP4VideoSampleEntryBox {
    public var videoCodecType: CMFormatDescription.MediaSubType? {
        switch typeName {
        case "avc1":
            return .h264
        case "hvc1":
            return .hevc
        default:
            return nil
        }
    }
    
    public func makeFormatDescription() async throws -> CMFormatDescription {
        // TODO: Missing Extensions:
        // Do i need them all?
        // CVImageBufferChromaLocationBottomField, VerbatimISOSampleEntry, CVImageBufferChromaLocationTopField, CVFieldCount, CVPixelAspectRatio
        
        var extensions: CMFormatDescription.Extensions = .init()
        
        
        guard let videoCodecType = videoCodecType else {
            throw MP4Error.internalError("unknown format: \(typeName.description)")
        }
        
        switch videoCodecType {
        case .h264:
            extensions[.formatName] = .string("avc1")
            if let avcCBox = firstChild(ofType: "avcC") as? MP4SimpleDataBox {
                let sampleDescriptionExtensionAtoms: NSDictionary = [
                    "avcC": try await avcCBox.data as NSData
                ]
                extensions[.sampleDescriptionExtensionAtoms] = .init(sampleDescriptionExtensionAtoms)
            }
        case .hevc:
            extensions[.formatName] = .string("HEVC")
            if let avcCBox = firstChild(ofType: "hvcC") as? MP4SimpleDataBox {
                let sampleDescriptionExtensionAtoms: NSDictionary = [
                    "hvcC": try await avcCBox.data as NSData
                ]
                extensions[.sampleDescriptionExtensionAtoms] = .init(sampleDescriptionExtensionAtoms)
            }
        default:
            throw MP4Error.internalError("unknown format: \(typeName.description)")
        }
        
        
        extensions[.version] = .number(version)
        extensions[.revisionLevel] = .number(revisionLevel)
        extensions[.temporalQuality] = .number(temporalQuality)
        extensions[.spatialQuality] = .number(spatialQuality)
        extensions[.depth] = .number(bitDepth)


        firstChild(ofType: MP4ColorParameterBox.self)?.extensions(updating: &extensions)
        
        return try .init(videoCodecType: videoCodecType, width: Int(width), height: Int(height), extensions: extensions)
    }
}
