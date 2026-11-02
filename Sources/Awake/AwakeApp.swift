import AppKit
import SwiftUI

@main
struct AwakeApp: App {
    @StateObject private var controller = AwakeController()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller)
        } label: {
            Image(systemName: controller.isAwake ? "sun.max.fill" : "moon.zzz")
                .accessibilityLabel(controller.isAwake ? "Awake: on" : "Awake: off")
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuContent: View {
    @ObservedObject var controller: AwakeController

    var body: some View {
        Text(controller.statusText)

        if controller.isAwake {
            Button("Turn Off") { controller.stop() }
        } else {
            Button("Keep Awake") { controller.start(.indefinitely) }
        }

        Menu("Keep Awake For") {
            ForEach(AwakeDuration.timed) { duration in
                Button(duration.label) { controller.start(duration) }
            }
        }

        Divider()

        Toggle("Keep Display On", isOn: $controller.keepDisplayOn)

        Toggle("Launch at Login", isOn: Binding(
            get: { controller.launchAtLogin },
            set: { controller.setLaunchAtLogin($0) }
        ))

        Divider()

        Button("Quit Awake") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
