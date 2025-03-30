//
//  MP4Asset.swift
//
//
//  Created by Matteo Ludwig on 20.11.23.
//

import Foundation
import CoreMedia


open class MP4Asset {
    public let reader: any MP4Reader
    public lazy var sequentialReader: MP4SequentialReader = .init(reader: self.reader, readBox: self.didReadBox)
    static var supportedTopLevelBoxTypes: MP4BoxTypeMap = [MP4FileTypeBox.self, MP4MovieBox.self, MP4MetaBox.self, MP4MovieFragmentBox.self]
    
    private var _boxes: [any MP4Box] = []
    public var boxes: [any MP4Box] {
        get async throws {
            while self.sequentialReader.remainingCount > 0 {
                _ = try await self.readNextBox()
            }
            return self._boxes
        }
    }
    
    private var _moovBox: MP4MovieBox?
    public var moovBox: MP4MovieBox {
        get async throws {
            if self._moovBox == nil {
                self._moovBox = try await self.findMoovBox()
            }
            return self._moovBox!
        }
    }
    
    private var _tracks: [MP4Track]?
    public var tracks: [MP4Track] {
        get async throws {
            if self._tracks == nil {
                self._tracks = try await self.moovBox.tracks.map {MP4Track(box: $0, reader: reader)}
            }
            return self._tracks!
        }
    }
    
    private var boxByteRangeMap: [ObjectIdentifier: Range<Int>] = [:]
    private var initialMDatByteOffset: Int? = nil
    private var assumedMDatByteOffset: Int? = nil
    
    public private(set) var canBeEditedInplace: Bool = true
    
    public var isStreamable: Bool? {
        get async throws {
            let boxes = try await self.boxes
            let moovBoxIndex = boxes.firstIndex { $0.typeName == "moov" }
            let mdatBoxIndex = boxes.firstIndex { $0.typeName == "mdat" }
            guard let moovBoxIndex = moovBoxIndex, let mdatBoxIndex = mdatBoxIndex else {
                return nil
            }
            return moovBoxIndex < mdatBoxIndex
        }
    }
    
    public var isFragmented: Bool? {
        get async throws {
            return try await self.moovBox.moovieExtendsBox != nil
        }
    }
    
    public init(reader: MP4Reader) async throws {
        self.reader = reader
    }
    
    public convenience init(url: URL, context: MP4IOContext) async throws {
        try await self.init(reader: try MP4FileReader(url: url, context: context))
    }
    
    public convenience init(data: Data, context: MP4IOContext) async throws {
        try await self.init(reader: MP4BufferReader(data: data, context: context))
    }
    
    public func metaData() async throws -> MP4MetaData {
        try await MP4MetaData(asset: self)
    }
    
    private func didReadBox(_ box: any MP4Box, _ byteRange: Range<Int>) {
    }
    
    private func readNextBox() async throws -> any MP4Box {
        let currentReadOffset = self.sequentialReader.readOffset
        
        let box = try await self.sequentialReader.readBox(boxTypeMap: Self.supportedTopLevelBoxTypes)
        self._boxes.append(box)
        
        switch box.typeName {
        case "moov":
            self._moovBox = box as? MP4MovieBox
        case "ftyp":
            if let ftypBox = box as? MP4FileTypeBox, self.reader.context.fileType == nil {
                self.reader.context.fileType = ftypBox.majorBrand == "qt  " ? .quicktime : .isoMp4
            }
        case "mdat":
            self.initialMDatByteOffset = currentReadOffset
        default:
            break
        }
        return box
    }
    
    private func findMoovBox() async throws -> MP4MovieBox {
        if let moovBox = self._boxes.first(where: {$0.typeName == "moov"}) {
            return moovBox as! MP4MovieBox
        }
        
        while self._moovBox == nil && self.sequentialReader.remainingCount > 0 {
            _ = try await self.readNextBox()
        }
        
        guard let moovBox = self._moovBox else {
            throw MP4Error.endOfFile  // TODO: Better error
        }
        
        return moovBox
    }
    
    public func repairChunkOffsets() async throws {
        let boxes = try await self.boxes.filter { $0.typeName != "free" }
        
        guard let currentMDatByteOffset = self.assumedMDatByteOffset ?? self.initialMDatByteOffset else { return }
        
        var newMDatByteOffset = 0
        for box in boxes {
            guard box.typeName != "mdat" else { break }
            newMDatByteOffset += box.overestimatedByteSize
        }
        newMDatByteOffset += 8
        
        let byteOffsetDiff = newMDatByteOffset - currentMDatByteOffset
        
        for track in try await tracks {
            if let chunkOffsetBox = track.box.mediaBox?.mediaInformationBox?.sampleTableBox?.chunkOffsetBox {
                chunkOffsetBox.moveChunks(by: byteOffsetDiff)
            }
        }
        
        self.assumedMDatByteOffset = newMDatByteOffset
        
        self.canBeEditedInplace = false
        self._boxes = boxes
    }
    
