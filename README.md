<p align="center" >
  <img src="https://raw.githubusercontent.com/scinfu/SwiftSoup/master/swiftsoup.png" alt="SwiftSoup" title="SwiftSoup">
</p>

[//]: # (Add link to changelog)
![Static Badge](https://img.shields.io/badge/latest-0.1.0-blue)
![Platform OS X | iOS | tvOS | watchOS | Linux](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-orange.svg)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)
![🐧 linux: ready](https://img.shields.io/badge/%F0%9F%90%A7%20linux-ready-red.svg)
[![License](https://img.shields.io/cocoapods/l/SwiftSoup.svg?style=flat)](http://cocoapods.org/pods/SwiftSoup)

`PrettySwiftSoup` is a convention-compliant version of [`SwiftSoup`](https://github.com/scinfu/SwiftSoup).

[`SwiftSoup`](https://github.com/scinfu/SwiftSoup) is a **Swift** library used for parsing and manipulating HTML documents. [`SwiftSoup`](https://github.com/scinfu/SwiftSoup) allows developers to extract data from HTML, manipulate the Document Object Model (DOM), and handle character encodings, making it useful for tasks like web scraping and HTML parsing in **Swift** applications.

By inheriting [`SwiftSoup`](https://github.com/scinfu/SwiftSoup), `PrettySwiftSoup` improves the object naming conventions to align with **Swift** standards.
`PrettySwiftSoup` provides renamed objects, appropriate argument labels for methods, and built-in documentation to ensure continuity with the familiar **Swift** development style.

> [!WARNING]  
> Object symbols may continue to change until version `1.0.0` is released. Please pay attention to dependency version management.

# Swift Package Manager
`PrettySwiftSoup` is available through [Swift Package Manager](https://github.com/apple/swift-package-manager). 
To install it, simply add the dependency to your Package.Swift file:

```swift
...
dependencies: [
    .package(url: "https://github.com/GST/PrettySwiftSoup.git", from: "0.1.0"),
],
targets: [
    .target( name: "YourTarget", dependencies: ["PrettySwiftSoup"]),
]
...
```

# Comparison to `SwiftSoup`
See [**Full List of Changes**](https://github.com/GST-Main/ConventionedSwiftSoup/blob/master/Changes.md)

# Version Correspondence
| `PrettySwiftSoup` | `SwiftSoup` |
|:-----------------:|:-----------:|
|       `0.1.0`     |   `2.7.2`   |

# Example
## Get elements from HTML
```swift
let html =
"""
<html>
<body>

<h1>My First Heading</h1>

<p>My first paragraph.</p>

</body>
</html>
"""

guard let document: HTMLDocument = HTMLParser.parse(html) else {
    fatalError("Failed to parse HTML document")
}
let headingElements: HTMLElements = document.getElementsByTag(named: "h1")
let element: HTMLElement? = headingElements.first
let textInElement: String = element!.text
print(textInElement)
// Prints "My First Heading"
```
1. `HTMLDocument` is a subclass of `HTMLElement` which includes entire elements tree in an HTML document. Use the `HTMLParser.parse(_:)` method to get an `HTMLDocument`
2. `HTMLDocument` is the root node of the elements tree. To find elements with a specific tag name in an HTML tree, use `HTMLElement`'s method `getElementsByTag(named:)`. You can also use these methods to get specific elements:
    * `getElementByID(_:)`
    * `getElementsByAttribute(named:)`
    * `getElementsByClass(named:)`
    * and more methods like these...
3. You retrieve a list of elements of type `HTMLElements`. `HTMLElements` is a reference type that contains `HTMLElement` objects. You can handle this type like a built-in `Array` in Swift. In this example, I used `first` optional property to get the first element.
4. `HTMLElement` contains data of an HTML element, such as text, attribute, clas snames, etc. I tried to print the element's text, and it is printed successfully.

## Play with `HTMLElement`
Let's assume `html` is a `String` variable with this HTML code:
```html
<div id="main" class="container" role="main-container" data-version="0.1.0">
    <header class="header main-header">
        <h1>Welcome to the Example Page</h1>
    </header>
    <nav class="navbar" id="navBar" role="navigation">
        <ul class="nav-list">
            <li class="nav-item"><a href="/section1">Section 1</a></li>
            <li class="nav-item"><a href="/section2">Section 2</a></li>
        </ul>
    </nav>
    <footer class="footer">
        <p>Footer information</p>
    </footer>
    <script>console.log('Hello, world!');</script>
</div>
```

`HTMLElement` contains information about an HTML element as a node in the the tree:
```swift
guard let document = HTMLParser.parse(html, baseURI: "http://example.com/") else {
    fatalError("Failed to parse")
}

if let mainElement = document.getElementById("main") {
    let className: String? = mainElement.className // Optional("container")
    let classNames: OrderedSet<String> = mainElement.classNames // ["container"]
    let tagName: String = mainElement.tagName // "div"
    let normalizedTagName: String = mainElement.tagNameNormal // "div"
    let role: String? = mainElement.getAttribute(withKey: "role") // Optional("main-container")
    let style: String? = mainElement.getAttribute(withKey: "style") // nil
    let nonTextContent: String? = mainElement.nonTextContent // Optional("console.log('Hello, world!');")
    let datas: [String:String] = mainElement.datas // ["version":"0.1.0"]
    let selector: String = mainElement.cssSelector // "#container"
    
    // Get the first child (the <header> element)
    guard let firstChild: HTMLElement = mainElement.firstChild else {
        return
    }
    let className2 = firstChild.className // Optional("header main-header")
    let classNames2 = firstChild.classNames // ["header", "main-header"]
    let text: String = firstChild.text // "Welcome to the Example Page"
    let ownText: String = firstChild.ownText // ""
    
    // Get the second child (the <nav> element)
    guard let secondChild: HTMLElement = mainElement.getChild(at: 1) else {
        return
    }
    let id: String? = secondChild.id // Optional("navBar")
    
    // Get the third child (the <footer> element) which is the next sibling
    guard let thirdChild: HTMLElement = secondChild.nextSiblingElement else {
        return
    }
    let tagName2: String = thirdChild.tagName // "footer"
    
    let elementWithHref = mainElement
        .getElementById("navBar")?
        .firstChild?
        .getElementsByTag(named: "a")
        .first
    if let elementWithHref {
        let urlPath: String? = elementWithHref.absoluteURLPath(ofAttribute: "href") // Optional("http://example.com/section1")
    }
}
```
### Points of interests
* Specify the `baseURI:` argument in `HTMLParser.parse(_:baseURI:)` to set the base URI of all elements in the document.
* Get elements by calling `getElementByID(:)`, `getElementsByTag(named:)`, `getElementsByClass(named:)`, etc. These methods search all descendants of the element including itself. You can also use `select(cssQuery:)` to find elements using a CSS selector.
* Use `HTMLElement`'s properties and methods to get corresponding properties of an HTML element, such as `className`, `tagName`, `getAttribute(withKey:)`, etc.
    * The `nonTextContent` property represents an elements non-textual contents, like `<script>`, `<style>`, etc. This includes all non-textual content of the element's descendants.
    * The `text` property includes not only the element's own text but also the text of its descendants.
* Access relative elements using `firstChild`, `getChild(at:)`, `nextSiblingElement`, `parent`, etc.

## Modifying Contents
```swift
guard let document = HTMLParser.parse(html, baseURI: "http://example.com/") else {
    fatalError("Failed to parse")
}

let heading = document.getElementsByTag(named: "h1").first!
try! heading.setText("Welcome to Silent Hill")
    .setTagName("h2")
    .setAttribute(withKey: "foo", value: "bar")

let list = document.getElementById("navBar")!.firstChild!
try! list.appendElement(tagName: "li")
    .setClass(names: ["nav-item", "customized"])
    .appendElement(tagName: "a")
    .setAttribute(withKey: "href", value: "/section3")
    .setText("Section 1")

do {
    let newElement = HTMLElement(tag: .init("h3"), baseURI: document.baseURI ?? "")
    newElement.setText("Hello, world!")
        .setClass(names: ["created"])
    
    try heading.insertHTMLAsNextSibling("<br>Bruh")
        .insertNodeAsNextSibling(newElement)
} catch let error as SwiftSoupError {
    if error == .failedToParseHTML {
        print("Invalid HTML")
    } else {
        print("SwiftSoup error: \(error.localizedDescription)")
    }
} catch {
    print("Unknown error: \(error.localizedDescription)")
}

let footer = document.getElementsByTag(named: "footer").first!
footer.remove()
```
### Points of interests
* Use setter methods to set properties of an HTML element.
* Almost all setters returns `self` so that you can chain the setter methods.
* To add a new element, use `appendElement(tagName:)`, `insertHTMLAsNextSibling(_:)`, `insertNodeAsNextSibling(_:)`, etc.
    * `appendElement(tagName:)` allows you to add new element with a tag name. The new element is inserted as the last child of the caller. You can then set several properties of the element.
    * `insertHTMLAsNextSibling(_:)` allows you to add a new element by parsing the given HTML code. The new element is inserted as the following sibling of the caller.
    * `insertNodeAsNextSibling(_:)` allows you to add an instance of `HTMLElement`.
    * There are more methods like these, and they return `self` for method chaining.
* Call `remove()` to remove an element. This removes an element from the HTML tree but does not deinitialize the object or free the memory.
* Note that setting and adding methods throw errors. For example, if you try to set an empty tag, it throws `SwiftSoupError.emptyTagName`. Possible errors for each method are described in the built-in documentation.




## Sanitize untrusted HTML (to prevent XSS)
### Problem
You want to allow untrusted users to supply HTML for output on your website (e.g. as comment submission). You need to clean this HTML to avoid [cross-site scripting](https://en.wikipedia.org/wiki/Cross-site_scripting) (XSS) attacks.
### Solution
Use the HTML `Cleaner` with a configuration specified by a `Whitelist`.

```swift
do {
    let unsafe: String = "<p><a href='http://example.com/' onclick='stealCookies()'>Link</a></p>"
    let safe: String = try HTMLParser.cleanBodyFragment(unsafe, whitelist: Whitelist.basic())
    // now: <p><a href="http://example.com/" rel="nofollow">Link</a></p>
} catch let error as SwiftSoupError {
    print(error.localizedDescription)
} catch {
    print("Unknown Error: \(error.localizedDescription)")
}
```

If you supply a whole HTML document, with a `<head>` tag, the `cleanBodyFragment(_:baseURI:whitelist:)` method will just return the cleaned body HTML.
You can clean both `<head>` and `<body>` by providing a `Whitelist` for each tags.

```swift
do {
    let unsafe: String = 
    """
    <html>
        <head>
            <title>Hey</title>
            <script>console.log('hi');</script>
        </head>
        <body>
            <p>Hello, world!</p>
        </body>
    </html>
    """
    
    var headWhitelist: Whitelist = {
        do {
            let customWhitelist = Whitelist.none()
            try customWhitelist
                .addTags("meta", "style", "title")
            return customWhitelist
        } catch {
            fatalError("Couldn't init head whitelist")
        }
    }()
    
    guard let unsafeDocument = HTMLParser.parse(unsafe) else { return }
    let safe: String? = try Cleaner(headWhitelist: headWhitelist, bodyWhitelist: .relaxed())
        .clean(unsafeDocument)
        .html
    // now: <html><head><title>Hey</title></head><body><p>Hello, world!</p></body></html>
} catch let error as SwiftSoupError {
    print(error.localizedDescription)
} catch {
    print("Unknown Error: \(error.localizedDescription)")
}
```

### Discussion
A cross-site scripting attack against your site can really ruin your day, not to mention your users'. Many sites avoid XSS attacks by not allowing HTML in user submitted content: they enforce plain text only, or use an alternative markup syntax like wiki-text or Markdown. These are seldom optimal solutions for the user, as they lower expressiveness, and force the user to learn a new syntax.

A better solution may be to use a rich text WYSIWYG editor (like [CKEditor](http://ckeditor.com) or [TinyMCE](https://www.tinymce.com)). These output HTML, and allow the user to work visually. However, their validation is done on the client side: you need to apply a server-side validation to clean up the input and ensure the HTML is safe to place on your site. Otherwise, an attacker can avoid the client-side Javascript validation and inject unsafe HMTL directly into your site

The SwiftSoup whitelist sanitizer works by parsing the input HTML (in a safe, sand-boxed environment), and then iterating through the parse tree and only allowing known-safe tags and attributes (and values) through into the cleaned output.

It does not use regular expressions, which are inappropriate for this task.

SwiftSoup provides a range of `Whitelist` configurations to suit most requirements; they can be modified if necessary, but take care.

The cleaner is useful not only for avoiding XSS, but also in limiting the range of elements the user can provide: you may be OK with textual `a`, `strong` elements, but not structural `div` or `table` elements.