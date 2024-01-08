//
//  MP4PagingReader.swift
//
//
//  Created by Matteo Ludwig on 25.12.23.
//

import Foundation


public class MP4PagingReader: MP4Reader {
    public let underlyingReader: any MP4Reader
    public var totalSize: Int { self.underlyingReader.totalSize }
    
    public var context: MP4IOContext
    
    struct Page {
        let index: Int
        let data: Data
        var lastAccessed: Date
    }
    
    private var pages: [Int: Page] = [:]
    public let pageSize: Int
    public let maxPagesInMemory: Int
    
    public var pagesInMemory: Int {
        self.pages.count
    }
    
    public var currentMemoryUsage: Int {
        self.pages.count * self.pageSize
    }
    
    public init(reader: any MP4Reader, maxPagesInMemory: Int = 16, pageSize: Int = 4096) {
        self.underlyingReader = reader
        self.context = underlyingReader.context
        self.pageSize = pageSize
        self.maxPagesInMemory = maxPagesInMemory
    }
    
    public convenience init(reader: any MP4Reader, maxMemoryUsageBytes: Int, pageSize: Int = 4096) {
        let maxPages = maxMemoryUsageBytes/pageSize
        self.init(reader: reader, maxPagesInMemory: maxPages, pageSize: pageSize)
    }
    
    private func byteRange(for page: Int) -> Range<Int> {
        return (page*pageSize)..<((page+1)*pageSize)
    }
    
    private func pages(for byteRange: Range<Int>) throws -> Range<Int> {
        if byteRange.upperBound > self.totalSize {
            throw MP4Error.tooFewBytes
        }
        return (byteRange.lowerBound/pageSize)..<((byteRange.upperBound + pageSize - 1)/pageSize)
    }
    
    public func isPreparedToRead(byteRange: Range<Int>) throws -> Bool {
        try self.pages(for: byteRange).allSatisfy { self.pages[$0] != nil }
    }
    
    private func discardPagesIfNeeded() {
        guard self.pages.count > self.maxPagesInMemory else { return }
        
        let sortedPages = self.pages.values.sorted { a, b in
            a.lastAccessed < b.lastAccessed
        }
        
        for page in sortedPages[0..<self.pages.count-self.maxPagesInMemory] {
            self.pages[page.index] = nil
        }
    }
    
    public func prepareToRead(byteRange: Range<Int>) async throws {
        let neededPages = try self.pages(for: byteRange)
        guard neededPages.count <= self.maxPagesInMemory else {
            return
        }
        let missingPages: [Int] = neededPages.filter {  self.pages[$0] == nil }
        guard !missingPages.isEmpty else { return }
        
        let pages = try await withThrowingTaskGroup(of: Page.self) { group in
            for page in missingPages {
                group.addTask {
                    let data = try await self.underlyingReader.readData(byteRange: self.byteRange(for: page))
                    return Page(index: page, data: data, lastAccessed: Date())
                }
            }
            
            var result: [Page] = []
            for try await page in group {
                result.append(page)
            }
            return result
        }
        
        for page in pages {
            self.pages[page.index] = page
        }
        
        self.discardPagesIfNeeded()
    }
    
    private func dataFromPage(page: Int, byteRange: Range<Int>) -> Data? {
        let pageBegin = page*self.pageSize
        self.pages[page]?.lastAccessed = Date()
        return self.pages[page]?.data[max(0, byteRange.lowerBound - pageBegin)..<min(self.pageSize, byteRange.upperBound-pageBegin)]
    }
    
    public func readData(byteRange: Range<Int>) async throws -> Data {
        try await self.prepareToRead(byteRange: byteRange)
        let pages = try self.pages(for: byteRange)
        guard !pages.isEmpty else { return .init() }
        
        if pages.count > self.maxPagesInMemory {
            return try await self.underlyingReader.readData(byteRange: byteRange)
        }
        
        if pages.count == 1 {
            guard let pageData = self.dataFromPage(page: pages.lowerBound, byteRange: byteRange) else {
                throw MP4Error.internalError("Error in MP4PaginReader: missing page")
            }
            return pageData
        }
        
        var result = Data(capacity: byteRange.count)
        for page in pages {
            guard let pageData = self.dataFromPage(page: page, byteRange: byteRange) else {
                throw MP4Error.internalError("Error in MP4PaginReader: missing page")
            }
            result.append(pageData)
        }
        
        return result
    }
    
}
