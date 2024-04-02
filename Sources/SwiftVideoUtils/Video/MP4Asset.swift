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
    public lazy var sequentialReader: MP4SequentialReader = .init(reader: self.reader)
    static var supportedTopLevelBoxTypes: MP4BoxTypeMap = [MP4FileTypeBox.self, MP4MovieBox.self, MP4MetaBox.self]
    
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
    
    var isStreamable: Bool? {
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
    
    private func readNextBox() async throws -> any MP4Box {
        let box = try await self.sequentialReader.readBox(boxTypeMap: Self.supportedTopLevelBoxTypes)
        self._boxes.append(box)
        
        switch box.typeName {
        case "moov":
            self._moovBox = box as? MP4MovieBox
        case "ftyp":
            if let ftypBox = box as? MP4FileTypeBox, self.reader.context.fileType == nil {
                self.reader.context.fileType = ftypBox.majorBrand == "qt  " ? .quicktime : .isoMp4
            }
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
    
    public func makeStreamable() async throws -> Bool {
        guard try await self.isStreamable == false else {
            return false
        }
        var boxes = try await self.boxes
        let moovBoxIndex = boxes.firstIndex { $0.typeName == "moov" }
        let mdatBoxIndex = boxes.firstIndex { $0.typeName == "mdat" }
        guard let moovBoxIndex = moovBoxIndex, let mdatBoxIndex = mdatBoxIndex else {
            return false
        }
        let moovBox = boxes.remove(at: moovBoxIndex)
        boxes.insert(moovBox, at: mdatBoxIndex)
        self._boxes = boxes
        return true
    }
    
    public func data(byteRange: Range<Int>) async throws -> Data {
        return try await self.reader.readData(byteRange: byteRange)
    }
}


extension MP4Asset: MP4Writeable {
    public func write(to writer: MP4Writer) async throws {
        try await writer.write(try await boxes)
    }
    
    public var overestimatedByteSize: Int {
        0
    }
}
