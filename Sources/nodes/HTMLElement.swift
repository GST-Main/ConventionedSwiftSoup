//
//  HTMLElement.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

// TODO: Code example
/// A node representing an HTML element.
///
/// This is a subclass of ``Node`` that contains information about a HTML element. Access this information with properties or methods like ``className``, ``tagName``, ``text``, ``Node/getAttribute(key:)``, etc.
///
/// Use methods of this object to get elements with specific id, tag name, attirbute, etc.
/// For example, ``getElementById(_:)`` retrieves an ``HTMLElements`` object consisting of ``HTMLElement`` objects whose id matches the specified id.
///
/// You can modify an element using methods like ``setAttribute(key:value:)-5p0uc``, ``setClass(names:)``, ``setHTML(_:)``, etc.
///
/// Some properties and methods, such as ``parent`` or ``setAttribute(key:value:)-5p0uc``, from the superclass ``Node`` have been overriden. Most of these changes simply replace the type ``Node`` with ``HTMLElement``.
///
/// - todo: This object also represents an XML element. This is temporary and will be refactored into a more object-oriented structure in the future.
open class HTMLElement: Node {
	public internal(set) var tag: Tag

    private static let classString = "class"
    private static let emptyString = ""
    private static let idString = "id"
    private static let rootString = "#root"

    //private static let classSplit : Pattern = Pattern("\\s+")
	private static let classSplit = "\\s+"

    /// Create a new standalone element.
    ///
    /// - Tip: Creating a new ``HTMLElement`` is useful when you need to insert a new element into an existing element. Please check ``appendElement(tagName:)`` or ``insertChildrenElements(_:at:)``.
    public init(tag: Tag, baseURI: String, attributes: Attributes) {
        self.tag = tag
        super.init(baseURI: baseURI, attributes: attributes)
    }
    /// Create a new standalone element.
    ///
    /// - Tip: Creating a new ``HTMLElement`` is useful when you need to insert a new element into an existing element. Please check ``appendElement(tagName:)`` or ``insertChildrenElements(_:at:)``.
    public init(tag: Tag, baseURI: String) {
        self.tag = tag
        super.init(baseURI: baseURI, attributes: Attributes())
    }
    
    /// The node name of this node.
    ///
    /// In ``HTMLElement``, this is the element's tag name.
    open override var nodeName: String {
        return tag.getName()
    }
    
    /// The name of the tag for this element.
    open var tagName: String {
        return tag.getName()
    }
    /// The normalized name of the tag for this element.
    open var tagNameNormal: String {
        return tag.getNameNormal()
    }

    /// Set the name of the tag of this element.
    ///
    /// - Parameter tagName: A new tag name for this element.
    /// - Returns: `self` for chaining.
    ///
    /// ## Throws
    /// * `SwiftSoupError.emptyTagName` if given tag name is an empty string.
    @discardableResult
    public func setTagName(_ tagName: String) throws -> HTMLElement {
        if tagName.isEmpty {
            throw SwiftSoupError.emptyTagName
        }
        tag = try Tag.valueOf(tagName, ParseSettings.preserveCase) // preserve the requested tag case
        return self
    }

    /// A Boolean value indicating whether a element is a block.
    open var isBlock: Bool {
        return tag.isBlock()
    }

    /// A value of the "id" attribute.
    ///
    /// The id is NOT unique actually. It just represent the "id" attribute's value. If this element has no "id" element, this property represents empty string.
    open var id: String? {
        guard let attributes = attributes else {
            return nil
        }
        
        do {
            return try attributes.getIgnoreCase(key: HTMLElement.idString)
        } catch {
            return nil
        }
    }

