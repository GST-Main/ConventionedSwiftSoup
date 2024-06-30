//
//  XmlTreeBuilderTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 14/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import XCTest
import PrettySwiftSoup

class XmlTreeBuilderTest: XCTestCase {

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testSimpleXmlParse()throws {
		let xml = "<doc id=2 href='/bar'>Foo <br /><link>One</link><link>Two</link></doc>"
		let treeBuilder: XmlTreeBuilder = XmlTreeBuilder()
		let doc: Document = try treeBuilder.parse(xml, "http://foo.com/")
		XCTAssertEqual("<doc id=\"2\" href=\"/bar\">Foo <br /><link>One</link><link>Two</link></doc>",
                       TextUtil.stripNewlines(doc.html!))
		XCTAssertEqual(doc.getElementById("2")?.absoluteURLPath(ofAttribute: "href"), "http://foo.com/bar")
	}

	func testPopToClose()throws {
		// test: </val> closes Two, </bar> ignored
		let xml = "<doc><val>One<val>Two</val></bar>Three</doc>"
		let treeBuilder: XmlTreeBuilder = XmlTreeBuilder()
		let doc = try treeBuilder.parse(xml, "http://foo.com/")
		XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>", TextUtil.stripNewlines(doc.html!))
	}

	func testCommentAndDocType()throws {
		let xml = "<!DOCTYPE HTML><!-- a comment -->One <qux />Two"
		let treeBuilder: XmlTreeBuilder = XmlTreeBuilder()
		let doc = try treeBuilder.parse(xml, "http://foo.com/")
		XCTAssertEqual("<!DOCTYPE HTML><!-- a comment -->One <qux />Two", TextUtil.stripNewlines(doc.html!))
	}

	func testSupplyParserToJsoupClass()throws {
		let xml = "<doc><val>One<val>Two</val></bar>Three</doc>"
        let doc = try HTMLParser.xmlParser().parse(xml, baseURI: "http://foo.com/")
		XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>", TextUtil.stripNewlines(doc.html!))
	}

	//TODO: nabil
	//	public void testSupplyParserToConnection() throws IOException {
	//	String xmlUrl = "http://direct.infohound.net/tools/jsoup-xml-test.xml";
	//
	//	// parse with both xml and html parser, ensure different
	//	Document xmlDoc = Jsoup.connect(xmlUrl).parser(HTMLParser.xmlParser()).get();
	//	Document htmlDoc = Jsoup.connect(xmlUrl).parser(HTMLParser.htmlParser()).get();
	//	Document autoXmlDoc = Jsoup.connect(xmlUrl).get(); // check connection auto detects xml, uses xml parser
	//
	//	XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>",
	//	TextUtil.stripNewlines(xmlDoc.html));
	//	assertFalse(htmlDoc.equals(xmlDoc));
	//	XCTAssertEqual(xmlDoc, autoXmlDoc);
	//	XCTAssertEqual(1, htmlDoc.select("head").count); // html parser normalises
	//	XCTAssertEqual(0, xmlDoc.select("head").count); // xml parser does not
	//	XCTAssertEqual(0, autoXmlDoc.select("head").count); // xml parser does not
	//	}

	//TODO: nabil
//	func testSupplyParserToDataStream()throws {
//		let testBundle = Bundle(for: type(of: self))
//		let fileURL = testBundle.url(forResource: "xml-test", withExtension: "xml")
//		File xmlFile = new File(XmlTreeBuilder.class.getResource("/htmltests/xml-test.xml").toURI());
//		InputStream inStream = new FileInputStream(xmlFile);
//		let doc = Jsoup.parse(inStream, null, "http://foo.com", HTMLParser.xmlParser());
//		XCTAssertEqual("<doc><val>One<val>Two</val>Three</val></doc>",
//		               TextUtil.stripNewlines(doc.html));
//	}

	func testDoesNotForceSelfClosingKnownTags()throws {
		// html will force "<br>one</br>" to logically "<br />One<br />".
        // XML should be stay "<br>one</br> -- don't recognise tag.
		let htmlDoc = HTMLParser.parseHTML("<br>one</br>")!
		XCTAssertEqual("<br>one\n<br>", htmlDoc.body?.html)

        let xmlDoc = try HTMLParser.xmlParser().parse("<br>one</br>", baseURI: "")
		XCTAssertEqual("<br>one</br>", xmlDoc.html)
	}

	func testHandlesXmlDeclarationAsDeclaration()throws {
		let html = "<?xml encoding='UTF-8' ?><body>One</body><!-- comment -->"
        let doc = try HTMLParser.xmlParser().parse(html, baseURI: "")
		XCTAssertEqual("<?xml encoding=\"UTF-8\"?> <body> One </body> <!-- comment -->",
                           StringUtil.normaliseWhitespace(doc.outerHTML!))
		XCTAssertEqual("#declaration", doc.childNode(0).nodeName)
		XCTAssertEqual("#comment", doc.childNode(2).nodeName)
	}

	func testXmlFragment()throws {
		let xml = "<one src='/foo/' />Two<three><four /></three>"
        let nodes: [Node] = HTMLParser.parseXMLFragment(xml, baseURI: "http://example.com/")!
		XCTAssertEqual(3, nodes.count)

		XCTAssertEqual("http://example.com/foo/", nodes[0].absoluteURLPath(ofAttribute: "src"))
		XCTAssertEqual("one", nodes[0].nodeName)
		XCTAssertEqual("Two", (nodes[1] as? TextNode)?.text())
	}

