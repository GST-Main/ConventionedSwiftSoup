//
//  ElementTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 06/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//

import XCTest
@testable import PrettySwiftSoup
class ElementTest: XCTestCase {

	private let reference = "<div id=div1><p>Hello</p><p>Another <b>element</b></p><div id=div2><img src=foo.png></div></div>"

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testGetElementsByTagName() {
		let doc: HTMLDocument = HTMLParser.parse(reference)!
		let divs = doc.getElementsByTag("div")
		XCTAssertEqual(2, divs.count)
		XCTAssertEqual("div1", divs.get(index: 0)!.id)
		XCTAssertEqual("div2", divs.get(index: 1)!.id)

		let ps = doc.getElementsByTag("p")
		XCTAssertEqual(2, ps.count)
		XCTAssertEqual("Hello", (ps.get(index: 0)!.childNode(0) as! TextNode).getWholeText())
		XCTAssertEqual("Another ", (ps.get(index: 1)!.childNode(0) as! TextNode).getWholeText())
		let ps2 = doc.getElementsByTag("P")
		XCTAssertEqual(ps, ps2)

		let imgs = doc.getElementsByTag("img")
		XCTAssertEqual("foo.png", imgs.get(index: 0)!.getAttribute(withKey: "src"))

		let empty = doc.getElementsByTag("wtf")
		XCTAssertEqual(0, empty.count)
	}

	func testGetNamespacedElementsByTag() {
		let doc: HTMLDocument = HTMLParser.parse("<div><abc:def id=1>Hello</abc:def></div>")!
		let els: Elements = doc.getElementsByTag("abc:def")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("1", els.first?.id)
		XCTAssertEqual("abc:def", els.first?.tagName)
	}

	func testGetElementById() {
		let doc: HTMLDocument = HTMLParser.parse(reference)!
		let div: HTMLElement = doc.getElementById("div1")!
		XCTAssertEqual("div1", div.id)
		XCTAssertNil(doc.getElementById("none"))

		let doc2: HTMLDocument = HTMLParser.parse("<div id=1><div id=2><p>Hello <span id=2>world!</span></p></div></div>")!
		let div2: HTMLElement = doc2.getElementById("2")!
		XCTAssertEqual("div", div2.tagName) // not the span
		let span: HTMLElement = div2.getChild(at: 0)!.getElementById("2")! // called from <p> context should be span
		XCTAssertEqual("span", span.tagName)
	}

	func testGetText() {
		let doc: HTMLDocument = HTMLParser.parse(reference)!
		XCTAssertEqual("Hello Another element", doc.getText())
		XCTAssertEqual("Another element", doc.getElementsByTag("p").get(index: 1)!.getText())
	}

	func testGetChildText() {
		let doc: HTMLDocument = HTMLParser.parse("<p>Hello <b>there</b> now")!
		let p: HTMLElement = doc.select(cssQuery: "p").first!
		XCTAssertEqual("Hello there now", p.getText())
		XCTAssertEqual("Hello now", p.ownText)
	}

	func testNormalisesText() {
		let h: String = "<p>Hello<p>There.</p> \n <p>Here <b>is</b> \n s<b>om</b>e text."
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let text: String = doc.getText()
		XCTAssertEqual("Hello There. Here is some text.", text)
	}

	func testKeepsPreText() {
		let h = "<p>Hello \n \n there.</p> <div><pre>  What's \n\n  that?</pre>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		XCTAssertEqual("Hello there.   What's \n\n  that?", doc.getText())
	}

	func testKeepsPreTextInCode() {
		let h = "<pre><code>code\n\ncode</code></pre>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		XCTAssertEqual("code\n\ncode", doc.getText())
		XCTAssertEqual("<pre><code>code\n\ncode</code></pre>", doc.body?.html)
	}

	func testBrHasSpace() {
		var doc: HTMLDocument = HTMLParser.parse("<p>Hello<br>there</p>")!
		XCTAssertEqual("Hello there", doc.getText())
		XCTAssertEqual("Hello there", doc.select(cssQuery: "p").first?.ownText)

		doc = HTMLParser.parse("<p>Hello <br> there</p>")!
		XCTAssertEqual("Hello there", doc.getText())
	}

	func testGetSiblings() {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello<p id=1>there<p>this<p>is<p>an<p id=last>element</div>")!
		let p: HTMLElement = doc.getElementById("1")!
		XCTAssertEqual("there", p.getText())
		XCTAssertEqual("Hello", p.previousSiblingElement?.getText())
		XCTAssertEqual("this", p.nextSiblingElement?.getText())
		XCTAssertEqual("Hello", p.firstSiblingElement?.getText())
        XCTAssertEqual("element", p.lastSiblingElement?.getText())
	}

	func testGetSiblingsWithDuplicateContent() {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello<p id=1>there<p>this<p>this<p>is<p>an<p id=last>element</div>")!
		let p: HTMLElement = doc.getElementById("1")!
		XCTAssertEqual("there", p.getText())
		XCTAssertEqual("Hello", p.previousSiblingElement?.getText())
		XCTAssertEqual("this", p.nextSiblingElement?.getText())
		XCTAssertEqual("this", p.nextSiblingElement?.nextSiblingElement?.getText())
		XCTAssertEqual("is", p.nextSiblingElement?.nextSiblingElement?.nextSiblingElement?.getText())
		XCTAssertEqual("Hello", p.firstSiblingElement?.getText())
		XCTAssertEqual("element", p.lastSiblingElement?.getText())
	}

	func testGetAncestors() {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello <span>there</span></div>")!
		let span: HTMLElement = doc.select(cssQuery: "span").first!
		let parents: Elements = span.ancestors

		XCTAssertEqual(4, parents.count)
		XCTAssertEqual("p", parents.get(index: 0)!.tagName)
		XCTAssertEqual("div", parents.get(index: 1)!.tagName)
		XCTAssertEqual("body", parents.get(index: 2)!.tagName)
		XCTAssertEqual("html", parents.get(index: 3)!.tagName)
	}

