//
//  DocumentTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 31/10/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import XCTest
@testable import SwiftSoup

class DocumentTest: XCTestCase {

	private static let charsetUtf8 = String.Encoding.utf8
	private static let charsetIso8859 = String.Encoding.iso2022JP //"ISO-8859-1"

//	func testT()throws
//	{
//		do{
//			let html = "<!DOCTYPE html>" +
//				"<html>" +
//				"<head>" +
//				"<title>Some webpage</title>" +
//				"</head>" +
//				"<body>" +
//				"<p class='normal'>This is the first paragraph.</p>" +
//				"<p class='special'><b>this is in bold</b></p>" +
//				"</body>" +
//			"</html>";
//			
//			let doc: Document = Parser.parseHTML(html)!
//			try doc.append("<p class='special'><b>this is in bold</b></p>")
//			try doc.append("<p class='special'><b>this is in bold</b></p>")
//			try doc.append("<p class='special'><b>this is in bold</b></p>")
//			try doc.append("<p class='special'><b>this is in bold</b></p>")
//			let els: Elements = try doc.getElementsByClass("special")
//			let special: Element? = els.first//get first element
//			print(try special?.text())//"this is in bold"
//			print(special?.tagName())//"p"
//			print(special?.child(0).tag().getName())//"b"
//			
//			for el in els{
//				print(el)
//			}
//			
//		}catch Exception.Error(let type, let message)
//		{
//			print()
//		}catch{
//			print("")
//		}
//	}

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testSetTextPreservesDocumentStructure() {
        let doc: Document = Parser.parseHTML("<p>Hello</p>")!
        doc.setText("Replaced")
        XCTAssertEqual("Replaced", doc.getText())
        XCTAssertEqual("Replaced", doc.body!.getText())
        XCTAssertEqual(1, doc.select(cssQuery: "head").count)
	}

	func testTitles() {
        let noTitle: Document = Parser.parseHTML("<p>Hello</p>")!
        let withTitle: Document = Parser.parseHTML("<title>First</title><title>Ignore</title><p>Hello</p>")!
        
        XCTAssertEqual(nil, noTitle.title)
        noTitle.title = "Hello"
        XCTAssertEqual("Hello", noTitle.title)
        XCTAssertEqual("Hello", noTitle.select(cssQuery: "title").first?.getText())
        
        XCTAssertEqual("First", withTitle.title)
        withTitle.title = "Hello"
        XCTAssertEqual("Hello", withTitle.title)
        XCTAssertEqual("Hello", withTitle.select(cssQuery: "title").first?.getText())
        
        let normaliseTitle: Document = Parser.parseHTML("<title>   Hello\nthere   \n   now   \n")!
        XCTAssertEqual("Hello there now", normaliseTitle.title)
	}

	func testOutputEncoding() {
        let doc: Document = Parser.parseHTML("<p title=π>π & < > </p>")!
        // default is utf-8
        XCTAssertEqual("<p title=\"π\">π &amp; &lt; &gt; </p>", doc.body?.html)
        XCTAssertEqual("UTF-8", doc.outputSettings.charset().displayName())
        
        doc.outputSettings.charset(.ascii)
        XCTAssertEqual(Entities.EscapeMode.base, doc.outputSettings.escapeMode())
        XCTAssertEqual("<p title=\"&#x3c0;\">&#x3c0; &amp; &lt; &gt; </p>", doc.body?.html)
        
        doc.outputSettings.escapeMode(Entities.EscapeMode.extended)
        XCTAssertEqual("<p title=\"&pi;\">&pi; &amp; &lt; &gt; </p>", doc.body?.html)
	}

	func testXhtmlReferences() {
		let doc: Document = Parser.parseHTML("&lt; &gt; &amp; &quot; &apos; &times;")!
		doc.outputSettings.escapeMode(Entities.EscapeMode.xhtml)
		XCTAssertEqual("&lt; &gt; &amp; \" ' ×", doc.body?.html)
	}

