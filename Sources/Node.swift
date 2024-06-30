//
//  Node.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/// A node of tree that contains data of parsed HTML or XML.
///
/// Basically, you use ``Element`` type, subclass of ``Node``, to access HTML elements rather than this type. ``Node`` object has information about a node that constitute a tree, like ``parent`` and ``getChildNodes()``. It also has information about the common elements of both HTML and XML like ``getAttributes()`` and ``absoluteURLPath(ofAttribute:)``.
///
/// - Note: This class also contains members only for HTML such as ``insertHTMLAsPreviousSibling(_:)``. I believe this has an unclear role as an OOP object and is considered an anti-pattern. However, it will be left as is to minimize changes to the existing code.
open class Node: Equatable, Hashable {
    private static let abs = "abs:"
    fileprivate static let empty = ""
    private static let EMPTY_NODES = Array<Node>()
    weak var parentNode: Node?
    public var childNodes: [Node]
    var attributes: Attributes?
    /// Base URI of this node.
    public internal(set) var baseURI: String?

    /// The index of this node in its node sibling list.
    public var siblingIndex: Int = 0

    /// Create a new ``Node``.
    public init(baseURI: String, attributes: Attributes) {
        self.childNodes = Node.EMPTY_NODES
        self.baseURI = baseURI.trim()
        self.attributes = attributes
    }
    /// Create a new ``Node`` with empty attributes.
    public init(baseURI baseUri: String) {
        childNodes = Node.EMPTY_NODES
        self.baseURI = baseUri.trim()
        self.attributes = Attributes()
    }
    /// Create a new ``Node`` with no attributes and baseURI.
    public init() {
        self.childNodes = Node.EMPTY_NODES
        self.attributes = nil
        self.baseURI = nil
    }

    /// The node name of this node.
    ///
    /// This is an abstract property. Subclasses overrides this property. For example, ``Element`` returns tag name and ``HTMLDocument`` returns literal `"#document"`.
    /// Call this method directly in ``Node`` instance will cause `fatalError`.
    public var nodeName: String {
        preconditionFailure("This method must be overridden")
    }

    /// Get a value of an attribute with the given key.
    ///
    /// - Parameters:
    ///     - key: The key of an attribute. Case sensitive. Should not be empty.
    ///
    /// - Returns: The value of an attribute with the given key. If not exists, returns nil.
    open func getAttribute(withKey key: String) -> String? {
        guard let value = try? attributes?.getIgnoreCase(key: key) else {
            return nil
        }
        if value.count > 0 {
            return value
        } else if (key.lowercased().startsWith(Node.abs)) {
            return absoluteURLPath(ofAttribute: key.substring(Node.abs.count))
        } else {
            return nil
        }
    }

    /// Get all of the elemtent's attributes.
    open func getAttributes() -> Attributes? {
        return attributes
    }

    /// Set an attribute of this node.
    ///
    /// Set an attribute with the given key. If the attribute already exists, it will be replaced.
    ///
    /// - Parameters:
    ///     - key: The key of an attribute to set. Must not be empty, otherwise throws `SwiftSoupError.emptyAttributeKey` error.
    ///     - value: The new value of an attribute with the given key.
    ///
    /// - Returns: `self` for chaining.
    ///
    /// ## Throws
    /// * `SwiftSoupError.emptyAttributeKey` if the given attributet key is an empty string.
    @discardableResult
    open func setAttribute(withKey key: String, newValue: String) throws -> Node {
        try attributes?.put(key, newValue)
        return self
    }

    /// A Boolean value indicating whether a node has any attributes.
    ///
    /// - Parameters:
    ///     - key: The key of an attribute to check.
    open func hasAttribute(withKey key: String) -> Bool {
		guard let attributes = attributes else {
			return false
		}
        if key.startsWith(Node.abs) {
            let key: String = key.substring(Node.abs.count)
            let abs = absoluteURLPath(ofAttribute: key)
            if let abs, !abs.isEmpty, attributes.hasKeyIgnoreCase(key: key) {
                return true
            }
        }
        return attributes.hasKeyIgnoreCase(key: key)
    }

