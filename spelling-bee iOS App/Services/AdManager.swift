//
//  AdManager.swift
//  spelling-bee iOS App
//
//  Manages Google AdMob interstitial advertisements for kids app compliance.
//  Ads are shown BEFORE and AFTER tests, never during gameplay.
//  Uses COPPA-compliant non-personalized ads only.
//

import Foundation
import SwiftUI
import GoogleMobileAds

@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // MARK: - Published State
    @Published var shouldShowAd: Bool = false
    @Published var isAdLoaded: Bool = false
    @Published var isShowingAd: Bool = false
    @Published var isInitialized: Bool = false

    // MARK: - Simulator Configuration
    /// Set to true to hide ads when running in simulator (useful for development)
    var hideAdsInSimulator: Bool = true

    /// Check if running in iOS Simulator
    var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Private Properties
    private var interstitialAd: GADInterstitialAd?
    private var testsCompletedSinceLastAd: Int = 0
    private let testsBeforeAd: Int = 1  // Show ad after every completed test

    // MARK: - Ad Configuration

    // Test ad unit IDs for development (MUST use these during development)
    private let testAdUnitID = "ca-app-pub-3940256099942544/4411468910"  // Interstitial
    private let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"  // Banner

    // Production ad unit IDs from AdMob console
    // Format: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
    private let productionAdUnitID = "ca-app-pub-9359627609474299/7621244143"  // Replace with your interstitial ad unit ID
    private let productionBannerAdUnitID = "ca-app-pub-9359627609474299/7677084463"  // Replace with your banner ad unit ID

    // Current ad unit IDs (switches based on build configuration)
    private var currentAdUnitID: String {
        #if DEBUG
        return testAdUnitID
        #else
        return productionAdUnitID
        #endif
    }

    var currentBannerAdUnitID: String {
        #if DEBUG
        return testBannerAdUnitID
        #else
        return productionBannerAdUnitID
        #endif
    }

    // MARK: - Dependencies
    private var storeManager: StoreManager { StoreManager.shared }

    // MARK: - Initialization

    override init() {
        super.init()
    }

    /// Initialize Google Mobile Ads SDK
    /// MUST be called once at app launch before any ad requests
    func initializeSDK() {
        guard !isInitialized else { return }

        // Verify that GADApplicationIdentifier is set in Info.plist
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              !appID.isEmpty else {
            print("⚠️ GADApplicationIdentifier not found in Info.plist")
            print("⚠️ Ads will be disabled. Please add your AdMob App ID to Info.plist")
            isInitialized = false
            return
        }

        print("📱 Initializing Google Mobile Ads SDK with App ID: \(appID)")

        // CRITICAL: Configure SDK for child-directed treatment
        // This must be set BEFORE starting the SDK
        let requestConfiguration = GADMobileAds.sharedInstance().requestConfiguration

        // Set tag for child directed treatment
        requestConfiguration.tagForChildDirectedTreatment = true

        // Set maximum ad content rating to G (General Audiences)
        requestConfiguration.maxAdContentRating = .general

        print("🔒 SDK configured for child-directed treatment (COPPA compliant)")
        print("🔒 Maximum ad content rating: G (General Audiences)")

        // Configure for test devices
        #if DEBUG
        // Note: Simulators are automatically in test mode, no need to configure test device IDs
        print("📱 AdMob configured for test mode (simulator)")
        #endif

        // Start Google Mobile Ads SDK
        // NOTE: Do NOT initialize AppLovin separately - AdMob handles this automatically
        GADMobileAds.sharedInstance().start { [weak self] status in
            Task { @MainActor in
                self?.isInitialized = true
                print("✅ Google Mobile Ads SDK initialized successfully")
                print("📊 Mediation adapter statuses:")

                var appLovinDetected = false
                for (adapter, adapterStatus) in status.adapterStatusesByClassName {
                    let stateDescription = adapterStatus.state == .ready ? "✅ Ready" : "⏳ Not Ready"
                    print("  - \(adapter): \(stateDescription)")

                    // Check if AppLovin adapter is loaded
                    if adapter.lowercased().contains("applovin") {
                        appLovinDetected = true
                        print("    🎮 AppLovin mediation adapter detected!")
                    }
                }

                if appLovinDetected {
                    print("✅ AppLovin mediation is configured and ready")
                    print("   AppLovin will fill ads when Google AdMob has no inventory")
                } else {
                    print("ℹ️ AppLovin adapter not detected - ensure AdMob console is configured")
                }

                // Preload first ad after initialization
                await self?.loadAd()
            }
        }
    }

    // MARK: - Ad Loading

    /// Load an interstitial ad
    func loadAd() async {
        // Don't load ads if user purchased "Remove Ads" or in simulator
        guard adsEnabled else {
            if hideAdsInSimulator && isRunningInSimulator {
                print("⏭️ Ads disabled (running in simulator with hideAdsInSimulator=true)")
            } else {
                print("⏭️ Ads disabled (user purchased Remove Ads)")
            }
            return
        }

        // Don't load if SDK not initialized
        guard isInitialized else {
            print("⚠️ Cannot load ad: SDK not initialized")
            return
        }

        print("🔄 Loading interstitial ad...")

        // Create COPPA-compliant ad request
        let request = createChildSafeAdRequest()

        do {
            // Load interstitial ad
            let ad = try await GADInterstitialAd.load(
                withAdUnitID: currentAdUnitID,
                request: request
            )

            // Set delegate
            ad.fullScreenContentDelegate = self

            // Store the ad
            interstitialAd = ad
            isAdLoaded = true

            print("✅ Interstitial ad loaded successfully (child-safe)")

            // MARK: - Mediation Verification Logging
            // Log which ad network served the ad (for verifying AppLovin mediation)
            logMediationInfo(for: ad)

        } catch {
            print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
            isAdLoaded = false
            interstitialAd = nil
        }
    }

    // MARK: - Child-Safe Ad Request Configuration

    /// Creates a COPPA-compliant ad request for kids apps
    /// This ensures only age-appropriate, non-personalized ads are shown
    private func createChildSafeAdRequest() -> GADRequest {
        let request = GADRequest()

        // CRITICAL: Tag for child-directed treatment (COPPA compliance)
        // This tells Google AdMob to ONLY serve ads appropriate for children
        let extras = GADExtras()
        extras.additionalParameters = [
            "tag_for_child_directed_treatment": "1",  // Enforce child-directed ads
            "max_ad_content_rating": "G"              // General Audiences only
        ]
        request.register(extras)

        // Additional safety: Mark as kids app
        request.requestAgent = "kids_app"

        print("📋 Ad request configured for child-directed treatment (COPPA compliant)")

        return request
    }

    // MARK: - Mediation Verification

    /// Logs which ad network served the ad (for verifying mediation is working)
    /// When AppLovin fills, you'll see: com.google.ads.mediation.applovin
    private func logMediationInfo(for ad: GADInterstitialAd) {
        let responseInfo = ad.responseInfo

        // Log the winning ad network
        if let loadedAdNetworkInfo = responseInfo.loadedAdNetworkResponseInfo {
            let adNetworkClassName = loadedAdNetworkInfo.adNetworkClassName
            print("🏆 Ad served by: \(adNetworkClassName)")

            // Check if AppLovin served the ad
            if adNetworkClassName.contains("applovin") {
                print("📱 AppLovin mediation fill - Google AdMob had no inventory")
            } else if adNetworkClassName.contains("GADMediationAdapter") ||
                      adNetworkClassName.contains("google") {
                print("📱 Google AdMob fill - primary network served the ad")
            }

            // Log latency for performance monitoring
            let latency = loadedAdNetworkInfo.latency
            print("⏱️ Ad load latency: \(String(format: "%.2f", latency))s")
        }

        // Log the full waterfall for debugging (shows all networks tried)
        print("📊 Mediation waterfall:")
        for (index, adNetworkInfo) in responseInfo.adNetworkInfoArray.enumerated() {
            let networkName = adNetworkInfo.adNetworkClassName
            let errorDescription = adNetworkInfo.error?.localizedDescription ?? "No error"
            let latency = adNetworkInfo.latency

            if adNetworkInfo.error != nil {
                print("  \(index + 1). \(networkName) - ❌ No fill (\(errorDescription))")
            } else {
                print("  \(index + 1). \(networkName) - ✅ Filled in \(String(format: "%.2f", latency))s")
            }
        }

        // Log mediation adapter info from SDK initialization
        print("📋 Response ID: \(responseInfo.responseIdentifier ?? "N/A")")
    }

    // MARK: - Ad Display Logic

    /// Call this when a test is completed to determine if an ad should be shown
    func onTestCompleted() {
        // Don't show ads if user purchased "Remove Ads"
        guard adsEnabled else {
            shouldShowAd = false
            return
        }

        testsCompletedSinceLastAd += 1

        // Show ad after completing required number of tests
        if testsCompletedSinceLastAd >= testsBeforeAd {
            shouldShowAd = true
            testsCompletedSinceLastAd = 0
            print("📺 Post-test ad ready to show")
        }
    }

    /// Show interstitial ad
    func showAd(from viewController: UIViewController) {
        guard adsEnabled else {
            print("⏭️ Skipping ad (user purchased Remove Ads)")
            return
        }

        guard let ad = interstitialAd, isAdLoaded else {
            print("⚠️ No ad available to show, proceeding without ad")
            onAdDismissed()
            return
        }

        print("📺 Presenting interstitial ad...")
        isShowingAd = true
        ad.present(fromRootViewController: viewController)
    }

    /// Call this when the ad has been shown or dismissed
    func onAdDismissed() {
        shouldShowAd = false
        isShowingAd = false
        isAdLoaded = false
        interstitialAd = nil

        print("✅ Ad dismissed, preloading next ad...")

        // Preload next ad
        Task {
            await loadAd()
        }
    }

    /// Call this to skip showing the ad (e.g., if ad failed to load)
    func skipAd() {
        shouldShowAd = false
        isShowingAd = false
        print("⏭️ Ad skipped")

        // Try to load an ad for next time
        if !isAdLoaded {
            Task {
                await loadAd()
            }
        }
    }

    /// Check if ads should be shown (respects purchase state and simulator setting)
    var adsEnabled: Bool {
        // Hide ads if user purchased "Remove Ads"
        if storeManager.isAdsRemoved {
            return false
        }

        // Hide ads in simulator if configured
        if hideAdsInSimulator && isRunningInSimulator {
            return false
        }

        return true
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdManager: GADFullScreenContentDelegate {

    nonisolated func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("📊 Ad impression recorded")
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("❌ Ad failed to present: \(error.localizedDescription)")
            self.onAdDismissed()
        }
    }

    nonisolated func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("📺 Ad will present")
    }

    nonisolated func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("📺 Ad will dismiss")
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            print("✅ Ad dismissed by user")
            self.onAdDismissed()
        }
    }
}

