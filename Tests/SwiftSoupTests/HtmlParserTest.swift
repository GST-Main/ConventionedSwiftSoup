//
//  HtmlParserTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 10/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//
/**
Tests for the HTMLParser
*/

import XCTest
import PrettySwiftSoup

class HtmlParserTest: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testParsesSimpleDocument()throws {
		let html: String = "<html><head><title>First!</title></head><body><p>First post! <img src=\"foo.png\" /></p></body></html>"
		let doc: Document = HTMLParser.parseHTML(html)!
		// need a better way to verify these:
        let p: Element = doc.body!.getChild(at: 0)!
		XCTAssertEqual("p", p.tagName)
		let img: Element = p.getChild(at: 0)!
		XCTAssertEqual("foo.png", img.getAttribute(withKey: "src"))
		XCTAssertEqual("img", img.tagName)
	}

	func testParsesRoughAttributes()throws {
		let html: String = "<html><head><title>First!</title></head><body><p class=\"foo > bar\">First post! <img src=\"foo.png\" /></p></body></html>"
		let doc: Document = HTMLParser.parseHTML(html)!

		// need a better way to verify these:
		let p: Element = doc.body!.getChild(at: 0)!
		XCTAssertEqual("p", p.tagName)
		XCTAssertEqual("foo > bar", p.getAttribute(withKey: "class"))
	}

	func testParsesQuiteRoughAttributes()throws {
		let html: String = "<p =a>One<a <p>Something</p>Else"
		// this gets a <p> with attr '=a' and an <a tag with an attribue named '<p'; and then auto-recreated
		var doc: Document = HTMLParser.parseHTML(html)!
		XCTAssertEqual("<p =a>One<a <p>Something</a></p>\n" +
			"<a <p>Else</a>", doc.body!.html)

		doc = HTMLParser.parseHTML("<p .....>")!
		XCTAssertEqual("<p .....></p>", doc.body!.html)
	}

	func testParsesComments()throws {
		let html = "<html><head></head><body><img src=foo><!-- <table><tr><td></table> --><p>Hello</p></body></html>"
		let doc = HTMLParser.parseHTML(html)!

		let body: Element = doc.body!
		let comment: Comment =  body.childNode(1)as! Comment // comment should not be sub of img, as it's an empty tag
		XCTAssertEqual(" <table><tr><td></table> ", comment.getData())
		let p: Element = body.getChild(at: 1)!
		let text: TextNode = p.childNode(0)as! TextNode
		XCTAssertEqual("Hello", text.getWholeText())
	}

	func testParsesUnterminatedComments()throws {
		let html = "<p>Hello<!-- <tr><td>"
		let doc: Document = HTMLParser.parseHTML(html)!
		let p: Element = doc.getElementsByTag("p").get(index: 0)!
		XCTAssertEqual("Hello", p.getText())
		let text: TextNode = p.childNode(0) as! TextNode
		XCTAssertEqual("Hello", text.getWholeText())
		let comment: Comment = p.childNode(1)as! Comment
		XCTAssertEqual(" <tr><td>", comment.getData())
	}

	func testDropsUnterminatedTag()throws {
		// swiftsoup used to parse this to <p>, but whatwg, webkit will drop.
		let h1: String = "<p"
		var doc: Document = HTMLParser.parseHTML(h1)!
		XCTAssertEqual(0, doc.getElementsByTag("p").count)
		XCTAssertEqual("", doc.getText())

		let h2: String = "<div id=1<p id='2'"
		doc = HTMLParser.parseHTML(h2)!
		XCTAssertEqual("", doc.getText())
	}

	func testDropsUnterminatedAttribute()throws {
		// swiftsoup used to parse this to <p id="foo">, but whatwg, webkit will drop.
		let h1: String = "<p id=\"foo"
		let doc: Document = HTMLParser.parseHTML(h1)!
		XCTAssertEqual("", doc.getText())
	}

	func testParsesUnterminatedTextarea()throws {
		// don't parse right to end, but break on <p>
		let doc: Document = HTMLParser.parseHTML("<body><p><textarea>one<p>two")!
		let t: Element = doc.select(cssQuery: "textarea").first!
		XCTAssertEqual("one", t.getText())
		XCTAssertEqual("two", doc.select(cssQuery: "p").get(index: 1)!.getText())
	}

	func testParsesUnterminatedOption()throws {
		// bit weird this -- browsers and spec get stuck in select until there's a </select>
		let doc: Document = HTMLParser.parseHTML("<body><p><select><option>One<option>Two</p><p>Three</p>")!
		let options: Elements = doc.select(cssQuery: "option")
		XCTAssertEqual(2, options.count)
		XCTAssertEqual("One", options.first!.getText())
		XCTAssertEqual("TwoThree", options.last!.getText())
	}

	func testSpaceAfterTag()throws {
		let doc: Document = HTMLParser.parseHTML("<div > <a name=\"top\"></a ><p id=1 >Hello</p></div>")!
		XCTAssertEqual("<div> <a name=\"top\"></a><p id=\"1\">Hello</p></div>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testCreatesDocumentStructure()throws {
		let html = "<meta name=keywords /><link rel=stylesheet /><title>SwiftSoup</title><p>Hello world</p>"
		let doc = HTMLParser.parseHTML(html)!
		let head: Element = doc.head!
		let body: Element = doc.body!

		XCTAssertEqual(1, doc.children.count) // root node: contains html node
		XCTAssertEqual(2, doc.getChild(at: 0)!.children.count) // html node: head and body
		XCTAssertEqual(3, head.children.count)
		XCTAssertEqual(1, body.children.count)

		XCTAssertEqual("keywords", head.getElementsByTag("meta").get(index: 0)!.getAttribute(withKey: "name"))
		XCTAssertEqual(0, body.getElementsByTag("meta").count)
		XCTAssertEqual("SwiftSoup",  doc.title)
		XCTAssertEqual("Hello world", body.getText())
		XCTAssertEqual("Hello world", body.children.get(index: 0)!.text)
	}

	func testCreatesStructureFromBodySnippet()throws {
		// the bar baz stuff naturally goes into the body, but the 'foo' goes into root, and the normalisation routine
		// needs to move into the start of the body
		let html = "foo <b>bar</b> baz"
		let doc = HTMLParser.parseHTML(html)!
		XCTAssertEqual("foo bar baz", doc.text)

	}

	func testHandlesEscapedData()throws {
		let html = "<div title='Surf &amp; Turf'>Reef &amp; Beef</div>"
		let doc = HTMLParser.parseHTML(html)!
		let div: Element = doc.getElementsByTag("div").get(index: 0)!

		XCTAssertEqual("Surf & Turf", div.getAttribute(withKey: "title"))
		XCTAssertEqual("Reef & Beef", div.getText())
	}

	func testHandlesDataOnlyTags()throws {
		let t: String = "<style>font-family: bold</style>"
		let tels: Elements = HTMLParser.parseHTML(t)!.getElementsByTag("style")
		XCTAssertEqual("font-family: bold", tels.get(index: 0)!.data)
		XCTAssertEqual("", tels.get(index: 0)!.getText())

		let s: String = "<p>Hello</p><script>obj.insert('<a rel=\"none\" />');\ni++;</script><p>There</p>"
		let doc: Document = HTMLParser.parseHTML(s)!
		XCTAssertEqual("Hello There", doc.getText())
		XCTAssertEqual("obj.insert('<a rel=\"none\" />');\ni++;", doc.data)
	}

	func testHandlesTextAfterData()throws {
		let h: String = "<html><body>pre <script>inner</script> aft</body></html>"
		let doc: Document = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<html><head></head><body>pre <script>inner</script> aft</body></html>", TextUtil.stripNewlines(doc.html!))
	}

	func testHandlesTextArea()throws {
		let doc: Document = HTMLParser.parseHTML("<textarea>Hello</textarea>")!
		let els: Elements = doc.select(cssQuery: "textarea")
		XCTAssertEqual("Hello", els.text())
        XCTAssertEqual(1, els.count)
        XCTAssertEqual("Hello", els.first?.value)
	}

	func testPreservesSpaceInTextArea()throws {
		// preserve because the tag is marked as preserve white space
		let doc: Document = HTMLParser.parseHTML("<textarea>\n\tOne\n\tTwo\n\tThree\n</textarea>")!
		let expect: String = "One\n\tTwo\n\tThree" // the leading and trailing spaces are dropped as a convenience to authors
		let el: Element = doc.select(cssQuery: "textarea").first!
		XCTAssertEqual(expect, el.getText())
		XCTAssertEqual(expect, el.value)
		XCTAssertEqual(expect, el.html)
		XCTAssertEqual("<textarea>\n\t" + expect + "\n</textarea>", el.outerHTML) // but preserved in round-trip html
	}

	func testPreservesSpaceInScript()throws {
		// preserve because it's content is a data node
		let doc: Document = HTMLParser.parseHTML("<script>\nOne\n\tTwo\n\tThree\n</script>")!
		let expect = "\nOne\n\tTwo\n\tThree\n"
		let el: Element = doc.select(cssQuery: "script").first!
		XCTAssertEqual(expect, el.data)
		XCTAssertEqual("One\n\tTwo\n\tThree", el.html)
		XCTAssertEqual("<script>" + expect + "</script>", el.outerHTML)
	}

	func testDoesNotCreateImplicitLists()throws {
		// old SwiftSoup used to wrap this in <ul>, but that's not to spec
		let h: String = "<li>Point one<li>Point two"
		let doc: Document = HTMLParser.parseHTML(h)!
		let ol: Elements = doc.select(cssQuery: "ul") // should NOT have created a default ul.
		XCTAssertEqual(0, ol.count)
		let lis: Elements = doc.select(cssQuery: "li")
		XCTAssertEqual(2, lis.count)
		XCTAssertEqual("body", lis.first!.parent!.tagName)

		// no fiddling with non-implicit lists
		let h2: String = "<ol><li><p>Point the first<li><p>Point the second"
		let doc2: Document = HTMLParser.parseHTML(h2)!

		XCTAssertEqual(0, doc2.select(cssQuery: "ul").count)
		XCTAssertEqual(1, doc2.select(cssQuery: "ol").count)
		XCTAssertEqual(2, doc2.select(cssQuery: "ol li").count)
		XCTAssertEqual(2, doc2.select(cssQuery: "ol li p").count)
		XCTAssertEqual(1, doc2.select(cssQuery: "ol li").get(index: 0)!.children.count) // one p in first li
	}

	func testDiscardsNakedTds()throws {
		// SwiftSoup used to make this into an implicit table; but browsers make it into a text run
		let h: String = "<td>Hello<td><p>There<p>now"
		let doc: Document = HTMLParser.parseHTML(h)!
		XCTAssertEqual("Hello<p>There</p><p>now</p>", TextUtil.stripNewlines(doc.body!.html!))
		// <tbody> is introduced if no implicitly creating table, but allows tr to be directly under table
	}

	func testHandlesNestedImplicitTable()throws {
		let doc: Document = HTMLParser.parseHTML("<table><td>1</td></tr> <td>2</td></tr> <td> <table><td>3</td> <td>4</td></table> <tr><td>5</table>")!
		XCTAssertEqual("<table><tbody><tr><td>1</td></tr> <tr><td>2</td></tr> <tr><td> <table><tbody><tr><td>3</td> <td>4</td></tr></tbody></table> </td></tr><tr><td>5</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHandlesWhatWgExpensesTableExample()throws {
		// http://www.whatwg.org/specs/web-apps/current-work/multipage/tabular-data.html#examples-0
		let doc = HTMLParser.parseHTML("<table> <colgroup> <col> <colgroup> <col> <col> <col> <thead> <tr> <th> <th>2008 <th>2007 <th>2006 <tbody> <tr> <th scope=rowgroup> Research and development <td> $ 1,109 <td> $ 782 <td> $ 712 <tr> <th scope=row> Percentage of net sales <td> 3.4% <td> 3.3% <td> 3.7% <tbody> <tr> <th scope=rowgroup> Selling, general, and administrative <td> $ 3,761 <td> $ 2,963 <td> $ 2,433 <tr> <th scope=row> Percentage of net sales <td> 11.6% <td> 12.3% <td> 12.6% </table>")!
		XCTAssertEqual("<table> <colgroup> <col> </colgroup><colgroup> <col> <col> <col> </colgroup><thead> <tr> <th> </th><th>2008 </th><th>2007 </th><th>2006 </th></tr></thead><tbody> <tr> <th scope=\"rowgroup\"> Research and development </th><td> $ 1,109 </td><td> $ 782 </td><td> $ 712 </td></tr><tr> <th scope=\"row\"> Percentage of net sales </th><td> 3.4% </td><td> 3.3% </td><td> 3.7% </td></tr></tbody><tbody> <tr> <th scope=\"rowgroup\"> Selling, general, and administrative </th><td> $ 3,761 </td><td> $ 2,963 </td><td> $ 2,433 </td></tr><tr> <th scope=\"row\"> Percentage of net sales </th><td> 11.6% </td><td> 12.3% </td><td> 12.6% </td></tr></tbody></table>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHandlesTbodyTable()throws {
		let doc: Document = HTMLParser.parseHTML("<html><head></head><body><table><tbody><tr><td>aaa</td><td>bbb</td></tr></tbody></table></body></html>")!
		XCTAssertEqual("<table><tbody><tr><td>aaa</td><td>bbb</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHandlesImplicitCaptionClose()throws {
		let doc = HTMLParser.parseHTML("<table><caption>A caption<td>One<td>Two")!
		XCTAssertEqual("<table><caption>A caption</caption><tbody><tr><td>One</td><td>Two</td></tr></tbody></table>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testNoTableDirectInTable()throws {
		let doc: Document = HTMLParser.parseHTML("<table> <td>One <td><table><td>Two</table> <table><td>Three")!
		XCTAssertEqual("<table> <tbody><tr><td>One </td><td><table><tbody><tr><td>Two</td></tr></tbody></table> <table><tbody><tr><td>Three</td></tr></tbody></table></td></tr></tbody></table>",
		               TextUtil.stripNewlines(doc.body!.html!))
	}

	func testIgnoresDupeEndTrTag()throws {
		let doc: Document = HTMLParser.parseHTML("<table><tr><td>One</td><td><table><tr><td>Two</td></tr></tr></table></td><td>Three</td></tr></table>")! // two </tr></tr>, must ignore or will close table
		XCTAssertEqual("<table><tbody><tr><td>One</td><td><table><tbody><tr><td>Two</td></tr></tbody></table></td><td>Three</td></tr></tbody></table>",
		               TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHandlesBaseTags()throws {
		// only listen to the first base href
		let h = "<a href=1>#</a><base href='/2/'><a href='3'>#</a><base href='http://bar'><a href=/4>#</a>"
		let doc = HTMLParser.parseHTML(h, baseURI: "http://foo/")!
		XCTAssertEqual("http://foo/2/", doc.baseURI) // gets set once, so doc and descendants have first only

		let anchors: Elements = doc.getElementsByTag("a")
		XCTAssertEqual(3, anchors.count)

		XCTAssertEqual("http://foo/2/", anchors.get(index: 0)!.baseURI)
		XCTAssertEqual("http://foo/2/", anchors.get(index: 1)!.baseURI)
		XCTAssertEqual("http://foo/2/", anchors.get(index: 2)!.baseURI)

		XCTAssertEqual("http://foo/2/1", anchors.get(index: 0)!.absoluteURLPath(ofAttribute: "href"))
		XCTAssertEqual("http://foo/2/3", anchors.get(index: 1)!.absoluteURLPath(ofAttribute: "href"))
		XCTAssertEqual("http://foo/4", anchors.get(index: 2)!.absoluteURLPath(ofAttribute: "href"))
	}

	func testHandlesProtocolRelativeUrl()throws {
		let base = "https://example.com/"
		let html = "<img src='//example.net/img.jpg'>"
        let doc = HTMLParser.parseHTML(html, baseURI: base)!
        let el: Element = doc.select(cssQuery: "img").first!
		XCTAssertEqual("https://example.net/img.jpg", el.absoluteURLPath(ofAttribute: "src"))
	}

	func testHandlesCdata()throws {
		// todo: as this is html namespace, should actually treat as bogus comment, not cdata. keep as cdata for now
		let h = "<div id=1><![CDATA[<html>\n<foo><&amp;]]></div>" // the &amp; in there should remain literal
		let doc: Document = HTMLParser.parseHTML(h)!
		let div: Element = doc.getElementById("1")!
		XCTAssertEqual("<html> <foo><&amp;", div.getText())
		XCTAssertEqual(0, div.children.count)
		XCTAssertEqual(1, div.childNodeSize()) // no elements, one text node
	}

	func testHandlesUnclosedCdataAtEOF()throws {
		// https://github.com/jhy/jsoup/issues/349 would crash, as character reader would to seek past EOF
		let h = "<![CDATA[]]"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual(1, doc.body!.childNodeSize())
	}

	func testHandlesInvalidStartTags()throws {
		let h: String = "<div>Hello < There <&amp;></div>" // parse to <div {#text=Hello < There <&>}>
		let doc: Document = HTMLParser.parseHTML(h)!
		XCTAssertEqual("Hello < There <&>", doc.select(cssQuery: "div").first!.getText())
	}

	func testHandlesUnknownTags()throws {
		let h = "<div><foo title=bar>Hello<foo title=qux>there</foo></div>"
		let doc = HTMLParser.parseHTML(h)!
        let foos: Elements = doc.select(cssQuery: "foo")
		XCTAssertEqual(2, foos.count)
		XCTAssertEqual("bar", foos.first!.getAttribute(withKey: "title"))
		XCTAssertEqual("qux", foos.last!.getAttribute(withKey: "title"))
		XCTAssertEqual("there", foos.last!.getText())
	}

	func testHandlesUnknownInlineTags()throws {
		let h = "<p><cust>Test</cust></p><p><cust><cust>Test</cust></cust></p>"
		let doc: Document = HTMLParser.parseBodyFragment(h)!
		let out: String = doc.body!.html!
		XCTAssertEqual(h, TextUtil.stripNewlines(out))
	}

	func testParsesBodyFragment()throws {
		let h = "<!-- comment --><p><a href='foo'>One</a></p>"
        let doc: Document = HTMLParser.parseBodyFragment(h, baseURI: "http://example.com")!
		XCTAssertEqual("<body><!-- comment --><p><a href=\"foo\">One</a></p></body>", TextUtil.stripNewlines(doc.body!.outerHTML!))
		XCTAssertEqual("http://example.com/foo", doc.select(cssQuery: "a").first!.absoluteURLPath(ofAttribute: "href"))
	}

	func testHandlesUnknownNamespaceTags()throws {
		// note that the first foo:bar should not really be allowed to be self closing, if parsed in html mode.
		let h = "<foo:bar id='1' /><abc:def id=2>Foo<p>Hello</p></abc:def><foo:bar>There</foo:bar>"
		let doc: Document = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<foo:bar id=\"1\" /><abc:def id=\"2\">Foo<p>Hello</p></abc:def><foo:bar>There</foo:bar>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHandlesKnownEmptyBlocks()throws {
		// if a known tag, allow self closing outside of spec, but force an end tag. unknown tags can be self closing.
		let h = "<div id='1' /><script src='/foo' /><div id=2><img /><img></div><a id=3 /><i /><foo /><foo>One</foo> <hr /> hr text <hr> hr text two"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<div id=\"1\"></div><script src=\"/foo\"></script><div id=\"2\"><img><img></div><a id=\"3\"></a><i></i><foo /><foo>One</foo> <hr> hr text <hr> hr text two", TextUtil.stripNewlines(doc.body!.html!))
	}
    
    func testHandlesKnownEmptyNoFrames() throws {
        let h = "<html><head><noframes /><meta name=foo></head><body>One</body></html>";
        let doc = HTMLParser.parseHTML(h)!;
        XCTAssertEqual("<html><head><noframes></noframes><meta name=\"foo\"></head><body>One</body></html>", TextUtil.stripNewlines(doc.html!));
    }
    
    func testHandlesKnownEmptyStyle() throws {
        let h = "<html><head><style /><meta name=foo></head><body>One</body></html>";
        let doc = HTMLParser.parseHTML(h)!;
        XCTAssertEqual("<html><head><style></style><meta name=\"foo\"></head><body>One</body></html>", TextUtil.stripNewlines(doc.html!));
    }

    func testHandlesKnownEmptyTitle() throws {
        let h = "<html><head><title /><meta name=foo></head><body>One</body></html>";
        let doc = HTMLParser.parseHTML(h)!;
        XCTAssertEqual("<html><head><title></title><meta name=\"foo\"></head><body>One</body></html>", TextUtil.stripNewlines(doc.html!));
    }

	func testHandlesSolidusAtAttributeEnd()throws {
		// this test makes sure [<a href=/>link</a>] is parsed as [<a href="/">link</a>], not [<a href="" /><a>link</a>]
		let h = "<a href=/>link</a>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<a href=\"/\">link</a>", doc.body!.html)
	}

	func testHandlesMultiClosingBody()throws {
		let h = "<body><p>Hello</body><p>there</p></body></body></html><p>now"
		let doc: Document = HTMLParser.parseHTML(h)!
		XCTAssertEqual(3, doc.select(cssQuery: "p").count)
		XCTAssertEqual(3, doc.body!.children.count)
	}

	func testHandlesUnclosedDefinitionLists()throws {
		// SwiftSoup used to create a <dl>, but that's not to spec
		let h: String = "<dt>Foo<dd>Bar<dt>Qux<dd>Zug"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual(0, doc.select(cssQuery: "dl").count) // no auto dl
		XCTAssertEqual(4, doc.select(cssQuery: "dt, dd").count)
		let dts: Elements = doc.select(cssQuery: "dt")
		XCTAssertEqual(2, dts.count)
		XCTAssertEqual("Zug",  dts.get(index: 1)!.nextSiblingElement?.getText())
	}

	func testHandlesBlocksInDefinitions()throws {
		// per the spec, dt and dd are inline, but in practise are block
		let h = "<dl><dt><div id=1>Term</div></dt><dd><div id=2>Def</div></dd></dl>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("dt", doc.select(cssQuery: "#1").first!.parent!.tagName)
		XCTAssertEqual("dd", doc.select(cssQuery: "#2").first!.parent!.tagName)
		XCTAssertEqual("<dl><dt><div id=\"1\">Term</div></dt><dd><div id=\"2\">Def</div></dd></dl>",  TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHandlesFrames()throws {
		let h = "<html><head><script></script><noscript></noscript></head><frameset><frame src=foo></frame><frame src=foo></frameset></html>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<html><head><script></script><noscript></noscript></head><frameset><frame src=\"foo\"><frame src=\"foo\"></frameset></html>",
		               TextUtil.stripNewlines(doc.html!))
		// no body auto vivification
	}

	func testIgnoresContentAfterFrameset()throws {
		let h = "<html><head><title>One</title></head><frameset><frame /><frame /></frameset><table></table></html>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<html><head><title>One</title></head><frameset><frame><frame></frameset></html>", TextUtil.stripNewlines(doc.html!))
		// no body, no table. No crash!
	}

	func testHandlesJavadocFont()throws {
		let h = "<TD BGCOLOR=\"#EEEEFF\" CLASS=\"NavBarCell1\">    <A HREF=\"deprecated-list.html\"><FONT CLASS=\"NavBarFont1\"><B>Deprecated</B></FONT></A>&nbsp;</TD>"
		let doc = HTMLParser.parseHTML(h)!
		let a: Element = doc.select(cssQuery: "a").first!
		XCTAssertEqual("Deprecated", a.getText())
		XCTAssertEqual("font", a.getChild(at: 0)?.tagName)
		XCTAssertEqual("b", a.getChild(at: 0)?.getChild(at: 0)?.tagName)
	}

	func testHandlesBaseWithoutHref()throws {
		let h = "<head><base target='_blank'></head><body><a href=/foo>Test</a></body>"
        let doc = HTMLParser.parseHTML(h, baseURI: "http://example.com/")!
		let a: Element = doc.select(cssQuery: "a").first!
		XCTAssertEqual("/foo", a.getAttribute(withKey: "href"))
		XCTAssertEqual("http://example.com/foo",  a.getAttribute(withKey: "abs:href"))
	}

	func testNormalisesDocument()throws {
		let h = "<!doctype html>One<html>Two<head>Three<link></head>Four<body>Five </body>Six </html>Seven "
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<!doctype html><html><head></head><body>OneTwoThree<link>FourFive Six Seven </body></html>",
		               TextUtil.stripNewlines(doc.html!))
	}

	func testNormalisesEmptyDocument()throws {
		let doc = HTMLParser.parseHTML("")!
		XCTAssertEqual("<html><head></head><body></body></html>", TextUtil.stripNewlines(doc.html!))
	}

	func testNormalisesHeadlessBody()throws {
		let doc = HTMLParser.parseHTML("<html><body><span class=\"foo\">bar</span>")!
		XCTAssertEqual("<html><head></head><body><span class=\"foo\">bar</span></body></html>",
		               TextUtil.stripNewlines(doc.html!))
	}

	func testNormalisedBodyAfterContent()throws {
		let doc = HTMLParser.parseHTML("<font face=Arial><body class=name><div>One</div></body></font>")!
		XCTAssertEqual("<html><head></head><body class=\"name\"><font face=\"Arial\"><div>One</div></font></body></html>",
		               TextUtil.stripNewlines(doc.html!))
	}

	func testHgroup()throws {
		// SwiftSoup used to not allow hroup in h{n}, but that's not in spec, and browsers are OK
		let doc = HTMLParser.parseHTML("<h1>Hello <h2>There <hgroup><h1>Another<h2>headline</hgroup> <hgroup><h1>More</h1><p>stuff</p></hgroup>")!
		XCTAssertEqual("<h1>Hello </h1><h2>There <hgroup><h1>Another</h1><h2>headline</h2></hgroup> <hgroup><h1>More</h1><p>stuff</p></hgroup></h2>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testRelaxedTags()throws {
		let doc = HTMLParser.parseHTML("<abc_def id=1>Hello</abc_def> <abc-def>There</abc-def>")!
		XCTAssertEqual("<abc_def id=\"1\">Hello</abc_def> <abc-def>There</abc-def>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHeaderContents()throws {
		// h* tags (h1 .. h9) in browsers can handle any internal content other than other h*. which is not per any
		// spec, which defines them as containing phrasing content only. so, reality over theory.
		let doc = HTMLParser.parseHTML("<h1>Hello <div>There</div> now</h1> <h2>More <h3>Content</h3></h2>")!
		XCTAssertEqual("<h1>Hello <div>There</div> now</h1> <h2>More </h2><h3>Content</h3>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testSpanContents()throws {
		// like h1 tags, the spec says SPAN is phrasing only, but browsers and publisher treat span as a block tag
		let doc = HTMLParser.parseHTML("<span>Hello <div>there</div> <span>now</span></span>")!
		XCTAssertEqual("<span>Hello <div>there</div> <span>now</span></span>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testNoImagesInNoScriptInHead()throws {
		// SwiftSoup used to allow, but against spec if parsing with noscript
		let doc = HTMLParser.parseHTML("<html><head><noscript><img src='foo'></noscript></head><body><p>Hello</p></body></html>")!
		XCTAssertEqual("<html><head><noscript>&lt;img src=\"foo\"&gt;</noscript></head><body><p>Hello</p></body></html>", TextUtil.stripNewlines(doc.html!))
	}

	func testAFlowContents()throws {
		// html5 has <a> as either phrasing or block
		let doc = HTMLParser.parseHTML("<a>Hello <div>there</div> <span>now</span></a>")!
		XCTAssertEqual("<a>Hello <div>there</div> <span>now</span></a>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testFontFlowContents()throws {
		// html5 has no definition of <font>; often used as flow
		let doc = HTMLParser.parseHTML("<font>Hello <div>there</div> <span>now</span></font>")!
		XCTAssertEqual("<font>Hello <div>there</div> <span>now</span></font>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testhandlesMisnestedTagsBI()throws {
		// whatwg: <b><i></b></i>
		let h = "<p>1<b>2<i>3</b>4</i>5</p>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<p>1<b>2<i>3</i></b><i>4</i>5</p>", doc.body!.html)
		// adoption agency on </b>, reconstruction of formatters on 4.
	}

	func testhandlesMisnestedTagsBP()throws {
		//  whatwg: <b><p></b></p>
		let h = "<b>1<p>2</b>3</p>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<b>1</b>\n<p><b>2</b>3</p>", doc.body!.html)
	}

	func testhandlesUnexpectedMarkupInTables()throws {
		// whatwg - tests markers in active formatting (if they didn't work, would get in in table)
		// also tests foster parenting
		let h = "<table><b><tr><td>aaa</td></tr>bbb</table>ccc"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<b></b><b>bbb</b><table><tbody><tr><td>aaa</td></tr></tbody></table><b>ccc</b>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testHandlesUnclosedFormattingElements()throws {
		// whatwg: formatting elements get collected and applied, but excess elements are thrown away
		let h = "<!DOCTYPE html>\n" +
			"<p><b class=x><b class=x><b><b class=x><b class=x><b>X\n" +
			"<p>X\n" +
			"<p><b><b class=x><b>X\n" +
		"<p></b></b></b></b></b></b>X"
		let doc = HTMLParser.parseHTML(h)!
		doc.outputSettings.indentAmount(indentAmount: 0)
		let want = "<!doctype html>\n" +
			"<html>\n" +
			"<head></head>\n" +
			"<body>\n" +
			"<p><b class=\"x\"><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b>X </b></b></b></b></b></b></p>\n" +
			"<p><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b>X </b></b></b></b></b></p>\n" +
			"<p><b class=\"x\"><b><b class=\"x\"><b class=\"x\"><b><b><b class=\"x\"><b>X </b></b></b></b></b></b></b></b></p>\n" +
			"<p>X</p>\n" +
			"</body>\n" +
		"</html>"
		XCTAssertEqual(want, doc.html)
	}

	func testhandlesUnclosedAnchors()throws {
		let h = "<a href='http://example.com/'>Link<p>Error link</a>"
		let doc = HTMLParser.parseHTML(h)!
		let want = "<a href=\"http://example.com/\">Link</a>\n<p><a href=\"http://example.com/\">Error link</a></p>"
		XCTAssertEqual(want, doc.body!.html)
	}

	func testreconstructFormattingElements()throws {
		// tests attributes and multi b
		let h = "<p><b class=one>One <i>Two <b>Three</p><p>Hello</p>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<p><b class=\"one\">One <i>Two <b>Three</b></i></b></p>\n<p><b class=\"one\"><i><b>Hello</b></i></b></p>", doc.body!.html)
	}

	func testreconstructFormattingElementsInTable()throws {
		// tests that tables get formatting markers -- the <b> applies outside the table and does not leak in,
		// and the <i> inside the table and does not leak out.
		let h = "<p><b>One</p> <table><tr><td><p><i>Three<p>Four</i></td></tr></table> <p>Five</p>"
		let doc = HTMLParser.parseHTML(h)!
		let want = "<p><b>One</b></p>\n" +
			"<b> \n" +
			" <table>\n" +
			"  <tbody>\n" +
			"   <tr>\n" +
			"    <td><p><i>Three</i></p><p><i>Four</i></p></td>\n" +
			"   </tr>\n" +
			"  </tbody>\n" +
		" </table> <p>Five</p></b>"
		XCTAssertEqual(want, doc.body!.html)
	}

	func testcommentBeforeHtml()throws {
		let h = "<!-- comment --><!-- comment 2 --><p>One</p>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<!-- comment --><!-- comment 2 --><html><head></head><body><p>One</p></body></html>", TextUtil.stripNewlines(doc.html!))
	}

	func testemptyTdTag()throws {
		let h = "<table><tr><td>One</td><td id='2' /></tr></table>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual("<td>One</td>\n<td id=\"2\"></td>", doc.select(cssQuery: "tr").first!.html)
	}

	func testhandlesSolidusInA()throws {
		// test for bug #66
		let h = "<a class=lp href=/lib/14160711/>link text</a>"
		let doc = HTMLParser.parseHTML(h)!
		let a: Element = doc.select(cssQuery: "a").first!
		XCTAssertEqual("link text", a.getText())
		XCTAssertEqual("/lib/14160711/", a.getAttribute(withKey: "href"))
	}

	func testhandlesSpanInTbody()throws {
		// test for bug 64
		let h = "<table><tbody><span class='1'><tr><td>One</td></tr><tr><td>Two</td></tr></span></tbody></table>"
		let doc = HTMLParser.parseHTML(h)!
		XCTAssertEqual(doc.select(cssQuery: "span").first!.children.count, 0) // the span gets closed
		XCTAssertEqual(doc.select(cssQuery: "table").count, 1) // only one table
	}

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testParsesSimpleDocument", testParsesSimpleDocument),
			("testParsesRoughAttributes", testParsesRoughAttributes),
			("testParsesQuiteRoughAttributes", testParsesQuiteRoughAttributes),
			("testParsesComments", testParsesComments),
			("testParsesUnterminatedComments", testParsesUnterminatedComments),
			("testDropsUnterminatedTag", testDropsUnterminatedTag),
			("testDropsUnterminatedAttribute", testDropsUnterminatedAttribute),
			("testParsesUnterminatedTextarea", testParsesUnterminatedTextarea),
			("testParsesUnterminatedOption", testParsesUnterminatedOption),
			("testSpaceAfterTag", testSpaceAfterTag),
			("testCreatesDocumentStructure", testCreatesDocumentStructure),
			("testCreatesStructureFromBodySnippet", testCreatesStructureFromBodySnippet),
			("testHandlesEscapedData", testHandlesEscapedData),
			("testHandlesDataOnlyTags", testHandlesDataOnlyTags),
			("testHandlesTextAfterData", testHandlesTextAfterData),
			("testHandlesTextArea", testHandlesTextArea),
			("testPreservesSpaceInTextArea", testPreservesSpaceInTextArea),
			("testPreservesSpaceInScript", testPreservesSpaceInScript),
			("testDoesNotCreateImplicitLists", testDoesNotCreateImplicitLists),
			("testDiscardsNakedTds", testDiscardsNakedTds),
			("testHandlesNestedImplicitTable", testHandlesNestedImplicitTable),
			("testHandlesWhatWgExpensesTableExample", testHandlesWhatWgExpensesTableExample),
			("testHandlesTbodyTable", testHandlesTbodyTable),
			("testHandlesImplicitCaptionClose", testHandlesImplicitCaptionClose),
			("testNoTableDirectInTable", testNoTableDirectInTable),
			("testIgnoresDupeEndTrTag", testIgnoresDupeEndTrTag),
			("testHandlesBaseTags", testHandlesBaseTags),
			("testHandlesProtocolRelativeUrl", testHandlesProtocolRelativeUrl),
			("testHandlesCdata", testHandlesCdata),
			("testHandlesUnclosedCdataAtEOF", testHandlesUnclosedCdataAtEOF),
			("testHandlesInvalidStartTags", testHandlesInvalidStartTags),
			("testHandlesUnknownTags", testHandlesUnknownTags),
			("testHandlesUnknownInlineTags", testHandlesUnknownInlineTags),
			("testParsesBodyFragment", testParsesBodyFragment),
			("testHandlesUnknownNamespaceTags", testHandlesUnknownNamespaceTags),
			("testHandlesKnownEmptyBlocks", testHandlesKnownEmptyBlocks),
			("testHandlesSolidusAtAttributeEnd", testHandlesSolidusAtAttributeEnd),
			("testHandlesMultiClosingBody", testHandlesMultiClosingBody),
			("testHandlesUnclosedDefinitionLists", testHandlesUnclosedDefinitionLists),
			("testHandlesBlocksInDefinitions", testHandlesBlocksInDefinitions),
			("testHandlesFrames", testHandlesFrames),
			("testIgnoresContentAfterFrameset", testIgnoresContentAfterFrameset),
			("testHandlesJavadocFont", testHandlesJavadocFont),
			("testHandlesBaseWithoutHref", testHandlesBaseWithoutHref),
			("testNormalisesDocument", testNormalisesDocument),
			("testNormalisesEmptyDocument", testNormalisesEmptyDocument),
			("testNormalisesHeadlessBody", testNormalisesHeadlessBody),
			("testNormalisedBodyAfterContent", testNormalisedBodyAfterContent),
			("testHgroup", testHgroup),
			("testRelaxedTags", testRelaxedTags),
			("testHeaderContents", testHeaderContents),
			("testSpanContents", testSpanContents),
			("testNoImagesInNoScriptInHead", testNoImagesInNoScriptInHead),
			("testAFlowContents", testAFlowContents),
			("testFontFlowContents", testFontFlowContents),
			("testhandlesMisnestedTagsBI", testhandlesMisnestedTagsBI),
			("testhandlesMisnestedTagsBP", testhandlesMisnestedTagsBP),
			("testhandlesUnexpectedMarkupInTables", testhandlesUnexpectedMarkupInTables),
			("testHandlesUnclosedFormattingElements", testHandlesUnclosedFormattingElements),
			("testhandlesUnclosedAnchors", testhandlesUnclosedAnchors),
			("testreconstructFormattingElements", testreconstructFormattingElements),
			("testreconstructFormattingElementsInTable", testreconstructFormattingElementsInTable),
			("testcommentBeforeHtml", testcommentBeforeHtml),
			("testemptyTdTag", testemptyTdTag),
			("testhandlesSolidusInA", testhandlesSolidusInA),
			("testhandlesSpanInTbody", testhandlesSpanInTbody)
		]
	}()

}
