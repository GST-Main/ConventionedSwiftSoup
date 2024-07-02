# Removed Symbols
## Global Methods
All global methods are moved into parser classes:
```swift
// Old way
let document = parse(htmlToParse, uri)

// New way
let document = HTMLParser.parse(htmlToParse, baseURI: uri)
```

|           Symbol          |            Note            |
|:-------------------------:|:--------------------------:|
| parse(\_:\_:\_:)          | Use `HTMLParser.parse(_:baseURI:)` instead |
| parseBodyFragment(\_:\_:) | Use `HTMLParser.parseBodyFragment(_:baseURI:)` instead |
| clean(\_:\_:\_:\_:)       | Use  `HTMLParser.cleanBodyFragment(_:baseURI:whitelist:settings:)` instead |
| isValid(\_:\_:)           | Use `validateBodyFragment(_:whitelist:)` instead |

## In `Node`
| Symbol | Note |
|:------:|:----------:|
| childNodeSize | Use `childNodes.count` instead |
| childNode(_:) | Use subscript instead |

## In `HTMLElements`
`HTMLElements` conforms to `RandomAccessCollection`, so most of the previously defined iteration utility methods have been removed. These methods were redundant and unclear because the Swift's built-in sequence iteration methods are sufficient to replace their usage. Use the Swift built-in sequence iteration methods instead:
```swift
// Add a class name to all elements
// Old way
let elements = document.getElementsByTag("h2")
try! elements.addClass("subheader")

// New way
let elements = document.getElementsByTag(named: "h2")
elements.forEach { $0.addClass(named: "subheader") }
```

To find a specific value in list, do like this:

```swift
// Get a value of the first "style" attribute in an element list if exists
// Old way
let elements = document.getElementsByClass("cls")
let firstStyle = try? elements.attr("style")

// New way
let elements = document.getElementsByClass(named: "cls")
let firstStyle = elements
    .first(where: { $0.hasAttribute(withKey: "style") } )?
    .getAttribute(withKey: "style")
// Alternative way
let firstStyle = element.reduce(nil) { $0 ?? $1.getAttribute(withKey: "style") }
```
|      Symbol     |           Note           |
|:---------------:|:------------------------:|
| attr(_:)        |                          |
| attr(\_:\_:)    |                          |
| removeAttr(_:)  |                          |
| addClass(_:)    |                          |
| removeClass(_:) |                          |
| toggleClass(_:) |                          |
| val()           |                          |
| val(_:)         |                          |
| toString()      | same as `outerHTML`      |
| tagName(_:)     |                          |
| html(_:)        |                          |
| prepend(_:)     |                          |
| append(_:)      |                          |
| before(_:)      |                          |
| after(_:)       |                          |
| wrap(_:)        |                          |
| unwrap(_:)      |                          |
| empty()         |                          |
| remove()        |                          |
| eq(_:)          |                          |
| parents()       |                          |
| first()         | `first` already exists   |
| isEmpty()       | `isEmpty` already exists |
| size()          | `count` already exists   |
| last()          | `last` already exists    |

## In `HTMLDocument`

|      Symbol     |        Note       |
|:---------------:|:----------------------:|
| updateMetaCharset | It's removed and not checked. |
| updateMetaCharsetElement()   | Now, the value indicated by this method is always treated as `true`. |
| updateMetaCharsetElement(_:) | Now, the value set by this method is always treated as `true`. |

# Renamed Types

Some types are renamed to clarify the roles of objects and to avoid symbol duplication.

| `SwiftSoup` | `PrettySwiftSoup` |           Note           |
|-------------|-------------------|:------------------------:|
|    Parser   |    MarkupParser   |        Base class        |
|             |     HTMLParser    | Inherited `MarkupParser` |
|             |     XMLParser     | Inherited `MarkupParser` |
|   Document  |    HTMLDocument   |                          |
|   Element   |    HTMLElement    |                          |
|   Elements  |    HTMLElements   |                          |
|  Exception  |   SwiftSoupError  |    `enum` -> `struct`    |

# Renamed Methods and Properties
In `Node`, `HTMLElement`, `HTMLElements` and `HTMLDocument`, many getter and setter method is replaced with property.

Some methods have been modified to avoid redundantly throwing errors. Instead, they return an empty list or `nil` if the specific value cannot be found.

