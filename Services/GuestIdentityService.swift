// GuestIdentityService.swift
// Handles stable local guest installation identity, guest mode state, and auth boundaries.

import Foundation
import SwiftUI
import Combine

public enum AuthState {
    case guest(installationId: String)
    case authenticated(userId: String, email: String)
}

public final class GuestIdentityService: ObservableObject {
    public static let shared = GuestIdentityService()

    private let installationKey = "SplidWise.Guest.InstallationId"
    private let guestNameKey = "SplidWise.Guest.DisplayName"
    private let authUserKey = "SplidWise.Auth.UserId"
    private let authEmailKey = "SplidWise.Auth.Email"

    @Published public private(set) var installationId: String
    @Published public var guestDisplayName: String
    @Published public private(set) var authenticatedUserId: String?
    @Published public private(set) var authenticatedEmail: String?

    public var isGuest: Bool {
        return authenticatedUserId == nil
    }

    public var currentUserId: String {
        return authenticatedUserId ?? installationId
    }

    private init() {
        // Retrieve or generate a stable local installation identifier
        if let storedId = UserDefaults.standard.string(forKey: installationKey), !storedId.isEmpty {
            self.installationId = storedId
        } else {
            let newId = "guest_" + UUID().uuidString
            UserDefaults.standard.set(newId, forKey: installationKey)
            self.installationId = newId
        }

        self.guestDisplayName = UserDefaults.standard.string(forKey: guestNameKey) ?? "Guest User"
        self.authenticatedUserId = UserDefaults.standard.string(forKey: authUserKey)
        self.authenticatedEmail = UserDefaults.standard.string(forKey: authEmailKey)
    }

    public func setGuestDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.guestDisplayName = trimmed
        UserDefaults.standard.set(trimmed, forKey: guestNameKey)
    }

    /// Logs into an authenticated account. Does NOT automatically merge private local guest data
    /// without explicit user consent.
    public func simulateLogin(userId: String, email: String) {
        self.authenticatedUserId = userId
        self.authenticatedEmail = email
        UserDefaults.standard.set(userId, forKey: authUserKey)
        UserDefaults.standard.set(email, forKey: authEmailKey)
    }

    /// Logs out. Preserves all local guest data without accidental deletion.
    public func logout() {
        self.authenticatedUserId = nil
        self.authenticatedEmail = nil
        UserDefaults.standard.removeObject(forKey: authUserKey)
        UserDefaults.standard.removeObject(forKey: authEmailKey)
    }

    /// Returns a user-friendly explanatory message when an action requires authentication.
    public func promptForFeatureRequiringAuth(featureName: String) -> String {
        return "The feature '\(featureName)' requires a registered account for cloud sharing and cross-device sync. You can continue using full offline calculations and local groups as a guest without an account."
    }
}
