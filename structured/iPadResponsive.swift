import SwiftUI

// MARK: - Responsive layout helpers
//
// On iPad, an unconstrained content stack stretches edge-to-edge,
// which makes CTA buttons span 700+ points (uncomfortable to tap with
// a thumb) and onboarding subtitles span lines so wide they're tiring
// to read. These helpers cap content at a comfortable
// reading/interaction width on large screens while leaving phones
// unaffected — phones are already narrower than every cap we apply.
//
// The pattern is intentionally a no-op on phones rather than a
// branched layout: SwiftUI's `frame(maxWidth:)` only kicks in when the
// proposed width exceeds the cap, so iPhone widths (393–430pt) stay
// fully fluid and we don't fork two layouts to maintain.

extension View {
    /// Caps the view at `maxWidth` and centers it inside its parent.
    /// Phones never hit the cap so they render unchanged. Use on
    /// onboarding text blocks and CTA buttons that would otherwise
    /// stretch to the full ~744pt iPad width.
    func iPadCappedWidth(_ maxWidth: CGFloat = 520) -> some View {
        // Two-frame trick: the inner frame caps the content's width
        // and centers its own children; the outer infinity frame fills
        // the parent width and centers the capped block within it.
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Forces a page-style sheet presentation on iPad so modal sheets
    /// (e.g. paywall, picker sheets) don't render as a tiny centered
    /// formSheet that truncates their content. iPhone is unaffected —
    /// its sheets already span the full screen width.
    @ViewBuilder
    func iPadPageSheet() -> some View {
        if #available(iOS 18.0, *) {
            self.presentationSizing(.page)
        } else {
            self.frame(idealWidth: 700, idealHeight: 900)
        }
    }
}