	func testNormalisesStructure() {
		let doc: Document = Parser.parseHTML("<html><head><script>one</script><noscript><p>two</p></noscript></head><body><p>three</p></body><p>four</p></html>")!
		XCTAssertEqual("<html><head><script>one</script><noscript>&lt;p&gt;two</noscript></head><body><p>three</p><p>four</p></body></html>", TextUtil.stripNewlines(doc.html!))
	}

	func testClone() {
		let doc: Document = Parser.parseHTML("<title>Hello</title> <p>One<p>Two")!
		let clone: Document = doc.copy() as! Document

        XCTAssertEqual("<html><head><title>Hello</title> </head><body><p>One</p><p>Two</p></body></html>", TextUtil.stripNewlines(clone.html!))
        clone.title = "Hello there"
		try! clone.select(cssQuery: "p").first!.setText("One more").setAttribute(withKey: "id", newValue: "1")
		XCTAssertEqual("<html><head><title>Hello there</title> </head><body><p id=\"1\">One more</p><p>Two</p></body></html>", TextUtil.stripNewlines(clone.html!))
		XCTAssertEqual("<html><head><title>Hello</title> </head><body><p>One</p><p>Two</p></body></html>", TextUtil.stripNewlines(doc.html!))
	}

	func testClonesDeclarations() {
		let doc: Document = Parser.parseHTML("<!DOCTYPE html><html><head><title>Doctype test")!
		let clone: Document = doc.copy() as! Document

		XCTAssertEqual(doc.html, clone.html)
		XCTAssertEqual("<!doctype html><html><head><title>Doctype test</title></head><body></body></html>",
		               TextUtil.stripNewlines(clone.html!))
	}

	//todo:
	//	func testLocation()throws {
	//		File in = new ParseTest().getFile("/htmltests/yahoo-jp.html")
	//		Document doc = Jsoup.parse(in, "UTF-8", "http://www.yahoo.co.jp/index.html");
	//		String location = doc.location();
	//		String baseUri = doc.baseUri();
	//		assertEquals("http://www.yahoo.co.jp/index.html",location);
	//		assertEquals("http://www.yahoo.co.jp/_ylh=X3oDMTB0NWxnaGxsBF9TAzIwNzcyOTYyNjUEdGlkAzEyBHRtcGwDZ2Ex/",baseUri);
	//		in = new ParseTest().getFile("/htmltests/nyt-article-1.html");
	//		doc = Jsoup.parse(in, null, "http://www.nytimes.com/2010/07/26/business/global/26bp.html?hp");
	//		location = doc.location();
	//		baseUri = doc.baseUri();
	//		assertEquals("http://www.nytimes.com/2010/07/26/business/global/26bp.html?hp",location);
	//		assertEquals("http://www.nytimes.com/2010/07/26/business/global/26bp.html?hp",baseUri);
	//	}

	func testHtmlAndXmlSyntax() {
		let h: String = "<!DOCTYPE html><body><img async checked='checked' src='&<>\"'>&lt;&gt;&amp;&quot;<foo />bar"
		let doc: Document = Parser.parseHTML(h)!

		doc.outputSettings.syntax(syntax: OutputSettings.Syntax.html)
		XCTAssertEqual("<!doctype html>\n" +
			"<html>\n" +
			" <head></head>\n" +
			" <body>\n" +
			"  <img async checked src=\"&amp;<>&quot;\">&lt;&gt;&amp;\"\n" +
			"  <foo />bar\n" +
			" </body>\n" +
			"</html>", doc.html)

		doc.outputSettings.syntax(syntax: OutputSettings.Syntax.xml)
		XCTAssertEqual("<!DOCTYPE html>\n" +
			"<html>\n" +
			" <head></head>\n" +
			" <body>\n" +
			"  <img async=\"\" checked=\"checked\" src=\"&amp;<>&quot;\" />&lt;&gt;&amp;\"\n" +
			"  <foo />bar\n" +
			" </body>\n" +
			"</html>", doc.html)
	}

