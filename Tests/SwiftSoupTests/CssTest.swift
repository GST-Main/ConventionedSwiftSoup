//
//  CssTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 11/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//

import XCTest
import PrettySwiftSoup

class CssTest: XCTestCase {
	var html: HTMLDocument!
	private var htmlString: String!

	override func setUp() {
		super.setUp()

		let sb: StringBuilder = StringBuilder(string: "<html><head></head><body>")

		sb.append("<div id='pseudo'>")
		for i in 1...10 {
			sb.append("<p>\(i)</p>")
		}
		sb.append("</div>")

		sb.append("<div id='type'>")
		for i in 1...10 {
			sb.append("<p>\(i)</p>")
			sb.append("<span>\(i)</span>")
			sb.append("<em>\(i)</em>")
			sb.append("<svg>\(i)</svg>")
		}
		sb.append("</div>")

		sb.append("<span id='onlySpan'><br /></span>")
		sb.append("<p class='empty'><!-- Comment only is still empty! --></p>")

		sb.append("<div id='only'>")
		sb.append("Some text before the <em>only</em> child in this div")
		sb.append("</div>")

		sb.append("</body></html>")
		htmlString = sb.toString()
		html = HTMLParser.parse(htmlString)
	}

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testFirstChild()throws {
		check(html.select(cssQuery: "#pseudo :first-child"), "1")
		check(html.select(cssQuery: "html:first-child"))
	}

	func testLastChild()throws {
         check(html.select(cssQuery: "#pseudo :last-child"), "10")
         check(html.select(cssQuery: "html:last-child"))
	}

	func testNthChild_simple()throws {
		for i in 1...10 {
			check(html.select(cssQuery: "#pseudo :nth-child(\(i))"), "\(i)")
		}
	}

	func testNthOfType_unknownTag()throws {
		for i in 1...10 {
			check(html.select(cssQuery: "#type svg:nth-of-type(\(i))"), "\(i)")
		}
	}

	func testNthLastChild_simple()throws {
		for i in 1...10 {
			check(html.select(cssQuery: "#pseudo :nth-last-child(\(i))"), "\(11-i)")
		}
	}

	func testNthOfType_simple()throws {
		for i in 1...10 {
			check(html.select(cssQuery: "#type p:nth-of-type(\(i))"), "\(i)")
		}
	}

	func testNthLastOfType_simple()throws {
		for i in 1...10 {
			check(html.select(cssQuery: "#type :nth-last-of-type(\(i))"), "\(11-i)", "\(11-i)", "\(11-i)", "\(11-i)")
		}
	}

	func testNthChild_advanced()throws {
		check(html.select(cssQuery: "#pseudo :nth-child(-5)"))
		check(html.select(cssQuery: "#pseudo :nth-child(odd)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#pseudo :nth-child(2n-1)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#pseudo :nth-child(2n+1)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#pseudo :nth-child(2n+3)"), "3", "5", "7", "9")
		check(html.select(cssQuery: "#pseudo :nth-child(even)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#pseudo :nth-child(2n)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#pseudo :nth-child(3n-1)"), "2", "5", "8")
		check(html.select(cssQuery: "#pseudo :nth-child(-2n+5)"), "1", "3", "5")
		check(html.select(cssQuery: "#pseudo :nth-child(+5)"), "5")
	}

	func testNthOfType_advanced()throws {
		check(html.select(cssQuery: "#type :nth-of-type(-5)"))
		check(html.select(cssQuery: "#type p:nth-of-type(odd)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#type em:nth-of-type(2n-1)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#type p:nth-of-type(2n+1)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#type span:nth-of-type(2n+3)"), "3", "5", "7", "9")
		check(html.select(cssQuery: "#type p:nth-of-type(even)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#type p:nth-of-type(2n)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#type p:nth-of-type(3n-1)"), "2", "5", "8")
		check(html.select(cssQuery: "#type p:nth-of-type(-2n+5)"), "1", "3", "5")
		check(html.select(cssQuery: "#type :nth-of-type(+5)"), "5", "5", "5", "5")
	}

	func testNthLastChild_advanced()throws {
		check(html.select(cssQuery: "#pseudo :nth-last-child(-5)"))
		check(html.select(cssQuery: "#pseudo :nth-last-child(odd)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#pseudo :nth-last-child(2n-1)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#pseudo :nth-last-child(2n+1)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#pseudo :nth-last-child(2n+3)"), "2", "4", "6", "8")
		check(html.select(cssQuery: "#pseudo :nth-last-child(even)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#pseudo :nth-last-child(2n)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#pseudo :nth-last-child(3n-1)"), "3", "6", "9")

		check(html.select(cssQuery: "#pseudo :nth-last-child(-2n+5)"), "6", "8", "10")
		check(html.select(cssQuery: "#pseudo :nth-last-child(+5)"), "6")
	}

