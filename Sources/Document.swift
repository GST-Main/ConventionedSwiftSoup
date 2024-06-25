//
//  Document.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

open class Document: Element {
    public enum QuirksMode {
        case noQuirks, quirks, limitedQuirks
    }

    public var outputSettings = OutputSettings()
    private var _quirksMode: Document.QuirksMode = QuirksMode.noQuirks
    public let location: String
    private var updateMetaCharset: Bool = false

    /**
     Create a new, empty Document.
     @param baseUri base URI of document
     @see SwiftSoup#parse
     @see #createShell
     */
    public init(baseURI: String) {
        self.location = baseURI
        super.init(try! Tag.valueOf("#root", ParseSettings.htmlDefault), baseURI)
    }

    /**
     Create a valid, empty shell of a document, suitable for adding more elements to.
     @param baseUri baseUri of document
     @return document with html, head, and body elements.
     */
    static public func createShell(baseURI: String) -> Document {
        let doc: Document = Document(baseURI: baseURI)
        let html: Element = try! doc.appendElement(tagName: "html")
        try! html.appendElement(tagName: "head")
        try! html.appendElement(tagName: "body")

        return doc
    }

    /**
     Accessor to the document's {@code head} element.
     @return {@code head}
     */
    public var head: Element? {
        findFirstElementByTagName("head", self)
    }

    /**
     Accessor to the document's {@code body} element.
     @return {@code body}
     */
    public var body: Element? {
        return findFirstElementByTagName("body", self)
    }

    /**
     Get the string contents of the document's {@code title} element.
     @return Trimmed title, or empty string if none set.
     */
    public var title: String? {
        // title is a preserve whitespace tag (for document output), but normalised here
        if let titleElement = getElementsByTag("title")?.first {
            return StringUtil.normaliseWhitespace(titleElement.getText()).trim()
        } else {
            return nil
        }
    }

    /**
     Set the document's {@code title} element. Updates the existing element, or adds {@code title} to {@code head} if
     not present
     @param title string to set as title
     */
    public func setTitle(_ title: String) throws {
        if let titleElement = getElementsByTag("title")?.first {
            try titleElement.setText(title)
        } else {
            try head?.appendElement(tagName: "title").setText(title)
        }
    }

    /**
     Create a new Element, with this document's base uri. Does not make the new element a child of this document.
     @param tagName element tag name (e.g. {@code a})
     @return new element
     */
    public func createElement(withTagName tagName: String) throws -> Element {
        return try Element(Tag.valueOf(tagName, ParseSettings.preserveCase), self.baseURI!)
    }

    /**
     Normalise the document. This happens after the parse phase so generally does not need to be called.
     Moves any text content that is not in the body element into the body.
     @return this document after normalisation
     */
    @discardableResult
    public func normalise() throws -> Document {
        var htmlElement = findFirstElementByTagName("html", self)
        if htmlElement == nil {
            htmlElement = try appendElement(tagName: "html")
        }
        guard let htmlElement else {
            fatalError("htmlElement can't be `nil`")
        }

        if head == nil {
            try htmlElement.prependElement(tagName: "head")
        }
        if body == nil {
            try htmlElement.appendElement(tagName: "body")
        }

        // pull text nodes out of root, html, and head els, and push into body. non-text nodes are already taken care
        // of. do in inverse order to maintain text order.
        try normaliseTextNodes(head!)
        try normaliseTextNodes(htmlElement)
        try normaliseTextNodes(self)

        try normaliseStructure("head", htmlElement)
        try normaliseStructure("body", htmlElement)

        try ensureMetaCharsetElement()

        return self
    }