	func testHtmlParseDefaultsToHtmlOutputSyntax() {
		let doc: Document = Parser.parseHTML("x")!
		XCTAssertEqual(OutputSettings.Syntax.html, doc.outputSettings.syntax())
	}

	func testHtmlAppendable() {
		let htmlContent: String = "<html><head><title>Hello</title></head><body><p>One</p><p>Two</p></body></html>"
		let document: Document = Parser.parseHTML(htmlContent)!
		let outputSettings: OutputSettings = OutputSettings()

		outputSettings.prettyPrint(pretty: false)
		document.outputSettings = outputSettings
		XCTAssertEqual(htmlContent, try! document.html(StringBuilder()).toString())
	}

	//todo: // Ignored since this test can take awhile to run.
	//	func testOverflowClone() {
	//		let builder: StringBuilder = StringBuilder();
	//		for i in 0..<100000
	//		{
	//			builder.insert(0, "<i>");
	//			builder.append("</i>");
	//		}
	//		let doc: Document = try! Jsoup.parse(builder.toString());
	//		doc.copy();
	//	}

	func testDocumentsWithSameContentAreEqual() throws {
		let docA: Document = Parser.parseHTML("<div/>One")!
		let docB: Document = Parser.parseHTML("<div/>One")!
		_ = Parser.parseHTML("<div/>Two")!

		XCTAssertFalse(docA.equals(docB))
		XCTAssertTrue(docA.equals(docA))
		//todo:
		//		XCTAssertEqual(docA.hashCode(), docA.hashCode());
		//		XCTAssertFalse(docA.hashCode() == docC.hashCode());
	}

	func testDocumentsWithSameContentAreVerifialbe() throws {
		let docA: Document = Parser.parseHTML("<div/>One")!
		let docB: Document = Parser.parseHTML("<div/>One")!
		let docC: Document = Parser.parseHTML("<div/>Two")!

		XCTAssertTrue(docA.hasSameValue(docB))
		XCTAssertFalse(docA.hasSameValue(docC))
	}

	func testMetaCharsetUpdateUtf8() {
		let doc: Document = createHtmlDocument("changeThis")
        doc.charset = DocumentTest.charsetUtf8

		let htmlCharsetUTF8: String = "<html>\n" + " <head>\n" + "  <meta charset=\"" + "UTF-8" + "\">\n" + " </head>\n" + " <body></body>\n" + "</html>"
		XCTAssertEqual(htmlCharsetUTF8, doc.outerHTML ?? "")

		let selectedElement: Element = doc.select(cssQuery: "meta[charset]").first!
		XCTAssertEqual(DocumentTest.charsetUtf8, doc.charset)
		XCTAssertEqual("UTF-8", selectedElement.getAttribute(withKey: "charset"))
		XCTAssertEqual(doc.charset, doc.outputSettings.charset())

	}

	func testMetaCharsetUpdateIsoLatin2()throws {
		let doc: Document = createHtmlDocument("changeThis")
		doc.charset = .isoLatin2

		let htmlCharsetISO = "<html>\n" +
			" <head>\n" +
			"  <meta charset=\"" + String.Encoding.isoLatin2.displayName() + "\">\n" +
			" </head>\n" +
			" <body></body>\n" +
		"</html>"
		XCTAssertEqual(htmlCharsetISO, doc.outerHTML)

		let selectedElement: Element = doc.select(cssQuery: "meta[charset]").first!
		XCTAssertEqual(String.Encoding.isoLatin2.displayName(), doc.charset.displayName())
		XCTAssertEqual(String.Encoding.isoLatin2.displayName(), selectedElement.getAttribute(withKey: "charset"))
		XCTAssertEqual(doc.charset, doc.outputSettings.charset())
	}

