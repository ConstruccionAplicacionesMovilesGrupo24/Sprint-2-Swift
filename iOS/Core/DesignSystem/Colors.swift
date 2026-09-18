import SwiftUI

/// CampusMeal color tokens, taken from the "Fundamentos" frame of the CampusMeal UI Figma file.
/// Kept in sync with the Android design system (Core/DesignSystem/Color.kt).
enum CampusMealColors {
    // Brand ramp — derived from CampusMeal Orange #E6791C.
    static let brand50 = Color(hex: 0xFDF4EC)
    static let brand100 = Color(hex: 0xFAE4CE)
    static let brand300 = Color(hex: 0xEFAA6D)
    static let brand500 = Color(hex: 0xE6791C)
    static let brand600 = Color(hex: 0xC4620F)
    static let brand700 = Color(hex: 0x984511)
    static let brand900 = Color(hex: 0x4A2108)

    // Accent ramp — derived from Yellow #F1C002.
    static let accent50 = Color(hex: 0xFEF9E0)
    static let accent100 = Color(hex: 0xFDEFB3)
    static let accent300 = Color(hex: 0xF6CF28)
    static let accent500 = Color(hex: 0xF1C002)
    static let accent700 = Color(hex: 0x8F7101)

    // Sand ramp — borders and warm surfaces.
    static let sand100 = Color(hex: 0xF6F0E9)
    static let sand200 = Color(hex: 0xE9DDCE)
    static let sand300 = Color(hex: 0xD3BDA6)
    static let sand400 = Color(hex: 0xB99F84)

    // Neutrals.
    static let neutral0 = Color(hex: 0xFFFFFF)
    static let neutral50 = Color(hex: 0xF3F5F4)
    static let neutral100 = Color(hex: 0xE8EBEA)
    static let neutral200 = Color(hex: 0xD6DAD9)
    static let neutral300 = Color(hex: 0xB3BAB8)
    static let neutral500 = Color(hex: 0x6B7471)
    static let neutral700 = Color(hex: 0x3A403E)
    static let neutral900 = Color(hex: 0x22201E)

    // Positive state.
    static let positive100 = Color(hex: 0xE2EFE4)
    static let positive500 = Color(hex: 0x3D7A4E)
    static let positive700 = Color(hex: 0x2A5636)
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