## In `Node`
|         `SwiftSoup`         |          `PrettySwiftSoup`         | Propertyized | Error Removed |
|-----------------------------|------------------------------------|:-:|:-:|
| parent()                    | parent                             | ✅ | |
| getParentNode()             | parentNode                         | ✅ | |
| setParentNode(_:)           | parentNode                         | ✅ | |
| getChildNodes()             | childNodes                         | ✅ | |
| childNodesAsArray()         | childNodes                         |    | |
| addChildren(_:) throws      | appendChildren(_:)                 |   | ✅ |
| addChildren(\_:\_:)         | insertChildren(_:at:)              |   | |
| reparentChild(_:) throws    | reparentChild(_:)                  |   | ✅ |
| setSiblingIndex(_:)         | siblingIndex                       | ✅ | |
| siblingNodes()              | siblingNodes                       | ✅ | |
| nextSibling()               | nextSibling                        | ✅ | |
| previousSibling()           | previousSibling                    | ✅ | |
| getBaseUri()                | baseURI                            | ✅ | |
| setBaseUri(_:)              | baseURI                            | ✅ | |
| remove() throws             | remove()                           |   | ✅ |
| before(_:)                  | insertHTMLAsPreviousSibling(_:)    |   | |
| before(_:)                  | insertNodeAsPreviousSibling(_:)    |   | |
| after(_:)                   | insertHTMLAsNextSibling(_:)        |   | |
| after(_:)                   | insertNodeAsNextSibling(_:)        |   | |
| addSiblingHtml(index:_:)    | insertSiblingHTML(_:at:)           |   | |
| wrap(_:) throws -> Node?    | wrap(html:) throws -> Node         |   | |
| unwrap() throws -> Node?    | unwrap() throws -> Node            | ✅ | |
| outerHtml() throws          | outerHTML                          | ✅ | ✅ |
| replaceWith(_:) throws      | replace(with:)                     |   | ✅ |
| replaceChild(\_:\_:)        | replaceChildNode(_:with:)          |   | |
| getDeepChild(el:)           | getDeepChild(element:)             |   | |
| hasSameValue(_:) throws     | hasSameValue(_:)                   |   | ✅ |
| attr(_:) throws -> String   | getAttribute(withKey:) -> String?  |   | ✅ |
| attr(\_:\_:)                | setAttribute(withKey:value:)    |   | |
| hasAttr(_:)                 | hasAttribute(withKey:)             |   | |
| removeAttr(_:)              | removeAttribute(wihtKey:)          |   | |
| absUrl(_:) throws -> String | absoluteURLPath(ofAttribute:) -> String? |  | ✅ |
| nodeName()                  | nodeName                           | ✅ | |

