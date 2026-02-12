import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @State private var elevenLabsAPIKey = ""
    @State private var openclawURL = "http://localhost:18789"
    @State private var openclawToken = ""
    @State private var saved = false
    
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Push-to-Talk:", name: .toggleRecording)
            } header: {
                Text("Keyboard Shortcut")
            }
            
            Section {
                TextField("OpenClaw URL", text: $openclawURL)
                    .textFieldStyle(.roundedBorder)
                SecureField("OpenClaw Token", text: $openclawToken)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("OpenClaw Connection")
            }
            
            Section {
                SecureField("ElevenLabs API Key", text: $elevenLabsAPIKey)
                    .textFieldStyle(.roundedBorder)
                Text("Leave empty to use system voice")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Text-to-Speech")
            }
            
            Section {
                Button(saved ? "Saved ✓" : "Save Configuration") {
                    saveConfig()
                }
                .disabled(saved)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 400, height: 350)
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        if let config = AppConfig.load() {
            elevenLabsAPIKey = config.elevenLabsAPIKey
            openclawURL = config.openclawURL ?? "http://localhost:18789"
            openclawToken = config.openclawToken ?? ""
        }
    }
    
    private func saveConfig() {
        let config = AppConfig(elevenLabsAPIKey: elevenLabsAPIKey, openclawURL: openclawURL, openclawToken: openclawToken)
        config.save()
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saved = false
        }
    }
}
