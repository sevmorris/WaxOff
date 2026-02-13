import SwiftUI

struct PresetPicker: View {
    @EnvironmentObject var queue: ProcessingQueue
    @State private var showingSaveSheet = false
    @State private var newPresetName = ""

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Section("Built-in Presets") {
                    ForEach(Preset.builtIn) { preset in
                        Button(preset.name) {
                            queue.applyPreset(preset)
                        }
                    }
                }

                if !queue.presetStore.presets.isEmpty {
                    Section("Custom Presets") {
                        ForEach(queue.presetStore.presets) { preset in
                            HStack {
                                Button(preset.name) {
                                    queue.applyPreset(preset)
                                }
                            }
                        }
                    }
                }

                Divider()

                Button("Save Current Settings...") {
                    newPresetName = ""
                    showingSaveSheet = true
                }

                if !queue.presetStore.presets.isEmpty {
                    Menu("Delete Preset") {
                        ForEach(queue.presetStore.presets) { preset in
                            Button(preset.name, role: .destructive) {
                                queue.presetStore.deletePreset(preset)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                    Text(currentPresetName)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .sheet(isPresented: $showingSaveSheet) {
            SavePresetSheet(presetName: $newPresetName) {
                if !newPresetName.isEmpty {
                    queue.saveCurrentAsPreset(name: newPresetName)
                }
                showingSaveSheet = false
            } onCancel: {
                showingSaveSheet = false
            }
        }
    }

    private var currentPresetName: String {
        if let preset = queue.presetStore.selectedPreset {
            return preset.name
        }
        return "Custom"
    }
}

struct SavePresetSheet: View {
    @Binding var presetName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Save Preset")
                .font(.headline)

            TextField("Preset Name", text: $presetName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }

                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(presetName.isEmpty)
            }
        }
        .padding(24)
    }
}

#Preview {
    PresetPicker()
        .environmentObject(ProcessingQueue())
        .padding()
}
