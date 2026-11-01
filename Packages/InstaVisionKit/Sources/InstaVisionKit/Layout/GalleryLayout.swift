import Foundation
import simd

/// Positions for frames on a curved wall around the viewer.
public enum GalleryLayout {
    public static let radius: Float = 2.6
    public static let frameSize: Float = 0.75
    public static let spacing: Float = 0.12
    public static let rows = 2
    public static let eyeHeight: Float = 1.45

    /// Returns a position and the yaw (rotation around Y) that faces the origin, for each index.
    public static func placements(count: Int) -> [(position: SIMD3<Float>, yaw: Float)] {
        guard count > 0 else { return [] }
        let columns = Int((Double(count) / Double(rows)).rounded(.up))
        // Angular width of one frame plus gap on the arc.
        let step = (frameSize + spacing) / radius
        let start = -step * Float(columns - 1) / 2
        let rowHeight = frameSize + spacing
        let top = eyeHeight + rowHeight * Float(rows - 1) / 2

        return (0..<count).map { index in
            let column = index / rows
            let row = index % rows
            let angle = start + step * Float(column)
            let position = SIMD3<Float>(
                radius * sin(angle),
                top - rowHeight * Float(row),
                -radius * cos(angle)
            )
            return (position, -angle)
        }
    }
}
