import Foundation

public enum DiffLine: Hashable, Sendable {
    case context(String)
    case added(String)
    case removed(String)
}

public enum TextDiffer {
    /// Simple LCS-based line diff. Output is in source-then-target order
    /// suitable for unified-diff-style rendering.
    public static func diff(old: String, new: String) -> [DiffLine] {
        let a = old.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let b = new.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let lcs = lcsTable(a, b)
        var i = a.count, j = b.count
        var out: [DiffLine] = []
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && a[i-1] == b[j-1] {
                out.append(.context(a[i-1])); i -= 1; j -= 1
            } else if j > 0 && (i == 0 || lcs[i][j-1] >= lcs[i-1][j]) {
                out.append(.added(b[j-1])); j -= 1
            } else if i > 0 && (j == 0 || lcs[i][j-1] < lcs[i-1][j]) {
                out.append(.removed(a[i-1])); i -= 1
            }
        }
        return out.reversed()
    }

    /// Count added / removed lines.
    public static func stats(_ lines: [DiffLine]) -> (added: Int, removed: Int) {
        var added = 0; var removed = 0
        for line in lines {
            switch line {
            case .added:   added += 1
            case .removed: removed += 1
            case .context: break
            }
        }
        return (added, removed)
    }

    private static func lcsTable(_ a: [String], _ b: [String]) -> [[Int]] {
        let n = a.count; let m = b.count
        var t = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        if n == 0 || m == 0 { return t }
        for i in 1...n {
            for j in 1...m {
                if a[i-1] == b[j-1] { t[i][j] = t[i-1][j-1] + 1 }
                else { t[i][j] = max(t[i-1][j], t[i][j-1]) }
            }
        }
        return t
    }
}
