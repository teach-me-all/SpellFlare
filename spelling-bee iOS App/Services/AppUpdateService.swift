//
//  AppUpdateService.swift
//  spelling-bee iOS App
//
//  Checks for app updates via iTunes Lookup API and manages update prompts.
//  Compliant with App Store Review Guidelines for kids apps.
//

import Foundation
import UIKit

@MainActor
class AppUpdateService: ObservableObject {
    static let shared = AppUpdateService()

    // MARK: - Published State
    @Published private(set) var updateAvailable = false
    @Published private(set) var appStoreVersion: String?

    // MARK: - Constants
    private let bundleId = "com.raves.spelling-bee-ios"
    private let dismissedVersionKey = "AppUpdateService.dismissedVersion"
    private let lastCheckKey = "AppUpdateService.lastCheckDate"
    private let minimumCheckInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - iTunes Lookup Response
    private struct iTunesLookupResponse: Codable {
        let resultCount: Int
        let results: [AppInfo]

        struct AppInfo: Codable {
            let version: String
            let trackViewUrl: String
        }
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Check for available updates (call on Home screen appear)
    func checkForUpdate() async {
        // Rate limit: don't check more than once per day
        if let lastCheck = UserDefaults.standard.object(forKey: lastCheckKey) as? Date {
            if Date().timeIntervalSince(lastCheck) < minimumCheckInterval {
                // Already checked recently, use cached state
                return
            }
        }

        guard let appStoreInfo = await fetchAppStoreInfo() else {
            // Fail silently - don't show update prompt if lookup fails
            return
        }

        // Store last check time
        UserDefaults.standard.set(Date(), forKey: lastCheckKey)

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let storeVersion = appStoreInfo.version

        // Compare versions
        guard isVersion(storeVersion, newerThan: currentVersion) else {
            // No update available
            updateAvailable = false
            appStoreVersion = nil
            return
        }

        // Check if user already dismissed this version
        let dismissedVersion = UserDefaults.standard.string(forKey: dismissedVersionKey)
        if dismissedVersion == storeVersion {
            // User already dismissed this version, don't show again
            updateAvailable = false
            return
        }

        // Update is available and not dismissed
        appStoreVersion = storeVersion
        updateAvailable = true
    }

    /// User tapped "Update" - open App Store
    func openAppStore() {
        // Use the app's App Store URL
        // Format: https://apps.apple.com/app/idXXXXXXXXX
        // Or use the generic lookup URL which redirects
        let appStoreURLString = "https://apps.apple.com/app/id\(appStoreId)"

        if let url = URL(string: appStoreURLString) {
            UIApplication.shared.open(url)
        }

        // Dismiss after opening (user made a choice)
        updateAvailable = false
    }

    /// User tapped "Later" - dismiss and remember this version
    func dismissUpdate() {
        if let version = appStoreVersion {
            UserDefaults.standard.set(version, forKey: dismissedVersionKey)
        }
        updateAvailable = false
        appStoreVersion = nil
    }

    // MARK: - Private Methods

    /// Fetch app info from iTunes Lookup API
    private func fetchAppStoreInfo() async -> iTunesLookupResponse.AppInfo? {
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=us"

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Verify response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let lookupResponse = try JSONDecoder().decode(iTunesLookupResponse.self, from: data)

            // Return first result if available
            return lookupResponse.results.first

        } catch {
            // Fail silently
            print("AppUpdateService: Failed to fetch app info - \(error.localizedDescription)")
            return nil
        }
    }

    /// Compare semantic versions (e.g., "2.1.0" vs "2.0.5")
    private func isVersion(_ version1: String, newerThan version2: String) -> Bool {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }

        // Pad shorter array with zeros
        let maxLength = max(v1Components.count, v2Components.count)
        let v1Padded = v1Components + Array(repeating: 0, count: maxLength - v1Components.count)
        let v2Padded = v2Components + Array(repeating: 0, count: maxLength - v2Components.count)

        // Compare component by component
        for i in 0..<maxLength {
            if v1Padded[i] > v2Padded[i] {
                return true
            } else if v1Padded[i] < v2Padded[i] {
                return false
            }
        }

        // Versions are equal
        return false
    }

    // MARK: - App Store ID
    // Note: Replace with your actual App Store ID once the app is published
    // You can find this in App Store Connect or from the app's App Store URL
    private var appStoreId: String {
        // Fallback to generic search if ID not set
        // This will be replaced with actual ID after first App Store submission
        return "6740543307" // Replace with actual App Store ID
    }
}
