//
//  ExifOrientationTests.swift
//  
//
//  Created by Matteo Ludwig on 01.12.23.
//

import XCTest

@testable import SwiftVideoUtils

final class ExifOrientationTests: XCTestCase {


    func testFromTransform() throws {
        XCTAssertEqual(ExifOrientation(transform: .identity), .identity)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi * 0.5)), .rotate90deg)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi)), .rotate180deg)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi * 1.5)), .rotate270deg)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi * 2)), .identity)
        
        
        XCTAssertEqual(ExifOrientation(transform: .identity.scaledBy(x: -1, y: 1)), .mirror)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi * 0.5).scaledBy(x: -1, y: 1)), .mirrorAndRotate90deg)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi).scaledBy(x: -1, y: 1)), .mirrorAndRotate180deg)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi * 1.5).scaledBy(x: -1, y: 1)), .mirrorAndRotate270deg)
        XCTAssertEqual(ExifOrientation(transform: .init(rotationAngle: .pi * 2).scaledBy(x: -1, y: 1)), .mirror)
        
        XCTAssertNil(ExifOrientation(transform: .identity.rotated(by: .pi*0.2)))
        XCTAssertNil(ExifOrientation(transform: .identity.rotated(by: .pi*0.8)))
        XCTAssertNil(ExifOrientation(transform: .identity.scaledBy(x: 2, y: 1)))
        XCTAssertNil(ExifOrientation(transform: .identity.scaledBy(x: 0, y: 1)))
        XCTAssertNil(ExifOrientation(transform: .identity.scaledBy(x: 0, y: 0)))
        XCTAssertNil(ExifOrientation(transform: .identity.scaledBy(x: 2, y: 2)))
        XCTAssertNil(ExifOrientation(transform: .identity.scaledBy(x: -1, y: 2)))
        XCTAssertNil(ExifOrientation(transform: .identity.scaledBy(x: -1, y: -2)))
        XCTAssertNil(ExifOrientation(transform: .identity.rotated(by: .pi).scaledBy(x: 0.999, y: 1)))
        
        
        if #available(iOS 16.0, *) {
            var components = CGAffineTransformComponents()
            components.scale = .init(width: 1, height: 1)
            components.horizontalShear = 1
            XCTAssertNil(ExifOrientation(transform: CGAffineTransform(components)))
            
            components.horizontalShear = -1
            XCTAssertNil(ExifOrientation(transform: CGAffineTransform(components)))
            
            components.rotation = .pi
            XCTAssertNil(ExifOrientation(transform: CGAffineTransform(components)))
            
            components.rotation = 2 * .pi
            XCTAssertNil(ExifOrientation(transform: CGAffineTransform(components)))
            
            components.rotation = -.pi
            XCTAssertNil(ExifOrientation(transform: CGAffineTransform(components)))
        }
        
    }



}
