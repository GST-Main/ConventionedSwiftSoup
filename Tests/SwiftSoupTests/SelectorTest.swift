//
//  SelectorTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 12/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//

import XCTest
import PrettySwiftSoup

class SelectorTest: XCTestCase {

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testByTag()throws {
		// should be case insensitive
		let els: HTMLElements = HTMLParser.parse("<div id=1><div id=2><p>Hello</p></div></div><DIV id=3>")!.select(cssQuery: "DIV")
		XCTAssertEqual(3, els.count)
		XCTAssertEqual("1", els.get(index: 0)!.id)
		XCTAssertEqual("2", els.get(index: 1)!.id)
		XCTAssertEqual("3", els.get(index: 2)!.id)

		let none: HTMLElements = HTMLParser.parse("<div id=1><div id=2><p>Hello</p></div></div><div id=3>")!.select(cssQuery: "span")
		XCTAssertEqual(0, none.count)
	}

	func testById()throws {
		let els: HTMLElements = HTMLParser.parse("<div><p id=foo>Hello</p><p id=foo>Foo two!</p></div>")!.select(cssQuery: "#foo")
		XCTAssertEqual(2, els.count)
		XCTAssertEqual("Hello", els.get(index: 0)!.getText())
		XCTAssertEqual("Foo two!", els.get(index: 1)!.getText())

		let none: HTMLElements = HTMLParser.parse("<div id=1></div>")!.select(cssQuery: "#foo")
		XCTAssertEqual(0, none.count)
	}

	func testByClass()throws {
		let els: HTMLElements = HTMLParser.parse("<p id=0 class='ONE two'><p id=1 class='one'><p id=2 class='two'>")!.select(cssQuery: "P.One")
		XCTAssertEqual(2, els.count)
		XCTAssertEqual("0", els.get(index: 0)!.id)
		XCTAssertEqual("1", els.get(index: 1)!.id)

		let none: HTMLElements = HTMLParser.parse("<div class='one'></div>")!.select(cssQuery: ".foo")
		XCTAssertEqual(0, none.count)

		let els2: HTMLElements = HTMLParser.parse("<div class='One-Two'></div>")!.select(cssQuery: ".one-two")
		XCTAssertEqual(1, els2.count)
	}

	func testByAttribute()throws {
		let h: String = "<div Title=Foo /><div Title=Bar /><div Style=Qux /><div title=Bam /><div title=SLAM />" +
		"<div data-name='with spaces'/>"
		let doc: HTMLDocument = HTMLParser.parse(h)!

		let withTitle: HTMLElements = doc.select(cssQuery: "[title]")
		XCTAssertEqual(4, withTitle.count)

		let foo: HTMLElements = doc.select(cssQuery: "[TITLE=foo]")
		XCTAssertEqual(1, foo.count)

		let foo2: HTMLElements = doc.select(cssQuery: "[title=\"foo\"]")
		XCTAssertEqual(1, foo2.count)

		let foo3: HTMLElements = doc.select(cssQuery: "[title=\"Foo\"]")
		XCTAssertEqual(1, foo3.count)

		let dataName: HTMLElements = doc.select(cssQuery: "[data-name=\"with spaces\"]")
		XCTAssertEqual(1, dataName.count)
		XCTAssertEqual("with spaces", dataName.first?.getAttribute(withKey: "data-name"))

		let not: HTMLElements = doc.select(cssQuery: "div[title!=bar]")
		XCTAssertEqual(5, not.count)
		XCTAssertEqual("Foo", not.first?.getAttribute(withKey: "title"))

		let starts: HTMLElements = doc.select(cssQuery: "[title^=ba]")
		XCTAssertEqual(2, starts.count)
		XCTAssertEqual("Bar", starts.first?.getAttribute(withKey: "title"))
		XCTAssertEqual("Bam", starts.last?.getAttribute(withKey: "title"))

		let ends: HTMLElements = doc.select(cssQuery: "[title$=am]")
		XCTAssertEqual(2, ends.count)
		XCTAssertEqual("Bam", ends.first?.getAttribute(withKey: "title"))
		XCTAssertEqual("SLAM", ends.last?.getAttribute(withKey: "title"))

		let contains: HTMLElements = doc.select(cssQuery: "[title*=a]")
		XCTAssertEqual(3, contains.count)
		XCTAssertEqual("Bar", contains.first?.getAttribute(withKey: "title"))
		XCTAssertEqual("SLAM", contains.last?.getAttribute(withKey: "title"))
	}