	func testXmlParseDefaultsToHtmlOutputSyntax()throws {
        let doc = try HTMLParser.xmlParser().parse("x", baseURI: "")
		XCTAssertEqual(OutputSettings.Syntax.xml, doc.outputSettings.syntax())
	}

	func testDoesHandleEOFInTag()throws {
		let html = "<img src=asdf onerror=\"alert(1)\" x="
        let xmlDoc = try HTMLParser.xmlParser().parse(html, baseURI: "")
		XCTAssertEqual("<img src=\"asdf\" onerror=\"alert(1)\" x=\"\" />", xmlDoc.html)
	}
	//todo:
//		func testDetectCharsetEncodingDeclaration()throws{
//		File xmlFile = new File(XmlTreeBuilder.class.getResource("/htmltests/xml-charset.xml").toURI());
//		InputStream inStream = new FileInputStream(xmlFile);
//		let doc = Jsoup.parse(inStream, null, "http://example.com/", HTMLParser.xmlParser());
//		XCTAssertEqual("ISO-8859-1", doc.charset().name());
//		XCTAssertEqual("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?> <data>äöåéü</data>",
//		TextUtil.stripNewlines(doc.html));
//		}

	func testParseDeclarationAttributes()throws {
		let xml = "<?xml version='1' encoding='UTF-8' something='else'?><val>One</val>"
        let doc = try HTMLParser.xmlParser().parse(xml, baseURI: "")
        guard let decl: XmlDeclaration =  doc.childNode(0) as? XmlDeclaration else {
            XCTAssertTrue(false)
            return
        }
		XCTAssertEqual("1", decl.getAttribute(withKey: "version"))
		XCTAssertEqual("UTF-8", decl.getAttribute(withKey: "encoding"))
		XCTAssertEqual("else", decl.getAttribute(withKey: "something"))
		try XCTAssertEqual("version=\"1\" encoding=\"UTF-8\" something=\"else\"", decl.getWholeDeclaration())
		XCTAssertEqual("<?xml version=\"1\" encoding=\"UTF-8\" something=\"else\"?>", decl.outerHTML)
	}

	func testCaseSensitiveDeclaration()throws {
		let xml = "<?XML version='1' encoding='UTF-8' something='else'?>"
        let doc = try HTMLParser.xmlParser().parse(xml, baseURI: "")
		XCTAssertEqual("<?XML version=\"1\" encoding=\"UTF-8\" something=\"else\"?>", doc.outerHTML)
	}

	func testCreatesValidProlog()throws {
		let document = Document.createShell(baseURI: "")
		document.outputSettings.syntax(syntax: OutputSettings.Syntax.xml)
        document.charset = .utf8
		XCTAssertEqual("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
			"<html>\n" +
			" <head></head>\n" +
			" <body></body>\n" +
			"</html>", document.outerHTML)
	}

	func testPreservesCaseByDefault()throws {
		let xml = "<TEST ID=1>Check</TEST>"
        let doc = try HTMLParser.xmlParser().parse(xml, baseURI: "")
		XCTAssertEqual("<TEST ID=\"1\">Check</TEST>", TextUtil.stripNewlines(doc.html!))
	}

	func testCanNormalizeCase()throws {
		let xml = "<TEST ID=1>Check</TEST>"
        let parser = HTMLParser.xmlParser()
        parser.settings = ParseSettings.htmlDefault
        let doc = try  parser.parse(xml, baseURI: "")
		XCTAssertEqual("<test id=\"1\">Check</test>", TextUtil.stripNewlines(doc.html!))
	}

    func testNilReplaceInQueue()throws {
        let html: String = "<TABLE><TBODY><TR><TD></TD><TD><FONT color=#000000 size=1><I><FONT size=5><P align=center></FONT></I></FONT>&nbsp;</P></TD></TR></TBODY></TABLE></TD></TR></TBODY></TABLE></DIV></DIV></DIV><BLOCKQUOTE></BLOCKQUOTE><DIV style=\"FONT: 10pt Courier New\"><BR><BR>&nbsp;</DIV></BODY></HTML>"
        _ = HTMLParser.parseHTML(html)!
    }

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testSimpleXmlParse", testSimpleXmlParse),
			("testPopToClose", testPopToClose),
			("testCommentAndDocType", testCommentAndDocType),
			("testSupplyParserToJsoupClass", testSupplyParserToJsoupClass),
			("testDoesNotForceSelfClosingKnownTags", testDoesNotForceSelfClosingKnownTags),
			("testHandlesXmlDeclarationAsDeclaration", testHandlesXmlDeclarationAsDeclaration),
			("testXmlFragment", testXmlFragment),
			("testXmlParseDefaultsToHtmlOutputSyntax", testXmlParseDefaultsToHtmlOutputSyntax),
			("testDoesHandleEOFInTag", testDoesHandleEOFInTag),
			("testParseDeclarationAttributes", testParseDeclarationAttributes),
			("testCaseSensitiveDeclaration", testCaseSensitiveDeclaration),
			("testCreatesValidProlog", testCreatesValidProlog),
			("testPreservesCaseByDefault", testPreservesCaseByDefault),
			("testCanNormalizeCase", testCanNormalizeCase),
            ("testNilReplaceInQueue", testNilReplaceInQueue)
		]
	}()

}
