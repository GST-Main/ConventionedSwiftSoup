//
//  HTMLParser.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/// An HTML parser.
///
/// A static method ``parse(_:baseURI:)`` is commonly used for parsing HTML.
public class HTMLParser: MarkupParser {
    /// Create an HTML parser.
    public init() {
        super.init(HtmlTreeBuilder())
    }

	// MARK: Static Methods
    /// Parse HTML into a ``HTMLDocument``.
    ///
    /// ``HTMLDocument`` is the main object of ``PrettySwiftSoup``. You can get ``HTMLDocument`` object by calling this static method.
    /// ```swift
    /// let url = URL(string: "https://www.swift.org")!
    /// let data = try! Data(contentsOf: url)
    /// let html = String(data: data, encoding: .utf8)!
    /// if let document = HTMLParser.parse(html) {
    ///     // do something with document...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///     - html: HTML string to parse.
    ///     - baseURI: Base URI of document for resolving resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: Parsed ``HTMLDocument`` object. If parser failed to parse the HTML string, returns `nil` instead.
    public static func parse(_ html: String, baseURI: String = "") -> HTMLDocument? {
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
    public static func parseHTMLFragment(_ fragmentHTML: String, context: HTMLElement?, baseURI: String = "") -> [Node]? {
        let treeBuilder = HtmlTreeBuilder()
        return try? treeBuilder.parseFragment(fragmentHTML, context, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }
    
    internal static func _parseHTMLFragment(_ fragmentHTML: String, context: HTMLElement?, baseURI: String = "") throws -> [Node] {
        let treeBuilder = HtmlTreeBuilder()
        return try treeBuilder.parseFragment(fragmentHTML, context, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }

    /// Parse a fragment of HTML into the ``HTMLDocument/body`` of a ``HTMLDocument``.
    ///
    /// - Parameters:
    ///     - bodyHTML: The fragment of HTML to parse.
    ///     - baseURI: Base URI of document for resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: Parsed ``HTMLDocument`` object, with empty ``HTMLDocument/head``, and HTML parsed into ``HTMLDocument/body``. If parser failed to parse HTML string, returns `nil` instead.
    public static func parseBodyFragment(_ bodyHTML: String, baseURI: String = "") -> HTMLDocument? {
        let document = HTMLDocument.createShell(baseURI: baseURI)
        if let body: HTMLElement = document.body, let nodes = parseHTMLFragment(bodyHTML, context: body, baseURI: baseURI) {
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
    
    // TODO: More descriptions (later)
    /// Get safe HTML from untrusted input HTML, by parsing input HTML and filtering it through a whitelist of permitted tags and attributes.
    public class func cleanBodyFragment(_ bodyHTML: String, baseURI: String = "", whitelist: Whitelist, settings: OutputSettings? = nil) throws -> String {
        guard let dirty: HTMLDocument = parseBodyFragment(bodyHTML, baseURI: baseURI) else {
            throw SwiftSoupError.failedToParseHTML
        }
        let cleaner = Cleaner(whitelist)
        let clean: HTMLDocument = try cleaner.clean(dirty)
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
            guard let dirty: HTMLDocument = parseBodyFragment(bodyHTML, baseURI: "") else {
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
}