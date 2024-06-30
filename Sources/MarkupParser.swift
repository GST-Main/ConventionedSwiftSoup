import Foundation

open class MarkupParser {
    internal static let DEFAULT_MAX_ERRORS: Int = 0 // by default, error tracking is disabled.

    public var treeBuilder: TreeBuilder
    public var maxErrors: Int = DEFAULT_MAX_ERRORS
    public private(set) var errors: ParseErrorList = ParseErrorList(16, 16)
    public var isTrackErrors: Bool { maxErrors > 0 }
    public var settings: ParseSettings

    /// Create a new ``Parser`` using the specified ``TreeBuilder``
    /// - Parameters:
    ///     - treeBuilder: A ``TreeBuilder`` object to use to parse input into ``Document``s.
    init(_ treeBuilder: TreeBuilder) {
        self.treeBuilder = treeBuilder
        self.settings = treeBuilder.defaultSettings()
    }

    /// Parse HTML into a ``Document``.
    ///
    /// - Parameters:
    ///     - html: HTML string to parse.
    ///     - baseURI: Base URI of document for resolving resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: Parsed ``Document`` object.
    ///
    /// You can track parse errors whereas static method ``parseHTML(_:baseURI:)-swift.type.method`` can't.
    ///
    /// ## Throws:
    /// * `SwiftSoupError.failedToParseHTML`` if parsing is failed.
    public func parse(_ input: String, baseURI: String) throws -> Document {
        errors = isTrackErrors ? ParseErrorList.tracking(maxErrors) : ParseErrorList.noTracking()
        return try treeBuilder.parse(input, baseURI, errors, settings)
    }
}