	func testMetaCharsetUpdateNoCharset() throws {
		let docNoCharset: Document = Document.createShell(baseURI: "")
		docNoCharset.charset = .utf8

        XCTAssertEqual(String.Encoding.utf8.displayName(), docNoCharset.select(cssQuery: "meta[charset]").first?.getAttribute(withKey: "charset"))

		let htmlCharsetUTF8 = "<html>\n" +
			" <head>\n" +
			"  <meta charset=\"" + String.Encoding.utf8.displayName() + "\">\n" +
			" </head>\n" +
			" <body></body>\n" +
		"</html>"
        XCTAssertEqual(htmlCharsetUTF8, docNoCharset.outerHTML)
	}

	func testMetaCharsetUpdateDisabled()throws {
		let docDisabled: Document = Document.createShell(baseURI: "")

		let htmlNoCharset = "<html>\n" +
			" <head></head>\n" +
			" <body></body>\n" +
		"</html>"
        XCTAssertEqual(htmlNoCharset, docDisabled.outerHTML)
        XCTAssertNil(docDisabled.select(cssQuery: "meta[charset]").first)
	}

	func testMetaCharsetUpdateDisabledNoChanges()throws {
		let doc: Document = createHtmlDocument("dontTouch")

		let htmlCharset = "<html>\n" +
			" <head>\n" +
			"  <meta charset=\"dontTouch\">\n" +
			"  <meta name=\"charset\" content=\"dontTouch\">\n" +
			" </head>\n" +
			" <body></body>\n" +
		"</html>"
        XCTAssertEqual(htmlCharset, doc.outerHTML)

		var selectedElement: Element = doc.select(cssQuery: "meta[charset]").first!
		XCTAssertNotNil(selectedElement)
        XCTAssertEqual("dontTouch", selectedElement.getAttribute(withKey: "charset"))

		selectedElement = doc.select(cssQuery: "meta[name=charset]").first!
		XCTAssertNotNil(selectedElement)
        XCTAssertEqual("dontTouch", selectedElement.getAttribute(withKey: "content"))
	}

	func testMetaCharsetUpdateEnabledAfterCharsetChange()throws {
		let doc: Document = createHtmlDocument("dontTouch")
        doc.charset = .utf8

		let selectedElement: Element = doc.select(cssQuery: "meta[charset]").first!
        XCTAssertEqual(String.Encoding.utf8.displayName(), selectedElement.getAttribute(withKey: "charset"))
        XCTAssertTrue(doc.select(cssQuery: "meta[name=charset]").isEmpty)
	}

	func testMetaCharsetUpdateCleanup()throws {
		let doc: Document = createHtmlDocument("dontTouch")
        doc.charset = .utf8

		let htmlCharsetUTF8 = "<html>\n" +
			" <head>\n" +
			"  <meta charset=\"" + String.Encoding.utf8.displayName() + "\">\n" +
			" </head>\n" +
			" <body></body>\n" +
		"</html>"

		XCTAssertEqual(htmlCharsetUTF8, doc.outerHTML)
	}

	func testMetaCharsetUpdateXmlUtf8()throws {
		let doc: Document = try createXmlDocument("1.0", "changeThis", true)
        doc.charset = .utf8

		let xmlCharsetUTF8 = "<?xml version=\"1.0\" encoding=\"" + String.Encoding.utf8.displayName() + "\"?>\n" +
			"<root>\n" +
			" node\n" +
		"</root>"
        XCTAssertEqual(xmlCharsetUTF8, doc.outerHTML)

		let selectedNode: XmlDeclaration = doc.childNode(0) as! XmlDeclaration
		XCTAssertEqual(String.Encoding.utf8.displayName(), doc.charset.displayName())
        XCTAssertEqual(String.Encoding.utf8.displayName(), selectedNode.getAttribute(withKey: "encoding"))
		XCTAssertEqual(doc.charset, doc.outputSettings.charset())
	}

