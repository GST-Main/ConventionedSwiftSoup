//
//  NodeTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 17/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import XCTest
import PrettySwiftSoup

class NodeTest: XCTestCase {

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testHandlesBaseUri() {
		do {
			let tag: Tag = try Tag.valueOf("a")
			let attribs: Attributes = Attributes()
			try attribs.put("relHref", "/foo")
			try attribs.put("absHref", "http://bar/qux")

			let noBase: HTMLElement = HTMLElement(tag: tag, baseURI: "", attributes: attribs)
			XCTAssertEqual("", noBase.absoluteURLPath(ofAttribute: "relHref")) // with no base, should NOT fallback to href attrib, whatever it is
			XCTAssertEqual("http://bar/qux", noBase.absoluteURLPath(ofAttribute: "absHref")) // no base but valid attrib, return attrib

			let withBase: HTMLElement = HTMLElement(tag: tag, baseURI: "http://foo/", attributes: attribs)
			XCTAssertEqual("http://foo/foo", withBase.absoluteURLPath(ofAttribute: "relHref")) // construct abs from base + rel
			XCTAssertEqual("http://bar/qux", withBase.absoluteURLPath(ofAttribute: "absHref")) // href is abs, so returns that
			XCTAssertEqual(nil, withBase.absoluteURLPath(ofAttribute: "noval"))

			let dodgyBase: HTMLElement = HTMLElement(tag: tag, baseURI: "wtf://no-such-protocol/", attributes: attribs)
			XCTAssertEqual("http://bar/qux", dodgyBase.absoluteURLPath(ofAttribute: "absHref")) // base fails, but href good, so get that
			//TODO:Nabil in swift an url with scheme wtf is valid , find a method to validate schemes
			//XCTAssertEqual("", try dodgyBase.absUrl("relHref")); // base fails, only rel href, so return nothing
		} catch {
			XCTAssertEqual(1, 2)
		}

	}

	func testSetBaseUriIsRecursive() {
        let doc: HTMLDocument = HTMLParser.parse("<div><p></p></div>")!
        let baseUri: String = "https://jsoup.org"
        doc.baseURI = baseUri
        
        XCTAssertEqual(baseUri, doc.baseURI)
        XCTAssertEqual(baseUri, doc.select(cssQuery: "div").first?.baseURI)
        XCTAssertEqual(baseUri, doc.select(cssQuery: "p").first?.baseURI)
	}

	func testHandlesAbsPrefix() {
        let doc: HTMLDocument = HTMLParser.parse("<a href=/foo>Hello</a>", baseURI: "https://jsoup.org/")!
        let a: HTMLElement? = doc.select(cssQuery: "a").first
        XCTAssertEqual("/foo", a?.getAttribute(withKey: "href"))
        XCTAssertEqual("https://jsoup.org/foo", a?.getAttribute(withKey: "abs:href"))
        //XCTAssertTrue(a!.hasAttr("abs:href"));//TODO:nabil
	}

	func testHandlesAbsOnImage() {
        let doc: HTMLDocument = HTMLParser.parse("<p><img src=\"/rez/osi_logo.png\" /></p>", baseURI: "https://jsoup.org/")!
        let img: HTMLElement? = doc.select(cssQuery: "img").first
        XCTAssertEqual("https://jsoup.org/rez/osi_logo.png", img?.getAttribute(withKey: "abs:src"))
        XCTAssertEqual(img?.absoluteURLPath(ofAttribute: "src"), img?.getAttribute(withKey: "abs:src"))
	}

	func testHandlesAbsPrefixOnHasAttr() {
        // 1: no abs url; 2: has abs url
        let doc: HTMLDocument = HTMLParser.parse("<a id=1 href='/foo'>One</a> <a id=2 href='https://jsoup.org/'>Two</a>")!
        let one: HTMLElement = doc.select(cssQuery: "#1").first!
        let two: HTMLElement = doc.select(cssQuery: "#2").first!
        
        XCTAssertFalse(one.hasAttribute(withKey: "abs:href"))
        XCTAssertTrue(one.hasAttribute(withKey: "href"))
        XCTAssertEqual("", one.absoluteURLPath(ofAttribute: "href"))
        
        XCTAssertTrue(two.hasAttribute(withKey: "abs:href"))
        XCTAssertTrue(two.hasAttribute(withKey: "href"))
        XCTAssertEqual("https://jsoup.org/", two.absoluteURLPath(ofAttribute: "href"))
	}