	func testNthLastOfType_advanced()throws {
		check(html.select(cssQuery: "#type :nth-last-of-type(-5)"))
		check(html.select(cssQuery: "#type p:nth-last-of-type(odd)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#type em:nth-last-of-type(2n-1)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#type p:nth-last-of-type(2n+1)"), "2", "4", "6", "8", "10")
		check(html.select(cssQuery: "#type span:nth-last-of-type(2n+3)"), "2", "4", "6", "8")
		check(html.select(cssQuery: "#type p:nth-last-of-type(even)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#type p:nth-last-of-type(2n)"), "1", "3", "5", "7", "9")
		check(html.select(cssQuery: "#type p:nth-last-of-type(3n-1)"), "3", "6", "9")

		check(html.select(cssQuery: "#type span:nth-last-of-type(-2n+5)"), "6", "8", "10")
		check(html.select(cssQuery: "#type :nth-last-of-type(+5)"), "6", "6", "6", "6")
	}

	func testFirstOfType()throws {
		check(html.select(cssQuery: "div:not(#only) :first-of-type"), "1", "1", "1", "1", "1")
	}

	func testLastOfType()throws {
		check(html.select(cssQuery: "div:not(#only) :last-of-type"), "10", "10", "10", "10", "10")
	}

	func testEmpty()throws {
		let sel: HTMLElements = html.select(cssQuery: ":empty")
		XCTAssertEqual(3, sel.count)
		XCTAssertEqual("head", sel.getElement(at: 0)?.tagName)
		XCTAssertEqual("br", sel.getElement(at: 1)?.tagName)
		XCTAssertEqual("p", sel.getElement(at: 2)?.tagName)
	}

	func testOnlyChild()throws {
		let sel: HTMLElements = html.select(cssQuery: "span :only-child")
		XCTAssertEqual(1, sel.count)
		XCTAssertEqual("br", sel.getElement(at: 0)?.tagName)

		check(html.select(cssQuery: "#only :only-child"), "only")
	}

	func testOnlyOfType()throws {
		let sel: HTMLElements = html.select(cssQuery: ":only-of-type")
		XCTAssertEqual(6, sel.count)
		XCTAssertEqual("head", sel.getElement(at: 0)?.tagName)
		XCTAssertEqual("body", sel.getElement(at: 1)?.tagName)
		XCTAssertEqual("span", sel.getElement(at: 2)?.tagName)
		XCTAssertEqual("br", sel.getElement(at: 3)?.tagName)
		XCTAssertEqual("p", sel.getElement(at: 4)?.tagName)
		XCTAssertTrue(sel.getElement(at: 4)?.hasClass(named: "empty") == true)
		XCTAssertEqual("em", sel.getElement(at: 5)?.tagName)
	}

	func check(_ resut: HTMLElements, _ expectedContent: String... ) {
		check(resut, expectedContent)
	}

	func check(_ result: HTMLElements, _ expectedContent: [String] ) {
		XCTAssertEqual(expectedContent.count, result.count)
		for i in 0..<expectedContent.count {
            XCTAssertNotNil(result.getElement(at: i))
            XCTAssertEqual(expectedContent[i], result.getElement(at: i)?.ownText)
		}
	}

	func testRoot()throws {
		let sel: HTMLElements = html.select(cssQuery: ":root")
		XCTAssertEqual(1, sel.count)
		XCTAssertNotNil(sel.getElement(at: 0)!)
        try XCTAssertEqual(Tag.valueOf("html"), sel.getElement(at: 0)?.tag)

		let sel2: HTMLElements = html.select(cssQuery: "body").select(cssQuery: ":root")
		XCTAssertEqual(1, sel2.count)
		XCTAssertNotNil(sel2.getElement(at: 0)!)
		try XCTAssertEqual(Tag.valueOf("body"), sel2.getElement(at: 0)?.tag)
	}

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testFirstChild", testFirstChild),
			("testLastChild", testLastChild),
			("testNthChild_simple", testNthChild_simple),
			("testNthOfType_unknownTag", testNthOfType_unknownTag),
			("testNthLastChild_simple", testNthLastChild_simple),
			("testNthOfType_simple", testNthOfType_simple),
			("testNthLastOfType_simple", testNthLastOfType_simple),
			("testNthChild_advanced", testNthChild_advanced),
			("testNthOfType_advanced", testNthOfType_advanced),
			("testNthLastChild_advanced", testNthLastChild_advanced),
			("testNthLastOfType_advanced", testNthLastOfType_advanced),
			("testFirstOfType", testFirstOfType),
			("testLastOfType", testLastOfType),
			("testEmpty", testEmpty),
			("testOnlyChild", testOnlyChild),
			("testOnlyOfType", testOnlyOfType),
			("testRoot", testRoot)
		]
	}()
}
