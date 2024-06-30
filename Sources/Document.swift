//
//  Document.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/// An ``Element`` representing an HTML document.
///
/// ``Document`` is a main object of ``PrettySwiftSoup``.
/// In most cases, an HTML document is first parsed into a ``Document`` instance
/// using the static method ``HTMLParser/parse(_:baseURI:)`` of ``HTMLParser``.
/// Then, you manipulate the document with members of its superclasses or itself.
/// ```swift
/// let url = URL(string: "https://www.swift.org")!
/// let data = try! Data(contentsOf: url)
/// let html = String(data: data, encoding: .utf8)!
/// if let document = HTMLParser.parse(html) {
///     // do something with document...
/// }
/// ```
///
/// A ``Document`` is commonly treated as an ``Element`` since it is a subclass of ``Element``. Useful methods from ``Element`` (or even ``Node``), such as ``Element/getElementById(_:)`` or ``Element/getChild(at:)``, are also essential for ``Document``. For more information, please check ``Element`` documentation.
/// ```swift
/// // Get an element with id "soup"
/// let soupElement: Element? = document.getElementById("soup")
/// // Get the first child of the first child of a document
/// let grandkid: Element? = document.firstChild?.firstChild
/// // Append an element to children
/// if let grandkid {
///     document.appendChild(grandkid)
/// }
/// // Get HTML string
/// let htmlString: String = document.html ?? ""
/// ```
///
/// ``Document`` contains members specifically useful for an HTML document. 
/// For example, you can get ``head`` and ``body`` from a document.
/// The property ``charset`` represents which text-encoding is used to represent a document.
open class Document: Element {
    public enum QuirksMode {
        case noQuirks, quirks, limitedQuirks
    }

    public var outputSettings = OutputSettings()
    private var _quirksMode: Document.QuirksMode = QuirksMode.noQuirks
    /// An alias of a document's base URI.
    public let location: String

    /// Create an empty document.
    public init(baseURI: String) {
        self.location = baseURI
        super.init(tag: try! Tag.valueOf("#root", ParseSettings.htmlDefault), baseURI: baseURI)
    }

    /// Create a valid and empty shell of a document suitable for adding more elements to.
    static public func createShell(baseURI: String) -> Document {
        let doc: Document = Document(baseURI: baseURI)
        let html: Element = try! doc.appendElement(tagName: "html")
        try! html.appendElement(tagName: "head")
        try! html.appendElement(tagName: "body")

        return doc
    }

    /// A head element of this document.
    public var head: Element? {
        findFirstElementByTagName("head", self)
    }

    /// A body element of this document.
    public var body: Element? {
        return findFirstElementByTagName("body", self)
    }

    /**
     Get the string contents of the document's {@code title} element.
     @return Trimmed title, or empty string if none set.
     */
    
    /// A String value representing contents of the title element.
    public var title: String? {
        // title is a preserve whitespace tag (for document output), but normalised here
        get {
            if let titleElement = getElementsByTag("title").first {
                return StringUtil.normaliseWhitespace(titleElement.getText()).trim()
            } else {
                return nil
            }
        }
        set {
            if let newValue {
                if let titleElement = getElementsByTag("title").first {
                    titleElement.setText(newValue)
                } else {
                    try! head?.appendElement(tagName: "title").setText(newValue)
                }
            } else if let titleElement = getElementsByTag("title").first {
                titleElement.remove()
            }
        }
    }

    /// Create a new element with the given tag name.
    ///
    /// Create a new ``Element`` instance with the base URI of this document and the specified tag name. This method does not add the created element to this document.
    ///
    /// - Parameter tagName: A tag name of new element.
    /// - Returns: A new element.
    public func createElement(withTagName tagName: String) throws -> Element {
        return try Element(tag: Tag.valueOf(tagName, ParseSettings.preserveCase), baseURI: self.baseURI!)
    }

    /// Normalize this document.
    ///
    /// This happens after the parse phase so generally does not need to be called. Moves any text content that is not in the body element into the body.
    ///
    /// - Returns: This document after normalization.
    @discardableResult
    public func normalise() throws -> Document {
        var htmlElement = findFirstElementByTagName("html", self)
        if htmlElement == nil {
            htmlElement = try! appendElement(tagName: "html")
        }
        guard let htmlElement else {
            fatalError("htmlElement can't be `nil`")
        }

        if head == nil {
            try! htmlElement.prependElement(tagName: "head")
        }
        if body == nil {
            try! htmlElement.appendElement(tagName: "body")
        }

        // pull text nodes out of root, html, and head els, and push into body. non-text nodes are already taken care
        // of. do in inverse order to maintain text order.
        try normaliseTextNodes(head!)
        try normaliseTextNodes(htmlElement)
        try normaliseTextNodes(self)

        normaliseStructure("head", htmlElement)
        normaliseStructure("body", htmlElement)

        ensureMetaCharsetElement()

        return self
    }

