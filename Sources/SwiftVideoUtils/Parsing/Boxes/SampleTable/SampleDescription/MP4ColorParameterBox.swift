//
//  MP4ColorParameterBox.swift
//
//
//  Created by Matteo Ludwig on 28.11.23.
//

import Foundation
import CoreVideo


public class MP4ColorParameterBox: MP4ParsableBox {
    public static let typeName: String = "colr"
    public static let fullyParsable: Bool = true
    
    public var colorParameterType: String
    
    public var primariesIndex: UInt16
    public var transferFunctionIndex: UInt16
    public var matrixIndex: UInt16
    
    public required init(reader: any MP4Reader) async throws {
        self.colorParameterType = try await reader.readAscii(byteCount: 4)
        
        self.primariesIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.transferFunctionIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.matrixIndex = try await reader.readInteger(byteOrder: .bigEndian)
    }
    
    var colorPrimaries: CFString? {
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
    
    var transferFunction: CFString? {
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
    
    var yCbCrMatrix: CFString? {
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
}