    public func makeStreamable() async throws -> Bool {
        guard try await self.isStreamable == false else {
            return false
        }
        if try await self.isFragmented == true {
            throw MP4Error.featureNotSupported("Cannot make fragmented files streamable (yet).")
        }
        // TODO: Ensure that we can safely do so (check that all top level boxes are supported)
        var boxes = try await self.boxes
        let moovBoxIndex = boxes.firstIndex { $0.typeName == "moov" }
        let mdatBoxIndex = boxes.firstIndex { $0.typeName == "mdat" }
        guard let moovBoxIndex = moovBoxIndex, let mdatBoxIndex = mdatBoxIndex else {
            return false
        }
        let moovBox = boxes.remove(at: moovBoxIndex)
        boxes.insert(moovBox, at: mdatBoxIndex)
        self._boxes = boxes
        
        self.canBeEditedInplace = false
        
        try await self.repairChunkOffsets()
        
        return true
    }
    
    public func data(byteRange: Range<Int>) async throws -> Data {
        return try await self.reader.readData(byteRange: byteRange)
    }
}


extension MP4Asset: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await self.repairChunkOffsets()
        
        for box in try await boxes {
            if box.typeName == "mdat", let assumedMDatByteOffset = self.assumedMDatByteOffset {
                let offsetDiff = assumedMDatByteOffset - writer.offset
                if offsetDiff >= 8 {
                    let fillerBox = MP4SimpleDataBox(typeName: "free", data: Data(repeating: 0, count: offsetDiff - 8))
                    try await writer.write(fillerBox)
                } else if offsetDiff > 0 {
                    throw MP4Error.internalError("Did not leave enough headroom for moov atom, aborting write operations.")
                }
            }
            
            
            try await writer.write(box)
        }
        
    }
    
    public var overestimatedByteSize: Int {
        0
    }
}

extension MP4Asset {
    func totalDuration() async throws -> CMTime {
        let moovBox = try await self.moovBox
        guard let moovieHeaderBox = moovBox.moovieHeaderBox else {
            throw MP4Error.failedToFindBox(path: "moov.mvhd")
        }
        if try await self.isFragmented == false {
            return CMTime(value: CMTimeValue(moovieHeaderBox.duration), timescale: CMTimeScale(moovieHeaderBox.timescale))
        } else if let moovieExtendsHeaderBox = moovBox.moovieExtendsBox?.moovieExtendsHeaderBox {
            return CMTime(value: CMTimeValue(moovieExtendsHeaderBox.fragmentDuration), timescale: CMTimeScale(moovieHeaderBox.timescale))

        } else {
            let moofBoxes = try await boxes.compactMap {$0 as? MP4MovieFragmentBox }
            var result: Int = 0
            for moofBox in moofBoxes {
                for trackFragment in moofBox.trackFragments {
                    result += trackFragment.totalSampleDuration()
                }
            }
            return CMTime(value: CMTimeValue(result), timescale: CMTimeScale(moovieHeaderBox.timescale))
        }
    }
}

extension MP4Asset {
    private func writeBoxInplace(_ box: any MP4Box, to writer: MP4Writer) async throws {
        guard self.canBeEditedInplace else { throw MP4Error.assetCannotBeEditedInplace }
        guard let byteRange = box.readByteRange else { throw MP4Error.internalError("Cannot write box inplace: Box does not contain a byte range") }
        
        let bufferWriter = MP4BufferWriter(context: self.reader.context)
        try await bufferWriter.write(box)
        
        guard bufferWriter.count == byteRange.count else {
            throw MP4Error.internalError("Cannot write box inplace: Box did change size")
        }
        
        writer.offset = byteRange.lowerBound
        
        try await writer.write(bufferWriter.buffer)
    }
}

extension MP4Asset {
    public func overwriteCreationTimeInplace(creationTime: Date, modificationTime: Date) async throws {
        guard self.canBeEditedInplace else { throw MP4Error.assetCannotBeEditedInplace }
        guard let fileUrl = (self.reader as? MP4FileReader)?.fileURL else {
            throw MP4Error.featureNotSupported("Writing inplace is only supported for file based assets")
        }
        
        let writer = try MP4FileWriter(url: fileUrl, context: self.reader.context)
        
        let moovBox = try await self.moovBox
        if let moovieHeaderBox = moovBox.moovieHeaderBox {
            moovieHeaderBox.creationTime = creationTime
            moovieHeaderBox.modificationTime = modificationTime
            try await self.writeBoxInplace(moovieHeaderBox, to: writer)
        }
        for trackBox in moovBox.tracks {
            if let trackHeaderBox = trackBox.trackHeaderBox {
                trackHeaderBox.creationTime = creationTime
                trackHeaderBox.modificationTime = modificationTime
                try await self.writeBoxInplace(trackHeaderBox, to: writer)
            }
            
            if let mediaHeaderBox = trackBox.mediaBox?.mediaHeaderBox {
                mediaHeaderBox.creationTime = creationTime
                mediaHeaderBox.modificationTime = modificationTime
                try await self.writeBoxInplace(mediaHeaderBox, to: writer)
            }
        }
        
        try await writer.close()
    }
}
