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
    
    public struct BoxStream: AsyncSequence {
        let asset: MP4Asset
        
        public func makeAsyncIterator() -> AsyncIterator {
            .init(asset: asset)
        }
        
        public struct AsyncIterator: AsyncIteratorProtocol {
            private var nextIndex: Int = 0
            let asset: MP4Asset
            
            init(asset: MP4Asset) {
                self.asset = asset
            }
            
            public mutating func next() async throws -> (any MP4Box)? {
                if nextIndex >= asset._boxes.count {
                    do {
                        try await asset.readNextBox()
                    } catch MP4Error.endOfFile {
                        return nil
                    }
                }
                if nextIndex < asset._boxes.count {
                    nextIndex += 1
                    return self.asset._boxes[nextIndex - 1]
                } else {
                    return nil
                }
            }
        }
    }
    
    fileprivate var _boxes: [any MP4Box] = []
    public var boxes: BoxStream {
        .init(asset: self)
    }
    
    func readAllBoxes() async throws -> [any MP4Box] {
        if self.sequentialReader.remainingCount == 0 {
            return self._boxes
        } else {
            var result: [any MP4Box] = []
            for try await box in self.boxes {
                result.append(box)
            }
            return result
        }
    }
    
    private var _moovBox: MP4MovieBox?
    public var moovBox: MP4MovieBox {
        get async throws {
            if self._moovBox == nil {
                for try await box in self.boxes {
                    if let moovBox = box as? MP4MovieBox {
                        return moovBox
                    }
                }
            }
            guard let moovBox = _moovBox else {
                throw MP4Error.internalError("Did not find moov box")
            }
            return moovBox
        }
    }
    
    private var _tracks: [MP4Track]?
    public var tracks: [MP4Track] {
        get async throws {
            if self._tracks == nil {
                if try await self.isFragmented {
                    self._tracks = try await self.moovBox.tracks.map {
                        try MP4FragmentedTrack(asset: self, trackBox: $0, reader: reader)
                    }
                } else {
                    self._tracks = try await self.moovBox.tracks.map {MP4Track(box: $0, reader: reader)}
                }
            }
            return self._tracks!
        }
    }
    
    private var boxByteRangeMap: [ObjectIdentifier: Range<Int>] = [:]
    private var initialMDatByteOffset: Int? = nil
    private var assumedMDatByteOffset: Int? = nil
    
    public private(set) var canBeEditedInplace: Bool = true
    
    public var isStreamable: Bool {
        get async throws {
            var foundMoovBox: Bool = false
            for try await box in self.boxes {
                if box.typeName == "moov" {
                    foundMoovBox = true
                } else if box.typeName == "mdat" {
                    return foundMoovBox
                }
            }
            return false
        }
    }
    
    public var isFragmented: Bool {
        get async throws {
            return try await self.moovBox.movieExtendsBox != nil
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
    
    private func readNextBox() async throws {
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
    }
    
    public func repairChunkOffsets() async throws {
        let boxes = try await self.readAllBoxes().filter { $0.typeName != "free" }
        
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
        var boxes = try await self.readAllBoxes()
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
        
        for try await box in self.boxes {
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
    func totalDuration() async throws -> TimeInterval {
        let moovBox = try await self.moovBox
        guard let movieHeaderBox = moovBox.movieHeaderBox else {
            throw MP4Error.failedToFindBox(path: "moov.mvhd")
        }
        if try await self.isFragmented == false {
            return Double(movieHeaderBox.duration)/Double(movieHeaderBox.timescale)
        } else if let movieExtendsHeaderBox = moovBox.movieExtendsBox?.movieExtendsHeaderBox {
            return Double(movieExtendsHeaderBox.fragmentDuration)/Double(movieHeaderBox.timescale)

        } else {
            var duration: TimeInterval = 0
            for track in try await self.tracks {
                duration = max(duration, try await track.duration())
            }
            return duration
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
        if let movieHeaderBox = moovBox.movieHeaderBox {
            movieHeaderBox.creationTime = creationTime
            movieHeaderBox.modificationTime = modificationTime
            try await self.writeBoxInplace(movieHeaderBox, to: writer)
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
