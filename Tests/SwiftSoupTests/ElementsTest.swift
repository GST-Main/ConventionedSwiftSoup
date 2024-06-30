//
//  ElementsTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 12/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//
/**
Tests for ElementList.
*/
import XCTest
import PrettySwiftSoup
class ElementsTest: XCTestCase {

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testFilter()throws {
		let h: String = "<p>Excl</p><div class=headline><p>Hello</p><p>There</p></div><div class=headline><h1>Headline</h1></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let els: HTMLElements = doc.select(cssQuery: ".headline").select(cssQuery: "p")
		XCTAssertEqual(2, els.count)
        XCTAssertEqual("Hello", els.get(index: 0)!.getText())
        XCTAssertEqual("There", els.get(index: 1)!.getText())
	}

	func testRandomAccessCollection()throws {
		let h: String = "<div><p>one</p><div class=headline><p>two</p><p>three</p></div><p>four</p></div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let els: HTMLElements = doc.select(cssQuery: "p")
		XCTAssertEqual(els.count, 4)
		for i in (els.startIndex ..< els.endIndex).shuffled() {
			let el = els[i]
			XCTAssertEqual(el.tag.getName(), "p")
		}
	}

	func testAttributes()throws {
		let h = "<p title=foo><p title=bar><p class=foo><p class=bar>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let withTitle: HTMLElements = doc.select(cssQuery: "p[title]")
		XCTAssertEqual(2, withTitle.count)
        XCTAssertTrue(withTitle.hasAttribute(key: "title"))
		XCTAssertFalse(withTitle.hasAttribute(key: "class"))
	}

