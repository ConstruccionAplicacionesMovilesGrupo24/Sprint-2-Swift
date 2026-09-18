import SwiftUI

/// CampusMeal type scale, matching the "Fundamentos" frame of the Figma design system.
/// Uses the same Inter font files bundled in the Android app (Core/DesignSystem/Fonts) for cross-platform parity.
enum CampusMealTypography {
    static let displayL = Font.custom("Inter-Bold", size: 32)
    static let headingXL = Font.custom("Inter-Bold", size: 24)
    static let headingL = Font.custom("Inter-SemiBold", size: 20)
    static let headingM = Font.custom("Inter-SemiBold", size: 17)
    static let bodyL = Font.custom("Inter-Regular", size: 16)
    static let bodyM = Font.custom("Inter-Regular", size: 15)
    static let bodyS = Font.custom("Inter-Regular", size: 13)
    static let labelL = Font.custom("Inter-SemiBold", size: 16)
    static let labelM = Font.custom("Inter-Medium", size: 14)
    static let labelS = Font.custom("Inter-SemiBold", size: 12)
    static let caption = Font.custom("Inter-Medium", size: 11)

    /// Line spacing = (line-height - font-size) per the Figma scale, as SwiftUI's `.lineSpacing()` is additive.
    enum LineSpacing {
        static let displayL: CGFloat = 8
        static let headingXL: CGFloat = 8
        static let headingL: CGFloat = 8
        static let headingM: CGFloat = 7
        static let bodyL: CGFloat = 8
        static let bodyM: CGFloat = 7
        static let bodyS: CGFloat = 5
        static let labelL: CGFloat = 4
        static let labelM: CGFloat = 4
        static let labelS: CGFloat = 4
        static let caption: CGFloat = 3
    }
}
