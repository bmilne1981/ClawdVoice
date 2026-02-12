import Foundation
import AVFoundation
import Speech
import Combine
import AppKit

class VoiceManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var lastTranscript = ""
    @Published var lastResponse = ""
    @Published var statusMessage = "Ready"
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioPlayer: AVAudioPlayer?
    
    // Configuration
    private var openclawURL = "http://127.0.0.1:18789"
    private var openclawToken = ""
    private var elevenLabsAPIKey = ""
    private let elevenLabsVoiceID = "UgBBYS2sOqTuMpoF3BR0"
    
    override init() {
        super.init()
        loadConfig()
        requestPermissions()
    }
    
    private func loadConfig() {
        if let config = AppConfig.load() {
            elevenLabsAPIKey = config.elevenLabsAPIKey
            openclawURL = config.openclawURL ?? "http://localhost:18789"
            openclawToken = config.openclawToken ?? ""
        }
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized: \(status)")
                @unknown default:
                    break
                }
            }
        }
        
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            print("Microphone access: \(granted)")
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        statusMessage = "Listening..."
        lastTranscript = ""
        
        startLiveRecognition()
    }
    
    private func startLiveRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.lastTranscript = result.bestTranscription.formattedString
                }
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    func stopRecordingAndProcess() {
        // Add delay to capture trailing words
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.doStopRecordingAndProcess()
        }
    }
    
    private func doStopRecordingAndProcess() {
        guard isRecording else { return }
        
        isRecording = false
        statusMessage = "Processing..."
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        let transcript = lastTranscript
        guard !transcript.isEmpty else {
            statusMessage = "No speech detected"
            return
        }
        
        isProcessing = true
        sendToOpenClaw(text: transcript)
    }
    
    private func sendToOpenClaw(text: String) {
        statusMessage = "Talking to Clawd..."
        
        // Use voice bridge for full session context
        let bridgeURL = "http://localhost:8770/voice"
        let url = URL(string: bridgeURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = ["text": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 60
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                    self?.isProcessing = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    self?.statusMessage = "API Error: \(httpResponse.statusCode)"
                    self?.isProcessing = false
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let content = json["response"] as? String {
                    self?.lastResponse = content
                    self?.speakResponse(content)
                } else {
                    let responseStr = data.flatMap { String(data: $0, encoding: .utf8) } ?? "unknown"
                    print("Failed to parse response: \(responseStr)")
                    self?.statusMessage = "No response"
                    self?.isProcessing = false
                }
            }
        }.resume()
    }

    private func speakResponse(_ text: String) {
        statusMessage = "Speaking..."
        
        guard !elevenLabsAPIKey.isEmpty else {
            // Fallback to system TTS
            let synth = NSSpeechSynthesizer()
            synth.startSpeaking(text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.statusMessage = "Ready"
                self.isProcessing = false
            }
            return
        }
        
        // Use ElevenLabs
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(elevenLabsVoiceID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": ["stability": 0.5, "similarity_boost": 0.75]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    self?.statusMessage = "TTS Error"
                    self?.isProcessing = false
                    return
                }
                
                // Save and play audio
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("clawd_response.mp3")
                try? data.write(to: tempURL)
                
                do {
                    self?.audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.play()
                } catch {
                    print("Audio playback error: \(error)")
                    self?.statusMessage = "Ready"
                    self?.isProcessing = false
                }
            }
        }.resume()
    }
}

extension VoiceManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.statusMessage = "Ready"
            self.isProcessing = false
        }
    }
}
