//
//  Parser.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/**
* Parses HTML into a {@link Document}. Generally best to use one of the  more convenient parse methods
* in {@link SwiftSoup}.
*/
public class Parser {
	private static let DEFAULT_MAX_ERRORS: Int = 0 // by default, error tracking is disabled.

	public var treeBuilder: TreeBuilder
	public var maxErrors: Int = DEFAULT_MAX_ERRORS
	public private(set) var errors: ParseErrorList = ParseErrorList(16, 16)
    public var isTrackErrors: Bool { maxErrors > 0 }
	public var settings: ParseSettings

	/**
	* Create a new Parser, using the specified TreeBuilder
	* @param treeBuilder TreeBuilder to use to parse input into Documents.
	*/
	init(_ treeBuilder: TreeBuilder) {
		self.treeBuilder = treeBuilder
        self.settings = treeBuilder.defaultSettings()
	}

    // TODO: Document
	public func parseHTML(_ html: String, baseURI: String) throws -> Document {
		errors = isTrackErrors ? ParseErrorList.tracking(maxErrors) : ParseErrorList.noTracking()
		return try treeBuilder.parse(html, baseURI, errors, settings)
	}

	// MARK: Static Methods
	/**
	* Parse HTML into a Document.
	*
	* @param html HTML to parse
	* @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
	*
	* @return parsed Document
	*/
    public static func parseHTML(_ html: String, baseURI: String = "") -> Document? {
        return try? _parseHTML(html, baseURI: baseURI)
    }
    public class func _parseHTML(_ html: String, baseURI: String = "") throws -> Document {
        let treeBuilder: TreeBuilder = HtmlTreeBuilder()
        return try treeBuilder.parse(html, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }

	/**
	* Parse a fragment of HTML into a list of nodes. The context element, if supplied, supplies parsing context.
	*
	* @param fragmentHtml the fragment of HTML to parse
	* @param context (optional) the element that this HTML fragment is being parsed for (i.e. for inner HTML). This
	* provides stack context (for implicit element creation).
	* @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
	*
	* @return list of nodes parsed from the input HTML. Note that the context element, if supplied, is not modified.
	*/
    public static func parseHTMLFragment(_ fragmentHTML: String, context: Element?, baseURI: String = "") -> Array<Node>? {
        return try? _parseHTMLFragment(fragmentHTML, context: context, baseURI: baseURI)
    }
    public class func _parseHTMLFragment(_ fragmentHTML: String, context: Element?, baseURI: String = "") throws -> Array<Node> {
        let treeBuilder = HtmlTreeBuilder()
        return try treeBuilder.parseFragment(fragmentHTML, context, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }

    // TODO: Document

	/**
	* Parse a fragment of XML into a list of nodes.
	*
	* @param fragmentXml the fragment of XML to parse
	* @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
	* @return list of nodes parsed from the input XML.
	*/
    public static func parseXMLFragment(_ fragmentXML: String, baseURI: String = "") -> Array<Node>? {
        return try? _parseXMLFragment(fragmentXML, baseURI: baseURI)
    }
    public class func _parseXMLFragment(_ fragmentXML: String, baseURI: String = "") throws -> Array<Node> {
        let treeBuilder: XmlTreeBuilder = XmlTreeBuilder()
        return try treeBuilder.parseFragment(fragmentXML, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }

	/**
	* Parse a fragment of HTML into the {@code body} of a Document.
	*
	* @param bodyHtml fragment of HTML
	* @param baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
	*
	* @return Document, with empty head, and HTML parsed into body
	*/
    public static func parseBodyFragment(_ bodyHTML: String, baseURI: String = "") -> Document? {
        return try? _parseBodyFragment(bodyHTML, baseURI: baseURI)
    }
    public class func _parseBodyFragment(_ bodyHTML: String, baseURI: String = "") throws -> Document {
        let document = Document.createShell(baseURI)
        if let body: Element = document.body() {
            let nodeList: Array<Node> = try _parseHTMLFragment(bodyHTML, context: body, baseURI: baseURI)
            if nodeList.count > 0 {
                for i in 1..<nodeList.count {
                    try nodeList[i].remove()
                }
            }
            for node: Node in nodeList {
                try body.appendChild(node)
            }
        }
        return document
    }
    
