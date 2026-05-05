import SwiftUI

struct Song: Identifiable {
    let id = UUID()
    let name: String
}

struct MusicTabView: View {
    @ObservedObject var ble: BLEManager
    @State private var selected: UUID? = nil
    @State private var isPlaying = false
    @State private var showNowPlaying = false

    let songs: [Song] = [
        Song(name: "Lullaby in"),
        Song(name: "Wind Chimes"),
        Song(name: "Morning Dew"),
        Song(name: "Soft Bloom"),
        Song(name: "Petal Dream"),
        Song(name: "Twinkle Night"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Music")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.ptText)
                Spacer()
                if showNowPlaying {
                    Button("Library") {
                        withAnimation { showNowPlaying = false }
                    }
                    .font(.ptCaption)
                    .foregroundColor(.ptPinkDeep)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.ptDivider)

            if showNowPlaying, let selId = selected,
               let song = songs.first(where: { $0.id == selId }) {
                nowPlayingView(song: song)
            } else {
                songList
            }
        }
    }

    var songList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(songs) { song in
                    Button {
                        selected = song.id
                        isPlaying = true
                        withAnimation { showNowPlaying = true }
                    } label: {
                        HStack {
                            Text(song.name)
                                .font(.ptBody)
                                .foregroundColor(.ptText)
                            Spacer()
                            if selected == song.id {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
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
                    .background(selected == song.id ? Color.ptPinkLight.opacity(0.4) : Color.clear)

                    Divider().background(Color.ptDivider).padding(.leading, 16)
                }
            }
        }
    }

    func nowPlayingView(song: Song) -> some View {
        VStack(spacing: 12) {
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

            Text(song.name)
                .font(.ptBody)
                .foregroundColor(.ptText)

            // Controls
            HStack(spacing: 32) {
                Button {
                    if let idx = songs.firstIndex(where: { $0.id == selected }), idx > 0 {
                        selected = songs[idx - 1].id
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.ptTextMid)
                }
                .buttonStyle(.plain)

                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.ptPinkDeep)
                }
                .buttonStyle(.plain)

                Button {
                    if let idx = songs.firstIndex(where: { $0.id == selected }), idx < songs.count - 1 {
                        selected = songs[idx + 1].id
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.ptTextMid)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }
}
