//
//  MP4FragmentedTrack.swift
//  SwiftVideoUtils
//
//  Created by Matteo Ludwig on 30.03.25.
//

import Foundation
import CoreMedia

open class MP4FragmentedTrack: MP4Track {
    public let asset: MP4Asset
    public let trackID: UInt32
    
    private var _duration: TimeInterval?
    
    public typealias TrackFragmentBoxSequence = AsyncFlatMapSequence<AsyncCompactMapSequence<MP4Asset.BoxStream, MP4MovieFragmentBox>, AsyncStream<MP4TrackFragmentBox>>
    public var trackFragmentBoxes: TrackFragmentBoxSequence {
        self.asset.boxes.compactMap {
            $0 as? MP4MovieFragmentBox
        }.flatMap { (movieFragmentBox: MP4MovieFragmentBox) in
            AsyncStream(MP4TrackFragmentBox.self) { continuation in
                for trackFragmentBox in movieFragmentBox.trackFragments {
                    if trackFragmentBox.trackFragmentHeaderBox?.trackID == self.trackID {
                        continuation.yield(trackFragmentBox)
                    }
                }
                continuation.finish()
            }
        }
    }
    
    public typealias MovieFragmentBoxSequence = AsyncFilterSequence<AsyncCompactMapSequence<MP4Asset.BoxStream, MP4MovieFragmentBox>>
    public var movieFragmentBoxes: MovieFragmentBoxSequence {
        self.asset.boxes.compactMap {
            $0 as? MP4MovieFragmentBox
        }.filter {
            $0.trackFragments.contains(where: { $0.trackFragmentHeaderBox?.trackID == self.trackID })
        }
    }
    
    private var _trackExtendsBox: MP4TrackExtendsBox?? = nil
    public var trackExtendsBox: MP4TrackExtendsBox? {
        get async throws {
            if self._trackExtendsBox == nil {
                self._trackExtendsBox = try await self.asset.moovBox.firstChild(ofType: MP4MovieExtendsBox.self)?.children(ofType: MP4TrackExtendsBox.self).first {
                    $0.trackID == self.trackID
                }
            }
            return self._trackExtendsBox!
        }
    }

    init(asset: MP4Asset, trackBox: MP4TrackBox, reader: any MP4Reader) throws {
        guard let trackID = trackBox.trackHeaderBox?.trackID else {
            throw MP4Error.trackNotFound(0)
        }

        self.asset = asset
        self.trackID = trackID
        super.init(box: trackBox, reader: reader)
        //self._duration = try await duration()
    }

    public override func duration() async throws -> TimeInterval {
        if self._duration == nil {
            let moovBox = try await self.asset.moovBox
            
            guard let movieHeaderBox = moovBox.movieHeaderBox else {
                throw MP4Error.failedToFindBox(path: "moov.mvhd")
            }
            
            if let movieExtendsHeaderBox = moovBox.movieExtendsBox?.movieExtendsHeaderBox {
                self._duration = Double(movieExtendsHeaderBox.fragmentDuration)/Double(movieHeaderBox.timescale)
            } else {
                let moofBoxes = self.asset.boxes.compactMap {$0 as? MP4MovieFragmentBox }
                var result: Int = 0
                for try await moofBox in moofBoxes {
                    for trackFragment in moofBox.trackFragments {
                        if trackFragment.trackFragmentHeaderBox?.trackID == self.trackID {
                            result += trackFragment.totalSampleDuration()
                        }
                        
                    }
                }
                self._duration = Double(result)/Double(movieHeaderBox.timescale)
            }
        }
        
        return self._duration ?? .zero
    }
    
    public struct SampleIterator: AsyncIteratorProtocol {
        let trackExtendsBox: MP4TrackExtendsBox?
        var movieFragmentIterator: MovieFragmentBoxSequence.AsyncIterator
        
        private var bufferIterator: [SampleInfo].Iterator?
        
        private var currentSample: MP4Index<UInt32> = .zero
        private var currentDecodeTime: UInt32 = 0
        
        init(trackExtendsBox: MP4TrackExtendsBox?, movieFragmentIterator: MovieFragmentBoxSequence.AsyncIterator) {
            self.trackExtendsBox = trackExtendsBox
            self.movieFragmentIterator = movieFragmentIterator
        }
        