    // FIXME: Document
    /**
    * Get safe HTML from untrusted input HTML, by parsing input HTML and filtering it through a white-list of
    * permitted
    * tags and attributes.
    *
    * @param bodyHtml input untrusted HTML (body fragment)
    * @param baseUri URL to resolve relative URLs against
    * @param whitelist white-list of permitted HTML elements
    * @param outputSettings document output settings; use to control pretty-printing and entity escape modes
    * @return safe HTML (body fragment)
    * @see Cleaner#clean(Document)
    */
    public class func cleanBodyFragment(_ bodyHTML: String, baseURI: String = "", whitelist: Whitelist, settings: OutputSettings? = nil) -> String? {
        return try? _cleanBodyFragment(bodyHTML, baseURI: baseURI, whitelist: whitelist, settings: settings)
    }
    public class func _cleanBodyFragment(_ bodyHTML: String, baseURI: String = "", whitelist: Whitelist, settings: OutputSettings? = nil) throws -> String {
        let dirty: Document = try _parseBodyFragment(bodyHTML, baseURI: baseURI)
        let cleaner = Cleaner(whitelist)
        let clean: Document = try cleaner.clean(dirty)
        if let settings {
            clean.outputSettings(settings)
        }
        guard let body = clean.body() else {
            throw IllegalArgumentError(message: "No body fragment after cleaning")
        }
        return try body.html()
    }

    /**
     Test if the input HTML has only tags and attributes allowed by the Whitelist. Useful for form validation. The input HTML should
     still be run through the cleaner to set up enforced attributes, and to tidy the output.
     @param bodyHtml HTML to test
     @param whitelist whitelist to test against
     @return true if no tags or attributes were removed; false otherwise
     @see #clean(String, Whitelist)
     */
    public static func validateBodyFragment(_ bodyHTML: String, whitelist: Whitelist) -> Bool {
        do {
            let dirty: Document = try _parseBodyFragment(bodyHTML, baseURI: "")
            let cleaner  = Cleaner(whitelist)
            return try cleaner.isValid(dirty)
        } catch {
            return false
        }
    }

	/**
	* Utility method to unescape HTML entities from a string
	* @param string HTML escaped string
	* @param inAttribute if the string is to be escaped in strict mode (as attributes are)
	* @return an unescaped string
	*/
	public static func unescapeEntities(_ string: String, _ inAttribute: Bool)throws->String {
		let tokeniser: Tokeniser = Tokeniser(CharacterReader(string), ParseErrorList.noTracking())
		return try tokeniser.unescapeEntities(inAttribute)
	}

	/**
	* @param bodyHtml HTML to parse
	* @param baseUri baseUri base URI of document (i.e. original fetch location), for resolving relative URLs.
	*
	* @return parsed Document
	* @deprecated Use {@link #parseBodyFragment} or {@link #parseFragment} instead.
	*/
	public static func parseBodyFragmentRelaxed(_ bodyHtml: String, baseURI: String) throws -> Document {
        return try Parser._parseHTML(bodyHtml, baseURI: baseURI)
	}

	// MARK: Builders
	/**
	* Create a new HTML parser. This parser treats input as HTML5, and enforces the creation of a normalised document,
	* based on a knowledge of the semantics of the incoming tags.
	* @return a new HTML parser.
	*/
	public static func htmlParser() -> Parser {
		return Parser(HtmlTreeBuilder())
	}

	/**
	* Create a new XML parser. This parser assumes no knowledge of the incoming tags and does not treat it as HTML,
	* rather creates a simple tree directly from the input.
	* @return a new simple XML parser.
	*/
	public static func xmlParser() -> Parser {
		return Parser(XmlTreeBuilder())
	}
}
