//
//  MP4AudioSampleEntryBox.swift
//
//
//  Created by Matteo Ludwig on 25.12.23.
//

import Foundation
import CoreMedia


public enum MP4AudioSampleEntry: MP4BoxProxy {
    public static var supportedTypeNames: [MP4FourCC] = ["mp4a"]
    
    case iso(MP4AudioSampleEntryBoxIso)
    case quicktimeV0(MP4AudioSampleEntryBoxQuicktimeV0)
    case quicktimeV1(MP4AudioSampleEntryBoxQuicktimeV1)
    
    public var wrappedBox: MP4ParsableBox {
        switch self {
        case .iso(let mP4AudioSampleEntryBoxIso):
            return mP4AudioSampleEntryBoxIso
        case .quicktimeV0(let mP4AudioSampleEntryBoxQuicktimeV0):
            return mP4AudioSampleEntryBoxQuicktimeV0
        case .quicktimeV1(let mP4AudioSampleEntryBoxQuicktimeV1):
            return mP4AudioSampleEntryBoxQuicktimeV1
        }
    }
    
    public init(typeName: MP4FourCC, contentReader: MP4SequentialReader) async throws {
        if contentReader.context.fileType == .isoMp4 {
            self = .iso(try await MP4AudioSampleEntryBoxIso(format: typeName, contentReader: contentReader))
        } else {
            let data = try await contentReader.readAllData()
            let bufferReader = MP4BufferReader(data: data, context: contentReader.context)
            let bufferedContentReader = MP4SequentialReader(reader: bufferReader)
            
            let version = try await bufferReader.readInteger(startingAt: 8, UInt16.self, byteOrder: .bigEndian)
            
            switch version {
            case 0:
                self = .quicktimeV0(try await MP4AudioSampleEntryBoxQuicktimeV0(format: typeName, contentReader: bufferedContentReader))
            case 1:
                self = .quicktimeV1(try await MP4AudioSampleEntryBoxQuicktimeV1(format: typeName, contentReader: bufferedContentReader))
//            case 2:
//                self.wrappedBox = try await MP4AudioSampleEntryBoxQuicktimeV2(format: typeName, contentReader: bufferedContentReader)
            default:
                throw MP4Error.failedToParseBox(description: "Version \(version) of stsd is not supported")
            }
        }
    }
    
    public func audioStreamBasicDescription() throws -> AudioStreamBasicDescription {
        switch self {
        case .iso(let mP4AudioSampleEntryBoxIso):
            return try mP4AudioSampleEntryBoxIso.audioStreamBasicDescription()
        case .quicktimeV0(let mP4AudioSampleEntryBoxQuicktimeV0):
            return try mP4AudioSampleEntryBoxQuicktimeV0.audioStreamBasicDescription()
        case .quicktimeV1(let mP4AudioSampleEntryBoxQuicktimeV1):
            return try mP4AudioSampleEntryBoxQuicktimeV1.audioStreamBasicDescription()
        }
    }
    
    public func makeFormatDescription() async throws -> CMFormatDescription {
        return try .init(audioStreamBasicDescription: try self.audioStreamBasicDescription())
    }
}

public class MP4AudioSampleEntryBoxIso: MP4SampleEntryBox {
    public static var supportedFormats: [MP4FourCC] = MP4AudioSampleEntry.supportedTypeNames
    public static var supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var typeName: MP4FourCC
    
    public var reserved1: Data
    
    public var dataReferenceIndex: UInt16
    
    public var reserved2: UInt64
    public var channelCount: UInt16
    public var sampleSize: UInt16
    public var preDefined: UInt16
    public var reserved3: UInt16
    public var sampleRate: UInt32
    
    public var children: [MP4Box]
    
