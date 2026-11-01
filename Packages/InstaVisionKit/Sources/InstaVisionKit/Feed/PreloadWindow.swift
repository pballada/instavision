import Foundation

/// Which items to keep ready around the one on screen, e.g. players for the next and previous Reel.
public enum PreloadWindow {
    /// IDs within `radius` of `current`, nearest first (current, next, previous, next+1, …).
    /// Ahead is preferred over behind because people mostly swipe forward.
    public static func ids<ID: Hashable>(around current: ID, in ids: [ID], radius: Int = 1) -> [ID] {
        guard let index = ids.firstIndex(of: current) else { return [] }
        var result = [current]
        for distance in 1...max(radius, 1) where radius > 0 {
            if ids.indices.contains(index + distance) { result.append(ids[index + distance]) }
            if ids.indices.contains(index - distance) { result.append(ids[index - distance]) }
        }
        return result
    }
}
