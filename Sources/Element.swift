//
//  Element.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

open class Element: Node {
	public internal(set) var tag: Tag

    private static let classString = "class"
    private static let emptyString = ""
    private static let idString = "id"
    private static let rootString = "#root"

    //private static let classSplit : Pattern = Pattern("\\s+")
	private static let classSplit = "\\s+"

    /**
     * Create a new, standalone Element. (Standalone in that is has no parent.)
     *
     * @param tag tag of this element
     * @param baseUri the base URI
     * @param attributes initial attributes
     * @see #appendChild(Node)
     * @see #appendElement(String)
     */
    public init(tag: Tag, baseURI: String, attributes: Attributes) {
        self.tag = tag
        super.init(baseURI: baseURI, attributes: attributes)
    }
    /**
     * Create a new Element from a tag and a base URI.
     *
     * @param tag element tag
     * @param baseUri the base URI of this element. It is acceptable for the base URI to be an empty
     *            string, but not null.
     * @see Tag#valueOf(String, ParseSettings)
     */
    public init(tag: Tag, baseURI: String) {
        self.tag = tag
        super.init(baseURI: baseURI, attributes: Attributes())
    }

    open override var nodeName: String {
        return tag.getName()
    }
    
    /**
     * Get the name of the tag for this element. E.g. {@code div}
     *
     * @return the tag name
     */
    open var tagName: String {
        return tag.getName()
    }
    // TODO: Document
    open var tagNameNormal: String {
        return tag.getNameNormal()
    }

    /**
     * Change the tag of this element. For example, convert a {@code <span>} to a {@code <div>} with
     * {@code el.tagName("div")}.
     *
     * @param tagName new tag name for this element
     * @return this element, for chaining
     */
    @discardableResult
    public func setTagName(_ tagName: String) throws -> Element {
        if tagName.isEmpty {
            throw SwiftSoupError.emptyTagName
        }
        tag = try Tag.valueOf(tagName, ParseSettings.preserveCase) // preserve the requested tag case
        return self
    }

    /**
     * Test if this element is a block-level element. (E.g. {@code <div> == true} or an inline element
     * {@code <p> == false}).
     *
     * @return true if block, false if not (and thus inline)
     */
    open var isBlock: Bool {
        return tag.isBlock()
    }

    /**
     * Get the {@code id} attribute of this element.
     *
     * @return The id attribute, if present, or an empty string if not.
     */
    open var id: String {
        guard let attributes = attributes else { return Element.emptyString }
        do {
            return try attributes.getIgnoreCase(key: Element.idString)
        } catch {}
        return Element.emptyString
    }

    /**
     * Set an attribute value on this element. If this element already has an attribute with the
     * key, its value is updated; otherwise, a new attribute is added.
     *
     * @return this element
     */
    @discardableResult
    open override func setAttribute(key: String, value: String) throws -> Element {
        try super.setAttribute(key: key, value: value)
        return self
    }

    /**
     * Set a boolean attribute value on this element. Setting to <code>true</code> sets the attribute value to "" and
     * marks the attribute as boolean so no value is written out. Setting to <code>false</code> removes the attribute
     * with the same key if it exists.
     *
     * @param attributeKey the attribute key
     * @param attributeValue the attribute value
     *
     * @return this element
     */
    @discardableResult
    open func setAttribute(key: String, value: Bool) throws -> Element {
        try attributes?.put(key, value)
        return self
    }

    /**
     * Get this element's HTML5 custom data attributes. Each attribute in the element that has a key
     * starting with "data-" is included the dataset.
     * <p>
     * E.g., the element {@code <div data-package="SwiftSoup" data-language="Java" class="group">...} has the dataset
     * {@code package=SwiftSoup, language=java}.
     * <p>
     * This map is a filtered view of the element's attribute map. Changes to one map (add, remove, update) are reflected
     * in the other map.
     * <p>
     * You can find elements that have data attributes using the {@code [^data-]} attribute key prefix selector.
     * @return a map of {@code key=value} custom data attributes.
     */
    open var attributesAsDictionary: Dictionary<String, String> {
        attributes!.dataset()
    }

    open override var parent:Element? {
        return parentNode as? Element
    }

    /**
     * Get this element's parent and ancestors, up to the document root.
     * @return this element's stack of parents, closest first.
     */
    open var ancestors: Elements {
        let ancestors: Elements = Elements()
        Element.accumulateParents(self, ancestors)
        return ancestors
    }

    private static func accumulateParents(_ el: Element, _ parents: Elements) {
        let parent: Element? = el.parent
        if (parent != nil && !(parent!.tagName == Element.rootString)) {
            parents.append(parent!)
            accumulateParents(parent!, parents)
        }
    }

    /**
     * Get a child element of this element, by its 0-based index number.
     * <p>
     * Note that an element can have both mixed Nodes and Elements as children. This method inspects
     * a filtered list of children that are elements, and the index is based on that filtered list.
     * </p>
     *
     * @param index the index number of the element to retrieve
     * @return the child element, if it exists, otherwise throws an {@code IndexOutOfBoundsException}
     * @see #childNode(int)
     */
    open func getChild(at index: Int) -> Element? {
        return children.get(index: index)
    }

