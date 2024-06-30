//
//  HTMLParser.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/// Parses HTML into a ``Document``.
///
/// Generally, static method ``parseHTML(_:baseURI:)-swift.type.method`` is mostly recommended.
public class HTMLParser {
	private static let DEFAULT_MAX_ERRORS: Int = 0 // by default, error tracking is disabled.

	public var treeBuilder: TreeBuilder
	public var maxErrors: Int = DEFAULT_MAX_ERRORS
	public private(set) var errors: ParseErrorList = ParseErrorList(16, 16)
    public var isTrackErrors: Bool { maxErrors > 0 }
	public var settings: ParseSettings

    /// Create a new ``HTMLParser`` using the specified ``TreeBuilder``
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
	public func parseHTML(_ html: String, baseURI: String) throws -> Document {
		errors = isTrackErrors ? ParseErrorList.tracking(maxErrors) : ParseErrorList.noTracking()
		return try treeBuilder.parse(html, baseURI, errors, settings)
	}

	// MARK: Static Methods
    /// Parse HTML into a ``Document``.
    ///
    /// ``Document`` is the main object of ``SwiftSoup``. You can get ``Document`` object by calling this static method.
    /// ```swift
    /// let url = URL(string: "https://www.swift.org")!
    /// let data = try! Data(contentsOf: url)
    /// let html = String(data: data, encoding: .utf8)!
    /// if let document = HTMLParser.parseHTML(html) {
    ///     // do something with document...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///     - html: HTML string to parse.
    ///     - baseURI: Base URI of document for resolving resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: Parsed ``Document`` object. If parser failed to parse the HTML string, returns `nil` instead.
    public static func parseHTML(_ html: String, baseURI: String = "") -> Document? {
        let treeBuilder: TreeBuilder = HtmlTreeBuilder()
        return try? treeBuilder.parse(html, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }

    /// Parse a fragment of HTML into a list of nodes. The context element, if supplied, supplies parsing context.
    ///
    /// - Parameters:
    ///     - fragmentHTML: The fragment of HTML to parse.
    ///     - context: The element that this HTML fragment is being parsed for (i.e. for inner HTML). this provides stack context for implicit element creation).
    ///     - baseURI: Base URI of document for resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: An array of nodes parsed from the given HTML. If parser failed to parse the HTML string, returns `nil` instead. Note that the context element, if supplied, is not modified.
    public static func parseHTMLFragment(_ fragmentHTML: String, context: Element?, baseURI: String = "") -> [Node]? {
        let treeBuilder = HtmlTreeBuilder()
        return try? treeBuilder.parseFragment(fragmentHTML, context, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }
    
    internal static func _parseHTMLFragment(_ fragmentHTML: String, context: Element?, baseURI: String = "") throws -> [Node] {
        let treeBuilder = HtmlTreeBuilder()
        return try treeBuilder.parseFragment(fragmentHTML, context, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }

    /// Parse a fragment of XML into a list of nodes.
    ///
    /// - Parameters:
    ///     - fragmentXML: The fragment of XML to parse.
    ///     - baseURI: Base URI of document for resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: An array of nodes parsed from the input XML. If parser failed to parse the XML string, returns `nil` instead.
    public static func parseXMLFragment(_ fragmentXML: String, baseURI: String = "") -> [Node]? {
        let treeBuilder: XmlTreeBuilder = XmlTreeBuilder()
        return try? treeBuilder.parseFragment(fragmentXML, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }

    /// Parse a fragment of HTML into the ``Document/body`` of a ``Document``.
    ///
    /// - Parameters:
    ///     - bodyHTML: The fragment of HTML to parse.
    ///     - baseURI: Base URI of document for resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: Parsed ``Document`` object, with empty ``Document/head``, and HTML parsed into ``Document/body``. If parser failed to parse HTML string, returns `nil` instead.
    public static func parseBodyFragment(_ bodyHTML: String, baseURI: String = "") -> Document? {
        let document = Document.createShell(baseURI: baseURI)
        if let body: Element = document.body, let nodes = parseHTMLFragment(bodyHTML, context: body, baseURI: baseURI) {
            if nodes.count > 0 {
                for i in 1..<nodes.count {
                    nodes[i].remove()
                }
            }
            for node: Node in nodes {
                body.appendChild(node)
            }
        }
        return document
    }
    
    /// Get safe HTML from untrusted input HTML, by parsing input HTML and filtering it through a whitelist of permitted tags and attributes.
    ///
    /// This is legacy and throwing version of ``HTMLParser/cleanBodyFragment(_:baseURI:whitelist:settings:)``.
    ///
    /// - Note: As this method throws ``SwiftSoupError/failedToParseHTML`` error only, use the new method ``HTMLParser/cleanBodyFragment(_:baseURI:whitelist:settings:)`` instead.
    public class func cleanBodyFragment(_ bodyHTML: String, baseURI: String = "", whitelist: Whitelist, settings: OutputSettings? = nil) throws -> String {
        guard let dirty: Document = parseBodyFragment(bodyHTML, baseURI: baseURI) else {
            throw SwiftSoupError.failedToParseHTML
        }
        let cleaner = Cleaner(whitelist)
        let clean: Document = try cleaner.clean(dirty)
        if let settings {
            clean.outputSettings = settings
        }
        guard let body = clean.body else {
            throw SwiftSoupError(message: "No body fragment after cleaning")
        }
        guard let html = body.html else {
            throw SwiftSoupError(message: "Illegal HTML after cleaning")
        }
        return html
    }

    /// Check if the given HTML has only tags and attributes allowed by the ``Whitelist``.
    ///
    /// Test if the given HTML has only tags and attributes allowed by the whitelist. This is useful for form validation. The HTML should still be run through the cleaner to set up enforced attributes and to tidy the output.
    ///
    /// - Parameters:
    ///     - bodyHTML: A HTML string to check.
    ///     - whitelist: Whitelist to test against.
    /// - Returns: Returns true if no tags or attributes were removed. Otherwise, returns false.
    /// # See Also
    /// * ``Cleaner``
    public static func validateBodyFragment(_ bodyHTML: String, whitelist: Whitelist) -> Bool {
        do {
            guard let dirty: Document = parseBodyFragment(bodyHTML, baseURI: "") else {
                return false
            }
            let cleaner  = Cleaner(whitelist)
            return try cleaner.isValid(dirty)
        } catch {
            return false
        }
    }

    /// An utility method to unescape HTML entities from a string.
    ///
    /// - Parameters:
    ///     - string: A HTML escaped string.
    ///     - inAttribute: If the string is to be escaped in strict mode (as attributes are).
    /// - Returns: An unescaped string.
	public static func unescapeEntities(_ string: String, _ inAttribute: Bool) throws -> String {
		let tokeniser: Tokeniser = Tokeniser(CharacterReader(string), ParseErrorList.noTracking())
		return try tokeniser.unescapeEntities(inAttribute)
	}

	// MARK: Builders
    /// Create a new HTML parser.
    ///
    /// This parser treats input as HTML5, and enforces the creation of a normalised document based on a knowledge of the semantics of the incoming tags.
    ///
    /// - Returns: A new HTML parser.
	public static func htmlParser() -> HTMLParser {
		return HTMLParser(HtmlTreeBuilder())
	}

    /// Create a new XML parser.
    ///
    /// This parser assumes no knowledge of the incoming tags and does not treat it as HTML rather creates a simple tree directly from the input.
    ///
    /// - Returns: A new simple XML parser.
	public static func xmlParser() -> HTMLParser {
		return HTMLParser(XmlTreeBuilder())
	}
}