## In `HTMLElement`
|           `SwiftSoup`           |         `PrettySwiftSoup`       | Propertyized | Error Removed |
|---------------------------------|---------------------------------|:--:|:--:|
| tag()                           | tag                             | ✅ |    |
| tagName()                       | tagName                         | ✅ |    |
| tagNameNormal()                 | tagNameNormal                   | ✅ |    |
| isBlock()                       | isBlock                         | ✅ |    |
| id()                            | id                              | ✅ |    |
| dataset()                       | nonTextContent                  | ✅ |    |
| parents()                       | ancestors                       | ✅ |    |
| child(_:)                       | getChild(at:)                   |    |    |
| children()                      | children                        | ✅ |    |
|                                 | firstChild                      | ✅ |    |
| textNodes()                     | textNodes                       | ✅ |    |
| dataNodes()                     | dataNodes                       | ✅ |    |
| iS(_:) throws                   | isMatchedWith(cssQuery:)        |    | ✅ |
| iS(_:) throws                   | isMatchedWith(evaluator:)       |    | ✅ |
| appendChild(_:) throws          | appendChild(_:)                 |    | ✅ |
| prependChild(_:) throws         | prependChild(_:)                |    | ✅ |
| insertChildren(\_:\_:)          | insertChildrenElements(_:at:)   |    |    |
| appendElement(_:)               | appendElement(tagName:)         |    |    |
| prependElement(_:)              | prependElement(_:)              |    |    |
| appendText(_:) throws           | appendText(_:)                  |    | ✅ |
| prependText(_:) throws          | prependText(_:)                 |    | ✅ |
| append(_:)                      | appendHTML(_:)                  |    |    |
| prepend(_:)                     | prependHTML(_:)                 |    |    |
| empty()                         | removeChildren()                |    |    |
| cssSelector() throws            | cssSelector                     | ✅ | ✅ |
| siblingElements()               | siblingelements                 | ✅ |    |
| nextElementSibling() throws     | nextSiblingElement              | ✅ | ✅ |
| previousElementSibling() throws | previousSiblingElement          | ✅ | ✅ |
| firstElementSibling()           | firstSiblingElement             | ✅ | ✅ |
| lastElementSibling()            | lastSiblingElement              | ✅ | ✅ |
| elementSiblingIndex() throws    | elementSiblingIndex             | ✅ | ✅ |
| getElementsByTag(_:) throws [^1]| getElementsByTag(named:)|   | ✅ |
| text(trimAndNormaliseWhitespace:) throws  | getText(trimAndNormaliseWhitespace:) |    | ✅ |
| text(trimAndNormaliseWhitespace:) throws  | text                  | ✅ | ✅ |
| ownText()                       | ownText                         | ✅ |    |
| text(_:)                        | setText(_:)                     |    |    |
| hasText()                       | hasText                         | ✅ |    |
| data()                          | data                            |    |    |
| className() throws              | className                       | ✅ | ✅ |
| classNames() throws             | classNames                      | ✅ | ✅ |
| classNames(_:) throws           | setClass(names:)                |    | ✅ |
| hasClass(_:)                    | hasClass(named:)                |    |    |
| addClass(_:) throws             | addClass(named:)                |    | ✅ |
| removeClass(_:) throws          | removeClass(named:)             |    | ✅ |
| toggleClass(_:) throws          | toggleClass(named:)             |    | ✅ |
| val() throws                    | value                           | ✅ | ✅ |
| val(_:) throws                  | setValue(_:)                    |    | ✅ |
| html() throws                   | html                            | ✅ | ✅ |
| html(_:)                        | setHTML(_:)                     |    |    |

[^1]: All `getElementsBySth` methods are updated like this.

## In `HTMLElements`
|          `SwiftSoup`          |         `PrettySwiftSoup        | Propertyized | Error Removed |
|-------------------------------|---------------------------------|:--:|:--:|
| init(_:)                      | init(_:)                        |    |    |
| hasAttr(_:)                   | hasAttribute(withKey:)          |    |    |
| hasClass(_:)                  | hasClass(named:)                |    |    |
| hasText()                     | hasText                         |    |    |
| text(trimAndNormaliseWhitespace:) throws | text(trimAndNormaliseWhitespace:) |    | ✅ |
| eachText() throws             | texts                           | ✅ | ✅ |
| html() throws                 | html                            | ✅ | ✅ |
| outerHTML() throws            | outerHTML                       | ✅ | ✅ |
| select(_:) throws             | select(cssQuery:)               |    | ✅ |
| not(_:) throws                | selectNot(cssQuery:)            |    | ✅ |
| iS(_:) throws                 | hasElementMatchWithCSSQuery(_:) | ✅ |    |
| add(_:)                       | append(_:)                      |    |    |
|                               | append(contentsOf:)             |    |    |
| add(\_:\_:)                   | insert(_:at:)                   |    |    |
|                               | insert(contentsOf:at:)          |    |    |
| get(_:)                       | getElement(at:)                 |    |    |
| array()                       | toArray()                       |    |    |

## In `HTMLDocument`
|      `SwiftSoup`      |    `PrettySwiftSoup   | Propertyized | Error Removed |
|-----------------------|-----------------------|:--:|:--:|
| outputSettings()      | outputSettings        | ✅ |    |
| outputSettings(_:)    | outputSettings        | ✅ |    |
| location()            | location              | ✅ |    |
| init(_:)              | init(baseURI:)        |    |    |
| createShell(_:)       | createShell(baseURI:) |    |    |
| head()                | head                  | ✅ |    |
| body()                | body                  | ✅ |    |
| title() throws        | title                 | ✅ | ✅ |
| createElement(_:)     | createElement(withTagName:)|    |    |
| charset(_:) throws    | charset               | ✅ | ✅ |
| charset()             | charset               | ✅ |    |
