//
//  ExifMetaData.swift
//
//
//  Created by Matteo Ludwig on 01.12.23.
//

import Foundation
import ImageIO
import CoreLocation


private var exifDateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
    dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return dateFormatter
}()


public struct ExifMetaData {
    public var dateTimeOriginal: Date?
    public var dateTimeDigitized: Date?
    public var dateTimeTiff: Date?
    
    public var make: String?
    public var model: String?
    public var lensModel: String?
    
    public var artist: String?
    public var software: String?
    public var copyright: String?
    
    public var profileName: String?
    
    public var dataWidth: Int32?
    public var dataHeight: Int32?
    public var orientation : ExifOrientation?
    
    public var width: Int32? {
        orientation?.swapWidthAndHeight == true ? dataHeight : dataWidth
    }
    public var height: Int32? {
        orientation?.swapWidthAndHeight == true ? dataWidth : dataHeight
    }
    
    public var bitDepth: Int32?
    
    public var horizontalResolution: Int32?
    public var verticalResolution: Int32?
    
    public var focalLength35mm: Int32?
    public var aperatureValue: Double?
    public var contrast: Int32?
    public var saturation: Int32?
    public var sharpness: Int32?
    public var exposureMode: Int32?
    public var isoSpeedRating: Int32?
    public var exposureTime: Double?
    
    public var fValue: Double? {
        aperatureValue.map { round(100 * sqrt(pow(2, $0)))/100 }
    }
    
    public var latitude: Double?
    public var longitude: Double?
    public var altitude: Double?
    
    public var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return .init(latitude: latitude, longitude: longitude)
    }
    
    public var location: CLLocation? {
        guard let coordinate = coordinate else { return nil }
        return .init(coordinate: coordinate, altitude: altitude ?? 0,
                     horizontalAccuracy: 0, verticalAccuracy: 0,
                     timestamp: dateTime ?? Date())
    }
    
    
    public var dateTime: Date? {
        dateTimeOriginal ?? dateTimeTiff
    }
    
    init(imageProperties: [String: AnyObject]) {
        if let tiffData = imageProperties["{TIFF}"] as? [String: AnyObject] {
            self.make = tiffData["Make"] as? String
            self.model = tiffData["Model"] as? String
            
            self.artist = tiffData["Artist"] as? String
            self.software = tiffData["Software"] as? String
            self.copyright = tiffData["Copyright"] as? String
            
            self.horizontalResolution = tiffData["XResolution"] as? Int32
            self.verticalResolution = tiffData["YResolution"] as? Int32
            
            self.dateTimeTiff = (tiffData["DateTime"] as? String).flatMap {
                exifDateFormatter.date(from: $0)
            }
            
            self.orientation = (tiffData["Orientation"] as? Int32).flatMap { .init(rawValue: Int16(truncatingIfNeeded: $0)) }
        }
        
        if let exifData = imageProperties["{Exif}"] as? [String: AnyObject] {
            self.dateTimeOriginal = (exifData["DateTimeOriginal"] as? String).flatMap {
                exifDateFormatter.date(from: $0)
            }
            
            self.dateTimeDigitized = (exifData["DateTimeDigitized"] as? String).flatMap {
                exifDateFormatter.date(from: $0)
            }
            
            if self.make == nil {
                self.make = exifData["LensMake"] as? String
            }
            if self.model == nil {
                self.model = exifData["LensModel"] as? String
            }
            
            
            self.focalLength35mm = exifData["FocalLenIn35mmFilm"] as? Int32
            self.aperatureValue = exifData["ApertureValue"] as? Double
            self.contrast = exifData["Contrast"] as? Int32
            self.saturation = exifData["Saturation"] as? Int32
            self.sharpness = exifData["Sharpness"] as? Int32
            self.exposureMode = exifData["ExposureMode"] as? Int32
            self.isoSpeedRating = ( exifData["ISOSpeedRatings"] as? [Int32])?.first
            self.exposureTime = exifData["ExposureTime"] as? Double
        }
        
        if let exifAuxData = imageProperties["{ExifAux}"] as? [String: AnyObject] {
            self.lensModel = exifAuxData["LensModel"] as? String
        }
        
        if let gpsData = imageProperties["{GPS}"]  as? [String: AnyObject] {
            if let latitude = gpsData["Latitude"] as? Double,
               let latitudeRef = gpsData["LatitudeRef"] as? String,
               let longitude = gpsData["Longitude"] as? Double,
               let longitudeRef = gpsData["LongitudeRef"] as? String {
                
                self.altitude = gpsData["Altitude"] as? Double
                if (gpsData["AltitudeRef"] as? UInt16) == 1, let altitude = self.altitude {
                    self.altitude = -altitude
                }
                self.latitude = latitude * (latitudeRef == "N" ? 1 : -1)
                self.longitude = longitude * (longitudeRef == "E" ? 1 : -1)
            }
        }
        
        self.profileName = imageProperties["ProfileName"] as? String
        
        self.dataWidth = imageProperties["PixelWidth"] as? Int32
        self.dataHeight = imageProperties["PixelHeight"] as? Int32
        
        self.orientation = (imageProperties["Orientation"] as? Int32).flatMap { .init(rawValue: Int16(truncatingIfNeeded: $0)) }
        
        self.horizontalResolution = imageProperties["DPIWidth"] as? Int32
        self.verticalResolution = imageProperties["DPIHeight"] as? Int32
        self.bitDepth = imageProperties["Depth"] as? Int32
    }
    
    init?(imageData: Data) {
        guard let imageProperties = Self.getImageProperties(data: imageData) else {
            return nil
        }
        self = .init(imageProperties: imageProperties)
    }
}

extension ExifMetaData: Codable {
    
}

extension ExifMetaData {
    public static func getImageProperties(data: Data) -> [String: AnyObject]? {
        var metaData: CFDictionary? = nil
        
        
        data.withUnsafeBytes { rawBufferPointer in
            rawBufferPointer.withMemoryRebound(to: UInt8.self) { buffer in
                if let cfData = CFDataCreate(kCFAllocatorDefault, buffer.baseAddress!, buffer.count),
                   let source = CGImageSourceCreateWithData(cfData, nil) {
                    metaData = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                }
            }
        }
        if let dict = metaData as? [String: AnyObject] {
            return dict
        }
        return nil
    }
}
