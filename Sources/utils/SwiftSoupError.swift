import Foundation

public struct SwiftSoupError: Error, Equatable {
    var localizedDescription: String
    
    init(message: String) {
        localizedDescription = message
    }
    
    public static let emptyAttributeKey = Self(message: "Attribute's key must not be empty")
    public static let emptyTagName = Self(message: "Tag name must not be empty")
    public static let emptyHTML = Self(message: "HTML must not be empty")
    public static let notChildNode = Self(message: "Given node is not a child of caller")
    public static let failedToParseHTML = Self(message: "Failed to parse HTML")
    public static let noParentNode = Self(message: "No parent node to insert")
    public static let noHTMLElementsToWrap = Self(message: "No HTML elements to wrap")
    public static let noChildrenToUnwrap = Self(message: "No children elements to unwrap")
    public static let indexOutOfBounds = Self(message: "Index out of bounds")
    public static let noHref = Self(message: "No \"href\" attribute")
}