	func testElementSiblingIndex() {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One</p>...<p>Two</p>...<p>Three</p>")!
		let ps: Elements = doc.select(cssQuery: "p")
		XCTAssertTrue(0 == ps.get(index: 0)!.elementSiblingIndex)
		XCTAssertTrue(1 == ps.get(index: 1)!.elementSiblingIndex)
		XCTAssertTrue(2 == ps.get(index: 2)!.elementSiblingIndex)
	}

	func testElementSiblingIndexSameContent() {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One</p>...<p>One</p>...<p>One</p>")!
		let ps: Elements = doc.select(cssQuery: "p")
		XCTAssertTrue(0 == ps.get(index: 0)!.elementSiblingIndex)
		XCTAssertTrue(1 == ps.get(index: 1)!.elementSiblingIndex)
		XCTAssertTrue(2 == ps.get(index: 2)!.elementSiblingIndex)
	}

	func testGetElementsWithClass() {
		let doc: HTMLDocument = HTMLParser.parse("<div class='mellow yellow'><span class=mellow>Hello <b class='yellow'>Yellow!</b></span><p>Empty</p></div>")!

		let els = doc.getElementsByClass("mellow")
		XCTAssertEqual(2, els.count)
		XCTAssertEqual("div", els.get(index: 0)!.tagName)
		XCTAssertEqual("span", els.get(index: 1)!.tagName)

		let els2 = doc.getElementsByClass("yellow")
		XCTAssertEqual(2, els2.count)
		XCTAssertEqual("div", els2.get(index: 0)!.tagName)
		XCTAssertEqual("b", els2.get(index: 1)!.tagName)

		let none = doc.getElementsByClass("solo")
		XCTAssertEqual(0, none.count)
	}

	func testGetElementsWithAttribute() {
		let doc: HTMLDocument = HTMLParser.parse("<div style='bold'><p title=qux><p><b style></b></p></div>")!
		let els = doc.getElementsByAttribute(key: "style")
		XCTAssertEqual(2, els.count)
		XCTAssertEqual("div", els.get(index: 0)!.tagName)
		XCTAssertEqual("b", els.get(index: 1)!.tagName)

		let none = doc.getElementsByAttribute(key: "class")
		XCTAssertEqual(0, none.count)
	}

	func testGetElementsWithAttributeDash() {
		let doc: HTMLDocument = HTMLParser.parse("<meta http-equiv=content-type value=utf8 id=1> <meta name=foo content=bar id=2> <div http-equiv=content-type value=utf8 id=3>")!
		let meta: Elements = doc.select(cssQuery: "meta[http-equiv=content-type], meta[charset]")
		XCTAssertEqual(1, meta.count)
		XCTAssertEqual("1", meta.first!.id)
	}

	func testGetElementsWithAttributeValue() {
		let doc = HTMLParser.parse("<div style='bold'><p><p><b style></b></p></div>")!
		let els: Elements = doc.getElementsByAttribute(key: "style", value: "bold")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("div", els.get(index: 0)!.tagName)

        let none: Elements = doc.getElementsByAttribute(key: "style", value: "none")
		XCTAssertEqual(0, none.count)
	}

	func testClassDomMethods() {
		let doc: HTMLDocument = HTMLParser.parse("<div><span class=' mellow yellow '>Hello <b>Yellow</b></span></div>")!
		let els: Elements = doc.getElementsByAttribute(key: "class")
		let span: HTMLElement = els.get(index: 0)!
		XCTAssertEqual("mellow yellow", span.className)
		XCTAssertTrue(span.hasClass(named: "mellow"))
		XCTAssertTrue(span.hasClass(named: "yellow"))
		var classes: OrderedSet<String> = span.classNames
		XCTAssertEqual(2, classes.count)
		XCTAssertTrue(classes.contains("mellow"))
		XCTAssertTrue(classes.contains("yellow"))

		XCTAssertEqual(nil, doc.className)
		classes = doc.classNames
		XCTAssertEqual(0, classes.count)
		XCTAssertFalse(doc.hasClass(named: "mellow"))
	}

    func testHasClassDomMethods()throws {
        let tag: Tag = try Tag.valueOf("a")
        let attribs: Attributes = Attributes()
        let el: HTMLElement = HTMLElement(tag: tag, baseURI: "", attributes: attribs)

        try attribs.put("class", "toto")
        var hasClass = el.hasClass(named: "toto")
        XCTAssertTrue(hasClass)

        try attribs.put("class", " toto")
        hasClass = el.hasClass(named: "toto")
        XCTAssertTrue(hasClass)

        try attribs.put("class", "toto ")
        hasClass = el.hasClass(named: "toto")
        XCTAssertTrue(hasClass)

        try attribs.put("class", "\ttoto ")
        hasClass = el.hasClass(named: "toto")
        XCTAssertTrue(hasClass)

        try attribs.put("class", "  toto ")
        hasClass = el.hasClass(named: "toto")
        XCTAssertTrue(hasClass)

        try attribs.put("class", "ab")
        hasClass = el.hasClass(named: "toto")
        XCTAssertFalse(hasClass)

        try attribs.put("class", "     ")
        hasClass = el.hasClass(named: "toto")
        XCTAssertFalse(hasClass)

        try attribs.put("class", "tototo")
        hasClass = el.hasClass(named: "toto")
        XCTAssertFalse(hasClass)

        try attribs.put("class", "raulpismuth  ")
        hasClass = el.hasClass(named: "raulpismuth")
        XCTAssertTrue(hasClass)

        try attribs.put("class", " abcd  raulpismuth efgh ")
        hasClass = el.hasClass(named: "raulpismuth")
        XCTAssertTrue(hasClass)

        try attribs.put("class", " abcd efgh raulpismuth")
        hasClass = el.hasClass(named: "raulpismuth")
        XCTAssertTrue(hasClass)

        try attribs.put("class", " abcd efgh raulpismuth ")
        hasClass = el.hasClass(named: "raulpismuth")
        XCTAssertTrue(hasClass)
    }

    func testClassUpdates()throws {
        let doc: HTMLDocument = HTMLParser.parse("<div class='mellow yellow'></div>")!
        let div: HTMLElement = doc.select(cssQuery: "div").first!

        div.addClass(named: "green")
        XCTAssertEqual("mellow yellow green", div.className)
        div.removeClass(named: "red") // noop
        div.removeClass(named: "yellow")
        XCTAssertEqual("mellow green", div.className)
        div.toggleClass(named: "green").toggleClass(named: "red")
        XCTAssertEqual("mellow red", div.className)
    }

