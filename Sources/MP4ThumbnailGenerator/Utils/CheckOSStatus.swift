//
//  CheckOSStatus.swift
//
//
//  Created by Matteo Ludwig on 19.11.23.
//

import Foundation

func errorFromOSStatus(_ status: OSStatus) -> Error? {
    guard status != noErr else {
        return nil
    }
    
    return NSError(domain: NSOSStatusErrorDomain, code: Int(status), 
                   userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status, nil) ?? "Unknown error"])
}

func checkOSStatus(_ status: OSStatus) throws{
    if let error = errorFromOSStatus(status) {
        throw error
    }
}