    /// Set an attribute value on this element.
    ///
    /// If an attribute with given key exists, set a new value of it. Otherwise, add a new attirbute with given key and value.
    ///
    /// ## Throws
    /// * `SwiftSoupError.emptyAttributeKey` if given key is an empty string.
    ///
    /// - Parameters:
    ///     - key: The key of an attribute to set. Must not be empty otherwise throws an `SwiftSoupError.emptyAttributeKey` error.
    ///     - value: The new value of an attribute with the given key.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    open override func setAttribute(withKey: String, value: String) throws -> HTMLElement {
        try super.setAttribute(withKey: withKey, value: value)
        return self
    }

    /// Set a boolean attribute value on this element.
    ///
    /// Setting to `true` sets the attribute value to "" and marks the attribute as boolean so no value is written out.
    /// Setting to `false` removes the attribute with the same key if it exists.
    ///
    /// ## Throws
    /// * `SwiftSoupError.emptyAttributeKey` if given key is an empty string.
    ///
    /// - Parameters:
    ///     - key: The key of an attribute to set. Must not be empty otherwise throws an `SwiftSoupError.emptyAttributeKey` error.
    ///     - value: The new boolean value of an attribute with the given key.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    open func setAttribute(withKey key: String, value: Bool) throws -> HTMLElement {
        try attributes?.put(key, value)
        return self
    }

    /// A dictionary containing `key:value` pairs of data.
    ///
    /// This property represents values of \``data-*`\` attributes.
    ///
    /// ```swift
    /// let html =
    /// """
    /// <div id="main" data-user-id="123" data-info="additional info"> ... </div>
    /// """
    ///
    /// let element = HTMLParser.parse(html)!.getElementById("main")!
    /// print(element.datas)
    ///
    /// // Prints "["user-id":"123","info":"additional info"]"
    /// ```
    open var datas: Dictionary<String, String> {
        attributes!.dataset()
    }

    /// A parent of this element.
    open override var parent: HTMLElement? {
        return parentNode as? HTMLElement
    }

    /// An ``HTMLElements`` object contains this element's parent and ancestors up to the document root.
    ///
    /// This property represent this element's stack of parents by closest first.
    open var ancestors: HTMLElements {
        let ancestors: HTMLElements = HTMLElements()
        HTMLElement.accumulateParents(self, ancestors)
        return ancestors
    }

    private static func accumulateParents(_ el: HTMLElement, _ parents: HTMLElements) {
        let parent: HTMLElement? = el.parent
        if (parent != nil && !(parent!.tagName == HTMLElement.rootString)) {
            parents.append(parent!)
            accumulateParents(parent!, parents)
        }
    }

    /// Get a child element of this element at given index.
    ///
    /// This method is a safe way to get a child element with specific index.
    ///
    /// An element can have both mixed ``Node``s and ``HTMLElement``s as children.
    /// This method inspects a filtered list of children that are elements.
    ///
    /// This method also checks if the given index is in valid range and safely returns the child element.
    ///
    /// - Parameter index: The index number of the child element to retrieve.
    /// - Returns: The child element, if exists, otherwise returns `nil`.
    open func getChild(at index: Int) -> HTMLElement? {
        return children.getElement(at: index)
    }

    /// This element's child elements.
    open var children: HTMLElements {
        // create on the fly rather than maintaining two lists. if gets slow, memoize, and mark dirty on change
        let elements = childNodes.compactMap { $0 as? HTMLElement }
        return HTMLElements(elements)
    }
    
    /// The first child of this element.
    open var firstChild: HTMLElement? {
        getChild(at: 0)
    }

    /// Child text nodes of this element.
    ///
    /// ```swift
    /// let html =
    /// """
    /// <p>One
    ///     <span>Two</span>
    ///     Three
    ///     <br>
    ///     Four
    /// </p>
    /// """
    /// let element = HTMLParser.parse(html)!.body!
    /// let childNodes = element.childNodes
    /// let textNodes = element.textNodes
    ///
    /// // `childNodes` is ["One"(TextNode), <span>(HTMLElement), "Three"(TextNode), <br>(HTMLElement), "Four"(TextNode)] as a `Node` array.
    /// // `textNode` is ["One", "Three", "Four"] as a `TextNode` array.
    /// ```
    open var textNodes: [TextNode] {
        return childNodes.compactMap { $0 as? TextNode }
    }

    /// Child data nodes of this element.
    open var dataNodes: [DataNode] {
        return childNodes.compactMap{ $0 as? DataNode }
    }

    /// Find elements that match the CSS query.
    ///
    /// Find elements with a CSS query among all descendants of this element, including the element itself.
    ///
    /// - Parameter cssQuery: A css selector to find element
    /// - Returns: Elements that match the query. Returns empty if none match.
    public func select(cssQuery: String) -> HTMLElements {
        do {
            return try CssSelector.select(cssQuery, self)
        } catch {
            return HTMLElements()
        }
    }

    /// Check if this element matches the given CSS query.
    public func isMatchedWith(cssQuery: String) -> Bool {
        do {
            return try self.isMatchedWith(evaluator: QueryParser.parse(cssQuery))
        } catch {
            return false
        }
    }

    /** old documentary
     * Check if this element matches the given {@link CssSelector} CSS query.
     * @param cssQuery a {@link CssSelector} CSS query
     * @return if this element matches the query
     */
    
    ///
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

    /// Add a node to the end of element's children.
    ///
    /// If the given node already exists on a tree, the node will be removed from the tree before appending.
    ///
    /// - Parameter child: A child node to append.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func appendChild(_ child: Node) -> HTMLElement {
        reparentChild(child)
        ensureChildNodes()
        childNodes.append(child)
        child.siblingIndex = childNodes.count - 1
        return self
    }

    /// Add a node to the start of this element's children.
    ///
    /// If the given node already exists on a tree, the node will be removed from the tree before prepending.
    ///
    /// - Parameter child: A child node to prepend.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func prependChild(_ child: Node) -> HTMLElement {
        insertChildren(child, at: 0)
        return self
    }

    /// Insert the given child nodes at the sepcific index of this element's children.
    ///
    /// If the given nodes already exist on some trees, the nodes will be removed from trees before insertion.
    ///
    /// ## Throws
    /// * `SwiftSoupError.indexOutOfBounds` if the index is out of bound.
    ///
    /// - Parameters:
    ///     - children: Nodes to insert as children.
    ///     - index: An index to insert children at.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    public func insertChildrenElements(_ children: [Node], at index: Int) throws -> HTMLElement {
        var index = index
        let currentSize = childNodes.count
        if index < 0 {
            index += currentSize + 1
        } // roll around
        guard index >= 0 && index <= currentSize else {
            throw SwiftSoupError.indexOutOfBounds
        }

        super.insertChildren(children, at: index)
        return self
    }

    /// Append a new element.
    ///
    /// Create a new element by tag name, and add it as the last child.
    /// ```swift
    /// try? div.appendElement("h2")
    ///         .setAttribute(key: "id", value: "apple")
    ///         .setText("Hello, World!")
    /// ```
    ///
    /// ## Throws
    /// * `SwiftSoupError.emptyTagName` if the given tag name is an empty string.
    ///
    /// - Parameter tagName: The tag name of the new elemen . Must not be empty, otherwise throws `SwiftSoupError.emptyTagName`error.
    /// - Returns: The created element. This allows you to start a builder chain.
    @discardableResult
    public func appendElement(tagName: String) throws -> HTMLElement {
        let child = HTMLElement(tag: try Tag.valueOf(tagName), baseURI: baseURI!)
        appendChild(child)
        return child
    }

    /// Prepend a new element.
    ///
    /// Create a new element by tag name, and add it as the first child.
    /// ```swift
    /// try? div.prependElement("h2")
    ///         .setAttribute(key: "id", value: "apple")
    ///         .setText("Hello, World!")
    /// ```
    ///
    /// ## Throws
    /// * `SwiftSoupError.emptyTagName` if the given tag name is an empty string.
    ///
    /// - Parameter tagName: The tag name of the new element. Must not be empty, otherwise throws `SwiftSoupError.emptyTagName`error.
    /// - Returns: The created element. This allows you to start a builder chain.
    @discardableResult
    public func prependElement(tagName: String) throws -> HTMLElement {
        let child: HTMLElement = HTMLElement(tag: try Tag.valueOf(tagName), baseURI: baseURI!)
        prependChild(child)
        return child
    }

    /// Append a new text node as a child of this element.
    ///
    /// Create a new ``TextNode`` object and append it as the last child of this element.
    ///
    /// - Parameter text: A text to add.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func appendText(_ text: String) -> HTMLElement {
        let node: TextNode = TextNode(text, baseURI!)
        appendChild(node)
        return self
    }

    /// Prepend a new text node as a child of this element.
    ///
    /// Create a new ``TextNode`` object and prepend it as the first child of this element.
    ///
    /// - Parameter text: A text to add.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func prependText(_ text: String) -> HTMLElement {
        let node: TextNode = TextNode(text, baseURI!)
        prependChild(node)
        return self
    }

    /// Append a HTML element as a child of this element.
    ///
    /// Parse the given HTML string and create an ``HTMLElement``. Then, append it as the last child of this element.
    ///
    /// ## Throws
    /// * `SwiftSoupError.failedToParseHTML` if failed to parse HTML.
    ///
    /// - Parameter html: HTML to append inside this element.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func appendHTML(_ html: String) throws -> HTMLElement {
        let nodes: [Node] = try HTMLParser._parseHTMLFragment(html, context: self, baseURI: baseURI!)
        appendChildren(nodes)
        return self
    }

    /// Prepend a HTML element as a child of this element.
    ///
    /// Parse the given HTML string and create an ``HTMLElement``. Then, prepend it as the first child of this element.
    ///
    /// ## Throws
    /// * `SwiftSoupError.failedToParseHTML` if failed to parse HTML.
    ///
    /// - Parameter html: HTML to prepend inside this element.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func prependHTML(_ html: String) throws -> HTMLElement {
        let nodes: Array<Node> = try HTMLParser._parseHTMLFragment(html, context: self, baseURI: baseURI!)
        super.insertChildren(nodes, at: 0)
        return self
    }

    /// Insert the specified HTML into the DOM as a preceding sibling.
    ///
    /// Parse the given HTML string and create a new element. Then, insert the new element as a preceding sibling of this element.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this node doesn't have a parent.
    /// * `SwiftSoupError.failedToParseHTML` if parsing HTML is failed.
    ///
    /// - Parameter html: HTML string to add before this element.
    /// - Returns: `self` for chaining.
    @discardableResult
    open override func insertHTMLAsPreviousSibling(_ html: String) throws -> HTMLElement {
        return try super.insertHTMLAsPreviousSibling(html) as! HTMLElement
    }

    /// Insert the specified element into the DOM as a preceding sibling.
    ///
    /// Insert the given element as a preceding sibling of this element.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this element doesn't have a parent.
    ///
    /// - Parameter node: An element to insert. This must be an ``HTMLElement`` instance.
    /// - Returns: `self` for chaining.
    /// - Attention: The parameter `node` must be an instance of `HTMLElement`. Even though it's named `node` and the type is `Node`, it will be force-casted in run time.
    @discardableResult
    open override func insertNodeAsPreviousSibling(_ node: Node) throws -> HTMLElement {
        return try super.insertNodeAsPreviousSibling(node) as! HTMLElement
    }
    
    /// Insert the specified HTML into the DOM as a following sibling.
    ///
    /// Parse the given HTML string and create a new element. Then, insert the new element as a following sibling of this element.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this element doesn't have a parent.
    /// * `SwiftSoupError.failedToParseHTML` if parsing HTML is failed.
    ///
    /// - Parameter html: HTML string to add after this node.
    /// - Returns: `self` for chaining.
    @discardableResult
    open override func insertHTMLAsNextSibling(_ html: String) throws -> HTMLElement {
        return try super.insertHTMLAsNextSibling(html) as! HTMLElement
    }

    /// Insert the specified element into the DOM as a following sibling.
    ///
    /// Insert the given element as a following sibling of this element.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this element doesn't have a parent.
    ///
    /// - Parameter node: A element to add after this node. This must be an ``HTMLElement`` instance.
    /// - Returns: `self` for chaining.
    /// - Attention: The parameter `node` must be an instance of `HTMLElement`. Even though it's named `node` and the type is `Node`, it will be force-casted in run time.
    @discardableResult
    open override func insertNodeAsNextSibling(_ node: Node) throws -> HTMLElement {
        return try super.insertNodeAsNextSibling(node) as! HTMLElement
    }

    /// Remove all of the children.
    ///
    /// This method removes all of the child nodes. Any attributes are left as-is.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    public func removeAll() -> HTMLElement {
        childNodes.removeAll()
        return self
    }

    /// Wrap the supplied HTML around this element.
    ///
    /// - Parameter html: HTML to wrap around this element. For example, `"<div class="head"></div>"`. Can be arbitrarily deep.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    open override func wrap(html: String) throws -> HTMLElement {
        return try super.wrap(html: html) as! HTMLElement
    }

    /// A CSS selector that uniquely select this element.
    public var cssSelector: String {
        if let id {
            return "#" + id
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

        if (parent == nil || ((parent as? HTMLDocument) != nil)) // don't add HTMLDocument to selector, as will always have a html node
        {
            return selector
        }

        selector.insert(contentsOf: " > ", at: selector.startIndex)
        if (parent!.select(cssQuery: selector).count > 1) {
            selector.append(":nth-child(\(elementSiblingIndex + 1))")
        }

        return parent!.cssSelector + (selector)
    }

    /// Elements of siblings.
    ///
    /// An element is not a sibling of itself, so is excluded in the this property.
    public var siblingElements: HTMLElements {
        if parentNode == nil {
            return HTMLElements()
        }

        if let elements = parent?.children {
            let selfExcluded = elements.filter { $0 != self }
            return HTMLElements(selfExcluded)
        } else {
            return HTMLElements()
        }
    }

    /// The next sibling element of this element.
    ///
    /// This is similar to ``Node/nextSibling``, but specifically finds only elements.
    public var nextSiblingElement: HTMLElement? {
        guard let parent = parent else {
            return nil
        }
        let siblings = parent.children
        guard let index = siblings.firstIndex(of: self) else {
            return nil
        }
        
        return siblings.getElement(at: index + 1)
    }

    /// The preivous sibling element of this element.
    ///
    /// This is similar to ``Node/previousSibling``, but specifically finds only elements.
    public var previousSiblingElement: HTMLElement? {
        guard let parent = parent else {
            return nil
        }
        let siblings = parent.children
        guard let index = siblings.firstIndex(of: self) else {
            return nil
        }

        return siblings.getElement(at: index - 1)
    }

    /// The first sibling element of this element.
    public var firstSiblingElement: HTMLElement? {
        return parent?.children.first
    }

    /// An index value of this element in its element sibling list.
    ///
    /// This is similar to ``Node/siblingIndex``, but specifically indicates the index in the sibling elements.
    public var elementSiblingIndex: Int {
        guard let parent = parent else {
            return 0
        }
        return parent.children.firstIndex(of: self)!
    }

    /// The last sibling element of this element.
    public var lastSiblingElement: HTMLElement? {
        return parent?.children.last
    }

    // MARK: `getElementsBy...` Methods
    /// Get a list of elements by their tag name.
    ///
    /// Find elements with the specific tag name including itself and all descendants.
    ///
    /// - Parameter tagName: The tag name to search for. Case insensitive.
    /// - Returns: A matching list of elements.
    public func getElementsByTag(named tagName: String) -> HTMLElements {
        guard !tagName.isEmpty else { return HTMLElements() }
        let tagName = tagName.lowercased().trim()

        let result = try? Collector.collect(Evaluator.Tag(tagName), self)
        return result ?? HTMLElements()
    }

    /// Get an element by ID.
    ///
    /// Find the first matching element by ID. Starting with this element, it searches all descendants including itself.
    ///
    /// - Parameter id: The id to search for.
    /// - Returns: The first mathcing element by ID.
    public func getElementById(_ id: String) -> HTMLElement? {
        guard !id.isEmpty else { return nil }

        guard let elements: HTMLElements = try? Collector.collect(Evaluator.Id(id), self) else {
            return nil
        }
        if (elements.count > 0) {
            return elements.getElement(at: 0)
        } else {
            return nil
        }
    }

    /// Get a list of elements by its class name.
    ///
    /// Find elements with the specific class name including itself and all descendants.
    ///
    /// - Parameter className: A class name to search for.
    /// - Returns: A matching list of elements.
    public func getElementsByClass(named className: String) -> HTMLElements {
        let result = try? Collector.collect(Evaluator.Class(className), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements that have an attribute with the given key.
    ///
    /// Find elements with the specific attirbute key including itself and all descendants.
    ///
    /// - Parameter key: An attribute key to search for. Case insensitive.
    /// - Returns: A matching list of elements.
    public func getElementsByAttribute(key: String) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.Attribute(key), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements whose attribute keys start with supplied prefix.
    ///
    /// Find elements with the attribute key prefix including itself and all descendants.
    ///
    /// - Parameter keyPrefix: A prefix of attribute key to search for.
    /// - Returns: A matching list of elements.
    public func getElementsByAttribute(keyPrefix: String) -> HTMLElements {
        guard !keyPrefix.isEmpty else { return HTMLElements() }
        let keyPrefix = keyPrefix.trim()

        let result = try? Collector.collect(Evaluator.AttributeStarting(keyPrefix), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements whose attributes have the specific value.
    ///
    /// Find elements that match both the given attirbute key and value. Starting with this element, it searches all descendants including itself case insensitively.
    ///
    /// - Parameters
    ///     - key: A attribute key to search for.
    ///     - value: A value that an attribute's value with the given key should have.
    /// - Returns: A matching list of elements.
    public func getElementsByAttribute(key: String, value: String) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.AttributeWithValue(key, value), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements which either do not have attribute with the given key or with a different value.
    ///
    /// Find elements that do not match either the given attirbute key or value. Starting with this element, it searches all descendants including itself case insensitively.
    ///
    /// - Parameters
    ///     - key: A attribute key to search for.
    ///     - value: A value that an attribute's value with the given key should not have.
    /// - Returns: A matching list of elements.
    public func getElementsByAttributeNotMatching(key: String, value: String) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.AttributeWithValueNot(key, value), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements whose attribute value start with the given prefix.
    ///
    /// Find elements that match both the given attirbute key and value prefix. Starting with this element, it searches all descendants including itself case insensitively.
    ///
    /// - Parameters
    ///     - key: An attribute key to search for.
    ///     - valuePrefix: A prefix that an attribute's value with the given key should start with.
    /// - Returns: A matching list of elements.
    public func getElementsByAttribute(key: String, valueStartingWith valuePrefix: String) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()
        
        let result = try? Collector.collect(Evaluator.AttributeWithValueStarting(key, valuePrefix), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements whose attribute values end with the given suffix.
    ///
    /// Find elements that match both the given attirbute key and value prefix. Starting with this element, it searches all descendants including itself case insensitively.
    ///
    /// - Parameters
    ///     - key: An attribute key to search for.
    ///     - valueSuffix: A suffix that an attribute's value with the given key should end with.
    /// - Returns: A matching list of elements.
    public func getElementsByAttribute(key: String, valueEndingWith valueSuffix: String) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()
        
        let result = try? Collector.collect(Evaluator.AttributeWithValueEnding(key, valueSuffix), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements whose attribute values contain the given keyword.
    ///
    /// Find elements that have attributes with the given attirbute key, and whose attribute value also contains the given match string. Starting with this element, it searches all descendants including itself case insensitively.
    ///
    /// - Parameters
    ///     - key: An attribute key to search for.
    ///     - match: A substring that an attribute's value with the given key should contains.
    /// - Returns: A matching list of elements.
    public func getElementsByAttribute(key: String, valueMatchingWith match: String) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()
        
        let result = try? Collector.collect(Evaluator.AttributeWithValueContaining(key, match), self)
        return result ?? HTMLElements()
    }

    /**
     * Find elements that have attributes whose values match the supplied regular expression.
     * @param key name of the attribute
     * @param pattern compiled regular expression to match against attribute values
     * @return elements that have attributes matching this regular expression
     */
    
    ///
    public func getElementsByAttribute(key: String, valueMatchingWith pattern: Pattern) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()

        let result = try? Collector.collect(Evaluator.AttributeWithValueMatching(key, pattern), self)
        return result ?? HTMLElements()
    }

    /// Get a list of elements whose attribute values match the supplied regular expression.
    ///
    /// Find elements that have attributes with the given attirbute key, and whose attribute value also match the given regular expression string. Starting with this element, it searches all descendants including itself.
    ///
    /// - Parameters
    ///     - key: An attribute key to search for.
    ///     - match: A substring that an attribute's value with the given key should contains.
    /// - Returns: A matching list of elements.
    public func getElementsByAttribute(key: String, valueRegex regex: String) -> HTMLElements {
        guard !key.isEmpty else { return HTMLElements() }
        let key = key.trim()

        var pattern: Pattern
        do {
            pattern = Pattern.compile(regex)
            try pattern.validate()
        } catch {
            return HTMLElements()
        }
        return getElementsByAttribute(key: key, valueMatchingWith: pattern)
    }
    
    // TODO: SwiftRegex

    /// Get a list of elements whose sibling index is less than the supplied index.
    ///
    /// Find elements whose sibling index is less than the given index. Starting with this element, it searches all descendants including itself.
    public func getElementsByIndex(lessThan index: Int) -> HTMLElements {
        do {
            return try Collector.collect(Evaluator.IndexLessThan(index), self)
        } catch {
            return HTMLElements()
        }
    }

    /// Get a list of elements whose sibling index is greater than the supplied index.
    ///
    /// Find elements whose sibling index is greater than the given index. Starting with this element, it searches all descendants including itself.
    public func getElementsByIndex(greaterThan index: Int) -> HTMLElements {
        do {
            return try Collector.collect(Evaluator.IndexGreaterThan(index), self)
        } catch {
            return HTMLElements()
        }
    }

    /// Get a list of elements whose sibling index is equal to the supplied index.
    ///
    /// Find elements whose sibling index is equalt to the supplied index. Starting with this element, it searches all descendants including itself.
    public func getElementsByIndex(equals index: Int) -> HTMLElements {
        do {
            return try Collector.collect(Evaluator.IndexEquals(index), self)
        } catch {
            return HTMLElements()
        }
    }

    /// Get a list of elements that contain the specified string.
    ///
    /// Find elements with the given text. The matched text may appear directly in the element, or in any of its descendants. The search is case insensitive.
    ///
    /// - Parameter searchText: A search text to look for in the element's text.
    /// - Returns: Elements that contain the search text.
    public func getElementsContainingText(_ searchText: String) -> HTMLElements {
        do {
            return try Collector.collect(Evaluator.ContainsText(searchText), self)
        } catch {
            return HTMLElements()
        }
    }

    /// Get a list of elements that directly contain the specified string.
    ///
    /// Find elements with the given text. Only the elements in which the matched text appear directly will be collected. The search is case insensitive.
    ///
    /// - Parameter searchText: A search text to look for in the element's own text.
    /// - Returns: Elements that contain the search text directly.
    public func getElementsContainingOwnText(_ searchText: String) -> HTMLElements {
        do {
            return try Collector.collect(Evaluator.ContainsOwnText(searchText), self)
        } catch {
            return HTMLElements()
        }
    }

    /**
     * Find elements whose text matches the supplied regular expression.
     * @param pattern regular expression to match text against
     * @return elements matching the supplied regular expression.
     * @see HTMLElement#text()
     */
    
    ///
    public func getElementsMatchingText(_ pattern: Pattern) -> HTMLElements {
        do {
            return try Collector.collect(Evaluator.Matches(pattern), self)
        } catch {
            return HTMLElements()
        }
    }

    /// Get a list of elements whose text matches the supplied regular expression.
    ///
    /// Find elements with the given regular expression. The matched text may appear directly in the element, or in any of its descendants.
    ///
    /// - Parameter regex: Regular expression to match text against.
    /// - Returns: Elements that match the supplied regualr expression.
    public func getElementsMatchingText(_ regex: String) -> HTMLElements {
        let pattern: Pattern
        do {
            pattern = Pattern.compile(regex)
            try pattern.validate()
        } catch {
            return HTMLElements()
        }
        return getElementsMatchingText(pattern)
    }

    /**
     * Find elements whose own text matches the supplied regular expression.
     * @param pattern regular expression to match text against
     * @return elements matching the supplied regular expression.
     * @see HTMLElement#ownText()
     */
    
    ///
    public func getElementsMatchingOwnText(_ pattern: Pattern) -> HTMLElements {
        do {
            return try Collector.collect(Evaluator.MatchesOwn(pattern), self)
        } catch {
            return HTMLElements()
        }
    }

    /// Get a list of elements whose own text matches the supplied regular expression.
    ///
    /// Find elements with the given regular expression. Only the elements in which the matched text appear directly will be collected.
    ///
    /// - Parameter regex: Regular expression to match text against.
    /// - Returns: Elements that match the supplied regualr expression.
    public func getElementsMatchingOwnText(_ regex: String) -> HTMLElements {
        let pattern: Pattern
        do {
            pattern = Pattern.compile(regex)
            try pattern.validate()
        } catch {
            return HTMLElements()
        }
        return getElementsMatchingOwnText(pattern)
    }

    /// Elements of all elements under this element.
    ///
    /// This property represents all descendants of this element and also itself.
    public var allElements: HTMLElements {
        do {
            return try Collector.collect(Evaluator.AllElements(), self)
        } catch {
            return HTMLElements()
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
                    HTMLElement.appendNormalisedText(accum, textNode)
                } else {
                    accum.append(textNode.getWholeText())
                }
            } else if let element = (node as? HTMLElement) {
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
    
    /// Get a text within this element.
    ///
    /// This method retrieves the text within this element. The text includes not only the text directly in the element but also the text of its descendants.
    ///
    /// Each collected text may be trimmed and its whitespace normalized by the `trimAndNormaliseWhitespace` option.
    /// ```swift
    /// let html =
    /// """
    /// <p>One
    ///     <span>Two  </span>
    ///     Three
    ///     <br>  Four
    /// </p>
    /// """
    /// let document = HTMLParser.parse(html)!
    /// let p = document.getElementsByTag(named: "p").first!
    ///
    /// print(p.getText(trimAndNormaliseWhitespace: true))
    /// print(p.getText(trimAndNormaliseWhitespace: false))
    /// print(p.ownText)
    ///
    /// // Prints:
    /// // One Two Three Four  - getText(trimAndNormaliseWhitespace: true)
    /// // One                 - getText(trimAndNormaliseWhitespace: false)
    /// //     Two
    /// //     Three
    /// //       Four
    ///
    /// // One Three Four      - ownText
    /// ```
    ///
    /// # See Also
    /// * ``text`` : A simple property version of this method.
    /// * ``ownText`` : An element's own text.
    ///
    /// - Parameter trimAndNormaliseWhitespace: Trim and normalize whitespace if it's `true`.
    /// - Returns: A combined text within this element.
    public func getText(trimAndNormaliseWhitespace: Bool = true) -> String {
        let accum: StringBuilder = StringBuilder()
        try? NodeTraversor(textNodeVisitor(accum, trimAndNormaliseWhitespace: trimAndNormaliseWhitespace)).traverse(self)
        let text = accum.toString()
        if trimAndNormaliseWhitespace {
            return text.trim()
        }
        return text
    }
    
    /// A text within this element.
    ///
    /// A text that includes not only the text directly in the element but also the text of its descendants.
    ///
    /// This is a simple property version of ``getText(trimAndNormaliseWhitespace:)`` where `trimAndNormaliseWhitespace` is `true`.
    /// ```swift
    /// let html =
    /// """
    /// <p>One
    ///     <span>Two  </span>
    ///     Three
    ///     <br>  Four
    /// </p>
    /// """
    /// let document = HTMLParser.parse(html)!
    /// let p = document.getElementsByTag(named: "p").first!
    ///
    /// print(p.text)
    /// print(p.getText(trimAndNormaliseWhitespace: false))
    /// print(p.ownText)
    ///
    /// // Prints:
    /// // One Two Three Four  - text
    /// // One                 - getText(trimAndNormaliseWhitespace: false)
    /// //     Two
    /// //     Three
    /// //       Four
    /// //
    /// // One Three Four      - ownText
    /// ```
    ///
    /// # See Also
    /// * ``getText(trimAndNormaliseWhitespace:)`` : Original version of this property.
    /// * ``ownText`` : An element's own text.
    public var text: String {
        getText()
    }

    /// A text directly in this element.
    ///
    /// This property represent only the text owned by this element whereas ``text`` also contains its desendants' texts.
    /// ```swift
    /// let html =
    /// """
    /// <p>One
    ///     <span>Two  </span>
    ///     Three
    ///     <br>  Four
    /// </p>
    /// """
    /// let document = HTMLParser.parse(html)!
    /// let p = document.getElementsByTag(named: "p").first!
    ///
    /// print(p.text)
    /// // Prints "One Two Three Four"
    ///
    /// print(p.ownText)
    /// // Prints "One Three Four"
    /// ```
    ///
    /// # See Also
    /// * ``text`` : A text within an element
    /// * ``getText(trimAndNormaliseWhitespace:)`` : Get a text within an element.
    public var ownText: String {
        let stringBuilder: StringBuilder = StringBuilder()
        ownText(stringBuilder)
        return stringBuilder.toString().trim()
    }

    private func ownText(_ accum: StringBuilder) {
        for child: Node in childNodes {
            if let textNode = (child as? TextNode) {
                HTMLElement.appendNormalisedText(accum, textNode)
            } else if let child =  (child as? HTMLElement) {
                HTMLElement.appendWhitespaceIfBr(child, accum)
            }
        }
    }

    private static func appendNormalisedText(_ accum: StringBuilder, _ textNode: TextNode) {
        let text: String = textNode.getWholeText()

        if (HTMLElement.preserveWhitespace(textNode.parentNode)) {
            accum.append(text)
        } else {
            StringUtil.appendNormalisedWhitespace(accum, string: text, stripLeading: TextNode.lastCharIsWhitespace(accum))
        }
    }

    private static func appendWhitespaceIfBr(_ element: HTMLElement, _ accum: StringBuilder) {
        if (element.tag.getName() == "br" && !TextNode.lastCharIsWhitespace(accum)) {
            accum.append(" ")
        }
    }

    static func preserveWhitespace(_ node: Node?) -> Bool {
        // looks only at this element and one level up, to prevent recursion & needless stack searches
        if let element = (node as? HTMLElement) {
            return element.tag.preserveWhitespace() || element.parent != nil && element.parent!.tag.preserveWhitespace()
        }
        return false
    }

    /// Set the text of this element.
    ///
    /// Set the text of this element. Any existing contents will be replaced.
    ///
    /// - Parameter text: A text to set.
    /// - Returns: `self`for chaining.
    /// - Attention: All of children of this element will be removed.
    @discardableResult
    public func setText(_ text: String) -> HTMLElement {
        removeAll()
        let textNode: TextNode = TextNode(text, baseURI)
        appendChild(textNode)
        return self
    }

    /// A Boolean value indicating whether this element has any text content.
    ///
    /// This property represents whether this element has any text. All texts in descendants are also checked.
    public var hasText: Bool {
        for childNode in childNodes {
            if let textNode = childNode as? TextNode {
                if !textNode.isBlank() {
                    return true
                }
            } else if let element = childNode as? HTMLElement {
                if element.hasText {
                    return true
                }
            }
        }
        return false
    }

    /// A String value representing combined non-text contents.
    ///
    /// This property includes non-textual content within this element,
    /// such as `<script>`, `<style>`, etc., including the content of its descendants.
    /// If there are no non-textual contents, this property is `nil`.
    ///
    /// ```swift
    /// let html =
    /// """
    /// <div id="js">
    /// <script> console.log('Hello, world!'); </script>
    /// </div>
    /// """
    /// let div = HTMLParser.parse(html)!.getElementById("js")!
    /// print(div.nonTextContent!)
    ///
    /// // Prints " console.log('Hello, world!'); "
    /// ```
    public var nonTextContent: String? {
        var isEmpty = true
        let stringBuilder: StringBuilder = StringBuilder()

        for childNode: Node in childNodes {
            if let data = (childNode as? DataNode) {
                isEmpty = false
                stringBuilder.append(data.getWholeData())
            } else if let element = (childNode as? HTMLElement) {
                if let elementData = element.nonTextContent {
                    isEmpty = false
                    stringBuilder.append(elementData)
                }
            }
        }
        return isEmpty ? nil : stringBuilder.toString()
    }

    /// A String value of this element's "class" attribute.
    ///
    /// This property represents the "class" attribute of this element. Multiple class names are separated by spaces. If there is no class attribute, this will be nil.
    public var className: String? {
        return getAttribute(withKey: HTMLElement.classString)?.trim()
    }

    /// A list of class names of this element.
    ///
    /// This property represents the all of the element's class names. In other words, this represent split values of "class" attribute using the separator `" "`.
    ///
    /// - Tip: Modifications to this set are not refelected. Use ``setClass(names:)`` to modify class names.
    public var classNames: OrderedSet<String> {
        guard let className else { return [] }
		let fitted = className.replaceAll(of: HTMLElement.classSplit, with: " ", options: .caseInsensitive)
        let names: [String] = fitted.components(separatedBy: " ")
		let classNames = OrderedSet(sequence: names)
		classNames.remove(HTMLElement.emptyString) // if classNames() was empty, would include an empty class
		return classNames
	}

    /// Set "class" attribute value of this element.
    ///
    /// This method combines the given class names and sets the "class" atrribute. Existing class attribute will be replaced.
    @discardableResult
    public func setClass(names: OrderedSet<String>) -> HTMLElement {
        try! attributes?.put(HTMLElement.classString, StringUtil.join(names, sep: " "))
        return self
    }

    // performance sensitive
    /// Check if this element has a class attribute with given name. Case insensitive.
    public func hasClass(named className: String) -> Bool {
        let classAtt: String? = attributes?.get(key: HTMLElement.classString)
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

    /// Add a class name to this element's class attribute.
    ///
    /// - Parameter className: A class name to add.
    /// - Returns: `self` for chaining.
    @discardableResult
	public func addClass(named className: String) -> HTMLElement {
		let classes = classNames
		classes.append(className)
		setClass(names: classes)
        
		return self
	}

    /// Remove a class name from this element's class attribute.
    ///
    /// - Parameter className: A class name to remove.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func removeClass(named className: String) -> HTMLElement {
        let classes = classNames
		classes.remove(className)
        setClass(names: classes)
        
        return self
    }

    /// Toggle a class name on this element's class attribute.
    ///
    /// If the class name exists, remove it; otherwise add it.
    ///
    /// - Parameter className: A class name to toggle.
    /// - Returns `self` for chaining.
    @discardableResult
    public func toggleClass(named className: String) -> HTMLElement {
        let classes = classNames
        if classes.contains(className) {
            classes.remove(className)
        } else {
            classes.append(className)
        }
        setClass(names: classes)

        return self
    }
    
    /// A string value of a form element.
    ///
    /// This property represents a value of a form element like `input` or `textarea`. For a `textarea` element, the value will be the text of the textarea.
    public var value: String? {
        if tagName == "textarea" {
            return text
        } else {
            return getAttribute(withKey: "value")
        }
    }

    /// Set the value of a form element.
    ///
    /// Set a value of form element like `input` or `textarea` with this method.
    ///
    /// - Parameter value: A new value to set.
    /// - Returns: `self` for chaining.
    @discardableResult
    public func setValue(_ value: String) -> HTMLElement {
        if tagName == "textarea" {
            setText(value)
        } else {
            try! setAttribute(withKey: "value", value: value)
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
    
    // FIXME: Found unexpected whitespaces. and add example code.
    /// A String value represents this element's inner HTML text.
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

    open override func html(_ appendable: StringBuilder) throws -> StringBuilder {
        for node in childNodes {
            try node.outerHtml(appendable)
        }
        return appendable
    }

    // FIXME: Parse HTML first before clear html
    /// Set this element's inner HTML.
    ///
    /// This method clears and sets the inner HTML. The given HTML string is first parsed as an ``HTMLElement`` and then replaces existing children with the parsed ``HTMLElement``.
    ///
    /// - Parameter html: A HTML string to parse and set into this element.
    /// - Returns: `self` for chaining.
    /// - Attention: Removing existing children precedes parsing the given HTML. This means that this element's children will be empty if an error occurs.
    ///
    /// ## Throws
    /// * `SwiftSoupError.failedToParseHTML` if a parser failed to parse HTML.
    @discardableResult
	public func setHTML(_ html: String) throws -> HTMLElement {
		removeAll()
		try appendHTML(html)
		return self
	}

	public override func copy(with zone: NSZone? = nil) -> Any {
		let clone = HTMLElement(tag: tag, baseURI: baseURI!, attributes: attributes!)
		return copy(clone: clone)
	}

	public override func copy(parent: Node?) -> Node {
		let clone = HTMLElement(tag: tag, baseURI: baseURI!, attributes: attributes!)
		return copy(clone: clone, parent: parent)
	}
	public override func copy(clone: Node, parent: Node?) -> Node {
		return super.copy(clone: clone, parent: parent)
	}

    public static func ==(lhs: HTMLElement, rhs: HTMLElement) -> Bool {
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