        public mutating func next() async throws -> SampleInfo? {
            if let sample = bufferIterator?.next() {
                return sample
            }
            bufferIterator = nil
            
            guard let movieFragmentBox = try await movieFragmentIterator.next() else {
                return nil
            }
            
            // FIXME: This does not respect ISO/IEC DIS 14496-12:2022(E) Table 6
            guard var dataStart = movieFragmentBox.readByteRange?.lowerBound else {
                throw MP4Error.internalError("Failed to find data start")
            }
            
            var buffer: [SampleInfo] = []
            for trackFragmentBox in movieFragmentBox.trackFragments {
                
                dataStart += Int(trackFragmentBox.trackFragmentHeaderBox?.baseDataOffset ?? 0)
                
                let defaultSampleSize = trackFragmentBox.trackFragmentHeaderBox?.defaultSampleSize ?? trackExtendsBox?.defaultSampleSize
                let defaultSampleDuration = trackFragmentBox.trackFragmentHeaderBox?.defaultSampleDuration ?? trackExtendsBox?.defaultSampleDuration
                let defaultSampleFlags = trackFragmentBox.trackFragmentHeaderBox?.defaultSampleFlags ?? trackExtendsBox?.defaultSampleFlags
                
                
                for trackRun in trackFragmentBox.trackFragmentRunBoxes {
                    var runDataCursor = dataStart + Int(trackRun.dataOffset ?? 0)
                    
                    for runSample in 0..<trackRun.sampleCount {
                        let sampleData = trackRun.samples[Int(runSample)]
                        
                        let sampleFlags = sampleData.flags ?? defaultSampleFlags
                        
                        guard let sampleDuration = sampleData.duration ?? defaultSampleDuration else {
                            throw MP4Error.internalError("Sample with missing duration")
                        }
                        guard let sampleSize = sampleData.size ?? defaultSampleSize else {
                            throw MP4Error.internalError("Sample with missing size")
                        }
                        
                        buffer.append(.init(index: currentSample,
                                            decodeTiming: currentDecodeTime..<currentDecodeTime+sampleDuration,
                                            dataRange: runDataCursor..<runDataCursor + Int(sampleSize),
                                            flags: sampleFlags,
                                            compositionTimeOffset: sampleData.compositionTimeOffset))
                        
                        currentDecodeTime += sampleDuration
                        currentSample += 1
                        runDataCursor += Int(sampleSize)
                    }
                }
            
            }
            bufferIterator = buffer.makeIterator()
            return bufferIterator?.next()
        }
    }
    
    public func makeSampleIterator() async throws -> SampleIterator {
        .init(trackExtendsBox: try await self.trackExtendsBox,
              movieFragmentIterator: self.movieFragmentBoxes.makeAsyncIterator())
    }
    
    
    public override func sampleData(for samples: Range<MP4Index<UInt32>>) async throws -> ([SampleInfo], Data) {
        var sampleInfos: [SampleInfo] = []
        var sampleIterator = try await makeSampleIterator()
        
        while let sampleInfo = try await sampleIterator.next() {
            if samples.contains(sampleInfo.index) {
                sampleInfos.append(sampleInfo)
            }
        }
        
        guard !sampleInfos.isEmpty else { return ([], Data()) }
        
        let readRanges = sampleInfos.map(\.dataRange).merged()
        var data = Data(capacity: readRanges.map { $0.count }.reduce(0, +))
        for readRange in readRanges {
            data.append(try await self.reader.readData(byteRange: readRange))
        }
        return (sampleInfos, data)
    }
    
    // TODO: clarify that this is using decode times!
    public override func sample(at timeOffset: TimeInterval) async throws -> MP4Index<UInt32>? {
        
        // FIXME: This does not work for fragmented tracks
        let time = UInt32(timeOffset * TimeInterval(try self.timescale))
        guard let timeToSampleBox = self.box.mediaBox?.mediaInformationBox?.sampleTableBox?.timeToSampleBox else {
            throw MP4Error.failedToFindBox(path: "mdia.minf.stbl.stts")
        }
        return timeToSampleBox.sample(at: time)
    }
    
    public override func syncSample(closestBefore timeOffset: TimeInterval) async throws -> MP4Index<UInt32>? {
        var sampleIterator = try await makeSampleIterator()
        let seekToTime: Int64 = Int64(timeOffset * TimeInterval(try self.timescale))
        
        while let sampleInfo = try await sampleIterator.next() {
            if sampleInfo.decodeTiming.lowerBound >= seekToTime && sampleInfo.flags?.sampleIsNonSyncSampleFlag == false {
                return sampleInfo.index
            }
        }
        return nil
    }
    
    public override func syncSample(_ index: Int) async throws -> MP4Index<UInt32>? {
        var sampleIterator = try await makeSampleIterator()
        var syncSampleCounter: Int = 0
        
        while let sampleInfo = try await sampleIterator.next() {
            if sampleInfo.flags?.sampleIsNonSyncSampleFlag == false {
                if syncSampleCounter == index {
                    return sampleInfo.index
                }
                syncSampleCounter += 1
            }
        }
        return nil
    }
}
