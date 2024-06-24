//
//  Elements.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 20/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

// TODO: Document
open class Elements: NSCopying {
	fileprivate var _elements: [Element] = []

	///base init
	public init() {
	}
	///Initialized with an array
	public init(_ a: Array<Element>) {
		_elements = a
	}
	///Initialized with an order set
	public init(_ a: OrderedSet<Element>) {
		_elements.append(contentsOf: a)
	}

	/**
	* Creates a deep copy of these elements.
	* @return a deep copy
	*/
	public func copy(with zone: NSZone? = nil) -> Any {
		let clone: Elements = Elements()
		for e: Element in _elements {
			clone.append(e.copy() as! Element)
		}
		return clone
	}

	/**
	* Get the combined text of all the matched elements.
	* <p>
	* Note that it is possible to get repeats if the matched elements contain both parent elements and their own
	* children, as the Element.text() method returns the combined text of a parent and all its children.
	* @return string of all text: unescaped and no HTML.
	* @see Element#text()
	*/
	open func text(trimAndNormaliseWhitespace: Bool = true) -> String {
		let sb: StringBuilder = StringBuilder()
		for element in self {
			if !sb.isEmpty {
				sb.append(" ")
			}
            sb.append(element.getText(trimAndNormaliseWhitespace: trimAndNormaliseWhitespace))
		}
		return sb.toString()
	}
    
    /**
     * Get the text content of each of the matched elements. If an element has no text, then it is not included in the
     * result.
     * @return A list of each matched element's text content.
     * @see Element#text()
     * @see Element#hasText()
     * @see #text()
     */
    public var texts: [String] {
        var texts: [String] = []
        for element in self {
            if element.hasText {
                texts.append(element.text)
            }
        }
        return texts
    }

	/**
	* Get the combined inner HTML of all matched elements.
	* @return string of all element's inner HTML.
	* @see #text()
	* @see #outerHtml()
	*/
    open var html: String? {
		let stringBuilder: StringBuilder = StringBuilder()
		for element in self {
			if !stringBuilder.isEmpty {
				stringBuilder.append("\n")
			}
            guard let subHTML = element.html else {
                return nil
            }
			stringBuilder.append(subHTML)
		}
		return stringBuilder.toString()
	}

	/**
	* Get the combined outer HTML of all matched elements.
	* @return string of all element's outer HTML.
	* @see #text()
	* @see #html()
	*/
    open var outerHtml: String? {
		let stringBuilder: StringBuilder = StringBuilder()
		for element in self {
			if !stringBuilder.isEmpty {
				stringBuilder.append("\n")
			}
            do {
                stringBuilder.append(try element.outerHtml())
            } catch {
                return nil
            }
		}
		return stringBuilder.toString()
	}
    
    // MARK: "has" Methods
    /**
    Checks if any of the matched elements have this attribute set.
    @param attributeKey attribute key
    @return true if any of the elements have the attribute; false if none do.
    */
    open func hasAttribute(key: String) -> Bool {
        for element in self {
            if element.hasAttr(key) {
                return true
            }
        }
        return false
    }

    /**
    Determine if any of the matched elements have this class name set in their {@code class} attribute.
    @param className class name to check for
    @return true if any do, false if none do
    */
    open func hasClass(named className: String) -> Bool {
        for element in self {
            if (element.hasClass(named: className)) {
                return true
            }
        }
        return false
    }

    /// Check if an element has text
    open var hasText: Bool {
        for element in self {
            if element.hasText {
                return true
            }
        }
        return false
    }

	// MARK: CSS Filters
	/**
	* Find matching elements within this element list.
	* @param query A {@link CssSelector} query
	* @return the filtered list of elements, or an empty list if none match.
	*/
	open func select(cssQuery: String) -> Elements {
        do {
            return try CssSelector.select(cssQuery, _elements)
        } catch {
            return Elements([])
        }
	}

