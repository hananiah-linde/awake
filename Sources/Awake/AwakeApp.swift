import AppKit

@main
@MainActor
enum AwakeApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = StatusItemController(controller: AwakeController())
    }
}

/// Left click toggles Awake on/off (indefinitely). Right click (or two-finger tap / control-click) opens the menu.
/// MenuBarExtra can't tell the two apart, so this uses NSStatusItem directly.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let controller: AwakeController
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    init(controller: AwakeController) {
        self.controller = controller
        super.init()

        menu.delegate = self
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        controller.onChange = { [weak self] in self?.updateButton() }
        updateButton()
    }

    // MARK: - Clicks

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            controller.toggle()
        }
    }

    private func showMenu() {
        rebuildMenu()
        // Attaching the menu only for this click keeps left click free for toggling.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    // MARK: - Menu

    private func rebuildMenu() {
        menu.removeAllItems()

        if let status = controller.statusText {
            menu.addItem(NSMenuItem(title: status, action: nil, keyEquivalent: ""))
            menu.addItem(.separator())
        }

        menu.addItem(NSMenuItem(title: "Keep Awake For", action: nil, keyEquivalent: ""))
        for (index, duration) in AwakeDuration.timed.enumerated() {
            let item = NSMenuItem(title: duration.label, action: #selector(startTimed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.indentationLevel = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        login.target = self
        login.state = controller.launchAtLogin ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Awake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    @objc private func startTimed(_ sender: NSMenuItem) {
        controller.start(AwakeDuration.timed[sender.tag])
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        controller.setLaunchAtLogin(!controller.launchAtLogin)
    }

    // MARK: - Icon

    private func updateButton() {
        guard let button = statusItem.button else { return }
        let timed = controller.isAwake && controller.endsAt != nil
        button.image = StatusIcon.image(timed: timed)
        // Dimmed (greyed out) while sleep is allowed.
        button.appearsDisabled = !controller.isAwake
        button.setAccessibilityLabel(controller.isAwake ? "Awake: on" : "Awake: off")
    }
}
