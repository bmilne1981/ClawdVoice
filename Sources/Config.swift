import Foundation

struct AppConfig: Codable {
    let elevenLabsAPIKey: String
    let openclawURL: String?
    let openclawToken: String?
    
    static func load() -> AppConfig? {
        let configPath = NSHomeDirectory() + "/.clawd-voice-config.json"
        guard let data = FileManager.default.contents(atPath: configPath) else { return nil }
        return try? JSONDecoder().decode(AppConfig.self, from: data)
    }
    
    func save() {
        let configPath = NSHomeDirectory() + "/.clawd-voice-config.json"
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: URL(fileURLWithPath: configPath))
        }
    }
}
