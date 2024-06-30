//
//  TextNodeTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 09/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//

import XCTest
@testable import PrettySwiftSoup

class TextNodeTest: XCTestCase {

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testBlank() {
		let one = TextNode("", "")
		let two = TextNode("     ", "")
		let three = TextNode("  \n\n   ", "")
		let four = TextNode("Hello", "")
		let five = TextNode("  \nHello ", "")

		XCTAssertTrue(one.isBlank())
		XCTAssertTrue(two.isBlank())
		XCTAssertTrue(three.isBlank())
		XCTAssertFalse(four.isBlank())
		XCTAssertFalse(five.isBlank())
	}

	func testTextBean()throws {
		let doc = HTMLParser.parse("<p>One <span>two &amp;</span> three &amp;</p>")!
		let p: Element = doc.select(cssQuery: "p").first!

		let span: Element = doc.select(cssQuery: "span").first!
		XCTAssertEqual("two &", span.getText())
		let spanText: TextNode =  span.childNode(0) as! TextNode
		XCTAssertEqual("two &", spanText.text())

		let tn: TextNode = p.childNode(2) as! TextNode
		XCTAssertEqual(" three &", tn.text())

		tn.text(" POW!")
		XCTAssertEqual("One <span>two &amp;</span> POW!", TextUtil.stripNewlines(p.html!))

		try _ = tn.setAttribute(withKey: "text", newValue: "kablam &")
		XCTAssertEqual("kablam &", tn.text())
		XCTAssertEqual("One <span>two &amp;</span>kablam &amp;", TextUtil.stripNewlines(p.html!))
	}

	func testSplitText()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div>Hello there</div>")!
		let div: Element = doc.select(cssQuery: "div").first!
		let tn: TextNode =  div.childNode(0) as! TextNode
		let tail: TextNode = try tn.splitText(6)
		XCTAssertEqual("Hello ", tn.getWholeText())
		XCTAssertEqual("there", tail.getWholeText())
		tail.text("there!")
		XCTAssertEqual("Hello there!", div.getText())
		XCTAssertTrue(tn.parent == tail.parent)
	}

	func testSplitAnEmbolden()throws {
		let doc: HTMLDocument = HTMLParser.parse("<div>Hello there</div>")!
		let div: Element = doc.select(cssQuery: "div").first!
		let tn: TextNode = div.childNode(0) as! TextNode
		let tail: TextNode = try  tn.splitText(6)
		try tail.wrap(html: "<b></b>")

		XCTAssertEqual("Hello <b>there</b>", TextUtil.stripNewlines(div.html!)) // not great that we get \n<b>there there... must correct
	}

	func testWithSupplementaryCharacter()throws {
		#if !os(Linux)
			let doc: HTMLDocument = HTMLParser.parse(String(Character(UnicodeScalar(135361)!)))!
			let t: TextNode = doc.body!.textNodes[0]
			XCTAssertEqual(String(Character(UnicodeScalar(135361)!)), t.outerHTML!.trim())
		#endif
	}

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testBlank", testBlank),
			("testTextBean", testTextBean),
			("testSplitText", testSplitText),
			("testSplitAnEmbolden", testSplitAnEmbolden),
			("testWithSupplementaryCharacter", testWithSupplementaryCharacter)
			]
	}()
}
