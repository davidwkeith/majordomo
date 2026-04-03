import Foundation
import Testing
@testable import Majordomo

@Test func generatesGetAndSetToolsForReadWriteCapability() {
    let spec = CapabilitySpec(type: "boolean", min: nil, max: nil, unit: nil, readonly: nil, enumValues: nil)
    let tools = CapabilityToolGenerator.generateTools(
        capabilityName: "power",
        spec: spec,
        prefix: "bedroom_tv"
    )

    #expect(tools.count == 2)

    let getTool = tools.first { $0.name == "bedroom_tv_get_power" }!
    #expect(getTool.description.contains("power"))

    let setTool = tools.first { $0.name == "bedroom_tv_set_power" }!
    #expect(setTool.description.contains("power"))
}

@Test func generatesOnlyGetToolForReadonlyCapability() {
    let spec = CapabilitySpec(type: "integer", min: 0, max: 100, unit: nil, readonly: true, enumValues: nil)
    let tools = CapabilityToolGenerator.generateTools(
        capabilityName: "battery",
        spec: spec,
        prefix: "sensor"
    )

    #expect(tools.count == 1)
    #expect(tools[0].name == "sensor_get_battery")
}

@Test func generatesToolsWithoutPrefix() {
    let spec = CapabilitySpec(type: "boolean", min: nil, max: nil, unit: nil, readonly: nil, enumValues: nil)
    let tools = CapabilityToolGenerator.generateTools(
        capabilityName: "power",
        spec: spec,
        prefix: nil
    )

    #expect(tools.count == 2)
    #expect(tools[0].name == "get_power")
    #expect(tools[1].name == "set_power")
}

@Test func generatesToolsForAllCapabilitiesInManifest() throws {
    let json = """
    {
      "name": "TV",
      "id": "com.tv.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "A TV.",
      "endpoint": { "type": "lan-ws", "address": "lan://10.0.0.1:8001" },
      "tool_prefix": "living_room_tv",
      "capabilities": {
        "power": { "type": "boolean" },
        "volume": { "type": "integer", "min": 0, "max": 100 },
        "input": { "type": "string", "enum": ["hdmi1", "hdmi2"] },
        "battery": { "type": "integer", "min": 0, "max": 100, "readonly": true }
      }
    }
    """.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(EndpointManifest.self, from: json)
    let tools = CapabilityToolGenerator.generateAllTools(from: manifest)

    // power: get + set = 2, volume: get + set = 2, input: get + set = 2, battery: get only = 1
    #expect(tools.count == 7)

    let toolNames = Set(tools.map(\.name))
    #expect(toolNames.contains("living_room_tv_get_power"))
    #expect(toolNames.contains("living_room_tv_set_power"))
    #expect(toolNames.contains("living_room_tv_get_volume"))
    #expect(toolNames.contains("living_room_tv_set_volume"))
    #expect(toolNames.contains("living_room_tv_get_input"))
    #expect(toolNames.contains("living_room_tv_set_input"))
    #expect(toolNames.contains("living_room_tv_get_battery"))
    #expect(!toolNames.contains("living_room_tv_set_battery"))
}

@Test func generatesNoToolsWhenNoCapabilities() throws {
    let json = """
    {
      "name": "API",
      "id": "com.api.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "An API.",
      "endpoint": { "type": "https", "base_url": "https://example.com" }
    }
    """.data(using: .utf8)!

    let manifest = try JSONDecoder().decode(EndpointManifest.self, from: json)
    let tools = CapabilityToolGenerator.generateAllTools(from: manifest)
    #expect(tools.isEmpty)
}

@Test func getToolDescriptionIncludesTypeInfo() {
    let spec = CapabilitySpec(type: "integer", min: 0, max: 100, unit: "percent", readonly: nil, enumValues: nil)
    let tools = CapabilityToolGenerator.generateTools(
        capabilityName: "brightness",
        spec: spec,
        prefix: "lamp"
    )

    let getTool = tools.first { $0.name == "lamp_get_brightness" }!
    #expect(getTool.description.contains("brightness"))

    let setTool = tools.first { $0.name == "lamp_set_brightness" }!
    #expect(setTool.description.contains("brightness"))
}

@Test func setToolDescriptionIncludesEnumValues() {
    let spec = CapabilitySpec(type: "string", min: nil, max: nil, unit: nil, readonly: nil, enumValues: ["hdmi1", "hdmi2", "tv"])
    let tools = CapabilityToolGenerator.generateTools(
        capabilityName: "input",
        spec: spec,
        prefix: "tv"
    )

    let setTool = tools.first { $0.name == "tv_set_input" }!
    #expect(setTool.description.contains("hdmi1"))
}
