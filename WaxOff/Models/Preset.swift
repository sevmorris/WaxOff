import Foundation

struct Preset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var options: ProcessingOptions

    init(id: UUID = UUID(), name: String, options: ProcessingOptions) {
        self.id = id
        self.name = name
        self.options = options
    }

    static let builtIn: [Preset] = [
        Preset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Podcast Standard",
            options: ProcessingOptions(
                targetLUFS: -18,
                truePeak: -1.0,
                lra: 11.0,
                outputMode: .both,
                mp3Bitrate: 160,
                sampleRate: 44100,
                phaseRotationEnabled: true
            )
        ),
        Preset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Podcast Loud",
            options: ProcessingOptions(
                targetLUFS: -16,
                truePeak: -1.0,
                lra: 11.0,
                outputMode: .both,
                mp3Bitrate: 192,
                sampleRate: 44100,
                phaseRotationEnabled: true
            )
        ),
        Preset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "WAV Only (Mastering)",
            options: ProcessingOptions(
                targetLUFS: -18,
                truePeak: -1.0,
                lra: 11.0,
                outputMode: .wav,
                mp3Bitrate: 160,
                sampleRate: 48000,
                phaseRotationEnabled: true
            )
        )
    ]
}

final class PresetStore: ObservableObject {
    @Published var presets: [Preset] = []
    @Published var selectedPresetID: UUID?

    private let userDefaultsKey = "WaxOffUserPresets"

    init() {
        loadPresets()
    }

    var allPresets: [Preset] {
        Preset.builtIn + presets
    }

    var selectedPreset: Preset? {
        guard let id = selectedPresetID else { return nil }
        return allPresets.first { $0.id == id }
    }

    func savePreset(name: String, options: ProcessingOptions) {
        let preset = Preset(name: name, options: options)
        presets.append(preset)
        saveToUserDefaults()
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        if selectedPresetID == preset.id {
            selectedPresetID = nil
        }
        saveToUserDefaults()
    }

    func isBuiltIn(_ preset: Preset) -> Bool {
        Preset.builtIn.contains { $0.id == preset.id }
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            presets = try JSONDecoder().decode([Preset].self, from: data)
        } catch {
            LogService.shared.log("Failed to load presets: \(error)")
        }
    }

    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(presets)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            LogService.shared.log("Failed to save presets: \(error)")
        }
    }
}