    public required init(format: MP4FourCC, contentReader reader: MP4SequentialReader) async throws {
        
        self.typeName = format
        self.reserved1 = try await reader.readData(count: 6)
        self.dataReferenceIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.reserved2 = try await reader.readInteger(byteOrder: .bigEndian)
        self.channelCount = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.preDefined = try await reader.readInteger(byteOrder: .bigEndian)
        self.reserved3 = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleRate = try await reader.readInteger(byteOrder: .bigEndian) >> 16

        self.children = try await reader.readBoxes(boxTypeMap: Self.supportedChildBoxTypes)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(self.reserved1)
        try await writer.write(self.dataReferenceIndex, byteOrder: .bigEndian)
        try await writer.write(self.reserved2, byteOrder: .bigEndian)
        try await writer.write(self.channelCount, byteOrder: .bigEndian)
        try await writer.write(self.sampleSize, byteOrder: .bigEndian)
        try await writer.write(self.preDefined, byteOrder: .bigEndian)
        try await writer.write(self.reserved3, byteOrder: .bigEndian)
        try await writer.write(self.sampleRate << 16, byteOrder: .bigEndian)
        
        try await writer.write(self.children)
    }
    
    public var overestimatedContentByteSize: Int {
        28 + self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
    
    public func audioStreamBasicDescription() throws -> AudioStreamBasicDescription {
        switch self.typeName {
        case "mp4a":
            return .init(mSampleRate: Double(self.sampleRate),
                         mFormatID: kAudioFormatMPEG4AAC, mFormatFlags: 0,
                         mBytesPerPacket: 0, mFramesPerPacket: 1024,
                         mBytesPerFrame: 0, mChannelsPerFrame: UInt32(self.channelCount),
                         mBitsPerChannel: UInt32(self.sampleSize), mReserved: 0)
        default:
            throw MP4Error.internalError("unsupported format: \(typeName.description)")
        }
    }
}


public class MP4AudioSampleEntryBoxQuicktimeV0: MP4SampleEntryBox {
    public static var supportedFormats: [MP4FourCC] = MP4AudioSampleEntry.supportedTypeNames
    public static var supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var typeName: MP4FourCC
    
    public var reserved1: Data
    
    public var dataReferenceIndex: UInt16
    
    public var version: UInt16
    public var revision: UInt16
    public var vendor: UInt32
    
    public var channelCount: UInt16
    public var sampleSize: UInt16
    public var compressionID: UInt16
    public var packetSize: UInt16
    public var sampleRate: FixedPointNumber<UInt32>
    
    public var children: [MP4Box]
    
    public required init(format: MP4FourCC, contentReader reader: MP4SequentialReader) async throws {
        self.typeName = format
        self.reserved1 = try await reader.readData(count: 6)
        self.dataReferenceIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.version = try await reader.readInteger(byteOrder: .bigEndian)
        self.revision = try await reader.readInteger(byteOrder: .bigEndian)
        self.vendor = try await reader.readInteger(byteOrder: .bigEndian)
        self.channelCount = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.compressionID = try await reader.readInteger(byteOrder: .bigEndian)
        self.packetSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleRate = try await reader.readUnsignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        
        self.children = try await reader.readBoxes(boxTypeMap: Self.supportedChildBoxTypes)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(self.reserved1)
        try await writer.write(self.dataReferenceIndex, byteOrder: .bigEndian)
        try await writer.write(self.version, byteOrder: .bigEndian)
        try await writer.write(self.revision, byteOrder: .bigEndian)
        try await writer.write(self.vendor, byteOrder: .bigEndian)
        try await writer.write(self.channelCount, byteOrder: .bigEndian)
        try await writer.write(self.sampleSize, byteOrder: .bigEndian)
        try await writer.write(self.compressionID, byteOrder: .bigEndian)
        try await writer.write(self.packetSize, byteOrder: .bigEndian)
        try await writer.write(self.sampleRate, byteOrder: .bigEndian)
        
        try await writer.write(self.children)
    }
    
    public var overestimatedContentByteSize: Int {
        28 + self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
    
    public func audioStreamBasicDescription() throws -> AudioStreamBasicDescription {
        throw MP4Error.internalError("unsupported format: \(typeName.description)")
    }
}


public class MP4AudioSampleEntryBoxQuicktimeV1: MP4SampleEntryBox {
    public static var supportedFormats: [MP4FourCC] = MP4AudioSampleEntry.supportedTypeNames
    public static var supportedChildBoxTypes: MP4BoxTypeMap = []
    
