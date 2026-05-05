import SwiftUI

struct PairingView: View {
    @ObservedObject var ble: BLEManager
    @State private var step: PairingStep = .welcome

    enum PairingStep { case welcome, selectDevice, connected }

    var body: some View {
        ZStack {
            Color.ptCream.ignoresSafeArea()

            switch step {
            case .welcome:       welcomeScreen
            case .selectDevice:  selectDeviceScreen
            case .connected:     connectedScreen
            }
        }
        .onChange(of: ble.connectionState) { _, state in
            switch state {
            case .scanning, .connecting:
                if step == .welcome { step = .selectDevice }
            case .connected:
                withAnimation(.easeInOut(duration: 0.4)) { step = .connected }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    // Parent will swap to HomeView once connected
                }
            case .disconnected:
                break
            }
        }
    }

    // MARK: Welcome

    var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // Flower illustration area
            ZStack {
                Circle()
                    .fill(Color.ptPinkLight.opacity(0.5))
                    .frame(width: 220, height: 220)
                FlowerView(isOpen: true, ledColor: .orange, onTap: {})
                    .scaleEffect(1.5)
                    .frame(width: 220, height: 220)
                    .clipped()
            }
            .padding(.bottom, 32)

            Text("WELCOME TO")
                .font(.system(size: 11, weight: .medium))
                .tracking(3)
                .foregroundColor(.ptTextMid)

            Text("PETALUX")
                .font(Font.custom("Georgia", size: 32))
                .foregroundColor(.ptText)
                .padding(.bottom, 8)

            Text("Your smart blooming lamp")
                .font(.ptCaption)
                .foregroundColor(.ptTextLight)

            Spacer()

            connectButton("Connect Device") {
                step = .selectDevice
                ble.startScanning()
            }
            .padding(.bottom, 48)
        }
    }

    // MARK: Select device

    var selectDeviceScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Select Your Device")
                .font(Font.custom("Georgia", size: 22))
                .foregroundColor(.ptText)
                .padding(.bottom, 24)

            // Device row — now a button
            Button {
                if ble.connectionState == .disconnected {
                    ble.startScanning()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Petalux Lamp")
                            .font(.ptBody)
                            .foregroundColor(.ptText)
                        Text(statusText)
                            .font(.ptCaption)
                            .foregroundColor(.ptTextLight)
                    }
                    Spacer()
                    if ble.connectionState == .connecting || ble.connectionState == .scanning {
                        ProgressView()
                            .tint(.ptPinkDeep)
                            .scaleEffect(0.8)
                    } else {
                        Text("Tap to connect")
                            .font(.ptCaption)
                            .foregroundColor(.ptPinkDeep)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.7))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ptPink, lineWidth: 0.5))
                .padding(.horizontal, 32)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // Add this helper var
    var statusText: String {
        switch ble.connectionState {
        case .scanning:    return "Scanning..."
        case .connecting:  return "Connecting..."
        case .connected:   return "Connected"
        case .disconnected: return "Not connected"
        }
    }
    // MARK: Connected

    var connectedScreen: some View {
        VStack(spacing: 16) {
            Spacer()

            // Checkmark
            ZStack {
                Circle()
                    .fill(Color.ptSage.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.ptSage)
            }

            Text("Device Connected")
                .font(Font.custom("Georgia", size: 22))
                .foregroundColor(.ptText)

            Text("Petalux Lamp is ready")
                .font(.ptCaption)
                .foregroundColor(.ptTextLight)

            Spacer()

            connectButton("Enter App") { /* parent handles navigation */ }
                .padding(.bottom, 48)
        }
    }

    // MARK: Shared button

    func connectButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.ptSage)
                .cornerRadius(30)
                .padding(.horizontal, 40)
        }
        .buttonStyle(.plain)
    }
}
