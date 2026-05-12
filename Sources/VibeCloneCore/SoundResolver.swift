import Foundation

public enum SoundResolver {
    public static func resolve(name: String,
                               paths: Paths,
                               bundleURL: URL?,
                               fileManager: FileManager = .default) -> URL? {
        let custom = paths.dotDir
            .appendingPathComponent("custom-sounds")
            .appendingPathComponent("\(name).aiff")
        if fileManager.fileExists(atPath: custom.path) { return custom }
        if let b = bundleURL?.appendingPathComponent("\(name).aiff"),
           fileManager.fileExists(atPath: b.path) {
            return b
        }
        return nil
    }
}
