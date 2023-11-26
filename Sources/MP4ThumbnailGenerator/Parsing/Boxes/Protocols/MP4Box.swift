//
//  MP4Box.swift
//  WebDAV Photos
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation


public protocol MP4Box: CustomStringConvertible {
    var typeName: String { get }
    
    var children: [MP4Box] { get }
    
    func indentedString(level: Int) -> String
}

// MARK: Child accessors
public extension MP4Box {
    var children: [MP4Box] { [] }
    
    func children(ofType typeName: any StringProtocol) -> [MP4Box] {
        children.filter { $0.typeName == typeName }
    }
    
    func children<T: MP4ParsableBox>(ofType type: T.Type) -> [T] {
        children.filter { $0.typeName == type.typeName }.map { $0 as! T }
    }
    
    func firstChild(ofType typeName: any StringProtocol) -> MP4Box? {
        children.first { $0.typeName == typeName }
    }
    
    func firstChild<T: MP4ParsableBox>(ofType type: T.Type) -> T? {
        children.first { $0.typeName == type.typeName } as? T
    }
}

// MARK: Path
public extension MP4Box {
    func children(path: [any StringProtocol]) -> [any MP4Box] {
        var workingArray: [any MP4Box] = [self]
        for step in path {
            guard !workingArray.isEmpty else { return [] }
            workingArray = workingArray.flatMap { box in
                box.children(ofType: step)
            }
        }
        
        return workingArray
    }
    
    func firstChild(path: [any StringProtocol]) -> (any MP4Box)? {
        // This may be faster with dfs but its fine for now
        var workingArray: [any MP4Box] = [self]
        for step in path {
            guard !workingArray.isEmpty else { return nil }
            workingArray = workingArray.flatMap { box in
                box.children(ofType: step)
            }
        }
        
        return workingArray.first
    }
    
    func children(path: String) -> [any MP4Box] {
        children(path: path.split(separator: "."))
    }
    
    func firstChild(path: String) -> (any MP4Box)? {
        firstChild(path: path.split(separator: "."))
    }
}

// MARK: CustomStringConvertible
public extension MP4Box {
    func indentedString(level: Int = 0) -> String {
        var result = String(repeating: "  ", count: level) + typeName
        if !children.isEmpty {
            result += "\n" + children.map {$0.indentedString(level: level+1)}.joined(separator: "\n")
        }
        return result
    }
    
    var description: String {
        self.indentedString()
    }
}
