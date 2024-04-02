//
//  MP4ColorParameterBox.swift
//
//
//  Created by Matteo Ludwig on 28.11.23.
//

import Foundation
import CoreVideo
import CoreMedia

public class MP4ColorParameterBox: MP4ConcreteBox {
    public static let typeName: MP4FourCC = "colr"
    public static let supportedChildBoxTypes: MP4BoxTypeMap = []
    public var children: [MP4Box] { [] }
    
    public var colorParameterType: String
    
    public var primariesIndex: UInt16
    public var transferFunctionIndex: UInt16
    public var matrixIndex: UInt16
    
    public var flags: UInt8?
    
    var fullRangeVideo: Bool? {
        get {
            flags.map { $0 & (1<<7) != 0 }
        }
        set {
            if let flags = flags, let newValue = newValue {
                if newValue {
                    self.flags = flags | (1<<7)
                } else {
                    self.flags = flags & ~(1<<7)
                }
            }
        }
    }
    
    public required init(contentReader reader: MP4SequentialReader) async throws {
        self.colorParameterType = try await reader.readAscii(byteCount: 4)
        
        self.primariesIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.transferFunctionIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.matrixIndex = try await reader.readInteger(byteOrder: .bigEndian)
        
        if reader.context.fileType == .isoMp4 {
            self.flags = try await reader.read()
        }
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(colorParameterType, encoding: .ascii, length: 4)
        
        try await writer.write(primariesIndex, byteOrder: .bigEndian)
        try await writer.write(transferFunctionIndex, byteOrder: .bigEndian)
        try await writer.write(matrixIndex, byteOrder: .bigEndian)
        
        if writer.context.fileType == .isoMp4 {
            try await writer.write(flags ?? 0)
        }
    }
    
    public var overestimatedContentByteSize: Int {
        4 + 7
    }
    
    public var colorPrimaries: CFString? {
        switch primariesIndex {
        case 1:
            return kCVImageBufferColorPrimaries_ITU_R_709_2
        case 9:
            return kCVImageBufferColorPrimaries_ITU_R_2020
        case 11:
            return kCVImageBufferColorPrimaries_DCI_P3
        case 12:
            return kCVImageBufferColorPrimaries_P3_D65
        default:
            return nil
        }
    }
    
    public var transferFunction: CFString? {
        switch transferFunctionIndex {
        case 1:
            return kCVImageBufferTransferFunction_ITU_R_709_2
        case 7:
            return kCVImageBufferTransferFunction_SMPTE_240M_1995
        case 17:
            return kCVImageBufferTransferFunction_SMPTE_ST_428_1
        default:
            return nil
        }
    }
    
    public var yCbCrMatrix: CFString? {
        switch matrixIndex {
        case 1:
            return kCVImageBufferYCbCrMatrix_ITU_R_709_2
        case 6:
            return kCVImageBufferYCbCrMatrix_ITU_R_601_4
        case 7:
            return kCVImageBufferYCbCrMatrix_SMPTE_240M_1995
        case 9:
            return kCVImageBufferYCbCrMatrix_ITU_R_2020
        default:
            return nil
        }
    }
    
    public func extensions(updating extensions: inout CMFormatDescription.Extensions) {
        if let primaries = colorPrimaries {
            extensions[.colorPrimaries] = .string(primaries)
        }
        if let transferFunction = transferFunction {
            extensions[.transferFunction] = .string(transferFunction)
        }
        if let yCbCrMatrix = yCbCrMatrix {
            extensions[.yCbCrMatrix] = .string(yCbCrMatrix)
        }
        if let fullRangeVideo = fullRangeVideo {
            extensions[.fullRangeVideo] = .number(fullRangeVideo ? 1 : 0)
        }
    }
}