	func testNamespacedTag()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><abc:def id=1>Hello</abc:def></div> <abc:def class=bold id=2>There</abc:def>")!
		let byTag: HTMLElements = doc.select(cssQuery: "abc|def")
		XCTAssertEqual(2, byTag.count)
		XCTAssertEqual("1", byTag.first?.id)
		XCTAssertEqual("2", byTag.last?.id)

		let byAttr: HTMLElements = doc.select(cssQuery: ".bold")
		XCTAssertEqual(1, byAttr.count)
		XCTAssertEqual("2", byAttr.last?.id)

		let byTagAttr: HTMLElements = doc.select(cssQuery: "abc|def.bold")
		XCTAssertEqual(1, byTagAttr.count)
		XCTAssertEqual("2", byTagAttr.last?.id)

		let byContains: HTMLElements = doc.select(cssQuery: "abc|def:contains(e)")
		XCTAssertEqual(2, byContains.count)
		XCTAssertEqual("1", byContains.first?.id)
		XCTAssertEqual("2", byContains.last?.id)
	}

	func testWildcardNamespacedTag()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><abc:def id=1>Hello</abc:def></div> <abc:def class=bold id=2>There</abc:def>")!
		let byTag: HTMLElements = doc.select(cssQuery: "*|def")
		XCTAssertEqual(2, byTag.count)
		XCTAssertEqual("1", byTag.first?.id)
		XCTAssertEqual("2", byTag.last?.id)

		let byAttr: HTMLElements = doc.select(cssQuery: ".bold")
		XCTAssertEqual(1, byAttr.count)
		XCTAssertEqual("2", byAttr.last?.id)

		let byTagAttr: HTMLElements = doc.select(cssQuery: "*|def.bold")
		XCTAssertEqual(1, byTagAttr.count)
		XCTAssertEqual("2", byTagAttr.last?.id)

		let byContains: HTMLElements = doc.select(cssQuery: "*|def:contains(e)")
		XCTAssertEqual(2, byContains.count)
		XCTAssertEqual("1", byContains.first?.id)
		XCTAssertEqual("2", byContains.last?.id)
	}

	func testByAttributeStarting()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1 data-name=SwiftSoup>Hello</div><p data-val=5 id=2>There</p><p id=3>No</p>")!
		var withData: HTMLElements = doc.select(cssQuery: "[^data-]")
		XCTAssertEqual(2, withData.count)
		XCTAssertEqual("1", withData.first?.id)
		XCTAssertEqual("2", withData.last?.id)

		withData = doc.select(cssQuery: "p[^data-]")
		XCTAssertEqual(1, withData.count)
		XCTAssertEqual("2", withData.first?.id)
	}

	func testByAttributeRegex()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p><img src=foo.png id=1><img src=bar.jpg id=2><img src=qux.JPEG id=3><img src=old.gif><img></p>")!
		let imgs: HTMLElements = doc.select(cssQuery: "img[src~=(?i)\\.(png|jpe?g)]")
		XCTAssertEqual(3, imgs.count)
		XCTAssertEqual("1", imgs.get(index: 0)!.id)
		XCTAssertEqual("2", imgs.get(index: 1)!.id)
		XCTAssertEqual("3", imgs.get(index: 2)!.id)
	}

	func testByAttributeRegexCharacterClass()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p><img src=foo.png id=1><img src=bar.jpg id=2><img src=qux.JPEG id=3><img src=old.gif id=4></p>")!
		let imgs: HTMLElements = doc.select(cssQuery: "img[src~=[o]]")
		XCTAssertEqual(2, imgs.count)
		XCTAssertEqual("1", imgs.get(index: 0)!.id)
		XCTAssertEqual("4", imgs.get(index: 1)!.id)
	}

	func testByAttributeRegexCombined()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><table class=x><td>Hello</td></table></div>")!
		let els: HTMLElements = doc.select(cssQuery: "div table[class~=x|y]")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("Hello", els.text())
	}

	func testCombinedWithContains()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p id=1>One</p><p>Two +</p><p>Three +</p>")!
		let els: HTMLElements = doc.select(cssQuery: "p#1 + :contains(+)")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("Two +", els.text())
		XCTAssertEqual("p", els.first?.tagName)
	}

	func testAllElements()throws {
		let h: String = "<div><p>Hello</p><p><b>there</b></p></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let allDoc: HTMLElements = doc.select(cssQuery: "*")
		let allUnderDiv: HTMLElements = doc.select(cssQuery: "div *")
		XCTAssertEqual(8, allDoc.count)
		XCTAssertEqual(3, allUnderDiv.count)
		XCTAssertEqual("p", allUnderDiv.first?.tagName)
	}

	func testAllWithClass()throws {
		let h: String = "<p class=first>One<p class=first>Two<p>Three"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let ps: HTMLElements = doc.select(cssQuery: "*.first")
		XCTAssertEqual(2, ps.count)
	}

	func testGroupOr()throws {
		let h: String = "<div title=foo /><div title=bar /><div /><p></p><img /><span title=qux>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let els: HTMLElements = doc.select(cssQuery: "p,div,[title]")

		XCTAssertEqual(5, els.count)
		XCTAssertEqual("div", els.get(index: 0)!.tagName)
		XCTAssertEqual("foo", els.get(index: 0)!.getAttribute(withKey: "title"))
		XCTAssertEqual("div", els.get(index: 1)!.tagName)
		XCTAssertEqual("bar", els.get(index: 1)!.getAttribute(withKey: "title"))
		XCTAssertEqual("div", els.get(index: 2)!.tagName)
        XCTAssertTrue(els.get(index: 2)!.getAttribute(withKey: "title") == nil) // missing attributes come back as empty string
		XCTAssertFalse(els.get(index: 2)!.hasAttribute(withKey: "title"))
		XCTAssertEqual("p", els.get(index: 3)!.tagName)
		XCTAssertEqual("span", els.get(index: 4)!.tagName)
	}

	func testGroupOrAttribute()throws {
		let h: String = "<div id=1 /><div id=2 /><div title=foo /><div title=bar />"
        let els: HTMLElements = HTMLParser.parse(h)!.select(cssQuery: "[id],[title=foo]")

		XCTAssertEqual(3, els.count)
		XCTAssertEqual("1", els.get(index: 0)!.id)
		XCTAssertEqual("2", els.get(index: 1)!.id)
		XCTAssertEqual("foo", els.get(index: 2)!.getAttribute(withKey: "title"))
	}

	func testDescendant()throws {
		let h: String = "<div class=head><p class=first>Hello</p><p>There</p></div><p>None</p>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let root: HTMLElement = doc.getElementsByClass("HEAD").first!

		let els: HTMLElements = root.select(cssQuery: ".head p")
		XCTAssertEqual(2, els.count)
		XCTAssertEqual("Hello", els.get(index: 0)!.getText())
		XCTAssertEqual("There", els.get(index: 1)!.getText())

		let p: HTMLElements = root.select(cssQuery: "p.first")
		XCTAssertEqual(1, p.count)
		XCTAssertEqual("Hello", p.get(index: 0)!.getText())

		let empty: HTMLElements = root.select(cssQuery: "p .first") // self, not descend, should not match
		XCTAssertEqual(0, empty.count)

		let aboveRoot: HTMLElements = root.select(cssQuery: "body div.head")
		XCTAssertEqual(0, aboveRoot.count)
	}

	func testAnd()throws {
		let h: String = "<div id=1 class='foo bar' title=bar name=qux><p class=foo title=bar>Hello</p></div"
		let doc: HTMLDocument = HTMLParser.parse(h)!

		let div: HTMLElements = doc.select(cssQuery: "div.foo")
		XCTAssertEqual(1, div.count)
		XCTAssertEqual("div", div.first?.tagName)

		let p: HTMLElements = doc.select(cssQuery: "div .foo") // space indicates like "div *.foo"
		XCTAssertEqual(1, p.count)
		XCTAssertEqual("p", p.first?.tagName)

		let div2: HTMLElements = doc.select(cssQuery: "div#1.foo.bar[title=bar][name=qux]") // very specific!
		XCTAssertEqual(1, div2.count)
		XCTAssertEqual("div", div2.first?.tagName)

		let p2: HTMLElements = doc.select(cssQuery: "div *.foo") // space indicates like "div *.foo"
		XCTAssertEqual(1, p2.count)
		XCTAssertEqual("p", p2.first?.tagName)
	}

	func testDeeperDescendant()throws {
		let h: String = "<div class=head><p><span class=first>Hello</div><div class=head><p class=first><span>Another</span><p>Again</div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let root: HTMLElement = doc.getElementsByClass("head").first!

		let els: HTMLElements = root.select(cssQuery: "div p .first")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("Hello", els.first?.getText())
		XCTAssertEqual("span", els.first?.tagName)

		let aboveRoot: HTMLElements = root.select(cssQuery: "body p .first")
		XCTAssertEqual(0, aboveRoot.count)
	}

	func testParentChildElement()throws {
		let h: String = "<div id=1><div id=2><div id = 3></div></div></div><div id=4></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!

		let divs: HTMLElements = doc.select(cssQuery: "div > div")
		XCTAssertEqual(2, divs.count)
		XCTAssertEqual("2", divs.get(index: 0)!.id) // 2 is child of 1
		XCTAssertEqual("3", divs.get(index: 1)!.id) // 3 is child of 2

		let div2: HTMLElements = doc.select(cssQuery: "div#1 > div")
		XCTAssertEqual(1, div2.count)
		XCTAssertEqual("2", div2.get(index: 0)!.id)
	}

	func testParentWithClassChild()throws {
		let h: String = "<h1 class=foo><a href=1 /></h1><h1 class=foo><a href=2 class=bar /></h1><h1><a href=3 /></h1>"
		let doc: HTMLDocument = HTMLParser.parse(h)!

		let allAs: HTMLElements = doc.select(cssQuery: "h1 > a")
		XCTAssertEqual(3, allAs.count)
		XCTAssertEqual("a", allAs.first?.tagName)

		let fooAs: HTMLElements = doc.select(cssQuery: "h1.foo > a")
		XCTAssertEqual(2, fooAs.count)
		XCTAssertEqual("a", fooAs.first?.tagName)

		let barAs: HTMLElements = doc.select(cssQuery: "h1.foo > a.bar")
		XCTAssertEqual(1, barAs.count)
	}

	func testParentChildStar()throws {
		let h: String = "<div id=1><p>Hello<p><b>there</b></p></div><div id=2><span>Hi</span></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let divChilds: HTMLElements = doc.select(cssQuery: "div > *")
		XCTAssertEqual(3, divChilds.count)
		XCTAssertEqual("p", divChilds.get(index: 0)!.tagName)
		XCTAssertEqual("p", divChilds.get(index: 1)!.tagName)
		XCTAssertEqual("span", divChilds.get(index: 2)!.tagName)
	}

	func testMultiChildDescent()throws {
		let h: String = "<div id=foo><h1 class=bar><a href=http://example.com/>One</a></h1></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let els: HTMLElements = doc.select(cssQuery: "div#foo > h1.bar > a[href*=example]")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("a", els.first?.tagName)
	}

	func testCaseInsensitive()throws {
		let h: String = "<dIv tItle=bAr><div>" // mixed case so a simple toLowerCase() on value doesn't catch
		let doc: HTMLDocument = HTMLParser.parse(h)!

		XCTAssertEqual(2, doc.select(cssQuery: "DIV").count)
		XCTAssertEqual(1, doc.select(cssQuery: "DIV[TITLE]").count)
		XCTAssertEqual(1, doc.select(cssQuery: "DIV[TITLE=BAR]").count)
		XCTAssertEqual(0, doc.select(cssQuery: "DIV[TITLE=BARBARELLA").count)
	}

	func testAdjacentSiblings()throws {
		let h: String = "<ol><li>One<li>Two<li>Three</ol>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let sibs: HTMLElements = doc.select(cssQuery: "li + li")
		XCTAssertEqual(2, sibs.count)
		XCTAssertEqual("Two", sibs.get(index: 0)!.getText())
		XCTAssertEqual("Three", sibs.get(index: 1)!.getText())
	}

	func testAdjacentSiblingsWithId()throws {
		let h: String = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let sibs: HTMLElements = doc.select(cssQuery: "li#1 + li#2")
		XCTAssertEqual(1, sibs.count)
		XCTAssertEqual("Two", sibs.get(index: 0)!.getText())
	}

	func testNotAdjacent()throws {
		let h: String = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let sibs: HTMLElements = doc.select(cssQuery: "li#1 + li#3")
		XCTAssertEqual(0, sibs.count)
	}

	func testMixCombinator()throws {
		let h: String = "<div class=foo><ol><li>One<li>Two<li>Three</ol></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let sibs: HTMLElements = doc.select(cssQuery: "body > div.foo li + li")

		XCTAssertEqual(2, sibs.count)
		XCTAssertEqual("Two", sibs.get(index: 0)!.getText())
		XCTAssertEqual("Three", sibs.get(index: 1)!.getText())
	}

	func testMixCombinatorGroup()throws {
		let h: String = "<div class=foo><ol><li>One<li>Two<li>Three</ol></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let els: HTMLElements = doc.select(cssQuery: ".foo > ol, ol > li + li")

		XCTAssertEqual(3, els.count)
		XCTAssertEqual("ol", els.get(index: 0)!.tagName)
		XCTAssertEqual("Two", els.get(index: 1)!.getText())
		XCTAssertEqual("Three", els.get(index: 2)!.getText())
	}

	func testGeneralSiblings()throws {
		let h: String = "<ol><li id=1>One<li id=2>Two<li id=3>Three</ol>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let els: HTMLElements = doc.select(cssQuery: "#1 ~ #3")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("Three", els.first?.getText())
	}

	// for http://github.com/jhy/jsoup/issues#issue/10
	func testCharactersInIdAndClass()throws {
		// using CSS spec for identifiers (id and class): a-z0-9, -, _. NOT . (which is OK in html spec, but not css)
		let h: String = "<div><p id='a1-foo_bar'>One</p><p class='b2-qux_bif'>Two</p></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!

		let el1: HTMLElement = doc.getElementById("a1-foo_bar")!
		XCTAssertEqual("One", el1.getText())
		let el2: HTMLElement = doc.getElementsByClass("b2-qux_bif").first!
		XCTAssertEqual("Two", el2.getText())

		let el3: HTMLElement = doc.select(cssQuery: "#a1-foo_bar").first!
		XCTAssertEqual("One", el3.getText())
		let el4: HTMLElement = doc.select(cssQuery: ".b2-qux_bif").first!
		XCTAssertEqual("Two", el4.getText())
	}

	// for http://github.com/jhy/jsoup/issues#issue/13
	func testSupportsLeadingCombinator()throws {
		var h: String = "<div><p><span>One</span><span>Two</span></p></div>"
		var doc: HTMLDocument = HTMLParser.parse(h)!

		let p: HTMLElement = doc.select(cssQuery: "div > p").first!
		let spans: HTMLElements = p.select(cssQuery: "> span")
		XCTAssertEqual(2, spans.count)
		XCTAssertEqual("One", spans.first?.getText())

		// make sure doesn't get nested
		h = "<div id=1><div id=2><div id=3></div></div></div>"
		doc = HTMLParser.parse(h)!
		let div: HTMLElement = doc.select(cssQuery: "div").select(cssQuery: " > div").first!
		XCTAssertEqual("2", div.id)
	}

	func testPseudoLessThan()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>")!
		let ps: HTMLElements = doc.select(cssQuery: "div p:lt(2)")
		XCTAssertEqual(3, ps.count)
		XCTAssertEqual("One", ps.get(index: 0)!.getText())
		XCTAssertEqual("Two", ps.get(index: 1)!.getText())
		XCTAssertEqual("Four", ps.get(index: 2)!.getText())
	}

	func testPseudoGreaterThan()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One</p><p>Two</p><p>Three</p></div><div><p>Four</p>")!
		let ps: HTMLElements = doc.select(cssQuery: "div p:gt(0)")
		XCTAssertEqual(2, ps.count)
		XCTAssertEqual("Two", ps.get(index: 0)!.getText())
		XCTAssertEqual("Three", ps.get(index: 1)!.getText())
	}

	func testPseudoEquals()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>")!
		let ps: HTMLElements = doc.select(cssQuery: "div p:eq(0)")
		XCTAssertEqual(2, ps.count)
		XCTAssertEqual("One", ps.get(index: 0)!.getText())
		XCTAssertEqual("Four", ps.get(index: 1)!.getText())

		let ps2: HTMLElements = doc.select(cssQuery: "div:eq(0) p:eq(0)")
		XCTAssertEqual(1, ps2.count)
		XCTAssertEqual("One", ps2.get(index: 0)!.getText())
		XCTAssertEqual("p", ps2.get(index: 0)!.tagName)
	}

	func testPseudoBetween()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>One</p><p>Two</p><p>Three</>p></div><div><p>Four</p>")!
		let ps: HTMLElements = doc.select(cssQuery: "div p:gt(0):lt(2)")
		XCTAssertEqual(1, ps.count)
		XCTAssertEqual("Two", ps.get(index: 0)!.getText())
	}

	func testPseudoCombined()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div class='foo'><p>One</p><p>Two</p></div><div><p>Three</p><p>Four</p></div>")!
		let ps: HTMLElements = doc.select(cssQuery: "div.foo p:gt(0)")
		XCTAssertEqual(1, ps.count)
		XCTAssertEqual("Two", ps.get(index: 0)!.getText())
	}

	func testPseudoHas()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=0><p><span>Hello</span></p></div> <div id=1><span class=foo>There</span></div> <div id=2><p>Not</p></div>")!

		let divs1: HTMLElements = doc.select(cssQuery: "div:has(span)")
		XCTAssertEqual(2, divs1.count)
		XCTAssertEqual("0", divs1.get(index: 0)!.id)
		XCTAssertEqual("1", divs1.get(index: 1)!.id)

		let divs2: HTMLElements = doc.select(cssQuery: "div:has([class]")
		XCTAssertEqual(1, divs2.count)
		XCTAssertEqual("1", divs2.get(index: 0)!.id)

		let divs3: HTMLElements = doc.select(cssQuery: "div:has(span, p)")
		XCTAssertEqual(3, divs3.count)
		XCTAssertEqual("0", divs3.get(index: 0)!.id)
		XCTAssertEqual("1", divs3.get(index: 1)!.id)
		XCTAssertEqual("2", divs3.get(index: 2)!.id)

		let els1: HTMLElements = doc.body!.select(cssQuery: ":has(p)")
		XCTAssertEqual(3, els1.count) // body, div, dib
		XCTAssertEqual("body", els1.first?.tagName)
		XCTAssertEqual("0", els1.get(index: 1)!.id)
		XCTAssertEqual("2", els1.get(index: 2)!.id)
	}

	func testNestedHas()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p><span>One</span></p></div> <div><p>Two</p></div>")!
		var divs: HTMLElements = doc.select(cssQuery: "div:has(p:has(span))")
		XCTAssertEqual(1, divs.count)
		XCTAssertEqual("One", divs.first?.getText())

		// test matches in has
		divs = doc.select(cssQuery: "div:has(p:matches((?i)two))")
		XCTAssertEqual(1, divs.count)
		XCTAssertEqual("div", divs.first?.tagName)
		XCTAssertEqual("Two", divs.first?.getText())

		// test contains in has
		divs = doc.select(cssQuery: "div:has(p:contains(two))")
		XCTAssertEqual(1, divs.count)
		XCTAssertEqual("div", divs.first?.tagName)
		XCTAssertEqual("Two", divs.first?.getText())
	}

	func testPseudoContains()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>The Rain.</p> <p class=light>The <i>rain</i>.</p> <p>Rain, the.</p></div>")!

		let ps1: HTMLElements = doc.select(cssQuery: "p:contains(Rain)")
		XCTAssertEqual(3, ps1.count)

		let ps2: HTMLElements = doc.select(cssQuery: "p:contains(the rain)")
		XCTAssertEqual(2, ps2.count)
		XCTAssertEqual("The Rain.", ps2.first?.html)
		XCTAssertEqual("The <i>rain</i>.", ps2.last?.html)

		let ps3: HTMLElements = doc.select(cssQuery: "p:contains(the Rain):has(i)")
		XCTAssertEqual(1, ps3.count)
		XCTAssertEqual("light", ps3.first?.className)

		let ps4: HTMLElements = doc.select(cssQuery: ".light:contains(rain)")
		XCTAssertEqual(1, ps4.count)
		XCTAssertEqual("light", ps3.first?.className)

		let ps5: HTMLElements = doc.select(cssQuery: ":contains(rain)")
		XCTAssertEqual(8, ps5.count) // html, body, div,...
	}

	func testPsuedoContainsWithParentheses()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p id=1>This (is good)</p><p id=2>This is bad)</p>")!

		let ps1: HTMLElements = doc.select(cssQuery: "p:contains(this (is good))")
		XCTAssertEqual(1, ps1.count)
		XCTAssertEqual("1", ps1.first?.id)

		let ps2: HTMLElements = doc.select(cssQuery: "p:contains(this is bad\\))")
		XCTAssertEqual(1, ps2.count)
		XCTAssertEqual("2", ps2.first?.id)
	}

	func testContainsOwn()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p id=1>Hello <b>there</b> now</p>")!
		let ps: HTMLElements = doc.select(cssQuery: "p:containsOwn(Hello now)")
		XCTAssertEqual(1, ps.count)
		XCTAssertEqual("1", ps.first?.id)

		XCTAssertEqual(0, doc.select(cssQuery: "p:containsOwn(there)").count)
	}

	func testMatches()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p id=1>The <i>Rain</i></p> <p id=2>There are 99 bottles.</p> <p id=3>Harder (this)</p> <p id=4>Rain</p>")!

		let p1: HTMLElements = doc.select(cssQuery: "p:matches(The rain)") // no match, case sensitive
		XCTAssertEqual(0, p1.count)

		let p2: HTMLElements = doc.select(cssQuery: "p:matches((?i)the rain)") // case insense. should include root, html, body
		XCTAssertEqual(1, p2.count)
		XCTAssertEqual("1", p2.first?.id)

		let p4: HTMLElements = doc.select(cssQuery: "p:matches((?i)^rain$)") // bounding
		XCTAssertEqual(1, p4.count)
		XCTAssertEqual("4", p4.first?.id)

		let p5: HTMLElements = doc.select(cssQuery: "p:matches(\\d+)")
		XCTAssertEqual(1, p5.count)
		XCTAssertEqual("2", p5.first?.id)

		let p6: HTMLElements = doc.select(cssQuery: "p:matches(\\w+\\s+\\(\\w+\\))") // test bracket matching
		XCTAssertEqual(1, p6.count)
		XCTAssertEqual("3", p6.first?.id)

		let p7: HTMLElements = doc.select(cssQuery: "p:matches((?i)the):has(i)") // multi
		XCTAssertEqual(1, p7.count)
		XCTAssertEqual("1", p7.first?.id)
	}

	func testMatchesOwn()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p id=1>Hello <b>there</b> now</p>")!

		let p1: HTMLElements = doc.select(cssQuery: "p:matchesOwn((?i)hello now)")
		XCTAssertEqual(1, p1.count)
		XCTAssertEqual("1", p1.first?.id)

		XCTAssertEqual(0, doc.select(cssQuery: "p:matchesOwn(there)").count)
	}

	func testRelaxedTags()throws {
		let doc: HTMLDocument = HTMLParser.parse("<abc_def id=1>Hello</abc_def> <abc-def id=2>There</abc-def>")!

		let el1: HTMLElements = doc.select(cssQuery: "abc_def")
		XCTAssertEqual(1, el1.count)
		XCTAssertEqual("1", el1.first?.id)

		let el2: HTMLElements = doc.select(cssQuery: "abc-def")
		XCTAssertEqual(1, el2.count)
		XCTAssertEqual("2", el2.first?.id)
	}

	func testNotParas()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p id=1>One</p> <p>Two</p> <p><span>Three</span></p>")!

		let el1: HTMLElements = doc.select(cssQuery: "p:not([id=1])")
		XCTAssertEqual(2, el1.count)
		XCTAssertEqual("Two", el1.first?.getText())
		XCTAssertEqual("Three", el1.last?.getText())

		let el2: HTMLElements = doc.select(cssQuery: "p:not(:has(span))")
		XCTAssertEqual(2, el2.count)
		XCTAssertEqual("One", el2.first?.getText())
		XCTAssertEqual("Two", el2.last?.getText())
	}

	func testNotAll()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p>Two</p> <p><span>Three</span></p>")!

		let el1: HTMLElements = doc.body!.select(cssQuery: ":not(p)") // should just be the span
		XCTAssertEqual(2, el1.count)
		XCTAssertEqual("body", el1.first?.tagName)
		XCTAssertEqual("span", el1.last?.tagName)
	}

	func testNotClass()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div class=left>One</div><div class=right id=1><p>Two</p></div>")!

		let el1: HTMLElements = doc.select(cssQuery: "div:not(.left)")
		XCTAssertEqual(1, el1.count)
		XCTAssertEqual("1", el1.first?.id)
	}

	func testHandlesCommasInSelector()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p name='1,2'>One</p><div>Two</div><ol><li>123</li><li>Text</li></ol>")!

		let ps: HTMLElements = doc.select(cssQuery: "[name=1,2]")
		XCTAssertEqual(1, ps.count)

		let containers: HTMLElements = doc.select(cssQuery: "div, li:matches([0-9,]+)")
		XCTAssertEqual(2, containers.count)
		XCTAssertEqual("div", containers.get(index: 0)!.tagName)
		XCTAssertEqual("li", containers.get(index: 1)!.tagName)
		XCTAssertEqual("123", containers.get(index: 1)!.getText())
	}

	func testSelectSupplementaryCharacter()throws {
		#if !os(Linux)
			let s = String(Character(UnicodeScalar(135361)!))
			let doc: HTMLDocument = HTMLParser.parse("<div k" + s + "='" + s + "'>^" + s + "$/div>")!
			XCTAssertEqual("div", doc.select(cssQuery: "div[k" + s + "]").first?.tagName)
			XCTAssertEqual("div", doc.select(cssQuery: "div:containsOwn(" + s + ")").first?.tagName)
		#endif
	}

	func testSelectClassWithSpace()throws {
		 let html: String = "<div class=\"value\">class without space</div>\n"
			+ "<div class=\"value \">class with space</div>"

		let doc: HTMLDocument = HTMLParser.parse(html)!

		var found: HTMLElements = doc.select(cssQuery: "div[class=value ]")
		XCTAssertEqual(2, found.count)
		XCTAssertEqual("class without space", found.get(index: 0)!.getText())
		XCTAssertEqual("class with space", found.get(index: 1)!.getText())

		found = doc.select(cssQuery: "div[class=\"value \"]")
		XCTAssertEqual(2, found.count)
		XCTAssertEqual("class without space", found.get(index: 0)!.getText())
		XCTAssertEqual("class with space", found.get(index: 1)!.getText())

		found = doc.select(cssQuery: "div[class=\"value\\ \"]")
		XCTAssertEqual(0, found.count)
	}

	func testSelectSameElements()throws {
		let html: String = "<div>one</div><div>one</div>"

		let doc: HTMLDocument = HTMLParser.parse(html)!
		let els: HTMLElements = doc.select(cssQuery: "div")
		XCTAssertEqual(2, els.count)

		let subSelect: HTMLElements = els.select(cssQuery: ":contains(one)")
		XCTAssertEqual(2, subSelect.count)
	}

	func testAttributeWithBrackets()throws {
		let html: String = "<div data='End]'>One</div> <div data='[Another)]]'>Two</div>"
		let doc: HTMLDocument = HTMLParser.parse(html)!
		_ = doc.select(cssQuery: "div[data='End]'")
		XCTAssertEqual("One", doc.select(cssQuery: "div[data='End]'").first?.getText())
		XCTAssertEqual("Two", doc.select(cssQuery: "div[data='[Another)]]'").first?.getText())
		XCTAssertEqual("One", doc.select(cssQuery: "div[data=\"End]\"").first?.getText())
		XCTAssertEqual("Two", doc.select(cssQuery: "div[data=\"[Another)]]\"").first?.getText())
	}

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testByTag", testByTag),
			("testById", testById),
			("testByClass", testByClass),
			("testByAttribute", testByAttribute),
			("testNamespacedTag", testNamespacedTag),
			("testWildcardNamespacedTag", testWildcardNamespacedTag),
			("testByAttributeStarting", testByAttributeStarting),
			("testByAttributeRegex", testByAttributeRegex),
			("testByAttributeRegexCharacterClass", testByAttributeRegexCharacterClass),
			("testByAttributeRegexCombined", testByAttributeRegexCombined),
			("testCombinedWithContains", testCombinedWithContains),
			("testAllElements", testAllElements),
			("testAllWithClass", testAllWithClass),
			("testGroupOr", testGroupOr),
			("testGroupOrAttribute", testGroupOrAttribute),
			("testDescendant", testDescendant),
			("testAnd", testAnd),
			("testDeeperDescendant", testDeeperDescendant),
			("testParentChildElement", testParentChildElement),
			("testParentWithClassChild", testParentWithClassChild),
			("testParentChildStar", testParentChildStar),
			("testMultiChildDescent", testMultiChildDescent),
			("testCaseInsensitive", testCaseInsensitive),
			("testAdjacentSiblings", testAdjacentSiblings),
			("testAdjacentSiblingsWithId", testAdjacentSiblingsWithId),
			("testNotAdjacent", testNotAdjacent),
			("testMixCombinator", testMixCombinator),
			("testMixCombinatorGroup", testMixCombinatorGroup),
			("testGeneralSiblings", testGeneralSiblings),
			("testCharactersInIdAndClass", testCharactersInIdAndClass),
			("testSupportsLeadingCombinator", testSupportsLeadingCombinator),
			("testPseudoLessThan", testPseudoLessThan),
			("testPseudoGreaterThan", testPseudoGreaterThan),
			("testPseudoEquals", testPseudoEquals),
			("testPseudoBetween", testPseudoBetween),
			("testPseudoCombined", testPseudoCombined),
			("testPseudoHas", testPseudoHas),
			("testNestedHas", testNestedHas),
			("testPseudoContains", testPseudoContains),
			("testPsuedoContainsWithParentheses", testPsuedoContainsWithParentheses),
			("testContainsOwn", testContainsOwn),
			("testMatches", testMatches),
			("testMatchesOwn", testMatchesOwn),
			("testRelaxedTags", testRelaxedTags),
			("testNotParas", testNotParas),
			("testNotAll", testNotAll),
			("testNotClass", testNotClass),
			("testHandlesCommasInSelector", testHandlesCommasInSelector),
			("testSelectSupplementaryCharacter", testSelectSupplementaryCharacter),
			("testSelectClassWithSpace", testSelectClassWithSpace),
			("testSelectSameElements", testSelectSameElements),
			("testAttributeWithBrackets", testAttributeWithBrackets)
		]
	}()

}
