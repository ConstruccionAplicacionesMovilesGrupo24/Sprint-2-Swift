//
//  InventoryModels.swift
//  CampusMeal
//

import Foundation

// Field names match the backend contract exactly (CampusMealBack docs/API_CONTRACT.md §9,
// Android `InventoryItemDto` / `ExpiringInventoryResponseDto`). All seven item fields are
// always present and never null.

struct InventoryItemDTO: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let quantity: Double
    let unit: String
    // Calendar date "YYYY-MM-DD" — kept as String, it is not an instant.
    let expirationDate: String
    // Calculated by the backend in America/Bogota. Never recomputed on the client.
    let remainingDays: Int
    let active: Bool
}

struct ExpiringInventoryResponse: Decodable {
    // Already in BQ2 priority order; the UI displays it as received.
    let items: [InventoryItemDTO]
}

extension InventoryItemDTO {
    var isDueToday: Bool { remainingDays <= 0 }

    var expirationLabel: String {
        isDueToday
            ? "Due today"
            : "Due in \(remainingDays) day\(remainingDays == 1 ? "" : "s")"
    }

    // "1 L", "0.5 kg", "6 units" — drops a trailing ".0".
    var quantityDescription: String {
        let amount = quantity.rounded() == quantity
            ? String(Int(quantity))
            : quantity.formatted(.number.precision(.fractionLength(0...2)))
        return "\(amount) \(unit)"
    }
}
