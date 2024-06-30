//
//  AttributeParseTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 10/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//
/**
Test suite for attribute parser.
*/

import XCTest
import PrettySwiftSoup

class AttributeParseTest: XCTestCase {

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testparsesRoughAttributeString()throws {
		let html: String = "<a id=\"123\" class=\"baz = 'bar'\" style = 'border: 2px'qux zim foo = 12 mux=18 />"
		// should be: <id=123>, <class=baz = 'bar'>, <qux=>, <zim=>, <foo=12>, <mux.=18>

		let el: Element = HTMLParser.parseHTML(html)!.getElementsByTag("a").get(index: 0)!
		let attr: Attributes = el.getAttributes()!
		XCTAssertEqual(7, attr.size())
		XCTAssertEqual("123", attr.get(key: "id"))
		XCTAssertEqual("baz = 'bar'", attr.get(key: "class"))
		XCTAssertEqual("border: 2px", attr.get(key: "style"))
		XCTAssertEqual("", attr.get(key: "qux"))
		XCTAssertEqual("", attr.get(key: "zim"))
		XCTAssertEqual("12", attr.get(key: "foo"))
		XCTAssertEqual("18", attr.get(key: "mux"))
	}

	func testhandlesNewLinesAndReturns()throws {
		let html: String = "<a\r\nfoo='bar\r\nqux'\r\nbar\r\n=\r\ntwo>One</a>"
		let el: Element = HTMLParser.parseHTML(html)!.select(cssQuery: "a").first!
		XCTAssertEqual(2, el.getAttributes()?.size())
		XCTAssertEqual("bar\r\nqux", el.getAttribute(withKey: "foo")) // currently preserves newlines in quoted attributes. todo confirm if should.
		XCTAssertEqual("two", el.getAttribute(withKey: "bar"))
	}

	func testparsesEmptyString()throws {
		let html: String = "<a />"
		let el: Element = HTMLParser.parseHTML(html)!.getElementsByTag("a").get(index: 0)!
		let attr: Attributes = el.getAttributes()!
		XCTAssertEqual(0, attr.size())
	}

	func testcanStartWithEq()throws {
		let html: String = "<a =empty />"
		let el: Element = HTMLParser.parseHTML(html)!.getElementsByTag("a").get(index: 0)!
		let attr: Attributes = el.getAttributes()!
		XCTAssertEqual(1, attr.size())
		XCTAssertTrue(attr.hasKey(key: "=empty"))
		XCTAssertEqual("", attr.get(key: "=empty"))
	}

	func teststrictAttributeUnescapes()throws {
		let html: String = "<a id=1 href='?foo=bar&mid&lt=true'>One</a> <a id=2 href='?foo=bar&lt;qux&lg=1'>Two</a>"
		let els: Elements = HTMLParser.parseHTML(html)!.select(cssQuery: "a")
		XCTAssertEqual("?foo=bar&mid&lt=true", els.first!.getAttribute(withKey: "href"))
		XCTAssertEqual("?foo=bar<qux&lg=1", els.last!.getAttribute(withKey: "href"))
	}

	func testmoreAttributeUnescapes()throws {
		let html: String = "<a href='&wr_id=123&mid-size=true&ok=&wr'>Check</a>"
		let els: Elements = HTMLParser.parseHTML(html)!.select(cssQuery: "a")
		XCTAssertEqual("&wr_id=123&mid-size=true&ok=&wr",  els.first!.getAttribute(withKey: "href"))
	}

	func testparsesBooleanAttributes()throws {
		let html: String = "<a normal=\"123\" boolean empty=\"\"></a>"
		let el: Element = HTMLParser.parseHTML(html)!.select(cssQuery: "a").first!

		XCTAssertEqual("123", el.getAttribute(withKey: "normal"))
		XCTAssertEqual(nil, el.getAttribute(withKey: "boolean"))
		XCTAssertEqual(nil, el.getAttribute(withKey: "empty"))

		let attributes: Array<Attribute> = el.getAttributes()!.asList()
		XCTAssertEqual(3, attributes.count, "There should be 3 attribute present")

		// Assuming the list order always follows the parsed html
		XCTAssertFalse((attributes[0] as? BooleanAttribute) != nil, "'normal' attribute should not be boolean")
		XCTAssertTrue((attributes[1] as? BooleanAttribute) != nil, "'boolean' attribute should be boolean")
		XCTAssertFalse((attributes[2] as? BooleanAttribute) != nil, "'empty' attribute should not be boolean")

		XCTAssertEqual(html, el.outerHTML)
	}

	func testdropsSlashFromAttributeName()throws {
		let html: String = "<img /onerror='doMyJob'/>"
		var doc: Document = HTMLParser.parseHTML(html)!
		XCTAssertTrue(doc.select(cssQuery: "img[onerror]").count != 0, "SelfClosingStartTag ignores last character")
		XCTAssertEqual("<img onerror=\"doMyJob\">", doc.body!.html)

        doc = try HTMLParser.xmlParser().parseHTML(html, baseURI: "")
		XCTAssertEqual("<img onerror=\"doMyJob\" />", doc.html)
	}

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testparsesRoughAttributeString", testparsesRoughAttributeString),
			("testhandlesNewLinesAndReturns", testhandlesNewLinesAndReturns),
			("testparsesEmptyString", testparsesEmptyString),
			("testcanStartWithEq", testcanStartWithEq),
			("teststrictAttributeUnescapes", teststrictAttributeUnescapes),
			("testmoreAttributeUnescapes", testmoreAttributeUnescapes),
			("testparsesBooleanAttributes", testparsesBooleanAttributes),
			("testdropsSlashFromAttributeName", testdropsSlashFromAttributeName)
		]
	}()

}
