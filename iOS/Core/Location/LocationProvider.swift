//
//  LocationProvider.swift
//  CampusMeal
//

import CoreLocation

struct Coordinates: Equatable {
    let latitude: Double
    let longitude: Double
}

/// Thin async wrapper over CLLocationManager. Never throws: a denied/undetermined-then-denied
/// permission, an OS error, or no fix all resolve to `nil` so the caller falls back to a
/// manual campus selection (issue #33 acceptance criteria — location must never block or
/// crash the app).
final class LocationProvider: NSObject {
    static let shared = LocationProvider()

    private let manager = CLLocationManager()
    private var authorizationStatus: CLAuthorizationStatus
    private var authorizationContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<Coordinates?, Never>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    /// Prompts for when-in-use permission if it hasn't been decided yet, then requests one
    /// location fix. Returns `nil` on denial, an OS error, or no fix.
    func requestCoordinates() async -> Coordinates? {
        if authorizationStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        authorizationContinuation?.resume()
        authorizationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinates = locations.last.map {
            Coordinates(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        locationContinuation?.resume(returning: coordinates)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}
