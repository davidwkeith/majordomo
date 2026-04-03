import Foundation
import Testing
@testable import Majordomo

@Test func decodesMinimalPhoneManifest() throws {
    let json = """
    {
      "name": "Chase Credit Card Support",
      "id": "com.chase.support.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "Call Chase credit card support.",
      "endpoint": {
        "type": "phone",
        "address": "tel:+18004322000",
        "label": "Chase Credit Card Support"
      }
    }
    """.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(EndpointManifest.self, from: json)

    #expect(manifest.name == "Chase Credit Card Support")
    #expect(manifest.id == "com.chase.support.majordomo-plugin")
    #expect(manifest.type == "endpoint")
    #expect(manifest.version == "1.0.0")
    #expect(manifest.description == "Call Chase credit card support.")
    #expect(manifest.endpoint.type == "phone")
    #expect(manifest.endpoint.address == "tel:+18004322000")
    #expect(manifest.endpoint.label == "Chase Credit Card Support")
    #expect(manifest.endpoint.baseURL == nil)
    #expect(manifest.endpoint.auth == nil)
    #expect(manifest.tools == nil)
    #expect(manifest.prompts == nil)
    #expect(manifest.toolPrefix == nil)
    #expect(manifest.capabilities == nil)
}

@Test func decodesWebAPIManifestWithAuthAndTools() throws {
    let json = """
    {
      "name": "GitHub API",
      "id": "com.github.api.majordomo-plugin",
      "type": "endpoint",
      "version": "2.0.0",
      "description": "GitHub REST API.",
      "endpoint": {
        "type": "https",
        "base_url": "https://api.github.com",
        "auth": { "type": "bearer", "keychain_key": "github_token" }
      },
      "tools": [
        {
          "name": "list_repos",
          "description": "List repositories for the authenticated user.",
          "handler": "https",
          "annotations": { "readOnlyHint": true, "openWorldHint": true }
        }
      ],
      "prompts": [
        {
          "type": "coworker",
          "file": "prompts/coworker.md",
          "description": "GitHub API behavioral constraints."
        }
      ]
    }
    """.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(EndpointManifest.self, from: json)

    #expect(manifest.endpoint.type == "https")
    #expect(manifest.endpoint.baseURL == "https://api.github.com")
    #expect(manifest.endpoint.auth?.type == "bearer")
    #expect(manifest.endpoint.auth?.keychainKey == "github_token")

    let tool = try #require(manifest.tools?.first)
    #expect(tool.name == "list_repos")
    #expect(tool.handler == "https")
    #expect(tool.annotations?["readOnlyHint"] == true)
    #expect(tool.annotations?["openWorldHint"] == true)

    let prompt = try #require(manifest.prompts?.first)
    #expect(prompt.type == "coworker")
    #expect(prompt.file == "prompts/coworker.md")
}

@Test func decodesRSSManifest() throws {
    let json = """
    {
      "name": "AP News",
      "id": "com.apnews.feed.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "AP News top stories feed.",
      "endpoint": {
        "type": "rss",
        "address": "https://feeds.apnews.com/rss/apf-topnews",
        "label": "AP News Top Stories"
      }
    }
    """.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(EndpointManifest.self, from: json)
    #expect(manifest.endpoint.type == "rss")
    #expect(manifest.endpoint.address == "https://feeds.apnews.com/rss/apf-topnews")
}

@Test func decodesManifestWithToolPrefixAndCapabilities() throws {
    let json = """
    {
      "name": "Bedroom TV",
      "id": "com.samsung.tv.bedroom.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "Samsung TV in the bedroom.",
      "endpoint": {
        "type": "lan-ws",
        "address": "lan://192.168.1.50:8001",
        "label": "Bedroom Samsung TV"
      },
      "tool_prefix": "bedroom_tv",
      "capabilities": {
        "power": { "type": "boolean" },
        "volume": { "type": "integer", "min": 0, "max": 100 },
        "input": { "type": "string", "enum": ["hdmi1", "hdmi2", "tv"] },
        "brightness": { "type": "integer", "min": 0, "max": 100 }
      }
    }
    """.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(EndpointManifest.self, from: json)
    #expect(manifest.toolPrefix == "bedroom_tv")

    let caps = try #require(manifest.capabilities)
    #expect(caps.count == 4)

    let power = try #require(caps["power"])
    #expect(power.type == "boolean")
    #expect(power.readonly == nil)

    let volume = try #require(caps["volume"])
    #expect(volume.type == "integer")
    #expect(volume.min == 0)
    #expect(volume.max == 100)

    let input = try #require(caps["input"])
    #expect(input.type == "string")
    #expect(input.enumValues == ["hdmi1", "hdmi2", "tv"])
}

@Test func decodesReadonlyCapability() throws {
    let json = """
    {
      "name": "Sensor",
      "id": "com.sensor.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "Temperature sensor.",
      "endpoint": {
        "type": "lan-http",
        "address": "lan://192.168.1.99:80",
        "label": "Temp Sensor"
      },
      "capabilities": {
        "humidity": { "type": "number", "unit": "percent", "readonly": true },
        "battery": { "type": "integer", "min": 0, "max": 100, "readonly": true }
      }
    }
    """.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(EndpointManifest.self, from: json)
    let caps = try #require(manifest.capabilities)

    let humidity = try #require(caps["humidity"])
    #expect(humidity.type == "number")
    #expect(humidity.unit == "percent")
    #expect(humidity.readonly == true)

    let battery = try #require(caps["battery"])
    #expect(battery.readonly == true)
}

@Test func encodesManifestRoundTrip() throws {
    let json = """
    {
      "name": "Test Plugin",
      "id": "com.test.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "A test plugin.",
      "endpoint": {
        "type": "https",
        "base_url": "https://example.com",
        "auth": { "type": "bearer", "keychain_key": "test_key" }
      }
    }
    """.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(EndpointManifest.self, from: json)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let reEncoded = try encoder.encode(decoded)
    let reDecoded = try JSONDecoder().decode(EndpointManifest.self, from: reEncoded)

    #expect(reDecoded.name == decoded.name)
    #expect(reDecoded.id == decoded.id)
    #expect(reDecoded.endpoint.type == decoded.endpoint.type)
    #expect(reDecoded.endpoint.baseURL == decoded.endpoint.baseURL)
    #expect(reDecoded.endpoint.auth?.type == decoded.endpoint.auth?.type)
    #expect(reDecoded.endpoint.auth?.keychainKey == decoded.endpoint.auth?.keychainKey)
}
