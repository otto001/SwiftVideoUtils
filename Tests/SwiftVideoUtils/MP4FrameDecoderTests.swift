import XCTest
import AVFoundation

@testable import SwiftVideoUtils

func urlForFileName(_ fileName: String) -> URL {
    var url = URL(fileURLWithPath: #file)
    url.deleteLastPathComponent()
    url.appendPathComponent(fileName)
    return url
}

final class MP4FrameDecoderTests: XCTestCase {
    func testiPhoneFHD() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD.MOV")))
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage()
        
        XCTAssertEqual(thumbnail.width, 1920)
        XCTAssertEqual(thumbnail.height, 1080)
    }
    
    func testiPhoneUHD() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_UHD.MOV")))
        print("TestVideo_iPhone_UHD")
        print(try await asset.videoFormatDescription)
        if #available(iOS 16, *) {
            print(try await AVURLAsset(url: urlForFileName("TestVideo_iPhone_UHD.MOV")).load(.tracks).first!.load(.formatDescriptions).first!)
        } else {
            // Fallback on earlier versions
        }
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage()
        
        XCTAssertEqual(thumbnail.width, 3840)
        XCTAssertEqual(thumbnail.height, 2160)
    }
    
    func testiPhoneFHDPortait() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD_Portait.MOV")))
        print("TestVideo_iPhone_FHD_Portait")
        print(try await asset.videoFormatDescription)
        if #available(iOS 16, *) {
            let asset = AVURLAsset(url: urlForFileName("TestVideo_iPhone_FHD_Portait.MOV"))
            let track = try await asset.load(.tracks).first!
            let fmt = try await track.load(.formatDescriptions).first!
            let trnsfrm = track.preferredTransform
            
            for mfmt in try await asset.load(.availableMetadataFormats) {
                let metadata = try await asset.loadMetadata(for: mfmt)
                print()
            }
        } else {
            // Fallback on earlier versions
        }
        
        print(try await asset.moovBox.description)
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage()
        let metaData = try await asset.metaData()
        XCTAssertEqual(thumbnail.width, 1080)
        XCTAssertEqual(thumbnail.height, 1920)
    }
    
    func testGoProH8() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_GoPro_H8.mp4")))
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage()
        
        XCTAssertEqual(thumbnail.width, 1920)
        XCTAssertEqual(thumbnail.height, 1080)
    }
    
    func testGooglePhotosAndroid10() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_GooglePhotos_Android10.mp4")))
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage()
        
        XCTAssertEqual(thumbnail.width, 3840)
        XCTAssertEqual(thumbnail.height, 2160)
    }
    
    func testThumbnailGenerator() async throws {
        let url = urlForFileName("TestVideo_iPhone_UHD.MOV")
        
        let data = try Data(contentsOf: url)

        let bufferedReader = MP4BlockReader(count: data.count) { range in
            //try await Task.sleep(nanoseconds: 100_000_000)
            let range = range.lowerBound..<min(max(range.upperBound, range.lowerBound+128), data.count)
            print("reading range \(range.lowerBound)-\(range.upperBound) (count: \(range.count))")
            return Data(data[range])
        }
        
        let asset = try await MP4Asset(reader: bufferedReader)
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage()
        print(thumbnail.width, thumbnail.height)
        //print(try await asset.metaData())
        //print(try await asset.moovBox.description)
//        let data = try! Data(contentsOf: url)
//        
//        let thumbnailGenerator = try MP4FrameDecoder(initialData: data)
//        let thumbnail = try await thumbnailGenerator.thumbnail { range in
//            data[range]
//        }
//        
//        XCTAssertEqual(thumbnail.width, 1920)
//        XCTAssertEqual(thumbnail.height, 1080)
//        let myFormat = thumbnailGenerator.videoFormat
    }
}