	func testMetaCharsetUpdateXmlIso2022JP()throws {
		let doc: Document = try createXmlDocument("1.0", "changeThis", true)
        doc.charset = .iso2022JP

		let xmlCharsetISO = "<?xml version=\"1.0\" encoding=\"" + String.Encoding.iso2022JP.displayName() + "\"?>\n" +
			"<root>\n" +
			" node\n" +
		"</root>"
        XCTAssertEqual(xmlCharsetISO, doc.outerHTML)

		let selectedNode: XmlDeclaration =  doc.childNode(0) as! XmlDeclaration
		XCTAssertEqual(String.Encoding.iso2022JP.displayName(), doc.charset.displayName())
        XCTAssertEqual(String.Encoding.iso2022JP.displayName(), selectedNode.getAttribute(withKey: "encoding"))
		XCTAssertEqual(doc.charset, doc.outputSettings.charset())
	}

	func testMetaCharsetUpdateXmlNoCharset()throws {
		let doc: Document = try createXmlDocument("1.0", "none", false)
		doc.charset = .utf8

		let xmlCharsetUTF8 = "<?xml version=\"1.0\" encoding=\"" + String.Encoding.utf8.displayName() + "\"?>\n" +
			"<root>\n" +
			" node\n" +
		"</root>"
        XCTAssertEqual(xmlCharsetUTF8, doc.outerHTML)

		let selectedNode: XmlDeclaration = doc.childNode(0) as! XmlDeclaration
        XCTAssertEqual(String.Encoding.utf8.displayName(), selectedNode.getAttribute(withKey: "encoding"))
	}

	func testMetaCharsetUpdateXmlDisabled()throws {
		let doc: Document = try createXmlDocument("none", "none", false)

		let xmlNoCharset = "<root>\n" +
			" node\n" +
		"</root>"
        XCTAssertEqual(xmlNoCharset, doc.outerHTML)
	}

	func testMetaCharsetUpdateXmlDisabledNoChanges()throws {
		let doc: Document = try createXmlDocument("dontTouch", "dontTouch", true)

		let xmlCharset = "<?xml version=\"dontTouch\" encoding=\"dontTouch\"?>\n" +
			"<root>\n" +
			" node\n" +
		"</root>"
        XCTAssertEqual(xmlCharset, doc.outerHTML)

		let selectedNode: XmlDeclaration = doc.childNode(0) as! XmlDeclaration
        XCTAssertEqual("dontTouch", selectedNode.getAttribute(withKey: "encoding"))
        XCTAssertEqual("dontTouch", selectedNode.getAttribute(withKey: "version"))
	}

	private func createHtmlDocument(_ charset: String) -> Document {
		let doc: Document = Document.createShell(baseURI: "")
		try! doc.head?.appendElement(tagName: "meta").setAttribute(withKey: "charset", newValue: charset)
		try! doc.head?.appendElement(tagName: "meta").setAttribute(withKey: "name", newValue: "charset").setAttribute(withKey: "content", newValue: charset)
		return doc
	}

	func createXmlDocument(_ version: String, _ charset: String, _ addDecl: Bool)throws->Document {
		let doc: Document = Document(baseURI: "")
		try doc.appendElement(tagName: "root").setText("node")
		doc.outputSettings.syntax(syntax: OutputSettings.Syntax.xml)

		if( addDecl == true ) {
			let decl: XmlDeclaration = XmlDeclaration("xml", "", false)
			try decl.setAttribute(withKey: "version", newValue: version)
			try decl.setAttribute(withKey: "encoding", newValue: charset)
            doc.prependChild(decl)
		}

		return doc
	}

    func testThai() {
        let str = "บังคับ"
        guard let doc = Parser.parseHTML(str) else {
            XCTFail()
            return}
        guard let txt = doc.html else {
            XCTFail()
            return}
        XCTAssertEqual("<html>\n <head></head>\n <body>\n  บังคับ\n </body>\n</html>", txt)
    }

