import SwiftUI

struct SoundTrack: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
}

struct MusicTabView: View {
    @ObservedObject var ble: BLEManager
    @State private var selectedSoundID = "calm_melody"
    @State private var showNowPlaying = false

    private let soundTracks: [SoundTrack] = [
        SoundTrack(id: "1", name: "Bloom",     subtitle: "Built-in speaker"),
        SoundTrack(id: "2", name: "Sunrise",   subtitle: "Built-in speaker"),
        SoundTrack(id: "3", name: "Moonlight", subtitle: "Built-in speaker"),
    ]

    private var selectedSound: SoundTrack? {
        soundTracks.first { $0.id == selectedSoundID }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if showNowPlaying {
                    Button {
                        ble.send(.musicStop)
                        withAnimation { showNowPlaying = false }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Songs")
                                .font(.ptCaption)
                        }
                        .foregroundColor(.ptPinkDeep)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Sound")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.ptText)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.ptDivider)

            if showNowPlaying, let sound = selectedSound {
                nowPlayingView(sound: sound)
            } else {
                soundList
            }
        }
        .onChange(of: ble.lampState.currentSound) { _, soundID in
            guard let soundID, soundTracks.contains(where: { $0.id == soundID }) else { return }
            selectedSoundID = soundID
        }
    }

    var soundList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(soundTracks) { sound in
                    Button {
                        selectedSoundID = sound.id
                        if ble.send(.musicPlay(sound: sound.id)) {
                            withAnimation { showNowPlaying = true }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sound.name)
                                    .font(.ptBody)
                                    .foregroundColor(.ptText)
                                Text(sound.subtitle)
                                    .font(.ptCaption)
                                    .foregroundColor(.ptTextLight)
                            }
                            Spacer()
                            if selectedSoundID == sound.id {
                                Image(systemName: isSoundPlaying(sound) ? "pause.fill" : "play.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.ptPinkDeep)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.ptTextLight)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                    .disabled(!ble.isCommandReady)
                    .opacity(ble.isCommandReady ? 1 : 0.4)
                    .background(selectedSoundID == sound.id ? Color.ptPinkLight.opacity(0.4) : Color.clear)

                    Divider().background(Color.ptDivider).padding(.leading, 16)
                }
            }
        }
    }

    func nowPlayingView(sound: SoundTrack) -> some View {
        let isPlaying = isSoundPlaying(sound)

        return VStack(spacing: 12) {
            // Album art placeholder - soft pink circle
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.ptPinkLight, Color.ptPink.opacity(0.6)],
                            center: .center, startRadius: 10, endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)
                Image(systemName: "music.note")
                    .font(.system(size: 28))
                    .foregroundColor(.ptPinkDeep.opacity(0.6))
            }
            .rotationEffect(.degrees(isPlaying ? 360 : 0))
            .animation(isPlaying ? .linear(duration: 8).repeatForever(autoreverses: false) : .default, value: isPlaying)

            Text(sound.name)
                .font(.ptBody)
                .foregroundColor(.ptText)
            Text(sound.subtitle)
                .font(.ptCaption)
                .foregroundColor(.ptTextLight)

            // Controls
            HStack(spacing: 28) {
                Button {
                    if isPlaying {
                        ble.send(.musicStop)
                    } else {
                        ble.send(.musicPlay(sound: sound.id))
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.ptPinkDeep)
                }
                .buttonStyle(.plain)
                .disabled(!ble.isCommandReady)
                .opacity(ble.isCommandReady ? 1 : 0.4)
            }
        }
        .padding(.vertical, 12)
    }

    private func isSoundPlaying(_ sound: SoundTrack) -> Bool {
        if let currentSound = ble.lampState.currentSound {
            return ble.lampState.isMusicPlaying && currentSound == sound.id
        }
        return ble.lampState.isMusicPlaying && selectedSoundID == sound.id
    }
}