    /**
     * Get this element's child elements.
     * <p>
     * This is effectively a filter on {@link #childNodes()} to get Element nodes.
     * </p>
     * @return child elements. If this element has no children, returns an
     * empty list.
     * @see #childNodes()
     */
    open var children: Elements {
        // create on the fly rather than maintaining two lists. if gets slow, memoize, and mark dirty on change
        let elements = childNodes.compactMap { $0 as? Element }
        return Elements(elements)
    }
    
    // TODO: Document
    open var firstChild: Element? {
        getChild(at: 0)
    }

    /**
     * Get this element's child text nodes. The list is unmodifiable but the text nodes may be manipulated.
     * <p>
     * This is effectively a filter on {@link #childNodes()} to get Text nodes.
     * @return child text nodes. If this element has no text nodes, returns an
     * empty list.
     * </p>
     * For example, with the input HTML: {@code <p>One <span>Two</span> Three <br> Four</p>} with the {@code p} element selected:
     * <ul>
     *     <li>{@code p.text()} = {@code "One Two Three Four"}</li>
     *     <li>{@code p.ownText()} = {@code "One Three Four"}</li>
     *     <li>{@code p.children} = {@code Elements[<span>, <br>]}</li>
     *     <li>{@code p.childNodes()} = {@code List<Node>["One ", <span>, " Three ", <br>, " Four"]}</li>
     *     <li>{@code p.textNodes()} = {@code List<TextNode>["One ", " Three ", " Four"]}</li>
     * </ul>
     */
    open var textNodes: [TextNode] {
        return childNodes.compactMap { $0 as? TextNode }
    }

    /**
     * Get this element's child data nodes. The list is unmodifiable but the data nodes may be manipulated.
     * <p>
     * This is effectively a filter on {@link #childNodes()} to get Data nodes.
     * </p>
     * @return child data nodes. If this element has no data nodes, returns an
     * empty list.
     * @see #data()
     */
    open var dataNodes: [DataNode] {
        return childNodes.compactMap{ $0 as? DataNode }
    }

    /**
     * Find elements that match the {@link CssSelector} CSS query, with this element as the starting context. Matched elements
     * may include this element, or any of its children.
     * <p>
     * This method is generally more powerful to use than the DOM-type {@code getElementBy*} methods, because
     * multiple filters can be combined, e.g.:
     * </p>
     * <ul>
     * <li>{@code el.select("a[href]")} - finds links ({@code a} tags with {@code href} attributes)
     * <li>{@code el.select("a[href*=example.com]")} - finds links pointing to example.com (loosely)
     * </ul>
     * <p>
     * See the query syntax documentation in {@link CssSelector}.
     * </p>
     *
     * @param cssQuery a {@link CssSelector} CSS-like query
     * @return elements that match the query (empty if none match)
     * @see CssSelector
     * @throws CssSelector.SelectorParseException (unchecked) on an invalid CSS query.
     */
    public func select(cssQuery: String) -> Elements {
        do {
            return try CssSelector.select(cssQuery, self)
        } catch {
            return Elements()
        }
    }

    /**
     * Check if this element matches the given {@link CssSelector} CSS query.
     * @param cssQuery a {@link CssSelector} CSS query
     * @return if this element matches the query
     */
    public func isMatchedWith(cssQuery: String) -> Bool {
        do {
            return try self.isMatchedWith(evaluator: QueryParser.parse(cssQuery))
        } catch {
            return false
        }
    }

    /**
     * Check if this element matches the given {@link CssSelector} CSS query.
     * @param cssQuery a {@link CssSelector} CSS query
     * @return if this element matches the query
     */
    public func isMatchedWith(evaluator: Evaluator) -> Bool {
        guard let od = self.ownerDocument() else {
            return false
        }
        do {
            return try evaluator.matches(od, self)
        } catch {
            return false
        }
    }

    /**
     * Add a node child node to this element.
     *
     * @param child node to add.
     * @return this element, so that you can add more child nodes or elements.
     */
    @discardableResult
    public func appendChild(_ child: Node) -> Element {
        reparentChild(child)
        ensureChildNodes()
        childNodes.append(child)
        child.siblingIndex = childNodes.count - 1
        return self
    }

    /**
     * Add a node to the start of this element's children.
     *
     * @param child node to add.
     * @return this element, so that you can add more child nodes or elements.
     */
    @discardableResult
    public func prependChild(_ child: Node) -> Element {
        insertChildren(child, at: 0)
        return self
    }

    /**
     * Inserts the given child nodes into this element at the specified index. Current nodes will be shifted to the
     * right. The inserted nodes will be moved from their current parent. To prevent moving, copy the nodes first.
     *
     * @param index 0-based index to insert children at. Specify {@code 0} to insert at the start, {@code -1} at the
     * end
     * @param children child nodes to insert
     * @return this element, for chaining.
     */
    @discardableResult
    public func insertChildren(_ children: [Node], at index: Int) throws -> Element {
        var index = index
        let currentSize = childNodeSize()
        if index < 0 {
            index += currentSize + 1
        } // roll around
        guard index >= 0 && index <= currentSize else {
            throw SwiftSoupError.indexOutOfBounds
        }

        super.insertChildren(children, at: index)
        return self
    }

