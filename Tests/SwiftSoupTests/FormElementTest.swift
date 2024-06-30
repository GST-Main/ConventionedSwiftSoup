//
//  FormElementTest.swift
//  SwiftSoup
//
//  Created by Nabil Chatbi on 09/11/16.
//  Copyright © 2016 Nabil Chatbi. All rights reserved.
//

import XCTest
import PrettySwiftSoup

class FormElementTest: XCTestCase {

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

	func testHasAssociatedControls()throws {
		//"button", "fieldset", "input", "keygen", "object", "output", "select", "textarea"
		let html = "<form id=1><button id=1><fieldset id=2 /><input id=3><keygen id=4><object id=5><output id=6>" +
		"<select id=7><option></select><textarea id=8><p id=9>"
        guard let doc: HTMLDocument = HTMLParser.parse(html) else {
            XCTFail()
            return
        }

		let form: FormElement = doc.select(cssQuery: "form").first! as! FormElement
		XCTAssertEqual(8, form.elements().count)
	}

	//todo:
//	func createsFormData()throws {
//		let html = "<form><input name='one' value='two'><select name='three'><option value='not'>" +
//			"<option value='four' selected><option value='five' selected><textarea name=six>seven</textarea>" +
//			"<input name='seven' type='radio' value='on' checked><input name='seven' type='radio' value='off'>" +
//			"<input name='eight' type='checkbox' checked><input name='nine' type='checkbox' value='unset'>" +
//			"<input name='ten' value='text' disabled>" +
//		"</form>";
//		let doc: HTMLDocument = try Jsoup.parse(html);
//		let form: FormElement = try doc.select("form").first as! FormElement
//		let data = form.formData();//List<Connection.KeyVal>
//		
//		XCTAssertEqual(6, data.count);
//		XCTAssertEqual("one=two", data.get(index: 0)!.toString());
//		XCTAssertEqual("three=four", data.get(index: 1)!.toString());
//		XCTAssertEqual("three=five", data.get(index: 2)!.toString());
//		XCTAssertEqual("six=seven", data.get(index: 3)!.toString());
//		XCTAssertEqual("seven=on", data.get(index: 4)!.toString()); // set
//		XCTAssertEqual("eight=on", data.get(index: 5)!.toString()); // default
//		// nine should not appear, not checked checkbox
//		// ten should not appear, disabled
//	}

	//todo:
//	@Test public void createsSubmitableConnection() {
//	String html = "<form action='/search'><input name='q'></form>";
//	HTMLDocument doc = Jsoup.parse(html, "http://example.com/");
//	doc.select("[name=q]").attr("value", "jsoup");
//	
//	FormElement form = ((FormElement) doc.select("form").first);
//	Connection con = form.submit();
//	
//	assertEquals(Connection.Method.GET, con.request().method());
//	assertEquals("http://example.com/search", con.request().url().toExternalForm());
//	List<Connection.KeyVal> dataList = (List<Connection.KeyVal>) con.request().data();
//	assertEquals("q=jsoup", dataList.get(index: 0)!.toString());
//	
//	doc.select("form").attr("method", "post");
//	Connection con2 = form.submit();
//	assertEquals(Connection.Method.POST, con2.request().method());
//	}

	//TODO:
//	func testActionWithNoValue()throws {
//	String html = "<form><input name='q'></form>";
//	HTMLDocument doc = Jsoup.parse(html, "http://example.com/");
//	FormElement form = ((FormElement) doc.select("form").first);
//	Connection con = form.submit();
//	
//	assertEquals("http://example.com/", con.request().url().toExternalForm());
//	}

//TODO:
//	@Test public void actionWithNoBaseUri() {
//	String html = "<form><input name='q'></form>";
//	HTMLDocument doc = Jsoup.parse(html);
//	FormElement form = ((FormElement) doc.select("form").first);
//	
//	
//	boolean threw = false;
//	try {
//	Connection con = form.submit();
//	} catch (IllegalArgumentException e) {
//	threw = true;
//	assertEquals("Could not determine a form action URL for submit. Ensure you set a base URI when parsing.",
//	e.getMessage());
//	}
//	assertTrue(threw);
//	}

	func testFormsAddedAfterParseAreFormElements()throws {
		let doc: HTMLDocument = HTMLParser.parse("<body />")!
		try doc.body?.setHTML("<form action='http://example.com/search'><input name='q' value='search'>")
		let formEl: Element = doc.select(cssQuery: "form").first!
		XCTAssertNotNil(formEl as? FormElement)

		let form: FormElement =  formEl as! FormElement
		XCTAssertEqual(1, form.elements().count)
	}

	func testControlsAddedAfterParseAreLinkedWithForms()throws {
		let doc: HTMLDocument = HTMLParser.parse("<body />")!
		try doc.body?.setHTML("<form />")

		let formEl: Element = doc.select(cssQuery: "form").first!
		try formEl.appendHTML("<input name=foo value=bar>")

		XCTAssertNotNil(formEl as? FormElement)
		let form: FormElement = formEl as! FormElement
		XCTAssertEqual(1, form.elements().count)

		//todo:
		///List<Connection.KeyVal> data = form.formData();
		//assertEquals("foo=bar", data.get(index: 0)!.toString());
	}

	//todo:
//	func testUsesOnForCheckboxValueIfNoValueSet()throws {
//	let doc = try Jsoup.parse("<form><input type=checkbox checked name=foo></form>");
//	let form = try doc.select("form").first! as! FormElement
//	List<Connection.KeyVal> data = form.formData();
//	assertEquals("on", data.get(index: 0)!.value());
//	assertEquals("foo", data.get(index: 0)!.key());
//	}

	//todo:
//	@Test public void adoptedFormsRetainInputs() {
//	// test for https://github.com/jhy/jsoup/issues/249
//	String html = "<html>\n" +
//	"<body>  \n" +
//	"  <table>\n" +
//	"      <form action=\"/hello.php\" method=\"post\">\n" +
//	"      <tr><td>User:</td><td> <input type=\"text\" name=\"user\" /></td></tr>\n" +
//	"      <tr><td>Password:</td><td> <input type=\"password\" name=\"pass\" /></td></tr>\n" +
//	"      <tr><td><input type=\"submit\" name=\"login\" value=\"login\" /></td></tr>\n" +
//	"   </form>\n" +
//	"  </table>\n" +
//	"</body>\n" +
//	"</html>";
//	HTMLDocument doc = Jsoup.parse(html);
//	FormElement form = (FormElement) doc.select("form").first;
//	List<Connection.KeyVal> data = form.formData();
//	assertEquals(3, data.count);
//	assertEquals("user", data.get(index: 0)!.key());
//	assertEquals("pass", data.get(index: 1)!.key());
//	assertEquals("login", data.get(index: 2)!.key());
//	}

	static var allTests = {
		return [
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
            ("testHasAssociatedControls", testHasAssociatedControls),
			("testFormsAddedAfterParseAreFormElements", testFormsAddedAfterParseAreFormElements),
			("testControlsAddedAfterParseAreLinkedWithForms", testControlsAddedAfterParseAreLinkedWithForms)
		]
	}()
}
