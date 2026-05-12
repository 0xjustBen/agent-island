import Foundation
import AppKit
import VibeCloneCore

public enum SoundName: String, Sendable {
    case permission
    case notification
    case idle
}

@MainActor
final class SoundPlayer {
    private let paths: Paths
    private let bundleURL: URL?

    init(paths: Paths,
         bundleURL: URL? = Bundle.main.resourceURL?.appendingPathComponent("Sounds")) {
        self.paths = paths
        self.bundleURL = bundleURL
    }

    /// Fire-and-forget playback. No-op if `enabled` is false or sound missing.
    func play(_ name: SoundName, enabled: Bool) {
        guard enabled else { return }
        guard let url = SoundResolver.resolve(name: name.rawValue,
                                              paths: paths,
                                              bundleURL: bundleURL) else { return }
        let sound = NSSound(contentsOf: url, byReference: true)
        sound?.play()
    }
}