    public var typeName: MP4FourCC
    
    public var reserved1: Data
    
    public var dataReferenceIndex: UInt16
    
    public var version: UInt16
    public var revision: UInt16
    public var vendor: UInt32
    
    public var channelCount: UInt16
    public var sampleSize: UInt16
    public var compressionID: UInt16
    public var packetSize: UInt16
    public var sampleRate: FixedPointNumber<UInt32>
    
    public var framesPerPacket: UInt32
    public var bytesPerPacket: UInt32
    public var bytesPerFrame: UInt32
    public var bytesPerSample: UInt32
    
    public var children: [MP4Box]
    
    public required init(format: MP4FourCC, contentReader reader: MP4SequentialReader) async throws {
        self.typeName = format
        self.reserved1 = try await reader.readData(count: 6)
        self.dataReferenceIndex = try await reader.readInteger(byteOrder: .bigEndian)
        self.version = try await reader.readInteger(byteOrder: .bigEndian)
        self.revision = try await reader.readInteger(byteOrder: .bigEndian)
        self.vendor = try await reader.readInteger(byteOrder: .bigEndian)
        self.channelCount = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.compressionID = try await reader.readInteger(byteOrder: .bigEndian)
        self.packetSize = try await reader.readInteger(byteOrder: .bigEndian)
        self.sampleRate = try await reader.readUnsignedFixedPoint(fractionBits: 16, byteOrder: .bigEndian)
        self.framesPerPacket = try await reader.readInteger(byteOrder: .bigEndian)
        self.bytesPerPacket = try await reader.readInteger(byteOrder: .bigEndian)
        self.bytesPerFrame = try await reader.readInteger(byteOrder: .bigEndian)
        self.bytesPerSample = try await reader.readInteger(byteOrder: .bigEndian)
        
        self.children = try await reader.readBoxes(boxTypeMap: Self.supportedChildBoxTypes)
    }
    
    public func writeContent(to writer: MP4Writer) async throws {
        try await writer.write(self.reserved1)
        try await writer.write(self.dataReferenceIndex, byteOrder: .bigEndian)
        try await writer.write(self.version, byteOrder: .bigEndian)
        try await writer.write(self.revision, byteOrder: .bigEndian)
        try await writer.write(self.vendor, byteOrder: .bigEndian)
        try await writer.write(self.channelCount, byteOrder: .bigEndian)
        try await writer.write(self.sampleSize, byteOrder: .bigEndian)
        try await writer.write(self.compressionID, byteOrder: .bigEndian)
        try await writer.write(self.packetSize, byteOrder: .bigEndian)
        try await writer.write(self.sampleRate, byteOrder: .bigEndian)
        try await writer.write(self.framesPerPacket, byteOrder: .bigEndian)
        try await writer.write(self.bytesPerPacket, byteOrder: .bigEndian)
        try await writer.write(self.bytesPerFrame, byteOrder: .bigEndian)
        try await writer.write(self.bytesPerSample, byteOrder: .bigEndian)
        
        try await writer.write(self.children)
    }
    
    public var overestimatedContentByteSize: Int {
        44 + self.children.map {$0.overestimatedByteSize}.reduce(0, +)
    }
    
    public func audioStreamBasicDescription() throws -> AudioStreamBasicDescription {
        switch self.typeName {
        case "mp4a":
            return .init(mSampleRate: self.sampleRate.double,
                         mFormatID: kAudioFormatMPEG4AAC, mFormatFlags: 0,
                         mBytesPerPacket: 0, mFramesPerPacket: self.framesPerPacket,
                         mBytesPerFrame: self.bytesPerFrame, mChannelsPerFrame: UInt32(self.channelCount),
                         mBitsPerChannel: UInt32(self.sampleSize), mReserved: 0)
        default:
            throw MP4Error.internalError("unsupported format: \(typeName.description)")
        }
    }
}
