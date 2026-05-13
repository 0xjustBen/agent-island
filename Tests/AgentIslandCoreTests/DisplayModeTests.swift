import Testing
import Foundation
@testable import AgentIslandCore

@Test func displayMode_cases() {
    #expect(DisplayMode.allCases.count == 3)
    #expect(DisplayMode(rawValue: "notch") == .notch)
    #expect(DisplayMode(rawValue: "floatingBar") == .floatingBar)
    #expect(DisplayMode(rawValue: "menuBarOnly") == .menuBarOnly)
}

@Test func notchExpandStyle_cases() {
    #expect(NotchExpandStyle.allCases.count == 2)
    #expect(NotchExpandStyle(rawValue: "auto") == .auto)
    #expect(NotchExpandStyle(rawValue: "pinned") == .pinned)
}

@Test func roundTrip_via_jsonCoder() throws {
    let modes: [DisplayMode] = [.notch, .floatingBar, .menuBarOnly]
    for m in modes {
        let data = try JSONEncoder().encode(m)
        let back = try JSONDecoder().decode(DisplayMode.self, from: data)
        #expect(back == m)
    }
}