    func testOuterHtml()throws {
        let doc = HTMLParser.parse("<div title='Tags &amp;c.'><img src=foo.png><p><!-- comment -->Hello<p>there")!
        XCTAssertEqual("<html><head></head><body><div title=\"Tags &amp;c.\"><img src=\"foo.png\"><p><!-- comment -->Hello</p><p>there</p></div></body></html>",
                       TextUtil.stripNewlines(doc.outerHTML!))
    }

	func testInnerHtml()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div>\n <p>Hello</p> </div>")!
		XCTAssertEqual("<p>Hello</p>", doc.getElementsByTag("div").get(index: 0)!.html)
	}

	func testFormatHtml()throws {
		let doc: HTMLDocument = HTMLParser.parse("<title>Format test</title><div><p>Hello <span>jsoup <span>users</span></span></p><p>Good.</p></div>")!
		XCTAssertEqual("<html>\n <head>\n  <title>Format test</title>\n </head>\n <body>\n  <div>\n   <p>Hello <span>jsoup <span>users</span></span></p>\n   <p>Good.</p>\n  </div>\n </body>\n</html>", doc.html)
	}

	func testFormatOutline()throws {
		let doc: HTMLDocument = HTMLParser.parse("<title>Format test</title><div><p>Hello <span>jsoup <span>users</span></span></p><p>Good.</p></div>")!
		doc.outputSettings.outline(outlineMode: true)
		XCTAssertEqual("<html>\n <head>\n  <title>Format test</title>\n </head>\n <body>\n  <div>\n   <p>\n    Hello \n    <span>\n     jsoup \n     <span>users</span>\n    </span>\n   </p>\n   <p>Good.</p>\n  </div>\n </body>\n</html>", doc.html)
	}

	func testSetIndent()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello\nthere</p></div>")!
		doc.outputSettings.indentAmount(indentAmount: 0)
		XCTAssertEqual("<html>\n<head></head>\n<body>\n<div>\n<p>Hello there</p>\n</div>\n</body>\n</html>", doc.html)
	}

	func testNotPretty()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div>   \n<p>Hello\n there\n</p></div>")!
		doc.outputSettings.prettyPrint(pretty: false)
		XCTAssertEqual("<html><head></head><body><div>   \n<p>Hello\n there\n</p></div></body></html>", doc.html)

		let div: HTMLElement? = doc.select(cssQuery: "div").first
		XCTAssertEqual("   \n<p>Hello\n there\n</p>", div?.html)
	}

	func testEmptyElementFormatHtml()throws {
		// don't put newlines into empty blocks
		let doc: HTMLDocument = HTMLParser.parse("<section><div></div></section>")!
		XCTAssertEqual("<section>\n <div></div>\n</section>", doc.select(cssQuery: "section").first?.outerHTML)
	}

	func testNoIndentOnScriptAndStyle()throws {
		// don't newline+indent closing </script> and </style> tags
		let doc: HTMLDocument = HTMLParser.parse("<script>one\ntwo</script>\n<style>three\nfour</style>")!
		XCTAssertEqual("<script>one\ntwo</script> \n<style>three\nfour</style>", doc.head?.html)
	}

	func testContainerOutput()throws {
		let doc: HTMLDocument = HTMLParser.parse("<title>Hello there</title> <div><p>Hello</p><p>there</p></div> <div>Another</div>")!
		XCTAssertEqual("<title>Hello there</title>",  doc.select(cssQuery: "title").first?.outerHTML)
		XCTAssertEqual("<div>\n <p>Hello</p>\n <p>there</p>\n</div>",  doc.select(cssQuery: "div").first?.outerHTML)
		XCTAssertEqual("<div>\n <p>Hello</p>\n <p>there</p>\n</div> \n<div>\n Another\n</div>", doc.select(cssQuery: "body").first?.html)
	}

	func testSetText()throws {
		let h: String = "<div id=1>Hello <p>there <b>now</b></p></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		XCTAssertEqual("Hello there now", doc.getText()) // need to sort out node whitespace
		XCTAssertEqual("there now", doc.select(cssQuery: "p").get(index: 0)!.getText())

		let div: HTMLElement? = doc.getElementById("1")?.setText("Gone")
		XCTAssertEqual("Gone", div?.getText())
		XCTAssertEqual(0, doc.select(cssQuery: "p").count)
	}

	func testAddNewElement()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>Hello</p></div>")!
		let div: HTMLElement = doc.getElementById("1")!
        try div.appendElement(tagName: "p").setText("there")
		try div.appendElement(tagName: "P").setAttribute(withKey: "CLASS", newValue: "second").setText("now")
		// manually specifying tag and attributes should now preserve case, regardless of parse mode
		XCTAssertEqual("<html><head></head><body><div id=\"1\"><p>Hello</p><p>there</p><P CLASS=\"second\">now</P></div></body></html>",
		             TextUtil.stripNewlines(doc.html!))

		// check sibling index (with short circuit on reindexChildren):
		let ps: Elements = doc.select(cssQuery: "p")
		for i in 0..<ps.count {
            XCTAssertEqual(i, ps.get(index: i)!.siblingIndex)
		}
	}

	func testAddBooleanAttribute()throws {
		let div: HTMLElement = try HTMLElement(tag: Tag.valueOf("div"), baseURI: "")

		try div.setAttribute(key: "true", value: true)

		try div.setAttribute(withKey: "false", newValue: "value")
		try div.setAttribute(key: "false", value: false)

		XCTAssertTrue(div.hasAttribute(withKey: "true"))
		XCTAssertEqual(nil, div.getAttribute(withKey: "true"))

		let attributes: Array<Attribute> = div.getAttributes()!.asList()
		XCTAssertEqual(1, attributes.count)
		XCTAssertTrue((attributes[0] as? BooleanAttribute) != nil)

		XCTAssertFalse(div.hasAttribute(withKey: "false"))

		XCTAssertEqual("<div true></div>", div.outerHTML)
	}

	func testAppendRowToTable()throws {
		let doc: HTMLDocument = HTMLParser.parse("<table><tr><td>1</td></tr></table>")!
		let table: HTMLElement? = doc.select(cssQuery: "tbody").first
        try table?.appendHTML("<tr><td>2</td></tr>")

		XCTAssertEqual("<table><tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testPrependRowToTable()throws {
		let doc: HTMLDocument = HTMLParser.parse("<table><tr><td>1</td></tr></table>")!
		let table: HTMLElement? = doc.select(cssQuery: "tbody").first
		try table?.prependHTML("<tr><td>2</td></tr>")

		XCTAssertEqual("<table><tbody><tr><td>2</td></tr><tr><td>1</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body!.html!))

		// check sibling index (reindexChildren):
		let ps: Elements = doc.select(cssQuery: "tr")
		for i in 0..<ps.count {
            XCTAssertEqual(i, ps.get(index: i)!.siblingIndex)
		}
	}

	func testPrependElement()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>Hello</p></div>")!
		let div: HTMLElement? = doc.getElementById("1")
        try div?.prependElement(tagName: "p").setText("Before")
		XCTAssertEqual("Before", div?.getChild(at: 0)?.text)
		XCTAssertEqual("Hello", div?.getChild(at: 1)?.text)
	}

	func testAddNewText()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>Hello</p></div>")!
		let div: HTMLElement = doc.getElementById("1")!
        div.appendText(" there & now >")
		XCTAssertEqual("<p>Hello</p> there &amp; now &gt;", TextUtil.stripNewlines(div.html!))
	}

	func testPrependText()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>Hello</p></div>")!
		let div: HTMLElement = doc.getElementById("1")!
        div.prependText("there & now > ")
		XCTAssertEqual("there & now > Hello", div.getText())
		XCTAssertEqual("there &amp; now &gt; <p>Hello</p>", TextUtil.stripNewlines(div.html!))
	}

	// nil not allower