	//todo:
//	func testShiftJisRoundtrip()throws {
//		let input =
//			"<html>"
//				+   "<head>"
//				+     "<meta http-equiv=\"content-type\" content=\"text/html; charset=Shift_JIS\" />"
//				+   "</head>"
//				+   "<body>"
//				+     "before&nbsp;after"
//				+   "</body>"
//				+ "</html>";
//		InputStream is = new ByteArrayInputStream(input.getBytes(Charset.forName("ASCII")));
//		
//		Document doc = Jsoup.parse(is, null, "http://example.com");
//		doc.outputSettings.escapeMode(Entities.EscapeMode.xhtml);
//		
//		String output = new String(doc.html.getBytes(doc.outputSettings.charset), doc.outputSettings.charset);
//		
//		assertFalse("Should not have contained a '?'.", output.contains("?"));
//		assertTrue("Should have contained a '&#xa0;' or a '&nbsp;'.",
//		output.contains("&#xa0;") || output.contains("&nbsp;"));
//	}

    func testNewLine() {
        let h = "<html><body><div>\r\n<div dir=\"ltr\">\r\n<div id=\"divtagdefaultwrapper\"><font face=\"Calibri,Helvetica,sans-serif\" size=\"3\" color=\"black\"><span style=\"font-size:12pt;\" id=\"divtagdefaultwrapper\">\r\n<div style=\"margin-top:0;margin-bottom:0;\">&nbsp;TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\"><br>\r\n\r\n</div>\r\n<div style=\"margin-top:0;margin-bottom:0;\">TEST</div>\r\n</span></font></div>\r\n</div>\r\n</div>\r\n</body></html>"

        let doc: Document = Parser.parseHTML(h)!
        let text = doc.getText()
        XCTAssertEqual(text, "TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST")
    }

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testSetTextPreservesDocumentStructure", testSetTextPreservesDocumentStructure),
			("testTitles", testTitles),
			("testOutputEncoding", testOutputEncoding),
			("testXhtmlReferences", testXhtmlReferences),
			("testNormalisesStructure", testNormalisesStructure),
			("testClone", testClone),
			("testClonesDeclarations", testClonesDeclarations),
			("testHtmlAndXmlSyntax", testHtmlAndXmlSyntax),
			("testHtmlParseDefaultsToHtmlOutputSyntax", testHtmlParseDefaultsToHtmlOutputSyntax),
			("testHtmlAppendable", testHtmlAppendable),
			("testDocumentsWithSameContentAreEqual", testDocumentsWithSameContentAreEqual),
			("testDocumentsWithSameContentAreVerifialbe", testDocumentsWithSameContentAreVerifialbe),
			("testMetaCharsetUpdateUtf8", testMetaCharsetUpdateUtf8),
			("testMetaCharsetUpdateIsoLatin2", testMetaCharsetUpdateIsoLatin2),
			("testMetaCharsetUpdateNoCharset", testMetaCharsetUpdateNoCharset),
			("testMetaCharsetUpdateDisabled", testMetaCharsetUpdateDisabled),
			("testMetaCharsetUpdateDisabledNoChanges", testMetaCharsetUpdateDisabledNoChanges),
			("testMetaCharsetUpdateEnabledAfterCharsetChange", testMetaCharsetUpdateEnabledAfterCharsetChange),
			("testMetaCharsetUpdateCleanup", testMetaCharsetUpdateCleanup),
			("testMetaCharsetUpdateXmlUtf8", testMetaCharsetUpdateXmlUtf8),
			("testMetaCharsetUpdateXmlIso2022JP", testMetaCharsetUpdateXmlIso2022JP),
			("testMetaCharsetUpdateXmlNoCharset", testMetaCharsetUpdateXmlNoCharset),
			("testMetaCharsetUpdateXmlDisabled", testMetaCharsetUpdateXmlDisabled),
			("testMetaCharsetUpdateXmlDisabledNoChanges", testMetaCharsetUpdateXmlDisabledNoChanges),
			("testThai", testThai),
            ("testNewLine", testNewLine)
		]
	}()

}
