//
//  ContextStore.swift
//  CampusMeal
//

import Foundation

/// Single shared source of truth for `MealContext`, in-memory for Sprint 2 (same lifetime as
/// `SessionManager`). Home, Restaurants and Decision all read `current` instead of each
/// keeping their own copy, so editing context in one place updates every screen.
@Observable
final class ContextStore {
    static let shared = ContextStore()

    private(set) var current = MealContext()

    private init() {}

    func update(_ context: MealContext) {
        current = context
    }
}
