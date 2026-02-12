import SwiftUI
import AppKit
import KeyboardShortcuts
import Combine

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording")
}

@main
struct ClawdVoiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var voiceManager: VoiceManager!
    var animationTimer: Timer?
    var animationFrame = 0
    var cancellables = Set<AnyCancellable>()
    
    let processingIcons = ["ellipsis.circle", "ellipsis.circle.fill", "circle.dotted", "ellipsis.circle"]
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Clawd Voice")
            button.action = #selector(togglePopover)
        }
        
        // Initialize voice manager
        voiceManager = VoiceManager()
        
        // Watch for processing state changes
        voiceManager.$isProcessing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isProcessing in
                if isProcessing {
                    self?.startAnimating()
                } else {
                    self?.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView(voiceManager: voiceManager))
        
        // Setup global keyboard shortcut
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
            self?.voiceManager.startRecording()
            self?.updateIcon(recording: true)
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            self?.voiceManager.stopRecordingAndProcess()
            self?.updateIcon(recording: false)
        }
        
        // Set default shortcut if not set
        if KeyboardShortcuts.getShortcut(for: .toggleRecording) == nil {
            KeyboardShortcuts.setShortcut(.init(.space, modifiers: .option), for: .toggleRecording)
        }
        
        print("ClawdVoice started! Press Option+Space to talk.")
    }
    
    func startAnimating() {
        animationFrame = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.animationFrame = (self.animationFrame + 1) % self.processingIcons.count
            if let button = self.statusItem.button {
                button.image = NSImage(systemSymbolName: self.processingIcons[self.animationFrame], accessibilityDescription: "Processing")
            }
        }
    }
    
    func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Clawd Voice")
        }
    }
    
    func updateIcon(recording: Bool) {
        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                let iconName = recording ? "waveform.circle.fill" : "waveform.circle"
                button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Clawd Voice")
            }
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
