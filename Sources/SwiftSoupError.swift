//
//  Exception.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 02/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

protocol SwiftSoupError: Error {
    
}

public struct IllegalArgumentError: SwiftSoupError {
    var localizedDescription: String
    
    init(message: String) {
        localizedDescription = message
    }
}

public struct SelectorParseError: SwiftSoupError {
    var localizedDescription: String
    
    init(message: String) {
        localizedDescription = message
    }
}
