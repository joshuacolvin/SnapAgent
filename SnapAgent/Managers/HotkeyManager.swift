import Foundation
import AppKit
import HotKey
import Carbon

@MainActor
class HotkeyManager: ObservableObject {
    private var regionHotKey: HotKey?
    private var fullscreenHotKey: HotKey?

    var onRegionHotkeyPressed: (() -> Void)?
    var onFullscreenHotkeyPressed: (() -> Void)?

    // Region select hotkey (default: Cmd+Shift+A)
    @Published var regionKeyCode: UInt32 = 0
    @Published var regionModifiers: NSEvent.ModifierFlags = [.command, .shift]

    // Fullscreen hotkey (default: Cmd+Shift+S)
    @Published var fullscreenKeyCode: UInt32 = 0
    @Published var fullscreenModifiers: NSEvent.ModifierFlags = [.command, .shift]

    init() {
        loadSavedHotkeys()
        registerHotkeys()
    }

    func registerHotkeys() {
        // Region hotkey
        regionHotKey = nil
        if let key = Key(carbonKeyCode: regionKeyCode) {
            regionHotKey = HotKey(key: key, modifiers: regionModifiers)
            regionHotKey?.keyDownHandler = { [weak self] in
                self?.onRegionHotkeyPressed?()
            }
        }

        // Fullscreen hotkey
        fullscreenHotKey = nil
        if let key = Key(carbonKeyCode: fullscreenKeyCode) {
            fullscreenHotKey = HotKey(key: key, modifiers: fullscreenModifiers)
            fullscreenHotKey?.keyDownHandler = { [weak self] in
                self?.onFullscreenHotkeyPressed?()
            }
        }
    }

    func updateRegionHotkey(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        regionKeyCode = keyCode
        regionModifiers = modifiers
        saveHotkeys()
        registerHotkeys()
    }

    func updateFullscreenHotkey(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        fullscreenKeyCode = keyCode
        fullscreenModifiers = modifiers
        saveHotkeys()
        registerHotkeys()
    }

    private func saveHotkeys() {
        UserDefaults.standard.set(Int(regionKeyCode), forKey: Constants.Keys.hotkeyKeyCode)
        UserDefaults.standard.set(Int(regionModifiers.rawValue), forKey: Constants.Keys.hotkeyModifiers)
        UserDefaults.standard.set(Int(fullscreenKeyCode), forKey: Constants.Keys.fullscreenHotkeyKeyCode)
        UserDefaults.standard.set(Int(fullscreenModifiers.rawValue), forKey: Constants.Keys.fullscreenHotkeyModifiers)
    }

    private func loadSavedHotkeys() {
        // Region hotkey
        if UserDefaults.standard.object(forKey: Constants.Keys.hotkeyKeyCode) != nil {
            regionKeyCode = UInt32(UserDefaults.standard.integer(forKey: Constants.Keys.hotkeyKeyCode))
            regionModifiers = NSEvent.ModifierFlags(
                rawValue: UInt(UserDefaults.standard.integer(forKey: Constants.Keys.hotkeyModifiers))
            )
        } else {
            regionKeyCode = UInt32(kVK_ANSI_A)
            regionModifiers = [.command, .shift]
        }

        // Fullscreen hotkey
        if UserDefaults.standard.object(forKey: Constants.Keys.fullscreenHotkeyKeyCode) != nil {
            fullscreenKeyCode = UInt32(UserDefaults.standard.integer(forKey: Constants.Keys.fullscreenHotkeyKeyCode))
            fullscreenModifiers = NSEvent.ModifierFlags(
                rawValue: UInt(UserDefaults.standard.integer(forKey: Constants.Keys.fullscreenHotkeyModifiers))
            )
        } else {
            fullscreenKeyCode = UInt32(kVK_ANSI_S)
            fullscreenModifiers = [.command, .shift]
        }
    }

    func describeHotkey(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("\u{2318}") }
        if modifiers.contains(.shift) { parts.append("\u{21E7}") }
        if modifiers.contains(.option) { parts.append("\u{2325}") }
        if modifiers.contains(.control) { parts.append("\u{2303}") }

        if let key = Key(carbonKeyCode: keyCode) {
            parts.append(key.description.uppercased())
        }

        return parts.joined()
    }

    var regionHotkeyDescription: String {
        describeHotkey(keyCode: regionKeyCode, modifiers: regionModifiers)
    }

    var fullscreenHotkeyDescription: String {
        describeHotkey(keyCode: fullscreenKeyCode, modifiers: fullscreenModifiers)
    }
}