	/**
	* Remove elements from this list that match the {@link CssSelector} query.
	* <p>
	* E.g. HTML: {@code <div class=logo>One</div> <div>Two</div>}<br>
	* <code>Elements divs = doc.select("div").not(".logo");</code><br>
	* Result: {@code divs: [<div>Two</div>]}
	* <p>
	* @param query the selector query whose results should be removed from these elements
	* @return a new elements list that contains only the filtered results
	*/
	open func selectNot(cssQuery: String) -> Elements {
        do {
            let out = try CssSelector.select(cssQuery, _elements)
            return CssSelector.filterOut(_elements, out._elements)
        } catch {
            return self.copy() as! Elements
        }
	}

	/**
	* Test if any of the matched elements match the supplied query.
	* @param query A selector
	* @return true if at least one element in the list matches the query.
	*/
    open func hasElementMatchedWithCSSQuery(_ cssQuery: String) -> Bool {
        guard let eval: Evaluator = try? QueryParser.parse(cssQuery) else {
            return false
        }
        
        for element in self {
            if element.isMatchedWith(evaluator: eval) {
                return true
            }
        }
        return false
    }

    // MARK: Array-Like Methods
	/**
	* Perform a depth-first traversal on each of the selected elements.
	* @param nodeVisitor the visitor callbacks to perform on each node
	* @return this, for chaining
	*/
    @discardableResult
	open func traverse(_ nodeVisitor: NodeVisitor) throws -> Elements {
		let traversor: NodeTraversor = NodeTraversor(nodeVisitor)
		for el: Element in _elements {
			try traversor.traverse(el)
		}
		return self
	}

	/**
	* Get the {@link FormElement} forms from the selected elements, if any.
	* @return a list of {@link FormElement}s pulled from the matched elements. The list will be empty if the elements contain
	* no forms.
	*/
	open func forms() -> Array<FormElement> {
		var forms: Array<FormElement> = Array<FormElement>()
		for el: Element in _elements {
			if let el = el as? FormElement {
				forms.append(el)
			}
		}
		return forms
	}
    
    open func append(_ newElement: Element) {
        _elements.append(newElement)
    }
    
    open func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        _elements.append(contentsOf: newElements)
    }
    
    open func insert(_ newElement: Element, at index: Int) {
        _elements.insert(newElement, at: index)
    }
    
    open func insert<C: Collection>(contensOf newElements: C, at index: Int) where C.Element == Element {
        _elements.insert(contentsOf: newElements, at: index)
    }
    
    /// Safely get element
    open func get(index: Int) -> Element? {
        guard index >= 0 else { return nil }
        guard index < count else { return nil }
        return self[index]
    }
    
    open func toArray() -> Array<Element> {
        return _elements
    }
}

/**
* Elements extension Equatable.
*/
extension Elements: Equatable {
	/// Returns a Boolean value indicating whether two values are equal.
	///
	/// Equality is the inverse of inequality. For any values `a` and `b`,
	/// `a == b` implies that `a != b` is `false`.
	///
	/// - Parameters:
	///   - lhs: A value to compare.
	///   - rhs: Another value to compare.
	public static func ==(lhs: Elements, rhs: Elements) -> Bool {
		return lhs._elements == rhs._elements
	}
}

/**
* Elements RandomAccessCollection
*/
extension Elements: RandomAccessCollection {
	public subscript(position: Int) -> Element {
		return _elements[position]
	}

	public var startIndex: Int {
		return _elements.startIndex
	}

	public var endIndex: Int {
		return _elements.endIndex
	}

	/// The number of Element objects in the collection.
	/// Equivalent to `size()`
	public var count: Int {
		return _elements.count
	}
}


/**
* Elements Extension Sequence.
*/
extension Elements: Sequence {
    /// Returns an iterator over the elements of this sequence.
    public func makeIterator() -> ElementsIterator {
        return ElementsIterator(self)
    }
    
    public struct ElementsIterator: IteratorProtocol {
        /// Elements reference
        let elements: Elements
        //current element index
        var index = 0

        /// Initializer
        init(_ countdown: Elements) {
            self.elements = countdown
        }

        /// Advances to the next element and returns it, or `nil` if no next element
        mutating public func next() -> Element? {
            let result = index < elements.count ? elements[index] : nil
            index += 1
            return result
        }
    }
}
