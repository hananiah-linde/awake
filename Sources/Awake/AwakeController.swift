import AppKit
import Foundation
import ServiceManagement

enum AwakeDuration: Hashable, Identifiable {
    case indefinitely
    case minutes(Int)

    var id: String { label }

    var label: String {
        switch self {
        case .indefinitely:
            return "Indefinitely"
        case .minutes(let m) where m < 60:
            return "\(m) Minutes"
        case .minutes(let m) where m == 60:
            return "1 Hour"
        case .minutes(let m):
            return m % 60 == 0 ? "\(m / 60) Hours" : "\(m) Minutes"
        }
    }

    var interval: TimeInterval? {
        switch self {
        case .indefinitely: return nil
        case .minutes(let m): return TimeInterval(m * 60)
        }
    }

    static let timed: [AwakeDuration] = [
        .minutes(15), .minutes(30), .minutes(60),
        .minutes(120), .minutes(240), .minutes(480),
    ]
}

@MainActor
final class AwakeController: ObservableObject {
    @Published private(set) var isAwake = false
    @Published private(set) var endsAt: Date?

    @Published var keepDisplayOn: Bool {
        didSet {
            UserDefaults.standard.set(keepDisplayOn, forKey: Keys.keepDisplayOn)
            // Re-apply so the change takes effect immediately while active.
            if isAwake { assertion.begin(preventDisplaySleep: keepDisplayOn) }
        }
    }

    private let assertion = SleepAssertion()
    private var timer: Timer?

    private enum Keys {
        static let keepDisplayOn = "keepDisplayOn"
    }

    init() {
        UserDefaults.standard.register(defaults: [Keys.keepDisplayOn: true])
        keepDisplayOn = UserDefaults.standard.bool(forKey: Keys.keepDisplayOn)
    }

    // MARK: - Awake state

    func toggle() {
        isAwake ? stop() : start(.indefinitely)
    }

    func start(_ duration: AwakeDuration) {
        timer?.invalidate()
        timer = nil

        guard assertion.begin(preventDisplaySleep: keepDisplayOn) else {
            isAwake = false
            endsAt = nil
            return
        }

        isAwake = true

        if let interval = duration.interval {
            endsAt = Date().addingTimeInterval(interval)
            let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
            // .common so the timer still fires while the menu is open (event-tracking run loop mode).
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        } else {
            endsAt = nil
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        assertion.end()
        isAwake = false
        endsAt = nil
    }

    var statusText: String {
        guard isAwake else { return "Sleep is allowed" }
        guard let endsAt else { return "Awake indefinitely" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = Calendar.current.isDateInToday(endsAt) ? .none : .short
        return "Awake until \(formatter.string(from: endsAt))"
    }

    // MARK: - Launch at login

    var launchAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Awake: launch-at-login change failed: \(error.localizedDescription)")
        }
        objectWillChange.send()
    }
}