	func testLiteralAbsPrefix() {
        // if there is a literal attribute "abs:xxx", don't try and make absolute.
        let doc: HTMLDocument = HTMLParser.parse("<a abs:href='odd'>One</a>")!
        let el: HTMLElement = doc.select(cssQuery: "a").first!
        XCTAssertTrue(el.hasAttribute(withKey: "abs:href"))
        XCTAssertEqual("odd", el.getAttribute(withKey: "abs:href"))
	}
	//TODO:Nabil
/*
	func testHandleAbsOnFileUris() {
		do{
			let doc: HTMLDocument = try Jsoup.parse("<a href='password'>One/a><a href='/var/log/messages'>Two</a>", "file:/etc/");
			let one: HTMLElement = try doc.select("a").first!;
			XCTAssertEqual("file:/etc/password", try one.absUrl("href"));
			let two: HTMLElement = try doc.select("a").get(index: 1)!;
			XCTAssertEqual("file:/var/log/messages", try two.absUrl("href"));
		}catch{
			XCTAssertEqual(1,2)
		}
	}
*/
	func testHandleAbsOnLocalhostFileUris() {
        let doc: HTMLDocument  = HTMLParser.parse("<a href='password'>One/a><a href='/var/log/messages'>Two</a>", baseURI: "file://localhost/etc/")!
        let one: HTMLElement? = doc.select(cssQuery: "a").first
        XCTAssertEqual("file://localhost/etc/password", one?.absoluteURLPath(ofAttribute: "href"))
	}

	func testHandlesAbsOnProtocolessAbsoluteUris() {
        let doc1: HTMLDocument = HTMLParser.parse("<a href='//example.net/foo'>One</a>", baseURI: "http://example.com/")!
        let doc2: HTMLDocument = HTMLParser.parse("<a href='//example.net/foo'>One</a>", baseURI: "https://example.com/")!
        
        let one: HTMLElement? = doc1.select(cssQuery: "a").first
        let two: HTMLElement? = doc2.select(cssQuery: "a").first
        
        XCTAssertEqual("http://example.net/foo", one?.absoluteURLPath(ofAttribute: "href"))
        XCTAssertEqual("https://example.net/foo", two?.absoluteURLPath(ofAttribute: "href"))
	}

	func testAbsHandlesRelativeQuery() {
        let doc: HTMLDocument = HTMLParser.parse("<a href='?foo'>One</a> <a href='bar.html?foo'>Two</a>", baseURI: "https://jsoup.org/path/file?bar")!
        
        let a1: HTMLElement? = doc.select(cssQuery: "a").first
        XCTAssertEqual("https://jsoup.org/path/file?foo", a1?.absoluteURLPath(ofAttribute: "href"))
        
        let a2: HTMLElement? = doc.select(cssQuery: "a").getElement(at: 1)!
        XCTAssertEqual("https://jsoup.org/path/bar.html?foo", a2?.absoluteURLPath(ofAttribute: "href"))
	}

	func testAbsHandlesDotFromIndex() {
        let doc: HTMLDocument = HTMLParser.parse("<a href='./one/two.html'>One</a>", baseURI: "http://example.com")!
        let a1: HTMLElement? = doc.select(cssQuery: "a").first
        XCTAssertEqual("http://example.com/one/two.html", a1?.absoluteURLPath(ofAttribute: "href"))
	}

	func testRemove() {
        let doc: HTMLDocument = HTMLParser.parse("<p>One <span>two</span> three</p>")!
        let p: HTMLElement? = doc.select(cssQuery: "p").first
        p?.childNodes[0].remove()
        
        XCTAssertEqual("two three", p?.getText())
        XCTAssertEqual("<span>two</span> three", TextUtil.stripNewlines(p!.html!))
	}

	func testReplace() {
		do {
			let doc: HTMLDocument = HTMLParser.parse("<p>One <span>two</span> three</p>")!
			let p: HTMLElement? = doc.select(cssQuery: "p").first
			let insert: HTMLElement = try doc.createElement(withTagName: "em").setText("foo")
            p?.childNodes[1].replace(with: insert)

			XCTAssertEqual("One <em>foo</em> three", p?.html)
		} catch {
			XCTAssertEqual(1, 2)
		}
	}

	func testOwnerDocument() {
        let doc: HTMLDocument = HTMLParser.parse("<p>Hello")!
        let p: HTMLElement? = doc.select(cssQuery: "p").first
        XCTAssertTrue(p?.ownerDocument() == doc)
        XCTAssertTrue(doc.ownerDocument() == doc)
        XCTAssertNil(doc.parent)
	}