    /// Remove an attribute from this node.
    ///
    /// - Parameters:
    ///     - key: The key of an attribute to remove. Must not be empty, otherwise throws `SwiftSoupError.emptyAttributeKey`error.
    ///
    /// - Returns: `self` for chaining.
    ///
    /// ## Throws
    /// * `SwiftSoupError.emptyAttributeKey` if the given attributet key is an empty string.
    @discardableResult
    open func removeAttribute(withKey key: String) throws -> Node {
        try attributes?.removeIgnoreCase(key: key)
        return self
    }

    /// Update the base URI of this node and all of its descendants.
    open func setBaseURI(_ baseURI: String) {
        try! traverse(nodeVisitor(baseURI)) // Never throws
        
        class nodeVisitor: NodeVisitor {
            private let baseURI: String
            init(_ baseURI: String) {
                self.baseURI = baseURI
            }

            func head(_ node: Node, _ depth: Int) throws {
                node.baseURI = baseURI
            }

            func tail(_ node: Node, _ depth: Int) throws {
            }
        }
    }

    /// Get an absolute URL string from an attribute.
    ///
    /// Get a URL string from an attribute of this node. The URL path will be resolved if the retrieved URL is relative.
    /// ```swift
    /// let wiki: HTMLDocument = ... // Parsed HTML of "https://en.wikipedia.org/wiki/Swift"
    /// wiki.baseURI = "https://en.wikipedia.org/"
    /// let link = wiki.getElementsContainingText("Swift (programming language)").first!
    /// let href = link.getAttribute(key: "href")!
    /// let urlPath = link.absoluteURLPath(ofAttribute: "href")!
    ///
    /// print(href)
    /// print(urlPath)
    ///
    /// // Prints "/wiki/Swift_(programming_language)"
    /// // Prints "https://en.wikipedia.org/wiki/Swift_(programming_language)"
    /// ```
    ///
    /// If the attribute value is already an absolute URL path, such as one containing `https://`, the attribute will be returned directly.
    ///
    /// - Parameters:
    ///     - attributeKey: The key of an attribute to retrieve URL path as value.
    ///
    /// - Returns: An absolute URL string. If there's no attribute with the given key, returns `nil`.
    open func absoluteURLPath(ofAttribute attributeKey: String) -> String? {
        guard let baseURI, let uriComponent = getAttribute(withKey: attributeKey) else {
            return nil
        }
        
        return StringUtil.resolve(baseURI, relUrl: uriComponent)
    }

    /// Get a child node by given index.
    ///
    /// Get a child by its 0-based index.
    ///
    /// - Attention: This method doesn't check if the index is in safe range. If the index out of bounds, it will cause a runtime error.
    open func childNode(_ index: Int) -> Node {
        return childNodes[index]
    }

    /// Get this node's children
    open func getChildNodes() -> [Node] {
        return childNodes
    }

    /// Get a deep copy of this node's children.
    ///
    /// Get a deep copy of this node's children. Changes made to these nodes will not be reflected in the original nodes.
    open func childNodesCopy() -> [Node] {
		var children: Array<Node> = Array<Node>()
		for node: Node in childNodes {
			children.append(node.copy() as! Node)
		}
		return children
    }

    /// Get the number of this node's children.
    public func childNodeSize() -> Int {
        return childNodes.count
    }

    final func childNodesAsArray() -> [Node] {
        return childNodes as Array
    }

    /// The parent node of this node.
    open var parent: Node? {
        return parentNode
    }

    /// Get the HTMLDocument associated with this node.
    ///
    /// - Returns: A ``HTMLDocument`` object associated with this node. If there's no such document, returns `nil`.
    open func ownerDocument() -> HTMLDocument? {
        if let this = self as? HTMLDocument {
            return this
        } else if let parentNode {
            return parentNode.ownerDocument()
        } else {
            return nil
        }
    }

