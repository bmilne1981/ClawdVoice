# ClawdVoice 🎙️

A macOS menubar app for voice interaction with [OpenClaw](https://github.com/openclaw/openclaw). Talk to your AI assistant with full session context, tool access, and natural conversation.

## Features

- **Push-to-talk**: Hold `⌥Space` (Option+Space) to speak
- **Full context**: Routes through your main OpenClaw session — same memory, same tools, same conversation
- **Visual feedback**: Menubar icon animates while processing
- **ElevenLabs TTS**: Responses are spoken back with high-quality voices
- **Configurable**: Point to any OpenClaw instance

## Requirements

- macOS 13.0+
- [OpenClaw](https://github.com/openclaw/openclaw) running locally or on your network
- Voice Bridge server (see below)
- ElevenLabs API key (for TTS)

## Installation

### Build from source

```bash
git clone https://github.com/bmilne1981/ClawdVoice.git
cd ClawdVoice
swift build -c release
cp -r .build/release/ClawdVoice /Applications/ClawdVoice.app/Contents/MacOS/
```

### Configure

Create `~/.clawd-voice-config.json`:

```json
{
  "elevenLabsAPIKey": "your-api-key",
  "openclawURL": "http://localhost:18789",
  "openclawToken": "your-openclaw-token"
}
```

## Voice Bridge

For full session context (recommended), run the voice bridge on your OpenClaw host:

```javascript
// voice-bridge/server.js - routes voice input through main session
// See: https://github.com/bmilne1981/ClawdVoice/wiki/Voice-Bridge
```

The bridge injects voice input into your main OpenClaw session, giving the voice interface access to your full conversation history and tools.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ ClawdVoice  │────▶│ Voice Bridge │────▶│  OpenClaw   │
│  (macOS)    │◀────│  (Node.js)   │◀────│  (Gateway)  │
└─────────────┘     └──────────────┘     └─────────────┘
      │                                         │
      │              ┌──────────────┐           │
      └─────────────▶│  ElevenLabs  │◀──────────┘
         TTS         │     API      │    (responses)
                     └──────────────┘
```

## Usage

1. Launch ClawdVoice (appears in menubar)
2. Hold `⌥Space` and speak
3. Release when done — there's a 2-second buffer to catch trailing words
4. Watch the icon animate while processing
5. Hear the response via ElevenLabs TTS

## Customization

### Change the voice

Edit `Sources/VoiceManager.swift` and update `elevenLabsVoiceID`:

```swift
private let elevenLabsVoiceID = "your-voice-id"
```

### Change the hotkey

Open Settings from the menubar dropdown to configure the keyboard shortcut.

## License

MIT

## Credits

Built for [OpenClaw](https://openclaw.ai) by Clawd 🐾
