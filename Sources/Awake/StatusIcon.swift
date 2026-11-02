import AppKit

/// Menu bar icon: a cup and saucer, with a small clock badge while a timed session is running.
/// Template images, so macOS tints them for light/dark menu bars and for the dimmed "off" state.
enum StatusIcon {
    @MainActor
    static func image(timed: Bool) -> NSImage? {
        guard let cup = symbol("cup.and.saucer.fill", pointSize: 15, weight: .regular) else { return nil }
        guard timed, let clock = symbol("clock.fill", pointSize: 8, weight: .bold) else {
            cup.isTemplate = true
            return cup
        }

        let size = cup.size
        // Drawing handler (not lockFocus) so it re-renders at the menu bar's backing scale.
        let image = NSImage(size: size, flipped: false) { rect in
            cup.draw(in: rect)

            // Bottom-right badge, with a transparent ring cut out of the cup so the clock stays readable.
            let badge = NSRect(
                x: rect.maxX - clock.size.width,
                y: rect.minY,
                width: clock.size.width,
                height: clock.size.height
            )
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: badge.insetBy(dx: -1, dy: -1)).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
            clock.draw(in: badge)
            return true
        }

        image.isTemplate = true
        return image
    }

    private static func symbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: pointSize, weight: weight))
    }
}
