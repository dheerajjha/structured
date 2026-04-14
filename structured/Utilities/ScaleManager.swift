import SwiftUI

// MARK: - Adaptive Scale Manager
//
// Provides a single scale factor based on screen width.
// iPhone (~390 pt) → 1.0×   iPad (~768–1024 pt) → up to 1.35×
//
// Usage:
//   .font(.system(size: scaled(28), weight: .bold))
//   .padding(.horizontal, scaled(16))
//   .frame(width: scaled(52), height: scaled(52))

/// Global reference width (iPhone 14/15 logical width).
private let referenceWidth: CGFloat = 390

/// Cached scale factor — computed once from the main screen width.
/// Clamped to [1.0, 1.35] so iPhones stay unchanged and iPads scale up.
let deviceScaleFactor: CGFloat = {
    let screenWidth = UIScreen.main.bounds.width
    let factor = screenWidth / referenceWidth
    return min(max(factor, 1.0), 1.35)
}()

/// Scale a point value for the current device.
///
/// On iPhone the value passes through unchanged.
/// On iPad it is multiplied by up to 1.35×.
///
/// ```swift
/// .font(.system(size: scaled(20)))
/// .padding(scaled(16))
/// ```
func scaled(_ value: CGFloat) -> CGFloat {
    value * deviceScaleFactor
}

/// Convenience overload for `Double` literals.
func scaled(_ value: Double) -> CGFloat {
    CGFloat(value) * deviceScaleFactor
}

/// Convenience overload for `Int` literals.
func scaled(_ value: Int) -> CGFloat {
    CGFloat(value) * deviceScaleFactor
}
