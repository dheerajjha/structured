import SwiftUI
import UIKit

// MARK: - Adaptive Scale Manager
//
// Provides:
// * `scaled(_:)` — a simple point-multiplier that scales up on larger devices
//   without requiring a `GeometryReader`. Recomputed whenever the active
//   foreground window changes size (e.g. rotation / Stage Manager resize).
// * `AdaptiveLayout` — an `EnvironmentValue` with the current window width,
//   size class and a helper `isWide` flag that views can read to swap layout.
//
// Usage:
//   .font(.system(size: scaled(28), weight: .bold))
//   @Environment(\.adaptiveLayout) var layout
//   if layout.isWide { iPadLayout } else { phoneLayout }
//

private let referenceWidth: CGFloat = 390  // iPhone 14/15 Pro logical width
private let minScale: CGFloat = 1.0
private let maxScale: CGFloat = 1.6        // allow slightly larger scaling on 13" iPad

/// Lightweight observer that keeps `cachedScale` up to date as the foreground
/// window resizes. Avoids the deprecated `UIScreen.main.bounds` path.
private final class AdaptiveScaleObserver: NSObject, @unchecked Sendable {
    static let shared = AdaptiveScaleObserver()
    var cachedScale: CGFloat = 1.0

    private override init() {
        super.init()
        // Bootstrap: schedule a refresh on the main actor.
        Task { @MainActor in self.refresh() }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIScene.didActivateNotification,
            object: nil
        )
    }

    @MainActor
    @objc func refresh() {
        guard let width = Self.activeWindowWidth() else { return }
        cachedScale = clampScale(factor: width / referenceWidth)
    }

    @MainActor
    static func activeWindowWidth() -> CGFloat? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let foreground = scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first
        return foreground?.windows.first { $0.isKeyWindow }?.bounds.width
            ?? foreground?.windows.first?.bounds.width
    }
}

private func clampScale(factor: CGFloat) -> CGFloat {
    min(max(factor, minScale), maxScale)
}

/// Point multiplier applied uniformly across the app. Rotates with the window.
/// Safe to call from any context — reads a cached value refreshed on the main actor.
var deviceScaleFactor: CGFloat {
    AdaptiveScaleObserver.shared.cachedScale
}

func scaled(_ value: CGFloat) -> CGFloat { value * deviceScaleFactor }
func scaled(_ value: Double)  -> CGFloat { CGFloat(value) * deviceScaleFactor }
func scaled(_ value: Int)     -> CGFloat { CGFloat(value) * deviceScaleFactor }

// MARK: - AdaptiveLayout environment

/// Describes the container the view is rendered into.
struct AdaptiveLayout: Equatable {
    var width: CGFloat = 0
    var height: CGFloat = 0
    var horizontalSizeClass: UserInterfaceSizeClass? = nil
    var verticalSizeClass: UserInterfaceSizeClass? = nil

    /// True when we should use a two-column / side-by-side layout (iPad, landscape, Stage Manager wide).
    var isWide: Bool {
        horizontalSizeClass == .regular && width >= 700
    }

    /// Max readable content width for phones, so the main content doesn't sprawl
    /// across the full width on iPad / landscape.
    var readableContentWidth: CGFloat {
        isWide ? min(width * 0.6, 640) : width
    }
}

private struct AdaptiveLayoutKey: EnvironmentKey {
    static let defaultValue: AdaptiveLayout = AdaptiveLayout()
}

extension EnvironmentValues {
    var adaptiveLayout: AdaptiveLayout {
        get { self[AdaptiveLayoutKey.self] }
        set { self[AdaptiveLayoutKey.self] = newValue }
    }
}

/// View modifier that plumbs the live window size + size class into the
/// `adaptiveLayout` environment for the subtree.
struct AdaptiveLayoutReader: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .environment(\.adaptiveLayout, AdaptiveLayout(
                    width: geo.size.width,
                    height: geo.size.height,
                    horizontalSizeClass: hSize,
                    verticalSizeClass: vSize
                ))
        }
    }
}

extension View {
    /// Attach at the root of a scene so descendants can observe the container
    /// width/size class via `@Environment(\.adaptiveLayout)`.
    func readAdaptiveLayout() -> some View {
        modifier(AdaptiveLayoutReader())
    }

    /// Clamp a view to a comfortable max width on wide containers, centered.
    func maxContentWidth(_ layout: AdaptiveLayout, cap: CGFloat = 640) -> some View {
        frame(maxWidth: layout.isWide ? cap : .infinity)
            .frame(maxWidth: .infinity)
    }
}

/// Centers and clamps content to a comfortable width on wide containers
/// (iPad, landscape, Stage Manager) while letting it fill on phones.
struct AdaptiveContentContainer<Content: View>: View {
    @Environment(\.adaptiveLayout) private var layout
    let maxWidth: CGFloat
    @ViewBuilder let content: () -> Content

    init(maxWidth: CGFloat = 720, @ViewBuilder content: @escaping () -> Content) {
        self.maxWidth = maxWidth
        self.content = content
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            content()
                .frame(maxWidth: layout.isWide ? maxWidth : .infinity)
            Spacer(minLength: 0)
        }
    }
}
