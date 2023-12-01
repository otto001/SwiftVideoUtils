//
//  File.swift
//  
//
//  Created by Matteo Ludwig on 23.11.23.
//

import Foundation


extension Optional {
    func unwrapOrFail(with error: any Error) throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        }
        throw error
    }
}

extension Optional where Wrapped: MP4ParsableBox {
    func unwrapOrFail() throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        }
        throw MP4Error.failedToFindBox(path: Wrapped.typeName)
    }
}
