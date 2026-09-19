//
//  InventoryView.swift
//  CampusMeal
//

import SwiftUI

// Placeholder for MS7 — full inventory management (add/edit items, expiration
// tracking backed by real storage) is implemented in Sprint 2.
struct InventoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundStyle(CampusMealColors.neutral500)
            Text("Inventory")
                .font(CampusMealTypography.headingXL)
                .foregroundStyle(CampusMealColors.neutral900)
            Text("Coming in Sprint 2")
                .font(CampusMealTypography.bodyM)
                .foregroundStyle(CampusMealColors.neutral500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CampusMealColors.neutral50)
    }
}

#Preview {
    InventoryView()
}
