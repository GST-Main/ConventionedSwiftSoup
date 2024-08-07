//
//  DocumentType.swift
//  SwifSoup
//
//  Created by Nabil Chatbi on 29/09/16.
//  Copyright © 2016 Nabil Chatbi.. All rights reserved.
//

import Foundation

/**
 * A {@code <!DOCTYPE>} node.
 */
public class DocumentType: Node {
    static let PUBLIC_KEY: String = "PUBLIC"
    static let SYSTEM_KEY: String = "SYSTEM"
    private static let NAME: String = "name"
    private static let PUB_SYS_KEY: String = "pubSysKey"; // PUBLIC or SYSTEM
    private static let PUBLIC_ID: String = "publicId"
    private static let SYSTEM_ID: String = "systemId"
    // todo: quirk mode from publicId and systemId

    /**
     * Create a new doctype element.
     * @param name the doctype's name
     * @param publicId the doctype's public ID
     * @param systemId the doctype's system ID
     * @param baseUri the doctype's base URI
     */
    public init(_ name: String, _ publicId: String, _ systemId: String, _ baseUri: String) {
        super.init(baseURI: baseUri)
        do {
            try setAttribute(withKey: DocumentType.NAME, value: name)
            try setAttribute(withKey: DocumentType.PUBLIC_ID, value: publicId)
            if (has(DocumentType.PUBLIC_ID)) {
                try setAttribute(withKey: DocumentType.PUB_SYS_KEY, value: DocumentType.PUBLIC_KEY)
            }
            try setAttribute(withKey: DocumentType.SYSTEM_ID, value: systemId)
        } catch {}
    }

    /**
     * Create a new doctype element.
     * @param name the doctype's name
     * @param publicId the doctype's public ID
     * @param systemId the doctype's system ID
     * @param baseUri the doctype's base URI
     */
    public init(_ name: String, _ pubSysKey: String?, _ publicId: String, _ systemId: String, _ baseUri: String) {
        super.init(baseURI: baseUri)
        do {
            try setAttribute(withKey: DocumentType.NAME, value: name)
            if(pubSysKey != nil) {
                try setAttribute(withKey: DocumentType.PUB_SYS_KEY, value: pubSysKey!)
            }
            try setAttribute(withKey: DocumentType.PUBLIC_ID, value: publicId)
            try setAttribute(withKey: DocumentType.SYSTEM_ID, value: systemId)
        } catch {}
    }

    public override var nodeName: String {
        return "#doctype"
    }

    override func outerHtmlHead(_ accum: StringBuilder, _ depth: Int, _ out: OutputSettings) {
        if (out.syntax() == OutputSettings.Syntax.html && !has(DocumentType.PUBLIC_ID) && !has(DocumentType.SYSTEM_ID)) {
            // looks like a html5 doctype, go lowercase for aesthetics
            accum.append("<!doctype")
        } else {
            accum.append("<!DOCTYPE")
        }
        if (has(DocumentType.NAME)) {
            if let attribute = getAttribute(withKey: DocumentType.NAME) {
                accum.append(" ").append(attribute)
            }
        }

        if (has(DocumentType.PUB_SYS_KEY)) {
            if let attribute = getAttribute(withKey: DocumentType.PUB_SYS_KEY) {
                accum.append(" ").append(attribute)
            }
        }

        if (has(DocumentType.PUBLIC_ID)) {
            if let attribute = getAttribute(withKey: DocumentType.PUBLIC_ID) {
                accum.append(" \"").append(attribute).append("\"")
            }
        }
        
        if (has(DocumentType.SYSTEM_ID)) {
            if let attribute = getAttribute(withKey: DocumentType.SYSTEM_ID) {
                accum.append(" \"").append(attribute).append("\"")
            }
        }
        accum.append(">")
    }

    override func outerHtmlTail(_ accum: StringBuilder, _ depth: Int, _ out: OutputSettings) {
    }

    private func has(_ attribute: String) -> Bool {
        if let attribute = getAttribute(withKey: attribute) {
            return !StringUtil.isBlank(attribute)
        } else {
            return false
        }
    }

	public override func copy(with zone: NSZone? = nil) -> Any {
		let clone = DocumentType(attributes!.get(key: DocumentType.NAME),
		                         attributes!.get(key: DocumentType.PUBLIC_ID),
		                         attributes!.get(key: DocumentType.SYSTEM_ID),
		                         baseURI!)
		return copy(clone: clone)
	}

	public override func copy(parent: Node?) -> Node {
		let clone = DocumentType(attributes!.get(key: DocumentType.NAME),
		                         attributes!.get(key: DocumentType.PUBLIC_ID),
		                         attributes!.get(key: DocumentType.SYSTEM_ID),
		                         baseURI!)
		return copy(clone: clone, parent: parent)
	}

	public override func copy(clone: Node, parent: Node?) -> Node {
		return super.copy(clone: clone, parent: parent)
	}

}