    /**
     * Create a new element by tag name, and add it as the last child.
     *
     * @param tagName the name of the tag (e.g. {@code div}).
     * @return the new element, to allow you to add content to it, e.g.:
     *  {@code parent.appendElement("h1").attr("id", "header").text("Welcome")}
     */
    @discardableResult
    public func appendElement(tagName: String) throws -> Element {
        let child = Element(tag: try Tag.valueOf(tagName), baseURI: baseURI!)
        appendChild(child)
        return child
    }

    /**
     * Create a new element by tag name, and add it as the first child.
     *
     * @param tagName the name of the tag (e.g. {@code div}).
     * @return the new element, to allow you to add content to it, e.g.:
     *  {@code parent.prependElement("h1").attr("id", "header").text("Welcome")}
     */
    @discardableResult
    public func prependElement(tagName: String) throws -> Element {
        let child: Element = Element(tag: try Tag.valueOf(tagName), baseURI: baseURI!)
        prependChild(child)
        return child
    }

    /**
     * Create and append a new TextNode to this element.
     *
     * @param text the unencoded text to add
     * @return this element
     */
    @discardableResult
    public func appendText(_ text: String) -> Element {
        let node: TextNode = TextNode(text, baseURI!)
        appendChild(node)
        return self
    }

    /**
     * Create and prepend a new TextNode to this element.
     *
     * @param text the unencoded text to add
     * @return this element
     */
    @discardableResult
    public func prependText(_ text: String) -> Element {
        let node: TextNode = TextNode(text, baseURI!)
        prependChild(node)
        return self
    }

    /**
     * Add inner HTML to this element. The supplied HTML will be parsed, and each node appended to the end of the children.
     * @param html HTML to add inside this element, after the existing HTML
     * @return this element
     * @see #html(String)
     */
    @discardableResult
    public func appendHTML(_ html: String) throws -> Element {
        let nodes: [Node] = try Parser._parseHTMLFragment(html, context: self, baseURI: baseURI!)
        appendChildren(nodes)
        return self
    }

    /**
     * Add inner HTML into this element. The supplied HTML will be parsed, and each node prepended to the start of the element's children.
     * @param html HTML to add inside this element, before the existing HTML
     * @return this element
     * @see #html(String)
     */
    @discardableResult
    public func prependHTML(_ html: String) throws -> Element {
        let nodes: Array<Node> = try Parser._parseHTMLFragment(html, context: self, baseURI: baseURI!)
        super.insertChildren(nodes, at: 0)
        return self
    }

    /**
     * Insert the specified HTML into the DOM before this element (as a preceding sibling).
     *
     * @param html HTML to add before this element
     * @return this element, for chaining
     * @see #after(String)
     */
    @discardableResult
    open override func insertHTMLAsPreviousSibling(_ html: String) throws -> Element {
        return try super.insertHTMLAsPreviousSibling(html) as! Element
    }

    /**
     * Insert the specified node into the DOM before this node (as a preceding sibling).
     * @param node to add before this element
     * @return this Element, for chaining
     * @see #after(Node)
     */
    @discardableResult
    open override func insertNodeAsPreviousSibling(_ node: Node) throws -> Element {
        return try super.insertNodeAsPreviousSibling(node) as! Element
    }

    /**
     * Insert the specified HTML into the DOM after this element (as a following sibling).
     *
     * @param html HTML to add after this element
     * @return this element, for chaining
     * @see #before(String)
     */
    @discardableResult
    open override func insertHTMLAsNextSibling(_ html: String) throws -> Element {
        return try super.insertHTMLAsNextSibling(html) as! Element
    }

    /**
     * Insert the specified node into the DOM after this node (as a following sibling).
     * @param node to add after this element
     * @return this element, for chaining
     * @see #before(Node)
     */
    open override func insertNodeAsNextSibling(_ node: Node) throws -> Element {
        return try super.insertNodeAsNextSibling(node) as! Element
    }

    /**
     * Remove all of the element's child nodes. Any attributes are left as-is.
     * @return this element
     */
    @discardableResult
    public func removeAll() -> Element {
        childNodes.removeAll()
        return self
    }

    /**
     * Wrap the supplied HTML around this element.
     *
     * @param html HTML to wrap around this element, e.g. {@code <div class="head"></div>}. Can be arbitrarily deep.
     * @return this element, for chaining.
     */
    @discardableResult
    open override func wrap(html: String) throws -> Element {
        return try super.wrap(html: html) as! Element
    }

