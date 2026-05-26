import SwiftUI

@main
struct PetaLuxApp: App {
    init() {
        print("🌸 App launched")  // add this
    }
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var ble = BLEManager()

    var body: some View {
        Group {
            if ble.connectionState == .connected {
                HomeView(ble: ble)
                    .transition(.opacity)
            } else {
                PairingView(ble: ble)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: ble.connectionState == .connected)
        .preferredColorScheme(.light)
    }
}
