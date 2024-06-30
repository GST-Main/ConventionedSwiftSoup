//
//  Elements.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 20/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/// A list of `Elements`.
///
/// `Elements` is a sequence that exclusively contains ``HTMLElement`` instances. This is a reference type whereas most of Swift's collection types are value types.
///
/// Typically, users do not directly instantiate this object; instead, it is often returned as the result of methods from ``HTMLElement``.
/// For example, ``HTMLElement/getElementsByClass(_:)`` returns an instance of ``Elements`` containing elements with a specified class name.
///
/// You can use Array-like members to manipulate a list of elements. This is the list of them:
/// * Use ``append(_:)``, ``append(contentsOf:)``, ``insert(_:at:)``, ``insert(contensOf:at:)`` to add new elements to `Elements`.
/// * Like `Array`, access an element in the list using the subscript. You can also use ``get(index:)`` method for safe access.
/// * To avoid out-of-bound index error, check information such as ``startIndex``, ``endIndex`` and``count``.
/// * Many other sequence methods and properties are supported: `forEach(_:)`, `map(_:)`, `first`, `reduce(_:_:)`, etc.
///
/// `Elements` has `HTMLElement` specialized methods and properties:
/// * ``text(trimAndNormaliseWhitespace:)``, ``texts``, ``html`` and ``outerHtml`` combines the list's element.
/// * You can simply check if any element meet specific conditions with "has-method"s: ``hasClass(named:)``, ``hasAttribute(key:)``, ``hasElementMatchedWithCSSQuery(_:)``, ``hasText``
/// * Filter the list using CSS queries: ``select(cssQuery:)``, ``selectNot(cssQuery:)``
open class Elements: NSCopying {
	fileprivate var _elements: [HTMLElement] = []

	/// Create an empty element list
	public init() {
	}
	/// Create an element list with given element array.
    public init<S: Sequence>(_ elements: S) where S.Element == HTMLElement {
        if let elements = elements as? Array<HTMLElement> {
            _elements = elements
        } else {
            _elements = Array(elements)
        }
	}

	public func copy(with zone: NSZone? = nil) -> Any {
		let clone = Elements()
		for element in self {
			clone.append(element.copy() as! HTMLElement)
		}
		return clone
	}

    /// Get a combined text of all elements.
    ///
    /// This method combines all elements' texts. Each element's text contains all of it's descendants' text. See ``HTMLElement/text``.
    ///
    /// - Parameter trimAndNormaliseWhitespace: Trim and normalized whitespace if it's `true`.
    /// - Returns: A combined text of all elements.
	open func text(trimAndNormaliseWhitespace: Bool = true) -> String {
		let stringBuilder: StringBuilder = StringBuilder()
		for element in self {
			if !stringBuilder.isEmpty {
				stringBuilder.append(" ")
			}
            stringBuilder.append(element.getText(trimAndNormaliseWhitespace: trimAndNormaliseWhitespace))
		}
		return stringBuilder.toString()
	}
    
    /// An Array of texts for each element.
    ///
    /// This property is an array of texts for each element that has any text.
    /// Each text includes not only the element's own text but also the text of all its descendants.
    /// See ``HTMLElement/text``.
    public var texts: [String] {
        var texts: [String] = []
        for element in self {
            if element.hasText {
                texts.append(element.text)
            }
        }
        return texts
    }

    /// A combined string of all inner HTML texts of elements.
    ///
    /// If one of the elements failed to get its HTML text, this property will be `nil`.
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

    /// A combined string of all outer HTML texts of elements.
    ///
    /// If one of the elements failed to get its outer HTML text, this property will be `nil`.
    open var outerHtml: String? {
		let stringBuilder: StringBuilder = StringBuilder()
		for element in self {
			if !stringBuilder.isEmpty {
				stringBuilder.append("\n")
			}
            if let outerHTML = element.outerHTML {
                stringBuilder.append(outerHTML)
            } else {
                return nil
            }
		}
		return stringBuilder.toString()
	}
    
    // MARK: "has" Methods
    /// Check if any of elements have an attribute with the specified key.
    open func hasAttribute(key: String) -> Bool {
        for element in self {
            if element.hasAttribute(withKey: key) {
                return true
            }
        }
        return false
    }

    /// Check if any of elements have the given class name.
    open func hasClass(named className: String) -> Bool {
        for element in self {
            if (element.hasClass(named: className)) {
                return true
            }
        }
        return false
    }

    /// A Boolean value indicating any of elements have text.
    open var hasText: Bool {
        for element in self {
            if element.hasText {
                return true
            }
        }
        return false
    }

	// MARK: CSS Filters
    /// Find matching elements with the given CSS query.
    ///
    /// This method filters the list based on the given CSS query. It only filters list elements, not retrieving matched inner elements.
    ///
    /// - Parameter cssQuery: A CSS selector to filter elements.
    /// - Returns: A new filtered list of elements.
	open func select(cssQuery: String) -> Elements {
        do {
            return try CssSelector.select(cssQuery, _elements)
        } catch {
            return Elements()
        }
	}

    /// Find elements that do Not match the given CSS query.
    ///
    /// This method filters the list based on the given CSS query, excluding matching elements.
    ///
    /// - Parameter cssQuery: A CSS selector to filter elements.
    /// - Returns: A new filtered list of elements that do not match the given CSS query.
	open func selectNot(cssQuery: String) -> Elements {
        do {
            let out = try CssSelector.select(cssQuery, _elements)
            return CssSelector.filterOut(_elements, out._elements)
        } catch {
            return self.copy() as! Elements
        }
	}

