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
        let thumbnail = try await generator.cgImage(for: generator.track.syncSample(for: 0)!)
        
        XCTAssertEqual(thumbnail.width, 1920)
        XCTAssertEqual(thumbnail.height, 1080)
    }
    
    func testiPhoneUHD() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_UHD.MOV")))
        //print("TestVideo_iPhone_UHD")
        //print(try await asset.)
//        if #available(iOS 16, *) {
//            print(try await AVURLAsset(url: urlForFileName("TestVideo_iPhone_UHD.MOV")).load(.tracks).first!.load(.formatDescriptions).first!)
//        } else {
//            // Fallback on earlier versions
//        }
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage(for: generator.track.syncSample(for: 0)!)
        
        XCTAssertEqual(thumbnail.width, 3840)
        XCTAssertEqual(thumbnail.height, 2160)
    }
    
    func testiPhoneFHDPortait() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_iPhone_FHD_Portrait.MOV")))
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage(for: generator.track.syncSample(for: 0)!)

        XCTAssertEqual(thumbnail.width, 1080)
        XCTAssertEqual(thumbnail.height, 1920)
    }
    
    func testGoProH8() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_GoPro_H8.mp4")))
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage(for: generator.track.syncSample(for: 0)!)
        
        XCTAssertEqual(thumbnail.width, 1920)
        XCTAssertEqual(thumbnail.height, 1080)
    }
    
    func testGooglePhotosAndroid10() async throws {
        let asset = try await MP4Asset(reader: MP4FileReader(url: urlForFileName("TestVideo_GooglePhotos_Android10.mp4")))
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage(for: generator.track.syncSample(for: 0)!)
        
        XCTAssertEqual(thumbnail.width, 3840)
        XCTAssertEqual(thumbnail.height, 2160)
    }
    
    func testThumbnailGenerator() async throws {
        let url = urlForFileName("TestVideo_iPhone_UHD.MOV")
        
        let data = try Data(contentsOf: url)

        let bufferedReader = MP4BlockReader(totalSize: data.count) { range in
            let range = range.lowerBound..<min(max(range.upperBound, range.lowerBound+128), data.count)
            return Data(data[range])
        }
        
        let asset = try await MP4Asset(reader: bufferedReader)
        let generator = try await MP4FrameDecoder(asset: asset)
        let thumbnail = try await generator.cgImage(for: generator.track.syncSample(for: 0)!)
    }
}
