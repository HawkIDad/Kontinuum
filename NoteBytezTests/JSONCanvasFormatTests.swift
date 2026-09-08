// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JSONCanvasFormatTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

struct JSONCanvasFormatTests {

    @Test func nodeEncodesUsingTheSpecsFieldNames() throws {
        let node = JSONCanvasNode(id: "n1", type: .file, x: 10, y: 20, width: 240, height: 140, color: "#FF0000", file: "Suspect A.md")
        let data = try JSONEncoder().encode(node)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"id\":\"n1\""))
        #expect(json.contains("\"type\":\"file\""))
        #expect(json.contains("\"file\":\"Suspect A.md\""))
        #expect(json.contains("\"color\":\"#FF0000\""))
    }

    @Test func nodeDecodesEveryType() throws {
        let json = """
        {"nodes":[
            {"id":"1","type":"text","x":0,"y":0,"width":100,"height":100,"text":"Freeform"},
            {"id":"2","type":"file","x":0,"y":0,"width":100,"height":100,"file":"Note.md"},
            {"id":"3","type":"link","x":0,"y":0,"width":100,"height":100,"url":"https://example.com"},
            {"id":"4","type":"group","x":0,"y":0,"width":100,"height":100,"label":"Suspects"}
        ],"edges":[]}
        """
        let document = try JSONDecoder().decode(JSONCanvasDocument.self, from: Data(json.utf8))

        #expect(document.nodes.count == 4)
        #expect(document.nodes[0].type == .text && document.nodes[0].text == "Freeform")
        #expect(document.nodes[1].type == .file && document.nodes[1].file == "Note.md")
        #expect(document.nodes[2].type == .link && document.nodes[2].url == "https://example.com")
        #expect(document.nodes[3].type == .group && document.nodes[3].label == "Suspects")
    }

    @Test func nodeDecodeFallsBackLenientlyOnMissingGeometry() throws {
        let json = """
        {"id":"1","type":"text","text":"No geometry given"}
        """
        let node = try JSONDecoder().decode(JSONCanvasNode.self, from: Data(json.utf8))
        #expect(node.x == 0)
        #expect(node.y == 0)
        #expect(node.width == 0)
        #expect(node.height == 0)
    }

    @Test func edgeDecodesFromSideToSideColorAndLabel() throws {
        let json = """
        {"id":"e1","fromNode":"1","fromSide":"right","toNode":"2","toSide":"left","color":"#00FF00","label":"reveals"}
        """
        let edge = try JSONDecoder().decode(JSONCanvasEdge.self, from: Data(json.utf8))
        #expect(edge.fromNode == "1")
        #expect(edge.fromSide == "right")
        #expect(edge.toNode == "2")
        #expect(edge.toSide == "left")
        #expect(edge.color == "#00FF00")
        #expect(edge.label == "reveals")
    }

    @Test func documentRoundTripsThroughEncodeAndDecode() throws {
        let original = JSONCanvasDocument(
            nodes: [JSONCanvasNode(id: "1", type: .group, x: 5, y: 5, width: 300, height: 200, label: "Suspects")],
            edges: [JSONCanvasEdge(id: "e1", fromNode: "1", fromSide: nil, toNode: "1", toSide: nil, color: nil, label: nil)]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONCanvasDocument.self, from: data)

        #expect(decoded.nodes.count == 1)
        #expect(decoded.nodes.first?.label == "Suspects")
        #expect(decoded.edges.count == 1)
        #expect(decoded.edges.first?.id == "e1")
    }

}