	func testBefore() {
		do {
			let doc: HTMLDocument = HTMLParser.parse("<p>One <b>two</b> three</p>")!
			let newNode: HTMLElement =  HTMLElement(tag: try Tag.valueOf("em"), baseURI: "")
            newNode.appendText("four")

			try doc.select(cssQuery: "b").first?.insertNodeAsPreviousSibling(newNode)
			XCTAssertEqual("<p>One <em>four</em><b>two</b> three</p>", doc.body?.html)

			try doc.select(cssQuery: "b").first?.insertHTMLAsPreviousSibling("<i>five</i>")
			XCTAssertEqual("<p>One <em>four</em><i>five</i><b>two</b> three</p>", doc.body?.html)
		} catch {
			XCTAssertEqual(1, 2)
		}
	}

	func testAfter() {
		do {
			let doc: HTMLDocument = HTMLParser.parse("<p>One <b>two</b> three</p>")!
			let newNode: HTMLElement = HTMLElement(tag: try Tag.valueOf("em"), baseURI: "")
            newNode.appendText("four")

			try _ = doc.select(cssQuery: "b").first?.insertNodeAsNextSibling(newNode)
			XCTAssertEqual("<p>One <b>two</b><em>four</em> three</p>", doc.body?.html)

			try doc.select(cssQuery: "b").first?.insertHTMLAsNextSibling("<i>five</i>")
			XCTAssertEqual("<p>One <b>two</b><i>five</i><em>four</em> three</p>", doc.body?.html)
		} catch {
			XCTAssertEqual(1, 2)
		}

	}

	func testUnwrap() {
		do {
			let doc: HTMLDocument = HTMLParser.parse("<div>One <span>Two <b>Three</b></span> Four</div>")!
			let span: HTMLElement? = doc.select(cssQuery: "span").first
			let twoText: Node? = span?.childNodes[0]
			let node: Node? = try span?.unwrap()

			XCTAssertEqual("<div>One Two <b>Three</b> Four</div>", TextUtil.stripNewlines(doc.body!.html!))
			XCTAssertTrue(((node as? TextNode) != nil))
			XCTAssertEqual("Two ", (node as? TextNode)?.text())
			XCTAssertEqual(node, twoText)
			XCTAssertEqual(node?.parent, doc.select(cssQuery: "div").first)
		} catch {
			XCTAssertEqual(1, 2)
		}
	}

	func testUnwrapNoChildren() {
		do {
			let doc: HTMLDocument = HTMLParser.parse("<div>One <span></span> Two</div>")!
			let span: HTMLElement? = doc.select(cssQuery: "span").first
			let node: Node? = try span?.unwrap()
			XCTAssertEqual("<div>One  Two</div>", TextUtil.stripNewlines(doc.body!.html!))
			XCTAssertTrue(node == nil)
        } catch let error as SwiftSoupError {
            if error == .noChildrenToUnwrap {
                return
            } else {
                XCTFail("Unknown Error:\n\(error.localizedDescription)")
            }
        } catch {
            XCTFail("Unknown Error:\n\(error.localizedDescription)")
		}
	}

	func testTraverse() {
		do {
			let doc: HTMLDocument = HTMLParser.parse("<div><p>Hello</p></div><div>There</div>")!
			let accum: StringBuilder = StringBuilder()
			class nv: NodeVisitor {
				let accum: StringBuilder
				init (_ accum: StringBuilder) {
					self.accum = accum
				}
				func head(_ node: Node, _ depth: Int)throws {
					accum.append("<" + node.nodeName + ">")
				}
				func tail(_ node: Node, _ depth: Int)throws {
					accum.append("</" + node.nodeName + ">")
				}
			}
			try doc.select(cssQuery: "div").first?.traverse(nv(accum))
			XCTAssertEqual("<div><p><#text></#text></p></div>", accum.toString())

		} catch {
			XCTAssertEqual(1, 2)
		}
	}

	func testOrphanNodeReturnsNullForSiblingElements() {
		do {
			let node: Node = HTMLElement(tag: try Tag.valueOf("p"), baseURI: "")
			let el: HTMLElement = HTMLElement(tag: try Tag.valueOf("p"), baseURI: "")

			XCTAssertEqual(0, node.siblingIndex)
			XCTAssertEqual(0, node.siblingNodes.count)

			XCTAssertNil(node.previousSibling)
			XCTAssertNil(node.nextSibling)

			XCTAssertEqual(0, el.siblingElements.count)
			XCTAssertNil(el.previousSiblingElement)
			XCTAssertNil(el.nextSiblingElement)
		} catch {
			XCTAssertEqual(1, 2)
		}
	}

