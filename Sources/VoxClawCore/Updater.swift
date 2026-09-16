#if os(macOS)
import Combine
import Sparkle

/// Wraps Sparkle's updater so SwiftUI can drive a "Check for Updates…" command
/// and reflect whether a check is currently allowed.
///
/// `SUFeedURL` (the appcast) and `SUPublicEDKey` (the EdDSA public key) are read
/// from the app's Info.plist — see `Scripts/package_app.sh`, which writes both.
@MainActor
final class VoxClawUpdater: ObservableObject {
    private let controller: SPUStandardUpdaterController?

    /// Drives the enabled state of the "Check for Updates…" menu item.
    @Published var canCheckForUpdates = false

    init() {
        // Sparkle reads SUFeedURL/SUPublicEDKey from the app's Info.plist. In an
        // unbundled build (the SwiftPM CLI binary: `swift build` -> `voxclaw --listen`)
        // there is no Info.plist, and starting the updater raises a modal NSAlert on
        // the main thread that blocks the run loop - including the HTTP listener.
        guard Bundle.main.infoDictionary?["SUFeedURL"] != nil else {
            controller = nil
            return
        }
        // startingUpdater: true begins Sparkle's scheduled background update checks.
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.controller = controller
        controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .assign(to: &$canCheckForUpdates)
    }

    /// Triggers a user-initiated update check (shows Sparkle's UI).
    func checkForUpdates() {
        controller?.updater.checkForUpdates()
    }
}
#endif
