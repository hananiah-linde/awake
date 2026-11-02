import Foundation
import IOKit.pwr_mgt

/// Thin wrapper around an IOKit power assertion — the same mechanism `caffeinate` uses.
/// While the assertion is held, macOS won't idle-sleep. Releasing it (or quitting) restores normal behavior.
final class SleepAssertion {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    /// Keeps both the display and the system awake (PreventUserIdleDisplaySleep implies no idle system sleep).
    @discardableResult
    func begin(reason: String = "Awake is keeping this Mac awake") -> Bool {
        end()

        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        guard result == kIOReturnSuccess else {
            NSLog("Awake: failed to create power assertion (IOReturn \(result))")
            return false
        }

        assertionID = id
        isActive = true
        return true
    }

    func end() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
    }

    deinit { end() }
}