    // does not recurse.
    private func normaliseTextNodes(_ element: Element) throws {
        var toMove: [Node] = []
        for node: Node in element.childNodes {
            if let tn = (node as? TextNode) {
                if (!tn.isBlank()) {
                    toMove.append(tn)
                }
            }
        }

        for i in (0..<toMove.count).reversed() {
            let node: Node = toMove[i]
            try element.removeChild(node)
            body?.prependChild(TextNode(" ", ""))
            body?.prependChild(node)
        }
    }

    // merge multiple <head> or <body> contents into one, delete the remainder, and ensure they are owned by <html>
    private func normaliseStructure(_ tag: String, _ htmlEl: Element) {
        let elements: Elements = self.getElementsByTag(tag)
        let master: Element? = elements.first // will always be available as created above if not existent
        if (elements.count > 1) { // dupes, move contents to master
            var toMove: Array<Node> = Array<Node>()
            for i in 1..<elements.count {
                let dupe: Node = elements.get(index: i)!
                for node: Node in dupe.childNodes {
                    toMove.append(node)
                }
                dupe.remove()
            }

            for dupe: Node in toMove {
                master?.appendChild(dupe)
            }
        }
        // ensure parented by <html>
        if (!(master != nil && master!.parent != nil && master!.parent!.equals(htmlEl))) {
            htmlEl.appendChild(master!) // includes remove()
        }
    }

    // fast method to get first by tag name, used for html, head, body finders
    private func findFirstElementByTagName(_ tag: String, _ node: Node) -> Element? {
        if (node.nodeName == tag) {
            return node as? Element
        } else {
            for child: Node in node.childNodes {
                let found: Element? = findFirstElementByTagName(tag, child)
                if (found != nil) {
                    return found
                }
            }
        }
        return nil
    }

    open override var outerHTML: String? {
        return super.html // no outer wrapper tag
    }

    @discardableResult
    public override func setText(_ text: String) -> Element {
        body?.setText(text) // overridden to not nuke doc structure
        return self
    }

    /// The node name of this node.
    ///
    /// In ``Document``, this is the literal "#document".
    open override var nodeName: String {
        return "#document"
    }
    
    /// A text encoding used in this document.
    public var charset: String.Encoding {
        get {
            outputSettings.charset()
        }
        set {
            outputSettings.charset(newValue)
            ensureMetaCharsetElement()
        }
    }

    /**
     * Ensures a meta charset (html) or xml declaration (xml) with the current
     * encoding used. This only applies with
     * {@link #updateMetaCharsetElement(boolean) updateMetaCharset} set to
     * <tt>true</tt>, otherwise this method does nothing.
     *
     * <ul>
     * <li>An exsiting element gets updated with the current charset</li>
     * <li>If there's no element yet it will be inserted</li>
     * <li>Obsolete elements are removed</li>
     * </ul>
     *
     * <p><b>Elements used:</b></p>
     *
     * <ul>
     * <li><b>Html:</b> <i>&lt;meta charset="CHARSET"&gt;</i></li>
     * <li><b>Xml:</b> <i>&lt;?xml version="1.0" encoding="CHARSET"&gt;</i></li>
     * </ul>
     */
    private func ensureMetaCharsetElement() {
        let syntax: OutputSettings.Syntax = outputSettings.syntax()
        
        if syntax == .html {
            let metaCharset: Element? = select(cssQuery: "meta[charset]").first
            
            if (metaCharset != nil) {
                try! metaCharset?.setAttribute(withKey: "charset", newValue: charset.displayName())
            } else {
                let head: Element? = self.head
                
                if (head != nil) {
                    try! head?.appendElement(tagName: "meta").setAttribute(withKey: "charset", newValue: charset.displayName())
                }
            }
            
            // Remove obsolete elements
            let s = select(cssQuery: "meta[name=charset]")
            s.forEach{ $0.remove() }
            
        } else if syntax == .xml {
            let node: Node = getChildNodes()[0]
            if let decl = (node as? XmlDeclaration) {
                if (decl.name()=="xml") {
                    try! decl.setAttribute(withKey: "encoding", newValue: charset.displayName())
                    
                    if hasAttribute(withKey: "version") {
                        try! decl.setAttribute(withKey: "version", newValue: "1.0")
                    }
                } else {
                    let decl = XmlDeclaration("xml", baseURI ?? "", false)
                    try! decl.setAttribute(withKey: "version", newValue: "1.0")
                    try! decl.setAttribute(withKey: "encoding", newValue: charset.displayName())
                    
                    prependChild(decl)
                }
            } else {
                let decl = XmlDeclaration("xml", baseURI ?? "", false)
                try! decl.setAttribute(withKey: "version", newValue: "1.0")
                try! decl.setAttribute(withKey: "encoding", newValue: charset.displayName())
                
                prependChild(decl)
            }
        }
    }

    public func quirksMode() -> Document.QuirksMode {
        return _quirksMode
    }

    @discardableResult
    public func quirksMode(_ quirksMode: Document.QuirksMode) -> Document {
        self._quirksMode = quirksMode
        return self
    }