// MARK: - Pre-Test Ad View (Shows Google AdMob interstitial before test starts)
struct PreTestAdView: View {
    @ObservedObject var adManager = AdManager.shared
    let level: Int
    let onDismiss: () -> Void

    var body: some View {
        AdMobInterstitialViewWrapper(onDismiss: onDismiss)
            .onAppear {
                print("📺 Pre-test ad view appeared for level \(level)")
            }
    }
}

// MARK: - Post-Test Ad Wrapper (Shows real Google AdMob interstitial)
struct PostTestAdView: View {
    @ObservedObject var adManager = AdManager.shared
    let onDismiss: () -> Void

    var body: some View {
        AdMobInterstitialViewWrapper(onDismiss: onDismiss)
            .onAppear {
                print("📺 Post-test ad view appeared")
            }
    }
}

// MARK: - UIViewControllerRepresentable for AdMob Interstitial
struct AdMobInterstitialViewWrapper: UIViewControllerRepresentable {
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> AdMobViewController {
        let vc = AdMobViewController()
        vc.onDismiss = onDismiss
        return vc
    }

    func updateUIViewController(_ uiViewController: AdMobViewController, context: Context) {}
}

class AdMobViewController: UIViewController {
    var onDismiss: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Task { @MainActor in
            // Small delay to ensure view is fully presented
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Show the ad
            AdManager.shared.showAd(from: self)

            // If ad fails or isn't loaded, dismiss immediately
            if !AdManager.shared.isAdLoaded {
                onDismiss?()
            }
        }
    }
}

// MARK: - Banner Ad View (Simple display banner for game screen)
struct BannerAdView: View {
    @ObservedObject var adManager = AdManager.shared
    @ObservedObject var storeManager = StoreManager.shared

    var body: some View {
        Group {
            if adManager.adsEnabled {
                BannerAdViewWrapper()
                    .frame(height: 50)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

// MARK: - UIViewRepresentable for GADBannerView
struct BannerAdViewWrapper: UIViewRepresentable {

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)

        // Configure banner
        banner.adUnitID = AdManager.shared.currentBannerAdUnitID

        // Find root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
        }

        // Create child-safe COPPA-compliant request
        let request = GADRequest()

        // CRITICAL: Tag for child-directed treatment (COPPA compliance)
        let extras = GADExtras()
        extras.additionalParameters = [
            "tag_for_child_directed_treatment": "1",  // Enforce child-directed ads
            "max_ad_content_rating": "G"              // General Audiences only
        ]
        request.register(extras)
        request.requestAgent = "kids_app"

        // Load ad
        banner.load(request)

        print("📱 Banner ad loading (child-safe, COPPA compliant)...")

        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // No updates needed
    }
}