    /// Check if any of elements match the given CSS query.
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

    /// Perform a depth-first traversal on each of the selected elements.
    @discardableResult
	open func traverse(_ nodeVisitor: NodeVisitor) throws -> Elements {
		let traversor: NodeTraversor = NodeTraversor(nodeVisitor)
		for element in self {
			try traversor.traverse(element)
		}
		return self
	}

    /// Get an filtered array whose element is ``FormElement``.
	open func forms() -> [FormElement] {
		var forms: Array<FormElement> = Array<FormElement>()
		for element in self {
			if let element = element as? FormElement {
				forms.append(element)
			}
		}
		return forms
	}
    
    /// Adds a new element at the end of the list.
    ///
    /// Use this method to append a single element to the end of a list.
    ///
    /// - Parameter newElement: The element to append to the list.
    /// - Complexity: O(1) on average, over many calls to `append(_:)` on the
    ///   same list.
    open func append(_ newElement: HTMLElement) {
        _elements.append(newElement)
    }
    
    /// Adds the elements of a sequence to the end of the list.
    ///
    /// Use this method to append the elements of a sequence to the end of this
    /// array. This example appends the elements of a `Range<Int>` instance
    /// to an array of integers.
    ///
    /// ```swift
    /// let elements = Elements()
    /// let divs = document.getElementsByTag("div")
    /// let spans = document.getElementsByTag("span")
    /// elements.append(contentsOf: divs)
    /// elements.append(contentsOf: spans)
    /// ```
    ///
    /// - Parameter newElements: The elements to append to the list.
    ///
    /// - Complexity: O(*m*) on average, where *m* is the length of
    ///   `newElements`, over many calls to `append(contentsOf:)` on the same
    ///   list.
    open func append<S: Sequence>(contentsOf newElements: S) where S.Element == HTMLElement {
        _elements.append(contentsOf: newElements)
    }
    
    /// Inserts a new element at the specified position.
    ///
    /// The new element is inserted before the element currently at the specified
    /// index. If you pass the array's `endIndex` property as the `index`
    /// parameter, the new element is appended to the list.
    /// ```swift
    /// let elements = document.getElementsByTag("div")
    /// let contents = document.getElementById("main-contents")!
    /// let extra = document.getElementById("extra-contents")!
    ///
    /// elements.insert(contents, at: 3)
    /// elements.insert(contents, at: elements.endIndex)
    /// ```
    ///
    /// - Parameter newElement: The new element to insert into the list.
    /// - Parameter index: The position at which to insert the new element.
    ///   `index` must be a valid index of the list or equal to its `endIndex`
    ///   property.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the list. If
    ///   `index == endIndex`, this method is equivalent to `append(_:)`.
    open func insert(_ newElement: HTMLElement, at index: Int) {
        _elements.insert(newElement, at: index)
    }
    
    /// Inserts the elements of a sequence into the collection at the specified
    /// position.
    ///
    /// The new elements are inserted before the element currently at the
    /// specified index. If you pass the collection's `endIndex` property as the
    /// `index` parameter, the new elements are appended to the collection.
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameter newElements: The new elements to insert into the collection.
    /// - Parameter index: The position at which to insert the new elements. `index`
    ///   must be a valid index of the collection.
    ///
    /// - Complexity: O(*n* + *m*), where *n* is length of this collection and
    ///   *m* is the length of `newElements`. If `i == endIndex`, this method
    ///   is equivalent to `append(contentsOf:)`.
    open func insert<C: Collection>(contensOf newElements: C, at index: Int) where C.Element == HTMLElement {
        _elements.insert(contentsOf: newElements, at: index)
    }
    
    /// Safely get an element at the specified position.
    ///
    /// Unlike using the subscript of a sequence, this method does not cause any runtime error.
    /// even if the given index is out of bounds.
    /// Instead, it returns `nil` to provide a safe and convenient way to hande such situations.
    ///
    /// - Parameter index: The position of an element to get.
    /// - Returns: An element at the given index if exists, otherwise returns `nil`
    open func get(index: Int) -> HTMLElement? {
        guard index >= 0 else { return nil }
        guard index < count else { return nil }
        return self[index]
    }
    
    /// Get an Array of contents.
    open func toArray() -> [HTMLElement] {
        return _elements
    }
}

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

extension Elements: RandomAccessCollection {
	public subscript(position: Int) -> HTMLElement {
		return _elements[position]
	}

    /// The position of the first element in a nonempty list.
    ///
    /// For an instance of `HTMLElement`, `startIndex` is always zero. If the list
    /// is empty, `startIndex` is equal to `endIndex`.
	public var startIndex: Int {
		return _elements.startIndex
	}

    /// The list's "past the end" position---that is, the position one greater
    /// than the last valid subscript argument.
    ///
    /// If the list is empty, `endIndex` is equal to `startIndex`.
	public var endIndex: Int {
		return _elements.endIndex
	}

    /// The number of elements in the list.
	public var count: Int {
		return _elements.count
	}
}


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
        mutating public func next() -> HTMLElement? {
            let result = index < elements.count ? elements[index] : nil
            index += 1
            return result
        }
    }
}