	func testNodeIsNotASiblingOfItself() {
        let doc: HTMLDocument = HTMLParser.parse("<div><p>One<p>Two<p>Three</div>")!
        let p2: HTMLElement = doc.select(cssQuery: "p").getElement(at: 1)!
        
        XCTAssertEqual("Two", p2.getText())
        let nodes = p2.siblingNodes
        XCTAssertEqual(2, nodes.count)
        XCTAssertEqual("<p>One</p>", nodes[0].outerHTML)
        XCTAssertEqual("<p>Three</p>", nodes[1].outerHTML)
	}

	func testChildNodesCopy() {
        let doc: HTMLDocument = HTMLParser.parse("<div id=1>Text 1 <p>One</p> Text 2 <p>Two<p>Three</div><div id=2>")!
        let div1: HTMLElement? = doc.select(cssQuery: "#1").first
        let div2: HTMLElement? = doc.select(cssQuery: "#2").first
        let divChildren = div1?.childNodesCopy()
        XCTAssertEqual(5, divChildren?.count)
        let tn1: TextNode? = div1?.childNodes[0] as? TextNode
        let tn2: TextNode? = divChildren?[0] as? TextNode
        tn2?.text("Text 1 updated")
        XCTAssertEqual("Text 1 ", tn1?.text())
        div2?.insertChildren(divChildren!, at: 0)
        XCTAssertEqual("<div id=\"1\">Text 1 <p>One</p> Text 2 <p>Two</p><p>Three</p></div><div id=\"2\">Text 1 updated"+"<p>One</p> Text 2 <p>Two</p><p>Three</p></div>", TextUtil.stripNewlines(doc.body!.html!))
	}

	func testSupportsClone() {
        let doc: HTMLDocument = HTMLParser.parse("<div class=foo>Text</div>")!
        let el: HTMLElement = doc.select(cssQuery: "div").first!
        XCTAssertTrue(el.hasClass(named: "foo"))
        
        let elClone: HTMLElement = (doc.copy() as! HTMLDocument).select(cssQuery: "div").first!
        XCTAssertTrue(elClone.hasClass(named: "foo"))
        XCTAssertTrue(elClone.getText() == "Text")
        
        el.removeClass(named: "foo")
        el.setText("None")
        XCTAssertFalse(el.hasClass(named: "foo"))
        XCTAssertTrue(elClone.hasClass(named: "foo"))
        XCTAssertTrue(el.getText() == "None")
        XCTAssertTrue(elClone.getText()=="Text")
	}

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testHandlesBaseUri", testHandlesBaseUri),
			("testSetBaseUriIsRecursive", testSetBaseUriIsRecursive),
			("testHandlesAbsPrefix", testHandlesAbsPrefix),
			("testHandlesAbsOnImage", testHandlesAbsOnImage),
			("testHandlesAbsPrefixOnHasAttr", testHandlesAbsPrefixOnHasAttr),
			("testLiteralAbsPrefix", testLiteralAbsPrefix),
			("testHandleAbsOnLocalhostFileUris", testHandleAbsOnLocalhostFileUris),
			 ("testHandlesAbsOnProtocolessAbsoluteUris", testHandlesAbsOnProtocolessAbsoluteUris),
			 ("testAbsHandlesRelativeQuery", testAbsHandlesRelativeQuery),
			 ("testAbsHandlesDotFromIndex", testAbsHandlesDotFromIndex),
			 ("testRemove", testRemove),
			 ("testReplace", testReplace),
			 ("testOwnerDocument", testOwnerDocument),
			 ("testBefore", testBefore),
			 ("testAfter", testAfter),
			 ("testUnwrap", testUnwrap),
			 ("testUnwrapNoChildren", testUnwrapNoChildren),
			 ("testTraverse", testTraverse),
			 ("testOrphanNodeReturnsNullForSiblingElements", testOrphanNodeReturnsNullForSiblingElements),
			 ("testNodeIsNotASiblingOfItself", testNodeIsNotASiblingOfItself),
			 ("testChildNodesCopy", testChildNodesCopy),
			 ("testSupportsClone", testSupportsClone)
		]
	}()
}
