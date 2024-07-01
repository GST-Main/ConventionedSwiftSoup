import Foundation

/// A parser of markup languages like HTML and XML.
///
/// This is a base class for both ``HTMLParser`` and ``XMLParser``. Genrally, it is not used directly. Use ``HTMLParser`` for parsing an HTML document and ``XMLParser`` for parsing an XML document.
open class MarkupParser {
    internal static let DEFAULT_MAX_ERRORS: Int = 0 // by default, error tracking is disabled.

    public var treeBuilder: TreeBuilder
    public var maxErrors: Int = DEFAULT_MAX_ERRORS
    public private(set) var errors: ParseErrorList = ParseErrorList(16, 16)
    public var isTrackErrors: Bool { maxErrors > 0 }
    public var settings: ParseSettings

    /// Create a new ``MarkupParser`` using the specified ``TreeBuilder``
    /// - Parameters:
    ///     - treeBuilder: A ``TreeBuilder`` object to use to parse input into ``HTMLDocument``s.
    public init(_ treeBuilder: TreeBuilder) {
        self.treeBuilder = treeBuilder
        self.settings = treeBuilder.defaultSettings()
    }

    /// Parse given markup code into a ``HTMLDocument``.
    ///
    /// - Parameters:
    ///     - source: A markup-based code to parse.
    ///     - baseURI: The base URI of document for resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: Parsed ``HTMLDocument`` object.
    ///
    /// ## Throws:
    /// * `SwiftSoupError.failedToParseHTML` if parsing is failed.
    public func parse(_ source: String, baseURI: String) throws -> HTMLDocument {
        errors = isTrackErrors ? ParseErrorList.tracking(maxErrors) : ParseErrorList.noTracking()
        return try treeBuilder.parse(source, baseURI, errors, settings)
    }
}