    // does not recurse.
    private func normaliseTextNodes(_ element: Element) throws {
        var toMove: Array<Node> =  Array<Node>()
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
            try body?.prependChild(TextNode(" ", ""))
            try body?.prependChild(node)
        }
    }

    // merge multiple <head> or <body> contents into one, delete the remainder, and ensure they are owned by <html>
    private func normaliseStructure(_ tag: String, _ htmlEl: Element) throws {
        guard let elements: Elements = self.getElementsByTag(tag) else {
            throw IllegalArgumentError(message: "Cannot get elements") // FIXME: fixme
        }
        let master: Element? = elements.first // will always be available as created above if not existent
        if (elements.count > 1) { // dupes, move contents to master
            var toMove: Array<Node> = Array<Node>()
            for i in 1..<elements.count {
                let dupe: Node = elements.get(index: i)!
                for node: Node in dupe.childNodes {
                    toMove.append(node)
                }
                try dupe.remove()
            }

            for dupe: Node in toMove {
                try master?.appendChild(dupe)
            }
        }
        // ensure parented by <html>
        if (!(master != nil && master!.parent != nil && master!.parent!.equals(htmlEl))) {
            try htmlEl.appendChild(master!) // includes remove()
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

    /**
     Set the text of the {@code body} of this document. Any existing nodes within the body will be cleared.
     @param text unencoded text
     @return this document
     */
    @discardableResult
    public override func setText(_ text: String) throws -> Element {
        try body?.setText(text) // overridden to not nuke doc structure
        return self
    }

    open override var nodeName: String {
        return "#document"
    }

    /**
     * Sets the charset used in this document. This method is equivalent
     * to {@link OutputSettings#charset(java.nio.charset.Charset)
     * OutputSettings.charset(Charset)} but in addition it updates the
     * charset / encoding element within the document.
     *
     * <p>This enables
     * {@link #updateMetaCharsetElement(boolean) meta charset update}.</p>
     *
     * <p>If there's no element with charset / encoding information yet it will
     * be created. Obsolete charset / encoding definitions are removed!</p>
     *
     * <p><b>Elements used:</b></p>
     *
     * <ul>
     * <li><b>Html:</b> <i>&lt;meta charset="CHARSET"&gt;</i></li>
     * <li><b>Xml:</b> <i>&lt;?xml version="1.0" encoding="CHARSET"&gt;</i></li>
     * </ul>
     *
     * @param charset Charset
     *
     * @see #updateMetaCharsetElement(boolean)
     * @see OutputSettings#charset(java.nio.charset.Charset)
     */
    public func charset(_ charset: String.Encoding) throws {
        updateMetaCharsetElement(true)
        outputSettings.charset(charset)
        try ensureMetaCharsetElement()
    }

    /**
     * Returns the charset used in this document. This method is equivalent
     * to {@link OutputSettings#charset()}.
     *
     * @return Current Charset
     *
     * @see OutputSettings#charset()
     */
    public var charset: String.Encoding {
        outputSettings.charset()
    }

    /**
     * Sets whether the element with charset information in this document is
     * updated on changes through {@link #charset(java.nio.charset.Charset)
     * Document.charset(Charset)} or not.
     *
     * <p>If set to <tt>false</tt> <i>(default)</i> there are no elements
     * modified.</p>
     *
     * @param update If <tt>true</tt> the element updated on charset
     * changes, <tt>false</tt> if not
     *
     * @see #charset(java.nio.charset.Charset)
     */
    public func updateMetaCharsetElement(_ update: Bool) {
        self.updateMetaCharset = update
    }

    /**
     * Returns whether the element with charset information in this document is
     * updated on changes through {@link #charset(java.nio.charset.Charset)
     * Document.charset(Charset)} or not.
     *
     * @return Returns <tt>true</tt> if the element is updated on charset
     * changes, <tt>false</tt> if not
     */
    public func updateMetaCharsetElement() -> Bool {
        return updateMetaCharset
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
    private func ensureMetaCharsetElement() throws {
        if (updateMetaCharset) {
            let syntax: OutputSettings.Syntax = outputSettings.syntax()

            if (syntax == OutputSettings.Syntax.html) {
                let metaCharset: Element? = select(cssQuery: "meta[charset]").first

                if (metaCharset != nil) {
                    try metaCharset?.setAttribute(key: "charset", value: charset.displayName())
                } else {
                    let head: Element? = self.head

                    if (head != nil) {
                        try head?.appendElement(tagName: "meta").setAttribute(key: "charset", value: charset.displayName())
                    }
                }

                // Remove obsolete elements
				let s = select(cssQuery: "meta[name=charset]")
                try s.forEach{ try $0.remove() }

            } else if (syntax == OutputSettings.Syntax.xml) {
                let node: Node = getChildNodes()[0]

                if let decl = (node as? XmlDeclaration) {

                    if (decl.name()=="xml") {
                        try decl.setAttribute(key: "encoding", value: charset.displayName())

                        _ = try  decl.getAttribute(key: "version")
                        try decl.setAttribute(key: "version", value: "1.0")
                    } else {
                        try Validate.notNull(obj: baseURI)
                        let decl = XmlDeclaration("xml", baseURI!, false)
                        try decl.setAttribute(key: "version", value: "1.0")
                        try decl.setAttribute(key: "encoding", value: charset.displayName())

                        try prependChild(decl)
                    }
                } else {
                    try Validate.notNull(obj: baseURI)
                    let decl = XmlDeclaration("xml", baseURI!, false)
                    try decl.setAttribute(key: "version", value: "1.0")
                    try decl.setAttribute(key: "encoding", value: charset.displayName())

                    try prependChild(decl)
                }
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
		clone.updateMetaCharset = updateMetaCharset
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