//	func testThrowsOnAddNullText()throws {
//		let doc: HTMLDocument = try Jsoup.parse("<div id=1><p>Hello</p></div>");
//		let div: HTMLElement = try doc.getElementById("1")!;
//		div.appendText(nil);
//	}

	// nil not allower
//	@Test(expected = IllegalArgumentException.class)  public void testThrowsOnPrependNullText() {
//	HTMLDocument doc = Jsoup.parse("<div id=1><p>Hello</p></div>");
//	HTMLElement div = doc.getElementById("1");
//	div.prependText(null);
//	}

	func testAddNewHtml()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>Hello</p></div>")!
		let div: HTMLElement = doc.getElementById("1")!
		try div.appendHTML("<p>there</p><p>now</p>")
		XCTAssertEqual("<p>Hello</p><p>there</p><p>now</p>", TextUtil.stripNewlines(div.html!))

		// check sibling index (no reindexChildren):
		let ps: Elements = doc.select(cssQuery: "p")
		for i in 0..<ps.count {
            XCTAssertEqual(i, ps.get(index: i)?.siblingIndex)
		}
	}

	func testPrependNewHtml()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>Hello</p></div>")!
		let div: HTMLElement = doc.getElementById("1")!
		try div.prependHTML("<p>there</p><p>now</p>")
		XCTAssertEqual("<p>there</p><p>now</p><p>Hello</p>", TextUtil.stripNewlines(div.html!))

		// check sibling index (reindexChildren):
		let ps: Elements = doc.select(cssQuery: "p")
		for i in 0..<ps.count {
            XCTAssertEqual(i, ps.get(index: i)?.siblingIndex)
		}
	}

	func testSetHtml()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>Hello</p></div>")!
		let div: HTMLElement = doc.getElementById("1")!
		try div.setHTML("<p>there</p><p>now</p>")
		XCTAssertEqual("<p>there</p><p>now</p>", TextUtil.stripNewlines(div.html!))
	}

	func testSetHtmlTitle()throws {
		let doc: HTMLDocument = HTMLParser.parse("<html><head id=2><title id=1></title></head></html>")!

		let title: HTMLElement = doc.getElementById("1")!
		try title.setHTML("good")
		XCTAssertEqual("good", title.html)
		try title.setHTML("<i>bad</i>")
		XCTAssertEqual("&lt;i&gt;bad&lt;/i&gt;", title.html)

		let head: HTMLElement = doc.getElementById("2")!
		try head.setHTML("<title><i>bad</i></title>")
		XCTAssertEqual("<title>&lt;i&gt;bad&lt;/i&gt;</title>", head.html)
	}

	func testWrap()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p><p>There</p></div>")!
		let p: HTMLElement = doc.select(cssQuery: "p").first!
		try p.wrap(html: "<div class='head'></div>")
		XCTAssertEqual("<div><div class=\"head\"><p>Hello</p></div><p>There</p></div>", TextUtil.stripNewlines(doc.body!.html!))

		let ret: HTMLElement = try p.wrap(html: "<div><div class=foo></div><p>What?</p></div>")
		XCTAssertEqual("<div><div class=\"head\"><div><div class=\"foo\"><p>Hello</p></div><p>What?</p></div></div><p>There</p></div>",
                    TextUtil.stripNewlines(doc.body!.html!))

		XCTAssertEqual(ret, p)
	}

	func testBefore()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p><p>There</p></div>")!
		let p1: HTMLElement = doc.select(cssQuery: "p").first!
		try p1.insertHTMLAsPreviousSibling("<div>one</div><div>two</div>")
		XCTAssertEqual("<div><div>one</div><div>two</div><p>Hello</p><p>There</p></div>", TextUtil.stripNewlines(doc.body!.html!))

		try doc.select(cssQuery: "p").last?.insertHTMLAsPreviousSibling("<p>Three</p><!-- four -->")
		XCTAssertEqual("<div><div>one</div><div>two</div><p>Hello</p><p>Three</p><!-- four --><p>There</p></div>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testAfter()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p><p>There</p></div>")!
		let p1: HTMLElement = doc.select(cssQuery: "p").first!
		try p1.insertHTMLAsNextSibling("<div>one</div><div>two</div>")
		XCTAssertEqual("<div><p>Hello</p><div>one</div><div>two</div><p>There</p></div>", TextUtil.stripNewlines(doc.body!.html!))

		try doc.select(cssQuery: "p").last?.insertHTMLAsNextSibling("<p>Three</p><!-- four -->")
		XCTAssertEqual("<div><p>Hello</p><div>one</div><div>two</div><p>There</p><p>Three</p><!-- four --></div>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testWrapWithRemainder()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p></div>")!
		let p: HTMLElement = doc.select(cssQuery: "p").first!
		try p.wrap(html: "<div class='head'></div><p>There!</p>")
		XCTAssertEqual("<div><div class=\"head\"><p>Hello</p><p>There!</p></div></div>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHasText()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p><p></p></div>")!
		let div: HTMLElement = doc.select(cssQuery: "div").first!
		let ps: Elements = doc.select(cssQuery: "p")

		XCTAssertTrue(div.hasText)
		XCTAssertTrue(ps.first!.hasText)
		XCTAssertFalse(ps.last!.hasText)
	}

	//todo:datase is a simple dictionary but in java it's different
	func testDataset()throws {
//		let doc: HTMLDocument = try Jsoup.parse("<div id=1 data-name=jsoup class=new data-package=jar>Hello</div><p id=2>Hello</p>");
//		let div: HTMLElement = try doc.select("div").first!;
//		var dataset = div.dataset();
//		let attributes: Attributes = div.getAttributes()!;
//		
//		// size, get, set, add, remove
//		XCTAssertEqual(2, dataset.count);
//		XCTAssertEqual("jsoup", dataset["name"]);
//		XCTAssertEqual("jar", dataset["package"]);
//		
//		dataset["name"] = "jsoup updated"
//		dataset["language"] = "java"
//		dataset.removeValue(forKey: "package")
//		
//		XCTAssertEqual(2, dataset.count);
//		XCTAssertEqual(4, attributes.count);
//		XCTAssertEqual("jsoup updated", try attributes.get(key: "data-name"));
//		XCTAssertEqual("jsoup updated", dataset["name"]);
//		XCTAssertEqual("java", try attributes.get(key: "data-language"));
//		XCTAssertEqual("java", dataset["language"]);
//		
//		try attributes.put("data-food", "bacon");
//		XCTAssertEqual(3, dataset.count);
//		XCTAssertEqual("bacon", dataset["food"]);
//		
//		try attributes.put("data-", "empty");
//		XCTAssertEqual(nil, dataset[""]); // data- is not a data attribute
//		
//		let p: HTMLElement = try doc.select("p").first!;
//		XCTAssertEqual(0, p.dataset().count);

	}

	func testpParentlessToString()throws {
		let doc: HTMLDocument = HTMLParser.parse("<img src='foo'>")!
		let img: HTMLElement = doc.select(cssQuery: "img").first!
		XCTAssertEqual("<img src=\"foo\">", img.outerHTML)

        img.remove() // lost its parent
		XCTAssertEqual("<img src=\"foo\">", img.outerHTML)
	}

	func testClone()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One<p><span>Two</div>")!

		let p: HTMLElement = doc.select(cssQuery: "p").get(index: 1)!
		let clone: HTMLElement = p.copy() as! HTMLElement

		XCTAssertNil(clone.parent) // should be orphaned
		XCTAssertEqual(0, clone.siblingIndex)
		XCTAssertEqual(1, p.siblingIndex)
		XCTAssertNotNil(p.parent)

        try clone.appendHTML("<span>Three")
		XCTAssertEqual("<p><span>Two</span><span>Three</span></p>", TextUtil.stripNewlines(clone.outerHTML!))
		XCTAssertEqual("<div><p>One</p><p><span>Two</span></p></div>", TextUtil.stripNewlines(doc.body!.html!)) // not modified

        doc.body?.appendChild(clone) // adopt
		XCTAssertNotNil(clone.parent)
		XCTAssertEqual("<div><p>One</p><p><span>Two</span></p></div><p><span>Two</span><span>Three</span></p>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testClonesClassnames()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div class='one two'></div>")!
		let div: HTMLElement = doc.select(cssQuery: "div").first!
		let classes = div.classNames
		XCTAssertEqual(2, classes.count)
		XCTAssertTrue(classes.contains("one"))
		XCTAssertTrue(classes.contains("two"))

		let copy: HTMLElement = div.copy() as! HTMLElement
		let copyClasses: OrderedSet<String> = copy.classNames
		XCTAssertEqual(2, copyClasses.count)
		XCTAssertTrue(copyClasses.contains("one"))
		XCTAssertTrue(copyClasses.contains("two"))
		copyClasses.append("three")
		copyClasses.remove("one")

		XCTAssertTrue(classes.contains("one"))
		XCTAssertFalse(classes.contains("three"))
		XCTAssertFalse(copyClasses.contains("one"))
		XCTAssertTrue(copyClasses.contains("three"))

		XCTAssertEqual("", div.html)
		XCTAssertEqual("", copy.html)
	}

	func testTagNameSet()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><i>Hello</i>")!
		try doc.select(cssQuery: "i").first!.setTagName("em")
		XCTAssertEqual(0, doc.select(cssQuery: "i").count)
		XCTAssertEqual(1, doc.select(cssQuery: "em").count)
		XCTAssertEqual("<em>Hello</em>", doc.select(cssQuery: "div").first!.html)
	}

	func testGetTextNodes()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p>One <span>Two</span> Three <br> Four</p>")!
		let textNodes: Array<TextNode> = doc.select(cssQuery: "p").first!.textNodes

		XCTAssertEqual(3, textNodes.count)
		XCTAssertEqual("One ", textNodes[0].text())
		XCTAssertEqual(" Three ", textNodes[1].text())
		XCTAssertEqual(" Four", textNodes[2].text())

		XCTAssertEqual(0, doc.select(cssQuery: "br").first!.textNodes.count)
	}

	func testManipulateTextNodes()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p>One <span>Two</span> Three <br> Four</p>")!
		let p: HTMLElement = doc.select(cssQuery: "p").first!
		let textNodes: Array<TextNode> = p.textNodes

		textNodes[1].text(" three-more ")
		try textNodes[2].splitText(3).text("-ur")

		XCTAssertEqual("One Two three-more Fo-ur", p.getText())
		XCTAssertEqual("One three-more Fo-ur", p.ownText)
		XCTAssertEqual(4, p.textNodes.count) // grew because of split
	}

	func testGetDataNodes()throws {
		let doc: HTMLDocument = HTMLParser.parse("<script>One Two</script> <style>Three Four</style> <p>Fix Six</p>")!
		let script: HTMLElement = doc.select(cssQuery: "script").first!
		let style: HTMLElement = doc.select(cssQuery: "style").first!
		let p: HTMLElement = doc.select(cssQuery: "p").first!

		let scriptData: Array<DataNode> = script.dataNodes
		XCTAssertEqual(1, scriptData.count)
		XCTAssertEqual("One Two", scriptData[0].getWholeData())

		let styleData: Array<DataNode> = style.dataNodes
		XCTAssertEqual(1, styleData.count)
		XCTAssertEqual("Three Four", styleData[0].getWholeData())

		let pData: Array<DataNode> = p.dataNodes
		XCTAssertEqual(0, pData.count)
	}

	func testElementIsNotASiblingOfItself()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One<p>Two<p>Three</div>")!
		let p2: HTMLElement = doc.select(cssQuery: "p").get(index: 1)!

		XCTAssertEqual("Two", p2.getText())
		let els: Elements = p2.siblingElements
		XCTAssertEqual(2, els.count)
		XCTAssertEqual("<p>One</p>", els.get(index: 0)!.outerHTML)
		XCTAssertEqual("<p>Three</p>", els.get(index: 1)!.outerHTML)
	}

	func testChildThrowsIndexOutOfBoundsOnMissing()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One</p><p>Two</p></div>")!
		let div: HTMLElement = doc.select(cssQuery: "div").first!

		XCTAssertEqual(2, div.children.count)
		XCTAssertEqual("One", div.getChild(at: 0)?.text)
	}

	func testMoveByAppend()throws {
		// can empty an element and append its children to another element
		let doc: HTMLDocument = HTMLParser.parse("<div id=1>Text <p>One</p> Text <p>Two</p></div><div id=2></div>")!
		let div1: HTMLElement = doc.select(cssQuery: "div").get(index: 0)!
		let div2: HTMLElement = doc.select(cssQuery: "div").get(index: 1)!

		XCTAssertEqual(4, div1.childNodeSize())
		var children: Array<Node> = div1.getChildNodes()
		XCTAssertEqual(4, children.count)

        div2.insertChildren(children, at: 0)

		children = div1.getChildNodes()
		XCTAssertEqual(0, children.count) // children is backed by div1.childNodes, moved, so should be 0 now
		XCTAssertEqual(0, div1.childNodeSize())
		XCTAssertEqual(4, div2.childNodeSize())
		XCTAssertEqual("<div id=\"1\"></div>\n<div id=\"2\">\n Text \n <p>One</p> Text \n <p>Two</p>\n</div>", doc.body!.html)
	}

	func testInsertChildrenAtPosition()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1>Text1 <p>One</p> Text2 <p>Two</p></div><div id=2>Text3 <p>Three</p></div>")!
		let div1: HTMLElement = doc.select(cssQuery: "div").get(index: 0)!
		let p1s: Elements = div1.select(cssQuery: "p")
		let div2: HTMLElement = doc.select(cssQuery: "div").get(index: 1)!

		XCTAssertEqual(2, div2.childNodeSize())
		div2.insertChildren(p1s.toArray(), at: 0)
		XCTAssertEqual(2, div1.childNodeSize()) // moved two out
		XCTAssertEqual(4, div2.childNodeSize())
		XCTAssertEqual(1, p1s.get(index: 1)!.siblingIndex) // should be last

		var els: Array<Node> = Array<Node>()
        let el1: HTMLElement = try HTMLElement(tag: Tag.valueOf("span"), baseURI: "").setText("Span1")
        let el2: HTMLElement = try HTMLElement(tag: Tag.valueOf("span"), baseURI: "").setText("Span2")
		let tn1: TextNode = TextNode("Text4", "")
		els.append(el1)
		els.append(el2)
		els.append(tn1)

		XCTAssertNil(el1.parent)
        div2.insertChildren(els, at: 4)
		XCTAssertEqual(div2, el1.parent)
		XCTAssertEqual(7, div2.childNodeSize())
		XCTAssertEqual(4, el1.siblingIndex)
		XCTAssertEqual(5, el2.siblingIndex)
		XCTAssertEqual(6, tn1.siblingIndex)
	}

	func testInsertChildrenAsCopy()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1>Text <p>One</p> Text <p>Two</p></div><div id=2></div>")!
		let div1: HTMLElement = doc.select(cssQuery: "div").get(index: 0)!
		let div2: HTMLElement = doc.select(cssQuery: "div").get(index: 1)!
		let ps: Elements = doc.select(cssQuery: "p").copy() as! Elements
		ps.first!.setText("One cloned")
		div2.insertChildren(ps.toArray(), at: 0)

		XCTAssertEqual(4, div1.childNodeSize()) // not moved -- cloned
		XCTAssertEqual(2, div2.childNodeSize())
		XCTAssertEqual("<div id=\"1\">Text <p>One</p> Text <p>Two</p></div><div id=\"2\"><p>One cloned</p><p>Two</p></div>",
                       TextUtil.stripNewlines(doc.body!.html!))
	}

	func testCssPath()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=\"id1\">A</div><div>B</div><div class=\"c1 c2\">C</div>")!
		let divA: HTMLElement = doc.select(cssQuery: "div").get(index: 0)!
		let divB: HTMLElement = doc.select(cssQuery: "div").get(index: 1)!
		let divC: HTMLElement = doc.select(cssQuery: "div").get(index: 2)!
		XCTAssertEqual(divA.cssSelector, "#id1")
		XCTAssertEqual(divB.cssSelector, "html > body > div:nth-child(2)")
		XCTAssertEqual(divC.cssSelector, "html > body > div.c1.c2")

		XCTAssertTrue(divA == doc.select(cssQuery: divA.cssSelector).first)
		XCTAssertTrue(divB == doc.select(cssQuery: divB.cssSelector).first)
		XCTAssertTrue(divC == doc.select(cssQuery: divC.cssSelector).first)
	}

	func testClassNames()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div class=\"c1 c2\">C</div>")!
		let div: HTMLElement = doc.select(cssQuery: "div").get(index: 0)!

		XCTAssertEqual("c1 c2", div.className)

		let set1 = div.classNames
		let arr1 = set1
		XCTAssertTrue(arr1.count==2)
		XCTAssertEqual("c1", arr1[0])
		XCTAssertEqual("c2", arr1[1])

		// Changes to the set should not be reflected in the Elements getters
		set1.append("c3")
		XCTAssertTrue(2==div.classNames.count)
		XCTAssertEqual("c1 c2", div.className)

		// Update the class names to a fresh set
		let newSet = OrderedSet<String>()
		newSet.append(contentsOf: set1)
		//newSet["c3"] //todo: nabil not a set , add == append but not change exists c3

        div.setClass(names: newSet)

		XCTAssertEqual("c1 c2 c3", div.className)

		let set2 = div.classNames
		let arr2 = set2
        guard arr2.count == 3 else {
            XCTFail("Wrong number of elements")
            return
        }
		XCTAssertEqual("c1", arr2[0])
		XCTAssertEqual("c2", arr2[1])
		XCTAssertEqual("c3", arr2[2])
	}

	func testHashAndEqualsAndValue()throws {
		// .equals and hashcode are identity. value is content.

		let doc1 = "<div id=1><p class=one>One</p><p class=one>One</p><p class=one>Two</p><p class=two>One</p></div>" +
		"<div id=2><p class=one>One</p><p class=one>One</p><p class=one>Two</p><p class=two>One</p></div>"

		let doc: HTMLDocument = HTMLParser.parse(doc1)!
		let els: Elements = doc.select(cssQuery: "p")

		/*
		for (HTMLElement el : els) {
		System.out.println(el.hashCode() + " - " + el.outerHTML);
		}
		
		0 1534787905 - <p class="one">One</p>
		1 1534787905 - <p class="one">One</p>
		2 1539683239 - <p class="one">Two</p>
		3 1535455211 - <p class="two">One</p>
		4 1534787905 - <p class="one">One</p>
		5 1534787905 - <p class="one">One</p>
		6 1539683239 - <p class="one">Two</p>
		7 1535455211 - <p class="two">One</p>
		*/
		XCTAssertEqual(8, els.count)
		let e0: HTMLElement = els.get(index: 0)!
		let e1: HTMLElement = els.get(index: 1)!
		let e2: HTMLElement = els.get(index: 2)!
		let e3: HTMLElement = els.get(index: 3)!
		let e4: HTMLElement = els.get(index: 4)!
		let e5: HTMLElement = els.get(index: 5)!
		let e6: HTMLElement = els.get(index: 6)!
		let e7: HTMLElement = els.get(index: 7)!

		XCTAssertEqual(e0, e0)
		XCTAssertTrue(e0.hasSameValue(e1))
		XCTAssertTrue(e0.hasSameValue(e4))
		XCTAssertTrue(e0.hasSameValue(e5))
		XCTAssertFalse(e0.equals(e2))
		XCTAssertFalse(e0.hasSameValue(e2))
		XCTAssertFalse(e0.hasSameValue(e3))
		XCTAssertFalse(e0.hasSameValue(e6))
		XCTAssertFalse(e0.hasSameValue(e7))

		XCTAssertEqual(e0.hashValue, e0.hashValue)
		XCTAssertFalse(e0.hashValue == (e2.hashValue))
		XCTAssertFalse(e0.hashValue == (e3).hashValue)
		XCTAssertFalse(e0.hashValue == (e6).hashValue)
		XCTAssertFalse(e0.hashValue == (e7).hashValue)
	}

	func testRelativeUrls()throws {
		let html = "<body><a href='./one.html'>One</a> <a href='two.html'>two</a> <a href='../three.html'>Three</a> <a href='//example2.com/four/'>Four</a> <a href='https://example2.com/five/'>Five</a>"
        let doc: HTMLDocument = HTMLParser.parse(html, baseURI: "http://example.com/bar/")!
		let els: Elements = doc.select(cssQuery: "a")

		XCTAssertEqual("http://example.com/bar/one.html", els.get(index: 0)!.absoluteURLPath(ofAttribute: "href"))
        XCTAssertEqual("http://example.com/bar/two.html", els.get(index: 1)!.absoluteURLPath(ofAttribute: "href"))
        XCTAssertEqual("http://example.com/three.html", els.get(index: 2)!.absoluteURLPath(ofAttribute: "href"))
        XCTAssertEqual("http://example2.com/four/", els.get(index: 3)!.absoluteURLPath(ofAttribute: "href"))
        XCTAssertEqual("https://example2.com/five/", els.get(index: 4)!.absoluteURLPath(ofAttribute: "href"))
	}

	func testAppendMustCorrectlyMoveChildrenInsideOneParentElement()throws {
		let doc: HTMLDocument = HTMLDocument(baseURI: "")
		let body: HTMLElement = try doc.appendElement(tagName: "body")
		try body.appendElement(tagName: "div1")
		try body.appendElement(tagName: "div2")
		let div3: HTMLElement = try body.appendElement(tagName: "div3")
		div3.setText("Check")
		let div4: HTMLElement = try body.appendElement(tagName: "div4")

		var toMove: Array<HTMLElement> = Array<HTMLElement>()
		toMove.append(div3)
		toMove.append(div4)

		body.insertChildren(toMove, at: 0)

		let result: String = doc.outerHTML!.replaceAll(of: "\\s+", with: "")
		XCTAssertEqual("<body><div3>Check</div3><div4></div4><div1></div1><div2></div2></body>", result)
	}

	func testHashcodeIsStableWithContentChanges()throws {
		let root: HTMLElement = try HTMLElement(tag: Tag.valueOf("root"), baseURI: "")
		let set = OrderedSet<HTMLElement>()
		// Add root node:
		set.append(root)
		try root.appendChild(HTMLElement(tag: Tag.valueOf("a"), baseURI: ""))
		XCTAssertTrue(set.contains(root))
	}

	func testNamespacedElements()throws {
		// Namespaces with ns:tag in HTML must be translated to ns|tag in CSS.
		let html: String = "<html><body><fb:comments /></body></html>"
		let doc: HTMLDocument = HTMLParser.parse(html, baseURI: "http://example.com/bar/")!
		let els: Elements = doc.select(cssQuery: "fb|comments")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("html > body > fb|comments", els.get(index: 0)!.cssSelector)
	}

    func testChainedRemoveAttributes()throws {
        let html = "<a one two three four>Text</a>"
        let doc = HTMLParser.parse(html)!
        let a: HTMLElement = doc.select(cssQuery: "a").first!
       try a.removeAttribute(withKey: "zero")
            .removeAttribute(withKey: "one")
            .removeAttribute(withKey: "two")
            .removeAttribute(withKey: "three")
            .removeAttribute(withKey: "four")
            .removeAttribute(withKey: "five")
        XCTAssertEqual("<a>Text</a>", a.outerHTML)
    }

    func testIs()throws {
        let html = "<div><p>One <a class=big>Two</a> Three</p><p>Another</p>"
        let doc: HTMLDocument = HTMLParser.parse(html)!
        let p: HTMLElement = doc.select(cssQuery: "p").first!

        XCTAssertTrue(p.isMatchedWith(cssQuery: "p"))
        XCTAssertFalse(p.isMatchedWith(cssQuery: "div"))
        XCTAssertTrue(p.isMatchedWith(cssQuery: "p:has(a)"))
        XCTAssertTrue(p.isMatchedWith(cssQuery: "p:first-child"))
        XCTAssertFalse(p.isMatchedWith(cssQuery: "p:last-child"))
        XCTAssertTrue(p.isMatchedWith(cssQuery: "*"))
        XCTAssertTrue(p.isMatchedWith(cssQuery: "div p"))

        let q: HTMLElement = doc.select(cssQuery: "p").last!
        XCTAssertTrue(q.isMatchedWith(cssQuery: "p"))
        XCTAssertTrue(q.isMatchedWith(cssQuery: "p ~ p"))
        XCTAssertTrue(q.isMatchedWith(cssQuery: "p + p"))
        XCTAssertTrue(q.isMatchedWith(cssQuery: "p:last-child"))
        XCTAssertFalse(q.isMatchedWith(cssQuery: "p a"))
        XCTAssertFalse(q.isMatchedWith(cssQuery: "a"))
    }

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testGetElementsByTagName", testGetElementsByTagName),
			("testGetNamespacedElementsByTag", testGetNamespacedElementsByTag),
			("testGetElementById", testGetElementById),
			("testGetText", testGetText),
			("testGetChildText", testGetChildText),
			("testNormalisesText", testNormalisesText),
			("testKeepsPreText", testKeepsPreText),
			("testKeepsPreTextInCode", testKeepsPreTextInCode),
			("testBrHasSpace", testBrHasSpace),
			("testGetSiblings", testGetSiblings),
            ("testGetSiblingsWithDuplicateContent", testGetSiblingsWithDuplicateContent),
			("testGetAncestors", testGetAncestors),
			("testElementSiblingIndex", testElementSiblingIndex),
			("testElementSiblingIndexSameContent", testElementSiblingIndexSameContent),
			("testGetElementsWithClass", testGetElementsWithClass),
			("testGetElementsWithAttribute", testGetElementsWithAttribute),
			("testGetElementsWithAttributeDash", testGetElementsWithAttributeDash),
			("testGetElementsWithAttributeValue", testGetElementsWithAttributeValue),
			("testClassDomMethods", testClassDomMethods),
			("testHasClassDomMethods", testHasClassDomMethods),
			("testClassUpdates", testClassUpdates),
			("testOuterHtml", testOuterHtml),
			("testInnerHtml", testInnerHtml),
			("testFormatHtml", testFormatHtml),
			("testFormatOutline", testFormatOutline),
			("testSetIndent", testSetIndent),
			("testNotPretty", testNotPretty),
			("testEmptyElementFormatHtml", testEmptyElementFormatHtml),
			("testNoIndentOnScriptAndStyle", testNoIndentOnScriptAndStyle),
			("testContainerOutput", testContainerOutput),
			("testSetText", testSetText),
			("testAddNewElement", testAddNewElement),
			("testAddBooleanAttribute", testAddBooleanAttribute),
			("testAppendRowToTable", testAppendRowToTable),
			("testPrependRowToTable", testPrependRowToTable),
			("testPrependElement", testPrependElement),
			("testAddNewText", testAddNewText),
			("testPrependText", testPrependText),
			("testAddNewHtml", testAddNewHtml),
			("testPrependNewHtml", testPrependNewHtml),
			("testSetHtml", testSetHtml),
			("testSetHtmlTitle", testSetHtmlTitle),
			("testWrap", testWrap),
			("testBefore", testBefore),
			("testAfter", testAfter),
			("testWrapWithRemainder", testWrapWithRemainder),
			("testHasText", testHasText),
			("testDataset", testDataset),
			("testpParentlessToString", testpParentlessToString),
			("testClone", testClone),
			("testClonesClassnames", testClonesClassnames),
			("testTagNameSet", testTagNameSet),
			("testGetTextNodes", testGetTextNodes),
			("testManipulateTextNodes", testManipulateTextNodes),
			("testGetDataNodes", testGetDataNodes),
			("testElementIsNotASiblingOfItself", testElementIsNotASiblingOfItself),
			("testChildThrowsIndexOutOfBoundsOnMissing", testChildThrowsIndexOutOfBoundsOnMissing),
			("testMoveByAppend", testMoveByAppend),
			("testInsertChildrenAtPosition", testInsertChildrenAtPosition),
			("testInsertChildrenAsCopy", testInsertChildrenAsCopy),
			("testCssPath", testCssPath),
			("testClassNames", testClassNames),
			("testHashAndEqualsAndValue", testHashAndEqualsAndValue),
			("testRelativeUrls", testRelativeUrls),
			("testAppendMustCorrectlyMoveChildrenInsideOneParentElement", testAppendMustCorrectlyMoveChildrenInsideOneParentElement),
			("testHashcodeIsStableWithContentChanges", testHashcodeIsStableWithContentChanges),
			("testNamespacedElements", testNamespacedElements),
			("testChainedRemoveAttributes", testChainedRemoveAttributes),
			("testIs", testIs)
		]
	}()
}