    /// Remove this node from the DOM tree.
    ///
    /// Remove this node from the DOM tree. If this node has children, they are also removed together.
    open func remove() {
        // Assume users never try to remove root node
        try! parentNode?.removeChild(self)
    }

    /// Insert the specified HTML into the DOM as a preceding sibling.
    ///
    /// Parse the given HTML string and create a new node. Then, insert the new node as a preceding sibling of this node.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this node doesn't have a parent.
    /// * `SwiftSoupError.failedToParseHTML` if parsing HTML is failed.
    ///
    /// - Parameter html: HTML string to add before this node.
    /// - Returns: `self` for chaining.
    @discardableResult
    open func insertHTMLAsPreviousSibling(_ html: String) throws -> Node {
        try insertSiblingHTML(html, at: siblingIndex)
        return self
    }

    /// Insert the specified node into the DOM as a preceding sibling.
    ///
    /// Insert the given node as a preceding sibling of this node.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this node doesnt't have a parent.
    ///
    /// - Parameter node: A node to insert.
    /// - Returns: `self` for chaining.
    @discardableResult
    open func insertNodeAsPreviousSibling(_ node: Node) throws -> Node {
        guard let parentNode else {
            throw SwiftSoupError.noParentNode
        }

        parentNode.insertChildren(node, at: siblingIndex)
        return self
    }

    /// Insert the specified HTML into the DOM as a following sibling.
    ///
    /// Parse the given HTML string and create a new node. Then, insert the new node as a following sibling of this node.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this node doesn't have a parent.
    /// * `SwiftSoupError.failedToParseHTML` if parsing HTML is failed.
    ///
    /// - Parameter html: HTML string to add after this node.
    /// - Returns: `self` for chaining.
    @discardableResult
    open func insertHTMLAsNextSibling(_ html: String) throws -> Node {
        try insertSiblingHTML(html, at: siblingIndex + 1)
        return self
    }

    /// Insert the specified node into the DOM as a following sibling.
    ///
    /// Insert the given node as a following sibling of this node.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this node doesnt't have a parent.
    ///
    /// - Parameter node: A node to add after this node.
    /// - Returns: `self` for chaining.
    @discardableResult
    open func insertNodeAsNextSibling(_ node: Node) throws -> Node {
        guard let parentNode else {
            throw SwiftSoupError.noParentNode
        }

        parentNode.insertChildren(node, at: siblingIndex + 1)
        return self
    }

    /// Insert the specified HTML into the DOM as a sibling at the given index.
    ///
    /// Parse the given HTML string and create a new node. Then, insert the node as a sibling at the given index.
    ///
    /// - Parameters:
    ///     - html: HTML string to insert.
    ///     - index: The index at which to insert in the siblings.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if this node does not have a parent.
    /// * `SwiftSoupError.failedToParseHTML` if parsing HTML is failed.
    open func insertSiblingHTML(_ html: String, at index: Int) throws {
        guard let parentNode else {
            throw SwiftSoupError.noParentNode
        }

        let context: Element? = parent as? Element
        let nodes: [Node] = try HTMLParser._parseHTMLFragment(html, context: context, baseURI: baseURI!)
        parentNode.insertChildren(nodes, at: index)
    }

    /// Wrap the supplied HTML around this node.
    ///
    /// - Parameter html: HTML to wrap around this element. For example, `"<div class="head"></div>"`. Can be arbitrarily deep.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    open func wrap(html: String) throws -> Node {
        guard !html.isEmpty else {
            throw SwiftSoupError.emptyHTML
        }

        let context = parent as? Element
        var wrapChildren = try HTMLParser._parseHTMLFragment(html, context: context, baseURI: baseURI!)
        guard wrapChildren.count > 0, let wrap = wrapChildren[0] as? Element else {
            throw SwiftSoupError.noHTMLElementsToWrap
        }

        let deepest: Element = getDeepChild(element: wrap)
        try parentNode?.replaceChildNode(self, with: wrap)
		wrapChildren = wrapChildren.filter { $0 != wrap }
        deepest.appendChildren(self)