    /**
     * Get a CSS selector that will uniquely select this element.
     * <p>
     * If the element has an ID, returns #id;
     * otherwise returns the parent (if any) CSS selector, followed by {@literal '>'},
     * followed by a unique selector for the element (tag.class.class:nth-child(n)).
     * </p>
     *
     * @return the CSS Path that can be used to retrieve the element in a selector.
     */
    public var cssSelector: String {
        let elementId = id
        if (elementId.count > 0) {
            return "#" + elementId
        }

        // Translate HTML namespace ns:tag to CSS namespace syntax ns|tag
        let tagName: String = self.tagName.replacingOccurrences(of: ":", with: "|")
        var selector: String = tagName
        let cl = classNames
        let classes: String = cl.joined(separator: ".")
        if (classes.count > 0) {
            selector.append(".")
            selector.append(classes)
        }

        if (parent == nil || ((parent as? Document) != nil)) // don't add Document to selector, as will always have a html node
        {
            return selector
        }

        selector.insert(contentsOf: " > ", at: selector.startIndex)
        if (parent!.select(cssQuery: selector).count > 1) {
            selector.append(":nth-child(\(elementSiblingIndex + 1))")
        }

        return parent!.cssSelector + (selector)
    }

    /**
     * Get sibling elements. If the element has no sibling elements, returns an empty list. An element is not a sibling
     * of itself, so will not be included in the returned list.
     * @return sibling elements
     */
    public var siblingElements: Elements {
        if (parentNode == nil) {return Elements()}

        if let elements = parent?.children {
            return elements.copy() as! Elements
        } else {
            return Elements()
        }
    }

    /**
     * Gets the next sibling element of this element. E.g., if a {@code div} contains two {@code p}s,
     * the {@code nextElementSibling} of the first {@code p} is the second {@code p}.
     * <p>
     * This is similar to {@link #nextSibling()}, but specifically finds only Elements
     * </p>
     * @return the next element, or null if there is no next element
     * @see #previousElementSibling()
     */
    public var nextSiblingElement: Element? {
        guard let parent = parent else {
            return nil
        }
        let siblings = parent.children
        guard let index = siblings.firstIndex(of: self) else {
            return nil
        }
        
        return siblings.get(index: index + 1)
    }

    /**
     * Gets the previous element sibling of this element.
     * @return the previous element, or null if there is no previous element
     * @see #nextElementSibling()
     */
    public var previousSiblingElement: Element? {
        guard let parent = parent else {
            return nil
        }
        let siblings = parent.children
        guard let index = siblings.firstIndex(of: self) else {
            return nil
        }

        return siblings.get(index: index - 1)
    }

    /**
     * Gets the first element sibling of this element.
     * @return the first sibling that is an element (aka the parent's first element child)
     */
    public var firstSiblingElement: Element? {
        return parent?.children.first
    }

    /*
     * Get the list index of this element in its element sibling list. I.e. if this is the first element
     * sibling, returns 0.
     * @return position in element sibling list
     */
    public var elementSiblingIndex: Int {
        guard let parent = parent else {
            return 0
        }
        return parent.children.firstIndex(of: self)!
    }

    /**
     * Gets the last element sibling of this element
     * @return the last sibling that is an element (aka the parent's last element child)
     */
    public var lastSiblingElement: Element? {
        return parent?.children.last
    }

    // MARK: `getElemntsBy...` Methods
    /**
     * Finds elements, including and recursively under this element, with the specified tag name.
     * @param tagName The tag name to search for (case insensitively).
     * @return a matching unmodifiable list of elements. Will be empty if this element and none of its children match.
     */
    public func getElementsByTag(_ tagName: String) -> Elements? {
        guard !tagName.isEmpty else { return nil }
        let tagName = tagName.lowercased().trim()

        return try? Collector.collect(Evaluator.Tag(tagName), self)
    }

    /**
     * Find an element by ID, including or under this element.
     * <p>
     * Note that this finds the first matching ID, starting with this element. If you search down from a different
     * starting point, it is possible to find a different element by ID. For unique element by ID within a Document,
     * use {@link Document#getElementById(String)}
     * @param id The ID to search for.
     * @return The first matching element by ID, starting with this element, or null if none found.
     */
    public func getElementById(_ id: String) -> Element? {
        guard !id.isEmpty else { return nil }

        guard let elements: Elements = try? Collector.collect(Evaluator.Id(id), self) else {
            return nil
        }
        if (elements.count > 0) {
            return elements.get(index: 0)
        } else {
            return nil
        }
    }

