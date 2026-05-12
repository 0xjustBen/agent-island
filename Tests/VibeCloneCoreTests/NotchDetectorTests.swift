import Testing
import Foundation
@testable import VibeCloneCore

@Test func info_returns_notch_when_topInset_positive() {
    let i = NotchDetector.info(safeAreaTop: 32)
    #expect(i.hasNotch == true)
    #expect(i.notchHeight == 32)
    #expect(i.notchWidth == 180)
}

@Test func info_returns_no_notch_when_topInset_zero() {
    let i = NotchDetector.info(safeAreaTop: 0)
    #expect(i.hasNotch == false)
    #expect(i.notchWidth == 0)
    #expect(i.notchHeight == 0)
}

@Test func notchInfo_is_equatable() {
    let a = NotchInfo(hasNotch: true, notchWidth: 180, notchHeight: 32)
    let b = NotchInfo(hasNotch: true, notchWidth: 180, notchHeight: 32)
    let c = NotchInfo(hasNotch: false, notchWidth: 0, notchHeight: 0)
    #expect(a == b)
    #expect(a != c)
}
