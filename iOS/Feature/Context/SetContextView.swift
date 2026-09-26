//
//  SetContextView.swift
//  CampusMeal
//

import SwiftUI

/// Form to edit the shared `MealContext`. Presented modally from Home's "Change" button.
struct SetContextView: View {
    @Environment(\.dismiss) private var dismiss
    private let contextStore = ContextStore.shared

    @State private var useDeviceLocation: Bool
    @State private var selectedCampus: CampusOption
    @State private var deviceCoordinates: Coordinates?
    @State private var isLocating = false
    @State private var locationErrorMessage: String?

    @State private var availableMinutes: Int
    @State private var maximumBudget: Int
    @State private var dietaryPreferences: Set<DietaryTag>
    @State private var includeDelivery: Bool

    init() {
        let current = ContextStore.shared.current
        switch current.locationSource {
        case .device(let coordinates):
            _useDeviceLocation = State(initialValue: true)
            _deviceCoordinates = State(initialValue: coordinates)
            _selectedCampus = State(initialValue: .uniandes)
        case .manualCampus(let campus):
            _useDeviceLocation = State(initialValue: false)
            _selectedCampus = State(initialValue: campus)
        }
        _availableMinutes = State(initialValue: current.availableMinutes)
        _maximumBudget = State(initialValue: current.maximumBudget)
        _dietaryPreferences = State(initialValue: Set(current.dietaryPreferences))
        _includeDelivery = State(initialValue: current.includeDelivery)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Toggle("Use my current location", isOn: $useDeviceLocation)
                        .onChange(of: useDeviceLocation) { _, isOn in
                            if isOn {
                                Task { await requestDeviceLocation() }
                            } else {
                                locationErrorMessage = nil
                            }
                        }
                    if isLocating {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Getting your location…")
                                .font(CampusMealTypography.bodyS)
                                .foregroundStyle(CampusMealColors.neutral500)
                        }
                    }
                    if !useDeviceLocation {
                        Picker("Campus", selection: $selectedCampus) {
                            ForEach(CampusOption.allCases) { campus in
                                Text(campus.displayName).tag(campus)
                            }
                        }
                    }
                    if let locationErrorMessage {
                        Text(locationErrorMessage)
                            .font(CampusMealTypography.bodyS)
                            .foregroundStyle(.red)
                    }
                }

                Section("Time and budget") {
                    Stepper(
                        "Available time: \(availableMinutes) min",
                        value: $availableMinutes, in: 10...120, step: 5
                    )
                    Stepper(
                        "Budget: \(CampusMealFormat.cop(maximumBudget))",
                        value: $maximumBudget, in: 0...100_000, step: 1_000
                    )
                }

                Section("Dietary preferences") {
                    ForEach(DietaryTag.allCases, id: \.self) { tag in
                        Toggle(
                            tag.label,
                            isOn: Binding(
                                get: { dietaryPreferences.contains(tag) },
                                set: { isOn in
                                    if isOn {
                                        dietaryPreferences.insert(tag)
                                    } else {
                                        dietaryPreferences.remove(tag)
                                    }
                                }
                            )
                        )
                    }
                }

                Section {
                    Toggle("Include delivery options", isOn: $includeDelivery)
                }
            }
            .navigationTitle("Your context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func requestDeviceLocation() async {
        locationErrorMessage = nil
        isLocating = true
        defer { isLocating = false }

        guard let coordinates = await LocationProvider.shared.requestCoordinates() else {
            useDeviceLocation = false
            locationErrorMessage = "Couldn't get your location. Check Settings > Privacy > Location Services, or pick a campus below."
            return
        }
        deviceCoordinates = coordinates
    }

    private func save() {
        let locationSource: MealContext.LocationSource =
            if useDeviceLocation, let deviceCoordinates {
                .device(deviceCoordinates)
            } else {
                .manualCampus(selectedCampus)
            }

        contextStore.update(
            MealContext(
                locationSource: locationSource,
                availableMinutes: availableMinutes,
                maximumBudget: maximumBudget,
                dietaryPreferences: Array(dietaryPreferences),
                includeDelivery: includeDelivery
            )
        )
        dismiss()
    }
}

#Preview {
    SetContextView()
}