    /**
     * Find elements that have this class, including or under this element. Case insensitive.
     * <p>
     * Elements can have multiple classes (e.g. {@code <div class="header round first">}. This method
     * checks each class, so you can find the above with {@code el.getElementsByClass("header")}.
     *
     * @param className the name of the class to search for.
     * @return elements with the supplied class name, empty if none
     * @see #hasClass(String)
     * @see #classNames()
     */
    public func getElementsByClass(_ className: String) -> Elements {
        let result = try? Collector.collect(Evaluator.Class(className), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have a named attribute set. Case insensitive.
     *
     * @param key name of the attribute, e.g. {@code href}
     * @return elements that have this attribute, empty if none
     */
    public func getElementsByAttribute(key: String) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.Attribute(key), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have an attribute name starting with the supplied prefix. Use {@code data-} to find elements
     * that have HTML5 datasets.
     * @param keyPrefix name prefix of the attribute e.g. {@code data-}
     * @return elements that have attribute names that start with with the prefix, empty if none.
     */
    public func getElementsByAttribute(keyPrefix: String) -> Elements {
        guard !keyPrefix.isEmpty else { return Elements() }
        let keyPrefix = keyPrefix.trim()

        let result = try? Collector.collect(Evaluator.AttributeStarting(keyPrefix), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have an attribute with the specific value. Case insensitive.
     *
     * @param key name of the attribute
     * @param value value of the attribute
     * @return elements that have this attribute with this value, empty if none
     */
    public func getElementsByAttribute(key: String, value: String) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.AttributeWithValue(key, value), self)
        return result ?? Elements()
    }

    /**
     * Find elements that either do not have this attribute, or have it with a different value. Case insensitive.
     *
     * @param key name of the attribute
     * @param value value of the attribute
     * @return elements that do not have a matching attribute
     */
    public func getElementsByAttributeNotMatching(key: String, value: String) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.AttributeWithValueNot(key, value), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have attributes that start with the value prefix. Case insensitive.
     *
     * @param key name of the attribute
     * @param valuePrefix start of attribute value
     * @return elements that have attributes that start with the value prefix
     */
    public func getElementsByAttribute(key: String, valueStartingWith valuePrefix: String) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()
        
        let result = try? Collector.collect(Evaluator.AttributeWithValueStarting(key, valuePrefix), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have attributes that end with the value suffix. Case insensitive.
     *
     * @param key name of the attribute
     * @param valueSuffix end of the attribute value
     * @return elements that have attributes that end with the value suffix
     */
    public func getElementsByAttribute(key: String, valueEndingWith valueSuffix: String) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()
        
        let result = try? Collector.collect(Evaluator.AttributeWithValueEnding(key, valueSuffix), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have attributes whose value contains the match string. Case insensitive.
     *
     * @param key name of the attribute
     * @param match substring of value to search for
     * @return elements that have attributes containing this text
     */
    public func getElementsByAttribute(key: String, valueMathcingWith match: String) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()
        
        let result = try? Collector.collect(Evaluator.AttributeWithValueContaining(key, match), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have attributes whose values match the supplied regular expression.
     * @param key name of the attribute
     * @param pattern compiled regular expression to match against attribute values
     * @return elements that have attributes matching this regular expression
     */
    public func getElementsByAttribute(key: String, valueMathcingWith pattern: Pattern) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.AttributeWithValueMatching(key, pattern), self)
        return result ?? Elements()
    }

    /**
     * Find elements that have attributes whose values match the supplied regular expression.
     * @param key name of the attribute
     * @param regex regular expression to match against attribute values. You can use <a href="http://java.sun.com/docs/books/tutorial/essential/regex/pattern.html#embedded">embedded flags</a> (such as (?i) and (?m) to control regex options.
     * @return elements that have attributes matching this regular expression
     */
    public func getElementsByAttribute(key: String, valueRegex regex: String) -> Elements {
        guard !key.isEmpty else { return Elements() }
        let key = key.trim()

        var pattern: Pattern
        do {
            pattern = Pattern.compile(regex)
            try pattern.validate()
        } catch {
            return Elements()
        }
        return getElementsByAttribute(key: key, valueMathcingWith: pattern)
    }
    
    // TODO: SwiftRegex

    /**
     * Find elements whose sibling index is less than the supplied index.
     * @param index 0-based index
     * @return elements less than index
     */
    public func getElementsByIndex(lessThan index: Int) -> Elements {
        do {
            return try Collector.collect(Evaluator.IndexLessThan(index), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Find elements whose sibling index is greater than the supplied index.
     * @param index 0-based index
     * @return elements greater than index
     */
    public func getElementsByIndex(greaterThan index: Int) -> Elements {
        do {
            return try Collector.collect(Evaluator.IndexGreaterThan(index), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Find elements whose sibling index is equal to the supplied index.
     * @param index 0-based index
     * @return elements equal to index
     */
    public func getElementsByIndex(equals index: Int) -> Elements {
        do {
            return try Collector.collect(Evaluator.IndexEquals(index), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Find elements that contain the specified string. The search is case insensitive. The text may appear directly
     * in the element, or in any of its descendants.
     * @param searchText to look for in the element's text
     * @return elements that contain the string, case insensitive.
     * @see Element#text()
     */
    public func getElementsContainingText(_ searchText: String) -> Elements {
        do {
            return try Collector.collect(Evaluator.ContainsText(searchText), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Find elements that directly contain the specified string. The search is case insensitive. The text must appear directly
     * in the element, not in any of its descendants.
     * @param searchText to look for in the element's own text
     * @return elements that contain the string, case insensitive.
     * @see Element#ownText()
     */
    public func getElementsContainingOwnText(_ searchText: String) -> Elements {
        do {
            return try Collector.collect(Evaluator.ContainsOwnText(searchText), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Find elements whose text matches the supplied regular expression.
     * @param pattern regular expression to match text against
     * @return elements matching the supplied regular expression.
     * @see Element#text()
     */
    public func getElementsMatchingText(_ pattern: Pattern) -> Elements {
        do {
            return try Collector.collect(Evaluator.Matches(pattern), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Find elements whose text matches the supplied regular expression.
     * @param regex regular expression to match text against. You can use <a href="http://java.sun.com/docs/books/tutorial/essential/regex/pattern.html#embedded">embedded flags</a> (such as (?i) and (?m) to control regex options.
     * @return elements matching the supplied regular expression.
     * @see Element#text()
     */
    public func getElementsMatchingText(_ regex: String) -> Elements {
        let pattern: Pattern
        do {
            pattern = Pattern.compile(regex)
            try pattern.validate()
        } catch {
            return Elements()
        }
        return getElementsMatchingText(pattern)
    }

    /**
     * Find elements whose own text matches the supplied regular expression.
     * @param pattern regular expression to match text against
     * @return elements matching the supplied regular expression.
     * @see Element#ownText()
     */
    public func getElementsMatchingOwnText(_ pattern: Pattern) -> Elements {
        do {
            return try Collector.collect(Evaluator.MatchesOwn(pattern), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Find elements whose text matches the supplied regular expression.
     * @param regex regular expression to match text against. You can use <a href="http://java.sun.com/docs/books/tutorial/essential/regex/pattern.html#embedded">embedded flags</a> (such as (?i) and (?m) to control regex options.
     * @return elements matching the supplied regular expression.
     * @see Element#ownText()
     */
    public func getElementsMatchingOwnText(_ regex: String) -> Elements {
        let pattern: Pattern
        do {
            pattern = Pattern.compile(regex)
            try pattern.validate()
        } catch {
            return Elements()
        }
        return getElementsMatchingOwnText(pattern)
    }

    /**
     * Find all elements under this element (including self, and children of children).
     *
     * @return all elements
     */
    public var allElements: Elements {
        do {
            return try Collector.collect(Evaluator.AllElements(), self)
        } catch {
            return Elements()
        }
    }

    /**
     * Gets the combined text of this element and all its children. Whitespace is normalized and trimmed.
     * <p>
     * For example, given HTML {@code <p>Hello  <b>there</b> now! </p>}, {@code p.text()} returns {@code "Hello there now!"}
     *
     * @return unencoded text, or empty string if none.
     * @see #ownText()
     * @see #textNodes()
     */
    class textNodeVisitor: NodeVisitor {
        let accum: StringBuilder
        let trimAndNormaliseWhitespace: Bool
        init(_ accum: StringBuilder, trimAndNormaliseWhitespace: Bool) {
            self.accum = accum
            self.trimAndNormaliseWhitespace = trimAndNormaliseWhitespace
        }
        public func head(_ node: Node, _ depth: Int) {
            if let textNode = (node as? TextNode) {
                if trimAndNormaliseWhitespace {
                    Element.appendNormalisedText(accum, textNode)
                } else {
                    accum.append(textNode.getWholeText())
                }
            } else if let element = (node as? Element) {
                if !accum.isEmpty &&
                    (element.isBlock || element.tag.getName() == "br") &&
                    !TextNode.lastCharIsWhitespace(accum) {
                    accum.append(" ")
                }
            }
        }

        public func tail(_ node: Node, _ depth: Int) {
        }
    }
    
    // TODO: Document
    public func getText(trimAndNormaliseWhitespace: Bool = true) -> String {
        let accum: StringBuilder = StringBuilder()
        try? NodeTraversor(textNodeVisitor(accum, trimAndNormaliseWhitespace: trimAndNormaliseWhitespace)).traverse(self)
        let text = accum.toString()
        if trimAndNormaliseWhitespace {
            return text.trim()
        }
        return text
    }
    
    // TODO: Document
    public var text: String {
        getText()
    }

    /**
     * Gets the text owned by this element only; does not get the combined text of all children.
     * <p>
     * For example, given HTML {@code <p>Hello <b>there</b> now!</p>}, {@code p.ownText()} returns {@code "Hello now!"},
     * whereas {@code p.text()} returns {@code "Hello there now!"}.
     * Note that the text within the {@code b} element is not returned, as it is not a direct child of the {@code p} element.
     *
     * @return unencoded text, or empty string if none.
     * @see #text()
     * @see #textNodes()
     */
    public var ownText: String {
        let stringBuilder: StringBuilder = StringBuilder()
        ownText(stringBuilder)
        return stringBuilder.toString().trim()
    }

    private func ownText(_ accum: StringBuilder) {
        for child: Node in childNodes {
            if let textNode = (child as? TextNode) {
                Element.appendNormalisedText(accum, textNode)
            } else if let child =  (child as? Element) {
                Element.appendWhitespaceIfBr(child, accum)
            }
        }
    }

    private static func appendNormalisedText(_ accum: StringBuilder, _ textNode: TextNode) {
        let text: String = textNode.getWholeText()

        if (Element.preserveWhitespace(textNode.parentNode)) {
            accum.append(text)
        } else {
            StringUtil.appendNormalisedWhitespace(accum, string: text, stripLeading: TextNode.lastCharIsWhitespace(accum))
        }
    }

    private static func appendWhitespaceIfBr(_ element: Element, _ accum: StringBuilder) {
        if (element.tag.getName() == "br" && !TextNode.lastCharIsWhitespace(accum)) {
            accum.append(" ")
        }
    }

    static func preserveWhitespace(_ node: Node?) -> Bool {
        // looks only at this element and one level up, to prevent recursion & needless stack searches
        if let element = (node as? Element) {
            return element.tag.preserveWhitespace() || element.parent != nil && element.parent!.tag.preserveWhitespace()
        }
        return false
    }

    /**
     * Set the text of this element. Any existing contents (text or elements) will be cleared
     * @param text unencoded text
     * @return this element
     */
    @discardableResult
    public func setText(_ text: String) -> Element {
        removeAll()
        let textNode: TextNode = TextNode(text, baseURI)
        appendChild(textNode)
        return self
    }

    /**
     Test if this element has any text content (that is not just whitespace).
     @return true if element has non-blank text content.
     */
    public var hasText: Bool {
        for childNode in childNodes {
            if let textNode = childNode as? TextNode {
                if !textNode.isBlank() {
                    return true
                }
            } else if let element = childNode as? Element {
                if element.hasText {
                    return true
                }
            }
        }
        return false
    }

    /**
     * Get the combined data of this element. Data is e.g. the inside of a {@code script} tag.
     * @return the data, or empty string if none
     *
     * @see #dataNodes()
     */
    public var data: String {
        let stringBuilder: StringBuilder = StringBuilder()

        for childNode: Node in childNodes {
            if let data = (childNode as? DataNode) {
                stringBuilder.append(data.getWholeData())
            } else if let element = (childNode as? Element) {
                let elementData: String = element.data
                stringBuilder.append(elementData)
            }
        }
        return stringBuilder.toString()
    }

    /**
     * Gets the literal value of this element's "class" attribute, which may include multiple class names, space
     * separated. (E.g. on <code>&lt;div class="header gray"&gt;</code> returns, "<code>header gray</code>")
     * @return The literal class attribute, or <b>empty string</b> if no class attribute set.
     */
    public var className: String? {
        return getAttribute(key: Element.classString)?.trim()
    }

    /**
     * Get all of the element's class names. E.g. on element {@code <div class="header gray">},
     * returns a set of two elements {@code "header", "gray"}. Note that modifications to this set are not pushed to
     * the backing {@code class} attribute; use the {@link #classNames(java.util.Set)} method to persist them.
     * @return set of classnames, empty if no class attribute
     */
    public var classNames: OrderedSet<String> {
        guard let className else { return [] }
		let fitted = className.replaceAll(of: Element.classSplit, with: " ", options: .caseInsensitive)
		let names: [String] = fitted.components(separatedBy: " ")
		let classNames = OrderedSet(sequence: names)
		classNames.remove(Element.emptyString) // if classNames() was empty, would include an empty class
		return classNames
	}

    /**
     Set the element's {@code class} attribute to the supplied class names.
     @param classNames set of classes
     @return this element, for chaining
     */
    @discardableResult
    public func setClass(names: OrderedSet<String>) -> Element {
        try! attributes?.put(Element.classString, StringUtil.join(classNames, sep: " "))
        return self
    }

    /**
     * Tests if this element has a class. Case insensitive.
     * @param className name of class to check for
     * @return true if it does, false if not
     */
    // performance sensitive
    public func hasClass(named className: String) -> Bool {
        let classAtt: String? = attributes?.get(key: Element.classString)
        let len: Int = (classAtt != nil) ? classAtt!.count : 0
        let wantLen: Int = className.count

        if (len == 0 || len < wantLen) {
            return false
        }
        let classAttr = classAtt!

        // if both lengths are equal, only need compare the className with the attribute
        if (len == wantLen) {
            return className.equalsIgnoreCase(string: classAttr)
        }

        // otherwise, scan for whitespace and compare regions (with no string or arraylist allocations)
        var inClass: Bool = false
        var start: Int = 0
        for i in 0..<len {
            if (classAttr.charAt(i).isWhitespace) {
                if (inClass) {
                    // white space ends a class name, compare it with the requested one, ignore case
                    if (i - start == wantLen && classAttr.regionMatches(ignoreCase: true, selfOffset: start,
                                                                        other: className, otherOffset: 0,
                                                                        targetLength: wantLen)) {
                        return true
                    }
                    inClass = false
                }
            } else {
                if (!inClass) {
                    // we're in a class name : keep the start of the substring
                    inClass = true
                    start = i
                }
            }
        }

        // check the last entry
        if (inClass && len - start == wantLen) {
            return classAttr.regionMatches(ignoreCase: true, selfOffset: start,
                                           other: className, otherOffset: 0, targetLength: wantLen)
        }

        return false
    }

    /**
     Add a class name to this element's {@code class} attribute.
     @param className class name to add
     @return this element
     */
    @discardableResult
	public func addClass(named className: String) -> Element {
		let classes = classNames
		classes.append(className)
		setClass(names: classes)
        
		return self
	}

    /**
     Remove a class name from this element's {@code class} attribute.
     @param className class name to remove
     @return this element
     */
    @discardableResult
    public func removeClass(named className: String) -> Element {
        let classes = classNames
		classes.remove(className)
        setClass(names: classes)
        
        return self
    }

    /**
     Toggle a class name on this element's {@code class} attribute: if present, remove it; otherwise add it.
     @param className class name to toggle
     @return this element
     */
    @discardableResult
    public func toggleClass(named className: String) -> Element {
        let classes = classNames
        if classes.contains(className) {
            classes.remove(className)
        } else {
            classes.append(className)
        }
        setClass(names: classes)

        return self
    }

    /**
     * Get the value of a form element (input, textarea, etc).
     * @return the value of the form element, or empty string if not set.
     */
    public var value: String? {
        if tagName == "textarea" {
            return text
        } else {
            return getAttribute(key: "value")
        }
    }

    /**
     * Set the value of a form element (input, textarea, etc).
     * @param value value to set
     * @return this element (for chaining)
     */
    @discardableResult
    public func setValue(_ value: String) -> Element {
        if tagName == "textarea" {
            setText(value)
        } else {
            try! setAttribute(key: "value", value: value)
        }
        return self
    }

    override func outerHtmlHead(_ accum: StringBuilder, _ depth: Int, _ out: OutputSettings) throws {
        if (out.prettyPrint() && (tag.formatAsBlock() || (parent != nil && parent!.tag.formatAsBlock()) || out.outline())) {
            if !accum.isEmpty {
                indent(accum, depth, out)
            }
        }
        accum
            .append("<")
            .append(tagName)
        try attributes?.html(accum: accum, out: out)

        // selfclosing includes unknown tags, isEmpty defines tags that are always empty
        if (childNodes.isEmpty && tag.isSelfClosing()) {
            if (out.syntax() == OutputSettings.Syntax.html && tag.isEmpty()) {
                accum.append(" />") // <img /> for "always empty" tags. selfclosing is ignored but retained for xml/xhtml compatibility
            } else {
                accum.append(" />") // <img /> in xml
            }
        } else {
            accum.append(">")
        }
    }

    override func outerHtmlTail(_ accum: StringBuilder, _ depth: Int, _ out: OutputSettings) {
        if (!(childNodes.isEmpty && tag.isSelfClosing())) {
            if (out.prettyPrint() && (!childNodes.isEmpty && (
                tag.formatAsBlock() || (out.outline() && (childNodes.count>1 || (childNodes.count==1 && !(((childNodes[0] as? TextNode) != nil)))))
                ))) {
                indent(accum, depth, out)
            }
            accum.append("</").append(tagName).append(">")
        }
    }

    /**
     * Retrieves the element's inner HTML. E.g. on a {@code <div>} with one empty {@code <p>}, would return
     * {@code <p></p>}. (Whereas {@link #outerHtml()} would return {@code <div><p></p></div>}.)
     *
     * @return String of HTML.
     * @see #outerHtml()
     */
    public var html: String? {
        let accum: StringBuilder = StringBuilder()
        do {
            try html2(accum)
        } catch {
            return nil
        }
        return getOutputSettings().prettyPrint() ? accum.toString().trim() : accum.toString()
    }

    private func html2(_ accum: StringBuilder) throws {
        for node in childNodes {
            try node.outerHtml(accum)
        }
    }

    /**
     * {@inheritDoc}
     */
    open override func html(_ appendable: StringBuilder) throws -> StringBuilder {
        for node in childNodes {
            try node.outerHtml(appendable)
        }
        return appendable
    }

	/**
	* Set this element's inner HTML. Clears the existing HTML first.
	* @param html HTML to parse and set into this element
	* @return this element
	* @see #append(String)
	*/
    @discardableResult
	public func setHTML(_ html: String) throws -> Element {
		removeAll()
		try appendHTML(html)
		return self
	}

	public override func copy(with zone: NSZone? = nil) -> Any {
		let clone = Element(tag: tag, baseURI: baseURI!, attributes: attributes!)
		return copy(clone: clone)
	}

	public override func copy(parent: Node?) -> Node {
		let clone = Element(tag: tag, baseURI: baseURI!, attributes: attributes!)
		return copy(clone: clone, parent: parent)
	}
	public override func copy(clone: Node, parent: Node?) -> Node {
		return super.copy(clone: clone, parent: parent)
	}

    public static func ==(lhs: Element, rhs: Element) -> Bool {
    	guard lhs as Node == rhs as Node else {
            return false
        }
        
        return lhs.tag == rhs.tag
    }
	
    override public func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        hasher.combine(tag)
    }
}