	public override func copy(with zone: NSZone? = nil) -> Any {
		let clone = Document(baseURI: location)
		return copy(clone: clone)
	}

	public override func copy(parent: Node?) -> Node {
		let clone = Document(baseURI: location)
		return copy(clone: clone, parent: parent)
	}

	public override func copy(clone: Node, parent: Node?) -> Node {
		let clone = clone as! Document
		clone.outputSettings = outputSettings.copy() as! OutputSettings
		clone._quirksMode = _quirksMode
		return super.copy(clone: clone, parent: parent)
	}

}

public class OutputSettings: NSCopying {
    /**
     * The output serialization syntax.
     */
    public enum Syntax {case html, xml}

    private var _escapeMode: Entities.EscapeMode  = Entities.EscapeMode.base
    private var _encoder: String.Encoding = String.Encoding.utf8 // Charset.forName("UTF-8")
    private var _prettyPrint: Bool = true
    private var _outline: Bool = false
    private var _indentAmount: UInt  = 1
    private var _syntax = Syntax.html

    public init() {}

    /**
     * Get the document's current HTML escape mode: <code>base</code>, which provides a limited set of named HTML
     * entities and escapes other characters as numbered entities for maximum compatibility; or <code>extended</code>,
     * which uses the complete set of HTML named entities.
     * <p>
     * The default escape mode is <code>base</code>.
     * @return the document's current escape mode
     */
    public func escapeMode() -> Entities.EscapeMode {
        return _escapeMode
    }

    /**
     * Set the document's escape mode, which determines how characters are escaped when the output character set
     * does not support a given character:- using either a named or a numbered escape.
     * @param escapeMode the new escape mode to use
     * @return the document's output settings, for chaining
     */
    @discardableResult
    public func escapeMode(_ escapeMode: Entities.EscapeMode) -> OutputSettings {
        self._escapeMode = escapeMode
        return self
    }

    /**
     * Get the document's current output charset, which is used to control which characters are escaped when
     * generating HTML (via the <code>html()</code> methods), and which are kept intact.
     * <p>
     * Where possible (when parsing from a URL or File), the document's output charset is automatically set to the
     * input charset. Otherwise, it defaults to UTF-8.
     * @return the document's current charset.
     */
    public func encoder() -> String.Encoding {
        return _encoder
    }
    public func charset() -> String.Encoding {
        return _encoder
    }

    /**
     * Update the document's output charset.
     * @param charset the new charset to use.
     * @return the document's output settings, for chaining
     */
    @discardableResult
    public func encoder(_ encoder: String.Encoding) -> OutputSettings {
        self._encoder = encoder
        return self
    }

    @discardableResult
    public func charset(_ e: String.Encoding) -> OutputSettings {
        return encoder(e)
    }

    /**
     * Get the document's current output syntax.
     * @return current syntax
     */
    public func syntax() -> Syntax {
        return _syntax
    }

    /**
     * Set the document's output syntax. Either {@code html}, with empty tags and boolean attributes (etc), or
     * {@code xml}, with self-closing tags.
     * @param syntax serialization syntax
     * @return the document's output settings, for chaining
     */
    @discardableResult
    public func syntax(syntax: Syntax) -> OutputSettings {
        _syntax = syntax
        return self
    }

    /**
     * Get if pretty printing is enabled. Default is true. If disabled, the HTML output methods will not re-format
     * the output, and the output will generally look like the input.
     * @return if pretty printing is enabled.
     */
    public func prettyPrint() -> Bool {
        return _prettyPrint
    }

    /**
     * Enable or disable pretty printing.
     * @param pretty new pretty print setting
     * @return this, for chaining
     */
    @discardableResult
    public func prettyPrint(pretty: Bool) -> OutputSettings {
        _prettyPrint = pretty
        return self
    }

    /**
     * Get if outline mode is enabled. Default is false. If enabled, the HTML output methods will consider
     * all tags as block.
     * @return if outline mode is enabled.
     */
    public func outline() -> Bool {
        return _outline
    }

    /**
     * Enable or disable HTML outline mode.
     * @param outlineMode new outline setting
     * @return this, for chaining
     */
    @discardableResult
    public func outline(outlineMode: Bool) -> OutputSettings {
        _outline = outlineMode
        return self
    }

    /**
     * Get the current tag indent amount, used when pretty printing.
     * @return the current indent amount
     */
    public func indentAmount() -> UInt {
        return _indentAmount
    }

    /**
     * Set the indent amount for pretty printing
     * @param indentAmount number of spaces to use for indenting each level. Must be {@literal >=} 0.
     * @return this, for chaining
     */
    @discardableResult
    public func indentAmount(indentAmount: UInt) -> OutputSettings {
        _indentAmount = indentAmount
        return self
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone: OutputSettings = OutputSettings()
        clone.charset(_encoder) // new charset and charset encoder
        clone._escapeMode = _escapeMode//Entities.EscapeMode.valueOf(escapeMode.name())
        // indentAmount, prettyPrint are primitives so object.clone() will handle
        return clone
    }

}
