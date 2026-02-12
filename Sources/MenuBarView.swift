import SwiftUI

struct MenuBarView: View {
    @ObservedObject var voiceManager: VoiceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundColor(voiceManager.isRecording ? .red : .blue)
                Text("Clawd Voice")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(voiceManager.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Last transcript
            if !voiceManager.lastTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(voiceManager.lastTranscript)
                        .font(.caption)
                        .lineLimit(3)
                }
            }
            
            // Last response
            if !voiceManager.lastResponse.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clawd:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(voiceManager.lastResponse)
                        .font(.caption)
                        .lineLimit(3)
                }
            }
            
            Divider()
            
            // Instructions
            Text("Press ⌥Space to talk")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Buttons
            HStack {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.link)
            }
        }
        .padding()
        .frame(width: 280)
    }
    
    var statusColor: Color {
        if voiceManager.isRecording {
            return .red
        } else if voiceManager.isProcessing {
            return .orange
        } else {
            return .green
        }
    }
}
