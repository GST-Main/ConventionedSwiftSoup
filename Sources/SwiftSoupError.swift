import Foundation

protocol SwiftSoupError: Error {
    
}

public struct IllegalArgumentError: SwiftSoupError {
    var localizedDescription: String
    
    init(message: String) {
        localizedDescription = message
    }
    
    static let emptyAttributeKey = Self(message: "Attribute's key must not be empty")
    static let emptyTagName = Self(message: "Tag name must not be empty")
    static let emptyHTML = Self(message: "HTML must not be empty")
    static let notChildNode = Self(message: "Given node is not a child of caller")
    static let failedToParseHTML = Self(message: "Failed to parse HTML")
    static let noParentNode = Self(message: "No parent node to insert")
    static let noHTMLElementsToWrap = Self(message: "No HTML elements to wrap")
    static let noChildrenToUnwrap = Self(message: "No children elements to unwrap")
    static let indexOutOfBounds = Self(message: "Index out of bounds")
}

public struct SelectorParseError: SwiftSoupError {
    var localizedDescription: String
    
    init(message: String) {
        localizedDescription = message
    }
}
