//
//  ExifOrientation.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation


public enum ExifOrientation: Int16 {
    case identity = 1
    case rotate90deg = 6
    case rotate180deg = 3
    case rotate270deg = 8
    
    case mirror = 2
    case mirrorAndRotate90deg = 5
    case mirrorAndRotate180deg = 4
    case mirrorAndRotate270deg = 7
}

private let epsilon: CGFloat = 0.00001

extension ExifOrientation {
    public init?(matrix: MP4TransformationMatrix) {
        guard abs(matrix.u) < epsilon && abs(matrix.v) < epsilon && abs(matrix.w-1) < epsilon else { return nil }
        guard let orientation = ExifOrientation(transform: matrix.affineTransform) else { return nil }
        self = orientation
    }
    
    public init?(transform: CGAffineTransform) {
        // TODO: check that translation matches image size
        
        
        let rotationCos = transform.d
        let rotationSin = -transform.c
        
        guard rotationCos >= -1 && rotationCos <= 1 && rotationSin >= -1 && rotationSin <= 1 else {
            return nil
        }
        
        let rotationCosRadians = acos(rotationCos)
        let rotationSinRadians = asin(rotationSin)
        
        guard abs(rotationCosRadians - rotationSinRadians).remainder(dividingBy: .pi) < epsilon else {
            return nil
        }
        
        let scaleX: CGFloat
        
        if rotationCos != 0 {
            scaleX = transform.a / rotationCos
        } else if rotationSin != 0 {
            scaleX = transform.b / rotationSin
        } else {
            return nil
        }
        
        guard abs(scaleX - 1) < epsilon || abs(scaleX + 1) < epsilon else {
            return nil
        }
        
        var rotationDegrees = Int((rotationCosRadians / .pi) * 180) % 360
        if rotationSin < -epsilon {
            rotationDegrees = (rotationDegrees + 180) % 360
        }
        
        switch (rotationDegrees, scaleX) {
        case (0, 1): self = .identity
        case (90, 1): self = .rotate90deg
        case (180, 1): self = .rotate180deg
        case (270, 1): self = .rotate270deg
            
        case (0, -1): self = .mirror
        case (90, -1): self = .mirrorAndRotate90deg
        case (180, -1): self = .mirrorAndRotate180deg
        case (270, -1): self = .mirrorAndRotate270deg
            
        default: return nil
        }
        
        /*                      |------------------ CGAffineTransformComponents ----------------|
         *
         *      | a  b  0 |     | sx  0  0 |   |  1  0  0 |   | cos(t)  sin(t)  0 |   | 1  0  0 |
         *      | c  d  0 |  =  |  0 sy  0 | * | sh  1  0 | * |-sin(t)  cos(t)  0 | * | 0  1  0 |
         *      | tx ty 1 |     |  0  0  1 |   |  0  0  1 |   |   0       0     1 |   | tx ty 1 |
         *  CGAffineTransform      scale           shear            rotation          translation
         *
         *
         *      | a  b  0 |     | sx * cos(t)                      sx * sin(t)                      0 |
         *      | c  d  0 |  =  | sh * sy * cos(t) - sy * sin(t)   sh * sy * sin(t) + sy * cos(t)   0 |
         *      | tx ty 1 |     | tx                               ty                               1 |
         *
         */
    }
}
