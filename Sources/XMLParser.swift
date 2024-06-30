import Foundation

/// An XML parser.
public class XMLParser: MarkupParser {
    /// Create an XML parser.
    public init() {
        super.init(XmlTreeBuilder())
    }

    /// Parse a fragment of XML into a list of nodes.
    ///
    /// - Parameters:
    ///     - fragmentXML: The fragment of XML to parse.
    ///     - baseURI: Base URI of document for resolving relative URLs. To see how it can be used, see ``Node/absoluteURLPath(ofAttribute:)``.
    /// - Returns: An array of nodes parsed from the input XML. If parser failed to parse the XML string, returns `nil` instead.
    public static func parseXMLFragment(_ fragmentXML: String, baseURI: String = "") -> [Node]? {
        let treeBuilder: XmlTreeBuilder = XmlTreeBuilder()
        return try? treeBuilder.parseFragment(fragmentXML, baseURI, ParseErrorList.noTracking(), treeBuilder.defaultSettings())
    }
}