        // remainder (unbalanced wrap, like <div></div><p></p> -- The <p> is remainder
        if wrapChildren.count > 0 {
            for i in  0..<wrapChildren.count {
                let remainder: Node = wrapChildren[i]
                try remainder.parentNode?.removeChild(remainder)
                wrap.appendChild(remainder)
            }
        }
        
        return self
    }

    /// Unwrap this node from the DOM.
    ///
    /// Remove this node from the DOM and move its children up into the parent node. This has the effect of dropping the node but keeping its children.
    /// ```swift
    /// let html =
    /// """
    /// <div>One
    ///     <span>Two
    ///         <b>Three</b>
    ///     </span>
    /// </div>
    /// """
    /// let document = HTMLParser.parse(html)!
    /// let span = document.getElementsByTag("span").first!
    /// let result = try! span.unwrap()
    ///
    /// print(document.body!.html!)
    /// print(result)
    ///
    /// // Prints:
    /// // <div>One Two
    /// //     <b>Three</b>
    /// // </div>
    ///
    /// // Prints "Two "
    /// ```
    /// In the codes above, `result` is a ``TextNode`` contains text "Two " which was the first child node of `span`.
    ///
    /// ## Throws
    /// * `SwiftSoupError.noParentNode` if there's no parent node.
    /// * `SwiftSoupError.noChildrenToUnwrap` if there's no children node.
    ///
    /// - Returns: The first child of this node. It may be a ``TextNode``.
    @discardableResult
    open func unwrap() throws -> Node {
        guard let parentNode else {
            throw SwiftSoupError.noParentNode
        }
        guard let firstChild = childNodes.first else {
            throw SwiftSoupError.noChildrenToUnwrap
        }
        
        parentNode.insertChildren(self.childNodesAsArray(), at: siblingIndex)
        self.remove()

        return firstChild
    }

    private func getDeepChild(element: Element) -> Element {
        let children = element.children
        if (children.count > 0) {
            return getDeepChild(element: children.get(index: 0)!)
        } else {
            return element
        }
    }

    /// Replace this node with the supplied node.
    ///
    /// - Note: If this is a root node, this method does nothing.
    public func replace(with newNode: Node) {
        // Do nothing if self is root node
        if let parentNode {
            try! parentNode.replaceChildNode(self, with: newNode)
        }
    }

    /// Set the parent node to the supplied node.
    public func setParentNode(_ newParentNode: Node) {
        if let parentNode {
            try! parentNode.removeChild(self)
        }
        self.parentNode = newParentNode
    }

    /// Replace the specified child node with the new node.
    ///
    /// ## Throws
    /// * `SwiftSoupError.notChildNode` if the given child node is not a child of this.
    public func replaceChildNode(_ childNode: Node, with newNode: Node) throws {
        guard childNode.parentNode === self else {
            throw SwiftSoupError.notChildNode
        }

        if let parentNode = newNode.parentNode {
            try parentNode.removeChild(newNode)
        }

        let index: Int = childNode.siblingIndex
        childNodes[index] = newNode
        newNode.parentNode = self
        newNode.siblingIndex = index
        childNode.parentNode = nil
    }

    /// Remove the sepcified child node.
    ///
    /// ## Throws
    /// *  `SwiftSoupError.notChildNode` if the given child node is not a child of this.
    public func removeChild(_ node: Node) throws {
        guard node.parentNode === self else {
            throw SwiftSoupError.notChildNode
        }

        let index: Int = node.siblingIndex
        childNodes.remove(at: index)
        reindexChildren(index)
        node.parentNode = nil
    }

    /// Append the given nodes as children.
    public func appendChildren(_ children: Node...) {
        //most used. short circuit addChildren(int), which hits reindex children and array copy
        appendChildren(children)
    }

    /// Append the given nodes as children.
    public func appendChildren(_ children: [Node]) {
        //most used. short circuit addChildren(int), which hits reindex children and array copy
        for child in children {
            reparentChild(child)
            ensureChildNodes()
            childNodes.append(child)
            child.siblingIndex = childNodes.count - 1
        }
    }

    /// Insert the given nodes as children at specified index.
    public func insertChildren(_ children: Node..., at index: Int) {
        insertChildren(children, at: index)
    }

    /// Insert the given nodes as children at specified index.
    public func insertChildren(_ children: [Node], at index: Int) {
        ensureChildNodes()
        for i in children.indices.reversed() {
            let input: Node = children[i]
            reparentChild(input)
            childNodes.insert(input, at: index)
            reindexChildren(index)
        }
    }

    public func ensureChildNodes() {
        // What is this for?
        if childNodes == Node.EMPTY_NODES {
            childNodes = Array<Node>()
        }
    }

    public func reparentChild(_ childNode: Node) {
        if let parentNode = childNode.parentNode {
            try! parentNode.removeChild(childNode)
        }
        
        childNode.setParentNode(self)
    }

    private func reindexChildren(_ start: Int) {
        for i in start..<childNodes.count {
            childNodes[i].siblingIndex = i
        }
    }

    /// An array of nodes which are siblings of this node.
    ///
    /// An array of nodes which are siblings of this node. It doesn't contains this node itself.
    open var siblingNodes: [Node] {
        guard let parentNode else { return [] }

        let nodes: [Node] = parentNode.childNodes
        var siblings: [Node] = []
        for node in nodes {
            if node !== self {
                siblings.append(node)
            }
        }

        return siblings
    }

    /**
     Get this node's next sibling.
     @return next sibling, or null if this is the last sibling
     */
    
    /// The next sibling node of this node.
    ///
    /// The next sibling node of this node. If not exists, it is `nil`.
    open var nextSibling: Node? {
        guard let siblings = parentNode?.childNodes else {
            return nil
        }

        let index = siblingIndex + 1
        if siblings.count > index {
            return siblings[index]
        } else {
            return nil
        }
    }

    /// The previous sibling of this node.
    ///
    /// The previous sibling of this node. If not exists, it is `nil`.
    open var previousSibling: Node? {
        guard let parentNode else {
            return nil
        }

        if siblingIndex > 0 {
            return parentNode.childNodes[siblingIndex - 1]
        } else {
            return nil
        }
    }

    /// Perform a depth-first traversal through this node and its descendants.
    ///
    /// - Parameter nodeVisitor: The visitor callbacks to perform on each node.
    /// - Returns: `self` for chaining.
    @discardableResult
    open func traverse(_ nodeVisitor: NodeVisitor) throws -> Node {
        let traversor: NodeTraversor = NodeTraversor(nodeVisitor)
        try traversor.traverse(self)
        return self
    }

    /// The outer HTML of this node.
    open var outerHTML: String? {
        let accum: StringBuilder = StringBuilder(128)
        do {
            try outerHtml(accum)
        } catch {
            return nil
        }
        return accum.toString()
    }

    public func outerHtml(_ accum: StringBuilder) throws {
        try NodeTraversor(OuterHtmlVisitor(accum, getOutputSettings())).traverse(self)
    }

    // if this node has no document (or parent), retrieve the default output settings
    func getOutputSettings() -> OutputSettings {
        return ownerDocument() != nil ? ownerDocument()!.outputSettings : (HTMLDocument(baseURI: Node.empty)).outputSettings
    }

    /**
     Get the outer HTML of this node.
     @param accum accumulator to place HTML into
     @throws IOException if appending to the given accumulator fails.
     */
    func outerHtmlHead(_ accum: StringBuilder, _ depth: Int, _ out: OutputSettings) throws {
        preconditionFailure("This method must be overridden")
    }

    func outerHtmlTail(_ accum: StringBuilder, _ depth: Int, _ out: OutputSettings) throws {
        preconditionFailure("This method must be overridden")
    }

    /// Write this node and its children to the given ``StringBuilder``.
    ///
    /// - Parameter appendable: The ``StringBuilder`` to write to.
    /// - Returns: The supplied ``StringBuilder`` for chaining.
    open func html(_ appendable: StringBuilder) throws -> StringBuilder {
        try outerHtml(appendable)
        return appendable
    }

    public func indent(_ accum: StringBuilder, _ depth: Int, _ out: OutputSettings) {
        accum.append(UnicodeScalar.BackslashN).append(StringUtil.padding(depth * Int(out.indentAmount())))
    }

    /// Check if this node is the same instance of another
    ///
    /// Using this method is totally same as writing like `nodeA === nodeB`.
    open func equals(_ o: Node) -> Bool {
    // implemented just so that javadoc is clear this is an identity test
        return self === o
    }

    /// Check if this node has the same content as another node.
    open func hasSameValue(_ o: Node) -> Bool {
        if self === o {
            return true
        }

        return self.outerHTML == o.outerHTML
    }

    /// Create a stand-alone, deep copy of this node, and all of its children.
    ///
    /// The cloned node will have no siblings or
    /// parent node. As a stand-alone object, any changes made to the clone or any of its children will not impact the
    /// original node.
    /// <p>
    /// The cloned node may be adopted into another HTMLDocument or node structure using {@link Element#appendChild(Node)}.
    /// @return stand-alone cloned node
    public func copy(with zone: NSZone? = nil) -> Any {
		return copy(clone: Node())
    }

	public func copy(parent: Node?) -> Node {
		let clone = Node()
		return copy(clone: clone, parent: parent)
	}

	public func copy(clone: Node) -> Node {
		let thisClone: Node = copy(clone: clone, parent: nil) // splits for orphan

		// Queue up nodes that need their children cloned (BFS).
		var nodesToProcess: Array<Node> = Array<Node>()
		nodesToProcess.append(thisClone)

		while (!nodesToProcess.isEmpty) {
			let currParent: Node = nodesToProcess.removeFirst()

			for i in 0..<currParent.childNodes.count {
				let childClone: Node = currParent.childNodes[i].copy(parent: currParent)
				currParent.childNodes[i] = childClone
				nodesToProcess.append(childClone)
			}
		}
		return thisClone
	}

    /// Get a clone of the node using the given parent (which can be null).
    ///
    /// Not a deep copy of children.
	public func copy(clone: Node, parent: Node?) -> Node {
		clone.parentNode = parent // can be null, to create an orphan split
		clone.siblingIndex = parent == nil ? 0 : siblingIndex
		clone.attributes = attributes != nil ? attributes?.clone() : nil
		clone.baseURI = baseURI
		clone.childNodes = Array<Node>()

		for  child in childNodes {
			clone.childNodes.append(child)
		}

		return clone
	}

    private class OuterHtmlVisitor: NodeVisitor {
        private var accum: StringBuilder
        private var out: OutputSettings
        static private let  text = "#text"

        init(_ accum: StringBuilder, _ out: OutputSettings) {
            self.accum = accum
            self.out = out
        }

        open func head(_ node: Node, _ depth: Int)throws {

            try node.outerHtmlHead(accum, depth, out)
        }

        open func tail(_ node: Node, _ depth: Int)throws {
            // When compiling a release optimized swift linux 4.2 version the "saves a void hit."
            // causes a SIL error. Removing optimization on linux until a fix is found.
            #if os(Linux)
            try node.outerHtmlTail(accum, depth, out)
            #else
            if (!(node.nodeName == OuterHtmlVisitor.text)) { // saves a void hit.
                try node.outerHtmlTail(accum, depth, out)
            }
            #endif
        }
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs === rhs
    }

	/// The hash value.
	///
	/// Hash values are not guaranteed to be equal across different executions of
	/// your program. Do not save hash values to use during a future execution.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
        hasher.combine(baseURI)
    }
}

extension Node: CustomStringConvertible {
    /// A textual representation of this node.
    ///
    /// This property is same as `outherHTML ?? ""`.
	public var description: String {
        outerHTML ?? ""
	}
}

extension Node: CustomDebugStringConvertible {
    private static let space = " "
	public var debugDescription: String {
        if let outerHTML {
            return String(describing: type(of: self)) + Node.space + outerHTML
        } else {
            return String(describing: type(of: self))
        }
	}
}
