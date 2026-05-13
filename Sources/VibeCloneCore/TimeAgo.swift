import Foundation

public enum TimeAgo {
    /// "now" / "3s" / "28m" / "1h" / "5h" / "1d" / "3w" / "2y" — compact.
    public static func format(_ date: Date, relativeTo now: Date = Date()) -> String {
        let interval = max(0, now.timeIntervalSince(date))
        let secs = Int(interval)
        if secs < 5    { return "now" }
        if secs < 60   { return "\(secs)s" }
        let mins = secs / 60
        if mins < 60   { return "\(mins)m" }
        let hours = mins / 60
        if hours < 24  { return "\(hours)h" }
        let days = hours / 24
        if days < 7    { return "\(days)d" }
        let weeks = days / 7
        if weeks < 52  { return "\(weeks)w" }
        let years = days / 365
        return "\(years)y"
    }
}