	func testHasAttr()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p title=foo><p title=bar><p class=foo><p class=bar>")!
		let ps: HTMLElements = doc.select(cssQuery: "p")
		XCTAssertTrue(ps.hasAttribute(key: "class"))
		XCTAssertFalse(ps.hasAttribute(key: "style"))
	}

	func testHasAbsAttr()throws {
		let doc: HTMLDocument = HTMLParser.parse("<a id=1 href='/foo'>One</a> <a id=2 href='https://google.com'>Two</a>")!
		let one: HTMLElements = doc.select(cssQuery: "#1")
		let two: HTMLElements = doc.select(cssQuery: "#2")
		let both: HTMLElements = doc.select(cssQuery: "a")
		XCTAssertFalse(one.hasAttribute(key: "abs:href"))
		XCTAssertTrue(two.hasAttribute(key: "abs:href"))
		XCTAssertTrue(both.hasAttribute(key: "abs:href")) // hits on #2
	}

	func testClasses()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p class='mellow yellow'></p><p class='red green'></p>")!

		let els: HTMLElements = doc.select(cssQuery: "p")
        XCTAssertTrue(els.hasClass(named: "red"))
        XCTAssertFalse(els.hasClass(named: "blue"))
	}

	func testText()throws {
		let h = "<div><p>Hello<p>there<p>world</div>"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		XCTAssertEqual("Hello there world", doc.select(cssQuery: "div > *").text())
	}
    
    // TODO: texts test

	func testHasText()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p></div><div><p></p></div>")!
		let divs: HTMLElements = doc.select(cssQuery: "div")
		XCTAssertTrue(divs.hasText)
		XCTAssertFalse(doc.select(cssQuery: "div + div").hasText)
	}

	func testHtml()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p></div><div><p>There</p></div>")!
		let divs: HTMLElements = doc.select(cssQuery: "div")
		XCTAssertEqual("<p>Hello</p>\n<p>There</p>", divs.html)
	}

	func testOuterHtml()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p></div><div><p>There</p></div>")!
		let divs: HTMLElements = doc.select(cssQuery: "div")
		XCTAssertEqual("<div><p>Hello</p></div><div><p>There</p></div>", TextUtil.stripNewlines(divs.outerHtml!))
	}

	func testVal()throws {
        guard let doc = HTMLParser.parse("<input value='one' /><textarea>two</textarea>") else {
            XCTFail("Failed to parse")
            return
        }

        let els: HTMLElements = doc.select(cssQuery: "input, textarea")
		XCTAssertEqual(2, els.count)
		XCTAssertEqual("two", els.last?.value)
	}

	func testIs()throws {
		let h = "<p>Hello<p title=foo>there<p>world"
		let doc: HTMLDocument = HTMLParser.parse(h)!
		let ps: HTMLElements = doc.select(cssQuery: "p")
		XCTAssertTrue(ps.hasElementMatchedWithCSSQuery("[title=foo]"))
		XCTAssertFalse(ps.hasElementMatchedWithCSSQuery("[title=bar]"))
	}

	func testNot()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div id=1><p>One</p></div> <div id=2><p><span>Two</span></p></div>")!

		let div1: HTMLElements = doc.select(cssQuery: "div").selectNot(cssQuery: ":has(p > span)")
		XCTAssertEqual(1, div1.count)
		XCTAssertEqual("1", div1.first?.id)

		let div2: HTMLElements = doc.select(cssQuery: "div").selectNot(cssQuery: "#1")
		XCTAssertEqual(1, div2.count)
		XCTAssertEqual("2", div2.first?.id)
	}

	func testTraverse()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p></div><div>There</div>")!
		let accum: StringBuilder = StringBuilder()

		class nv: NodeVisitor {
			let accum: StringBuilder
			init(_ accum: StringBuilder) {
				self.accum = accum
			}
			public func head(_ node: Node, _ depth: Int) {
				accum.append("<" + node.nodeName + ">")
			}
			public func tail(_ node: Node, _ depth: Int) {
				accum.append("</" + node.nodeName + ">")
			}
		}
		try doc.select(cssQuery: "div").traverse(nv(accum))
		XCTAssertEqual("<div><p><#text></#text></p></div><div><#text></#text></div>", accum.toString())
	}

	func testForms()throws {
        let doc: HTMLDocument = HTMLParser.parse("<form id=1><input name=q></form><div /><form id=2><input name=f></form>")!
		let els: HTMLElements = doc.select(cssQuery: "*")
		XCTAssertEqual(9, els.count)

		let forms: Array<FormElement> = els.forms()
		XCTAssertEqual(2, forms.count)
		//XCTAssertTrue(forms[0] != nil)
		//XCTAssertTrue(forms[1] != nil)
        XCTAssertEqual("1", forms[0].id)
		XCTAssertEqual("2", forms[1].id)
	}

	func testClassWithHyphen()throws {
		let doc: HTMLDocument = HTMLParser.parse("<p class='tab-nav'>Check</p>")!
		let els: HTMLElements = doc.getElementsByClass("tab-nav")
		XCTAssertEqual(1, els.count)
		XCTAssertEqual("Check", els.text())
	}
    
    func testEachText()throws {
        let doc: HTMLDocument = HTMLParser.parse("<div><p>1<p>2<p>3<p>4<p>5<p>6</div><div><p>7<p>8<p>9<p>10<p>11<p>12<p></p></div>")!
        let divText = doc.select(cssQuery: "div").texts;
        XCTAssertEqual(2, divText.count);
        XCTAssertEqual("1 2 3 4 5 6", divText[0]);
        XCTAssertEqual("7 8 9 10 11 12", divText[1]);
        
        let pText: Array<String> = doc.select(cssQuery: "p").texts;
        let ps: HTMLElements = doc.select(cssQuery: "p");
        XCTAssertEqual(13, ps.count);
        XCTAssertEqual(12, pText.count); // not 13, as last doesn't have text
        XCTAssertEqual("1", pText[0]);
        XCTAssertEqual("2", pText[1]);
        XCTAssertEqual("5", pText[4]);
        XCTAssertEqual("7", pText[6]);
        XCTAssertEqual("12", pText[11]);
    }

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testFilter", testFilter),
			("testRandomAccessCollection", testRandomAccessCollection),
			("testAttributes", testAttributes),
			("testHasAttr", testHasAttr),
			("testHasAbsAttr", testHasAbsAttr),
			("testClasses", testClasses),
			("testText", testText),
			("testHasText", testHasText),
			("testHtml", testHtml),
			("testOuterHtml", testOuterHtml),
			("testVal", testVal),
			("testIs", testIs),
			("testNot", testNot),
			("testTraverse", testTraverse),
			("testForms", testForms),
			("testClassWithHyphen", testClassWithHyphen),
            ("testEachText", testEachText)
		]
	}()
}
